if BG.IsBlackListPlayer then return end
local _, ns = ...

local L = ns.L

local C = ns.Protocol
local SendGateway = ns.SendGateway
local SetClassCFF = ns.SetClassCFF
local Maxb = ns.Maxb
local GetItemID = ns.GetItemID


local channel = C.PREFIX_RECEIVE
C_ChatInfo.RegisterAddonMessagePrefix(channel)
for i = 1, BG.addonChannelCount do
    C_ChatInfo.RegisterAddonMessagePrefix(channel .. i)
end

local _, class = UnitClass("player")
local r, g, b, cff = GetClassColor(class)

local function resolveBuyerColor(item)
    if item.color then
        local cr, cg, cb = unpack(item.color)
        return ns.RGB_16(nil, cr, cg, cb)
    end
    return "FFFFFF"
end

function BG.ReceiveUI()
    local draft = {}
    local CreateButton
    local mainFrame
    local logFrame
    local titleText

    -- UI
    do
        -- 主界面
        mainFrame = CreateFrame("Frame", "BG.ReceiveFrame", UIParent, "BackdropTemplate")
        BG.ReceiveMainFrame = mainFrame
        do
            mainFrame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 2
            })
            mainFrame:SetBackdropColor(0, 0, 0, 0.9)
            mainFrame:SetBackdropBorderColor(r, g, b)
            mainFrame:SetPoint("CENTER")
            mainFrame:SetFrameLevel(100)
            mainFrame:SetMovable(true)
            mainFrame:SetToplevel(true)
            mainFrame:SetSize(300, 500)
            mainFrame.FB = BG.FB1
            mainFrame:SetScript("OnMouseUp", function(self)
                self:StopMovingOrSizing()
            end)
            mainFrame:SetScript("OnMouseDown", function(self)
                BG.FrameHide(0)
                self:StartMoving()
            end)
            mainFrame:SetScript("OnHide", function(self)
                StaticPopup_Hide("BiaoGe_YingYongReceiveBiaoGe")
            end)
            mainFrame:SetScript("OnShow", function(self)
                local FB = self.FB
                mainFrame:SetWidth(BG.FBWidth[FB])
                mainFrame:SetHeight(BG.FBHeight[FB] - 20)
                logFrame:SetHeight(mainFrame:GetHeight())
                logFrame.notText:SetShown(not next(logFrame.buttons))
            end)
            tinsert(UISpecialFrames, "BG.ReceiveFrame")

            BG.CreateCloseButton(mainFrame)
            mainFrame.CloseButton:SetSize(40, 40)

            local TitleText = mainFrame:CreateFontString()
            TitleText:SetPoint("TOP", mainFrame, "TOP", 0, -10)
            TitleText:SetFont(BIAOGE_TEXT_FONT, 16, "OUTLINE")
            titleText = TitleText
            BG.ReceiveMainFrameTitle = titleText

            local l = mainFrame:CreateLine()
            l:SetColorTexture(r, g, b)
            l:SetStartPoint("BOTTOMLEFT", TitleText, -20, -2)
            l:SetEndPoint("BOTTOMRIGHT", TitleText, 20, -2)
            l:SetThickness(1.5)
        end

        -- 拍卖记录
        do
            logFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            BG.ReceiveAuctionLogFrame = logFrame
            do
                logFrame:SetBackdrop(mainFrame:GetBackdrop())
                logFrame:SetBackdropColor(mainFrame:GetBackdropColor())
                logFrame:SetBackdropBorderColor(r, g, b)
                logFrame:SetSize(220, mainFrame:GetHeight())
                logFrame:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", 1, 0)
                logFrame:EnableMouse(true)
                logFrame.buttons = {}
                logFrame:SetScript("OnMouseUp", function(self)
                    mainFrame:GetScript("OnMouseUp")(mainFrame)
                end)
                logFrame:SetScript("OnMouseDown", function(self)
                    mainFrame:GetScript("OnMouseDown")(mainFrame)
                end)

                local t = logFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 16, "OUTLINE")
                t:SetPoint("TOP", logFrame, "TOP", 0, -8)
                t:SetText(L["拍卖记录"])
            end

            -- 滚动框
            do
                local frame = CreateFrame("Frame", nil, logFrame, "BackdropTemplate")
                frame:SetBackdrop({
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                frame:SetBackdropBorderColor(.5, .5, .5, .5)
                frame:SetBackdropColor(0, 0, 0, 0.8)
                frame:SetPoint("TOPLEFT", 5, -30)
                frame:SetPoint("BOTTOMRIGHT", -5, 5)
                frame:EnableMouse(true)
                logFrame.frame = frame

                local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
                scroll:SetPoint("TOPLEFT", 5, -5)
                scroll:SetPoint("BOTTOMRIGHT", -26, 5)
                scroll.ScrollBar.scrollStep = BG.scrollStep
                frame.scroll = scroll
                BG.CreateSrollBarBackdrop(scroll.ScrollBar)
                BG.HookScrollBarShowOrHide(scroll)
                logFrame.scroll = scroll

                local child = CreateFrame("Frame", nil, scroll)
                child:SetAllPoints()
                child:SetWidth(scroll:GetWidth())
                child:SetHeight(scroll:GetHeight())
                scroll:SetScrollChild(child)
                logFrame.child = child

                local _f = CreateFrame("Frame", nil, frame)
                _f:SetSize(1, 1)
                _f:SetPoint("TOPRIGHT", 0, 1)
                frame.tooltip = _f

                local t = child:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("TOP", 0, 0)
                t:SetTextColor(1, 0, 0)
                t:SetText(L["没有自动拍卖记录。"])
                t:SetWidth(scroll:GetWidth())
                t:Hide()
                logFrame.notText = t
            end

            -- 列表内容
            local buttons = logFrame.buttons
            function CreateButton(num, v)
                local bts = {}
                local width = logFrame.child:GetWidth()
                local link = v.zhuangbei
                local itemID = GetItemID(link)
                local icon, typeID = select(5, GetItemInfoInstant(link))
                local cr, cg, cb = GetItemQualityColor(v.quality)
                bts.link = link
                bts.itemID = itemID
                bts.num = num
                -- 主框架
                do
                    local rowFrame = CreateFrame("Frame", nil, logFrame.child, "BackdropTemplate")
                    rowFrame:SetSize(width, 32)
                    if not next(buttons) then
                        rowFrame:SetPoint("TOPLEFT")
                    else
                        rowFrame:SetPoint("TOPLEFT", buttons[#buttons].frame, "BOTTOMLEFT", 0, 0)
                    end
                    rowFrame.link = link
                    bts.frame = rowFrame
                    rowFrame:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(logFrame.frame.tooltip, "ANCHOR_BOTTOMRIGHT", 0, 0)
                        GameTooltip:ClearLines()
                        local infoItemID = GetItemInfoInstant(link)
                        if infoItemID then
                            GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                        end
                        bts.ds:Show()
                    end)
                    rowFrame:SetScript("OnLeave", function(self)
                        GameTooltip:Hide()
                        bts.ds:Hide()
                    end)

                    local stripe = rowFrame:CreateTexture(nil, "BACKGROUND")
                    stripe:SetAllPoints()
                    if num % 2 == 0 then
                        stripe:SetColorTexture(.5, .5, .5, .15)
                    else
                        stripe:SetColorTexture(0, 0, 0, .25)
                    end
                    bts.tex = stripe

                    local highlight = rowFrame:CreateTexture()
                    highlight:SetAllPoints()
                    highlight:SetColorTexture(.5, .5, .5, .5)
                    highlight:Hide()
                    bts.ds = highlight

                    tinsert(buttons, bts)
                end
                -- 图标和装等
                do
                    local iconFrame = CreateFrame("Frame", nil, bts.frame, "BackdropTemplate")
                    iconFrame:SetBackdrop({
                        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeSize = 1,
                    })
                    iconFrame:SetBackdropBorderColor(cr, cg, cb)
                    iconFrame:SetSize(bts.frame:GetHeight() - 2, bts.frame:GetHeight() - 2)
                    iconFrame:SetPoint("LEFT")
                    bts.iconFrame = iconFrame
                    local iconTexture = iconFrame:CreateTexture(nil, "BACKGROUND")
                    iconTexture:SetAllPoints()
                    iconTexture:SetTexture(icon)
                    iconTexture:SetTexCoord(unpack(BG.iconTexCoord))
                    bts.icon = iconTexture
                    iconFrame.level = iconFrame:CreateFontString()
                    iconFrame.level:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
                    iconFrame.level:SetPoint("BOTTOM", bts.icon, 0, 1)
                    local hasLevel = typeID == 2 or typeID == 4
                    iconFrame.level:SetText(hasLevel and v.itemlevel or nil)
                    iconFrame.level:SetTextColor(cr, cg, cb)
                    if v.bindType == 2 then
                        local text = bts.iconFrame:CreateFontString()
                        text:SetFont(BIAOGE_TEXT_FONT, 10, "OUTLINE")
                        text:SetPoint("TOP", bts.iconFrame, 0, -1)
                        text:SetText(L["装绑"])
                        text:SetTextColor(0, 1, 0)
                    end
                end
                -- 装备
                do
                    local itemText = bts.frame:CreateFontString()
                    itemText:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                    itemText:SetWidth(width - bts.icon:GetWidth())
                    itemText:SetPoint("TOPLEFT", bts.icon, "TOPRIGHT", 1, 0)
                    itemText:SetText(link:gsub("%[", ""):gsub("%]", ""))
                    itemText:SetJustifyH("LEFT")
                    itemText:SetWordWrap(false)
                    bts.item = itemText
                end
                -- 买家和金额
                do
                    local moneyText = bts.frame:CreateFontString()
                    moneyText:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                    moneyText:SetPoint("BOTTOMLEFT", bts.icon, "BOTTOMRIGHT", 1, 0)
                    moneyText:SetWidth(width - bts.icon:GetWidth())
                    moneyText.LiuPaiText = BG.STC_r1(L["<流拍>"])
                    if v.type == 1 then
                        local color = resolveBuyerColor(v)
                        moneyText:SetText(format("%s |cff%s%s|r", BG.FormatNumber(v.jine, 2), color, v.maijia))
                    else
                        moneyText:SetText(moneyText.LiuPaiText)
                    end
                    moneyText:SetJustifyH("LEFT")
                    moneyText:SetWordWrap(false)
                    bts.money = moneyText
                end
            end
        end

        -- 使用该表格
        do
            local bt = BG.CreateButton(mainFrame)
            bt:SetSize(120, 25)
            bt:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOM", -10, 20)
            bt:SetText(L["使用该表格"])
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                if not StaticPopupDialogs["BiaoGe_YingYongReceiveBiaoGe"] then
                    StaticPopupDialogs["BiaoGe_YingYongReceiveBiaoGe"] = {
                        text = L["确定使用该表格？\n你的当前表格将被其|cffff0000替换|r"],
                        button1 = L["是"],
                        button2 = L["否"],
                        OnCancel = function()
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        showAlert = true,
                    }
                end
                StaticPopupDialogs["BiaoGe_YingYongReceiveBiaoGe"].OnAccept = function()
                    local FB = draft.FB
                    BG.ClearBiaoGe("biaoge", FB)
                    BG.PairFBItem(function(item, buyer, money, b, i)
                        item:SetText(draft["boss" .. b]["zhuangbei" .. i] or "")
                        buyer:SetText(draft["boss" .. b]["maijia" .. i] or "")
                        buyer:SetCursorPosition(0)
                        if draft["boss" .. b]["color" .. i] then
                            buyer:SetTextColor(unpack(draft["boss" .. b]["color" .. i]))
                        end
                        money:SetText(draft["boss" .. b]["jine" .. i] or "")
                        local qiankuan = draft["boss" .. b]["qiankuan" .. i]
                        if qiankuan then
                            BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = qiankuan
                            BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                        end
                    end, nil, true, FB)
                    if next(draft.auctionLog) then
                        BiaoGe[FB].auctionLog = {}
                        for k, v in pairs(draft.auctionLog) do
                            BiaoGe[FB].auctionLog[k] = BG.Copy(v)
                        end
                    end
                    mainFrame:Hide()
                    BG.MainFrame:Show()
                    BG.ClickTabButton(BG.FBMainFrameTabNum)
                    BG.ClickFBbutton(FB)
                    BG.PlaySound(2)
                end
                StaticPopup_Show("BiaoGe_YingYongReceiveBiaoGe")
            end)

        end

        -- 二级
        for i, FB in ipairs(BG.FBtable) do
            BG["ReceiveFrame" .. FB] = CreateFrame("Frame", "BG.ReceiveFrame" .. FB, mainFrame)
            BG["ReceiveFrame" .. FB]:Hide()
        end
    end

    -- 将分享出来的表格文本渲染成可点击链接
    do
        local function ChangSendLink(self, event, msg, ...)
            local ver
            if strfind(msg, "^%[BiaoGe:.*%]$") then
                ver = 1
            elseif strfind(msg, "^%[" .. C.TAG_BIAOGE .. ":.*%]$") then
                ver = 2
            end
            if not ver then return end
            msg = strtrim(msg, "[]")
            local _, text = strsplit(":", msg, 2)
            if text then
                local newmsg = "|cff00BFFF" .. C.ITEM_PROTOCOL .. msg .. "|h[" .. text .. "]|h|r"
                if ver == 1 then
                    newmsg = newmsg .. L["|cffff0000（该链接为旧版本表格，已失效）"]
                end
                return false, newmsg, ...
            end
        end

        local chatEvents = {
            "CHAT_MSG_CHANNEL",
            "CHAT_MSG_YELL",
            "CHAT_MSG_GUILD",
            "CHAT_MSG_OFFICER",
            "CHAT_MSG_PARTY",
            "CHAT_MSG_PARTY_LEADER",
            "CHAT_MSG_RAID",
            "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_SAY",
            "CHAT_MSG_WHISPER",
            "CHAT_MSG_WHISPER_INFORM",
            "CHAT_MSG_BN_WHISPER",
            "CHAT_MSG_BN_WHISPER_INFORM",
            "CHAT_MSG_INSTANCE_CHAT",
            "CHAT_MSG_INSTANCE_CHAT_LEADER",
        }
        for _, chatEvent in ipairs(chatEvents) do
            ChatFrame_AddMessageEventFilter(chatEvent, ChangSendLink)
        end
    end

    local cd = {}
    hooksecurefunc("SetItemRef", function(link)
        local _, prefix, text = strsplit(":", link, 3)
        if not (prefix == C.TAG_BIAOGE and text) then return end
        local player, server, BiaoGeType, FB, title = strsplit("-", text)
        if BG.ValueInTable(BG.FBtable, FB) then
            if IsShiftKeyDown() then
                local msg = format("[%s:%s]", prefix, text)
                BG.InsertLink(msg)
            else
                if BG.SetCD(cd, 5) then
                    UIErrorsFrame:AddMessage(L["请求CD中..."], 1, 0, 0)
                    return
                end
                BG.ResetReceiveBiaoGe(FB)
                if not title then
                    title = ""
                end
                text = BiaoGeType .. "-" .. FB .. "-" .. title
                local fullName = player .. "-" .. server
                SendGateway.Throttled(channel, text, "WHISPER", fullName)
                BG.SendSystemMessage(format(L["已向%s发送请求%s。"], SetClassCFF(fullName), ""))
            end
        end
    end)

    -- 发送和接收表格数据
    -- 第一层用^^切分：基本信息、表格内容、拍卖记录三段
    -- 2级分割：&&
    -- 3级分割：¦
    local receiveStart = {}
    local receiveCodes = {}
    local receiveStart2 = {}
    local receiveCodes2 = {}
    function BG.ResetReceiveBiaoGe(FB)
        mainFrame:Hide()
        wipe(draft)
        draft.auctionLog = {}
        for b = 1, Maxb[FB] + 2 do
            draft["boss" .. b] = {}
            for i = 1, BG.GetMaxi(FB, b) do
                if BG.ReceiveFrame[FB]["boss" .. b]["zhuangbei" .. i] then
                    BG.ReceiveFrame[FB]["boss" .. b]["zhuangbei" .. i]:SetText("")
                    BG.ReceiveFrame[FB]["boss" .. b]["maijia" .. i]:SetText("")
                    BG.ReceiveFrame[FB]["boss" .. b]["maijia" .. i]:SetTextColor(1, 1, 1)
                    BG.ReceiveFrame[FB]["boss" .. b]["jine" .. i]:SetText("")
                    BG.ReceiveFrame[FB]["boss" .. b]["qiankuan" .. i]:Hide()

                    draft["boss" .. b]["zhuangbei" .. i] = ""
                    draft["boss" .. b]["maijia" .. i] = ""
                    draft["boss" .. b]["color" .. i] = { 1, 1, 1 }
                    draft["boss" .. b]["jine" .. i] = ""
                    draft["boss" .. b]["qiankuan" .. i] = nil
                end
            end
        end
        for index = #logFrame.buttons, 1, -1 do
            logFrame.buttons[index].frame:Hide()
            tremove(logFrame.buttons, index)
        end
        logFrame.notText:Hide()
    end

    local bossNumeric = { true, true, false, false, false, true, true, true, true }
    local logNumeric = { true, false, true, true, true, false, false, true, true, true }
    local function normalizeFields(fields, numericMask)
        for index in ipairs(numericMask) do
            if numericMask[index] then
                fields[index] = tonumber(fields[index])
            end
        end
        return unpack(fields)
    end

    local function ReceiveFinish(sender, codes)
        local code = table.concat(codes)
        code = code:match("^" .. C.FRAME_BEGIN .. "(.+)" .. C.FRAME_END .. "$")
        if not code then return end
        local str
        if ns.IsBase64(code) then
            str = C_EncodingUtil.DecompressString(ns.Decode(code))
        else
            return
        end
        local info, biaoge, log = BG.Split(C.SEP_SECTION, str)
        local FB, DT, title = BG.Split(C.SEP_ROW, info)
        DT = tonumber(DT)
        if FB and DT and title then
            BG.CreateFBUI(FB, "Receive")
            draft.FB = FB
            draft.DT = DT
            draft.title = title
            for _, bossStr in ipairs({ BG.Split(C.SEP_ROW, biaoge) }) do
                if bossStr and bossStr ~= "" then
                    local bossFields = { BG.Split(C.SEP_FIELD, bossStr) }
                    local b, i, item, buyer, money,
                    qk, c1, c2, c3 = normalizeFields(bossFields, bossNumeric)
                    if b and i and draft["boss" .. b] then
                        draft["boss" .. b]["zhuangbei" .. i] = item
                        draft["boss" .. b]["maijia" .. i] = buyer
                        draft["boss" .. b]["jine" .. i] = money
                        draft["boss" .. b]["qiankuan" .. i] = qk
                        if c1 and c2 and c3 then
                            draft["boss" .. b]["color" .. i] = { c1, c2, c3 }
                        end
                    end
                end
            end
            for _, bossStr in ipairs({ BG.Split(C.SEP_ROW, log) }) do
                if bossStr and bossStr ~= "" then
                    local logFields = { BG.Split(C.SEP_FIELD, bossStr) }
                    local type, zhuangbei, itemlevel, quality, bindType,
                    maijia, jine, c1, c2, c3 = normalizeFields(logFields, logNumeric)
                    if type and zhuangbei and itemlevel and quality and bindType and maijia and jine and class then
                        local color = { 1, 1, 1 }
                        if c1 and c2 and c3 then
                            color = { c1, c2, c3 }
                        end
                        tinsert(draft.auctionLog, {
                            type = type,
                            zhuangbei = zhuangbei,
                            itemlevel = itemlevel,
                            quality = quality,
                            bindType = bindType,
                            maijia = maijia,
                            jine = jine,
                            color = color,
                        })
                    end
                end
            end

            for b = 1, Maxb[FB] + 2 do
                for i = 1, BG.GetMaxi(FB, b) do
                    if BG.ReceiveFrame[FB]["boss" .. b]["zhuangbei" .. i] then
                        BG.ReceiveFrame[FB]["boss" .. b]["zhuangbei" .. i]:SetText(draft["boss" .. b]["zhuangbei" .. i] or "")
                        BG.ReceiveFrame[FB]["boss" .. b]["maijia" .. i]:SetText(draft["boss" .. b]["maijia" .. i] or "")
                        BG.ReceiveFrame[FB]["boss" .. b]["maijia" .. i]:SetCursorPosition(0)
                        if draft["boss" .. b]["color" .. i] then
                            BG.ReceiveFrame[FB]["boss" .. b]["maijia" .. i]:SetTextColor(unpack(draft["boss" .. b]["color" .. i]))
                        end
                        BG.ReceiveFrame[FB]["boss" .. b]["jine" .. i]:SetText(draft["boss" .. b]["jine" .. i] or "")
                        local qiankuan = draft["boss" .. b]["qiankuan" .. i]
                        if qiankuan then
                            BG.ReceiveFrame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                            BG.ReceiveFrame[FB]["boss" .. b]["qiankuan" .. i].qiankuan = qiankuan
                        end
                    end
                end
            end
            for index, entry in ipairs(draft.auctionLog) do
                CreateButton(index, entry)
            end

            BG.MainFrame:Hide()
            mainFrame.FB = FB
            mainFrame:Show()

            for _, frameFB in ipairs(BG.FBtable) do
                BG["ReceiveFrame" .. frameFB]:Hide()
            end
            BG["ReceiveFrame" .. FB]:Show()

            titleText:SetText(title)
            BG.SendSystemMessage(format(L["|cff00ff00已成功接收%s的表格。"], SetClassCFF(sender)))
        end
    end

    -- 接收数据
    BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, ...)
        local prefix, msg, distType, sender = ...
        if distType == "WHISPER" then
            if prefix == channel then
                if msg:match("^" .. C.FRAME_BEGIN) then
                    receiveStart[sender] = true
                    wipe(receiveCodes)
                end
                if receiveStart[sender] then
                    tinsert(receiveCodes, msg)
                    if msg:match(C.FRAME_END .. "$") then
                        receiveStart[sender] = nil
                        ReceiveFinish(sender, receiveCodes)
                    end
                end
            elseif prefix:match(channel .. '(%d+)') then
                if msg:match("^" .. C.FRAME_BEGIN) then
                    receiveStart2[sender] = true
                    wipe(receiveCodes2)
                end
                if receiveStart2[sender] then
                    tinsert(receiveCodes2, msg)
                    if msg:match(C.FRAME_END .. "$") then
                        ReceiveFinish(sender, receiveCodes2)
                        BG.After(2, function()
                            receiveStart2[sender] = nil
                            receiveStart[sender] = nil
                        end)
                    end
                end
                receiveStart[sender] = nil
            end
        end
    end)
end

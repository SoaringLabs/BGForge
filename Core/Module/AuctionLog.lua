if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local C = ns.Protocol
local SendGateway = ns.SendGateway
local NN = ns.NN
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local Maxb = ns.Maxb

local RealmID = GetRealmID()
local player = BG.playerName

BG.Init(function()
    BiaoGe.options.showAuctionLogFrame = BiaoGe.options.showAuctionLogFrame or 1
    BiaoGe.options.auctionLogChoose = BiaoGe.options.auctionLogChoose or 1
    BiaoGe.options.autoCreateBill = BiaoGe.options.autoCreateBill or 1
    BiaoGe.auctionTrade = nil
    BG.auctionTrade = {}
    local GetErrorItem

    BG.Once("showAuctionLogFrame", 260209, function()
        BiaoGe.options.showAuctionLogFrame = 1
    end)

    local function HighlightBiaoGeSameItems(itemId, itemLink, self)
        local tableRef = {}
        local raidKey = BG.FB1
        for bossSlot = 1, Maxb[raidKey] do
            for i = 1, BG.GetMaxi(raidKey, bossSlot) do
                local zb = BG.Frame[raidKey]["boss" .. bossSlot]["zhuangbei" .. i]
                local jine = BG.Frame[raidKey]["boss" .. bossSlot]["jine" .. i]
                if zb and itemId == GetItemID(zb:GetText()) then
                    tinsert(tableRef, { zb = zb, jine = jine })
                end
            end
        end
        if #tableRef <= 1 then return end
        local frame
        for i = 1, #tableRef do
            frame = BG.CreateHighlightFrame(self, nil, { 1, 0, 0, 0 }, 4)
        end
        local t = frame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
        t:SetPoint("RIGHT", self, "RIGHT", -2, 0)
        t:SetTextColor(1, 0, 0)
        t:SetText(#tableRef)
        BG.HighlightItemAuctionLog(itemLink)
    end

    local bt = CreateFrame("Button", nil, BG.MainFrame)
    do
        bt:SetPoint("LEFT", BG.ButtonMove, "RIGHT", BG.TopLeftButtonJianGe, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["拍卖记录"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        BG.SetTextHighlightTexture(bt)
        BG.ButtonAuctionLog = bt
        BG.LayoutMainMenuButtons()

        bt:SetScript("OnClick", function(self)
            if BG.auctionLogFrame:IsVisible() then
                BiaoGe.options.showAuctionLogFrame = 0
                BG.auctionLogFrame:Hide()
            else
                BiaoGe.options.showAuctionLogFrame = 1
                BG.auctionLogFrame:Show()
            end
            BG.PlaySound(1)
        end)
        bt:SetScript("OnEnter", function(self)
            local raidKey = BG.FB1
            local total = 0
            local tint = "00FF00"
            local tableRef = BiaoGe[raidKey].auctionLog
            if tableRef then
                for i, v in ipairs(tableRef) do
                    if v.type == 1 then
                        total = total + (tonumber(v.jine) or 0)
                    end
                end
            end

            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["自动拍卖装备（拍卖WA）的记录。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(format(L["自动拍卖合计收入：|cff%s%s|r"], tint, BG.FormatNumber(total, 2)), 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", GameTooltip_Hide)
    end

    local frame, child, scroll
    local CancelAllChoose
    local drag = {}

    -- 主界面
    local f = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
    local dropDown = LibBG:Create_UIDropDownMenu(nil, f)
    do
        do
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            f:SetBackdropColor(0, 0, 0, 0.8)
            f:SetBackdropBorderColor(GetClassRGB(nil, "player", BG.borderAlpha))
            f:SetSize(220, BG.FBHeight[BG.FB1] + (BG.MainNavigationHeight or 0))
            f:SetPoint("TOPRIGHT", BG.MainFrame, "TOPLEFT", 1, 0)
            f:EnableMouse(true)
            f:SetShown(BiaoGe.options.showAuctionLogFrame == 1)
            BG.auctionLogFrame = f
            f:SetScript("OnShow", function(self)
                BG.UpdateAuctionLogFrame()
            end)
            f:SetScript("OnMouseUp", function(self)
                BG.MainFrame:GetScript("OnMouseUp")(BG.MainFrame)
            end)
            f:SetScript("OnMouseDown", function(self)
                BG.MainFrame:GetScript("OnMouseDown")(BG.MainFrame)
            end)


            BG.CreateCloseButton(f, BG.IsRetail and 0 or -5, nil, "TOPLEFT")
            f.CloseButton:HookScript("OnClick", function(self)
                BiaoGe.options.showAuctionLogFrame = 0
            end)

            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", f, "TOP", 0, -5)
            BG.auctionLogFrame.title = t

            -- 提示
            local bt = CreateFrame("Button", nil, f)
            bt:SetSize(28, 28)
            bt:SetPoint("LEFT", BG.auctionLogFrame.title, "RIGHT", 0, -1)
            local textureRef = bt:CreateTexture()
            textureRef:SetAllPoints()
            textureRef:SetTexture(616343)
            bt:SetHighlightTexture(616343)
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
                GameTooltip:ClearLines()
                local red, green, blue = t:GetTextColor()
                GameTooltip:AddLine(t:GetText(), red, green, blue)
                GameTooltip:AddLine(L["自动拍卖装备（拍卖WA）的记录。该记录会跟随清空表格一起被清空。"], 1, 0.82, 0, true)
                GameTooltip:AddLine(" ", 1, 0.82, 0, true)
                GameTooltip:AddLine(L["操作提示："], 1, 1, 1, true)
                GameTooltip:AddLine(AddTexture("RIGHT") .. L["点击一个装备可以打开菜单"], 1, 0.82, 0, true)
                GameTooltip:AddLine(L["未拍和流拍页可以按住CTRL、SHIFT，或者框选来多选装备，便于团长批量发起拍卖"], 1, 0.82, 0, true)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)
        end

        -- 筛选显示
        do
            local buttons = {}
            local widthValue = 48
            local optionCount = {
                { name = L["全部"], id = 1, row = 1, width = 0, },
                { name = L["未拍"], id = 4, row = 1, width = widthValue, },
                { name = L["拍重"], id = 7, row = 1, width = widthValue * 2, },
                { name = L["我买的"], id = 6, row = 1, width = widthValue * 3, },
                { name = L["流拍"], id = 3, row = 2, width = 0, },
                { name = L["成功"], id = 2, row = 2, width = widthValue, },
                { name = L["成功(未交易)"], id = 5, row = 2, width = widthValue * 2, },
            }
            local buttonGroup = CreateFrame("Frame", nil, f)
            buttonGroup:SetPoint("TOPLEFT", 7, -38)
            buttonGroup:SetSize(1, 1)
            for slot = 1, #optionCount do
                local v = optionCount[slot]
                local bt = CreateFrame("CheckButton", nil, buttonGroup, "UIRadioButtonTemplate")
                bt:SetPoint("LEFT", v.width, -(v.row - 1) * 20)
                bt:SetSize(15, 15)
                tinsert(buttons, bt)
                bt.Text = bt:CreateFontString()
                bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                bt.Text:SetPoint("LEFT", bt, "RIGHT", 0, 0)
                bt.Text:SetText(v.name)
                bt.Text:SetTextColor(1, .82, 0)
                bt:SetHitRectInsets(0, -bt.Text:GetWidth(), -5, -5)

                if v.id == BiaoGe.options.auctionLogChoose then
                    bt:SetChecked(true)
                    bt.Text:SetTextColor(0, 1, 0)
                end

                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    for _, radioButton in ipairs(buttons) do
                        if radioButton ~= self then
                            radioButton:SetChecked(false)
                            radioButton.Text:SetTextColor(1, .82, 0)
                        end
                    end
                    self:SetChecked(true)
                    self.Text:SetTextColor(0, 1, 0)
                    BiaoGe.options.auctionLogChoose = v.id
                    BG.auctionLogFrame.changeFrame:Hide()
                    BG.UpdateAuctionLogFrame()
                    LibBG:CloseDropDownMenus()
                    if BG.StartAucitonFrame and BG.StartAucitonFrame:IsVisible() then
                        BG.StartAucitonFrame:Hide()
                    end
                end)
            end

            local l = buttons[1]:CreateLine()
            l:SetColorTexture(RGB("808080", 1))
            l:SetStartPoint("BOTTOMLEFT", 0, -2)
            l:SetEndPoint("BOTTOMLEFT", 205, -2)
            l:SetThickness(1)

            local l = buttons[5]:CreateLine()
            l:SetColorTexture(RGB("808080", 1))
            l:SetStartPoint("BOTTOMLEFT", 0, -2)
            l:SetEndPoint("BOTTOMLEFT", 195, -2)
            l:SetThickness(1)
        end

        -- 滚动框
        do
            frame = CreateFrame("Frame", nil, BG.auctionLogFrame, "BackdropTemplate")
            frame:SetBackdrop({
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            frame:SetBackdropBorderColor(.5, .5, .5, .5)
            frame:SetBackdropColor(0, 0, 0, 0.8)
            frame:SetPoint("TOPLEFT", 5, -73)
            frame:SetPoint("BOTTOMRIGHT", -5, 115)
            frame:EnableMouse(true)

            scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
            scroll:SetPoint("TOPLEFT", 5, -5)
            scroll:SetPoint("BOTTOMRIGHT", -26, 5)
            scroll.ScrollBar.scrollStep = BG.scrollStep
            frame.scroll = scroll
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll)

            child = CreateFrame("Frame", nil, scroll)
            child:SetAllPoints()
            child:SetWidth(scroll:GetWidth())
            child:SetHeight(scroll:GetHeight())
            child:RegisterForDrag("LeftButton")
            scroll:SetScrollChild(child)

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
            BG.auctionLogFrame.notText = t
        end

        -- 开始拍卖
        do
            local bt = BG.CreateButton(frame)
            -- bt:SetPoint("TOPLEFT", frame, "BOTTOM", -10, 30)
            -- bt:SetPoint("BOTTOMRIGHT", frame, -22, 2)
            bt:SetPoint("TOPLEFT", frame, "TOP", -10, -2)
            bt:SetPoint("BOTTOMRIGHT", frame, 'TOPRIGHT', -24, -26)
            bt:SetFrameLevel(110)
            bt:SetText(L["开始拍卖"])
            bt:RegisterForClicks("AnyUp")
            bt:Hide()
            BG.auctionLogFrame.ButtonStartAuction = bt
            bt:SetScript("OnClick", function(self, clickedButton)
                BG.PlaySound(1)
                if BiaoGe.options.auctionLogChoose == 3 then
                    local db = BiaoGe[BG.FB1].auctionLog
                    local isGen2 = BiaoGe.Auction.gen == 2
                    local mod = BiaoGe.Auction.mod
                    local resetThreshold = max(tonumber(BiaoGe.Auction.resetThreshold) or 0, 10)
                    local positions = {}
                    for _, v in ipairs(BG.auctionLogFrame.choosed) do
                        if v.money and v.index then
                            tinsert(positions, v.index)
                        end
                    end
                    sort(positions, function(leftValue, rightValue)
                        return leftValue > rightValue
                    end)
                    for _, index in ipairs(positions) do
                        if db and db[index] and db[index].type == 2 then
                            tremove(db, index)
                        end
                    end
                    local delay = 0
                    for _, v in ipairs(BG.auctionLogFrame.choosed) do
                        if v.money then
                            BG.After(delay, function()
                                BG.SendStartAuctionMsg(isGen2, v.id, v.money, 20, mod, v.link, resetThreshold)
                            end)
                            delay = delay + 1
                        end
                    end
                elseif BiaoGe.options.auctionLogChoose == 4 then
                    BG.StartAuction(BG.auctionLogFrame.choosed, bt, nil, true)
                    if BG.StartAucitonFrame and BG.StartAucitonFrame:IsVisible() then
                        BG.StartAucitonFrame:ClearAllPoints()
                        BG.StartAucitonFrame:SetPoint("TOP", frame, 0, 0)
                    end
                end
                CancelAllChoose()
            end)

            local bt = BG.CreateButton(BG.auctionLogFrame.ButtonStartAuction)
            -- bt:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 2, 30)
            -- bt:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -8, 2)
            bt:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
            bt:SetPoint("BOTTOMRIGHT", frame, "TOP", -10, -26)
            bt:SetFrameLevel(110)
            bt:SetText(L["取消选择"])
            BG.auctionLogFrame.ButtonCancelChoose = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                CancelAllChoose()
            end)
        end

        -- 合计收入
        do
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 2, -5)
            t:SetTextColor(1, 1, 1)
            t:SetJustifyH("LEFT")
            t:SetWordWrap(false)
            BG.auctionLogFrame.sumText = t
        end

        -- 增加
        do
            local bt = BG.CreateButton(BG.auctionLogFrame)
            bt:SetSize(28, 20)
            bt:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -3)
            bt:SetText("+")
            BG.auctionLogFrame.ButtonAdd = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                if BG.auctionLogFrame.changeFrame:IsVisible() and BG.auctionLogFrame.changeFrame.type == "new" then
                    BG.auctionLogFrame.changeFrame:Hide()
                else
                    BG.auctionLogFrame.changeFrame:Hide()
                    BG.auctionLogFrame.changeFrame.type = "new"
                    BG.auctionLogFrame.changeFrame.info = {}
                    BG.auctionLogFrame.changeFrame:Show()
                    BG.auctionLogFrame.changeFrame:ClearAllPoints()
                    BG.auctionLogFrame.changeFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
                end
            end)
        end

        -- 搜索
        do
            -- local edit = CreateFrame("EditBox", nil, f, BG.editSearchTemplate)
            local editBoxRef = CreateFrame("EditBox", nil, f, 'SearchBoxTemplate')
            editBoxRef:SetSize(f:GetWidth() - 20, 22)
            editBoxRef:SetPoint("TOPLEFT", BG.auctionLogFrame.sumText, "BOTTOMLEFT", 7, -5)
            editBoxRef.Instructions:SetText(L["搜索装备/买家/金额"])
            BG.auctionLogFrame.serachEdit = editBoxRef
            editBoxRef:SetScript("OnMouseDown", function(self, clickedButton)
                if clickedButton == "RightButton" then
                    self:SetEnabled(false)
                    self:SetText("")
                end
            end)
            editBoxRef:SetScript("OnMouseUp", function(self, clickedButton)
                self:SetEnabled(true)
            end)
            editBoxRef:SetScript("OnEditFocusGained", function(self)
                BG.lastfocus = self
            end)
        end
    end

    -- 生成账单
    do
        -- 生成表格账单
        do
            function GetErrorItem(tableRef, logQuantity)
                local raidKey = BG.FB1
                tableRef = tableRef or BiaoGe[raidKey].auctionLog
                local items = {}
                for position, v in ipairs(tableRef or {}) do
                    if v.type == 1 then
                        local itemID = GetItemID(v.zhuangbei)
                        if not items[itemID] then
                            items[itemID] = {}
                            items[itemID].info = {}
                            items[itemID].indexs = {}
                            items[itemID].link = v.zhuangbei
                            items[itemID].logCount = 0
                        end
                        tinsert(items[itemID].info, v)
                        tinsert(items[itemID].indexs, position)
                        items[itemID].logCount = items[itemID].logCount + 1
                    end
                end
                if next(items) then
                    if logQuantity then
                        local identifiers = {}
                        for itemID, v in pairs(items) do
                            tinsert(identifiers, itemID)
                        end
                        for _, itemID in ipairs(identifiers) do
                            if items[itemID].logCount <= 1 then
                                items[itemID] = nil
                            end
                        end
                    end
                    BG.PairFBItem(function(equipment)
                        local itemID = GetItemID(equipment:GetText())
                        if itemID and items[itemID] then
                            items[itemID].bgCount = items[itemID].bgCount or 0
                            items[itemID].bgCount = items[itemID].bgCount + 1
                        end
                    end)
                    local tableRef = {}
                    for itemID, v in pairs(items) do
                        if not v.bgCount or v.bgCount < v.logCount then
                            v.itemID = itemID
                            v.bgCount = v.bgCount or 0
                            tinsert(tableRef, v)
                        end
                    end
                    if next(tableRef) then
                        return tableRef
                    end
                end
            end

            local function HasQK()
                local has
                BG.PairFBItem(function(itemRef, purchaser, price, bossSlot, i)
                    if BiaoGe[BG.FB1]["boss" .. bossSlot]["qiankuan" .. i] then
                        has = true
                        return true
                    end
                end)
                return has
            end

            local bt = BG.CreateButton(BG.auctionLogFrame)
            bt:SetSize(110, 25)
            bt:SetPoint("BOTTOMLEFT", BG.auctionLogFrame, 5, 5)
            bt:SetText(L["生成表格账单"])
            BG.auctionLogFrame.ButtonCreateLedger = bt
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(L["根据自动拍卖记录，直接覆盖表格里每件装备所对应的买家和金额。"], 1, 0.82, 0, true)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["该功能仅修改买家和金额，如果表格里的装备栏是空的，则什么都不会发生。"], 1, 0.82, 0, true)
                local errorList = GetErrorItem()
                if errorList then
                    GameTooltip:AddLine(" ", 1, 0, 0, true)
                    GameTooltip:AddLine(L["以下装备可能存在重复拍卖："], 1, 0, 0, true)
                    for _, v in ipairs(errorList) do
                        local iconRef = select(5, GetItemInfoInstant(v.itemID))
                        GameTooltip:AddLine(L["%s%s：拍卖成功%s件，表格实际只有%s件"]:format(AddTexture(iconRef), v.link, v.logCount, v.bgCount), 1, .82, 0)
                    end
                end
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)
            bt:SetScript("OnClick", function(self)
                if HasQK() then
                    local name = "BiaoGe_CreateBillByAuctionLog"
                    if not StaticPopupDialogs[name] then
                        StaticPopupDialogs[name] = {
                            text = L["你的当前表格含有|cffff0000欠款|r，生成表格账单可能会导致欠款金额与欠款人对应不上。\n\n确定继续生成表格账单吗？"],
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
                    StaticPopupDialogs[name].OnAccept = function()
                        BG.PlaySound(2)
                        BG.CreateBillByAuctionLog()
                    end
                    StaticPopup_Show(name)
                else
                    BG.PlaySound(2)
                    BG.CreateBillByAuctionLog()
                end
            end)

            local function ClearAuctionLogFields(raidKey)
                for bossSlot = 1, Maxb[raidKey] - 1 do
                    local bossKey = "boss" .. bossSlot
                    local frameBoss = BG.Frame[raidKey][bossKey]
                    local dataBoss = BiaoGe[raidKey][bossKey]
                    for i = 1, BG.GetMaxi(raidKey, bossSlot) do
                        local zhuangbei = frameBoss["zhuangbei" .. i]
                        local maijia = frameBoss["maijia" .. i]
                        local jine = frameBoss["jine" .. i]
                        if zhuangbei then
                            maijia:SetText("")
                            maijia:SetTextColor(1, 1, 1)
                            dataBoss["maijia" .. i] = nil
                            for fieldKey, v in pairs(BG.playerClass) do
                                dataBoss[fieldKey .. i] = nil
                            end
                            jine:SetText("")
                            dataBoss["jine" .. i] = nil
                        end
                    end
                end
            end

            local function FillAuctionLogFields(raidKey)
                local logs = BiaoGe[raidKey].auctionLog
                for position = #logs, 1, -1 do
                    local v = logs[position]
                    if v.type == 1 then
                        local itemId = GetItemID(v.zhuangbei)
                        for bossSlot = 1, Maxb[raidKey] - 1 do
                            local bossKey = "boss" .. bossSlot
                            local frameBoss = BG.Frame[raidKey][bossKey]
                            local dataBoss = BiaoGe[raidKey][bossKey]
                            local completed
                            for i = 1, BG.GetMaxi(raidKey, bossSlot) do
                                local zhuangbei = frameBoss["zhuangbei" .. i]
                                local maijia = frameBoss["maijia" .. i]
                                local jine = frameBoss["jine" .. i]
                                if zhuangbei and GetItemID(zhuangbei:GetText()) == itemId and
                                    maijia:GetText() == "" and jine:GetText() == ""
                                then
                                    completed = true
                                    maijia:SetText(v.maijia or "")
                                    dataBoss["maijia" .. i] = v.maijia
                                    if v.color then
                                        maijia:SetTextColor(unpack(v.color))
                                    else
                                        maijia:SetTextColor(1, 1, 1)
                                    end
                                    for fieldKey in pairs(BG.playerClass) do
                                        dataBoss[fieldKey .. i] = v[fieldKey]
                                    end

                                    jine:SetText(v.jine or "")
                                    dataBoss["jine" .. i] = v.jine
                                    break
                                end
                            end
                            if completed then break end
                        end
                    end
                end
            end

            function BG.CreateBillByAuctionLog(raidKey)
                raidKey = raidKey or BG.FB2 or BG.FB1
                if not BiaoGe[raidKey].auctionLog then return end
                ClearAuctionLogFields(raidKey)
                BiaoGe[raidKey].tradeTbl = {}
                FillAuctionLogFields(raidKey)

                -- 已移除 CP 货币结算挂载点（第三方付费模块 BGV 提供）
            end

            function BG.IsAutoCreateBill()
                return BiaoGe.options.autoCreateBill == 1 and not BG.IsML
            end
        end

        -- 生成对账单
        do
            local bt = BG.CreateButton(BG.auctionLogFrame)
            bt:SetSize(95, 25)
            bt:SetPoint("BOTTOMRIGHT", BG.auctionLogFrame, -5, 5)
            bt:SetText(L["生成对账单"])
            BG.auctionLogFrame.ButtonCreateDuiZhang = bt
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(L["根据自动拍卖记录，生成一个对账单。"], 1, 0.82, 0, true)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(2)
                local FB = BG.FB1
                if not BiaoGe[FB].auctionLog then return end
                local duizhang = {}
                duizhang.addons = "biaoge"
                duizhang.FB = FB
                duizhang.t = GetServerTime()
                duizhang.time = date("%m-%d %H:%M:%S", GetServerTime())
                duizhang.msgTbl = {}
                duizhang.player = BG.STC_g1(L["自动拍卖记录"])
                duizhang.sumjine = 0
                duizhang.zhangdan = {}
                local ordinal = 0
                for i, v in ipairs(BiaoGe[FB].auctionLog) do
                    if v.type == 1 then
                        ordinal = ordinal + 1
                        duizhang.zhangdan[ordinal] = BG.Copy(v)
                        duizhang.zhangdan[ordinal].type = nil
                        duizhang.zhangdan[ordinal].time = nil
                        duizhang.zhangdan[ordinal].bindType = nil
                        duizhang.zhangdan[ordinal].itemlevel = nil
                        duizhang.zhangdan[ordinal].quality = nil
                        duizhang.sumjine = duizhang.sumjine + (tonumber(v.jine) or 0)
                    end
                end
                tinsert(BiaoGe.duizhang, duizhang)
                BG.DuiZhangList()
            end)
        end

        -- 自动生成账单
        do
            local bt = CreateFrame("CheckButton", nil, f, "ChatConfigCheckButtonTemplate")
            bt:SetSize(30, 30)
            bt:SetPoint("BOTTOMLEFT", BG.auctionLogFrame.ButtonCreateLedger, "TOPLEFT", 0, 0)
            bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            bt.Text:SetText(AddTexture("QUEST") .. L["自动生成表格账单"])
            bt.Text:SetWidth(min(bt.Text:GetWidth() + 20, BG.auctionLogFrame:GetWidth() - 40))
            bt.Text:SetWordWrap(false)
            bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
            bt:SetChecked(BiaoGe.options.autoCreateBill == 1)
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.Text:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(L["当一个装备拍卖成功时，会根据拍卖记录，自动填写表格里该装备所对应的买家和金额。"], 1, 0.82, 0, true)
                GameTooltip:AddLine(" ", 1, 0.82, 0, true)
                GameTooltip:AddLine(L["启用该功能时，交易记账会被自动禁用，以免记账冲突。"], 1, 0.82, 0, true)
                GameTooltip:AddLine(" ", 1, 0.82, 0, true)
                GameTooltip:AddLine(L["注意：如果你是团长或物品分配者，该功能不会生效。团长或物品分配者仍会使用更为可靠的交易记账。"], 1, 0, 0, true)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BiaoGe.options.autoCreateBill = self:GetChecked() and 1 or 0
                BG.UpdateAutoCreateBillButton()
            end)

            function BG.UpdateAutoCreateBillButton()
                bt:SetChecked(BiaoGe.options.autoCreateBill == 1)
                BG.options["buttonautoCreateBill"]:SetChecked(BiaoGe.options.autoCreateBill == 1)
            end
        end
    end

    -- 增加记录
    do
        local f = CreateFrame("Frame", nil, BG.auctionLogFrame, "BackdropTemplate")
        do
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 10,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f:SetBackdropColor(0, 0, 0, 0.8)
            f:SetSize(220, 140)
            f:SetFrameLevel(117)
            f:EnableMouse(true)
            f:Hide()
            BG.auctionLogFrame.changeFrame = f
            f:SetScript("OnMouseDown", function(self)
                if BG.FrameZhuangbeiList then
                    BG.FrameZhuangbeiList:Hide()
                end
                BG.ClearFocus()
            end)
            f:SetScript("OnShow", function(self)
                if BG.auctionLogFrame.changeFrame.type == "change" then
                    f.item:Show()
                    f.zhuangbei:Hide()
                    f.title:SetText(BG.auctionLogFrame.changeFrame.typeText)
                    f.ButtonSure:Enable()
                elseif BG.auctionLogFrame.changeFrame.type == "new" then
                    f.item:Hide()
                    f.zhuangbei:Show()
                    f.zhuangbei:SetFocus()
                    f.title:SetText(L["增加记录"])
                    f.ButtonSure:Disable()
                elseif BG.auctionLogFrame.changeFrame.type == "set" then
                    f.item:Show()
                    f.zhuangbei:Hide()
                    f.title:SetText(L["设为已拍"])
                    f.ButtonSure:Disable()
                end
                f.zhuangbei:SetText("")
                f.maijia:SetText("")
                f.jine:SetText("")
            end)

            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", 0, -10)
            f.title = t
        end
        -- 装备
        do
            local title = f:CreateFontString()
            title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            title:SetPoint("TOPLEFT", 5, -35)
            title:SetText(L["装备："])
            title:SetTextColor(1, 0.82, 0)
            title:SetWidth(60)
            title:SetJustifyH("RIGHT")
            title:SetWordWrap(false)

            -- 修改装备
            do
                local _f = CreateFrame("Frame", nil, BG.auctionLogFrame.changeFrame, "BackdropTemplate")
                _f:SetPoint("LEFT", title, "RIGHT", 10, 0)
                _f:SetSize(120, 15)
                _f:SetHyperlinksEnabled(true)
                local t = _f:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetAllPoints()
                t:SetJustifyH("LEFT")
                t:SetWordWrap(false)
                f.item = t
                t.title = title
                _f:SetScript("OnHyperlinkEnter", function(self, itemLink, text, clickedButton)
                    local itemId = GetItemInfoInstant(itemLink)
                    if itemId then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -self:GetWidth() + t:GetWrappedWidth(), 0)
                        GameTooltip:ClearLines()
                        GameTooltip:SetHyperlink(BG.SetSpecIDToLink(itemLink))
                    end
                end)
                _f:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
            end

            -- 手动添加装备
            do
                local editBoxRef = CreateFrame("EditBox", nil, f, BG.editTemplate)
                editBoxRef:SetSize(110, 20)
                editBoxRef:SetPoint("LEFT", title, "RIGHT", 10, 0)
                editBoxRef:SetAutoFocus(false)
                f.zhuangbei = editBoxRef
                editBoxRef:SetScript("OnEditFocusGained", function(self)
                    self:HighlightText()
                    BG.lastfocus = self
                end)
                editBoxRef:SetScript("OnTextChanged", function(self)
                    if GetItemID(self:GetText()) and GetItemInfoInstant(self:GetText()) then
                        f.ButtonSure:Enable()
                    else
                        f.ButtonSure:Disable()
                    end
                end)
                editBoxRef:SetScript("OnMouseDown", function(self, clickedButton)
                    if BG.auctionLogFrame.changeFrame.type == "set" then return end
                    if clickedButton == "RightButton" then
                        self:SetEnabled(false)
                        self:SetText("")
                        return
                    end
                end)
                editBoxRef:SetScript("OnMouseUp", function(self, clickedButton)
                    if BG.auctionLogFrame.changeFrame.type == "set" then return end
                    local infoType, itemId, linkText = GetCursorInfo()
                    if infoType == "item" then
                        self:SetText(linkText)
                        self:ClearFocus()
                        ClearCursor()
                    end
                    self:SetEnabled(true)
                end)
                editBoxRef:SetScript("OnEnter", function(self, clickedButton)
                    if not tonumber(self:GetText()) then
                        local itemLink = self:GetText()
                        local itemId = GetItemInfoInstant(itemLink)
                        if itemId then
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:SetHyperlink(BG.SetSpecIDToLink(itemLink))
                        end
                    end
                end)
                editBoxRef:SetScript("OnLeave", GameTooltip_Hide)

                -- 提示
                local bt = CreateFrame("Button", nil, editBoxRef)
                bt:SetSize(28, 28)
                bt:SetPoint("LEFT", editBoxRef, "RIGHT", 0, -1)
                f.zhuangbei.tip = bt
                local textureRef = bt:CreateTexture()
                textureRef:SetAllPoints()
                textureRef:SetTexture(616343)
                bt:SetHighlightTexture(616343)
                bt:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["添加装备"], 1, 1, 1, true)
                    GameTooltip:AddLine(L["按住Shift+点击表格/背包/聊天框装备；直接把装备拖到格子里"], 1, 0.82, 0, true)
                    GameTooltip:Show()
                end)
                bt:SetScript("OnLeave", GameTooltip_Hide)
            end
        end
        -- 买家
        do
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", f.item.title, "BOTTOMLEFT", 0, -7)
            t:SetText(L["买家："])
            t:SetTextColor(1, 0.82, 0)
            t:SetWidth(60)
            t:SetJustifyH("RIGHT")
            t:SetWordWrap(false)
            local editBoxRef = CreateFrame("EditBox", nil, f, BG.editTemplate)
            editBoxRef:SetSize(110, 20)
            editBoxRef:SetPoint("LEFT", t, "RIGHT", 10, 0)
            editBoxRef:SetAutoFocus(false)
            BG.SetEditStickyFocus(editBoxRef)
            editBoxRef.title = t
            f.maijia = editBoxRef
            editBoxRef:SetScript("OnTextChanged", function(self)
                if self:GetText() == "" then
                    self:SetTextColor(1, 1, 1)
                    BG.auctionLogFrame.changeFrame.info.maijia = nil
                    BG.auctionLogFrame.changeFrame.info.color = nil
                    if BG.FrameMaijiaList then
                        BG.FrameMaijiaList:Hide()
                    end
                else
                    BG.auctionLogFrame.changeFrame.info.maijia = self:GetText()
                    BG.auctionLogFrame.changeFrame.info.color = { self:GetTextColor() }
                end
                if BG.auctionLogFrame.changeFrame.type == "set" then
                    if self:GetText() ~= "" or f.maijia:GetText() ~= "" then
                        f.ButtonSure:Enable()
                    else
                        f.ButtonSure:Disable()
                    end
                end
            end)
            editBoxRef:SetScript("OnEditFocusGained", function(self)
                self:HighlightText()
                BG.lastfocus = self
                BG.SetListmaijia(self, true, nil, true)
            end)
            editBoxRef:SetScript("OnEditFocusLost", function(self)
                self:ClearHighlightText()
                if BG.FrameMaijiaList then
                    BG.FrameMaijiaList:Hide()
                end
            end)
            editBoxRef:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()
                if BG.FrameMaijiaList then
                    BG.FrameMaijiaList:Hide()
                end
            end)
            editBoxRef:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    self:SetEnabled(false)
                    self:SetText("")
                    if BG.lastfocus then
                        BG.lastfocus:ClearFocus()
                    end
                end
            end)
            editBoxRef:SetScript("OnMouseUp", function(self, enter)
                self:SetEnabled(true)
            end)
        end
        -- 金额
        do
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", f.maijia.title, "BOTTOMLEFT", 0, -7)
            t:SetText(L["金额："])
            t:SetTextColor(1, 0.82, 0)
            t:SetWidth(60)
            t:SetJustifyH("RIGHT")
            t:SetWordWrap(false)
            local editBoxRef = CreateFrame("EditBox", nil, f, BG.editTemplate)
            editBoxRef:SetSize(110, 20)
            editBoxRef:SetPoint("LEFT", t, "RIGHT", 10, 0)
            editBoxRef:SetAutoFocus(false)
            editBoxRef:SetNumeric(true)
            BG.SetEditStickyFocus(editBoxRef)
            f.jine = editBoxRef
            editBoxRef:SetScript("OnTextChanged", function(self)
                BG.UpdateTwo0(self)
                if self:GetText() == "" then
                    BG.auctionLogFrame.changeFrame.info.jine = nil
                else
                    BG.auctionLogFrame.changeFrame.info.jine = self:GetText()
                end
                if BG.auctionLogFrame.changeFrame.type == "set" then
                    if self:GetText() ~= "" or f.maijia:GetText() ~= "" then
                        f.ButtonSure:Enable()
                    else
                        f.ButtonSure:Disable()
                    end
                end
            end)
            editBoxRef:SetScript("OnEditFocusGained", function(self)
                self:HighlightText()
                BG.lastfocus = self
                local f = BG.CreateNumFrame(BG.auctionLogFrame.changeFrame)
                if f then
                    f:ClearAllPoints()
                    f:SetPoint("TOPLEFT", BG.auctionLogFrame.changeFrame, "TOPRIGHT", 0, 0)
                end
            end)
            editBoxRef:HookScript("OnEditFocusLost", function(self)
                if BG.FrameNumFrame then
                    BG.FrameNumFrame:Hide()
                end
            end)
            editBoxRef:SetScript("OnEnterPressed", function(self)
                f.ButtonSure:GetScript("OnClick")()
            end)
            editBoxRef:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    self:SetEnabled(false)
                    self:SetText("")
                    if BG.lastfocus then
                        BG.lastfocus:ClearFocus()
                    end
                end
            end)
            editBoxRef:SetScript("OnMouseUp", function(self, enter)
                self:SetEnabled(true)
            end)
        end
        -- 按钮
        do
            local bt = BG.CreateButton(f)
            bt:SetSize(95, 22)
            bt:SetPoint("BOTTOMLEFT", 10, 10)
            bt:SetText(L["确定"])
            f.ButtonSure = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                local raidKey = BG.FB1
                if BG.auctionLogFrame.changeFrame.type == "change" then
                    local i = BG.auctionLogFrame.changeFrame.info.num
                    if not BiaoGe[raidKey].auctionLog or not BiaoGe[raidKey].auctionLog[i] then return end
                    if not (BG.auctionLogFrame.changeFrame.info.maijia or BG.auctionLogFrame.changeFrame.info.jine) then
                        BiaoGe[raidKey].auctionLog[i].type = 2
                        BiaoGe[raidKey].auctionLog[i].maijia = nil
                        BiaoGe[raidKey].auctionLog[i].jine = nil
                    else
                        BiaoGe[raidKey].auctionLog[i].type = 1
                        BiaoGe[raidKey].auctionLog[i].maijia = BG.auctionLogFrame.changeFrame.info.maijia or ""
                        BiaoGe[raidKey].auctionLog[i].jine = BG.auctionLogFrame.changeFrame.info.jine or ""
                    end
                    for fieldKey in pairs(BG.playerClass) do
                        BiaoGe[raidKey].auctionLog[i][fieldKey] = BG.auctionLogFrame.changeFrame.info[fieldKey]
                    end
                    f:Hide()
                    BG.UpdateAuctionLogFrame(true)
                elseif BG.auctionLogFrame.changeFrame.type == "new" or BG.auctionLogFrame.changeFrame.type == "set" then
                    local zhuangbei
                    if BG.auctionLogFrame.changeFrame.type == "new" then
                        zhuangbei = f.zhuangbei:GetText()
                    elseif BG.auctionLogFrame.changeFrame.type == "set" then
                        zhuangbei = f.item:GetText():gsub("|T.+|t", ""):gsub(":|h", ":|h["):gsub("|h|r", "]|h|r")
                    end

                    local name, itemLink, quality, itemLevel, _, _, _, _, equipLocation, Texture,
                    _, typeId, subclassId, bindType = GetItemInfo(zhuangbei)
                    local firstArg = {
                        time = GetServerTime(),
                        zhuangbei = zhuangbei,
                        itemlevel = itemLevel,
                        quality = quality,
                        bindType = bindType,
                    }

                    if not (BG.auctionLogFrame.changeFrame.info.maijia or BG.auctionLogFrame.changeFrame.info.jine) then
                        firstArg.type = 2
                        firstArg.maijia = nil
                        firstArg.jine = nil
                    else
                        firstArg.type = 1
                        firstArg.maijia = BG.auctionLogFrame.changeFrame.info.maijia or ""
                        firstArg.jine = BG.auctionLogFrame.changeFrame.info.jine or ""
                    end
                    for fieldKey in pairs(BG.playerClass) do
                        firstArg[fieldKey] = BG.auctionLogFrame.changeFrame.info[fieldKey]
                    end
                    BiaoGe[raidKey].auctionLog = BiaoGe[raidKey].auctionLog or {}
                    tinsert(BiaoGe[raidKey].auctionLog, firstArg)
                    f:Hide()
                    if BG.auctionLogFrame.changeFrame.type == "new" then
                        BG.UpdateAuctionLogFrame(nil, true)
                    elseif BG.auctionLogFrame.changeFrame.type == "set" then
                        BG.UpdateAuctionLogFrame(true, true)
                    end
                end
            end)

            local bt = BG.CreateButton(f)
            bt:SetSize(95, 22)
            bt:SetPoint("BOTTOMRIGHT", -10, 10)
            bt:SetText(CANCEL)
            bt:SetScript("OnClick", function(self)
                f:Hide()
            end)
        end
    end

    function BG.SetAuctionLogItemState(v, status, keepAmount)
        -- 流拍
        if status ~= 2 then
            BG.UpdateAuctionLogFrame(true, true)
            return
        end
        v.type = 2
        v.maijia = nil
        if not keepAmount then
            v.jine = nil
        end
        v.trade = nil
        for fieldKey in pairs(BG.playerClass) do
            v[fieldKey] = nil
        end
        BG.UpdateAuctionLogFrame(true, true)
    end

    BG.auctionLogFrame.auctioning = {}
    BG.auctionLogFrame.buttons = {}
    BG.auctionLogFrame.choosed = {}
    local lastChoose, needDeleteItem
    local reAuctionSendCD = 0

    local function DeleteLiuPaiAuctionLog() -- 在流拍列表重拍一个装备时，该装备的流拍记录会被删除
        local raidKey = BG.FB1
        if not needDeleteItem or not BiaoGe[raidKey].auctionLog then return end
        for i, v in ipairs(BiaoGe[raidKey].auctionLog) do
            if v == needDeleteItem.v then
                tremove(BiaoGe[raidKey].auctionLog, i)
                BG.UpdateAuctionLogFrame(true, true)
                return
            end
        end
    end
    local function AddNeedDeleteItem(position, v)
        needDeleteItem = { i = position, v = v }
    end

    local START_AUCTION_BUTTON_LABELS = {
        [3] = L["一键重拍"],
        [4] = L["开始拍卖"],
    }

    local function UpdateButtonStartAuction()
        local bt = BG.auctionLogFrame.ButtonStartAuction
        local label = START_AUCTION_BUTTON_LABELS[BiaoGe.options.auctionLogChoose]
        if label then
            bt:SetText(label)
        else
            bt:Hide()
        end
        if #BG.auctionLogFrame.choosed > 0 then
            bt:Show()
            if BG.IsML then
                bt:Enable()
            else
                bt:Disable()
            end
        else
            bt:Hide()
        end
    end
    -- 右键菜单
    local CreateMenu, AddLogLine
    do
        function AddLogLine(v)
            local timeText = ''
            if v.time then
                timeText = L['剩余%s秒时出价']:format(v.time)
            end
            return format(L['%s、%s（%s）|cffff0000%s|r'], v.i, v.money, v.player, timeText)
        end

        local function MenuTitleEntry(text)
            return {
                isTitle = true,
                text = text,
                notCheckable = true,
            }
        end

        local function MenuBlankEntry()
            return {
                isTitle = true,
                text = "   ",
                notCheckable = true,
            }
        end

        local function MenuCancelEntry()
            return {
                text = CANCEL,
                notCheckable = true,
                func = function(self)
                    LibBG:CloseDropDownMenus()
                end,
            }
        end

        function CreateMenu(f, index, v, unsoldMode, link, icon)
            local FB = BG.FB1
            local menuEntries
            local function GetLogTooltipText()
                local text = ""
                local hasMore = true
                local limit = 80
                if #v.log > limit then
                    for i = 1 + (#v.log - limit), #v.log do
                        local _v = v.log[i]
                        if _v.i == 1 then
                            hasMore = false
                        end
                        text = text .. AddLogLine(_v) .. NN
                    end
                else
                    for i, _v in ipairs(v.log) do
                        if _v.i == 1 then
                            hasMore = false
                        end
                        text = text .. AddLogLine(_v) .. NN
                    end
                end

                if hasMore then
                    text = BG.STC_dis("......\n") .. text
                end
                return text
            end
            if unsoldMode then
                menuEntries = {
                    MenuTitleEntry(link:gsub("%[", ""):gsub("%]", "")),
                    MenuBlankEntry(),
                    {
                        text = L["设为已拍"],
                        notCheckable = true,
                        func = function()
                            BG.auctionLogFrame.changeFrame:Hide()
                            BG.auctionLogFrame.changeFrame.type = "set"
                            BG.auctionLogFrame.changeFrame.info = {}
                            BG.auctionLogFrame.changeFrame:Show()
                            BG.auctionLogFrame.changeFrame:ClearAllPoints()
                            BG.auctionLogFrame.changeFrame:SetPoint("TOP", f, "BOTTOM", 10, 0)
                            BG.auctionLogFrame.changeFrame.item:SetText(AddTexture(icon) .. v.zhuangbei:gsub("%[", ""):gsub("%]", ""))
                        end
                    },
                    {
                        text = L["设为流拍"],
                        notCheckable = true,
                        func = function()
                            BiaoGe[FB].auctionLog = BiaoGe[FB].auctionLog or {}
                            tinsert(BiaoGe[FB].auctionLog, {
                                type = 2,
                                time = GetServerTime(),
                                zhuangbei = v.zhuangbei,
                                itemlevel = v.level,
                                quality = v.quality,
                                bindType = v.bindType,
                            })
                            BG.UpdateAuctionLogFrame(true, true)
                        end
                    },
                    MenuBlankEntry(),
                    MenuCancelEntry(),
                }
                if not BG.IsML and IsInRaid(1) then
                    tinsert(menuEntries, 2, {
                        text = format("|cff%s%s|r", BG.TargetVerOver(BG.GetMLName(), 20070) and 'ffffff' or '808080', L['提醒团长拍卖']),
                        notCheckable = true,
                        func = function()
                            if GetTime() - reAuctionSendCD > 3 then
                                SendGateway.Addon(C.PREFIX_AUX, format(C.OP_REMIND_AUCTION .. "^%s^%s", GetItemID(link), link), "RAID")
                                BG.SendSystemMessage(L["已提醒团长拍卖："] .. link)
                                reAuctionSendCD = GetTime()
                            else
                                BG.SendSystemMessage(L["申请太频繁了，等待3秒后再尝试。"])
                            end
                        end,
                        tooltipTitle = L['提醒团长拍卖'],
                        tooltipText = L['团长的BGForge版本高于%s时才能收到你的请求。']:format('v2.0.7'),
                        tooltipOnButton = true,
                    })
                else
                    tinsert(menuEntries, 2, {
                        text = L["开始拍卖"],
                        notCheckable = true,
                        func = function()
                            BG.StartAuction(link, f, true, true)
                        end
                    })
                end
            else
                menuEntries = {
                    MenuTitleEntry(link:gsub("%[", ""):gsub("%]", "")),
                    {
                        text = L["重新拍卖"],
                        disabled = not BG.IsML,
                        notCheckable = true,
                        func = function()
                            AddNeedDeleteItem(index, v)
                            BG.StartAuction(link, f, true, true, nil, nil, DeleteLiuPaiAuctionLog)
                        end
                    },
                    {
                        -- 修改记录
                        notCheckable = true,
                        func = function(self, arg1)
                            BG.auctionLogFrame.changeFrame:Hide()
                            BG.auctionLogFrame.changeFrame.type = "change"
                            BG.auctionLogFrame.changeFrame.typeText = arg1
                            BG.auctionLogFrame.changeFrame.info = {}
                            BG.auctionLogFrame.changeFrame.info.num = index
                            for fieldKey in pairs(BG.playerClass) do
                                BG.auctionLogFrame.changeFrame.info[fieldKey] = v[fieldKey]
                            end
                            BG.auctionLogFrame.changeFrame:Show()
                            BG.auctionLogFrame.changeFrame:ClearAllPoints()
                            BG.auctionLogFrame.changeFrame:SetPoint("TOP", f, "BOTTOM", 10, 0)
                            BG.auctionLogFrame.changeFrame.item:SetText(AddTexture(icon) .. link:gsub("%[", ""):gsub("%]", ""))
                            BG.auctionLogFrame.changeFrame.item.itemID = GetItemID(link)
                            BG.auctionLogFrame.changeFrame.maijia:ClearFocus()
                            BG.auctionLogFrame.changeFrame.maijia:SetText(v.maijia or "")
                            BG.auctionLogFrame.changeFrame.maijia:SetTextColor(unpack(v.color or { 1, 1, 1 }))
                            BG.auctionLogFrame.changeFrame.jine:ClearFocus()
                            BG.auctionLogFrame.changeFrame.jine:SetText(v.jine or "")
                        end
                    },
                    {
                        text = L["删除记录"],
                        notCheckable = true,
                        func = function()
                            BG.auctionLogFrame.changeFrame:Hide()
                            if not BiaoGe[FB].auctionLog then return end
                            tremove(BiaoGe[FB].auctionLog, index)
                            BG.UpdateAuctionLogFrame(true, true)
                        end
                    },
                    MenuBlankEntry(),
                    MenuCancelEntry(),
                }

                if v.type == 1 then
                    -- 成功
                    menuEntries[3].text = L["修改记录"]
                    menuEntries[3].arg1 = menuEntries[3].text

                    local ordinal = 2
                    if v.log then
                        tinsert(menuEntries, ordinal, {
                            text = L["出价记录"],
                            notCheckable = true,
                            tooltipTitle = L["出价记录"],
                            tooltipText = GetLogTooltipText(),
                            tooltipOnButton = true,
                        })
                        ordinal = ordinal + 1
                    end
                    ordinal = ordinal + 1
                    tinsert(menuEntries, ordinal, {
                        text = L["设为流拍"],
                        notCheckable = true,
                        func = function()
                            BG.SetAuctionLogItemState(v, 2)
                        end
                    })
                    ordinal = ordinal + 1
                    if v.trade then
                        tinsert(menuEntries, ordinal, {
                            text = L["设为未交易"],
                            notCheckable = true,
                            func = function()
                                v.trade = nil
                                BG.UpdateAuctionLogFrame(true, true)
                            end
                        })
                    else
                        tinsert(menuEntries, ordinal, {
                            text = L["设为已交易"],
                            notCheckable = true,
                            tooltipTitle = L["设为已交易"],
                            tooltipText = L["交易时不再显示该装备的应收/应付金额，团长也不会自动摆放该装备。"],
                            tooltipOnButton = true,
                            func = function()
                                v.trade = true
                                BG.UpdateAuctionLogFrame(true, true)
                            end
                        })
                    end
                    tinsert(menuEntries, ordinal + 1, MenuBlankEntry())
                    -- 「交易玩家」「跟随玩家」：属金团收款/分金流程闭环的一部分 ——
                    -- 拍卖成功后团长需要与买家一对一交易来收取金额；交易要求双方处于交互距离内，
                    -- 「跟随玩家」用于走到买家身边，「交易玩家」用于开交易窗口，两者配套。
                    -- 同一菜单里的「设为已交易 / 设为未交易」也是收款状态管理，可佐证本菜单的用途。
                    -- InitiateTrade 只是「打开交易窗口」，双方仍需各自放入物品/金币并手动确认；
                    -- 它不移动任何金钱，与 AcceptTrade（代玩家完成交易）性质不同。
                    -- 两项保留均经策划确认；docs/07 §4.3 R2 需相应回填豁免说明。
                    if v.maijia ~= player then
                        ordinal = ordinal + 1
                        tinsert(menuEntries, ordinal + 1, {
                            text = TRADE .. PLAYER,
                            notCheckable = true,
                            disabled = true,
                            arg1 = "auctionLogTrade",
                            arg2 = v.maijia,
                            func = function()
                                InitiateTrade(v.maijia)
                            end
                        })
                        ordinal = ordinal + 1
                        tinsert(menuEntries, ordinal + 1, {
                            text = FOLLOW .. PLAYER,
                            notCheckable = true,
                            disabled = true,
                            arg1 = "auctionLogFollow",
                            arg2 = v.maijia,
                            func = function()
                                FollowUnit(v.maijia)
                            end
                        })
                        ordinal = ordinal + 1
                        tinsert(menuEntries, ordinal + 1, {
                            isTitle = true,
                            text = "   ",
                            notCheckable = true,
                        })
                    end
                elseif v.type == 2 then
                    -- 流拍
                    if not BG.IsML and IsInRaid(1) then
                        menuEntries[2].text = L['|cff%s向团长申请重拍|r']:format(BG.TargetVerOver(BG.GetMLName(), 20000) and tonumber(v.jine)
                            and 'ffffff' or '808080')
                        menuEntries[2].disabled = not (tonumber(v.jine))
                        menuEntries[2].func = function()
                            if GetTime() - reAuctionSendCD > 3 then
                                SendGateway.Addon(C.PREFIX_MAIN, format(C.OP_RE_AUCTION .. "^%s^%s^%s", GetItemID(link), link, v.jine), "RAID")
                                BG.SendSystemMessage(L["已向团长发送重拍申请："] .. link)
                                reAuctionSendCD = GetTime()
                            else
                                BG.SendSystemMessage(L["申请太频繁了，等待3秒后再尝试。"])
                            end
                        end
                        menuEntries[2].tooltipTitle = L['向团长申请重拍']
                        menuEntries[2].tooltipText = L['团长的BGForge版本高于%s时才能收到你的请求。']:format('v2.0.0')
                        menuEntries[2].tooltipOnButton = true
                    end
                    menuEntries[3].text = L["设为成功拍卖"]
                    menuEntries[3].arg1 = menuEntries[3].text
                    tinsert(menuEntries, 2, {
                        text = L["|cff808080流拍价："] .. (v.jine and BG.FormatNumber(v.jine, 2) or UNKNOWN),
                        isTitle = true,
                        notCheckable = true,
                    })
                    tinsert(menuEntries, 3, MenuBlankEntry())
                end
            end
            return menuEntries
        end

        -- 实时刷新「交易玩家」「跟随玩家」两个按钮的可用状态。
        -- 菜单项创建时是 disabled = true，这里按暴雪自身的可用性规则启用：
        -- 交易需在交互距离 2 内、跟随需在距离 4 内，且都要求不处于战斗中。
        _G["L_DropDownList1"]:HookScript("OnUpdate", function(self)
            if L_DropDownList1.dropdown ~= dropDown then return end
            for i = 1, _G['L_DropDownList1'].numButtons do
                local clickedButton = _G["L_DropDownList1Button" .. i]
                if clickedButton.arg1 == "auctionLogTrade" then
                    if not InCombatLockdown() and CheckInteractDistance(clickedButton.arg2, 2) then
                        clickedButton:Enable()
                    else
                        clickedButton:Disable()
                    end
                elseif clickedButton.arg1 == "auctionLogFollow" then
                    if not InCombatLockdown() and CheckInteractDistance(clickedButton.arg2, 4) then
                        clickedButton:Enable()
                    else
                        clickedButton:Disable()
                    end
                end
            end
        end)
    end

    -- 列表内容
    local CreateButton
    do
        function CancelAllChoose()
            wipe(BG.auctionLogFrame.choosed)
            BG.UpdateAuctionLogFrame(true, true)
        end

        local DRAG_BACKDROP = {
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1.5,
        }

        local function IsCanChooseList()
            return BiaoGe.options.auctionLogChoose == 3 or BiaoGe.options.auctionLogChoose == 4
        end

        local function CancelChoose(bt)
            bt.ischoose = nil
            if bt.num % 2 == 0 then
                bt.tex:SetColorTexture(.5, .5, .5, .15)
            else
                bt.tex:SetColorTexture(0, 0, 0, .25)
            end
        end
        local function SelectControlRow(bts, itemID, link, jine, index, num)
            bts.ischoose = not bts.ischoose
            if bts.ischoose then
                if #BG.auctionLogFrame.choosed < 5 then
                    tinsert(BG.auctionLogFrame.choosed, { id = itemID, link = link, money = jine, index = index })
                    bts.tex:SetColorTexture(1, 1, 0, .5)
                else
                    bts.ischoose = nil
                end
                lastChoose = num
            else
                for _i = #BG.auctionLogFrame.choosed, 1, -1 do
                    if BG.auctionLogFrame.choosed[_i].id == itemID then
                        tremove(BG.auctionLogFrame.choosed, _i)
                        break
                    end
                end
                CancelChoose(bts)
            end
        end

        local function SelectShiftRange(link, index, num)
            if #BG.auctionLogFrame.choosed == 0 then
                BG.InsertLink(link)
            elseif lastChoose then
                for _i, bt in ipairs(BG.auctionLogFrame.buttons) do
                    if _i ~= index then
                        CancelChoose(bt)
                    end
                end
                wipe(BG.auctionLogFrame.choosed)

                local tally = 0
                for _i = lastChoose, num, lastChoose < num and 1 or -1 do
                    if tally < 5 then
                        local bt = BG.auctionLogFrame.buttons[_i]
                        bt.ischoose = true
                        tinsert(BG.auctionLogFrame.choosed, { id = bt.itemID, link = bt.link, money = bt.jine, index = bt.index })
                        bt.tex:SetColorTexture(1, 1, 0, .5)
                        tally = tally + 1
                    end
                end
                lastChoose = nil
            end
        end

        local function SelectSingleRow(bts, itemID, link, jine, index, num)
            bts.ischoose = not bts.ischoose
            if bts.ischoose then
                tinsert(BG.auctionLogFrame.choosed, { id = itemID, link = link, money = jine, index = index })
                bts.tex:SetColorTexture(1, 1, 0, .5)
                lastChoose = num
            else
                for _i = #BG.auctionLogFrame.choosed, 1, -1 do
                    if BG.auctionLogFrame.choosed[_i].id == itemID then
                        tremove(BG.auctionLogFrame.choosed, _i)
                    end
                end
                CancelChoose(bts)
            end
        end

        local function OnMouseUp(f, clickedButton)
            local v = f.v
            local index = f.index
            local notAuctioned = f.notAuctioned
            local link = f.link
            local itemID = f.itemID
            local icon = f.icon
            local bts = f.bts
            local num = f.num
            if clickedButton == "RightButton" and not IsAltKeyDown() then
                wipe(BG.auctionLogFrame.choosed)
                lastChoose = num
                for _i, bt in ipairs(BG.auctionLogFrame.buttons) do
                    CancelChoose(bt)
                end
                local menuEntries = CreateMenu(f, index, v, notAuctioned, link, icon)
                if menuEntries then
                    LibBG:EasyMenu(menuEntries, dropDown, "cursor", 10, 10, "MENU", 2)
                    BG.PlaySound(1)
                end
                if IsCanChooseList() then
                    UpdateButtonStartAuction()
                end
                return
            end
            -- 已移除「设为最佳价格」分支（第三方付费模块 BGV 提供的能力）
            if IsAltKeyDown() and BG.IsML then
                if v.type == 1 or v.type == 2 then
                    AddNeedDeleteItem(index, v)
                end
                if IsCanChooseList() then
                    wipe(BG.auctionLogFrame.choosed)
                    for _i, bt in ipairs(BG.auctionLogFrame.buttons) do
                        CancelChoose(bt)
                    end
                    UpdateButtonStartAuction()
                end
                BG.StartAuction(link, f, true, nil, clickedButton == "RightButton", nil, (v.type == 1 or v.type == 2) and DeleteLiuPaiAuctionLog)
                return
            end
            if IsCanChooseList() then
                BG.PlaySound(1)
                if IsControlKeyDown() then
                    SelectControlRow(bts, itemID, link, v.jine, index, num)
                elseif IsShiftKeyDown() then
                    SelectShiftRange(link, index, num)
                else
                    BG.PlaySound(1)

                    for _i, bt in ipairs(BG.auctionLogFrame.buttons) do
                        if _i ~= num then
                            CancelChoose(bt)
                        end
                    end
                    wipe(BG.auctionLogFrame.choosed)

                    SelectSingleRow(bts, itemID, link, v.jine, index, num)
                end
                LibBG:CloseDropDownMenus()
            else
                if IsShiftKeyDown() then
                    BG.PlaySound(1)
                    BG.InsertLink(link)
                end
            end
            if IsCanChooseList() then
                UpdateButtonStartAuction()
            end
        end
        local function GetCursorUIPosition()
            local cursorX, cursorY = GetCursorPosition()
            local uiScale = UIParent:GetEffectiveScale()
            return cursorX / uiScale, cursorY / uiScale
        end

        local function IsDragBoxHit(f, left, right, top, bottom)
            local boxLeft, boxRight = f:GetLeft(), f:GetRight()
            local boxTop, boxBottom = f:GetTop(), f:GetBottom()
            if boxLeft and boxRight then
                if boxLeft < right and boxRight > left and boxTop > bottom and boxBottom < top then
                    return true
                end
            end
        end

        local function OnMouseDown(f, clickedButton)
            if not IsCanChooseList() then return end
            drag.startX, drag.startY = GetCursorUIPosition()
        end
        local function DragOnUpdate(self)
            if not IsCanChooseList() then return end
            local cursorX, cursorY = GetCursorUIPosition()
            drag.frame:ClearAllPoints()
            local left = min(cursorX, drag.startX)
            local right = max(cursorX, drag.startX)
            local top = max(cursorY, drag.startY)
            local bottom = min(cursorY, drag.startY)
            drag.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            drag.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right, bottom)

            -- 拖拽框选时逐个判断矩形是否相交
            for _, bt in ipairs(BG.auctionLogFrame.buttons) do
                local f = bt.frame
                if f:IsVisible() then
                    if IsDragBoxHit(f, left, right, top, bottom) then
                        if not bt.ischoose and #BG.auctionLogFrame.choosed < 5 then
                            bt.ischoose = true
                            tinsert(BG.auctionLogFrame.choosed, { id = bt.itemID, link = bt.link, money = bt.jine, index = bt.index })
                            bt.tex:SetColorTexture(1, 1, 0, .5)
                            lastChoose = bt.num
                        end
                    end
                end
            end
            UpdateButtonStartAuction()
        end
        local function OnDragStart(self)
            if not IsCanChooseList() then return end
            -- 先取消所有已选
            for _i, bt in ipairs(BG.auctionLogFrame.buttons) do
                CancelChoose(bt)
            end
            wipe(BG.auctionLogFrame.choosed)
            UpdateButtonStartAuction()
            LibBG:CloseDropDownMenus()
            local f = CreateFrame("Frame", nil, BG.auctionLogFrame, "BackdropTemplate")
            f:SetBackdrop(DRAG_BACKDROP)
            f:SetBackdropBorderColor(0, 1, 0, 1)
            f:SetFrameLevel(BG.auctionLogFrame:GetFrameLevel() + 10)
            drag.frame = f
            BG.auctionLogFrame:SetScript('OnUpdate', DragOnUpdate)
        end
        local function OnDragStop(self)
            if not drag.frame then return end
            drag.frame:Hide()
            BG.auctionLogFrame:SetScript('OnUpdate', nil)
        end

        child:SetScript("OnMouseDown", OnMouseDown)
        child:SetScript("OnDragStart", OnDragStart)
        child:SetScript("OnDragStop", OnDragStop)

        local LOG_ICON_BACKDROP = {
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        }

        local function BuildAuctionLogIcon(bts, iconTexture, red, green, blue, typeID, itemLevel, bindType)
            local iconFrame = CreateFrame("Frame", nil, bts.frame, "BackdropTemplate")
            iconFrame:SetBackdrop(LOG_ICON_BACKDROP)
            iconFrame:SetBackdropBorderColor(red, green, blue)
            iconFrame:SetSize(bts.frame:GetHeight() - 2, bts.frame:GetHeight() - 2)
            iconFrame:SetPoint("LEFT")
            bts.iconFrame = iconFrame
            local tex = iconFrame:CreateTexture(nil, "BACKGROUND")
            tex:SetAllPoints()
            tex:SetTexture(iconTexture)
            tex:SetTexCoord(unpack(BG.iconTexCoord))
            bts.icon = tex
            iconFrame.level = iconFrame:CreateFontString()
            iconFrame.level:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
            iconFrame.level:SetPoint("BOTTOM", bts.icon, 0, 1)
            iconFrame.level:SetText((typeID == 2 or typeID == 4) and itemLevel or nil)
            iconFrame.level:SetTextColor(red, green, blue)
            if bindType == 2 then
                local text = iconFrame:CreateFontString()
                text:SetFont(BIAOGE_TEXT_FONT, 10, "OUTLINE")
                text:SetPoint("TOP", iconFrame, 0, -1)
                text:SetText(L["装绑"])
                text:SetTextColor(0, 1, 0)
            end
        end

        local function BuildAuctionLogTexts(bts, v, width, link)
            local itemText = bts.frame:CreateFontString()
            itemText:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            itemText:SetWidth(width - bts.icon:GetWidth())
            itemText:SetPoint("TOPLEFT", bts.icon, "TOPRIGHT", 1, 0)
            itemText:SetText(link:gsub("%[", ""):gsub("%]", ""))
            itemText:SetJustifyH("LEFT")
            itemText:SetWordWrap(false)
            bts.item = itemText

            local moneyText = bts.frame:CreateFontString()
            moneyText:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            moneyText:SetPoint("BOTTOMLEFT", bts.icon, "BOTTOMRIGHT", 1, 0)
            moneyText:SetWidth(width - bts.icon:GetWidth())
            moneyText.notAuctionedText = BG.STC_dis(L["<未拍>"])
            moneyText.LiuPaiText = BG.STC_r1(L["<流拍>"])
            moneyText.auctionText = BG.STC_y1(L["<正在拍卖>"])
            if v.type == 1 then
                local color = "FFFFFF"
                if v.color then
                    local red, green, blue = unpack(v.color)
                    color = RGB_16(nil, red, green, blue)
                end
                moneyText:SetText(format("%s |cff%s%s|r", BG.FormatNumber(v.jine, 2), color, v.maijia))
            elseif v.type == 3 then
                moneyText:SetText(moneyText.notAuctionedText)
            else
                moneyText:SetText(moneyText.LiuPaiText)
            end
            moneyText:SetJustifyH("LEFT")
            moneyText:SetWordWrap(false)
            bts.money = moneyText

            if v.type == 1 and v.trade then
                local tradeText = bts.frame:CreateFontString(nil, "OVERLAY")
                tradeText:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                tradeText:SetPoint("TOPRIGHT", -1, -1)
                tradeText:SetText(L["已交易"])
                tradeText:SetTextColor(0, 1, 0)
            end
        end

        function CreateButton(index, v, num)
            local bts = {}
            local width = child:GetWidth()
            local link = v.zhuangbei
            local itemID = GetItemID(link)
            local icon, typeID = select(5, GetItemInfoInstant(link))
            local red, green, blue = GetItemQualityColor(v.quality)
            local notAuctioned = v.type == 3
            bts.link = link
            bts.itemID = itemID
            bts.num = num
            bts.jine = v.jine
            bts.index = index

            -- 主框架
            do
                local f = CreateFrame("Frame", nil, child, "BackdropTemplate")
                f:SetSize(width, 32)
                if #BG.auctionLogFrame.buttons == 0 then
                    f:SetPoint("TOPLEFT")
                else
                    f:SetPoint("TOPLEFT", BG.auctionLogFrame.buttons[#BG.auctionLogFrame.buttons].frame, "BOTTOMLEFT", 0, 0)
                end
                f:Show()
                f:RegisterForDrag("LeftButton")
                f.link = link
                f.index = index
                f.v = v
                f.num = num
                f.link = link
                f.itemID = itemID
                f.icon = icon
                f.typeID = typeID
                f.bts = bts
                f.jine = v.jine
                f.notAuctioned = notAuctioned
                bts.frame = f
                f:SetScript("OnMouseUp", OnMouseUp)
                f:SetScript("OnMouseDown", OnMouseDown)
                f:SetScript("OnDragStart", OnDragStart)
                f:SetScript("OnDragStop", OnDragStop)
                BG.OnEnterDelay(f, function(self)
                    GameTooltip:SetOwner(frame.tooltip, "ANCHOR_BOTTOMRIGHT", 0, 0)
                    GameTooltip:ClearLines()
                    local itemID = GetItemInfoInstant(link)
                    if itemID then
                        if not BG.IsHideTooltipKeyDown() then
                            GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                            GameTooltip:AddLine(L['< 按住CTRL+SHIFT隐藏此界面 >'], 0, 1, 0, true)
                            GameTooltip:Show()
                            BG.SetZUGSetTooltip(itemID, 'RIGHT')
                        end
                        BG.Show_AllHighlight(link, "auctionlog")
                        HighlightBiaoGeSameItems(itemID, link, self)
                        if IsAltKeyDown() and BG.IsML and BiaoGe.options["autoAuctionStart"] == 1 then
                            SetCursor("interface/cursor/repair")
                        elseif IsControlKeyDown() or IsShiftKeyDown() then
                            SetCursor(nil)
                        end
                        if BG.IsML then
                            BG.canShowStartAuctionCursor = true
                        end
                        BG.DressUpLastButton = self
                    end
                    bts.ds:Show()
                end, BG.itemOnEnterDelay)
                BG.OnLeaveDelay(f, function(self)
                    GameTooltip:Hide()
                    BG.Hide_AllHighlight()
                    bts.ds:Hide()
                    SetCursor(nil)
                    BG.canShowStartAuctionCursor = false
                    if BG.DressUpFrame then
                        BG.DressUpFrame:Hide()
                    end
                    BG.DressUpLastButton = nil
                end)

                local tex = bts.frame:CreateTexture(nil, "BACKGROUND")
                tex:SetAllPoints()
                if num % 2 == 0 then
                    tex:SetColorTexture(.5, .5, .5, .15)
                else
                    tex:SetColorTexture(0, 0, 0, .25)
                end
                bts.tex = tex

                local tex = bts.frame:CreateTexture()
                tex:SetAllPoints()
                tex:SetColorTexture(.5, .5, .5, .5)
                tex:Hide()
                bts.ds = tex

                tinsert(BG.auctionLogFrame.buttons, bts)

            end
            -- 图标和装等
            BuildAuctionLogIcon(bts, icon, red, green, blue, typeID, v.itemlevel, v.bindType)
            -- 装备、买家和金额
            BuildAuctionLogTexts(bts, v, width, link)

            if BG.SpecGearFilter then
                BG.SpecGearFilter.ApplyToCell(bts.frame, link)
            end
        end
    end

    local function MatchesBracketText(value, queryText)
        return value and value:match("%[.+%]"):find(queryText, 1, true)
    end

    local function MatchesPlainText(value, queryText)
        return value and value:find(queryText, 1, true)
    end

    local function SearchText(v)
        local queryText = BG.auctionLogFrame.serachEdit:GetText()
        if queryText == "" then
            return true
        end
        if MatchesBracketText(v.zhuangbei, queryText) then
            return true
        end
        if MatchesPlainText(v.maijia, queryText) then
            return true
        end
        if v.jine and v.jine == queryText then
            return true
        end
    end

    local function UpdateFrameSize()
        BG.auctionLogFrame:SetHeight(BG.FBHeight[BG.FB1] + (BG.MainNavigationHeight or 0))
        child:SetHeight(scroll:GetHeight())
    end

    local playerInfo = BiaoGe.playerInfo[RealmID]
    local function IsMyPlayer(player)
        return playerInfo[player]
    end

    local function MatchesAuctionLogFilter(v)
        local choose = BiaoGe.options.auctionLogChoose
        if choose == 1 then return true end
        if choose == 2 then return v.type == 1 end
        if choose == 3 then return v.type == 2 end
        if choose == 5 then return not v.trade and v.type == 1 end
        if choose == 6 then return v.type == 1 and IsMyPlayer(v.maijia) end
        return false
    end

    local function BuildUnauctionedRows(raidKey, tableRef)
        local newTbl = {}
        for bossSlot = 1, Maxb[raidKey] do
            for i = 1, BG.GetMaxi(raidKey, bossSlot) do
                if BG.Frame[raidKey]["boss" .. bossSlot]["zhuangbei" .. i] then
                    local equipment = BiaoGe[raidKey]["boss" .. bossSlot]["zhuangbei" .. i]
                    if GetItemID(equipment) then
                        tinsert(newTbl, equipment)
                    end
                end
            end
        end
        if tableRef then
            local duplicateList = BG.Copy(tableRef)
            for i = #newTbl, 1, -1 do
                for _i = #duplicateList, 1, -1 do
                    if GetItemID(newTbl[i]) == GetItemID(duplicateList[_i].zhuangbei) then
                        tremove(newTbl, i)
                        tremove(duplicateList, _i)
                        break
                    end
                end
            end
        end
        local cacheDelay = 0
        for i, zhuangbei in ipairs(newTbl) do
            local itemRef = Item:CreateFromItemID(GetItemID(zhuangbei))
            if not GetItemInfo(zhuangbei) then
                cacheDelay = 0.5
            end
            itemRef:ContinueOnItemLoad(function()
                local name, itemLink, quality, itemLevel, _, _, _, _, equipLocation, Texture,
                _, typeId, subclassId, bindType = GetItemInfo(zhuangbei)
                newTbl[i] = {
                    type = 3,
                    zhuangbei = zhuangbei,
                    itemlevel = itemLevel,
                    quality = quality,
                    bindType = bindType,
                }
            end)
        end
        return newTbl, cacheDelay
    end

    function BG.UpdateAuctionLogFrame(keepScroll, keepTop)
        if BG.auctionLogFrame:IsVisible() then
            UpdateFrameSize()
            for i, v in ipairs(BG.auctionLogFrame.buttons) do
                v.frame:Hide()
                v.frame:SetParent(nil)
            end
            wipe(BG.auctionLogFrame.buttons)
            BG.auctionLogFrame.notText:Hide()
            if not keepTop then
                wipe(BG.auctionLogFrame.choosed)
                lastChoose = nil
            end
            UpdateButtonStartAuction()

            local raidKey = BG.FB1
            local total = 0
            local tableRef = BiaoGe[raidKey].auctionLog
            local cacheDelay = 0
            if not tableRef or #tableRef == 0 then
                BG.auctionLogFrame.ButtonCreateLedger:Disable()
                BG.auctionLogFrame.ButtonCreateDuiZhang:Disable()
                if BiaoGe.options.auctionLogChoose ~= 4 then
                    BG.auctionLogFrame.notText:Show()
                end
            else
                BG.auctionLogFrame.ButtonCreateLedger:Enable()
                BG.auctionLogFrame.ButtonCreateDuiZhang:Enable()
            end
            BG.auctionLogFrame.ButtonAdd:Enable()
            BG.auctionLogFrame.title:SetText(L["自动拍卖记录"])
            BG.auctionLogFrame.title:SetTextColor(1, 1, 1)
            if tableRef then
                local ordinal = 0
                for i, v in ipairs(tableRef) do
                    -- type 1：成功 2：流拍
                    if MatchesAuctionLogFilter(v) and SearchText(v) then
                        ordinal = ordinal + 1
                        CreateButton(i, v, ordinal)
                    end
                    if v.type == 1 then
                        total = total + (tonumber(v.jine) or 0)
                    end
                end
                if BiaoGe.options.auctionLogChoose == 7 then
                    local errorList = GetErrorItem(tableRef, true)
                    if errorList then
                        for _, nestedRecord in ipairs(errorList) do
                            for i, v in ipairs(nestedRecord.info) do
                                ordinal = ordinal + 1
                                local position = nestedRecord.indexs[i]
                                CreateButton(position, v, ordinal)
                            end
                        end
                    end
                end
            end

            if BiaoGe.options.auctionLogChoose == 4 then
                local newTbl
                newTbl, cacheDelay = BuildUnauctionedRows(raidKey, tableRef)

                local function Create()
                    for i, bt in ipairs(BG.auctionLogFrame.buttons) do
                        bt.frame:Hide()
                    end
                    wipe(BG.auctionLogFrame.buttons)

                    for i, v in ipairs(newTbl) do
                        if SearchText(v) then
                            CreateButton(i, v, i)
                        end
                    end
                    BG.UpdateAuctioning()

                    for i, v in ipairs(BG.auctionLogFrame.choosed) do
                        local itemID = v.id
                        for i, bt in ipairs(BG.auctionLogFrame.buttons) do
                            if bt.itemID == itemID then
                                bt.ischoose = true
                                bt.tex:Show()
                                bt.tex:SetColorTexture(1, 1, 0, .5)
                                break
                            end
                        end
                    end
                end
                if cacheDelay == 0 then
                    Create()
                else
                    BG.After(cacheDelay, function()
                        Create()
                    end)
                end
            end

            BG.auctionLogFrame.sumText:SetText(L["合计收入："] .. BG.FormatNumber(total, 2))

            if BiaoGe.options.auctionLogChoose == 4 then
                if not keepTop then
                    BG.After(cacheDelay + 0.05, function()
                        local min, upperBound = frame.scroll.ScrollBar:GetMinMaxValues()
                        frame.scroll.ScrollBar:SetValue(min)
                    end)
                end
            elseif not keepScroll then
                BG.After(0, function()
                    local min, upperBound = frame.scroll.ScrollBar:GetMinMaxValues()
                    frame.scroll.ScrollBar:SetValue(upperBound)
                end)
            end
        end
        if BG.UpdateLootAuctionLogFrame then
            BG.UpdateLootAuctionLogFrame()
        end
    end

    function BG.UpdateAuctioning()
        if BiaoGe.options.auctionLogChoose ~= 4 then return end
        local auctioning = BG.Copy(BG.auctionLogFrame.auctioning)
        for _, bt in ipairs(BG.auctionLogFrame.buttons) do
            bt.money:SetText(bt.money.notAuctionedText)
            for i = #auctioning, 1, -1 do
                if bt.itemID == auctioning[i] then
                    bt.money:SetText(bt.money.auctionText)
                    tremove(auctioning, i)
                    break
                end
            end
        end
    end

    BG.auctionLogFrame.serachEdit:HookScript("OnTextChanged", BG.UpdateAuctionLogFrame)

    -- 记录自动拍卖结果
    do
        local function DeleteAuctioning(itemId)
            for i = #BG.auctionLogFrame.auctioning, 1, -1 do
                if BG.auctionLogFrame.auctioning[i] == itemId then
                    tremove(BG.auctionLogFrame.auctioning, i)
                    break
                end
            end
        end
        function BG.GetTargetAuctionTradeItems(tradePartner)
            local raidKey = BG.FB1
            local list = {}
            BG.auctionTrade[tradePartner] = list
            local logs = BiaoGe[raidKey].auctionLog
            if not logs then return end
            for i = 1, #logs do
                local v = logs[i]
                if v.type == 1 and not v.trade and v.maijia == tradePartner then
                    list[#list + 1] = BG.Copy(v)
                end
            end
        end

        local function MoneyIsError(price)
            return price:match("[!@#$%^&*]")
        end

        local function ItemExistsInFB(itemID, FB)
            local found
            BG.PairFBItem(function(itemRef)
                local stringValue = itemRef:GetText()
                if stringValue ~= '' and GetItemID(stringValue) == itemID then
                    found = FB
                    return true
                end
            end, nil, nil, FB)
            return found
        end

        local function GetFB(itemID)
            if BG.FB2 then return BG.FB2 end
            local found = ItemExistsInFB(itemID, BG.FB1)
            if found then
                return found
            end
            for i = #BG.FBtable, 1, -1 do
                local FB = BG.FBtable[i]
                if FB ~= BG.FB1 then
                    found = ItemExistsInFB(itemID, FB)
                    if found then
                        return found
                    end
                end
            end
            return BG.FB1
        end

        local function BuildBidLog(logs)
            if not next(logs) then return end
            local log = {}
            local ordinal = 1
            local completed = true
            for i = #logs, 1, -1 do
                if not completed and ordinal > 5 then break end
                ordinal = ordinal + 1
                local firstArg = BG.Copy(logs[i])
                firstArg.i = i
                tinsert(log, 1, firstArg)
            end
            return log
        end

        local function CollectBuyerClass(maijia)
            local playerClass = {}
            for fieldKey, v in pairs(BG.playerClass) do
                local payload = select(v.select, v.func(maijia))
                if payload == 0 then payload = nil end
                playerClass[fieldKey] = payload
            end
            if not playerClass.guild then
                playerClass.realm = nil
            end
            return playerClass
        end

        local function BuildSuccessLogRecord(zhuangbei, maijia, jine, itemLevel, quality, bindType, log)
            return {
                type = 1,
                time = time(),
                zhuangbei = zhuangbei,
                maijia = maijia,
                jine = jine,
                itemlevel = itemLevel,
                quality = quality,
                bindType = bindType,
                log = log,
                trade = BG.ImML() and maijia == BG.playerName or nil,
            }
        end

        function BG.AuctionWAEnd(finishType, zhuangbei, maijia, jine, logs)
            if finishType == 1 and zhuangbei and maijia and jine then -- 成功
                jine = tostring(jine)
                local itemID = GetItemID(zhuangbei)
                DeleteAuctioning(itemID)
                local itemRef = Item:CreateFromItemID(itemID)
                itemRef:ContinueOnItemLoad(function()
                    local name, itemLink, quality, itemLevel, _, _, _, _, equipLocation, Texture,
                    _, typeId, subclassId, bindType = GetItemInfo(zhuangbei)
                    local FB = GetFB(itemID)
                    local log = BuildBidLog(logs)
                    if log and MoneyIsError(jine) and logs[#logs] then
                        jine = tostring(logs[#logs].money)
                    end

                    local playerClass = CollectBuyerClass(maijia)
                    local firstArg = BuildSuccessLogRecord(zhuangbei, maijia, jine, itemLevel, quality, bindType, log)
                    for fieldKey, v in pairs(playerClass) do
                        firstArg[fieldKey] = v
                    end
                    BiaoGe[FB].auctionLog = BiaoGe[FB].auctionLog or {}
                    tinsert(BiaoGe[FB].auctionLog, firstArg)
                    BG.UpdateAuctionLogFrame(nil, true)

                    local tradePartner = BG.GN("NPC")
                    if BG.tradelastAuctionFrame.frame:IsVisible() and tradePartner and maijia == tradePartner then
                        BG.GetTargetAuctionTradeItems(maijia)
                        if BG.ImMLorLeader() then
                            BG.tradelastAuctionFrame.UpdateChooseType()
                            BG.tradelastAuctionFrame.UpdateAutoButtons()
                        end
                    end

                    BG.SaveRLAuction(zhuangbei, maijia, jine, FB)

                    if BG.IsAutoCreateBill() then
                        BG.After(0.1, function()
                            BG.CreateBillByAuctionLog(FB)
                        end)
                    end
                end)
                return
            elseif finishType == 2 and zhuangbei then -- 流拍
                local itemID = GetItemID(zhuangbei)
                DeleteAuctioning(itemID)
                local itemRef = Item:CreateFromItemID(itemID)
                itemRef:ContinueOnItemLoad(function()
                    local name, itemLink, quality, itemLevel, _, _, _, _, equipLocation, Texture,
                    _, typeId, subclassId, bindType = GetItemInfo(zhuangbei)
                    local raidKey = GetFB(itemID)
                    local firstArg = {
                        type = 2,
                        time = time(),
                        zhuangbei = zhuangbei,
                        jine = tonumber(jine) or 0,
                        itemlevel = itemLevel,
                        quality = quality,
                        bindType = bindType,
                    }
                    BiaoGe[raidKey].auctionLog = BiaoGe[raidKey].auctionLog or {}
                    tinsert(BiaoGe[raidKey].auctionLog, firstArg)
                    BG.UpdateAuctionLogFrame(nil, true)
                end)
                return
            elseif finishType == 3 and zhuangbei then -- 取消
                DeleteAuctioning(GetItemID(zhuangbei))
                BG.UpdateAuctioning()
            end
        end
    end

    -- 在成交的聊天消息末尾追加出价明细
    do
        local function ParseAuctionLogHyperlink(itemLink)
            if not itemLink then return end
            local _, secondArgument, thirdArgument, itemId, ordinal = strsplit(":", itemLink)
            if secondArgument ~= C.PREFIX_MAIN or thirdArgument ~= "AuctionWALog" or not ordinal then
                return
            end
            return tonumber(itemId), tonumber(ordinal), true
        end

        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", function(self, event, messageText, ...)
            if BiaoGe.options.autoAuctionLogLink ~= 1 then return end
            if not (messageText:match("{rt6}拍卖成功{rt6}") or messageText:match("{rt6}拍賣成功{rt6}") or messageText:match("{rt6}Auction Successful{rt6}")) then return end
            local itemId = GetItemID(messageText)
            if not itemId then return end
            BG.chatAuctionLog = BG.chatAuctionLog or {}
            local raidKey = BG.FB2 or BG.FB1
            local log
            if BiaoGe[raidKey].auctionLog and next(BiaoGe[raidKey].auctionLog) then
                local details = BiaoGe[raidKey].auctionLog[#BiaoGe[raidKey].auctionLog]
                if GetItemID(details.zhuangbei) == itemId and details.log then
                    log = BG.Copy(details.log)
                end
            end
            if not log then return end
            tinsert(BG.chatAuctionLog, log)
            local itemLink = "|cffFFFF00" .. C.ITEM_PROTOCOL .. "BiaoGe:AuctionWALog:" .. itemId .. ":"
                .. #BG.chatAuctionLog .. "|h[" .. L["记录"] .. "]|h|r"
            local newMessage = messageText .. itemLink
            return false, newMessage, ...
        end)
        local function OnHyperlinkEnter(self, itemLink)
            local itemId, ordinal, matched = ParseAuctionLogHyperlink(itemLink)
            if not matched then return end
            local _, link = GetItemInfo(itemId)
            if not link then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(link:gsub("%[", ""):gsub("%]", ""), 1, 1, 1, true)
            if BG.chatAuctionLog[ordinal][1] and BG.chatAuctionLog[ordinal][1].i ~= 1 then
                GameTooltip:AddLine("......", .5, .5, .5, true)
            end
            for i, v in ipairs(BG.chatAuctionLog[ordinal]) do
                GameTooltip:AddLine(AddLogLine(v), 1, .82, 0)
            end
            GameTooltip:Show()
        end
        local slot = 1
        while _G["ChatFrame" .. slot] do
            _G["ChatFrame" .. slot]:HookScript("OnHyperlinkEnter", OnHyperlinkEnter)
            _G["ChatFrame" .. slot]:HookScript("OnHyperlinkLeave", GameTooltip_Hide)
            slot = slot + 1
        end
        local lastNum
        hooksecurefunc("SetItemRef", function(itemLink, text, clickedButton)
            if not itemLink then return end
            local itemId, ordinal, matched = ParseAuctionLogHyperlink(itemLink)
            if not matched then
                lastNum = nil
                return
            end
            local _, link = GetItemInfo(itemId)
            if not link then return end
            if ItemRefTooltip:IsVisible() and ordinal == lastNum then
                lastNum = nil
                ItemRefTooltip:Hide()
                return
            end
            ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
            ItemRefTooltip:ClearLines()
            ItemRefTooltip:AddLine(link:gsub("%[", ""):gsub("%]", ""), 1, 1, 1, true)
            if BG.chatAuctionLog[ordinal][1] and BG.chatAuctionLog[ordinal][1].i ~= 1 then
                ItemRefTooltip:AddLine("......", .5, .5, .5, true)
            end
            for i, v in ipairs(BG.chatAuctionLog[ordinal]) do
                ItemRefTooltip:AddLine(v.i .. L["、"] .. v.money .. format(L["（%s）"], v.player), 1, .82, 0)
            end
            ItemRefTooltip:Show()
            lastNum = ordinal
        end)
    end

    local function EnableItemHyperlinkTooltip(popup)
        popup:SetHyperlinksEnabled(true)
        popup:SetScript("OnHyperlinkEnter", function(self, itemLink, text, clickedButton)
            local itemId = GetItemID(itemLink)
            if itemId then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:SetHyperlink(BG.SetSpecIDToLink(itemLink))
            end
        end)
        popup:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    end

    -- 团员申请重拍
    do
        local reAuctionCD = {}
        local name = "BiaoGe_ReAuctionRequest"
        StaticPopupDialogs[name] = {
            text = " ",
            button1 = L["重拍"],
            button2 = CANCEL,
            OnShow = function(self)
                local details = BG.pendingReAuction
                local text = self.Text or self.text
                local iconRef = select(5, GetItemInfoInstant(details.itemID))
                local senderText = SetClassCFF(details.sender)
                local itemIcon = AddTexture(iconRef)
                text:SetText(L['%s 向你申请重拍流拍装备：\n\n%s%s（流拍价：%s）\n\n是否重拍该装备？']:format(
                    senderText, itemIcon, details.link, details.money
                ))
                EnableItemHyperlinkTooltip(self)
            end,
            OnAccept = function()
                local details = BG.pendingReAuction
                if not details then return end
                local secondGen = BiaoGe.Auction.gen == 2
                local mod = BiaoGe.Auction.mod
                local resetThreshold = max(tonumber(BiaoGe.Auction.resetThreshold) or 0, 10)
                BG.SendStartAuctionMsg(secondGen, details.itemID, details.money, 20, mod, details.link, resetThreshold)
                local raidKey = BG.FB2 or BG.FB1
                local logs = BiaoGe[raidKey].auctionLog
                if not logs then return end
                for i, v in ipairs(logs) do
                    if v.type == 2 and BG.IsSameItem(v.zhuangbei, details.link) then
                        BG.SendSystemMessage(L['%s的拍卖记录已被改为正在拍卖。']:format(v.zhuangbei))
                        tremove(logs, i)
                        BG.UpdateAuctionLogFrame(nil, true)
                        return
                    end
                end
            end,
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
        BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, prefixText, messageText, distributionType, _, sender)
            if prefixText ~= C.PREFIX_MAIN or distributionType ~= "RAID" then return end
            local cmd, itemID, link, money = strsplit("^", messageText)
            if cmd ~= C.OP_RE_AUCTION then return end
            if not BG.ImML() then return end
            if GetTime() - (reAuctionCD[sender] or 0) > 3 then
                reAuctionCD[sender] = GetTime()
                itemID = tonumber(itemID)
                if not itemID then return end
                if not GetItemID(link) then return end
                money = tonumber(money) or 1
                if money < 1 then
                    money = 1
                end
                BG.SendSystemMessage(L["%s向你申请重拍流拍装备：%s（%s金）。"]:format(SetClassCFF(sender), link, money))
                local raidKey = BG.FB2 or BG.FB1
                if BiaoGe[raidKey].auctionLog then
                    for i, v in ipairs(BiaoGe[raidKey].auctionLog) do
                        if v.type == 2 and GetItemID(v.zhuangbei) == itemID then
                            BG.pendingReAuction = { sender = sender, itemID = itemID, link = link, money = money }
                            StaticPopup_Show(name)
                            return
                        end
                    end
                end
            end
        end)
    end

    -- 由团员提示团长还有装备没拍
    do
        local remindAuctionCD = {}
        local name = "BiaoGe_RemindAuctionRequest"
        StaticPopupDialogs[name] = {
            text = " ",
            button1 = L["知道了"],
            OnShow = function(self)
                local details = BG.pendingRemindAuction
                local text = self.Text or self.text
                local iconRef = select(5, GetItemInfoInstant(details.itemID))
                local senderText = SetClassCFF(details.sender)
                local itemIcon = AddTexture(iconRef)
                text:SetText(L['%s 提醒你拍卖未拍装备：\n\n%s%s']:format(
                    senderText, itemIcon, details.link
                ))
                EnableItemHyperlinkTooltip(self)
            end,
            OnAccept = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
        BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, prefixText, messageText, distributionType, _, sender)
            if prefixText ~= C.PREFIX_AUX or distributionType ~= "RAID" then return end
            local cmd, itemID, link = strsplit("^", messageText)
            if cmd ~= C.OP_REMIND_AUCTION then return end
            if not BG.ImML() then return end
            if GetTime() - (remindAuctionCD[sender] or 0) > 3 then
                remindAuctionCD[sender] = GetTime()
                itemID = tonumber(itemID)
                if not itemID then return end
                if not GetItemID(link) then return end
                BG.SendSystemMessage(L["%s提醒你拍卖未拍装备：%s。"]:format(SetClassCFF(sender), link))
                BG.pendingRemindAuction = { sender = sender, itemID = itemID, link = link }
                StaticPopup_Show(name)
            end
        end)
    end

    -- 团长退款后，让团员决定要不要把该条拍卖记录标记为流拍
    do
        local cd = {}
        local name = "BiaoGe_RefundAuctionToFailed"
        local function FindAuctionLog(itemId, purchaser, price)
            local raidKey = BG.FB2 or BG.FB1
            if not (BiaoGe[raidKey] and BiaoGe[raidKey].auctionLog) then return end
            local logs = BiaoGe[raidKey].auctionLog
            for i = 1, #logs do
                local v = logs[i]
                if v.type == 1 and BG.IsSame(v.zhuangbei, itemId)
                    and v.maijia == purchaser
                    and tostring(v.jine) == tostring(price)
                then
                    return i, v
                end
            end
        end
        StaticPopupDialogs[name] = {
            text = " ",
            button1 = L["是"],
            button2 = L["否"],
            OnShow = function(self)
                local details = BG.pendingRefundAuctionToFailed
                local text = self.Text or self.text
                local iconRef = select(5, GetItemInfoInstant(details.itemID))
                local leaderIcon = AddTexture("interface/groupframe/ui-group-leadericon")
                local senderText = SetClassCFF(details.sender)
                local itemIcon = AddTexture(iconRef)
                local buyerText = SetClassCFF(details.buyer)
                text:SetText(L['%s%s 广播退货消息：\n\n%s%s\n买家：%s\n退货金额：%s\n\n把该条拍卖记录设为流拍吗？']:format(
                    leaderIcon,
                    senderText,
                    itemIcon,
                    details.link,
                    buyerText,
                    details.money
                ))
                EnableItemHyperlinkTooltip(self)
            end,
            OnAccept = function()
                local details = BG.pendingRefundAuctionToFailed
                if not details then return end
                local _, v = FindAuctionLog(details.itemID, details.buyer, details.money)
                if v then
                    BG.SetAuctionLogItemState(v, 2,true)
                    BG.SendSystemMessage(L['%s的拍卖记录已被改为流拍。']:format(v.zhuangbei))
                end
            end,
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
        BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, prefixText, messageText, channelName, _, sender)
            if prefixText ~= C.PREFIX_AUX or channelName ~= "RAID" then return end
            if sender == player or not BG.IsMLByName(sender) then return end
            local cmd, itemID, link, buyer, money = strsplit("^", messageText)
            if cmd ~= C.OP_REFUND_TO_FAILED then return end
            if GetTime() - (cd[sender] or 0) > 1 then
                cd[sender] = GetTime()
                itemID = tonumber(itemID)
                if not (itemID and link and buyer and money) then return end
                local _, v = FindAuctionLog(itemID, buyer, money)
                if not v then return end
                BG.pendingRefundAuctionToFailed = {
                    sender = sender,
                    itemID = itemID,
                    link = v.zhuangbei or link,
                    buyer = buyer,
                    money = money,
                }
                StaticPopup_Show(name)
            end
        end)
    end
end)

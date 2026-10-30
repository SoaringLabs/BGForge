if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local SendGateway = ns.SendGateway
local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID
local ver = ns.ver
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()

local tradeFrameMaxButton = 15
local tradeFrameButtonHeight = 32

local function CreateLine(parent, y, width, height, color, alpha)
    local line = parent:CreateLine()
    line:SetColorTexture(RGB(color or "808080", alpha or 1))
    line:SetStartPoint("BOTTOMLEFT", 0, y)
    line:SetEndPoint("BOTTOMLEFT", width, y)
    line:SetThickness(height or 1.5)
    return line
end

local SendSystemMessage = BG.SendSystemMessage

local function AddIconByLink(link)
    local icon = select(5, GetItemInfoInstant(link))
    return AddTexture(icon)
end

local FONT_FLAGS = "OUTLINE"
local CHATFRAME_BG = "Interface/ChatFrame/ChatFrameBackground"
local FRAME_TEMPLATE = "BackdropTemplate"
local TRADE_LOG_PREFIX = "BGForge: "
local TRADE_COLUMN_FONT_SIZE = 14

local BACKDROP_EDGED = { bgFile = CHATFRAME_BG, edgeFile = CHATFRAME_BG, edgeSize = 1 }
local BACKDROP_FLAT = { bgFile = CHATFRAME_BG }

local TRADE_COLUMNS = {
    { name = L["序号"], width = 40, color = "808080", JustifyH = "CENTER", Enable = false, fontSize = 12 },
    { name = L["时间"], width = 70, color = "FFFFFF", JustifyH = "CENTER", Enable = true, fontSize = 12 },
    { name = L["地点"], width = 70, color = "FFFFFF", JustifyH = "CENTER", Enable = true, fontSize = 13 },
    { name = L["角色"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
    { name = L["交易对象"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
    { name = L["交出"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = 13 },
    { name = L["收到"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = 13 },
    { name = L["交易前财产"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = 13 },
    { name = L["交易后财产"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = 13 },
}

local TRADE_TITLE_WIDTH = 0
for _, column in ipairs(TRADE_COLUMNS) do
    TRADE_TITLE_WIDTH = TRADE_TITLE_WIDTH + column.width
end

local TRADE_SIDE_ORDER = { "player", "target" }
local TRADE_SIDE_LAYOUT = {
    player = { x = 10, y = -10 },
    target = { x = 10, y = 0, anchor = "playerNameText" },
}

local function SetOutlineFont(fontString, size)
    fontString:SetFont(BIAOGE_TEXT_FONT, size, FONT_FLAGS)
end

local function ApplyPanel(frame, backdrop, r, g, b, a)
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(r, g, b, a)
end

local function ResolveTradeMessageChannel()
    local channel = BiaoGe.options["tradeMSG_channel"]
    if channel == "WHISPER" then
        return channel
    end
    if IsInRaid(1) then
        return "RAID"
    end
    if IsInGroup(1) then
        return "PARTY"
    end
end

local function BuildTradeSideText(items, amount, label)
    local money = floor(amount / 1e4)
    local moneyText = money ~= 0 and (money .. "g") or ""
    local itemText = ""
    for i = 1, 6 do
        local v = items[i]
        if v then
            itemText = itemText .. v.item
            if v.count > 1 then
                itemText = itemText .. "x" .. v.count
            end
        end
    end
    local text = moneyText
    if moneyText ~= "" and itemText ~= "" then
        text = moneyText .. " "
    end
    text = text .. itemText
    if text ~= "" then
        text = label .. text
    end
    return text
end

local function BuildTradeItemSummary(items, amount)
    local itemText = ""
    local count = 0
    local item
    for i = 1, 6 do
        local v = items[i]
        if v then
            count = count + 1
            item = AddIconByLink(v.item) .. v.item
        end
    end
    if count == 1 then
        itemText = item
    elseif count > 1 then
        itemText = "|A:ParagonReputation_Bag:0:0|a" .. "x" .. count
    end
    local moneyText = ""
    if amount > 0 then
        moneyText = GetMoneyString(amount, true)
    end
    local split = ""
    if itemText ~= "" and moneyText ~= "" then
        split = ", "
    end
    return itemText .. split .. moneyText
end

local function TradeFieldOrder(a, b, key)
    if BiaoGe.tradeHistory.Order == 1 then
        return a[key] > b[key]
    end
    return b[key] > a[key]
end

local function TradeFrameOnShow(self)
    local ctx = self.tradeUI
    ctx.UpdateScrollFrame()
    ctx.UpdateButtons()
end

local function TradeBarOnUpdate(self, t)
    local ctx = self.tradeUI
    ctx.UpdateButtons()
    ctx.UpdateScrollButtonState()
    ctx.mainFrame.infoFrame:Hide()
    self:SetScript("OnUpdate", nil)
end

local function TradeBarOnValueChanged(self)
    self:SetScript("OnUpdate", TradeBarOnUpdate)
end

local function TradeCellOnEnter(self)
    local ctx = self.tradeUI
    local buttons = ctx.buttons
    local num = self.num
    ctx.mainFrame.frame.lastButtonNum = num
    for _, row in ipairs(buttons) do
        row[1].ds:Hide()
    end
    buttons[num][1].ds:Show()
    if self.onenter then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self.onenter, 1, 1, 1, true)
        GameTooltip:Show()
    end
    BG.ShowTradeHistoryInfo(self)
    ctx.StopTime()
end

local function TradeCellOnLeave(self)
    local ctx = self.tradeUI
    ctx.buttons[self.num][1].ds:Hide()
    GameTooltip:Hide()
    ctx.StartTime()
end

local function TradeCellOnMouseUp(self, button)
    if button ~= "RightButton" then return end
    local ctx = self.tradeUI
    local num = (floor(ctx.bar:GetValue()) or 0) + self.num
    local info = ctx.GetButtonInfo(num)
    local menu = {
        {
            text = info[4],
            isTitle = true,
            notCheckable = true,
        },
        {
            text = "   ",
            isTitle = true,
            notCheckable = true,
        },
        {
            text = L["删除该条记录"],
            notCheckable = true,
            func = function()
                local record = ctx.db[num]
                tremove(BiaoGe.tradeHistory[ctx.choose.realmID][record.player].info, record.i)
                ctx.UpdateScrollFrame()
                ctx.UpdateButtons()
                BG.PlaySound(1)
            end
        },
        {
            text = CANCEL,
            notCheckable = true,
            func = LibBG.CloseDropDownMenus,
        }
    }
    LibBG:EasyMenu(menu, BG.dropDown, "cursor", 0, 0, "MENU", 2)
    BG.PlaySound(1)
end

local function TradeHeaderOnClick(self)
    local ctx = self.tradeUI
    BG.PlaySound(1)
    ctx.mainFrame.isnewsorter = nil
    if BiaoGe.tradeHistory.OrderButtonID ~= self.id then
        ctx.mainFrame.isnewsorter = true
    end
    if not ctx.mainFrame.isnewsorter then
        BiaoGe.tradeHistory.Order = BiaoGe.tradeHistory.Order == 1 and 0 or 1
    end
    BiaoGe.tradeHistory.OrderButtonID = self.id
    ctx.UpdateScrollFrame()
    ctx.UpdateButtons()
end

local function TradeInfoOnEnter(self)
    local ctx = self.tradeUI
    ctx.StopTime()
    ctx.buttons[ctx.mainFrame.frame.lastButtonNum][1].ds:Show()
end

local function TradeInfoOnLeave(self)
    self.tradeUI.StartTime()
end

local function TradeInfoOnHide(self)
    local ctx = self.tradeUI
    ctx.buttons[ctx.mainFrame.frame.lastButtonNum][1].ds:Hide()
end

local function TradeItemOnEnter(self)
    local ctx = self.tradeUI
    ctx.StopTime()
    ctx.buttons[ctx.mainFrame.frame.lastButtonNum][1].ds:Show()
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
        GameTooltip:ClearLines()
        GameTooltip:SetHyperlink(self.link)
    end
end

local function TradeItemOnLeave(self)
    GameTooltip:Hide()
    self.tradeUI.StartTime()
end

local function TradeNameOnEnter(self)
    local ctx = self.tradeUI
    ctx.StopTime()
    ctx.buttons[ctx.mainFrame.frame.lastButtonNum][1].ds:Show()
end

local function TradeNameOnLeave(self)
    self.tradeUI.StartTime()
end

local function NewDropDownInfo(text, checked, func)
    local info = LibBG:UIDropDownMenu_CreateInfo()
    info.text = text
    if checked then
        info.checked = true
    end
    info.func = func
    return info
end

local function PlayerMenuColorName(v)
    return "|c" .. select(4, GetClassColor(v.class)) .. v.name
end

local function PlayerMenuLabel(v)
    return "  " .. PlayerMenuColorName(v) .. (v.level and (" (" .. v.level .. ")") or "")
end

local function TradePlayerMenuInit(self, level)
    local dropDown = self
    local ctx = self.tradeUI
    local choose = ctx.choose
    for _realmID, realmTable in pairs(BiaoGe.tradeHistory) do
        if type(realmTable) == "table" then
            if next(realmTable) then
                local realmLabel = BG.STC_y2(BiaoGe.realmName[_realmID] or _realmID)
                local info = NewDropDownInfo(realmLabel, not choose.player and _realmID == choose.realmID, function()
                    choose.realmID = _realmID
                    choose.player = nil
                    BiaoGe.tradeHistory.isChooseRealm = 1
                    LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[_realmID] or _realmID) .. " - " .. L["全部角色"]))
                    ctx.UpdateScrollFrame()
                    ctx.UpdateButtons()
                end)
                LibBG:UIDropDownMenu_AddButton(info)
            end
            for _, v in pairs(realmTable) do
                local playerName = PlayerMenuColorName(v)
                local realmName = BiaoGe.realmName[_realmID] or _realmID
                local info = NewDropDownInfo(PlayerMenuLabel(v), v.name == choose.player and v.realmID == choose.realmID, function()
                    choose.realmID = v.realmID
                    choose.player = v.name
                    BiaoGe.tradeHistory.isChooseRealm = 0
                    LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[v.realmID] or v.realmID) .. " - ") .. playerName)
                    ctx.UpdateScrollFrame()
                    ctx.UpdateButtons()
                end)
                info.arg1 = v.realmID .. "-" .. v.name
                info.arg2 = "|cffFFD100" .. realmName .. "-|r|c" .. select(4, GetClassColor(v.class)) .. v.name .. "|r"
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end
    end
end

local function TradePlayerButtonOnEnter(button)
    if L_DropDownList1.dropdown ~= button.tradeMainFrame.dropDown then return end
    if not button.deleteTradePlayer then
        local bt = CreateFrame("Button", nil, button)
        bt:SetSize(15, 15)
        bt:SetPoint("RIGHT", -2, 0)
        bt:SetNormalTexture("interface/raidframe/readycheck-notready")
        bt:SetHighlightTexture("interface/raidframe/readycheck-notready")
        bt:RegisterForClicks("AnyUp")
        bt.num = button.tradeIndex
        bt:Hide()
        button.deleteTradePlayer = bt
        bt:SetScript("OnClick", function(self)
            local dropDown = button.tradeMainFrame.dropDown
            dropDown.realmID, dropDown.player = strsplit("-", button.arg1)
            dropDown.realmID = tonumber(dropDown.realmID)
            dropDown.colorPlayer = button.arg2
            LibBG:CloseDropDownMenus()
            StaticPopup_Show("BiaoGe_DeleteTradeHistoryPlayer", dropDown.colorPlayer)
        end)
        bt:SetScript("OnEnter", function(self)
            button.isOnEnter = true
            LibBG:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
            button.Highlight:Show()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["删除该角色"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", function(self)
            LibBG:UIDropDownMenu_StartCounting(self:GetParent():GetParent())
            button.Highlight:Hide()
            GameTooltip:Hide()
        end)
        bt:SetScript("OnHide", function(self)
            self:Hide()
        end)
    end
    button.isOnEnter = true
    for ii = 1, _G['L_DropDownList1'].numButtons do
        local bt = _G["L_DropDownList1Button" .. ii]
        if bt.deleteTradePlayer then
            bt.deleteTradePlayer:Hide()
        end
    end
    if button.arg1 then
        button.deleteTradePlayer:Show()
    end
end

local function TradePlayerButtonOnLeave(button)
    if L_DropDownList1.dropdown ~= button.tradeMainFrame.dropDown then return end
    button.isOnEnter = false
    After(0, function()
        if not button.isOnEnter then
            button.deleteTradePlayer:Hide()
        end
    end)
end

local function CreateTradeSidePanel(frame, side, width, iconWidth, ctx)
    local layout = TRADE_SIDE_LAYOUT[side]
    local nameText = frame:CreateFontString()
    SetOutlineFont(nameText, 16)
    if layout.anchor then
        nameText:SetPoint("TOPLEFT", frame[layout.anchor], "TOPRIGHT", layout.x, layout.y)
    else
        nameText:SetPoint("TOPLEFT", layout.x, layout.y)
    end
    nameText:SetWidth(width)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    frame[side .. "NameText"] = nameText

    local moneyFrame = CreateFrame("Frame", nil, frame, FRAME_TEMPLATE)
    ApplyPanel(moneyFrame, BACKDROP_FLAT, 0, 0, 0, 0.5)
    moneyFrame:SetSize(width, 22)
    moneyFrame:SetPoint("TOPLEFT", frame[side .. "NameText"], "BOTTOMLEFT", 0, -5)
    local moneyText = moneyFrame:CreateFontString()
    SetOutlineFont(moneyText, 13)
    moneyText:SetAllPoints()
    moneyText:SetJustifyH("LEFT")
    frame[side .. "MoneyText"] = moneyText

    for i = 1, 7 do
        local itemFrame = CreateFrame("Frame", nil, frame, FRAME_TEMPLATE)
        ApplyPanel(itemFrame, BACKDROP_EDGED, 0, 0, 0, 0)
        itemFrame:SetBackdropBorderColor(1, 1, 1, .4)
        itemFrame:SetSize(iconWidth, iconWidth)
        if i == 1 then
            itemFrame:SetPoint("TOPLEFT", frame[side .. "MoneyText"], "BOTTOMLEFT", 0, -10)
        else
            itemFrame:SetPoint("TOPLEFT", frame[side .. "item" .. (i - 1)], "BOTTOMLEFT", 0, i == 7 and -15 or -2)
        end
        frame[side .. "item" .. i] = itemFrame
        itemFrame.tradeUI = ctx
        itemFrame:HookScript("OnEnter", TradeItemOnEnter)
        itemFrame:HookScript("OnLeave", TradeItemOnLeave)

        itemFrame.icon = itemFrame:CreateTexture(nil, "BACKGROUND")
        itemFrame.icon:SetAllPoints()
        itemFrame.icon:SetTexCoord(.07, .93, .07, .93)

        itemFrame.count = itemFrame:CreateFontString()
        SetOutlineFont(itemFrame.count, 13)
        itemFrame.count:SetPoint("BOTTOMRIGHT", -1, 1)

        itemFrame.level = itemFrame:CreateFontString()
        SetOutlineFont(itemFrame.level, 11)
        itemFrame.level:SetPoint("BOTTOM", 1, 1)

        local nameFrame = CreateFrame("Frame", nil, frame, FRAME_TEMPLATE)
        ApplyPanel(nameFrame, BACKDROP_FLAT, .5, .5, .5, 0.1)
        nameFrame:SetSize(width - iconWidth - 2, iconWidth)
        nameFrame:SetPoint("LEFT", itemFrame, "RIGHT", 2, 0)
        nameFrame.tradeUI = ctx
        itemFrame.name = nameFrame:CreateFontString()
        SetOutlineFont(itemFrame.name, 14)
        itemFrame.name:SetAllPoints()
        itemFrame.name:SetJustifyH("LEFT")
        nameFrame:HookScript("OnEnter", TradeNameOnEnter)
        nameFrame:HookScript("OnLeave", TradeNameOnLeave)
    end
end

local function FillTradeSide(frame, side, v)
    local nameText = frame[side .. "NameText"]
    nameText:SetText(v[side .. "Name"])
    local r, g, b = .5, .5, .5
    if v[side .. "Class"] then
        r, g, b = GetClassColor(v[side .. "Class"])
    end
    nameText:SetTextColor(r, g, b)
    local moneyText = frame[side .. "MoneyText"]
    if v[side .. "money"] == 0 then
        moneyText:SetText("")
    else
        moneyText:SetText(GetMoneyString(v[side .. "money"], true))
    end
    for i = 1, 7 do
        local vv = v[side .. "items"][i]
        local itemFrame = frame[side .. "item" .. i]
        if vv then
            local qr, qg, qb = GetItemQualityColor(vv.quality)
            local iconID, typeID = select(5, GetItemInfoInstant(vv.item))
            itemFrame.link = vv.item
            itemFrame.itemID = GetItemID(vv.item)
            itemFrame:SetBackdropBorderColor(qr, qg, qb, 1)
            itemFrame.icon:SetTexture(iconID)
            itemFrame.count:SetText(vv.count > 1 and vv.count or "")
            itemFrame.name:SetText(vv.name)
            itemFrame.name:SetTextColor(qr, qg, qb)
            itemFrame.level:SetText("")
            if typeID == 2 or typeID == 4 then
                local link = vv.item
                local item = Item:CreateFromItemLink(link)
                item:ContinueOnItemLoad(function()
                    if itemFrame.link == link then
                        local level = select(4, GetItemInfo(link))
                        if level then
                            itemFrame.level:SetText(level)
                        end
                    end
                end)
            end
        else
            itemFrame.link = nil
            itemFrame.itemID = nil
            itemFrame:SetBackdropBorderColor(1, 1, 1, .4)
            itemFrame.icon:SetTexture(nil)
            itemFrame.name:SetText("")
            itemFrame.count:SetText("")
            itemFrame.level:SetText("")
        end
    end
end

local function EnsureCurrentCharacter()
    local tradeHistory = BiaoGe.tradeHistory
    tradeHistory[realmID] = tradeHistory[realmID] or {}
    tradeHistory[realmID][player] = tradeHistory[realmID][player] or {
        name = player,
        realmID = realmID,
        info = {},
    }
    tradeHistory[realmID][player].class = select(2, UnitClass("player"))
    tradeHistory[realmID][player].level = UnitLevel("player")
end

local function RoadTrade()
    local mainFrame
    local trade = {}

    -- 交易事件
    do
        local function GetTradeInfo()
            trade = {
                time = GetServerTime(),
                zone = GetZoneText(),
                beforeMoney = GetMoney(),
                playerName = UnitName("player"),
                targetName = UnitName("NPC"),
                playerClass = select(2, UnitClass("player")),
                targetClass = select(2, UnitClass("NPC")),
                playermoney = GetPlayerTradeMoney(),
                targetmoney = GetTargetTradeMoney(),
                playeritems = {},
                targetitems = {},
            }
            for i = 1, 7 do
                local link = GetTradePlayerItemLink(i)
                local name, texture, quantity, quality, isUsable, enchant = GetTradePlayerItemInfo(i)
                if link then
                    trade.playeritems[i] = { name = name, item = link, count = quantity, quality = quality, }
                end

                local link = GetTradeTargetItemLink(i)
                local name, texture, quantity, quality, isUsable, enchant = GetTradeTargetItemInfo(i)
                if link then
                    trade.targetitems[i] = { name = name, item = link, count = quantity, quality = quality, }
                end
            end
        end

        local target
        local success
        -- 密语前缀（自定义前缀，避免使用其它插件的）
        local logo = TRADE_LOG_PREFIX
        local f = CreateFrame("Frame")
        f:RegisterEvent("TRADE_ACCEPT_UPDATE")
        f:RegisterEvent("UI_INFO_MESSAGE")
        f:RegisterEvent("TRADE_CLOSED")
        f:RegisterEvent("TRADE_SHOW")
        f:SetScript("OnEvent", function(self, event, ...)
            if event == "TRADE_ACCEPT_UPDATE" then
                local playerAccepted, targetAccepted = ...
                if playerAccepted == 1 or targetAccepted == 1 then
                    GetTradeInfo()
                end
            elseif event == "UI_INFO_MESSAGE" then
                local _, text = ...
                if text == ERR_TRADE_COMPLETE then
                    success = true
                    if not trade.time then
                        GetTradeInfo()
                    end
                    local record = BG.Copy(trade)
                    tinsert(BiaoGe.tradeHistory[realmID][player].info, record)
                    After(.5, function()
                        record.afterMoney = GetMoney()
                        if BG.TradeHistoryMainFrame.frame:IsVisible() then
                            BG.UpdateTradeHistoryScrollFrame()
                        end
                    end)

                    if BiaoGe.options.tradeSuccessSound == 1 then
                        BG.PlaySound("tradeSuccess")
                    end
                    if BiaoGe.options.tradeMSG == 1 and BiaoGe.options.tradeMSG_success == 1 then
                        local channel = ResolveTradeMessageChannel()
                        if channel then
                            local giveText = BuildTradeSideText(trade.playeritems, trade.playermoney, L["(交出)"])
                            local getText = BuildTradeSideText(trade.targetitems, trade.targetmoney, L["(收到)"])
                            local msg
                            if giveText ~= "" and getText ~= "" then
                                msg = giveText .. L["，"] .. getText
                            else
                                msg = giveText .. getText
                            end
                            SendGateway.Chat(logo .. format(L["与<%s>交易成功！%s"], channel == "WHISPER" and L["你"] or target, msg), channel, nil, target)
                        end
                    end
                elseif text == ERR_TRADE_CANCELLED or text == ERR_TRADE_BAG_FULL or text == ERR_TRADE_TARGET_BAG_FULL then
                end
            elseif event == "TRADE_SHOW" then
                success = false
                target = UnitName("NPC")
            elseif event == "TRADE_CLOSED" then
                After(0, function()
                    if not success and target then
                        if BiaoGe.options.tradeFalseSound == 1 then
                            BG.PlaySound("tradeFalse")
                        end
                        if BiaoGe.options.tradeMSG == 1 and BiaoGe.options.tradeMSG_false == 1 then
                            local channel = ResolveTradeMessageChannel()
                            if channel then
                                SendGateway.Chat(logo .. format(L["与<%s>交易失败！"], channel == "WHISPER" and L["你"] or target),
                                    channel, nil, target)
                            end
                        end
                    end
                end)
            end
        end)
    end

    mainFrame = BG.TradeHistoryMainFrame

    -- UI
    do
        local mainFrame = BG.TradeHistoryMainFrame
        local choose = {
            realmID = realmID,
            player = player,
        }
        if BiaoGe.tradeHistory.isChooseRealm == 1 then choose.player = nil end
        local BUTTONHEIGHT = tradeFrameButtonHeight
        local MAXBUTTONS = tradeFrameMaxButton
        local WIDTH = 10 + 27 + TRADE_TITLE_WIDTH
        local HEIGHT = (MAXBUTTONS + 1) * BUTTONHEIGHT + 15
        local titleWidth = TRADE_TITLE_WIDTH
        local db = {}
        local titlebuttons = {}
        local buttons = {}
        local dropDown
        local titleTbl = TRADE_COLUMNS
        local tradeCtx = {
            mainFrame = mainFrame,
            choose = choose,
            db = db,
            buttons = buttons,
        }

        local f, scroll, child, bar
        local GetDB, UpdateScrollFrame, UpdateScrollButtonState, GetButtonInfo, UpdateButtons
        local updateFrame = CreateFrame("Frame")
        local StartTime, StopTime
        do
            f = CreateFrame("Frame", nil, mainFrame, FRAME_TEMPLATE)
            ApplyPanel(f, BACKDROP_EDGED, 0, 0, 0, 0.4)
            f:SetBackdropBorderColor(1, 1, 1, .8)
            f:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 10, -65 - (BG.MainNavigationHeight or 0))
            f:SetSize(WIDTH + 5, HEIGHT)
            f:EnableMouse(true)
            mainFrame.frame = f
            f.tradeUI = tradeCtx
            f:SetScript("OnShow", TradeFrameOnShow)

            scroll = CreateFrame("ScrollFrame", nil, f, BG.scrollTemplate) -- 滚动
            scroll:SetWidth(WIDTH - 27 + 5)
            scroll:SetHeight(BUTTONHEIGHT * MAXBUTTONS)
            scroll:SetPoint("TOPLEFT", 0, -12 - BUTTONHEIGHT)
            bar = scroll.ScrollBar
            bar.scrollStep = 5
            bar.tradeUI = tradeCtx
            tradeCtx.bar = bar
            BG.CreateSrollBarBackdrop(bar)
            bar:HookScript("OnValueChanged", TradeBarOnValueChanged)

            child = CreateFrame("Frame", nil, f) -- 子框架
            child:SetWidth(scroll:GetWidth())
            child:SetHeight(scroll:GetHeight())
            scroll:SetScrollChild(child)

            for ii = 1, MAXBUTTONS do
                buttons[ii] = {}
                for i = 1, #titleTbl do
                    local cell = CreateFrame("Frame", nil, scroll)
                    cell:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                    if ii == 1 and i == 1 then
                        cell:SetPoint("TOPLEFT", scroll, 10, 0)
                        cell:SetParent(scroll)
                    elseif i == 1 then
                        cell:SetPoint("TOPLEFT", buttons[(ii - 1)][1], "BOTTOMLEFT", 0, 0)
                        cell:SetParent(scroll)
                    else
                        cell:SetPoint("LEFT", buttons[ii][i - 1], "RIGHT", 0, 0)
                        cell:SetParent(buttons[ii][1])
                    end
                    cell.num = ii
                    cell.tradeUI = tradeCtx
                    buttons[ii][i] = cell

                    cell.Text = cell:CreateFontString()
                    SetOutlineFont(cell.Text, titleTbl[i].fontSize or TRADE_COLUMN_FONT_SIZE)
                    cell.Text:SetPoint("CENTER")
                    cell.Text:SetTextColor(RGB(titleTbl[i].color))
                    cell.Text:SetJustifyH(titleTbl[i].JustifyH)
                    cell.Text:SetWidth(cell:GetWidth() - 2)
                    cell.Text:SetHeight(cell:GetHeight())

                    cell:SetScript("OnEnter", TradeCellOnEnter)
                    cell:SetScript("OnLeave", TradeCellOnLeave)
                    cell:SetScript("OnMouseUp", TradeCellOnMouseUp)
                end
                CreateLine(buttons[ii][1], 0, titleWidth, 1, nil, 0.2)

                -- 底色材质
                local cell = buttons[ii][1]
                cell.ds = cell:CreateTexture()
                cell.ds:SetPoint("TOPLEFT", 0, 0)
                cell.ds:SetPoint("BOTTOMRIGHT", buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)
                cell.ds:SetColorTexture(1, 1, 1, 0.1)
                cell.ds:Hide()
            end
        end
        -- 删除记录
        do
            local function DeleteTradeData()
                local now = GetServerTime()
                local saveDuration = BiaoGe.tradeHistory.saveDuration
                if saveDuration > 0 then
                    local cutoff = now - 86400 * saveDuration
                    for _, realmTable in pairs(BiaoGe.tradeHistory) do
                        if type(realmTable) == "table" then
                            for _, charTable in pairs(realmTable) do
                                local info = charTable.info
                                for i = #info, 1, -1 do
                                    if (info[i].time or 0) < cutoff then
                                        tremove(info, i)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            DeleteTradeData()

            local text = mainFrame:CreateFontString()
            text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 260, 10)
            SetOutlineFont(text, 15)
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["保存时长："])
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("LEFT", text, "RIGHT", -15, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 80)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            for i, v in ipairs(BG.saveDays) do
                if v.day == BiaoGe.tradeHistory.saveDuration then
                    LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                    break
                end
            end
            BG.dropDownToggle(dropDown)
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for i, v in ipairs(BG.saveDays) do
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    info.text = v.text
                    if v.day == BiaoGe.tradeHistory.saveDuration then
                        info.checked = true
                    end
                    info.func = function()
                        BiaoGe.tradeHistory.saveDuration = v.day
                        DeleteTradeData()
                        LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                        UpdateScrollFrame()
                        UpdateButtons()
                    end
                    LibBG:UIDropDownMenu_AddButton(info)
                end
            end)
        end
        -- 选择角色
        do
            local text = mainFrame:CreateFontString()
            text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 10)
            SetOutlineFont(text, 15)
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["角色："])
            dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("LEFT", text, "RIGHT", -15, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 180)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            BG.dropDownToggle(dropDown)
            mainFrame.dropDown = dropDown
            if BiaoGe.tradeHistory.isChooseRealm == 1 then
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - " .. L["全部角色"]))
            else
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - ") .. SetClassCFF(player, "player"))
            end

            dropDown.tradeUI = tradeCtx
            LibBG:UIDropDownMenu_Initialize(dropDown, TradePlayerMenuInit)

            -- 删除角色
            for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
                local button = _G["L_DropDownList1Button" .. i]
                button.tradeMainFrame = mainFrame
                button.tradeIndex = i
                button:HookScript("OnEnter", TradePlayerButtonOnEnter)
                button:HookScript("OnLeave", TradePlayerButtonOnLeave)
            end
            StaticPopupDialogs["BiaoGe_DeleteTradeHistoryPlayer"] = {
                text = L["确认删除%s的交易记录？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    LibBG:ToggleDropDownMenu(nil, nil, mainFrame.dropDown)
                    for i = 1, _G['L_DropDownList1'].numButtons do
                        local button = _G["L_DropDownList1Button" .. i]
                        if button.arg1 then
                            local _realmID, _player = strsplit("-", button.arg1)
                            _realmID = tonumber(_realmID)
                            if _realmID == realmID and _player == player then
                                button:Click()
                                break
                            end
                        end
                    end
                    local _realmID, _player = dropDown.realmID, dropDown.player
                    BiaoGe.tradeHistory[_realmID][_player] = nil
                    if _realmID == realmID and _player == player then
                        EnsureCurrentCharacter()
                    end
                    BG.UpdateTradeHistoryScrollFrame()
                    SendSystemMessage(format(L["已删除%s的交易记录。"], dropDown.colorPlayer))
                end,
                OnCancel = function()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
        end
        -- 搜索
        do
            local edit = CreateFrame("EditBox", nil, f, 'SearchBoxTemplate')
            edit:SetSize(150, 22)
            edit:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -5)
            edit.Instructions:SetText(L["搜索交易对象"])
            mainFrame.serachEdit = edit
            BG.SetEditBaseClass(edit)
            edit:HookScript("OnTextChanged", function(self)
                BG.UpdateTradeHistoryScrollFrame()
            end)
            edit:HookScript("OnEditFocusGained", function(self)
                BG.lastfocus = self
                if BG.GetVerNum(BG.ver) >= 12820 then
                    BG.SetListmaijia(self, true, nil, nil, true)
                end
            end)
            edit:HookScript("OnEditFocusLost", function(self)
                if BG.FrameMaijiaList then BG.FrameMaijiaList:Hide() end
            end)
        end
        -- 标题
        do
            for i, v in ipairs(titleTbl) do
                local bt = CreateFrame("Button", nil, f, FRAME_TEMPLATE)
                bt:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                if i == 1 then
                    bt:SetPoint("TOPLEFT", 10, -10)
                else
                    bt:SetPoint("LEFT", titlebuttons[i - 1], "RIGHT", 0, 0)
                    bt:SetParent(titlebuttons[i - 1])
                end
                bt:SetNormalFontObject(BG["FontWhite" .. TRADE_COLUMN_FONT_SIZE])
                bt:SetText(titleTbl[i].name)
                bt.textwidth = bt:GetFontString():GetStringWidth()
                bt.textJustifyH = titleTbl[i].JustifyH
                bt.sortOrder = 1
                bt.id = i
                bt.tradeUI = tradeCtx
                bt:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
                bt:SetEnabled(v.Enable)
                tinsert(titlebuttons, bt)

                bt.Text = bt:GetFontString()
                bt.Text:SetJustifyH(titleTbl[i].JustifyH)
                bt.Text:SetWidth(bt:GetWidth())
                bt.Text:SetWordWrap(false)

                bt:SetScript("OnClick", TradeHeaderOnClick)
            end
            CreateLine(titlebuttons[1], 0, titleWidth)
            -- 排序材质
            local sorter = mainFrame:CreateTexture(nil, "OVERLAY")
            sorter:SetSize(8, 8)
            sorter:SetTexture("Interface/Buttons/ui-sortarrow")
            mainFrame.sorter = sorter
            -- 提示
            local t = scroll:CreateFontString()
            SetOutlineFont(t, 15)
            t:SetPoint("TOP", 0, -5)
            t:SetTextColor(.5, .5, .5)
            t:SetText(L["该角色没有交易记录。"])
            mainFrame.notText = t
        end

        -- 刷新滚动框
        local function SearchText(v)
            local searchText = mainFrame.serachEdit:GetText()
            if searchText == "" then
                return true
            end
            if v.targetName and v.targetName:find(searchText, 1, true) then
                return true
            end
        end
        function GetDB()
            local realmID = choose.realmID
            local playerTbl = {}
            wipe(db)
            if choose.player then
                playerTbl = { choose.player }
            else
                for player, v in pairs(BiaoGe.tradeHistory[realmID]) do
                    tinsert(playerTbl, player)
                end
            end

            for _, player in pairs(playerTbl) do
                for i, v in ipairs(BiaoGe.tradeHistory[realmID][player].info) do
                    if SearchText(v) then
                        tinsert(db, BG.Copy(v))
                        db[#db].i = i
                        db[#db].player = player
                    end
                end
            end

            sort(db, function(a, b)
                local orderId = BiaoGe.tradeHistory.OrderButtonID
                if orderId == 2 then -- 按时间
                    if a.time and b.time and a.time ~= b.time then
                        return TradeFieldOrder(a, b, "time")
                    end
                elseif orderId == 3 then -- 按地点
                    if a.zone and b.zone then
                        if a.zone ~= b.zone then
                            return TradeFieldOrder(a, b, "zone")
                        end
                        if a.time and b.time and a.time ~= b.time then
                            return TradeFieldOrder(a, b, "time")
                        end
                    end
                end
                return false
            end)
        end

        function UpdateScrollFrame()
            GetDB()

            local sorter = mainFrame.sorter
            local bt = titlebuttons[BiaoGe.tradeHistory.OrderButtonID]
            sorter:SetParent(bt)
            sorter:ClearAllPoints()
            if bt.textJustifyH == "CENTER" then
                sorter:SetPoint("LEFT", bt, "CENTER", bt.textwidth / 2, 0)
            else
                sorter:SetPoint("LEFT", bt, "LEFT", bt.textwidth, 0)
            end
            if not mainFrame.isnewsorter then
                if BiaoGe.tradeHistory.Order == 1 then
                    sorter:SetTexCoord(0, 0.5, 0, 1)
                else
                    sorter:SetTexCoord(0, 0.5, 1, 0)
                end
            end

            local m = #db - MAXBUTTONS
            bar:SetMinMaxValues(0, max(0, m))
            if scroll.SetScrollExtent then
                scroll:SetScrollExtent(MAXBUTTONS, #db)
            end
            UpdateScrollButtonState()

            mainFrame.notText:SetShown(#db == 0)
        end

        function UpdateScrollButtonState()
            if bar.ThumbButton then return end
            local currValue = bar:GetValue();
            local scrollDownButton = bar.ScrollDownButton or _G[bar:GetName() .. "ScrollDownButton"];
            local scrollUpButton = bar.ScrollUpButton or _G[bar:GetName() .. "ScrollUpButton"];
            scrollUpButton:Enable();
            scrollDownButton:Enable();
            local minVal, maxVal = bar:GetMinMaxValues();
            if (currValue >= maxVal) then
                if (scrollDownButton) then
                    scrollDownButton:Disable()
                end
            end
            if (currValue <= minVal) then
                if (scrollUpButton) then
                    scrollUpButton:Disable();
                end
            end
        end

        function GetButtonInfo(num)
            local v = db[num]
            if not v then return end

            return {
                num, -- 序号
                date("%m-%d\n%H:%M", v.time), -- 时间
                v.zone, -- 地点
                "|c" .. select(4, GetClassColor(v.playerClass)) .. v.playerName .. "|r", -- 角色
                "|c" .. select(4, GetClassColor(v.targetClass)) .. v.targetName .. "|r", -- 交易对象
                BuildTradeItemSummary(v.playeritems, v.playermoney), -- 交出
                BuildTradeItemSummary(v.targetitems, v.targetmoney), -- 收到
                GetMoneyString(floor(v.beforeMoney / 1e4) * 10000, true), -- 交易前财产
                v.afterMoney and GetMoneyString(floor(v.afterMoney / 1e4) * 10000, true) or L["读取中"], -- 交易后财产
            }
        end

        function UpdateButtons()
            local value = floor(bar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local num = value + ii
                local tbl = GetButtonInfo(num)
                for i = 1, #titleTbl do
                    if tbl then
                        buttons[ii][i].Text:SetText(tbl[i])
                        buttons[ii][i].dbNum = num
                        if buttons[ii][i].Text:IsTruncated() then
                            buttons[ii][i].onenter = tbl[i]
                        else
                            buttons[ii][i].onenter = nil
                        end
                        buttons[ii][i]:Show()
                    else
                        buttons[ii][i]:Hide()
                    end
                end
            end
            GameTooltip:Hide()
        end

        tradeCtx.GetButtonInfo = GetButtonInfo
        tradeCtx.UpdateScrollFrame = UpdateScrollFrame
        tradeCtx.UpdateScrollButtonState = UpdateScrollButtonState
        tradeCtx.UpdateButtons = UpdateButtons

        function BG.UpdateTradeHistoryScrollFrame()
            UpdateScrollFrame()
            UpdateButtons()
        end

        -- 交易详细框
        do
            function StartTime()
                updateFrame.elapsed = 0
                updateFrame:SetScript("OnUpdate", function(self, elapsed)
                    self.elapsed = self.elapsed + elapsed
                    if self.elapsed >= .5 then
                        self:SetScript("OnUpdate", nil)
                        mainFrame.infoFrame:Hide()
                    end
                end)
            end

            function StopTime()
                updateFrame.elapsed = 0
                updateFrame:SetScript("OnUpdate", nil)
            end

            tradeCtx.StartTime = StartTime
            tradeCtx.StopTime = StopTime

            -- UI
            do
                local WIDTH = 120
                local ICON_WIDTH = 30

                local frame = CreateFrame("Frame", nil, mainFrame, FRAME_TEMPLATE)
                ApplyPanel(frame, BACKDROP_EDGED, 0, 0, 0, 0.4)
                frame:SetBackdropBorderColor(1, 1, 1, .8)
                frame:SetPoint("TOPLEFT", mainFrame.frame, "TOPRIGHT", 2, 0)
                frame:SetSize(WIDTH * 2 + 30, 310)
                frame:Hide()
                mainFrame.infoFrame = frame
                frame.tradeUI = tradeCtx
                frame:HookScript("OnEnter", TradeInfoOnEnter)
                frame:HookScript("OnLeave", TradeInfoOnLeave)
                frame:HookScript("OnHide", TradeInfoOnHide)

                frame.timeText = frame:CreateFontString()
                SetOutlineFont(frame.timeText, 13)
                frame.timeText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 2, 2)
                frame.timeText:SetTextColor(1, 1, 1)

                for _, side in ipairs(TRADE_SIDE_ORDER) do
                    CreateTradeSidePanel(frame, side, WIDTH, ICON_WIDTH, tradeCtx)
                end
            end

            function BG.ShowTradeHistoryInfo(self)
                local num = self.dbNum
                local v = db[num]
                local frame = mainFrame.infoFrame
                frame.timeText:SetText(date("%y/%m/%d %H:%M", v.time))
                FillTradeSide(frame, "player", v)
                FillTradeSide(frame, "target", v)
                mainFrame.infoFrame:Show()
            end
        end
    end

    -- 跳转到其他功能设置
    do
        local bt = BG.CreateButton(BG.TradeHistoryMainFrame)
        bt:SetSize(150, 25)
        bt:SetPoint("TOPLEFT", BG.TradeHistoryMainFrame.frame, "BOTTOMLEFT", 0, -5)
        bt:SetText(L["交易选项设置"])
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            BG.OpenOption()
            if BG.ButtonOptions_others then
                BG.ButtonOptions_others:Click()
            end
        end)
    end
end

BG.Init(function()
    BiaoGe.tradeHistory = BiaoGe.tradeHistory or {}
    local tradeHistory = BiaoGe.tradeHistory
    tradeHistory.saveDuration = tradeHistory.saveDuration or 7
    tradeHistory.OrderButtonID = tradeHistory.OrderButtonID or 2
    tradeHistory.Order = tradeHistory.Order or 1
    tradeHistory.isChooseRealm = tradeHistory.isChooseRealm or 1
    EnsureCurrentCharacter()

    if BiaoGe.disabledModules["TradeHistory"] then return end

    RoadTrade()
end)

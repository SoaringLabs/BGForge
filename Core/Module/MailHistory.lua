if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

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
local K = {
    player = "player",
    N_15 = 15,
    N_32 = 32,
    S_4 = "808080",
    BOTTOMLEFT = "BOTTOMLEFT",
    N_0 = 0,
    N_1_5 = 1.5,
    CheckButton = "CheckButton",
    ChatConfigCheckButtonTemplate = "ChatConfigCheckButtonTemplate",
    N_30 = 30,
    OUTLINE = "OUTLINE",
    OnClick = "OnClick",
    OnEnter = "OnEnter",
    ANCHOR_TOPLEFT = "ANCHOR_TOPLEFT",
    table = "table",
    OnLeave = "OnLeave",
    OnShow = "OnShow",
    N_2 = 2,
    send1 = "send1",
    send2 = "send2",
    Frame = "Frame",
    MAIL_SEND_INFO_UPDATE = "MAIL_SEND_INFO_UPDATE",
    UI_INFO_MESSAGE = "UI_INFO_MESSAGE",
    MAIL_SHOW = "MAIL_SHOW",
    OnEvent = "OnEvent",
    PLAYER_MONEY = "PLAYER_MONEY",
    EMPTY = "",
    S_28 = "(",
    S_29 = ")",
    buyer = "buyer",
    S_31 = " ",
    S_32 = "  ",
    S_33 = "\n",
    seller = "seller",
    S_35 = " + ",
    S_36 = " - ",
    x = "x",
    take2 = "take2",
    take1 = "take1",
    N_10 = 10,
    N_27 = 27,
    N_14 = 14,
    N_40 = 40,
    CENTER = "CENTER",
    N_70 = 70,
    FFFFFF = "FFFFFF",
    N_90 = 90,
    N_100 = 100,
    BackdropTemplate = "BackdropTemplate",
    TEX_CHATFRAMEBACKGROUND = "Interface/ChatFrame/ChatFrameBackground",
    N_0_4 = 0.4,
    TOPLEFT = "TOPLEFT",
    N_65 = 65,
    ScrollFrame = "ScrollFrame",
    N_12 = 12,
    OnValueChanged = "OnValueChanged",
    OnUpdate = "OnUpdate",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    OnMouseUp = "OnMouseUp",
    RightButton = "RightButton",
    S_62 = "   ",
    cursor = "cursor",
    MENU = "MENU",
    N_0_2 = 0.2,
    BOTTOMRIGHT = "BOTTOMRIGHT",
    N_0_1 = 0.1,
    N_86400 = 86400,
    N_260 = 260,
    N_3 = 3,
    N_80 = 80,
    TOP = "TOP",
    BOTTOM = "BOTTOM",
    N_180 = 180,
    TXT_C = "|c",
    S_76 = " (",
    S_77 = "-",
    COLOR_FFD100 = "|cffFFD100",
    TXT_R_C = "-|r|c",
    TXT_R = "|r",
    Button = "Button",
    TXT_INTERFACE_RAIDFRAME_READ = "interface/raidframe/readycheck-notready",
    AnyUp = "AnyUp",
    ANCHOR_RIGHT = "ANCHOR_RIGHT",
    OnHide = "OnHide",
    TOPRIGHT = "TOPRIGHT",
    N_120 = 120,
    S_88 = "  (",
    all = "all",
    FontWhite = "FontWhite",
    TEX_UI_CHARACTER_TAB_HIGHLIGHT = "Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight",
    OVERLAY = "OVERLAY",
    TEX_UI_SORTARROW = "Interface/Buttons/ui-sortarrow",
    time = "time",
    title = "title",
    N_0_5 = 0.5,
    TXT_A_PARAGONREPUTATION_BAG = "|A:ParagonReputation_Bag:0:0|a",
    S_98 = ", ",
    TXT_M_D_H_M = "%m-%d %H:%M",
    N_1e4 = 1e4,
    N_10000 = 10000,
    N_320 = 320,
    N_350 = 350,
    N_13 = 13,
    N_23 = 23,
    N_35 = 35,
    N_20 = 20,
    N_0_82 = 0.82,
    N_0_6 = 0.6,
    N_215 = 215,
    EditBox = "EditBox",
    N_85 = 85,
    send = "send",
    take = "take",
    TXT_Y_M_D_H_M = "%y/%m/%d %H:%M",
    N_0_05 = 0.05,
    N_6 = 6,
    ANCHOR_LEFT = "ANCHOR_LEFT",
    BACKGROUND = "BACKGROUND",
    N_11 = 11,
    N_7 = 7,
}

local player = UnitName(K.player)
local realmID = GetRealmID()
local realmName = BG.realmName
local SendSystemMessage = BG.SendSystemMessage

local mailFrameMaxButton = K.N_15
local mailFrameButtonHeight = K.N_32

local function CreateLine(parent, y, width, height, color, alpha)
    local line = parent:CreateLine()
    line:SetColorTexture(RGB(color or K.S_4, alpha or 1))
    line:SetStartPoint(K.BOTTOMLEFT, K.N_0, y)
    line:SetEndPoint(K.BOTTOMLEFT, width, y)
    line:SetThickness(height or K.N_1_5)
    return line
end

local function AddIconByLink(link)
    local icon = select(5, GetItemInfoInstant(link))
    return AddTexture(icon)
end

local function CreateCheckButton(name, text, parent, ontext)
    local button = CreateFrame(K.CheckButton, nil, parent, K.ChatConfigCheckButtonTemplate)
    button:SetSize(K.N_30, K.N_30)
    button.Text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
    button.Text:SetText(text)
    button:SetHitRectInsets(K.N_0, -button.Text:GetWidth(), K.N_0, K.N_0)
    button.name = name
    button.ontext = ontext
    BG.options["button" .. name] = button
    button:SetChecked(BiaoGe.options[name] == 1)
    button:SetScript(K.OnClick, function(self)
        BiaoGe.options[self.name] = self:GetChecked() and 1 or K.N_0
        BG.PlaySound(1)
    end)
    button:SetScript(K.OnEnter, function(self)
        if not self.ontext then return end
        GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
        GameTooltip:ClearLines()
        if type(self.ontext) == K.table then
            for i, tipText in ipairs(self.ontext) do
                if i == 1 then
                    GameTooltip:AddLine(tipText, 1, 1, 1, true)
                else
                    GameTooltip:AddLine(tipText, 1, .82, K.N_0, true)
                end
            end
            GameTooltip:Show()
        else
            GameTooltip:SetText(self.ontext)
        end
    end)
    button:SetScript(K.OnLeave, GameTooltip_Hide)
    button:SetScript(K.OnShow, function(self)
        self:SetChecked(BiaoGe.options[self.name] == 1)
    end)
    return button
end

local function EnsureCurrentCharacter()
    local mailHistory = BiaoGe.mailHistory
    mailHistory[realmID] = mailHistory[realmID] or {}
    mailHistory[realmID][player] = mailHistory[realmID][player] or {
        name = player,
        realmID = realmID,
        info = {},
    }
    mailHistory[realmID][player].class = select(K.N_2, UnitClass(K.player))
    mailHistory[realmID][player].level = UnitLevel(K.player)
end

local function RoadMail()
    local mainFrame

    -- 记录邮件
    do
        -- 寄出
        do
            local info
            local sentRecord
            local function Reset()
                info = {
                    giveMoney = K.N_0,
                    getMoney = K.N_0,
                    giveItem = {},
                    getItem = {},
                    type = K.send1,
                }
            end
            Reset()

            hooksecurefunc("SetSendMailMoney", function(money)
                info.type = K.send1
                if GetMoney() >= money then
                    info.giveMoney = money
                else
                    info.giveMoney = K.N_0
                end
            end)
            hooksecurefunc("SetSendMailCOD", function(money)
                if money > K.N_0 then
                    info.type = K.send2
                    if GetMoney() >= money then
                        info.giveMoney = money
                    else
                        info.giveMoney = K.N_0
                    end
                else
                    info.type = K.send1
                end
            end)
            hooksecurefunc("SendMail", function(name, title, text)
                info.name = name
                info.title = title
                info.text = text
                info.beforeMoney = GetMoney()
            end)

            local f = CreateFrame(K.Frame)
            f:RegisterEvent(K.MAIL_SEND_INFO_UPDATE)
            f:RegisterEvent(K.UI_INFO_MESSAGE)
            f:RegisterEvent(K.MAIL_SHOW)
            f:SetScript(K.OnEvent, function(self, event, ...)
                if event == K.MAIL_SEND_INFO_UPDATE then
                    wipe(info.giveItem)
                    for i = 1, ATTACHMENTS_MAX_SEND do
                        local name, itemID, texture, count, quality = GetSendMailItem(i)
                        if name then
                            tinsert(info.giveItem, {
                                itemID = itemID,
                                link = GetSendMailItemLink(i),
                                count = count,
                                quality = quality,
                            })
                        end
                    end
                elseif event == K.UI_INFO_MESSAGE then
                    local _, message = ...
                    if message == ERR_MAIL_SENT then
                        self:RegisterEvent(K.PLAYER_MONEY)
                        info.time = GetServerTime()
                        sentRecord = BG.Copy(info)
                        tinsert(BiaoGe.mailHistory[realmID][player].info, sentRecord)
                        -- 更新物品缓存
                        local player, realm = BG.SPN(info.name)
                        if not realm then
                            realm = realmName
                        end
                        local realmID
                        for _realmID, _realmName in pairs(BiaoGe.realmName) do
                            if realm == _realmName then
                                realmID = _realmID
                                break
                            end
                        end
                        if player and realmID then
                            if BiaoGe.playerInfo[realmID] and BiaoGe.playerInfo[realmID][player] then
                                BiaoGe.bag = BiaoGe.bag or {}
                                BiaoGe.bag[realmID] = BiaoGe.bag[realmID] or {}
                                BiaoGe.bag[realmID][player] = BiaoGe.bag[realmID][player] or {}
                                BiaoGe.bag[realmID][player].mail = BiaoGe.bag[realmID][player].mail or {}
                                for i, v in ipairs(info.giveItem) do
                                    local itemID = v.itemID
                                    BiaoGe.bag[realmID][player].mail[itemID] =
                                        (BiaoGe.bag[realmID][player].mail[itemID] or K.N_0) + v.count
                                end
                            end
                        end
                        -- 重置
                        Reset()
                        mainFrame:UpdateAllFrame()
                    end
                elseif event == K.MAIL_SHOW then
                    Reset()
                elseif event == K.PLAYER_MONEY then
                    self:UnregisterEvent(K.PLAYER_MONEY)
                    if sentRecord then
                        sentRecord.afterMoney = GetMoney()
                        sentRecord = nil
                    end
                end
            end)
        end

        -- 收件
        do
            -- new
            local tbl_noRead = {}
            local tbl_isRead = {}
            local last

            local function GetBodyText(mailIndex, bodyText, isInvoice)
                if isInvoice then
                    local invoiceType, itemName, playerName, bid, buyout, deposit, consignment,
                    moneyDelay, etaHour, etaMin, count, commerceAuction = GetInboxInvoiceInfo(mailIndex)
                    if not (playerName) then return bodyText end
                    local t = K.EMPTY
                    local buyMode;
                    if (bid == buyout) then
                        buyMode = K.S_28 .. BUYOUT .. K.S_29;
                    else
                        buyMode = K.S_28 .. HIGH_BIDDER .. K.S_29;
                    end
                    if (count and count > 1) then
                        itemName = format(AUCTION_MAIL_ITEM_STACK, itemName, count);
                    end
                    if (invoiceType == K.buyer) then
                        t = t .. BG.STC_y2(ITEM_PURCHASED_COLON) .. K.S_31 .. itemName .. K.S_32 .. buyMode .. K.S_33
                        t = t .. BG.STC_y2(SOLD_BY_COLON) .. K.S_31 .. playerName .. K.S_33
                        t = t .. BG.STC_y2(AMOUNT_PAID_COLON) .. GetMoneyString(bid) .. K.S_33
                    elseif (invoiceType == K.seller) then
                        t = t .. BG.STC_y2(ITEM_SOLD_COLON) .. K.S_31 .. itemName .. K.S_33
                        t = t .. BG.STC_y2(PURCHASED_BY_COLON) .. K.S_31 .. playerName .. K.S_32 .. buyMode .. K.S_33
                        t = t .. BG.STC_y2(SALE_PRICE_COLON) .. GetMoneyString(bid) .. K.S_33                                    -- 售价
                        t = t .. BG.STC_y2(DEPOSIT_COLON) .. BG.STC_g1(K.S_35) .. GetMoneyString(deposit) .. K.S_33               -- 保管费
                        t = t .. BG.STC_y2(AUCTION_HOUSE_CUT_COLON) .. BG.STC_r1(K.S_36) .. GetMoneyString(consignment) .. K.S_33 -- 拍卖费
                        t = t .. BG.STC_y2(AMOUNT_RECEIVED_COLON) .. GetMoneyString(bid + deposit - consignment) .. K.S_33       -- 收款金额
                    end
                    return t
                else
                    return bodyText
                end
            end

            local function GetMailInfo(mailIndex, wasRead, hasItem, daysLeft, sender, subject, money, CODAmount)
                local bodyText = K.EMPTY
                local _, isInvoice
                if wasRead then
                    bodyText, _, _, _, isInvoice = GetInboxText(mailIndex)
                    bodyText = GetBodyText(mailIndex, bodyText, isInvoice)
                end
                local getItem = {}
                local itemText = K.EMPTY
                if hasItem then
                    for itemIndex = 1, ATTACHMENTS_MAX_RECEIVE do
                        local name, itemID, texture, count, quality = GetInboxItem(mailIndex, itemIndex)
                        if name then
                            tinsert(getItem, {
                                itemID = itemID,
                                link = GetInboxItemLink(mailIndex, itemIndex),
                                count = count,
                                quality = quality,
                            })
                            itemText = itemText .. itemID .. K.x .. count .. K.S_31
                        end
                    end
                end
                return {
                    id = mailIndex,
                    daysLeft = daysLeft,
                    name = sender,
                    title = subject,
                    text = bodyText,
                    type = CODAmount > K.N_0 and K.take2 or K.take1,
                    getMoney = money,
                    giveMoney = CODAmount,
                    getItem = getItem,
                    giveItem = {},
                    itemText = itemText,
                }
            end

            local function IsSame(vv, v)
                if vv.daysLeft == v.daysLeft and
                    vv.name == v.name and
                    vv.title == v.title and
                    vv.type == v.type and
                    vv.getMoney == v.getMoney and
                    vv.giveMoney == v.giveMoney and
                    vv.itemText == v.itemText
                then
                    return true
                end
            end

            local function SaveMail(v)
                v.time = GetServerTime()
                v.id = nil
                v.daysLeft = nil
                v.itemText = nil
                tinsert(BiaoGe.mailHistory[realmID][player].info, BG.Copy(v))
                mainFrame:UpdateAllFrame()
            end

            hooksecurefunc("AutoLootMailItem", function(mailIndex)
                GetInboxText(mailIndex)
            end)

            BG.RegisterEvent("MAIL_INBOX_UPDATE", function(self, event)
                tbl_noRead = {}
                tbl_isRead = {}
                for mailIndex = 1, GetInboxNumItems() do
                    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft,
                    hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex)
                    if wasRead then
                        tinsert(tbl_isRead, GetMailInfo(mailIndex, wasRead, hasItem, daysLeft, sender, subject, money, CODAmount))
                    else
                        tinsert(tbl_noRead, GetMailInfo(mailIndex, wasRead, hasItem, daysLeft, sender, subject, money, CODAmount))
                    end
                end
                -- 拿当前已读邮件与上一批未读邮件比对，出现重复的就记录下来
                if last then
                    for _, vv in ipairs(last) do
                        for i = #tbl_isRead, 1, -1 do
                            local v = tbl_isRead[i]
                            if IsSame(v, vv) then
                                SaveMail(v)
                                tremove(tbl_isRead, i) -- 移除该已读邮件，避免重复保存
                                break
                            end
                        end
                    end
                end
                last = tbl_noRead
            end)
        end
    end

    mainFrame = BG.MailHistoryMainFrame

    -- UI
    local db = {}
    local updateFrame = CreateFrame(K.Frame)
    local StartTime, StopTime, ShowInfo
    do
        mainFrame.typeTbl = {
            all = L["全部"],
            send1 = BG.STC_b1(L["发件"]),
            send2 = BG.STC_b1(L["发件(到付)"]),
            take1 = BG.STC_g1(L["收件"]),
            take2 = BG.STC_g1(L["收件(到付)"]),
        }
        local choose = {
            realmID = realmID,
            player = player,
        }
        if BiaoGe.mailHistory.isChooseRealm == 1 then choose = { realmID = realmID, } end
        local BUTTONHEIGHT = mailFrameButtonHeight
        local MAXBUTTONS = mailFrameMaxButton
        local WIDTH = K.N_10 + K.N_27
        local HEIGHT = (MAXBUTTONS + 1) * BUTTONHEIGHT + K.N_15
        local FONTSIZE = K.N_14
        local titleWidth = K.N_0
        local titleTbl = {
            { name = L["序号"], width = K.N_40, color = K.S_4, JustifyH = K.CENTER, Enable = false, fontSize = FONTSIZE - K.N_2, },
            { name = L["时间"], width = K.N_70, color = K.FFFFFF, JustifyH = K.CENTER, Enable = true, fontSize = FONTSIZE - K.N_2, },
            { name = L["类型"], width = K.N_70, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false },
            { name = L["角色"], width = K.N_90, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false },
            { name = L["邮件对象"], width = K.N_90, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false },
            { name = L["主题"], width = K.N_100, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["发送"], width = K.N_90, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["收到"], width = K.N_90, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["邮寄前财产"], width = K.N_100, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["邮寄后财产"], width = K.N_100, color = K.FFFFFF, JustifyH = K.CENTER, Enable = false, fontSize = FONTSIZE - 1, },
        }
        for i, v in ipairs(titleTbl) do
            WIDTH = WIDTH + v.width
            titleWidth = titleWidth + v.width
        end
        mainFrame.titlebuttons = {}
        mainFrame.buttons = {}
        local f, scroll, child, bar
        local GetDB, UpdateScrollFrame, UpdateScrollButtonState, GetButtonInfo, UpdateButtons
        -- 框体
        do
            f = CreateFrame(K.Frame, nil, mainFrame, K.BackdropTemplate)
            f:SetBackdrop({
                bgFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeSize = 1,
            })
            f:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_4)
            f:SetBackdropBorderColor(1, 1, 1, .8)
            f:SetPoint(K.TOPLEFT, BG.MainFrame, K.TOPLEFT, K.N_10, -K.N_65 - (BG.MainNavigationHeight or 0))
            f:SetSize(WIDTH + 5, HEIGHT)
            f:EnableMouse(true)
            mainFrame.frame = f
            f:SetScript(K.OnShow, function(self)
                mainFrame:UpdateAllFrame()
            end)

            scroll = CreateFrame(K.ScrollFrame, nil, f, BG.scrollTemplate) -- 滚动
            scroll:SetWidth(WIDTH - K.N_27 + 5)
            scroll:SetHeight(BUTTONHEIGHT * MAXBUTTONS)
            scroll:SetPoint(K.TOPLEFT, K.N_0, -K.N_12 - BUTTONHEIGHT)
            bar = scroll.ScrollBar
            bar.scrollStep = 5
            BG.CreateSrollBarBackdrop(bar)
            bar:HookScript(K.OnValueChanged, function(self)
                self:SetScript(K.OnUpdate, function(self, t)
                    UpdateButtons()
                    UpdateScrollButtonState()
                    mainFrame.infoFrame:Hide()
                    self:SetScript(K.OnUpdate, nil)
                end)
            end)

            child = CreateFrame(K.Frame, nil, f) -- 子框架
            child:SetWidth(scroll:GetWidth())
            child:SetHeight(scroll:GetHeight())
            scroll:SetScrollChild(child)

            for ii = 1, MAXBUTTONS do
                mainFrame.buttons[ii] = {}
                for i = 1, #titleTbl do
                    local f = CreateFrame(K.Frame, nil, scroll)
                    f:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                    if ii == 1 and i == 1 then
                        f:SetPoint(K.TOPLEFT, scroll, K.N_10, K.N_0)
                        f:SetParent(scroll)
                    elseif i == 1 then
                        f:SetPoint(K.TOPLEFT, mainFrame.buttons[(ii - 1)][1], K.BOTTOMLEFT, K.N_0, K.N_0)
                        f:SetParent(scroll)
                    else
                        f:SetPoint(K.LEFT, mainFrame.buttons[ii][i - 1], K.RIGHT, K.N_0, K.N_0)
                        f:SetParent(mainFrame.buttons[ii][1])
                    end
                    f.num = ii
                    mainFrame.buttons[ii][i] = f

                    f.Text = f:CreateFontString()
                    f.Text:SetFont(BIAOGE_TEXT_FONT, titleTbl[i].fontSize or FONTSIZE, K.OUTLINE)
                    f.Text:SetPoint(K.CENTER)
                    f.Text:SetTextColor(RGB(titleTbl[i].color))
                    f.Text:SetJustifyH(titleTbl[i].JustifyH)
                    f.Text:SetWidth(f:GetWidth() - K.N_2)
                    f.Text:SetHeight(f:GetHeight())
                    -- f.Text:SetWordWrap(false)

                    f:SetScript(K.OnEnter, function(self)
                        mainFrame.frame.lastButtonNum = self.num
                        for _ii, v in ipairs(mainFrame.buttons) do
                            mainFrame.buttons[_ii][1].ds:Hide()
                        end

                        mainFrame.buttons[ii][1].ds:Show()
                        if self.onenter then
                            GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(self.onenter, 1, 1, 1, true)
                            GameTooltip:Show()
                        end
                        ShowInfo(self)
                        StopTime()
                    end)
                    f:SetScript(K.OnLeave, function(self)
                        mainFrame.buttons[ii][1].ds:Hide()
                        GameTooltip:Hide()
                        StartTime()
                    end)
                    f:SetScript(K.OnMouseUp, function(self, button)
                        if button ~= K.RightButton then return end
                        local value = floor(bar:GetValue()) or K.N_0
                        local num = value + ii
                        local tbl = GetButtonInfo(num)

                        local menu = {
                            {
                                text = tbl[4],
                                isTitle = true,
                                notCheckable = true,
                            },
                            {
                                text = K.S_62,
                                isTitle = true,
                                notCheckable = true,
                            },
                            {
                                text = L["删除该条记录"],
                                notCheckable = true,
                                func = function()
                                    local i = db[num].i
                                    local player = db[num].player
                                    local realmID = choose.realmID
                                    tremove(BiaoGe.mailHistory[realmID][player].info, i)
                                    mainFrame:UpdateAllFrame()
                                    BG.PlaySound(1)
                                end
                            },
                            {
                                text = CANCEL,
                                notCheckable = true,
                                func = LibBG.CloseDropDownMenus,
                            }
                        }
                        LibBG:EasyMenu(menu, BG.dropDown, K.cursor, K.N_0, K.N_0, K.MENU, K.N_2)
                        BG.PlaySound(1)
                    end)
                end
                CreateLine(mainFrame.buttons[ii][1], K.N_0, titleWidth, 1, nil, K.N_0_2)

                -- 底色材质
                local f = mainFrame.buttons[ii][1]
                f.ds = f:CreateTexture()
                f.ds:SetPoint(K.TOPLEFT, K.N_0, K.N_0)
                f.ds:SetPoint(K.BOTTOMRIGHT, mainFrame.buttons[ii][#titleTbl], K.BOTTOMRIGHT, K.N_0, K.N_0)
                f.ds:SetColorTexture(1, 1, 1, K.N_0_1)
                f.ds:Hide()
            end
        end
        -- 保存时长
        do
            local function DeleteTradeData()
                local time = GetServerTime()
                for realmID in pairs(BiaoGe.mailHistory) do
                    if type(BiaoGe.mailHistory[realmID]) == K.table then
                        for player in pairs(BiaoGe.mailHistory[realmID]) do
                            for i = #BiaoGe.mailHistory[realmID][player].info, 1, -1 do
                                local v = BiaoGe.mailHistory[realmID][player].info[i]
                                if BiaoGe.mailHistory.saveDuration > K.N_0 and time - (v.time or K.N_0) > K.N_86400 * BiaoGe.mailHistory.saveDuration then
                                    tremove(BiaoGe.mailHistory[realmID][player].info, i)
                                end
                            end
                        end
                    end
                end
            end
            DeleteTradeData()

            local text = mainFrame:CreateFontString()
            text:SetPoint(K.BOTTOMLEFT, f, K.TOPLEFT, K.N_260, K.N_10)
            text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["保存时长："])
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint(K.LEFT, text, K.RIGHT, -K.N_15, -K.N_3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, K.N_80)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, K.N_0, K.N_0, K.TOP, dropDown, K.BOTTOM)
            for i, v in ipairs(BG.saveDays) do
                if v.day == BiaoGe.mailHistory.saveDuration then
                    LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                    break
                end
            end
            BG.dropDownToggle(dropDown)
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for i, v in ipairs(BG.saveDays) do
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    info.text = v.text
                    if v.day == BiaoGe.mailHistory.saveDuration then
                        info.checked = true
                    end
                    info.func = function()
                        BiaoGe.mailHistory.saveDuration = v.day
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
            text:SetPoint(K.BOTTOMLEFT, f, K.TOPLEFT, K.N_0, K.N_10)
            text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["角色："])
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint(K.LEFT, text, K.RIGHT, -K.N_15, -K.N_3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, K.N_180)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, K.N_0, K.N_0, K.TOP, dropDown, K.BOTTOM)
            BG.dropDownToggle(dropDown)
            mainFrame.dropDown1 = dropDown
            if BiaoGe.mailHistory.isChooseRealm == 1 then
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. K.S_36 .. L["全部角色"]))
            else
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. K.S_36) .. SetClassCFF(player, K.player))
            end

            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for _realmID, v in pairs(BiaoGe.mailHistory) do
                    if type(v) == K.table then
                        if next(BiaoGe.mailHistory[_realmID]) then
                            local info = LibBG:UIDropDownMenu_CreateInfo()
                            info.text = BG.STC_y2(BiaoGe.realmName[_realmID] or _realmID)
                            if not choose.player and _realmID == choose.realmID then
                                info.checked = true
                            end
                            info.func = function()
                                choose = {
                                    realmID = _realmID,
                                    player = nil,
                                }
                                BiaoGe.mailHistory.isChooseRealm = 1
                                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[_realmID] or _realmID) .. K.S_36 .. L["全部角色"]))
                                UpdateScrollFrame()
                                UpdateButtons()
                            end
                            LibBG:UIDropDownMenu_AddButton(info)
                        end

                        for _, v in pairs(BiaoGe.mailHistory[_realmID]) do
                            local info = LibBG:UIDropDownMenu_CreateInfo()
                            local playerName = K.TXT_C .. select(4, GetClassColor(v.class)) .. v.name
                            info.text = K.S_32 .. playerName .. (v.level and K.S_76 .. v.level .. K.S_29 or K.EMPTY)
                            info.arg1 = v.realmID .. K.S_77 .. v.name
                            info.arg2 = K.COLOR_FFD100 .. (BiaoGe.realmName[_realmID] or _realmID)
                                .. K.TXT_R_C .. select(4, GetClassColor(v.class)) .. v.name .. K.TXT_R
                            if v.name == choose.player and v.realmID == choose.realmID then
                                info.checked = true
                            end
                            info.func = function()
                                choose = {
                                    realmID = v.realmID,
                                    player = v.name,
                                }
                                BiaoGe.mailHistory.isChooseRealm = K.N_0
                                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[v.realmID] or v.realmID) .. K.S_36) .. playerName)
                                UpdateScrollFrame()
                                UpdateButtons()
                            end
                            LibBG:UIDropDownMenu_AddButton(info)
                        end
                    end
                end
            end)

            -- 删除角色
            for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
                local button = _G["L_DropDownList1Button" .. i]
                button:HookScript(K.OnEnter, function()
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown1 then return end
                    if not button.deleteMailPlayer then
                        local bt = CreateFrame(K.Button, nil, button)
                        bt:SetSize(K.N_15, K.N_15)
                        bt:SetPoint(K.RIGHT, -K.N_2, K.N_0)
                        bt:SetNormalTexture(K.TXT_INTERFACE_RAIDFRAME_READ)
                        bt:SetHighlightTexture(K.TXT_INTERFACE_RAIDFRAME_READ)
                        bt:RegisterForClicks(K.AnyUp)
                        bt.num = i
                        bt:Hide()
                        button.deleteMailPlayer = bt
                        bt:SetScript(K.OnClick, function(self)
                            dropDown.realmID, dropDown.player = strsplit(K.S_77, button.arg1)
                            dropDown.realmID = tonumber(dropDown.realmID)
                            dropDown.colorPlayer = button.arg2
                            LibBG:CloseDropDownMenus()
                            StaticPopup_Show("BiaoGe_DeleteMailHistoryPlayer", dropDown.colorPlayer)
                        end)
                        bt:SetScript(K.OnEnter, function(self)
                            button.isOnEnter = true
                            LibBG:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
                            button.Highlight:Show()
                            GameTooltip:SetOwner(self, K.ANCHOR_RIGHT, K.N_0, K.N_0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(L["删除该角色"], 1, 1, 1, true)
                            GameTooltip:Show()
                        end)
                        bt:SetScript(K.OnLeave, function(self)
                            LibBG:UIDropDownMenu_StartCounting(self:GetParent():GetParent())
                            button.Highlight:Hide()
                            GameTooltip:Hide()
                        end)
                        bt:SetScript(K.OnHide, function(self)
                            self:Hide()
                        end)
                    end
                    button.isOnEnter = true
                    for ii = 1, _G['L_DropDownList1'].numButtons do
                        local bt = _G["L_DropDownList1Button" .. ii]
                        if bt.deleteMailPlayer then
                            bt.deleteMailPlayer:Hide()
                        end
                    end
                    if button.arg1 then
                        button.deleteMailPlayer:Show()
                    end
                end)
                button:HookScript(K.OnLeave, function()
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown1 then return end
                    button.isOnEnter = false
                    After(K.N_0, function()
                        if not button.isOnEnter then
                            button.deleteMailPlayer:Hide()
                        end
                    end)
                end)
            end
            StaticPopupDialogs["BiaoGe_DeleteMailHistoryPlayer"] = {
                text = L["确认删除%s的邮件记录？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    LibBG:ToggleDropDownMenu(nil, nil, mainFrame.dropDown1)
                    for i = 1, _G['L_DropDownList1'].numButtons do
                        local button = _G["L_DropDownList1Button" .. i]
                        if button.arg1 then
                            local _realmID, _player = strsplit(K.S_77, button.arg1)
                            _realmID = tonumber(_realmID)
                            if _realmID == realmID and _player == player then
                                button:Click()
                                break
                            end
                        end
                    end
                    local _realmID, _player = dropDown.realmID, dropDown.player
                    BiaoGe.mailHistory[_realmID][_player] = nil
                    if _realmID == realmID and _player == player then
                        EnsureCurrentCharacter()
                    end
                    mainFrame:UpdateAllFrame()
                    SendSystemMessage(format(L["已删除%s的邮件记录。"], dropDown.colorPlayer))
                end,
                OnCancel = function()
                end,
                timeout = K.N_0,
                whileDead = true,
                hideOnEscape = true,
            }
        end
        -- 邮件类型
        do
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint(K.BOTTOMRIGHT, f, K.TOPRIGHT, K.N_14, -K.N_2)
            LibBG:UIDropDownMenu_SetWidth(dropDown, K.N_120)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, K.N_0, K.N_0, K.TOP, dropDown, K.BOTTOM)
            BG.dropDownToggle(dropDown)
            mainFrame.dropDown2 = dropDown
            local text = dropDown:CreateFontString()
            text:SetPoint(K.RIGHT, dropDown, K.LEFT, K.N_15, K.N_3)
            text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["邮件类型："])
            LibBG:UIDropDownMenu_SetText(dropDown, mainFrame.typeTbl[BiaoGe.mailHistory.type])

            local function Init(type, count)
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = mainFrame.typeTbl[type] .. BG.STC_dis(K.S_88 .. count .. K.S_29)
                info.checked = BiaoGe.mailHistory.type == type
                info.func = function()
                    BiaoGe.mailHistory.type = type
                    LibBG:UIDropDownMenu_SetText(dropDown, mainFrame.typeTbl[BiaoGe.mailHistory.type])
                    mainFrame:UpdateAllFrame()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                local tbl = {
                    send1 = K.N_0,
                    send2 = K.N_0,
                    take1 = K.N_0,
                    take2 = K.N_0,
                }
                local realmID = choose.realmID
                local playerTbl = {}
                if choose.player then
                    playerTbl = { choose.player }
                else
                    for player, v in pairs(BiaoGe.mailHistory[realmID]) do
                        tinsert(playerTbl, player)
                    end
                end
                for _, player in pairs(playerTbl) do
                    for i, v in ipairs(BiaoGe.mailHistory[realmID][player].info) do
                        if tbl[v.type] then
                            tbl[v.type] = tbl[v.type] + 1
                        end
                    end
                end
                Init(K.all, tbl.send1 + tbl.send2 + tbl.take1 + tbl.take2)
                Init(K.send1, tbl.send1)
                Init(K.send2, tbl.send2)
                Init(K.take1, tbl.take1)
                Init(K.take2, tbl.take2)
            end)
        end
        -- 标题
        do
            for i, v in ipairs(titleTbl) do
                local bt = CreateFrame(K.Button, nil, f, K.BackdropTemplate)
                bt:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                if i == 1 then
                    bt:SetPoint(K.TOPLEFT, K.N_10, -K.N_10)
                else
                    bt:SetPoint(K.LEFT, mainFrame.titlebuttons[i - 1], K.RIGHT, K.N_0, K.N_0)
                    bt:SetParent(mainFrame.titlebuttons[i - 1])
                end
                bt:SetNormalFontObject(BG[K.FontWhite .. FONTSIZE])
                bt:SetText(titleTbl[i].name)
                bt.textwidth = bt:GetFontString():GetStringWidth()
                bt.textJustifyH = titleTbl[i].JustifyH
                bt.sortOrder = 1
                bt.id = i
                bt:SetHighlightTexture(K.TEX_UI_CHARACTER_TAB_HIGHLIGHT)
                bt:SetEnabled(v.Enable)
                tinsert(mainFrame.titlebuttons, bt)

                bt.Text = bt:GetFontString()
                bt.Text:SetJustifyH(titleTbl[i].JustifyH)
                bt.Text:SetWidth(bt:GetWidth())
                bt.Text:SetWordWrap(false)

                bt:SetScript(K.OnClick, function(self)
                    BG.PlaySound(1)
                    mainFrame.isnewsorter = nil
                    if BiaoGe.mailHistory.OrderButtonID ~= self.id then
                        mainFrame.isnewsorter = true
                    end
                    if not mainFrame.isnewsorter then
                        BiaoGe.mailHistory.Order = BiaoGe.mailHistory.Order == 1 and K.N_0 or 1
                    end
                    BiaoGe.mailHistory.OrderButtonID = self.id
                    UpdateScrollFrame()
                    UpdateButtons()
                end)
            end
            CreateLine(mainFrame.titlebuttons[1], K.N_0, titleWidth)
            -- 排序材质
            local sorter = mainFrame:CreateTexture(nil, K.OVERLAY)
            sorter:SetSize(8, 8)
            sorter:SetTexture(K.TEX_UI_SORTARROW)
            mainFrame.sorter = sorter
            -- 提示
            local t = scroll:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOP, K.N_0, -5)
            t:SetTextColor(.5, .5, .5)
            t:SetText(L["该角色没有该类型的邮件记录。"])
            mainFrame.notText = t
        end

        -- 刷新滚动框
        function GetDB()
            local realmID = choose.realmID
            local playerTbl = {}
            wipe(db)
            if choose.player then
                playerTbl = { choose.player }
            else
                for player, v in pairs(BiaoGe.mailHistory[realmID]) do
                    tinsert(playerTbl, player)
                end
            end

            local type = BiaoGe.mailHistory.type
            for _, player in pairs(playerTbl) do
                if BiaoGe.mailHistory[realmID][player] then
                    for i, v in ipairs(BiaoGe.mailHistory[realmID][player].info) do
                        if not v.name then
                            v.name = UNKNOWN
                        end
                        if type == K.all or v.type == type then
                            if BiaoGe.options["showEmptyMail"] == 1 or
                                not (v.getMoney == K.N_0 and v.giveMoney == K.N_0 and not next(v.getItem) and not next(v.giveItem))
                            then
                                if v.name:find(BUTTON_LAG_AUCTIONHOUSE) then
                                    if BiaoGe.options["showAuctionMail"] == 1 then
                                        local tbl = BiaoGe.mailHistory[realmID][player]
                                        tinsert(db, BG.Copy(v))
                                        db[#db].i = i
                                        db[#db].player = tbl.name
                                        db[#db].colorplayer = K.TXT_C .. select(4, GetClassColor(tbl.class)) .. tbl.name .. K.TXT_R
                                    end
                                else
                                    local tbl = BiaoGe.mailHistory[realmID][player]
                                    tinsert(db, BG.Copy(v))
                                    db[#db].i = i
                                    db[#db].player = tbl.name
                                    db[#db].colorplayer = K.TXT_C .. select(4, GetClassColor(tbl.class)) .. tbl.name .. K.TXT_R
                                end
                            end
                        end
                    end
                end
            end
            -- 拍卖行邮件合并
            if BiaoGe.options["showAuctionMail"] == 1 and BiaoGe.options["togetherAuctionMail"] == 1 then
                local tbl = {}
                for i = #db, 1, -1 do
                    local v = db[i]
                    if not next(tbl) then
                        if v.name:find(BUTTON_LAG_AUCTIONHOUSE) then
                            tbl = BG.Copy(v)
                            tremove(db, i)
                        end
                    else
                        if v.name:find(BUTTON_LAG_AUCTIONHOUSE) and v.player == tbl.player then
                            if not tbl.text:find(MAIL_SUBJECT_LABEL) then
                                tbl.text = BG.STC_y2(MAIL_SUBJECT_LABEL) .. tbl.title .. K.S_33 .. tbl.text
                            end
                            tbl.text = tbl.text .. K.S_33 .. BG.STC_y2(MAIL_SUBJECT_LABEL) .. v.title .. K.S_33 .. v.text
                            local count = tbl.title:match(L["%((%d+)个邮件合并%)"]) or 1
                            tbl.title = format(BG.STC_y1(L["(%s个邮件合并)"]), count + 1)
                            tbl.getMoney = tbl.getMoney + v.getMoney
                            for _, vv in ipairs(v.getItem) do
                                tinsert(tbl.getItem, BG.Copy(vv))
                            end
                            tremove(db, i)
                        else
                            tinsert(db, tbl)
                            tbl = {}
                        end
                    end
                end
                if next(tbl) then
                    tinsert(db, tbl)
                end
            end

            sort(db, function(a, b)
                if BiaoGe.mailHistory.OrderButtonID == K.N_2 then -- 按时间
                    local key = K.time
                    if a[key] and b[key] then
                        if a[key] ~= b[key] then
                            if BiaoGe.mailHistory.Order == 1 then
                                return a[key] > b[key]
                            else
                                return b[key] > a[key]
                            end
                        end
                    end
                end
                local key = K.title
                if a[key] and b[key] then
                    if a[key] ~= b[key] then
                        if BiaoGe.mailHistory.Order == 1 then
                            return a[key] > b[key]
                        else
                            return b[key] > a[key]
                        end
                    end
                end
                return false
            end)
        end

        function UpdateScrollFrame()
            GetDB()

            local sorter = mainFrame.sorter
            local bt = mainFrame.titlebuttons[BiaoGe.mailHistory.OrderButtonID]
            sorter:SetParent(bt)
            sorter:ClearAllPoints()
            if bt.textJustifyH == K.CENTER then
                sorter:SetPoint(K.LEFT, bt, K.CENTER, bt.textwidth / K.N_2, K.N_0)
            else
                sorter:SetPoint(K.LEFT, bt, K.LEFT, bt.textwidth, K.N_0)
            end
            if not mainFrame.isnewsorter then
                if BiaoGe.mailHistory.Order == 1 then
                    sorter:SetTexCoord(K.N_0, K.N_0_5, K.N_0, 1)
                else
                    sorter:SetTexCoord(K.N_0, K.N_0_5, 1, K.N_0)
                end
            end

            local m = #db - MAXBUTTONS
            bar:SetMinMaxValues(K.N_0, max(K.N_0, m))
            if scroll.SetScrollExtent then
                scroll:SetScrollExtent(MAXBUTTONS, #db)
            end
            UpdateScrollButtonState()

            mainFrame.notText:SetShown(#db == K.N_0)
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

            local targetText = v.name
            if targetText:find(BUTTON_LAG_AUCTIONHOUSE) then
                targetText = BG.STC_y1(targetText)
            end

            local giveItemText = K.EMPTY
            local count = #v.giveItem
            if count == 1 then
                giveItemText = AddIconByLink(v.giveItem[1].link) .. v.giveItem[1].link
            elseif count > 1 then
                giveItemText = K.TXT_A_PARAGONREPUTATION_BAG .. K.x .. count
            end
            local giveMoneyText = K.EMPTY
            local money = v.giveMoney
            if money > K.N_0 then
                giveMoneyText = GetMoneyString(money, true)
            end
            local giveSplit = K.EMPTY
            if giveItemText ~= K.EMPTY and giveMoneyText ~= K.EMPTY then
                giveSplit = K.S_98
            end

            local getItemText = K.EMPTY
            local count = #v.getItem
            if count == 1 then
                getItemText = AddIconByLink(v.getItem[1].link) .. v.getItem[1].link
            elseif count > 1 then
                getItemText = K.TXT_A_PARAGONREPUTATION_BAG .. K.x .. count
            end
            local getMoneyText = K.EMPTY
            local money = v.getMoney
            if money > K.N_0 then
                getMoneyText = GetMoneyString(money, true)
            end
            local getSplit = K.EMPTY
            if getItemText ~= K.EMPTY and getMoneyText ~= K.EMPTY then
                getSplit = K.S_98
            end

            return {
                num,                                                                              -- 序号
                date(K.TXT_M_D_H_M, v.time),                                                      -- 时间
                mainFrame.typeTbl[v.type],                                                        -- 类型
                v.colorplayer,                                                                    -- 角色
                targetText,                                                                       -- 邮寄对象
                v.title,                                                                          -- 主题
                giveItemText .. giveSplit .. giveMoneyText,                                       -- 发送
                getItemText .. getSplit .. getMoneyText,                                          -- 收到
                v.beforeMoney and GetMoneyString(floor(v.beforeMoney / K.N_1e4) * K.N_10000, true) or K.EMPTY, -- 邮寄前财产
                v.afterMoney and GetMoneyString(floor(v.afterMoney / K.N_1e4) * K.N_10000, true) or K.EMPTY,   -- 邮寄后财产
            }
        end

        function UpdateButtons()
            local value = floor(bar:GetValue()) or K.N_0
            for ii = 1, MAXBUTTONS do
                local num = value + ii
                local tbl = GetButtonInfo(num)
                for i = 1, #titleTbl do
                    if tbl then
                        mainFrame.buttons[ii][i].Text:SetText(tbl[i])
                        mainFrame.buttons[ii][i].dbNum = num
                        if mainFrame.buttons[ii][i].Text:IsTruncated() then
                            mainFrame.buttons[ii][i].onenter = tbl[i]
                        else
                            mainFrame.buttons[ii][i].onenter = nil
                        end
                        mainFrame.buttons[ii][i]:Show()
                    else
                        mainFrame.buttons[ii][i]:Hide()
                    end
                end
            end
            GameTooltip:Hide()
        end

        function mainFrame:UpdateAllFrame()
            if not self:IsVisible() then return end
            UpdateScrollFrame()
            UpdateButtons()
        end
    end

    -- 邮件详细框
    do
        function StartTime()
            updateFrame.elapsed = K.N_0
            updateFrame:SetScript(K.OnUpdate, function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed >= .5 then
                    self:SetScript(K.OnUpdate, nil)
                    mainFrame.infoFrame:Hide()
                end
            end)
        end

        function StopTime()
            updateFrame.elapsed = K.N_0
            updateFrame:SetScript(K.OnUpdate, nil)
        end

        local frame = CreateFrame(K.Frame, nil, mainFrame, K.BackdropTemplate)
        frame:SetBackdrop({
            bgFile = K.TEX_CHATFRAMEBACKGROUND,
            edgeFile = K.TEX_CHATFRAMEBACKGROUND,
            edgeSize = 1,
        })
        frame:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_4)
        frame:SetBackdropBorderColor(1, 1, 1, .8)
        frame:SetPoint(K.TOPLEFT, mainFrame.frame, K.TOPRIGHT, K.N_2, K.N_0)
        frame:SetSize(K.N_320, K.N_350)
        frame:Hide()
        mainFrame.infoFrame = frame
        frame:HookScript(K.OnEnter, function(self)
            StopTime()
            local num = mainFrame.frame.lastButtonNum
            mainFrame.buttons[num][1].ds:Show()
        end)
        frame:HookScript(K.OnLeave, StartTime)
        frame:HookScript(K.OnHide, function(self)
            local num = mainFrame.frame.lastButtonNum
            mainFrame.buttons[num][1].ds:Hide()
        end)

        frame.timeText = frame:CreateFontString()
        frame.timeText:SetFont(BIAOGE_TEXT_FONT, K.N_13, K.OUTLINE)
        frame.timeText:SetPoint(K.BOTTOMLEFT, frame, K.TOPLEFT, K.N_2, K.N_2)
        frame.timeText:SetTextColor(1, 1, 1)

        -- 各种文本
        do
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOP, K.N_0, -5)
            t:SetJustifyH(K.RIGHT)
            frame.typeText = t
            frame.line = frame:CreateLine()
            frame.line:SetColorTexture(1, 1, 1, .8)
            frame.line:SetStartPoint(K.TOPLEFT, 1, -K.N_23)
            frame.line:SetEndPoint(K.TOPRIGHT, -1, -K.N_23)
            frame.line:SetThickness(1)

            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, frame, K.TOPLEFT, K.N_80, -K.N_35)
            t:SetJustifyH(K.RIGHT)
            t:SetTextColor(1, .82, K.N_0)
            frame.nameText1 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.LEFT, frame.nameText1, K.RIGHT, 5, -K.N_0)
            t:SetJustifyH(K.LEFT)
            frame.nameText2 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, frame.nameText1, K.BOTTOMRIGHT, K.N_0, -K.N_10)
            t:SetJustifyH(K.RIGHT)
            t:SetText(MAIL_SUBJECT_LABEL)
            t:SetTextColor(1, .82, K.N_0)
            frame.titleText1 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.LEFT, frame.titleText1, K.RIGHT, 5, -K.N_0)
            t:SetJustifyH(K.LEFT)
            t:SetWidth(frame:GetWidth() - select(4, frame.nameText1:GetPoint()) - K.N_20)
            t:SetWordWrap(false)
            frame.titleText2 = t

            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, frame.titleText1, K.BOTTOMRIGHT, K.N_0, -K.N_10)
            t:SetTextColor(1, K.N_0_82, K.N_0)
            t:SetText(L["内容："])
            t:SetJustifyH(K.RIGHT)
            frame.textText1 = t
            local f = CreateFrame(K.Frame, nil, frame, K.BackdropTemplate)
            f:SetBackdrop({
                bgFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeSize = 1,
            })
            f:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_5)
            f:SetBackdropBorderColor(1, 1, 1, K.N_0_6)
            f:SetSize(K.N_215, K.N_120)
            f:SetPoint(K.TOPLEFT, frame.textText1, K.TOPRIGHT, 5, K.N_0)
            frame.textbg = f
            local scroll = CreateFrame(K.ScrollFrame, nil, f, BG.scrollTemplate)
            scroll:SetWidth(f:GetWidth() - K.N_10)
            scroll:SetHeight(f:GetHeight() - K.N_10)
            scroll:SetPoint(K.CENTER)
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll, true)
            local edit = CreateFrame(K.EditBox, nil, f)
            edit:SetWidth(scroll:GetWidth())
            edit:SetAutoFocus(false)
            edit:EnableMouse(false)
            edit:SetTextInsets(K.N_0, K.N_0, K.N_0, K.N_0)
            edit:SetMultiLine(true)
            edit:SetFont(BIAOGE_TEXT_FONT, K.N_13, K.OUTLINE)
            frame.textText2 = edit
            scroll:SetScrollChild(edit)

            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, frame.textText1, K.BOTTOMRIGHT, K.N_0, -K.N_0 - frame.textbg:GetHeight())
            t:SetJustifyH(K.RIGHT)
            t:SetTextColor(1, .82, K.N_0)
            frame.moneyText1 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.LEFT, frame.moneyText1, K.RIGHT, 5, -K.N_0)
            t:SetJustifyH(K.LEFT)
            t:SetWidth(frame:GetWidth() - select(4, frame.nameText1:GetPoint()) - K.N_20)
            t:SetWordWrap(false)
            frame.moneyText2 = t
        end

        -- 物品框
        do
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, frame.moneyText1, K.BOTTOMRIGHT, K.N_0, -K.N_10)
            t:SetJustifyH(K.RIGHT)
            t:SetTextColor(1, .82, K.N_0)
            frame.itemText = t

            local f = CreateFrame(K.Frame, nil, frame, K.BackdropTemplate)
            f:SetBackdrop({
                bgFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeSize = 1,
            })
            f:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_5)
            f:SetBackdropBorderColor(1, 1, 1, K.N_0_6)
            f:SetSize(frame.textbg:GetWidth(), K.N_85)
            f:SetPoint(K.TOPLEFT, frame.itemText, K.TOPRIGHT, 5, K.N_0)
            frame.itembg = f
            local scroll = CreateFrame(K.ScrollFrame, nil, f, BG.scrollTemplate) -- 滚动
            scroll:SetWidth(f:GetWidth())
            scroll:SetHeight(f:GetHeight() - 4)
            scroll:SetPoint(K.TOPLEFT, f, K.TOPLEFT, K.N_0, -K.N_2)
            f.scroll = scroll
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll, true)
            local child = CreateFrame(K.Frame, nil, scroll) -- 子框架
            child:SetWidth(scroll:GetWidth())
            child:SetHeight(scroll:GetHeight())
            scroll:SetScrollChild(child)
            frame.itemframe = child
            frame.buttons = {}
        end

        function ShowInfo(self)
            local num = self.dbNum
            local v = db[num]
            local frame = mainFrame.infoFrame
            local type
            local r, g, b
            if v.type:find(K.send) then
                type = K.send
                r, g, b = RGB(BG.b1)
            else
                type = K.take
                r, g, b = K.N_0, 1, K.N_0
            end
            frame.timeText:SetText(date(K.TXT_Y_M_D_H_M, v.time))
            frame:SetBackdropBorderColor(r, g, b, .8)
            frame:SetBackdropColor(r, g, b, K.N_0_05)
            frame.line:SetColorTexture(r, g, b, .8)
            frame.textbg:SetBackdropBorderColor(r, g, b, .8)
            frame.textbg:SetBackdropColor(r, g, b, K.N_0_05)
            frame.itembg:SetBackdropBorderColor(r, g, b, .8)
            frame.itembg:SetBackdropColor(r, g, b, K.N_0_05)

            frame.typeText:SetText(mainFrame.typeTbl[v.type])
            frame.nameText1:SetText(type == K.send and MAIL_TO_LABEL or FROM)
            local targetText = v.name
            if v.name:find(BUTTON_LAG_AUCTIONHOUSE) then
                targetText = BG.STC_y1(targetText)
            end
            frame.nameText2:SetText(targetText)
            frame.titleText2:SetText(v.title or K.EMPTY)
            frame.textText2:SetText(v.text or K.EMPTY)

            if v.giveMoney == K.N_0 and v.getMoney == K.N_0 then
                frame.moneyText1:Hide()
                frame.moneyText2:Hide()
            else
                frame.moneyText1:Show()
                frame.moneyText2:Show()

                local money = v.giveMoney == K.N_0 and v.getMoney or v.giveMoney
                local moneyText = K.EMPTY
                if v.type == K.send1 then
                    moneyText = L["发送金额："]
                elseif v.type == K.send2 then
                    moneyText = L["付款取信："]
                elseif v.type == K.take1 then
                    moneyText = L["收到金额："]
                elseif v.type == K.take2 then
                    moneyText = L["支出金额："]
                end
                frame.moneyText1:SetText(moneyText)
                frame.moneyText2:SetText(GetMoneyString(money, true))
            end

            -- 物品
            if #v.giveItem == K.N_0 and #v.getItem == K.N_0 then
                frame.itemText:Hide()
                frame.itembg:Hide()
            else
                for i, bt in ipairs(frame.buttons) do
                    bt:Hide()
                end
                wipe(frame.buttons)
                frame.itemText:Show()
                frame.itembg:Show()
                if type == K.send then
                    frame.itemText:SetText(L["发送物品："])
                else
                    frame.itemText:SetText(L["收到物品："])
                end
                local db = #v.giveItem == K.N_0 and v.getItem or v.giveItem

                local function CreateButton(i)
                    local v = db[i]
                    local r, g, b
                    local a = 1
                    if v.quality then
                        r, g, b = GetItemQualityColor(v.quality)
                    else
                        r, g, b = 1, 1, 1
                        a = K.N_0
                    end
                    local bt = CreateFrame(K.Frame, nil, frame.itemframe, K.BackdropTemplate)
                    bt:SetBackdrop({
                        edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                        edgeSize = 1,
                    })
                    bt:SetBackdropBorderColor(r, g, b, a)
                    bt:SetSize(K.N_30, K.N_30)
                    if i == 1 then
                        bt:SetPoint(K.TOPLEFT, frame.itemframe, K.TOPLEFT, 5, -K.N_3)
                    elseif (i - 1) % K.N_6 == K.N_0 then
                        bt:SetPoint(K.TOPLEFT, frame.buttons[i - K.N_6], K.BOTTOMLEFT, K.N_0, -5)
                    else
                        bt:SetPoint(K.TOPLEFT, frame.buttons[i - 1], K.TOPRIGHT, 5, K.N_0)
                    end
                    bt.itemID = v.itemID
                    bt.link = v.link
                    tinsert(frame.buttons, bt)
                    bt:HookScript(K.OnEnter, function(self)
                        StopTime()
                        local num = mainFrame.frame.lastButtonNum
                        mainFrame.buttons[num][1].ds:Show()
                        GameTooltip:SetOwner(self, K.ANCHOR_LEFT, K.N_0, K.N_0)
                        GameTooltip:ClearLines()
                        GameTooltip:SetHyperlink(bt.link)
                    end)
                    bt:HookScript(K.OnLeave, function(self)
                        GameTooltip:Hide()
                        StartTime()
                    end)

                    bt.icon = bt:CreateTexture(nil, K.BACKGROUND)
                    bt.icon:SetAllPoints()
                    bt.icon:SetTexCoord(.07, .93, .07, .93)
                    bt.icon:SetTexture(select(5, GetItemInfoInstant(bt.itemID)))

                    if v.count > 1 then
                        bt.count = bt:CreateFontString()
                        bt.count:SetFont(BIAOGE_TEXT_FONT, K.N_13, K.OUTLINE)
                        bt.count:SetPoint(K.BOTTOMRIGHT, -1, 1)
                        bt.count:SetText(v.count)
                    end

                    local typeID = select(K.N_6, GetItemInfoInstant(v.itemID))
                    if typeID == K.N_2 or typeID == 4 then
                        local link = v.link
                        local item = Item:CreateFromItemLink(link)
                        item:ContinueOnItemLoad(function()
                            local level = select(4, GetItemInfo(link))
                            if level then
                                bt.level = bt:CreateFontString()
                                bt.level:SetFont(BIAOGE_TEXT_FONT, K.N_11, K.OUTLINE)
                                bt.level:SetPoint(K.BOTTOM, 1, 1)
                                bt.level:SetText(level)
                            end
                        end)
                    end
                end

                for i, v in ipairs(db) do
                    CreateButton(i)
                end
            end

            mainFrame.infoFrame:Show()
        end
    end

    -- 选项
    do
        local mainFrame = BG.MailHistoryMainFrame
        local last
        -- 显示拍卖行邮件
        do
            local name = "showAuctionMail"
            BG.options[name .. "reset"] = 1
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["显示拍卖行邮件"]
            local ontext
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint(K.TOPLEFT, mainFrame.frame, K.BOTTOMLEFT, K.N_0, -K.N_10)
            mainFrame.optionsButton_showAuctionMail = bt
            last = bt
            bt:HookScript(K.OnClick, function(self)
                local name1 = "togetherAuctionMail"
                if self:GetChecked() then
                    BG.options["button" .. name1]:Show()
                else
                    BG.options["button" .. name1]:Hide()
                end
                mainFrame:UpdateAllFrame()
            end)
        end
        -- 把位置相邻的拍卖行邮件归并到一起
        do
            local name = "togetherAuctionMail"
            BG.options[name .. "reset"] = K.N_0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["合并相邻的拍卖行邮件"]
            local ontext = {
                text,
                L["相邻的拍卖行邮件会被合并显示为一个邮件，节省空间。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint(K.TOPLEFT, last, K.BOTTOMRIGHT, K.N_0, K.N_0)
            last = bt
            bt:HookScript(K.OnClick, function(self)
                mainFrame:UpdateAllFrame()
            end)
            if BiaoGe.options["showAuctionMail"] ~= 1 then
                bt:Hide()
            end
        end
        -- 显示空邮件
        do
            local name = "showEmptyMail"
            BG.options[name .. "reset"] = 1
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["显示空邮件"]
            local ontext = {
                text,
                L["没有附件的邮件，也会被显示。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint(K.TOPLEFT, mainFrame.optionsButton_showAuctionMail, K.BOTTOMLEFT, K.N_0, -K.N_30)
            last = bt
            bt:HookScript(K.OnClick, function(self)
                mainFrame:UpdateAllFrame()
            end)
        end
    end
end

BG.Init(function()
    BiaoGe.mailHistory = BiaoGe.mailHistory or {}
    local mailHistory = BiaoGe.mailHistory
    mailHistory.saveDuration = mailHistory.saveDuration or K.N_7
    mailHistory.OrderButtonID = mailHistory.OrderButtonID or K.N_2
    mailHistory.Order = mailHistory.Order or 1
    mailHistory.type = mailHistory.type or K.all
    if mailHistory.type ~= K.all and mailHistory.type ~= K.send1 and mailHistory.type ~= K.send2
        and mailHistory.type ~= K.take1 and mailHistory.type ~= K.take2
    then
        mailHistory.type = K.all
    end
    mailHistory.isChooseRealm = mailHistory.isChooseRealm or 1
    EnsureCurrentCharacter()

    if BiaoGe.disabledModules["MailHistory"] then return end

    RoadMail()
end)

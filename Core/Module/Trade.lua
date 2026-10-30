if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local L = ns.L

local C = ns.Protocol
local SendGateway = ns.SendGateway
local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local Maxb = ns.Maxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxb = ns.HopeMaxb
local HopeMaxi = ns.HopeMaxi

local RealmId = GetRealmID()
local player = BG.playerName
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

BG.tradeQuality = 0
BG.trade = {}
BG.trade.player = BG.playerName
BG.trade.many = {}
BG.trade.playerinfo = {}
BG.trade.targetinfo = {}
BG.trade.targetitems = {}
BG.trade.playeritems = {}

BG.TradeMyMoneyChange = {}

local T = {}

local BACKDROP_TOOLTIP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeSize = 1.5,
}

local BACKDROP_CHAT = {
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeSize = 1,
}

local BACKDROP_CHAT_ONLY = {
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
}

local BACKDROP_EDGE = {
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeSize = 1,
}

local BACKDROP_EDGE_THICK = {
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeSize = 1.5,
}

local function SetOutlineFont(fontString, size)
    fontString:SetFont(BIAOGE_TEXT_FONT, size, "OUTLINE")
end

local function SetJustifyLeft(text)
    text:SetJustifyH("LEFT")
end

local function CreateWageLabel(parent, width, fraction, height, anchorFrame, text, tooltipName, done, row)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width * fraction, height)
    if anchorFrame then
        frame:SetPoint("LEFT", anchorFrame, "RIGHT", 2, 0)
    else
        frame:SetPoint("LEFT", 0, 0)
    end
    local label = frame:CreateFontString()
    SetOutlineFont(label, 14)
    label:SetAllPoints()
    label:SetText(text)
    if done then
        label:SetTextColor(.5, .5, .5)
    else
        label:SetTextColor(1, .82, 0)
    end
    SetJustifyLeft(label)
    label:SetWordWrap(false)
    frame:SetScript("OnEnter", function(self)
        if label:IsTruncated() then
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(tooltipName, 1, .82, 0, true)
            GameTooltip:Show()
        end
        row.ds:Show()
    end)
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if row.tradeing then return end
        row.ds:Hide()
    end)
    return frame
end

local function CreateTradePreviewCheckButton(label, first)
    local bt = CreateFrame("CheckButton", nil, BG.tradeSeeFrame.frame, "ChatConfigCheckButtonTemplate")
    if first then
        bt:SetSize(20, 20)
    else
        bt:SetSize(BG.tradeSeeFrame.CheckButton:GetSize())
    end
    SetOutlineFont(bt.Text, 15)
    bt.Text:SetText(label)
    bt.Text:SetWidth(min(BG.tradeSeeFrame.frame:GetWidth() - 35, bt.Text:GetStringWidth() + 20))
    bt.Text:SetWordWrap(false)
    if first then
        bt:SetPoint("BOTTOMLEFT", BG.tradeSeeFrame.frame, "BOTTOMLEFT", 5, 0)
    else
        bt:SetPoint("BOTTOMLEFT", BG.tradeSeeFrame.CheckButton, "TOPLEFT", 0, 0)
    end
    bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
    return bt
end

local function UpdatePreviewButton(button, refund)
    button:Show()
    button.isChoose = button:GetChecked()
    local visible
    if refund then
        visible = BG.tradeSeeFrame.CheckButton:GetChecked()
            and (next(BG.trade.targetitems) or next(BG.trade.playeritems))
            and not (next(BG.trade.targetitems) and next(BG.trade.playeritems))
    else
        visible = BG.tradeSeeFrame.CheckButton:GetChecked()
            and not next(BG.trade.targetitems)
            and not next(BG.trade.playeritems)
    end
    if not visible then
        button:Hide()
        button:SetChecked(false)
        button.isChoose = false
    end
end

local function ResetPreviewButton(button, visible)
    button.isChoose = false
    button:SetChecked(false)
    if visible then
        button:Show()
    else
        button:Hide()
    end
end

local function ApplyPreviewColors(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    frame:SetBackdropColor(bgR, bgG, bgB, bgA)
    frame:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
end

local function CreateDuplicateTradeTexture(parent)
    local tex = parent:CreateTexture()
    tex:SetPoint("CENTER")
    tex:SetSize(parent:GetWidth() + 10, parent:GetHeight() + 10)
    tex:SetTexture(616343)
    return tex
end

local function IsTradePreviewEnabled()
    return BiaoGe.options["autoTrade"] == 1 and BiaoGe.options["tradePreview"] == 1 and IsInRaid(1)
end

local function IsAutoAuctionMoneyEnabled()
    return BiaoGe.options["autoAuctionMoney"] == 1
end

local function ShowTradeSideMoney(giveText, sum, label, isPlayer, formatMoney, updateColor, checkItems)
    if IsAutoAuctionMoneyEnabled() then
        if sum ~= 0 then
            if isPlayer then
                BG.tradeCopyMoneyButton:ShowButton(sum)
                if BiaoGe.options["autoShowTradeCopyMoney"] == 1 then
                    BG.TradeCopyMoney(sum)
                    BG.ShowAutoShowTradeCopyMoneyButton()
                end
            end
            giveText:Show()
            giveText:SetText(label .. formatMoney(sum))
            updateColor()
            checkItems()
        end
    end
end

local function CollectTradeItems(getLink, getInfo, dest)
    for i = 1, 6 do
        local link = getLink(i)
        local name, texture, quantity, quality, isUsable, enchant = getInfo(i)
        if link and quality >= BG.tradeQuality then
            table.insert(dest, { link = link, count = quantity })
            BG.tradeQianKuanListFrame.hasItem = true
        end
    end
end

local function HasTradableTime(bag, slot)
    BiaoGeTooltip3:SetOwner(UIParent, "ANCHOR_NONE", 0, 0)
    BiaoGeTooltip3:ClearLines()
    BiaoGeTooltip3:SetBagItem(bag, slot)
    local line = 1
    while _G["BiaoGeTooltip3TextLeft" .. line] do
        local text = _G["BiaoGeTooltip3TextLeft" .. line]:GetText()
        if text then
            local remaining = text:match(BIND_TRADE_TIME_REMAINING:gsub("%%s", "(.+)"))
            if remaining then
                return true
            end
        end
        line = line + 1
    end
    return false
end

local function RenderAuctionButton(bt, v, autoMode)
    bt.link = v.link
    bt.b = v.b
    bt.i = v.i
    bt.itemID = v.itemID
    bt.isLocked = v.isLocked
    local r, g, b = GetItemQualityColor(v.quality)
    bt:SetBackdropBorderColor(r, g, b, 1)
    bt:GetHighlightTexture():SetVertexColor(r, g, b)
    bt.icon:SetTexture(v.icon)
    bt.icon:SetTexCoord(unpack(BG.iconTexCoord))
    bt.icon:SetDesaturated(v.isLocked)
    bt.icon:SetVertexColor(1, 1, 1)
    bt.count:SetText(v.count == 1 and "" or v.count)
    bt.level:SetText(v.level or "")
    bt.level:SetTextColor(r, g, b)
    if autoMode then
        if not v.b then
            bt.icon:SetVertexColor(1, 0, 0)
        end
        bt.money = v.money
    end
    bt:Show()
end

local function UpdateTradeQianKuan(readMoney, budget)
    if not (IsAutoAuctionMoneyEnabled() and BiaoGe.options["autoAuctionQianKuan"] == 1) then return end
    local money = readMoney()
    if money then
        money = math.modf(money / 10000)
        local debt = budget - money
        if debt <= 0 then
            debt = ""
        end
        BG.tradeQianKuanEdit:ClearFocus()
        BG.tradeQianKuanEdit:SetText(debt)
    end
end

local function AcceptTradeWhenReady(readMoney, readBudget, clearWhenNotMatched)
    if not (IsAutoAuctionMoneyEnabled() and BiaoGe.options["autoAuctionSureClick"] == 1) then return end
    local money = floor(readMoney() / 1e4)
    if money > 0 and money == readBudget() then
        BG.tradeUpdateFrame.elapsed = 0
        BG.tradeUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
            if not TradeFrame:IsVisible() then
                self:SetScript("OnUpdate", nil)
                return
            end
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= .5 then
                self:SetScript("OnUpdate", nil)
                local current = floor(readMoney() / 1e4)
                if current > 0 and current == readBudget() then
                    UIErrorsFrame:AddMessage(L["BGForge正在申请确认交易"], 1, 1, 0)
                    AcceptTrade()
                end
            end
        end)
    elseif clearWhenNotMatched then
        BG.tradeUpdateFrame:SetScript("OnUpdate", nil)
    end
end

local function SetSlotMoneyColor(prefix, r, g, b)
    for i = 1, 6 do
        _G[prefix .. i .. "ItemButton"].moneyText:SetTextColor(r, g, b)
    end
end

local function UpdateMoneyTextColor(readMoney, budget, text, prefix, warnOverpay, r, g, b)
    local money = readMoney()
    if not money then return end
    money = math.modf(money / 10000)
    if money == budget then
        text:SetTextColor(0, 1, 0)
        SetSlotMoneyColor(prefix, 0, 1, 0)
    elseif money > budget then
        text:SetTextColor(1, 0, 0)
        SetSlotMoneyColor(prefix, 1, 0, 0)
        if warnOverpay and budget > 0 then
            local hasItem
            for i = 1, 6 do
                if GetTradePlayerItemInfo(i) then
                    hasItem = true
                    break
                end
            end
            if hasItem and BG.tradeQianKuanListFrame.frame:IsVisible() and not BG.trade.showedOverpayWarning then
                BG.trade.showedOverpayWarning = true
                StaticPopup_Show("BiaoGeTradeOverpayWarning", BG.tradeQianKuanListFrame.Text2.text:GetText())
            end
        end
    elseif r then
        text:SetTextColor(r, g, b)
        SetSlotMoneyColor(prefix, r, g, b)
    else
        text:SetTextColor(RGB(BG.b1))
        SetSlotMoneyColor(prefix, RGB(BG.b1))
    end
end

local function ApplyBuyerToCell(FB, b, i, name)
    local cell = BG.Frame[FB]["boss" .. b]["maijia" .. i]
    cell:SetText(name)
    cell:SetCursorPosition(0)
    cell:SetTextColor(GetClassRGB(name))
    BiaoGe[FB]["boss" .. b]["maijia" .. i] = name
    for k in pairs(BG.playerClass) do
        if name == BG.playerName then
            BiaoGe[FB]["boss" .. b][k .. i] = BG.trade.playerinfo[k]
        else
            BiaoGe[FB]["boss" .. b][k .. i] = BG.trade.targetinfo[k]
        end
    end
end

local function ApplyAmountToCell(FB, b, i, amount, debt)
    BG.Frame[FB]["boss" .. b]["jine" .. i]:SetText(amount)
    BiaoGe[FB]["boss" .. b]["jine" .. i] = amount
    if debt ~= 0 then
        BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = debt
        BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
    end
end

local function FindRaidUnitButton(prefix, suffix, groups, perGroup, leaderName)
    for group = 1, groups do
        for index = 1, perGroup do
            local bt = _G[prefix .. group .. suffix .. index]
            if bt and bt:IsVisible() and bt.unit and BG.GN(bt.unit) == leaderName then
                return bt
            end
        end
    end
end

local function BindHoverToDetail(frame, row)
    frame:SetScript("OnEnter", function()
        row.ds:Show()
    end)
    frame:SetScript("OnLeave", function()
        row.ds:Hide()
    end)
end

local function SumTradeSide(getLink, tradeName, sum, label, prefix, formatMoney)
    local used = {}
    for _, v in ipairs(BG.auctionTrade[tradeName]) do
        local money = tonumber(v.jine) or 0
        for i = 1, 6 do
            if not used[i] then
                local link = getLink(i)
                if link then
                    if GetItemID(v.zhuangbei) == GetItemID(link) then
                        used[i] = true
                        sum = sum + money
                        if IsAutoAuctionMoneyEnabled() then
                            local moneyText = _G[prefix .. i .. "ItemButton"].moneyText
                            moneyText:Show()
                            moneyText:SetText(label .. formatMoney(money))
                            moneyText.money = money
                        end
                        break
                    end
                end
            end
        end
    end
    return sum
end

local function CollectAutoAuction(targetSum, playerSum)
    wipe(BG.trade.autoAuction)
    local tradePartner, expectedSum, readMoney, getLink, prefix
    if BG.ImMLorLeader() then
        tradePartner = BG.GN("NPC")
        expectedSum, readMoney, getLink, prefix = targetSum, GetTargetTradeMoney, GetTradePlayerItemLink, "TradePlayerItem"
    else
        tradePartner = BG.playerName
        expectedSum, readMoney, getLink, prefix = playerSum, GetPlayerTradeMoney, GetTradeTargetItemLink, "TradeRecipientItem"
    end
    local traded = math.modf(readMoney() / 10000)
    local remain = tonumber(BG.tradeQianKuanEdit:GetText()) or 0
    if expectedSum == 0 or expectedSum ~= traded + remain then
        return
    end
    for i = 1, 6 do
        local link = getLink(i)
        if link then
            local moneyText = _G[prefix .. i .. "ItemButton"].moneyText
            if not moneyText:IsVisible() then
                wipe(BG.trade.autoAuction)
                return
            end
            local money = moneyText.money
            local debt = 0
            if remain ~= 0 then
                if remain > money then
                    debt = money
                    remain = remain - debt
                else
                    debt = remain
                    remain = 0
                end
            end
            tinsert(BG.trade.autoAuction, {
                link = link,
                player = tradePartner,
                money = money,
                qiankuan = debt,
            })
        end
    end
    if remain > 0 then
        local last = BG.trade.autoAuction[#BG.trade.autoAuction]
        if last then
            last.qiankuan = last.qiankuan + remain
        end
    end
end

BG.Init(function()
    -- 交易时自动记下买家与金额
    do
        function BG.ResetTradeInfo()
            BG.trade.many = {}
            BG.trade.playerinfo = {}
            BG.trade.targetinfo = {}
            BG.trade.targetmoney = 0
            BG.trade.playermoney = 0
            BG.trade.target = ""
            wipe(BG.trade.targetitems)
            wipe(BG.trade.playeritems)
        end

        function BG.GetTradeInfo()
            BG.ResetTradeInfo()
            BG.trade.target = BG.GN("NPC")
            BG.trade.targetmoney = floor(GetTargetTradeMoney() / 10000)
            BG.trade.playermoney = floor(GetPlayerTradeMoney() / 10000)
            for k, v in pairs(BG.playerClass) do
                BG.trade.playerinfo[k] = select(v.select, v.func("player"))
                BG.trade.targetinfo[k] = select(v.select, v.func("NPC"))
            end

            BG.tradeQianKuanListFrame.hasItem = nil
            CollectTradeItems(GetTradeTargetItemLink, GetTradeTargetItemInfo, BG.trade.targetitems)
            CollectTradeItems(GetTradePlayerItemLink, GetTradePlayerItemInfo, BG.trade.playeritems)

            BG.TradeIsAutoAuction()
        end

        function BG.CancelGuanZhuAndHopeInTrade(itemID)
            local name, link = GetItemInfo(itemID)
            local haveguanzhu, havehope
            for _, FB in pairs(BG.FBtable) do
                local maxBoss = Maxb[FB]
                for b = 1, maxBoss do
                    local maxSlot = BG.GetMaxi(FB, b)
                    local bossFrame = BG.Frame[FB]["boss" .. b]
                    for i = 1, maxSlot do
                        local bt = bossFrame["zhuangbei" .. i]
                        if bt then
                            local _itemID = GetItemID(bt:GetText())
                            if _itemID == itemID then
                                if BiaoGe[FB]["boss" .. b]["guanzhu" .. i] then
                                    BiaoGe[FB]["boss" .. b]["guanzhu" .. i] = nil
                                    bossFrame["guanzhu" .. i]:Hide()
                                    haveguanzhu = true
                                end
                            end
                        end
                    end
                end
            end

            -- 只有交易记账确认装备归当前角色后才移除心愿；单纯掉落不会删除。
            havehope = BG.DeleteHope and BG.DeleteHope(itemID) or false

            if haveguanzhu and havehope then
                BG.SendSystemMessage(format(L["已自动取消%s的关注和心愿。"], name))
            elseif haveguanzhu then
                BG.SendSystemMessage(format(L["已自动取消%s的关注。"], name))
            elseif havehope then
                BG.SendSystemMessage(format(L["已自动取消%s的心愿。"], name))
            end
        end

        function BG.GetTradeSeeText(saved)
            local FB = BG.FB1
            local target = BG.trade.target
            local player = BG.trade.player
            local targetmoney = BG.trade.targetmoney
            local playermoney = BG.trade.playermoney
            local targetitems = BG.trade.targetitems
            local playeritems = BG.trade.playeritems
            local returntext = ""
            BG.tradeSeeFrame.frame:SetNormalColor()
            if not BG.tradeSeeFrame.CheckButton:GetChecked() then
                return returntext
            end
            if BG.IsAutoCreateBill() then
                return returntext
            end
            local qiankuan = 0
            if BG.tradeQianKuanEdit and tonumber(BG.tradeQianKuanEdit:GetText()) then
                qiankuan = qiankuan + tonumber(BG.tradeQianKuanEdit:GetText())
            end
            local qiankuantext = ""
            if qiankuan ~= 0 then
                qiankuantext = format("|cffFF0000" .. L["（欠款%d）"] .. RR, qiankuan)
            end
            -- 双方都给出装备
            if targetitems[1] and playeritems[1] and targetmoney == 0 and playermoney == 0 then --双方都有装备，但没金额，这种是交易失败
                returntext = ("|cffDC143C" .. L["< 交易记账失败 >"] .. RN .. L["双方都给了装备，但没金额"] .. NN .. L["我不知道谁才是买家"] .. NN .. NN .. L["如果有金额我就能识别了"])
                BG.tradeSeeFrame.frame:SetFalseColor()
                return returntext
            end
            -- 记为罚款
            if BG.tradeSeeFrame.fakuanButton.isChoose and (targetmoney ~= 0 or playermoney ~= 0) then
                local Player, Money
                if targetmoney ~= 0 then
                    Player = target
                    Money = targetmoney
                elseif playermoney ~= 0 then
                    Player = player
                    Money = playermoney
                end
                returntext = (format("|cff00BFFF" ..
                    L["< 交易记账成功 >|r\n项目：|cffff0000罚款|r\n玩家：%s\n金额：%s%d|rg"],
                    SetClassCFF(Player), "|cffFFD700",
                    Money + qiankuan,
                    qiankuantext))
                if saved then
                    local hasGZ
                    BG.PairFBItem(function(item, buyer, money, b, i)
                        if item:GetText() == "" and buyer:GetText() == "" and money:GetText() == ""
                            and not BiaoGe[FB]["boss" .. b]["qiankuan" .. i] then
                            hasGZ = true
                            local _r, _g, _b = GetClassRGB(Player)
                            item:SetText(L["罚款"])
                            buyer:SetText(Player)
                            buyer:SetTextColor(_r, _g, _b)
                            money:SetText(Money + qiankuan)
                            BiaoGe[FB]["boss" .. b]["zhuangbei" .. i] = L["罚款"]
                            BiaoGe[FB]["boss" .. b]["maijia" .. i] = Player
                            BiaoGe[FB]["boss" .. b]["jine" .. i] = Money + qiankuan
                            for k, v in pairs(BG.playerClass) do
                                BiaoGe[FB]["boss" .. b][k .. i] = select(v.select, v.func(Player))
                            end
                            if qiankuan ~= 0 then
                                BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = qiankuan
                                BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                            end
                            return true
                        end
                    end, Maxb[FB])
                    if not hasGZ then
                        returntext = ("|cffDC143C" .. L["< 交易记账失败 >"] .. RN .. L["罚款格子满了。。"])
                        BG.PlaySound("fakuanFull")
                    end
                end
                return returntext
            end
            -- 记为退货
            if BG.tradeSeeFrame.refundButton.isChoose and (next(BG.trade.targetitems) or next(BG.trade.playeritems)) then
                local Player, items
                if next(BG.trade.targetitems) then
                    Player = target
                    items = BG.trade.targetitems
                elseif next(BG.trade.playeritems) then
                    Player = player
                    items = BG.trade.playeritems
                end
                if #items > 1 then
                    returntext = L["|cffDC143C< 退货失败 >|r\n只能对1件装备进行退货处理"]
                    BG.tradeSeeFrame.frame:SetFalseColor()
                    return returntext
                end
                local targetItem = items[1]
                local itemID = GetItemID(targetItem.link)
                local hasItem
                BG.PairFBItem(function(item, buyer, money, b, i)
                    local _item = item:GetText()
                    local _buyer = buyer:GetText()
                    local _money = money:GetText()
                    if itemID == GetItemID(_item) and Player == _buyer then
                        local QKmoney = tonumber(BiaoGe[FB]["boss" .. b]["qiankuan" .. i]) or 0
                        local __money = _money - QKmoney
                        local QKText = ""
                        if QKmoney > 0 then
                            QKText = L["（|cffFFD700%s|r-|cffff0000%s|r）"]:format(_money, QKmoney)
                        end
                        returntext = L["|cff00BFFF< 退货成功 >|r\n装备：%s\n退货人：%s\n应退金额：|cffFFD700%s|rg%s\nBoss：|cff%s%s"]:format(
                            _item, SetClassCFF(_buyer), __money, QKText, BG.Boss[FB]["boss" .. b]["color"], BG.Boss[FB]["boss" .. b]["name2"])
                        hasItem = true
                        if saved then
                            buyer:Clear()
                            money:Clear()
                            money:ClearQK()
                            if BiaoGe[FB].auctionLog then
                                for i, v in ipairs(BiaoGe[FB].auctionLog) do
                                    if v.type == 1 and v.maijia == _buyer and v.jine == _money
                                        and v.trade and BG.IsSameItem(v.zhuangbei, _item) then
                                        BG.SendSystemMessage(L['%s的拍卖记录已被改为未拍。']:format(v.zhuangbei))
                                        if BG.ImML() and IsInRaid(1) then
                                            SendGateway.Addon(C.PREFIX_AUX,
                                                format(C.OP_REFUND_TO_FAILED .. "^%s^%s^%s^%s", GetItemID(v.zhuangbei), v.zhuangbei, v.maijia, v.jine),
                                                "RAID")
                                        end
                                        tremove(BiaoGe[FB].auctionLog, i)
                                        local name = "BiaoGe_TuiHuoReAuction"
                                        if not StaticPopupDialogs[name] then
                                            StaticPopupDialogs[name] = {
                                                text = L["重新拍卖%s吗？\n\n起拍价：%s"],
                                                button1 = L["是"],
                                                button2 = L["否"],
                                                OnShow = function(self)
                                                    self:SetHyperlinksEnabled(true)
                                                    self:SetScript("OnHyperlinkEnter", function(self, link, text, button)
                                                        local itemID = GetItemID(link)
                                                        if itemID then
                                                            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, 0)
                                                            GameTooltip:ClearLines()
                                                            GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                                                        end
                                                    end)
                                                    self:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
                                                end,
                                                OnAccept = function(self, data)
                                                    local isGen2 = BiaoGe.Auction.gen == 2
                                                    local mod = BiaoGe.Auction.mod
                                                    local resetThreshold = max(tonumber(BiaoGe.Auction.resetThreshold) or 0, 10)
                                                    BG.SendStartAuctionMsg(isGen2, data.itemID, data.money, 20, mod, data.link, resetThreshold)
                                                end,
                                                OnCancel = function()
                                                end,
                                                timeout = 0,
                                                whileDead = true,
                                                hideOnEscape = true,
                                                showAlert = true,
                                            }
                                        end
                                        StaticPopup_Show(name, v.zhuangbei, _money,
                                            { link = v.zhuangbei, itemID = GetItemID(v.zhuangbei), money = _money })
                                        break
                                    end
                                end
                            end
                        end
                        return true
                    end
                end)
                if not hasItem then
                    returntext = L["|cffDC143C< 退货失败 >|r\n表格里没找到此件装备"]
                    BG.tradeSeeFrame.frame:SetFalseColor()
                else
                    BG.tradeSeeFrame.frame:SetGreenColor()
                end
                return returntext
            end

            -- 使用自动拍卖的记账
            if next(BG.trade.autoAuction) then
                local returnText = ""
                for _, v in ipairs(BG.trade.autoAuction) do
                    local b = v.b
                    local i = v.i
                    local link = v.link
                    local itemID = GetItemID(link)
                    local player = v.player
                    local money = v.money
                    local qiankuan = v.qiankuan
                    local icon = select(5, GetItemInfoInstant(itemID))
                    local qiankuanText = ""
                    if qiankuan > 0 then
                        qiankuanText = format(L["|cffFF0000（欠款%d）|r"], qiankuan)
                    end
                    returnText = returnText .. AddTexture(icon) .. " |cffFFD700" .. money .. "|rg" .. qiankuanText .. "\n"
                    if saved then
                        -- 保存买家信息
                        ApplyBuyerToCell(FB, b, i, player)
                        -- 金额和欠款
                        ApplyAmountToCell(FB, b, i, money, qiankuan)
                        -- 取消关注
                        if player == BG.playerName then
                            BG.CancelGuanZhuAndHopeInTrade(itemID)
                        end
                        -- 打包交易
                        local a = {
                            FB = FB,
                            itemID = itemID,
                            link = link,
                            b = b,
                            i = i
                        }
                        tinsert(BG.trade.many, a)
                    end
                end
                BG.tradeSeeFrame.frame:SetGreenColor()
                return returnText
            end

            -- 非自动拍卖的记账
            local Items, Money, Items2, Money2, Player
            for ii = 1, 2 do
                if ii == 1 then -- 玩家给出金额，得到装备（玩家买装备情景）
                    Items = targetitems
                    Items2 = playeritems
                    Money = playermoney
                    Money2 = targetmoney
                    Player = player
                elseif ii == 2 then -- 玩家给出装备，得到金钱（团长情景）
                    Items = playeritems
                    Items2 = targetitems
                    Money = targetmoney
                    Money2 = playermoney
                    Player = target
                end

                if (targetitems[1] and playeritems[1] and Money ~= 0)                 -- 双方都有装备，但玩家出了金
                    or (Items[1] and not Items2[1] and (Money ~= 0 or qiankuan ~= 0)) -- 其中一方有装备且金额不等于0
                then
                    local isFirstItem = true
                    local itemCount = #Items
                    for items = 1, itemCount do
                        local done
                        local maxBoss = Maxb[FB]
                        for b = 1, maxBoss do
                            local maxSlot = BG.GetMaxi(FB, b)
                            local bossFrame = BG.Frame[FB]["boss" .. b]
                            for i = 1, maxSlot do
                                local bt = bossFrame["zhuangbei" .. i]
                                if bt and GetItemID(bt:GetText()) == GetItemID(Items[items].link) and
                                    bossFrame["maijia" .. i]:GetText() == "" and
                                    bossFrame["jine" .. i]:GetText() == "" and
                                    not BiaoGe[FB]["boss" .. b]["qiankuan" .. i]
                                then
                                    if saved then
                                        ApplyBuyerToCell(FB, b, i, Player)
                                        ApplyAmountToCell(FB, b, i,
                                            isFirstItem and (Money + qiankuan) or L["打包交易"],
                                            isFirstItem and qiankuan or 0)
                                        -- 取消关注
                                        if Player == BG.playerName then
                                            local itemID = GetItemID(bt:GetText())
                                            BG.CancelGuanZhuAndHopeInTrade(itemID)
                                        end
                                        if #Items > 1 then
                                            local a = {
                                                FB = FB,
                                                itemID = GetItemID(Items[items].link),
                                                link = Items[items].link,
                                                b = b,
                                                i = i
                                            }
                                            tinsert(BG.trade.many, a)
                                        end
                                    end
                                    if isFirstItem then
                                        local Texture = select(10, GetItemInfo(Items[items].link))
                                        local bossMeta = BG.Boss[FB]["boss" .. b]
                                        returntext = (format("|cff00BFFF" ..
                                            L["< 交易记账成功 >|r\n装备：%s\n买家：%s\n金额：%s%d|rg%s\nBoss：%s%s|r"],
                                            (AddTexture(Texture) .. Items[items].link),
                                            SetClassCFF(Player), "|cffFFD700",
                                            Money + qiankuan,
                                            qiankuantext,
                                            "|cff" .. bossMeta["color"],
                                            bossMeta["name2"]))
                                    elseif not strfind(returntext, L["（剩余装备记录为打包交易）"]) then
                                        returntext = returntext .. NN .. BG.STC_dis(L["（剩余装备记录为打包交易）"])
                                    end
                                    isFirstItem = nil
                                    done = true
                                    break
                                end
                            end
                            if done then break end
                        end
                    end
                    if returntext ~= "" then
                        return returntext
                    end

                    returntext = ("|cffDC143C" .. L["< 交易记账失败 >"] .. RN .. L["表格里没找到此次交易的装备，或者该装备已记过账"])
                    BG.tradeSeeFrame.frame:SetFalseColor()
                    return returntext
                end
            end
            return returntext
        end
    end

    -- 欠款输入框、金币超过上限、重复交易、团长交易状态，以及交易框物品高亮
    do
        -- 交易欠款输入框
        do
            local f = CreateFrame("Frame", nil, TradeFrame, "BackdropTemplate")
            f:SetBackdrop(BACKDROP_TOOLTIP)
            f:SetBackdropColor(0.5, 0, 0, 0.5)
            f:SetBackdropBorderColor(1, 0, 0, .5)
            f:SetSize(150, 25)
            f:SetPoint("BOTTOM", TradeRecipientMoneyBg, "TOP", 0, 3)
            f:SetToplevel(true)
            f:EnableMouse(true)
            f:SetFrameLevel(TradeRecipientMoneyBg:GetFrameLevel() + 10)

            local edit = CreateFrame("EditBox", nil, f, BG.editTemplate)
            edit:SetSize(90, 20)
            edit:SetPoint("RIGHT", -5, 0)
            edit:SetText("")
            edit:SetTextColor(RGB("FF0000"))
            edit:SetNumeric(true)
            edit:SetAutoFocus(false)
            edit.frame = f
            edit:SetScript("OnTextChanged", function(self)
                BG.UpdateTwo0(self)
                BG.GetTradeInfo()
                BG.tradeSeeFrame.frame:Update()
            end)
            edit:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    self:SetEnabled(false)
                    self:SetText("")
                end
            end)
            edit:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    self:SetEnabled(true)
                end
            end)
            edit:HookScript("OnEditFocusLost", function(self, button)
                if BG.FrameNumFrame then
                    BG.FrameNumFrame:Hide()
                end
            end)
            BG.tradeQianKuanEdit = edit

            local text = edit:CreateFontString()
            text:SetPoint("RIGHT", edit, "LEFT", -8, 0)
            SetOutlineFont(text, 14)
            text:SetTextColor(RGB("FF0000"))
            text:SetText(L["欠款："])
            text:SetWidth(80)
            text:SetJustifyH("RIGHT")

            function BG.tradeQianKuanEdit:Update()
                self.frame:SetShown(BiaoGe.options["autoTrade"] == 1 and IsInRaid(1) and not BG.IsAutoCreateBill())
                self:SetText("")
            end

            _G.TradeFrame:HookScript("OnMouseDown", function(self, enter)
                edit:ClearFocus()
            end)
        end

        -- 金币超上限
        do
            local f = CreateFrame("Frame", nil, TradeFrame, "BackdropTemplate")
            f:SetBackdrop(BACKDROP_CHAT)
            f:SetBackdropColor(0, 0, 0, .9)
            f:SetBackdropBorderColor(1, 0, 0, 1)
            f:SetPoint("BOTTOMRIGHT", TradeRecipientMoneyBg, "TOPRIGHT", 0, 0)
            f:SetFrameStrata("HIGH")
            BG.tradeGoldTop = f
            local t = f:CreateFontString()
            t:SetPoint("CENTER")
            SetOutlineFont(t, 15)
            t:SetTextColor(RGB(BG.r1))
            t:SetText(L["金币已超上限！"])
            f:SetSize(t:GetStringWidth() + 10, t:GetHeight() + 5)
            if BG.verLess2 then
                BG.tradeGoldTop.topNum = 214745
            else
                BG.tradeGoldTop.topNum = 999999
            end

            function BG.tradeGoldTop:Update()
                self:Hide()
                if IsTradePreviewEnabled() then
                    local mymoney = floor(GetMoney() / 10000) or 0
                    local targetmoney = BG.trade.targetmoney or 0
                    if mymoney + targetmoney >= self.topNum then
                        self:Show()
                    end
                end
            end
        end

        -- 重复交易
        do
            local function Create(parent)
                local f = CreateFrame("Frame", nil, parent)
                f:SetFrameStrata("HIGH")
                local t = f:CreateFontString()
                SetOutlineFont(t, 15)
                t:SetTextColor(1, 0, 0)
                t:SetText(L["重复交易！"])
                f.Text = t
                -- f:Hide()
                -- 提示
                local bt = CreateFrame("Button", nil, f)
                bt:SetSize(16, 16)
                bt:SetPoint("BOTTOMLEFT", t, "BOTTOMRIGHT", 0, 0)
                CreateDuplicateTradeTexture(bt)
                bt:SetHighlightTexture(CreateDuplicateTradeTexture(bt))
                bt:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["重复交易"], 1, 1, 1, true)
                    GameTooltip:AddLine(format(L["你%s秒前曾交给他相同的金币！"], BG.tradeSameMoney.beforeTime), 1, 0.82, 0, true)
                    GameTooltip:Show()
                end)
                bt:SetScript("OnLeave", GameTooltip_Hide)
                return f
            end
            BG.tradeSameMoney = Create(TradeFrame)
            BG.tradeSameMoney:Hide()
            BG.tradeSameMoney.trade = {}
            BG.tradeSameMoney.Text:SetPoint("RIGHT", BG.tradeQianKuanEdit.frame, "LEFT", -20, 0)
            BG.tradeSameMoney.f2 = Create(BG.tradeSameMoney)
            BG.tradeSameMoney.f2.Text:SetPoint("BOTTOMLEFT", TradeFrameTradeButton, "TOPLEFT", 0, 0)

            function BG.tradeSameMoney:SaveTradeMoney()
                if IsTradePreviewEnabled() then
                    if next(BG.trade.targetitems) or next(BG.trade.playeritems)
                        or (BG.trade.playermoney and BG.trade.playermoney == 0)
                        or not BG.trade.target
                    then
                        return
                    end
                    self.trade[BG.trade.target] = self.trade[BG.trade.target] or {}
                    tinsert(self.trade[BG.trade.target], {
                        time = time(),
                        money = BG.trade.playermoney,
                    })
                end
            end

            function BG.tradeSameMoney:Update()
                self:Hide()
                if IsTradePreviewEnabled() then
                    local money = BG.trade.playermoney
                    local targetName = BG.trade.target
                    if not money or money == 0 or not targetName or not self.trade[targetName] then return end
                    local isSame
                    for _, v in ipairs(self.trade[targetName]) do
                        if v.money == money then
                            isSame = true
                            self.beforeTime = time() - v.time
                            break
                        end
                    end
                    if not isSame then return end
                    -- 交易框中一件物品也没有
                    if next(BG.trade.targetitems) or next(BG.trade.playeritems) then
                        return
                    end
                    self:Show()
                    UIErrorsFrame:AddMessage(L["重复交易！"], 1, 0, 0)
                end
            end

            C_Timer.NewTicker(30, function()
                local time = time()
                for name in pairs(BG.tradeSameMoney.trade) do
                    for i = #BG.tradeSameMoney.trade[name], 1, -1 do
                        local v = BG.tradeSameMoney.trade[name][i]
                        if time - v.time >= 60 * 2 then
                            tremove(BG.tradeSameMoney.trade[name], i)
                        end
                    end
                end
            end)
        end

        -- 团长交易状态
        do
            local cd
            local function HideTradingButton()
                if BG.isTradingTips then
                    BG.isTradingTips:Hide()
                end
            end
            local function ShowTradingButton(bt, targetName)
                targetName = targetName or UNKNOWN
                if not BG.isTradingTips then
                    local f = CreateFrame("Frame", nil, bt, "BackdropTemplate")
                    f:SetBackdrop(BACKDROP_CHAT_ONLY)
                    f:SetBackdropColor(0, 0, 0, 0.5)
                    local t = f:CreateFontString()
                    SetOutlineFont(t, 14)
                    t:SetTextColor(1, 0, 0)
                    t:SetText(L["交易中:"])
                    f.tradingText = t
                    local t = f:CreateFontString()
                    SetOutlineFont(t, 12)
                    t:SetPoint("TOP", f.tradingText, "BOTTOM")
                    f.targetText = t
                    BG.isTradingTips = f
                end
                local height = bt:GetHeight() * 0.8
                BG.isTradingTips:ClearAllPoints()
                BG.isTradingTips:SetParent(bt)
                BG.isTradingTips:SetAllPoints()
                BG.isTradingTips:SetFrameLevel(1000)
                BG.isTradingTips.tradingText:ClearAllPoints()
                BG.isTradingTips.tradingText:SetPoint("TOP", 0, -bt:GetHeight() * 0.15)
                SetOutlineFont(BG.isTradingTips.tradingText, height / 2)
                SetOutlineFont(BG.isTradingTips.targetText, height / 2 * 0.8)
                BG.isTradingTips.targetText:SetText(SetClassCFF(targetName))
                BG.isTradingTips:Show()
            end
            local function SetTradeIng(leaderName, targetName)
                if cd then return end
                cd = true
                BG.After(.2, function() cd = nil end)
                if not (BiaoGe.options.autoTrade == 1 and BiaoGe.options.isTrading == 1 and BG.IsMLByName(leaderName)) then return end
                local isCell
                if IsAddOnLoaded("Cell") then
                    local bt = FindRaidUnitButton("CellRaidFrameHeader", "UnitButton", 8, 5, leaderName)
                    if bt then
                        ShowTradingButton(bt, targetName)
                        return
                    end
                    isCell = true
                elseif IsAddOnLoaded("NDui") then
                    local bt = FindRaidUnitButton("oUF_Raid", "UnitButton", 8, 5, leaderName)
                    if bt then
                        ShowTradingButton(bt, targetName)
                        return
                    end
                elseif IsAddOnLoaded("ElvUI") then
                    for r = 1, 3 do
                        local bt = FindRaidUnitButton("ElvUF_Raid" .. r .. "Group", "UnitButton", 8, 5, leaderName)
                        if bt then
                            ShowTradingButton(bt, targetName)
                            return
                        end
                    end
                end
                if not isCell then
                    local bt = FindRaidUnitButton("CompactRaidGroup", "Member", 8, 5, leaderName)
                    if bt then
                        ShowTradingButton(bt, targetName)
                        return
                    end
                    for i = 1, 40 do
                        local raidButton = _G["CompactRaidFrame" .. i]
                        if raidButton and raidButton:IsVisible() and raidButton.unit and BG.GN(raidButton.unit) == leaderName then
                            ShowTradingButton(raidButton, targetName)
                            return
                        end
                    end
                end
            end
            BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, prefix, msg, channel, sender)
                sender = BG.GSN(sender)
                if not (prefix == C.PREFIX_MAIN and channel == "RAID" and BG.IsMLByName(sender)) then return end
                if msg == "tradeEnd" then
                    HideTradingButton()
                else
                    if not InCombatLockdown() and sender ~= BG.playerName then
                        local arg1, name = strsplit("-", msg, 2)
                        if arg1 == "tradeTo" then
                            SetTradeIng(sender, name)
                        end
                    end
                end
            end)
            BG.RegisterEvent("PLAYER_REGEN_DISABLED", function(self, ...)
                HideTradingButton()
            end)
            BG.RegisterEvent("GROUP_ROSTER_UPDATE", function(self, ...)
                HideTradingButton()
            end)
            BG.RegisterEvent("TRADE_SHOW", function(self, ...)
                if BG.ImMLorLeader() then
                    local target = BG.GN("NPC")
                    if target then
                        SendGateway.Addon(C.PREFIX_MAIN, "tradeTo-" .. target, "RAID")
                    end
                end
            end)
            local timer = 0
            BG.RegisterEvent("TRADE_CLOSED", function(self, ...)
                if GetTime() - timer < .2 then return end
                timer = GetTime()
                if BG.ImMLorLeader() then
                    SendGateway.Addon(C.PREFIX_MAIN, "tradeEnd", "RAID")
                end
            end)
        end

        -- 高亮交易框里物品对应的格子
        do
            local function PlayerOnEnter(self)
                local ID = self:GetParent():GetID()
                local link = GetTradePlayerItemLink(ID)
                if link then
                    BG.Show_AllHighlight(link)
                end
            end
            local function TargetOnEnter(self)
                local ID = self:GetParent():GetID()
                local link = GetTradeTargetItemLink(ID)
                if link then
                    BG.Show_AllHighlight(link)
                end
            end
            for i = 1, 7 do
                local playerBtn = _G["TradePlayerItem" .. i .. "ItemButton"]
                local recipientBtn = _G["TradeRecipientItem" .. i .. "ItemButton"]
                if playerBtn and playerBtn.HookScript then
                    playerBtn:HookScript("OnEnter", PlayerOnEnter)
                    playerBtn:HookScript("OnLeave", BG.Hide_AllHighlight)
                end
                if recipientBtn and recipientBtn.HookScript then
                    recipientBtn:HookScript("OnEnter", TargetOnEnter)
                    recipientBtn:HookScript("OnLeave", BG.Hide_AllHighlight)
                end
            end
        end
    end

    -- 欠款记录
    do
        BG.tradeQianKuanListFrame = {}
        local f = CreateFrame("Frame", nil, TradeFrame, "BackdropTemplate")
        f:SetBackdrop(BACKDROP_CHAT)
        f:SetBackdropColor(0, 0, 0, 0.7)
        f:SetBackdropBorderColor(0, 0, 0, 1)
        f:SetSize(TradeFrame:GetWidth() + 2, 175)
        f:SetPoint("TOP", TradeFrame, "BOTTOM", 0, -1)
        f:EnableMouse(true)
        f:Hide()
        BG.tradeQianKuanListFrame.frame = f

        local text = f:CreateFontString()
        text:SetPoint("TOP", f, "TOP", 0, -5)
        SetOutlineFont(text, 16)
        text:SetText(L["对方欠款记录"])

        local bt = BG.CreateButton(f)
        bt:SetSize(80, 20)
        bt:SetPoint("TOPLEFT", 8, -2)
        bt:SetText(L["刷新"])
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            BG.tradeQianKuanListFrame:Update()
        end)

        -- 总欠款
        do
            local f = CreateFrame("Frame", nil, BG.tradeQianKuanListFrame.frame)
            f:SetSize(0, 20)
            f:SetPoint("BOTTOMLEFT", 7, 5)
            f.text = f:CreateFontString()
            SetOutlineFont(f.text, 15)
            f.text:SetPoint("LEFT")
            f.text:SetText(L["合计欠款："])
            SetJustifyLeft(f.text)
            f:SetWidth(f.text:GetStringWidth())
            BG.tradeQianKuanListFrame.Text1 = f

            local f = CreateFrame("Frame", nil, BG.tradeQianKuanListFrame.Text1)
            f:SetSize(100, 20)
            f:SetPoint("LEFT", BG.tradeQianKuanListFrame.Text1, "RIGHT", 5, 0)
            f.text = f:CreateFontString()
            SetOutlineFont(f.text, 15)
            f.text:SetAllPoints()
            f.text:SetTextColor(1, 0, 0)
            SetJustifyLeft(f.text)
            BG.tradeQianKuanListFrame.Text2 = f
        end

        -- 清除全部欠款
        do
            local bt = BG.CreateButton(BG.tradeQianKuanListFrame.Text1)
            bt:SetSize(100, 20)
            bt:SetPoint("BOTTOMRIGHT", BG.tradeQianKuanListFrame.frame, "BOTTOMRIGHT", -7, 5)
            bt:SetText(L["清除全部欠款"])
            BG.tradeQianKuanListFrame.ButtonClearAll = bt
            bt:SetScript("OnClick", function(self)
                if BG.tradeQianKuanListFrame.hasItem then
                    return
                end
                local unit = "NPC"
                local target = BG.GN(unit)
                local class = select(2, UnitClass(unit))
                local color = select(4, GetClassColor(class))
                StaticPopup_Show("BiaoGeClearAllQianKuan", "|c" .. color .. target .. RR, BG.tradeQianKuanListFrame.Text2.text:GetText())
            end)
            bt:SetScript("OnEnter", function(self)
                if BG.tradeQianKuanListFrame.hasItem then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["错误！禁止清除欠款"], 1, 0, 0, true)
                    GameTooltip:AddLine(L["欠款需要单独收取，不要和装备混在一起交易！否则账单错误！"], 1, 0.82, 0, true)
                    GameTooltip:Show()
                end
            end)
            bt:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end

        local frame, child = BG.CreateScrollFrame(BG.tradeQianKuanListFrame.frame, BG.tradeQianKuanListFrame.frame:GetWidth() - 15, BG.tradeQianKuanListFrame.frame:GetHeight() - 55)
        frame:SetPoint("TOPLEFT", 7.5, -25)
        frame:SetBackdrop(BACKDROP_EDGE)
        frame:SetBackdropBorderColor(.5, .5, .5, .5)

        local buttons = {}
        function BG.tradeQianKuanListFrame:Update()
            BG.tradeQianKuanListFrame.frame:Hide()
            if IsTradePreviewEnabled() then
                local unit = "NPC"
                local target = BG.GN(unit)
                for i, v in ipairs(buttons) do
                    v.frame:Hide()
                end
                wipe(buttons)
                local sum = 0
                local yes
                local FB = BG.FB1
                local maxBoss = Maxb[FB]
                for b = 1, maxBoss do
                    local maxSlot = BG.GetMaxi(FB, b)
                    local bossFrame = BG.Frame[FB]["boss" .. b]
                    for i = 1, maxSlot do
                        local zhuangbei = bossFrame["zhuangbei" .. i]
                        local maijia = bossFrame["maijia" .. i]
                        if maijia then
                            if maijia:GetText() == target and BiaoGe[FB]["boss" .. b]["qiankuan" .. i] then
                                yes = true
                                local bts = {}
                                sum = sum + tonumber(BiaoGe[FB]["boss" .. b]["qiankuan" .. i])

                                -- 底色
                                do
                                    local f = CreateFrame("Frame", nil, child)
                                    if #buttons == 0 then
                                        f:SetPoint("TOPLEFT", 0, 0)
                                    else
                                        f:SetPoint("TOPLEFT", buttons[#buttons].frame, "BOTTOMLEFT", 0, -2)
                                    end
                                    f:SetSize(0, 20)
                                    bts.frame = f
                                    BindHoverToDetail(f, bts)
                                    local tex = bts.frame:CreateTexture()
                                    tex:SetPoint("LEFT")
                                    tex:SetSize(0, 20)
                                    tex:SetColorTexture(.5, .5, .5, .3)
                                    bts.ds = tex
                                    tex:Hide()
                                end
                                -- 序号
                                do
                                    local f = CreateFrame("Frame", nil, bts.frame)
                                    f:SetSize(20, 20)
                                    f:SetPoint("LEFT", 0, 0)
                                    f.text = f:CreateFontString()
                                    SetOutlineFont(f.text, 13)
                                    f.text:SetAllPoints()
                                    f.text:SetTextColor(1, 0.82, 0)
                                    f.text:SetText((#buttons + 1))
                                    bts.num = f
                                    BindHoverToDetail(f, bts)
                                end

                                -- 图标
                                do
                                    local icon = select(5, GetItemInfoInstant(zhuangbei:GetText()))
                                    local f = CreateFrame("Frame", nil, bts.frame)
                                    f:SetPoint("LEFT", bts.num, "RIGHT", 2, 0)
                                    f:SetSize(16, 16)
                                    local tex = f:CreateTexture()
                                    tex:SetAllPoints()
                                    tex:SetTexture(icon)
                                    bts.icon = f
                                    bts.hasicon = tex:GetTexture()
                                    BindHoverToDetail(f, bts)
                                end
                                -- 装备
                                do
                                    local f = CreateFrame("Frame", nil, bts.frame)
                                    f:SetSize(0, 20)
                                    f:SetPoint("LEFT", bts.icon, "RIGHT", bts.hasicon and 0 or -16, 0)
                                    f.text = f:CreateFontString()
                                    SetOutlineFont(f.text, 15)
                                    f.text:SetAllPoints()
                                    f.text:SetText(zhuangbei:GetText())
                                    SetJustifyLeft(f.text)
                                    bts.item = f
                                    f:SetScript("OnEnter", function(self)
                                        local link = zhuangbei:GetText()
                                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                                        GameTooltip:ClearLines()
                                        local itemID = GetItemInfoInstant(link)
                                        if itemID then
                                            GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                                            BG.Show_AllHighlight(link)
                                        end
                                        bts.ds:Show()
                                    end)
                                    f:SetScript("OnLeave", function(self)
                                        GameTooltip:Hide()
                                        BG.Hide_AllHighlight()
                                        bts.ds:Hide()
                                    end)
                                    f:SetScript("OnMouseDown", function(self)
                                        local link = zhuangbei:GetText()
                                        local name, link, quality, level, _, _, _, _, _, Texture, _, typeID = GetItemInfo(link)
                                        if link then
                                            if IsShiftKeyDown() then
                                                BG.InsertLink(link)
                                                -- else
                                                --     ShowUIPanel(ItemRefTooltip)
                                                --         ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
                                                --     end
                                                --     ItemRefTooltip:SetHyperlink(link)
                                            end
                                        end
                                    end)
                                end
                                -- 欠款
                                do
                                    local f = CreateFrame("Frame", nil, bts.frame)
                                    f:SetSize(80, 20)
                                    f:SetPoint("LEFT", bts.item, "RIGHT", 2, 0)
                                    f.text = f:CreateFontString()
                                    SetOutlineFont(f.text, 15)
                                    f.text:SetAllPoints()
                                    f.text:SetText(BiaoGe[FB]["boss" .. b]["qiankuan" .. i])
                                    f.text:SetTextColor(1, 0, 0)
                                    SetJustifyLeft(f.text)
                                    if f.text:GetStringWidth() > f.text:GetWidth() then
                                        f.iswordwrap = true
                                    end
                                    bts.qiankuan = f
                                    f:SetScript("OnEnter", function(self)
                                        if self.iswordwrap then
                                            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                                            GameTooltip:ClearLines()
                                            GameTooltip:AddLine(BiaoGe[FB]["boss" .. b]["qiankuan" .. i], 1, 0, 0, true)
                                            GameTooltip:Show()
                                        end
                                        bts.ds:Show()
                                    end)
                                    f:SetScript("OnLeave", function(self)
                                        GameTooltip:Hide()
                                        bts.ds:Hide()
                                    end)
                                end
                                -- 按钮
                                do
                                    local bt = BG.CreateButton(bts.frame)
                                    bt:SetSize(50, 18)
                                    bt:SetPoint("LEFT", bts.qiankuan, "RIGHT", 5, 0)
                                    bt:SetText(L["清除"])
                                    bts.button = bt
                                    bt:SetScript("OnClick", function()
                                        if BG.tradeQianKuanListFrame.hasItem then
                                            return
                                        end
                                        BG.PlaySound(1)
                                        local class = select(2, UnitClass(unit))
                                        local color = select(4, GetClassColor(class))
                                        BG.SendSystemMessage(format(L["已清除%s的%s欠款|cffFF0000%s|r。"],
                                            "|c" .. color .. target .. RR,
                                            zhuangbei:GetText():gsub("|cff......|Hitem:.-%[(.-)%]|h|r", "%1"),
                                            BiaoGe[FB]["boss" .. b]["qiankuan" .. i]))

                                        BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = nil
                                        BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Hide()

                                        BG.tradeQianKuanListFrame:Update()
                                    end)
                                    bt:SetScript("OnEnter", function(self)
                                        bts.ds:Show()
                                        if BG.tradeQianKuanListFrame.hasItem then
                                            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                                            GameTooltip:ClearLines()
                                            GameTooltip:AddLine(L["错误！禁止清除欠款"], 1, 0, 0, true)
                                            GameTooltip:AddLine(L["欠款需要单独收取，不要和装备混在一起交易！否则账单错误！"], 1, 0.82, 0, true)
                                            GameTooltip:Show()
                                        end
                                    end)
                                    bt:SetScript("OnLeave", function(self)
                                        bts.ds:Hide()
                                        GameTooltip:Hide()
                                    end)

                                    local l = bts.frame:CreateLine()
                                    l:SetColorTexture(RGB("808080", 1))
                                    l:SetStartPoint("BOTTOMLEFT", 0, 0)
                                    l:SetThickness(1)
                                    bts.line = l
                                end
                                tinsert(buttons, bts)
                            end
                        end
                    end
                end

                BG.tradeQianKuanListFrame.Text2.text:SetText(sum)

                local itemBase, lineOffset, rowWidth
                if #buttons > 5 then
                    frame.scroll.ScrollBar:Show()
                    frame.scroll:SetWidth(BG.tradeQianKuanListFrame.frame:GetWidth() - 15 - 31)
                    itemBase, lineOffset, rowWidth = 125, 0, BG.tradeQianKuanListFrame.frame:GetWidth() - 15 - 31
                else
                    frame.scroll.ScrollBar:Hide()
                    frame.scroll:SetWidth(BG.tradeQianKuanListFrame.frame:GetWidth() + 5)
                    itemBase, lineOffset, rowWidth = 145, -30, BG.tradeQianKuanListFrame.frame:GetWidth() - 25
                end
                for _, v in ipairs(buttons) do
                    v.item:SetWidth(v.hasicon and itemBase or (itemBase + v.icon:GetWidth()))
                    v.line:SetEndPoint("BOTTOMLEFT", frame.scroll:GetWidth() + lineOffset, 0)
                    v.frame:SetWidth(rowWidth)
                    v.ds:SetWidth(rowWidth)
                end
                if yes then
                    BG.tradeQianKuanListFrame.frame:Show()
                end
            end
        end

        function BG.tradeQianKuanListFrame:Reset()
            self.frame:Hide()
            self.hasItem = nil
        end

        StaticPopupDialogs["BiaoGeClearAllQianKuan"] = {
            text = L["确认清除%s的全部欠款吗？\n欠款合计：|cffFF0000%s|r"],
            button1 = L["是"],
            button2 = L["否"],
            OnAccept = function(...)
                local unit = "NPC"
                local target = BG.GN(unit)
                if not target then return end
                local class = select(2, UnitClass(unit))
                local color = select(4, GetClassColor(class))
                local FB = BG.FB1
                local maxBoss = Maxb[FB]
                for b = 1, maxBoss do
                    local maxSlot = BG.GetMaxi(FB, b)
                    local bossFrame = BG.Frame[FB]["boss" .. b]
                    for i = 1, maxSlot do
                        local maijia = bossFrame["maijia" .. i]
                        if maijia then
                            if maijia:GetText() == target and BiaoGe[FB]["boss" .. b]["qiankuan" .. i] then
                                BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = nil
                                bossFrame["qiankuan" .. i]:Hide()
                            end
                        end
                    end
                end
                BG.SendSystemMessage(format(L["已清除%s的全部欠款|cffFF0000%s|r。"],
                    "|c" .. color .. target .. RR,
                    BG.tradeQianKuanListFrame.Text2.text:GetText()))
                BG.tradeQianKuanListFrame:Update()
            end,
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }

        StaticPopupDialogs["BiaoGeTradeOverpayWarning"] = {
            text = L["|cffff0000警告：疑似你正在把欠款和装备同时交易，这会导致账单错误！|r\n\n本次交易你应让对方仅结清欠款|cffffff00%s金|r（不要摆放装备），完成后再发起新的交易给对方装备！"],
            button1 = L["知道了"],
            OnAccept = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
    end

    -- 记账效果预览
    do
        -- 预览框架
        do
            BG.tradeSeeFrame = {}
            local f = CreateFrame("Frame", nil, TradeFrame, "BackdropTemplate")
            f:SetBackdrop(BACKDROP_CHAT)
            f:SetSize(200, 150)
            f:SetPoint("BOTTOMLEFT", TradeFrame, "BOTTOMRIGHT", 1, -1)
            f:EnableMouse(true)
            f:SetToplevel(true)
            f:SetFrameLevel(TradeRecipientMoneyBg:GetFrameLevel() + 1)
            f:SetFrameStrata("HIGH")
            BG.tradeSeeFrame.frame = f

            local text = f:CreateFontString()
            text:SetPoint("TOP", f, "TOP", 0, -5)
            SetOutlineFont(text, 15)
            text:SetText(L["记账效果预览"])

            local text = f:CreateFontString()
            text:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -25)
            text:SetWidth(f:GetWidth() - 10)
            SetOutlineFont(text, 14)
            SetJustifyLeft(text)
            BG.tradeSeeFrame.text = text

            function BG.tradeSeeFrame.frame:SetNormalColor()
                ApplyPreviewColors(self, 0, 0, 0, 0.7, 0, 0, 0, 1)
            end

            function BG.tradeSeeFrame.frame:SetFalseColor()
                ApplyPreviewColors(self, 1, 0, 0, 0.2, 1, 0, 0, 1)
            end

            function BG.tradeSeeFrame.frame:SetGreenColor()
                ApplyPreviewColors(self, 0, 0, 0, 0.7, 0, 1, 0, 1)
            end

            function BG.tradeSeeFrame.frame:Reset()
                self:Hide()
                if IsTradePreviewEnabled() then
                    self:Show()
                    BG.tradeSeeFrame.CheckButton:SetChecked(true)
                    BG.tradeSeeFrame.text:SetText("")
                end
                BG.tradeSeeFrame.fakuanButton:Reset()
                BG.tradeSeeFrame.refundButton:Reset()
            end

            function BG.tradeSeeFrame.frame:Update()
                self:Hide()
                if IsTradePreviewEnabled() and not BG.IsAutoCreateBill() then
                    self:Show()
                    BG.tradeSeeFrame.fakuanButton:UpdateShow()
                    BG.tradeSeeFrame.refundButton:UpdateShow()
                    BG.tradeSeeFrame.text:SetText(BG.GetTradeSeeText())
                end
            end

            function BG.tradeSeeFrame.frame:SaveMoney()
                if BiaoGe.options["autoTrade"] == 1 and IsInRaid(1) then
                    if BG.IsAutoCreateBill() then
                        for i, v in ipairs(BG.trade.targetitems) do
                            local itemID = GetItemID(v.link)
                            BG.CancelGuanZhuAndHopeInTrade(itemID)
                        end
                    else
                        local text = BG.GetTradeSeeText("saved")
                        -- 保存打包交易
                        if #BG.trade.many > 1 then
                            local FBs = {}
                            for i, v in ipairs(BG.trade.many) do
                                FBs[v.FB] = true
                            end
                            for FB in pairs(FBs) do
                                tinsert(BiaoGe[FB].tradeTbl, BG.trade.many)
                            end
                        end
                        if BiaoGe.options["tradeNotice"] == 1 then
                            BG.FrameTradeMsg:AddMessage(text)
                        end
                    end
                end
            end

            BG.tradeSeeFrame.frame:SetNormalColor()
        end

        -- 本次交易自动记账
        do
            local bt = CreateTradePreviewCheckButton(L["本次交易自动记账"], true)
            bt:SetChecked(true)
            BG.tradeSeeFrame.CheckButton = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BG.tradeSeeFrame.fakuanButton:UpdateShow()
                BG.tradeSeeFrame.refundButton:UpdateShow()
                BG.tradeSeeFrame.frame:Update()
            end)
        end

        -- 本次交易记为罚款
        do
            local bt = CreateTradePreviewCheckButton(L["本次交易记为罚款"], false)
            BG.tradeSeeFrame.fakuanButton = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                self.isChoose = self:GetChecked()
                BG.tradeSeeFrame.frame:Update()
            end)

            function BG.tradeSeeFrame.fakuanButton:UpdateShow()
                UpdatePreviewButton(self, false)
                return
            end

            function BG.tradeSeeFrame.fakuanButton:Reset()
                ResetPreviewButton(self, true)
            end
        end

        -- 本次交易记为退货
        do
            local bt = CreateTradePreviewCheckButton(L["本次交易为退货"], false)
            BG.tradeSeeFrame.refundButton = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                self.isChoose = self:GetChecked()
                BG.tradeSeeFrame.frame:Update()
            end)

            function BG.tradeSeeFrame.refundButton:UpdateShow()
                UpdatePreviewButton(self, true)
                return
            end

            function BG.tradeSeeFrame.refundButton:Reset()
                ResetPreviewButton(self, false)
            end
        end
    end

    -- 最近拍卖
    do
        BG.tradelastAuctionFrame = {}
        local maxButtons = 10
        local buttons = {}
        local buttonGroup
        -- 主UI
        do
            local f = CreateFrame("Frame", nil, TradeFrame, "BackdropTemplate")
            f:SetBackdrop(BACKDROP_CHAT)
            f:SetBackdropColor(0, 0, 0, 0.7)
            f:SetBackdropBorderColor(0, 0, 0, 1)
            f:SetSize(BG.tradeSeeFrame.frame:GetWidth(), 110)
            f:SetPoint("BOTTOM", BG.tradeSeeFrame.frame, "TOP", 0, 1)
            f:EnableMouse(true)
            f:SetToplevel(true)
            f:SetFrameLevel(TradeRecipientMoneyBg:GetFrameLevel() + 1)
            f:SetFrameStrata("HIGH")
            f:Hide()
            BG.tradelastAuctionFrame.frame = f
            f:SetScript("OnShow", function(self)
                BG.After(0, function()
                    BG.tradelastAuctionFrame.buttonGroup:Show()
                    BG.tradelastAuctionFrame.UpdateChooseType()
                    BG.tradelastAuctionFrame.UpdateAllButtons()
                    self:RegisterEvent("BAG_UPDATE_DELAYED")
                    self:RegisterEvent("ITEM_LOCK_CHANGED")
                end)
            end)
            f:SetScript("OnHide", function(self)
                self:UnregisterAllEvents()
                BG.tradelastAuctionFrame.buttonGroup:Hide()
                for _, bt in ipairs(buttons) do
                    bt:Hide()
                end
            end)
            f:SetScript("OnEvent", function(self)
                BG.After(0.1, function()
                    BG.tradelastAuctionFrame.UpdateAllButtons()
                end)
            end)

            function BG.tradelastAuctionFrame.frame:UpdateShow()
                self:Hide()
                if IsTradePreviewEnabled() then
                    if BG.ImMLorLeader() then
                        self:Show()
                    end
                end
            end
        end

        for i = 1, maxButtons do
            local bt = CreateFrame("Button", nil, BG.tradelastAuctionFrame.frame, "BackdropTemplate")
            bt:SetBackdrop(BACKDROP_EDGE_THICK)
            bt:SetSize(35, 35)
            bt:RegisterForClicks("AnyUp")
            if i == 1 then
                bt:SetPoint("TOPLEFT", BG.tradelastAuctionFrame.frame, "TOPLEFT", 5, -30)
            elseif (i - 1) % 5 == 0 then
                bt:SetPoint("TOPLEFT", buttons[i - 5], "BOTTOMLEFT", 0, -4)
            else
                bt:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", 4, -0)
            end
            bt.icon = bt:CreateTexture(nil, "BACKGROUND", nil, 1)
            bt.icon:SetAllPoints()
            bt:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
            bt:Hide()
            tinsert(buttons, bt)

            bt.count = bt:CreateFontString()
            SetOutlineFont(bt.count, 11)
            bt.count:SetPoint("BOTTOMRIGHT", -2, 1)
            bt.count:SetTextColor(1, 1, 1)

            bt.level = bt:CreateFontString()
            SetOutlineFont(bt.level, 12.5)
            bt.level:SetPoint("BOTTOM", 0, 1)

            bt:SetScript("OnEnter", function(self)
                if BG.tradelastAuctionFrame.showType == "autoButton" then
                    BG.tradelastAuctionFrame.tooltip = {
                        red = not self.b,
                        money = self.money,
                    }
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                GameTooltip:ClearLines()
                if self.b and self.i then
                    GameTooltip:SetBagItem(self.b, self.i)
                else
                    GameTooltip:SetHyperlink(BG.SetSpecIDToLink(self.link))
                end
                BG.Show_AllHighlight(self.link)
            end)
            bt:SetScript("OnLeave", function()
                BG.tradelastAuctionFrame.tooltip = nil
                GameTooltip:Hide()
                BG.Hide_AllHighlight()
            end)
            bt:SetScript("OnClick", function(self)
                if self.b and self.i and not self.isLocked then
                    ClearCursor()
                    for i = 1, 6 do
                        if not GetTradePlayerItemInfo(i) then
                            C_Container.PickupContainerItem(self.b, self.i)
                            _G["TradePlayerItem" .. i .. "ItemButton"]:Click()
                            ClearCursor()
                            return
                        end
                    end
                end
            end)
        end

        -- 显示类型
        do
            local buttons = {}
            local numOptions = {
                { name = L["最近拍卖"], name2 = "lastButton" },
                { name = L["对方已拍"], name2 = "autoButton" },
            }
            local buttonGroup = CreateFrame("Frame", nil, BG.tradelastAuctionFrame.frame)
            buttonGroup:SetPoint("TOP", 0, -5)
            buttonGroup:SetSize(180, 20)
            BG.tradelastAuctionFrame.buttonGroup = buttonGroup
            local optionCount = #numOptions
            for i = 1, optionCount do
                local bt = CreateFrame("CheckButton", nil, buttonGroup, "UIRadioButtonTemplate")
                bt:SetPoint("LEFT", (i - 1) * buttonGroup:GetWidth() / 2 + 5, 0)
                bt:SetSize(15, 15)
                tinsert(buttons, bt)
                bt.Text = bt:CreateFontString()
                SetOutlineFont(bt.Text, 15)
                bt.Text:SetPoint("LEFT", bt, "RIGHT", 0, 0)
                bt.Text:SetText(numOptions[i].name)
                bt.Text:SetTextColor(1, .82, 0)
                bt.Text:SetWidth(75)
                SetJustifyLeft(bt.Text)
                bt:SetHitRectInsets(0, -bt.Text:GetWidth(), -5, -5)
                BG.tradelastAuctionFrame[numOptions[i].name2] = bt
                function bt:OnClick()
                    for _, radioButton in ipairs(buttons) do
                        if radioButton ~= self then
                            radioButton:SetChecked(false)
                            if radioButton:IsEnabled() then
                                radioButton.Text:SetTextColor(1, .82, 0)
                            else
                                radioButton.Text:SetTextColor(.5, .5, .5)
                            end
                        end
                    end
                    self:SetChecked(true)
                    self.Text:SetTextColor(0, 1, 0)
                    BG.tradelastAuctionFrame.showType = numOptions[i].name2
                end

                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    self:OnClick()
                    BG.tradelastAuctionFrame.UpdateAllButtons()
                end)
            end
        end

        local lastItems = {}
        local lastItemsInfo = {}
        -- 刷新最新拍卖物品
        function BG.tradelastAuctionFrame.UpdateLastButtons()
            for i, bt in ipairs(buttons) do
                bt:Hide()
            end
            wipe(lastItemsInfo)
            for ii, vv in ipairs(lastItems) do
                for b = 0, NUM_BAG_SLOTS do
                    local slotNum = C_Container.GetContainerNumSlots(b)
                    for i = 1, slotNum do
                        local info = C_Container.GetContainerItemInfo(b, i)
                        if info then
                            if BG.IsSameItem(vv.link, info.hyperlink) then
                                local notBound = not info.isBound or HasTradableTime(b, i)
                                if notBound then
                                    local _, _, _, level, _, _, _, _, _, _, _, typeID = GetItemInfo(vv.itemID)
                                    tinsert(lastItemsInfo, {
                                        link = info.hyperlink,
                                        itemID = vv.itemID,
                                        count = info.stackCount,
                                        icon = info.iconFileID,
                                        quality = info.quality,
                                        isLocked = info.isLocked,
                                        b = b,
                                        i = i,
                                        level = (typeID == 2 or typeID == 4) and level,
                                    })
                                end
                            end
                        end
                    end
                end
            end
            for i, v in ipairs(lastItemsInfo) do
                if i > maxButtons then break end
                RenderAuctionButton(buttons[i], v)
            end
        end

        -- 刷新对方已拍物品
        function BG.tradelastAuctionFrame.UpdateAutoButtons()
            for _, bt in ipairs(buttons) do
                bt:Hide()
            end
            wipe(lastItemsInfo)
            local tbl = {}
            local tradeName = BG.GN("NPC")
            if not (tradeName and BG.auctionTrade[tradeName] and next(BG.auctionTrade[tradeName])) then return end
            local auctionCount = #BG.auctionTrade[tradeName]
            for ii = 1, auctionCount do
                local vv = BG.auctionTrade[tradeName][ii]
                local link = vv.zhuangbei
                local itemID = GetItemID(link)
                local icon, typeID = select(5, GetItemInfoInstant(itemID))
                tinsert(lastItemsInfo, {
                    link = link,
                    itemID = itemID,
                    icon = icon,
                    quality = vv.quality,
                    level = (typeID == 2 or typeID == 4) and vv.itemlevel or nil,
                    money = tonumber(vv.jine) or 0,
                })

                for b = 0, NUM_BAG_SLOTS do
                    local slotNum = C_Container.GetContainerNumSlots(b)
                    for i = 1, slotNum do
                        if not tbl[b .. "-" .. i] then
                            local info = C_Container.GetContainerItemInfo(b, i)
                            if info then
                                if BG.IsSameItem(link, info.hyperlink) then
                                    local notBound = not info.isBound or HasTradableTime(b, i)
                                    if notBound then
                                        local last = lastItemsInfo[#lastItemsInfo]
                                        last.count = info.stackCount
                                        last.isLocked = info.isLocked
                                        last.b = b
                                        last.i = i
                                        tbl[b .. "-" .. i] = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if lastItemsInfo[#lastItemsInfo].b then break end
                end
            end
            for i, v in ipairs(lastItemsInfo) do
                if i > maxButtons then break end
                RenderAuctionButton(buttons[i], v, true)
            end
        end

        -- 刷新全部物品
        function BG.tradelastAuctionFrame.UpdateAllButtons()
            if BG.tradelastAuctionFrame.showType == "autoButton" then
                BG.tradelastAuctionFrame.UpdateAutoButtons()
            else
                BG.tradelastAuctionFrame.UpdateLastButtons()
            end
        end

        -- 刷新显示类型
        function BG.tradelastAuctionFrame.UpdateChooseType()
            BG.tradelastAuctionFrame.autoButton:Enable()
            BG.tradelastAuctionFrame.autoButton.Text:SetTextColor(1, .82, 0)
            local tradeName = BG.GN("NPC")
            if tradeName and BG.auctionTrade[tradeName] and next(BG.auctionTrade[tradeName]) then
                BG.tradelastAuctionFrame.autoButton:Click()
            else
                BG.tradelastAuctionFrame.lastButton:Click()
                BG.tradelastAuctionFrame.autoButton:Disable()
                BG.tradelastAuctionFrame.autoButton.Text:SetTextColor(.5, .5, .5)
            end
        end

        BG.RegisterEvent({ "CHAT_MSG_RAID_WARNING", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID" }, function(self, event, ...)
            local msg, playerName = ...
            if BG.IsSecret(msg) then return end
            local ML
            playerName = BG.GSN(playerName)
            if event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_RAID_LEADER" then
                ML = true
            elseif event == "CHAT_MSG_RAID" and playerName == BG.masterLooter then
                ML = true
            end
            if not ML then return end
            for link in msg:gmatch("|H(item:%d+:[%d-:]+)") do
                local itemID = GetItemID(link)
                for i = #lastItems, 1, -1 do
                    if lastItems[i].itemID == itemID then
                        tremove(lastItems, i)
                    end
                end
                tinsert(lastItems, 1, {
                    time = GetServerTime(),
                    itemID = itemID,
                    link = link,
                })
                for i = #lastItems, 1, -1 do
                    if #lastItems <= maxButtons then
                        break
                    end
                    tremove(lastItems, i)
                end
            end
            if BG.tradelastAuctionFrame.frame:IsVisible() and BG.tradelastAuctionFrame.showType == "lastButton" then
                BG.tradelastAuctionFrame.UpdateLastButtons()
            end
        end)

        C_Timer.NewTicker(60, function()
            local _time = GetServerTime()
            for i = #lastItems, 1, -1 do
                if _time - lastItems[i].time > 60 * 5 then
                    tremove(lastItems, i)
                end
            end
            if BG.tradelastAuctionFrame.frame:IsVisible() and BG.tradelastAuctionFrame.showType == "lastButton" then
                BG.tradelastAuctionFrame.UpdateLastButtons()
            end
        end)
    end

    -- 一键交易工资
    do
        BG.tradeFastGiveMoneyFrame = {}
        local mainFrame, frame, child, width, gzTbl, lastClick
        local givedTbl = {}
        local buttons = {}
        function BG.CreateTradeFastGiveMoneyFrame()
            if BG.tradeFastGiveMoneyFrame.frame then return end
            local f = CreateFrame("Frame", nil, TradeFrame, "BackdropTemplate")
            f:SetBackdrop(BACKDROP_CHAT)
            f:SetBackdropColor(0, 0, 0, 0.7)
            f:SetBackdropBorderColor(0, 0, 0, 1)
            f:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 1, -20)
            f:SetSize(200, 1)
            f:EnableMouse(true)
            f:SetToplevel(true)
            f:SetFrameLevel(TradeRecipientMoneyBg:GetFrameLevel() + 1)
            f:SetFrameStrata("HIGH")
            f.events = {}
            BG.tradeFastGiveMoneyFrame.frame = f
            mainFrame = f

            local text = f:CreateFontString()
            text:SetPoint("TOP", 0, -5)
            SetOutlineFont(text, 15)
            text:SetText(L["工资与补贴"])

            local bt = BG.CreateButton(f)
            bt:SetSize(50, 17)
            bt:SetPoint("TOPLEFT", 2, -3)
            bt:SetText(L["刷新"])
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BG.UpdateTradeFastGiveMoneyFrame()
            end)

            frame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            frame:SetPoint("TOPLEFT", 2.5, -22)
            frame:SetSize(195, 10)
            frame:SetBackdrop(BACKDROP_EDGE)
            frame:SetBackdropBorderColor(.5, .5, .5, .5)
            frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
            frame.scroll:SetPoint("TOPLEFT", 5, -2)
            frame.scroll:SetPoint("BOTTOMRIGHT", -5, 5)
            frame.scroll.ScrollBar.scrollStep = nil
            BG.HookScrollBarShowOrHide(frame.scroll, true)
            width = frame.scroll:GetWidth()
            child = CreateFrame("Frame", nil, frame.scroll)
            child:SetPoint("TOPLEFT")
            child:SetWidth(frame.scroll:GetWidth())
            child:SetHeight(frame.scroll:GetHeight())
            frame.scroll:SetScrollChild(child)
        end

        local function GetQianKuan()
            return tonumber(BG.tradeQianKuanListFrame.Text2.text:GetText()) or 0
        end
        function BG.TradeCopyMoney(money, name, isExpenses, isMan)
            if not StaticPopupDialogs["BiaoGe_Copy_Money"] then
                StaticPopupDialogs["BiaoGe_Copy_Money"] = {
                    text = L["按下 Ctrl+X 复制金额"],
                    button1 = OKAY,
                    hasEditBox = 1,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    OnShow = function(self, money)
                        local edit = self.EditBox or self.editBox
                        edit:SetScript("OnEditFocusLost", function()
                            self:Hide()
                        end)
                        edit:SetText(money)
                        edit:HighlightText()
                        edit:SetFocus()
                    end,
                    OnHide = function(self)
                        ChatEdit_FocusActiveWindow()
                        local edit = self.EditBox or self.editBox
                        edit:SetText("")
                    end,
                    EditBoxOnTextChanged = function(self)
                        if self:GetText() == "" then
                            self:GetParent():Hide()
                        end
                    end,
                    EditBoxOnEscapePressed = function(self)
                        self:GetParent():Hide()
                    end,
                }
            end
            StaticPopup_Show("BiaoGe_Copy_Money", nil, nil, money)
            if name then
                lastClick = nil
                if isExpenses and not isMan then
                    lastClick = {
                        money = money,
                        name = name,
                    }
                end
            end
        end

        local function CreateButton(name, money, isExpenses, hasMan)
            local ds
            local f = CreateFrame("Frame", nil, child)
            do
                f:SetSize(width, 20)
                if next(buttons) then
                    f:SetPoint("TOPLEFT", buttons[#buttons], "BOTTOMLEFT", 0, -2)
                else
                    f:SetPoint("TOPLEFT", 0, 0)
                end
                tinsert(buttons, f)
                f.ds = f:CreateTexture()
                f.ds:SetAllPoints()
                f.ds:SetColorTexture(.5, .5, .5, .3)
                f.ds:Hide()
                ds = f.ds
                f:SetScript("OnEnter", function(self)
                    ds:Show()
                end)
                f:SetScript("OnLeave", function(self)
                    if f.tradeing then return end
                    ds:Hide()
                end)
            end

            local nameFrame = CreateWageLabel(f, width, .40, f:GetHeight(), nil, name, name, givedTbl[name], f)
            local moneyFrame = CreateWageLabel(f, width, .35, nameFrame:GetHeight(), nameFrame, money, name, givedTbl[name], f)

            local bt = BG.CreateButton(f)
            do
                bt:SetSize(width * .25 - 5, nameFrame:GetHeight() - 2)
                bt:SetPoint("LEFT", moneyFrame, "RIGHT", 2, 0)
                bt:SetText(L["复制"])
                bt:RegisterForClicks("AnyUp")
                bt:SetScript("OnClick", function(self, button)
                    BG.PlaySound(1)
                    local money = money
                    local isMan
                    if button == "RightButton" and hasMan then
                        money = hasMan.avg
                        isMan = true
                    end
                    local myMoney = floor(GetMoney() / 1e4)
                    if money < 0 then
                        UIErrorsFrame:AddMessage(L["交易金额不能为负数！"], 1, 0, 0)
                    elseif myMoney >= money then
                        for _, f in pairs(buttons) do
                            f.ds:SetColorTexture(.5, .5, .5, .3)
                            f.ds:Hide()
                            f.tradeing = nil
                        end
                        ds:SetColorTexture(0, 1, 0, .5)
                        ds:Show()
                        f.tradeing = true
                        local qiankuan = GetQianKuan()
                        if qiankuan > 0 then
                            if money >= qiankuan then
                                if not StaticPopupDialogs["BIAOGE_FASTTRADE_QIANKUAN"] then
                                    StaticPopupDialogs["BIAOGE_FASTTRADE_QIANKUAN"] = {
                                        text = L["交易金额需要减去对方的总欠款吗？\n%s"],
                                        button1 = L["减去并清除欠款"],
                                        button2 = L["不减"],
                                        button3 = CANCEL,
                                        OnButton3 = function()
                                            StaticPopup_Hide("BIAOGE_FASTTRADE_QIANKUAN")
                                        end,
                                        selectCallbackByIndex = true,
                                        timeout = 0,
                                        whileDead = true,
                                        hideOnEscape = true,
                                        showAlert = true,
                                    }
                                end
                                StaticPopupDialogs["BIAOGE_FASTTRADE_QIANKUAN"].OnButton1 = function()
                                    StaticPopupDialogs["BiaoGeClearAllQianKuan"].OnAccept()
                                    BG.TradeCopyMoney(money - qiankuan, name, isExpenses, isMan)
                                end
                                StaticPopupDialogs["BIAOGE_FASTTRADE_QIANKUAN"].OnButton2 = function()
                                    BG.TradeCopyMoney(money, name, isExpenses, isMan)
                                end
                                StaticPopup_Hide("BIAOGE_FASTTRADE_QIANKUAN2")
                                StaticPopup_Show("BIAOGE_FASTTRADE_QIANKUAN",
                                    format("|cff00ff00%s|r - |cffff0000%s|r = |cffffff00%s|r", money, qiankuan, money - qiankuan))
                            else
                                if not StaticPopupDialogs["BIAOGE_FASTTRADE_QIANKUAN2"] then
                                    StaticPopupDialogs["BIAOGE_FASTTRADE_QIANKUAN2"] = {
                                        text = L["对方还有|cffff0000%s|r欠款，还继续交易对方|cffffff00%s|r？"],
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
                                StaticPopupDialogs["BIAOGE_FASTTRADE_QIANKUAN2"].OnAccept = function()
                                    BG.TradeCopyMoney(money, name, isExpenses, isMan)
                                end
                                StaticPopup_Hide("BIAOGE_FASTTRADE_QIANKUAN")
                                StaticPopup_Show("BIAOGE_FASTTRADE_QIANKUAN2", qiankuan, money)
                            end
                        else
                            BG.TradeCopyMoney(money, name, isExpenses, isMan)
                        end
                    else
                        UIErrorsFrame:AddMessage(L["你的钱不够！"], 1, 0, 0)
                    end
                end)
                bt:SetScript("OnEnter", function(self)
                    ds:Show()
                    if hasMan then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                        GameTooltip:AddLine(AddTexture("LEFT") .. self:GetText() .. money, 1, .82, 0, true)
                        GameTooltip:AddLine(AddTexture("RIGHT") .. self:GetText() .. hasMan.avg, 1, .82, 0, true)
                        GameTooltip:Show()
                    end
                end)
                bt:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    if f.tradeing then return end
                    ds:Hide()
                end)
            end

            local l = nameFrame:CreateLine()
            l:SetColorTexture(RGB("808080", 1))
            l:SetStartPoint("BOTTOMLEFT", 0, 0)
            l:SetEndPoint("BOTTOMLEFT", width, 0)
            l:SetThickness(1)
        end

        local function GetTargetTeamMember()
            local targetName = BG.GN("NPC")
            local targetTeam
            local team = {}
            for _, v in pairs(BG.raidRosterInfo) do
                if v.name ~= player then
                    team[v.subgroup] = team[v.subgroup] or 0
                    team[v.subgroup] = team[v.subgroup] + 1
                end
                if v.name == targetName then
                    targetTeam = v.subgroup
                end
            end
            return team[targetTeam] or 0
        end
        local function GetLeaderIcon(player)
            local icon = ""
            for i, v in ipairs(BG.raidRosterInfo) do
                if v.name == player then
                    if v.rank == 2 then
                        icon = icon .. AddTexture("interface/groupframe/ui-group-leadericon")
                    elseif v.isML then
                        icon = icon .. AddTexture("interface/groupframe/ui-group-masterlooter")
                    end
                    break
                end
            end
            return icon
        end
        function BG.UpdateTradeFastGiveMoneyFrame()
            if BG.tradeFastGiveMoneyFrame.frame then
                BG.tradeFastGiveMoneyFrame.frame:Hide()
            end
            if IsTradePreviewEnabled() then
                BG.CreateTradeFastGiveMoneyFrame()
                mainFrame:Show()
                if BG.ImMLorLeader() then
                    mainFrame:ClearAllPoints()
                    mainFrame:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 1, 1)
                    local w1 = mainFrame:GetTop()
                    if w1 then
                        local w2 = BG.tradelastAuctionFrame.frame:GetTop()
                        mainFrame:SetHeight(w1 - w2 - 0 - 1)
                        frame:SetHeight(mainFrame:GetHeight() - 25)
                    end
                else
                    if gzTbl and BG.IsMLByName(gzTbl.player) then
                        mainFrame:ClearAllPoints()
                        if BG.IsAutoCreateBill() then
                            mainFrame:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 1, 1)
                        else
                            mainFrame:SetPoint("BOTTOMLEFT", BG.tradeSeeFrame.frame, "TOPLEFT", 0, 1)
                        end
                        mainFrame:SetHeight(100)
                        frame:SetHeight(mainFrame:GetHeight() - 25)
                    else
                        mainFrame:Hide()
                    end
                end

                StaticPopup_Hide("BIAOGE_FASTTRADE_QIANKUAN")
                StaticPopup_Hide("BIAOGE_FASTTRADE_QIANKUAN2")
                lastClick = nil
                for _, bt in pairs(buttons) do
                    bt:Hide()
                end
                wipe(buttons)
                local FB = BG.FB1

                if BG.ImMLorLeader() then
                    local money = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. 5]:GetText()) or 0
                    local targetTeamMember = GetTargetTeamMember()
                    CreateButton(L["单人工资"], money)
                    CreateButton(format(L["%s人工资"], targetTeamMember), money * targetTeamMember)
                    local i = 1
                    while BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i] do
                        local item = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i]:GetText()
                        local hasMan = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i].hasMan
                        local money = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i]:GetText())
                        if item ~= "" and money and money ~= 0 then
                            CreateButton(item, money, true, hasMan)
                        end
                        i = i + 1
                    end
                else
                    if gzTbl and BG.IsMLByName(gzTbl.player) then
                        CreateButton(L["单人工资"], gzTbl.money)
                        local parent = buttons[1]
                        local t = parent:CreateFontString()
                        SetOutlineFont(t, 13)
                        t:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -5)
                        t:SetTextColor(.5, .5, .5)
                        t:SetWidth(parent:GetWidth() - 2)
                        SetJustifyLeft(t)
                        local time = GetServerTime() - gzTbl.time
                        t:SetText(format(L["数据来源：\n|cffffffff%s秒|r前%s通报的账单"], time, GetLeaderIcon(gzTbl.player) .. gzTbl.colorplayer))
                    end
                end
            end
        end

        -- 记录团长通报的工资
        local expireFrame = CreateFrame("Frame")
        BG.RegisterEvent({ "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID" }, function(self, event, msg, sender, ...)
            if BG.IsSecret(msg) then return end
            sender = BG.GSN(sender)
            if not BG.IsMLByName(sender) then return end
            local gz = msg:match("^人均工资：(%d+)")
            if not gz then
                gz = msg:match("^人均薪水：(%d+)")
            end
            if not gz then
                gz = msg:match("^Wages per capita:(%d+)")
            end
            if gz then
                gzTbl = {
                    player = sender,
                    colorplayer = SetClassCFF(sender),
                    money = tonumber(gz),
                    time = GetServerTime(),
                }
                -- x分钟后删除记录
                expireFrame.t = 0
                expireFrame:SetScript("OnUpdate", function(_, t)
                    expireFrame.t = expireFrame.t + t
                    if expireFrame.t >= 60 * 10 then
                        gzTbl = nil
                        expireFrame:SetScript("OnUpdate", nil)
                    end
                end)
            end
        end)

        BG.RegisterEvent("TRADE_CLOSED", function(self, ...)
            StaticPopup_Hide("BIAOGE_FASTTRADE_QIANKUAN")
            StaticPopup_Hide("BIAOGE_FASTTRADE_QIANKUAN2")
            StaticPopup_Hide("BiaoGe_Copy_Money")
        end)

        -- 把已经交易成功的补贴记下来
        function T.SaveTradeFastGiveMoney()
            if BiaoGe.options["autoTrade"] == 1 and IsInRaid(1) and lastClick then
                if lastClick.money == BG.trade.playermoney then
                    local name = lastClick.name
                    givedTbl[name] = { time = time() }
                    -- x分钟后删除记录
                    BG.After(60 * 5, function()
                        if givedTbl[name] then
                            if time() - givedTbl[name].time >= 60 * 5 then
                                givedTbl[name] = nil
                            end
                        end
                    end)
                end
            end
        end
    end

    -- 交易通知框架
    do
        local name = "tradeTime"
        BG.options[name .. "reset"] = 3
        local f = CreateFrame("ScrollingMessageFrame", "BG.FrameTradeMsg", UIParent, "BackdropTemplate")
        f:SetSpacing(1)                                                       -- 行间隔
        f:SetFadeDuration(1)                                                  -- 淡出动画的时间
        f:SetTimeVisible(BiaoGe.options[name] or BG.options[name .. "reset"]) -- 可见时间
        SetJustifyLeft(f)                                                 -- 对齐格式
        f:SetSize(350, 150)                                                   -- 大小
        SetOutlineFont(f, BiaoGe.options["tradeFontSize"] or 20)
        f:SetFrameLevel(131)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetClampedToScreen(true)
        f:SetHyperlinksEnabled(true)
        f.homepoin = { "BOTTOM", nil, "CENTER", 50, 100 }
        if BiaoGe.point[f:GetName()] then
            BiaoGe.point[f:GetName()][2] = nil
            f:SetPoint(unpack(BiaoGe.point[f:GetName()]))
        else
            f:SetPoint(unpack(f.homepoin)) --设置显示位置
        end
        tinsert(BG.Movetable, f)
        BG.FrameTradeMsg = f

        f.name = f:CreateFontString()
        SetOutlineFont(f.name, 15)
        f.name:SetTextColor(1, 1, 1, 1)
        f.name:SetText(L["交易通知"])
        f.name:SetPoint("TOP", 0, -5)
        f.name:Hide()

        f:SetScript("OnHyperlinkEnter", function(self, link, text, button)
            local itemID = GetItemInfoInstant(link)
            if itemID then
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
            end
        end)
        f:SetScript("OnHyperlinkLeave", function(self, link, text, button)
            GameTooltip:Hide()
        end)
        f:SetScript("OnHyperlinkClick", function(self, link, text, button)
            if IsShiftKeyDown() then
                BG.InsertLink(text)
            end
        end)
    end

    -- 自动摆放装备
    do
        BG.tradeAutoPickItem = {}

        BG.tradeUpdateFrame = CreateFrame("Frame")

        -- 创建应收/应付对象
        do
            local f = CreateFrame("Frame", nil, TradeFrame)
            f:SetFrameStrata("HIGH")
            local text = f:CreateFontString()
            text:SetPoint("TOPRIGHT", TradeRecipientMoneyBg, "BOTTOMRIGHT", -5, 3)
            SetOutlineFont(text, 14)
            BG.trade.GiveMeMoneyText = text

            local f = CreateFrame("Frame", nil, TradeFrame)
            f:SetFrameStrata("HIGH")
            local text = f:CreateFontString()
            text:SetPoint("TOPLEFT", TradePlayerInputMoneyInsetBg, "BOTTOMLEFT", 0, 3)
            SetOutlineFont(text, 14)
            BG.trade.GiveYouMoneyText = text

            for i = 1, 6 do
                local itemButton = _G["TradePlayerItem" .. i .. "ItemButton"]
                local text = itemButton:CreateFontString()
                text:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 8, -2)
                SetOutlineFont(text, 12)
                SetJustifyLeft(text)
                -- text:SetWidth(_G["TradePlayerItem" .. i .. "Name"]:GetWidth())
                text:SetWidth(120)
                text:Hide()
                itemButton.moneyText = text

                local itemButton = _G["TradeRecipientItem" .. i .. "ItemButton"]
                local text = itemButton:CreateFontString()
                text:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 8, -2)
                SetOutlineFont(text, 12)
                SetJustifyLeft(text)
                -- text:SetWidth(_G["TradeRecipientItem" .. i .. "Name"]:GetWidth())
                text:SetWidth(120)
                text:Hide()
                itemButton.moneyText = text
            end
        end

        local sumTargetMoney = 0
        local sumPlayerMoney = 0

        -- 自动拍卖时逐件装备分别记账，不合并成一笔
        BG.trade.autoAuction = {}
        function BG.TradeIsAutoAuction()
            local FB = BG.FB1
            CollectAutoAuction(sumTargetMoney, sumPlayerMoney)
            -- 核对表格里能否为它们全部找到合适的格子
            local same = {}
            for _, v in ipairs(BG.trade.autoAuction) do
                local done
                local maxBoss = Maxb[FB]
                for b = 1, maxBoss do
                    local maxSlot = BG.GetMaxi(FB, b)
                    local bossFrame = BG.Frame[FB]["boss" .. b]
                    for i = 1, maxSlot do
                        if not same[b .. "-" .. i] then
                            local bt = bossFrame["zhuangbei" .. i]
                            if bt and BG.IsSameItem(bt:GetText(), v.link) and
                                bossFrame["maijia" .. i]:GetText() == "" and
                                bossFrame["jine" .. i]:GetText() == "" and
                                not BiaoGe[FB]["boss" .. b]["qiankuan" .. i]
                            then
                                v.b = b
                                v.i = i
                                done = true
                                same[b .. "-" .. i] = true
                                break
                            end
                        end
                    end
                    if done then break end
                end
                if not done then
                    wipe(BG.trade.autoAuction)
                    return
                end
            end
        end

        local function UpdateTargetQianKuan()
            UpdateTradeQianKuan(GetTargetTradeMoney, sumTargetMoney)
            return
        end
        local function UpdateMyQianKuan()
            UpdateTradeQianKuan(GetPlayerTradeMoney, sumPlayerMoney)
            return
        end
        local function GetSumTargetMoney() return sumTargetMoney end
        local function GetSumPlayerMoney() return sumPlayerMoney end
        local function MLAcceptTrade()
            AcceptTradeWhenReady(GetTargetTradeMoney, GetSumTargetMoney)
            return
        end
        local function PlayerAcceptTrade()
            AcceptTradeWhenReady(GetPlayerTradeMoney, GetSumPlayerMoney, true)
            return
        end

        local function UpdateGiveMeMoneyTextColor()
            UpdateMoneyTextColor(GetTargetTradeMoney, sumTargetMoney, BG.trade.GiveMeMoneyText, "TradePlayerItem", true, 1, 0, 0)
        end
        local function UpdateGiveYouMoneyTextColor()
            UpdateMoneyTextColor(GetPlayerTradeMoney, sumPlayerMoney, BG.trade.GiveYouMoneyText, "TradeRecipientItem", false)
        end
        function BG.ResetAuctionTradeMoneyText()
            BG.tradeCopyMoneyButton:Hide()
            BG.trade.GiveMeMoneyText:Hide()
            BG.trade.GiveYouMoneyText:Hide()
            for i = 1, 6 do
                _G["TradePlayerItem" .. i .. "ItemButton"].moneyText:Hide()
                _G["TradePlayerItem" .. i .. "ItemButton"].moneyText.money = 0
                _G["TradeRecipientItem" .. i .. "ItemButton"].moneyText:Hide()
                _G["TradeRecipientItem" .. i .. "ItemButton"].moneyText.money = 0
            end
        end

        local function CheckItemIsNotAutoAuction()
            for _, v in ipairs({ { fuc = GetTradePlayerItemInfo, btName = "TradePlayerItem" },
                { fuc = GetTradeTargetItemInfo, btName = "TradeRecipientItem" }, }) do
                for i = 1, 6 do
                    if v.fuc(i) then
                        local bt = _G[v.btName .. i .. "ItemButton"]
                        if not bt.moneyText:IsVisible() then
                            bt.moneyText:Show()
                            bt.moneyText:SetText(L["|cffff0000错误：不要把该装备放在一起交易"])
                        end
                    end
                end
            end
        end
        local function FormatMoney(money)
            -- GetMoneyString(tonumber(sumTargetMoney .. "0000"))
            return BG.FormatNumber(money, 2)
        end

        -- 团长自动摆放装备
        local function StartGiveItem(tradeName)
            ClearCursor()
            local bagTbl = {}
            local tradeTbl = {}
            local function GiveItem(index)
                if not TradeFrame:IsVisible() then return end
                local v = BG.auctionTrade[tradeName][index]
                if not v then return end
                for b = 0, NUM_BAG_SLOTS do
                    local slotNum = C_Container.GetContainerNumSlots(b)
                    for i = 1, slotNum do
                        if not bagTbl[b .. "-" .. i] then
                            local info = C_Container.GetContainerItemInfo(b, i)
                            if info then
                                if BG.IsSameItem(v.zhuangbei, info.hyperlink) and not info.isLocked then
                                    local notBound = not info.isBound or HasTradableTime(b, i)
                                    if notBound then
                                        for ii = 1, 6 do
                                            if not tradeTbl[ii] then
                                                if not GetTradePlayerItemInfo(ii) then
                                                    C_Container.PickupContainerItem(b, i)
                                                    _G["TradePlayerItem" .. ii .. "ItemButton"]:Click()
                                                    ClearCursor()
                                                    bagTbl[b .. "-" .. i] = true
                                                    tradeTbl[ii] = true
                                                    BG.After(0.02, function()
                                                        GiveItem(index + 1)
                                                    end)
                                                    return
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                GiveItem(index + 1)
            end
            GiveItem(1)
        end
        local function IsNoItem()
            for ii = 1, 6 do
                if GetTradePlayerItemInfo(ii) then
                    return false
                end
            end
            return true
        end
        function BG.tradeAutoPickItem:Start()
            sumTargetMoney = 0
            sumPlayerMoney = 0
            BG.ResetAuctionTradeMoneyText()
            if not IsInRaid(1) then return end
            if BiaoGe.options["autoAuctionPut"] ~= 1 then return end
            if not BG.ImMLorLeader() then return end
            local tradeName = BG.GN("NPC")
            if not (BG.auctionTrade[tradeName] and next(BG.auctionTrade[tradeName])) then return end
            StartGiveItem(tradeName)
            BG.After(0.5, function()
                if TradeFrame:IsVisible() and BG.GN("NPC") == tradeName and IsNoItem() then
                    StartGiveItem(tradeName)
                end
            end)
        end

        -- 团长
        BG.RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", function(self, ...)
            sumTargetMoney = 0
            BG.ResetAuctionTradeMoneyText()
            if not IsInRaid(1) then return end
            if not BG.ImMLorLeader() then return end
            local tradeName = BG.GN("NPC")
            if not (BG.auctionTrade[tradeName] and next(BG.auctionTrade[tradeName])) then return end
            sumTargetMoney = SumTradeSide(GetTradePlayerItemLink, tradeName, 0, L["应收："], "TradePlayerItem", FormatMoney)
            ShowTradeSideMoney(BG.trade.GiveMeMoneyText, sumTargetMoney, L["合计应收："], false,
                FormatMoney, UpdateGiveMeMoneyTextColor, CheckItemIsNotAutoAuction)
            UpdateTargetQianKuan()
        end)

        -- 团员
        BG.RegisterEvent("TRADE_TARGET_ITEM_CHANGED", function(self, ...)
            sumPlayerMoney = 0
            BG.ResetAuctionTradeMoneyText()
            if not IsInRaid(1) then return end
            if BG.ImMLorLeader() then return end
            local tradeName = player
            if not (BG.auctionTrade[tradeName] and next(BG.auctionTrade[tradeName])) then return end
            sumPlayerMoney = SumTradeSide(GetTradeTargetItemLink, tradeName, 0, L["应付："], "TradeRecipientItem", FormatMoney)
            ShowTradeSideMoney(BG.trade.GiveYouMoneyText, sumPlayerMoney, L["合计应付："], true,
                FormatMoney, UpdateGiveYouMoneyTextColor, CheckItemIsNotAutoAuction)
            UpdateMyQianKuan()
        end)

        BG.RegisterEvent("TRADE_MONEY_CHANGED", function(self, ...)
            if not IsInRaid(1) then return end
            if not BG.ImMLorLeader() then return end
            if BG.trade.GiveMeMoneyText:IsVisible() then
                UpdateGiveMeMoneyTextColor()
            end
            UpdateTargetQianKuan()
            MLAcceptTrade()
        end)

        function BG.tradeAutoPickItem.TradeMyMoneyChange()
            if not IsInRaid(1) then return end
            if not TradeFrame:IsVisible() then return end
            if BG.ImMLorLeader() then return end
            if BG.trade.GiveYouMoneyText:IsVisible() then
                UpdateGiveYouMoneyTextColor()
            end
            UpdateMyQianKuan()
            PlayerAcceptTrade()
        end

        -- 交易完成后将对应拍卖记录标为已交易
        function T.SetItemTradeState()
            local FB = BG.FB2 or BG.FB1
            if IsInRaid(1) and BiaoGe[FB].auctionLog then
                local tradeName, tradeTbl
                if BG.ImMLorLeader() then
                    tradeName = BG.trade.target
                    tradeTbl = BG.trade.playeritems
                else
                    tradeName = BG.trade.player
                    tradeTbl = BG.trade.targetitems
                end
                local logRows = BiaoGe[FB].auctionLog
                for _, vv in ipairs(tradeTbl) do
                    local tradeLinkID = GetItemID(vv.link)
                    for _, v in ipairs(logRows) do
                        if v.type == 1 and not v.trade and v.maijia == tradeName and
                            GetItemID(v.zhuangbei) == tradeLinkID then
                            v.trade = true
                            break
                        end
                    end
                end
                BG.UpdateAuctionLogFrame(true, true)
            end
        end
    end

    -- 复制应付金额
    do
        local bt = BG.CreateButton(TradeFrame)
        bt:SetSize(110, 20)
        bt:SetPoint("BOTTOMLEFT", TradePlayerInputMoneyInsetBg, "TOPLEFT", 0, 2)
        bt:SetFrameLevel(TradeRecipientMoneyBg:GetFrameLevel() + 15)
        bt:SetText(L["复制应付金额"])
        bt:Hide()
        BG.tradeCopyMoneyButton = bt
        bt:SetScript("OnClick", function(self)
            BG.TradeCopyMoney(self.money)
        end)
        function BG.tradeCopyMoneyButton:ShowButton(money)
            if not (IsAutoAuctionMoneyEnabled() and BiaoGe.options["autoAuctionSetMoney"] == 1) then return end
            self.money = money
            self:Show()
        end

        -- 在确认对话框底部再加一个勾选项
        local wh = "BiaoGe_Copy_Money"
        local bt = CreateFrame("CheckButton", nil, UIParent, "ChatConfigCheckButtonTemplate")
        bt:SetSize(30, 30)
        SetOutlineFont(bt.Text, 15)
        bt.Text:SetText(L["自动弹出复制应付金额窗口"])
        bt:SetHitRectInsets(0, 0, 0, 0)
        bt:Hide()
        bt.name = "autoShowTradeCopyMoney"
        bt:SetChecked(BiaoGe.options["autoShowTradeCopyMoney"] == 1)
        bt:SetScript("OnShow", function(self)
            bt:SetChecked(BiaoGe.options["autoShowTradeCopyMoney"] == 1)
        end)
        bt:SetScript("OnClick", function(self)
            BiaoGe.options["autoShowTradeCopyMoney"] = self:GetChecked() and 1 or 0
            if not self:GetChecked() then
                StaticPopup_Hide(wh)
            end
            BG.PlaySound(1)
        end)

        function BG.ShowAutoShowTradeCopyMoneyButton()
            local _, dialog = StaticPopup_Visible(wh)
            if dialog then
                bt:ClearAllPoints()
                bt:SetPoint("TOPLEFT", dialog, "BOTTOMLEFT", 0, 0)
                bt:SetParent(dialog)
                bt.Text:SetWidth(StaticPopup1:GetWidth() - 50)
                bt:Show()
                if not dialog.BiaoGe_Copy_Money_HookHide then
                    dialog.BiaoGe_Copy_Money_HookHide = true
                    dialog:HookScript("OnHide", function()
                        if bt:GetParent() == dialog then
                            bt:Hide()
                        end
                    end)
                end
            end
        end
    end

    -- 交易状态变化时
    do
        function BG.TradeUpdate()
            if not TradeFrame:IsVisible() then return end
            BG.GetTradeInfo()
            BG.tradeSeeFrame.frame:Update()
            BG.tradeSameMoney:Update()
            BG.tradeGoldTop:Update()
            BG.tradeAutoPickItem.TradeMyMoneyChange()
        end

        hooksecurefunc(C_TradeInfo, "SetTradeMoney", function(money)
            BG.After(0, BG.TradeUpdate)
        end)

        BG.RegisterEvent({ "TRADE_PLAYER_ITEM_CHANGED", "TRADE_TARGET_ITEM_CHANGED", "TRADE_MONEY_CHANGED" }, function()
            BG.After(0, BG.TradeUpdate)
        end)
    end

    -- 交易开始
    BG.RegisterEvent("TRADE_SHOW", function(self, ...)
        if BiaoGe.options.autoTrade == 1 and BiaoGe.options.tradePreview == 1 then
            FlashClientIcon()
        end
        BG.trade.showedOverpayWarning = nil
        BG.GetTargetAuctionTradeItems(BG.ImMLorLeader() and BG.GN("NPC") or player)
        BG.ResetAuctionTradeMoneyText()
        BG.ResetTradeInfo()
        BG.tradeQianKuanEdit:Update()
        BG.tradeGoldTop:Update()
        BG.tradeSameMoney:Update()

        BG.tradeQianKuanListFrame:Reset()
        BG.tradeQianKuanListFrame:Update()

        BG.tradeSeeFrame.frame:Reset()
        BG.tradelastAuctionFrame.frame:UpdateShow()
        BG.UpdateTradeFastGiveMoneyFrame()

        BG.tradeAutoPickItem:Start()
    end)

    -- 交易完成
    BG.RegisterEvent("UI_INFO_MESSAGE", function(self, event, _, text)
        if text == ERR_TRADE_COMPLETE then
            BG.tradeSameMoney:SaveTradeMoney()
            BG.tradeSeeFrame.frame:SaveMoney()

            T.SetItemTradeState()
            T.SaveTradeFastGiveMoney()
        end
    end)
end)

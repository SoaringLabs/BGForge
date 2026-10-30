if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local L = ns.L

local GetClassRGB = ns.GetClassRGB
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod

local Maxb = ns.Maxb

local player = BG.playerName

local r, g, b = GetClassRGB(nil, "player")

local CURRENCY_ITEM_IDS = {
    [247796] = 395,
    [256883] = 395,
    [248329] = 3350,
    [266272] = 3414,
}

local function InstallSecureHook(target, name, callback)
    if target then
        hooksecurefunc(target, name, callback)
    else
        hooksecurefunc(name, callback)
    end
end

local function InstallTooltipHook(enumKey, eventName, callback)
    if BG.IsRetail then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType[enumKey], callback)
    else
        GameTooltip:HookScript(eventName, callback)
    end
end

local function RunAll(funcs, ...)
    for _, callback in ipairs(funcs) do
        callback(...)
    end
end

local function FormatAuctionMoney(record)
    return BG.FormatNumber(record.jine, 2) .. "(|c" .. select(4, GetClassColor(record.class)) .. record.maijia .. "|r)"
end

local function AddAuctionLines(self, records, label, red, green, blue)
    for _, record in ipairs(records) do
        self:AddDoubleLine(label, FormatAuctionMoney(record), red, green, blue)
    end
end

local function HookChatFrameHyperlinks()
    local index = 1
    while _G["ChatFrame" .. index] do
        local chatFrame = _G["ChatFrame" .. index]
        chatFrame:HookScript("OnHyperlinkEnter", function(_, link)
            BG.Show_AllHighlight(link, "chat")
        end)
        chatFrame:HookScript("OnHyperlinkLeave", BG.Hide_AllHighlight)
        index = index + 1
    end
end

local function HookBagnonContainerHooks()
    local handler = ContainerFrameItemButton_OnLeave
    if BG.IsRetail then
        handler = GameTooltip_Hide
    end
    local index = 1
    while _G["BagnonContainerItem" .. index] do
        _G["BagnonContainerItem" .. index]:HookScript("OnLeave", handler)
        index = index + 1
    end
end

local function CreateBagHighlightDriver()
    local link
    local dalayFrame = CreateFrame("Frame")
    dalayFrame.t = 0
    dalayFrame:Hide()
    local function OnUpdate(self, t)
        self.t = self.t + t
        if self.t >= .1 then
            self:Hide()
            if link then
                BG.Show_AllHighlight(link, "bag")
            end
        end
    end
    local function OnHide()
        dalayFrame:Hide()
        BG.Hide_AllHighlight()
    end
    dalayFrame:SetScript('OnUpdate', OnUpdate)

    local function OnEnter(self, button)
        local b = self:GetParent():GetID()
        local i = self:GetID()
        link = C_Container.GetContainerItemLink(b, i)
        dalayFrame.t = 0
        dalayFrame:Show()
    end
    return OnEnter, OnHide
end

BG.Init2(function()
    local itemFucs = {}
    local unitFucs = {}
    -- 单位
    do
        -- 悬停玩家时展示其欠款与罚款
        do
            local fk = {}
            local qk = {}
            local function Get()
                if not IsInRaid(1) then return end
                local FB = BG.FB1
                fk = {}
                qk = {}
                BG.PairFBItem(function(item, buyer, money, b, i)
                    local name = buyer:GetText()
                    if name == '' then return end
                    fk[name] = fk[name] or 0
                    qk[name] = qk[name] or 0
                    if b == Maxb[FB] then
                        fk[name] = fk[name] + (tonumber(money:GetText()) or 0)
                    end
                    qk[name] = qk[name] + (tonumber(BiaoGe[FB]["boss" .. b]["qiankuan" .. i]) or 0)
                end)
            end
            C_Timer.NewTicker(2, Get)

            local function AddUnitInfo(self, unit, name)
                if BiaoGe.options["mouseFK"] ~= 1 then return end
                if not IsInRaid(1) then return end
                local fkMoney = fk[name] or 0
                local qkMoney = qk[name] or 0
                if fkMoney == 0 and qkMoney == 0 then return end
                if fkMoney ~= 0 then
                    self:AddLine(L["罚款："] .. BG.STC_w1(BG.FormatNumber(fkMoney, 2)), 1, .82, 0)
                end
                if qkMoney ~= 0 then
                    self:AddLine(L["欠款："] .. BG.STC_w1(BG.FormatNumber(qkMoney, 2)), 1, .82, 0)
                end
                self:Show()
            end
            tinsert(unitFucs, AddUnitInfo)
        end

        -- 星团长
        if BG.MeetingHornRegimentData then
            local function AddUnitInfo(self, unit, name)
                if BiaoGe.options["MeetingHorn_starRaidLeader"] ~= 1 then return end
                local currentLevel = BG.MeetingHornRegimentData[name]
                if not currentLevel then return end
                currentLevel = currentLevel.level
                local nextText = _G["GameTooltipTextLeft1"]
                local str = nextText:GetText() or ''
                nextText:SetFormattedText('%s|T%s%s|t', str, BG.MeetingHornStarTexture(currentLevel), BG.MeetingHornGetCoords("tooltip"))
                self:Show()
            end
            tinsert(unitFucs, AddUnitInfo)
        end
    end

    -- 物品
    do
        -- MOP版本中，正义奖章与一袋岩石碎片会显示正义点数的数量
        if BG.IsMOP then
            local function AddInfo(self, itemID, link, name)
                if BiaoGe.options["showCurrencyCount"] ~= 1 then return end
                local currency = CURRENCY_ITEM_IDS[itemID]
                if not currency then return end
                local info = C_CurrencyInfo.GetCurrencyInfo(currency)
                local currencyName = info.name
                local count = info.quantity
                local maxCount = info.maxQuantity
                local tex = info.iconFileID
                local quality = info.quality
                local r, g, b = GetItemQualityColor(quality)
                self:AddLine(" ")
                self:AddLine("< BGForge >", 0, .75, 1)
                if info.useTotalEarnedForMaxQty then
                    local totalEarned = info.totalEarned
                    self:AddDoubleLine(AddTexture(tex) .. currencyName,
                        format(L["%s(总上限:%s/%s)"], count, BG.FormatNumber(totalEarned), BG.FormatNumber(maxCount)), r, g, b, 1, 1, 1)
                else
                    self:AddDoubleLine(AddTexture(tex) .. currencyName, BG.FormatNumber(count) .. "/" .. BG.FormatNumber(maxCount), r, g, b, 1, 1, 1)
                end
                self:Show()
            end
            tinsert(itemFucs, AddInfo)
        end

        -- 背包提示已拍未交易
        local function SetBagItem(self, b, i)
            if not BG.ImMLorLeader() then return end
            local info = C_Container.GetContainerItemInfo(b, i)
            if not info then return end
            local FB = BG.FB1
            if type(BiaoGe[FB].auctionLog) ~= "table" then return end
            local notBound
            if not info.isBound then
                notBound = true
            else
                for lineIndex = 1, self:NumLines() do
                    local tx = _G["GameTooltipTextLeft" .. lineIndex]:GetText()
                    if tx then
                        local time = tx:match(BIND_TRADE_TIME_REMAINING:gsub("%%s", "(.+)"))
                        if time then
                            notBound = true
                            break
                        end
                    end
                end
            end
            if not notBound then return end
            local trade = {}
            local notrade = {}
            for _, record in pairs(BiaoGe[FB].auctionLog) do
                if record.type == 1 and BG.IsSameItem(info.hyperlink, record.zhuangbei) then
                    tinsert(record.trade and trade or notrade, record)
                end
            end
            if not (next(trade) or next(notrade)) then return end
            self:AddLine(" ")
            AddAuctionLines(self, trade, L["已拍已交易"], 0, 1, 0)
            AddAuctionLines(self, notrade, L["已拍未交易"], 1, 0, 0)
            self:Show()
        end
        InstallSecureHook(GameTooltip, "SetBagItem", SetBagItem)

        -- 在表格和背包里高亮与之对应的物品
        do
            HookChatFrameHyperlinks()

            if IsAddOnLoaded("Bagnon") then
                BG.After(1, HookBagnonContainerHooks)
            end

            local OnEnter, OnHide = CreateBagHighlightDriver()
            InstallSecureHook(nil, "ContainerFrameItemButton_OnEnter", OnEnter)
            if BG.IsRetail then
                InstallSecureHook(nil, "GameTooltip_Hide", OnHide)
            else
                InstallSecureHook(nil, "ContainerFrameItemButton_OnLeave", OnHide)
            end
        end
    end

    -- 执行
    do
        local function UnitGo(self)
            if InCombatLockdown() then return end
            if BG.InBoss() then return end
            local _, unit = self:GetUnit()
            if BG.IsSecret(unit) then return end
            if not unit or not UnitIsPlayer(unit) then return end
            RunAll(unitFucs, self, unit, BG.GN(unit))
        end
        InstallTooltipHook("Unit", "OnTooltipSetUnit", UnitGo)

        local function ItemGo(self)
            if self ~= GameTooltip  then return end
            local name, link = self:GetItem()
            if not link then return end
            local itemID = GetItemID(link)
            if not itemID then return end
            RunAll(itemFucs, self, BG.GetLeiTingItem(itemID), link, name)
        end
        InstallTooltipHook("Item", "OnTooltipSetItem", ItemGo)
    end
end)

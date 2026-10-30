if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local L = ns.L

local GetClassRGB = ns.GetClassRGB


local player = BG.playerName

local myClassFileName = select(2, UnitClass('player'))
local r, g, b = GetClassRGB(nil, "player")

local ZUG_SET_GROUPS = {
    { 19865, 19866, },   -- [哈卡莱战刃]
    { 268051, 268050, }, -- [哈卡封印]
    { 19912, 19873, },   -- [督军的玛瑙指环]
    { 19896, 19910, },   -- [娅尔罗之握]
    { 19925, 19898, },   -- [巨魔族长徽记]
    { 19920, 19863, },   -- [始祖徽记]
    { 19905, 19893, },   -- [赞吉尔的徽记]
    { 18203, 18202, 18204, },
}

local ZUG_SWITCH_GROUPS = {
    { 34406, 34342, },
    { 34405, 34339, },
    { 34386, 34170, },
    { 34399, 34233, },
    { 34393, 34202, },
    { 34397, 34211, },
    { 34392, 34195, },
    { 34408, 34234, },
    { 34385, 34188, },
    { 34404, 34244, },
    { 34384, 34169, },
    { 34403, 34245, },
    { 34391, 34209, },
    { 34407, 34351, },
    { 34398, 34212, },
    { 34409, 34350, },
    { 34383, 34186, },
    { 34402, 34332, },
    { 34390, 34208, },
    { 34396, 34229, },
    { 34395, 34216, },
    { 34389, 34193, },
    { 34388, 34192, },
    { 34394, 34215, },
    { 34400, 34345, },
    { 34381, 34180, },
    { 34401, 34243, },
    { 34382, 34167, },
}

local INV_SLOT_ROWS = {
    { 'INVTYPE_HEAD', 1, 1 },
    { 'INVTYPE_NECK', 2, 2 },
    { 'INVTYPE_SHOULDER', 3, 3 },
    { 'INVTYPE_BODY', 4, 4 },
    { 'INVTYPE_CHEST', 5, 5 },
    { 'INVTYPE_WAIST', 6, 6 },
    { 'INVTYPE_LEGS', 7, 7 },
    { 'INVTYPE_FEET', 8, 8 },
    { 'INVTYPE_WRIST', 9, 9 },
    { 'INVTYPE_HAND', 10, 10 },
    { 'INVTYPE_SHIELD', 17, 17 },
    { 'INVTYPE_RANGED', 16, 18 },
    { 'INVTYPE_CLOAK', 15, 15 },
    { 'INVTYPE_2HWEAPON', 16, 16 },
    { 'INVTYPE_TABARD', 19, 19 },
    { 'INVTYPE_ROBE', 5, 5 },
    { 'INVTYPE_WEAPONMAINHAND', 16, 16 },
    { 'INVTYPE_WEAPONOFFHAND', 16, 17 },
    { 'INVTYPE_HOLDABLE', 17, 17 },
    { 'INVTYPE_THROWN', 16, 18 },
    { 'INVTYPE_RANGEDRIGHT', 16, 18 },
    { 'INVTYPE_WEAPON', 16, 16 },
}

local TOOLTIP_ANCHORS = {
    ['LEFT'] = { 'TOPRIGHT', 'TOPLEFT' },
    ['RIGHT'] = { 'TOPLEFT', 'TOPRIGHT' },
}

local ITEM_LEVEL_TEXT = L['|cffFFD100物品等级%s|r\n']
local EXCHANGE_SET_TITLE = L['|cff808080套装里的其他装备|r\n']
local EXCHANGE_SWITCH_TITLE = L['|cff808080可换成此装备|r\n']
local EXCHANGE_DEFAULT_TITLE = L['|cff808080兑换后的装备|r\n']

local itemSets = {}
local switchItems = {}

local EXCHANGE_SOURCES = {
    { map = itemSets, title = EXCHANGE_SET_TITLE },
    { map = switchItems, title = EXCHANGE_SWITCH_TITLE },
}

local function AddTooltipText(tooltip, index, text)
    local line = _G[tooltip:GetName() .. "TextLeft" .. index]
    if line then
        line:SetText(text .. line:GetText())
    end
end

local function AddItemLevelLine(tooltip, lineIndex, level)
    if BG.verLess3 and level then
        AddTooltipText(tooltip, lineIndex, ITEM_LEVEL_TEXT:format(level))
    end
end

BG.Init2(function()
    local db = {}
    local db2 = {}
    local all = {}

    local matchStr = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
    local classNames = {}
    for i = 1, GetNumClasses() do
        local className, classFilename = GetClassInfo(i)
        if className then
            classNames[className] = classFilename
        end
    end

    local function IndexClassItem(exItemID, classFileName, itemID)
        local classItems = db[exItemID][classFileName]
        if not classItems then
            classItems = {}
            db[exItemID][classFileName] = classItems
        end
        local classFlags = db2[exItemID][classFileName]
        if not classFlags then
            classFlags = {}
            db2[exItemID][classFileName] = classFlags
        end
        if classFlags[itemID] then return end
        tinsert(classItems, itemID)
        classFlags[itemID] = true
        local isSet = select(16, GetItemInfo(itemID))
        if isSet and classFileName ~= myClassFileName then
            all[exItemID] = nil
        end
    end

    -- 构建数据库
    local function AddItem(exItemID, itemIDs)
        db[exItemID] = db[exItemID] or {}
        db2[exItemID] = db2[exItemID] or {}

        for _, itemID in ipairs(itemIDs) do
            BG.OnItemLoad(itemID):ContinueOnItemLoad(function()
                BG.Tooltip_SetItemByID(itemID)
                for lineIndex = 1, BiaoGeTooltip:NumLines() do
                    local str = _G["BiaoGeTooltipTextLeft" .. lineIndex]:GetText()
                    if str then
                        local classStr = str:match(matchStr)
                        if classStr then
                            local classFileName = classNames[classStr]
                            if classFileName then
                                IndexClassItem(exItemID, classFileName, itemID)
                            end
                            return
                        end
                    end
                end
            end)
        end
    end

    local function ForEachExchangeItem(callback)
        for _, FB in ipairs(BG.FBtable) do
            for exItemID, itemIDs in pairs(BG.Loot[FB].ExchangeItems) do
                callback(exItemID, itemIDs)
            end
        end
    end

    ForEachExchangeItem(function(exItemID, itemIDs)
        all[exItemID] = itemIDs
    end)
    ForEachExchangeItem(AddItem)

    -- 小套装
    local function Build(groups, out)
        for _, group in ipairs(groups) do
            for _, itemID in pairs(group) do
                local companions = {}
                for _, otherID in pairs(group) do
                    if itemID ~= otherID then
                        tinsert(companions, otherID)
                    end
                end
                out[itemID] = companions
            end
        end
    end
    if BG.IsTitan then
        Build(ZUG_SET_GROUPS, itemSets)
        Build(ZUG_SWITCH_GROUPS, switchItems)
    end

    --[[
INVTYPE_FINGER = 11, 12,
INVTYPE_TRINKET = 13, 14,
INVTYPE_WEAPON = 16, 17,
]]
    local invSlotMap = {}
    for _, row in ipairs(INV_SLOT_ROWS) do
        invSlotMap[row[1]] = BG.verOver4 and row[2] or row[3]
    end

    local function ShowEquiped(slotID, tooltip, point1, point2)
        local currentItemLink = GetInventoryItemLink("player", slotID)
        if currentItemLink then
            local compareTip = BiaoGeTooltip5
            compareTip:SetOwner(tooltip, "ANCHOR_NONE")
            compareTip:ClearLines()
            compareTip:SetPoint(point1, tooltip, point2, 0, -10)
            compareTip:SetHyperlink(currentItemLink)
            AddTooltipText(compareTip, 1, format('|cff808080%s|r\n', CURRENTLY_EQUIPPED))
            local quality, level = select(3, GetItemInfo(currentItemLink))
            AddItemLevelLine(compareTip, 2, level)
            compareTip:SetParent(tooltip)
            compareTip:Show()
        end
    end

    local function ShowTooltip(lastTooltip, ids, point, title)
        local anchor = TOOLTIP_ANCHORS[point] or TOOLTIP_ANCHORS.RIGHT
        for i, id in ipairs(ids) do
            local tooltip = _G['BiaoGeTooltip' .. (i + 10)]
            tooltip:SetOwner(GameTooltip, "ANCHOR_NONE", 0, 0)
            tooltip:ClearLines()
            tooltip:SetPoint(anchor[1], lastTooltip, anchor[2], 0, 0)
            if type(id) ~= 'number' then
                tooltip:SetHyperlink(id)
            else
                tooltip:SetItemByID(id)
            end
            AddTooltipText(tooltip, 1, title)
            local level = select(4, GetItemInfo(id))
            AddItemLevelLine(tooltip, 2, level)
            tooltip.itemEquipLoc = select(4, GetItemInfoInstant(id))
            tooltip:SetParent(GameTooltip)
            tooltip:Show()
            lastTooltip = tooltip
        end
        return lastTooltip
    end

    local shoppingTips = {
        LEFT = { ShoppingTooltip2, ShoppingTooltip1 },
        RIGHT = { ShoppingTooltip1 },
    }
    local function GetTooltip(point)
        local candidates = shoppingTips[point]
        if candidates then
            for _, tooltip in ipairs(candidates) do
                if tooltip:IsVisible() then
                    return tooltip
                end
            end
        end
        return GameTooltip
    end

    local function ShowTooltipOnItemLoad(exItemID, ids, point, title)
        local tooltip = GetTooltip(point)
        tooltip.BiaoGeItemID = exItemID
        local loaded = 0
        local function OnLoaded()
            loaded = loaded + 1
            if loaded >= #ids and tooltip.BiaoGeItemID == exItemID then
                ShowTooltip(tooltip, ids, point, title)
            end
        end
        for _, itemID in pairs(ids) do
            BG.OnItemLoad(itemID):ContinueOnItemLoad(function()
                OnLoaded()
            end)
        end
    end

    function BG.SetZUGSetTooltip(exItemID, point)
        for _, rule in ipairs(EXCHANGE_SOURCES) do
            local ids = rule.map[exItemID]
            if ids then
                ShowTooltipOnItemLoad(exItemID, ids, point, rule.title)
                return
            end
        end
        local ids = db[exItemID] and db[exItemID][myClassFileName]
        if not ids then
            ids = all[exItemID]
        end
        if not ids or #ids > 5 then return end
        local lastTooltip = ShowTooltip(GameTooltip, ids, point, EXCHANGE_DEFAULT_TITLE)
        local lastItemEquipLoc = lastTooltip.itemEquipLoc
        local point1, _, point2 = lastTooltip:GetPoint()
        local slotID = invSlotMap[lastItemEquipLoc]
        if slotID then
            ShowEquiped(slotID, lastTooltip, point1, point2)
        end
    end
end)

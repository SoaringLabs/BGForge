local _, ns = ...

local L = ns.L

-- 隐私边界：只保存本机实际登录过的角色及其本周 CD、资源快照。
-- 不发送插件消息，也不读取战网账号、GUID、好友、公会或其他设备的数据。
local RAIDS = {
    { id = 580, name = L["太阳井"], compactWidth = 50 },
    { id = 568, name = L["祖阿曼"], compactWidth = 50 },
    { id = 649, name = L["十字军"], compactWidth = 50 },
    { id = 309, name = L["祖格"], compactWidth = 42 },
    { id = 533, name = L["纳克萨玛斯"], compactWidth = 70 },
    { id = 615, name = L["黑曜石"], compactWidth = 50 },
    { id = 616, name = L["永恒"], compactWidth = 42 },
    { id = 548, name = L["毒蛇"], compactWidth = 42 },
    { id = 550, name = L["风暴"], compactWidth = 42 },
    { id = 409, name = L["熔火"], compactWidth = 42 },
    { id = 624, name = L["宝库"], compactWidth = 42 },
}

-- 任务候选池沿用原版 BiaoGe 已验证的 Titan/WLK 定义，但完成快照只保存
-- 在 BGForge 当前本机角色记录中。专业日常只记录完成，不采集专业技能。
local QUEST_HEADER_GROUPS = {
    { id = "weekly", name = L["周常"] },
    { id = "professionDaily", name = L["专业日常"] },
    { id = "professionCooldown", name = L["专业制造"] },
}
local QUEST_COLUMNS = {
    {
        id = "raidWeekly",
        name = L["团本周常"],
        compactWidth = 60,
        groupID = "weekly",
        resetType = "weekly",
        questIDs = {
            24579, 24580, 24581, 24582, 24583, 24584,
            24585, 24586, 24587, 24588, 24589, 24590,
            93975, 94577, 94579, 95037, 96312,
        },
    },
    {
        id = "zulGurubWeekly",
        name = L["祖格周常"],
        compactWidth = 60,
        groupID = "weekly",
        resetType = "weekly",
        questIDs = { 98183 },
    },
    {
        id = "jewelcraftingDaily",
        name = L["珠宝"],
        compactWidth = 44,
        groupID = "professionDaily",
        resetType = "daily",
        questIDs = { 12959, 12962, 12961, 12958, 12963, 12960 },
    },
    {
        id = "cookingDaily",
        name = L["烹饪"],
        compactWidth = 44,
        groupID = "professionDaily",
        resetType = "daily",
        questIDs = { 13114, 13116, 13113, 13115, 13112, 13102, 13100, 13107, 13101, 13103 },
    },
    {
        id = "fishingDaily",
        name = L["钓鱼"],
        compactWidth = 44,
        groupID = "professionDaily",
        resetType = "daily",
        questIDs = { 13836, 13833, 13834, 13832, 13830 },
    },
}

-- Titan 3.80.2.69496 的客户端 SpellCooldowns + SkillLineAbility 联表结果。
-- 这里只保留当前确实存在长 CD 的逻辑项；泰坦精钢与三种专精布已无长 CD。
-- 炼金转化共享 Category 310，因此多个配方折叠成一个总览项目。
local PROFESSION_COOLDOWN_DEFINITIONS = {
    {
        id = "alchemyResearch",
        name = L["诺森德炼金研究"],
        professionName = L["炼金术"],
        skillLineID = 171,
        spellIDs = { 60893 },
    },
    {
        id = "alchemyTransmute",
        name = L["炼金转化"],
        professionName = L["炼金术"],
        skillLineID = 171,
        spellIDs = {
            11479, 11480,
            17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566,
            28566, 28567, 28568, 28569, 28580, 28581, 28582, 28583, 28584, 28585,
            53771, 53773, 53774, 53775, 53776, 53777, 53779,
            53780, 53781, 53782, 53783, 53784, 54020,
            66658, 66659, 66660, 66662, 66663, 66664,
        },
    },
    {
        id = "inscriptionNorthrendResearch",
        name = L["诺森德铭文研究"],
        professionName = L["铭文"],
        skillLineID = 773,
        spellIDs = { 61177 },
    },
    {
        id = "inscriptionMinorResearch",
        name = L["小型铭文研究"],
        professionName = L["铭文"],
        skillLineID = 773,
        spellIDs = { 61288 },
    },
    {
        id = "jewelcraftingBrilliantGlass",
        name = L["闪亮的玻璃"],
        professionName = L["珠宝加工"],
        skillLineID = 755,
        spellIDs = { 47280 },
    },
    {
        id = "jewelcraftingIcyPrism",
        name = L["冰冻棱柱"],
        professionName = L["珠宝加工"],
        skillLineID = 755,
        spellIDs = { 62242 },
    },
    {
        id = "tailoringGlacialBag",
        name = L["冰川背包"],
        professionName = L["裁缝"],
        skillLineID = 197,
        spellIDs = { 56005 },
    },
}

local professionCooldownDefinitionByID = {}
local professionCooldownDefinitionBySpellID = {}
local professionCooldownSkillLineSet = {}
local professionCooldownProfessionNameBySkillLineID = {}
for _, definition in ipairs(PROFESSION_COOLDOWN_DEFINITIONS) do
    definition.spellIDSet = {}
    professionCooldownDefinitionByID[definition.id] = definition
    professionCooldownSkillLineSet[definition.skillLineID] = true
    professionCooldownProfessionNameBySkillLineID[definition.skillLineID] = definition.professionName
    for _, spellID in ipairs(definition.spellIDs) do
        definition.spellIDSet[spellID] = true
        professionCooldownDefinitionBySpellID[spellID] = definition
    end
end

local PROFESSION_COOLDOWN_COLUMN = {
    id = "professionCooldown",
    name = L["制造 CD"],
    compactWidth = 70,
    groupID = "professionCooldown",
    isProfessionCooldown = true,
}

local questColumnByID = {}
local questColumnByQuestID = {}
for _, column in ipairs(QUEST_COLUMNS) do
    column.isQuest = true
    column.questIDSet = {}
    questColumnByID[column.id] = column
    for _, questID in ipairs(column.questIDs) do
        column.questIDSet[questID] = true
        questColumnByQuestID[questID] = column
    end
end

local LOCKOUT_COLUMNS = {}
for _, raid in ipairs(RAIDS) do
    LOCKOUT_COLUMNS[#LOCKOUT_COLUMNS + 1] = raid
end
for _, column in ipairs(QUEST_COLUMNS) do
    LOCKOUT_COLUMNS[#LOCKOUT_COLUMNS + 1] = column
end
LOCKOUT_COLUMNS[#LOCKOUT_COLUMNS + 1] = PROFESSION_COOLDOWN_COLUMN

local raidByID = {}
for _, raid in ipairs(RAIDS) do
    raidByID[raid.id] = raid
end

local RAID_OPTION_PREFIX = "raidLockoutShow_"
local QUEST_GROUP_OPTION_PREFIX = "raidLockoutShowGroup_"
local DATA_VERSION = 1
local DATA_KEY = "BGForgeRaidLockouts"
local RAID_MIN_LEVEL = 80
local TITAN_EMBER_CURRENCY_ID = 3403
local TITAN_SHARD_CURRENCY_ID = 3406
local LEGENDARY_ITEM_QUALITY = 5
-- 橙武碎片是普通物品而不是货币，客户端也没有“橙武材料”的语义分类。
-- 每个阶段只需在这里补充物品定义；角色快照和总览会自动按目录统计。
local TITAN_LEGENDARY_FRAGMENT_DEFINITIONS = {
    {
        itemID = 22726, -- 埃提耶什的碎片
        targetCount = 40,
        iconFileID = 134888,
    },
}
local TITAN_LEGENDARY_FRAGMENT_DEFINITION_BY_ITEM_ID = {}
for _, definition in ipairs(TITAN_LEGENDARY_FRAGMENT_DEFINITIONS) do
    TITAN_LEGENDARY_FRAGMENT_DEFINITION_BY_ITEM_ID[definition.itemID] = definition
end
local TITAN_LEGENDARY_UPGRADE_ITEM_IDS = {
    265340, 265524, 267339, 269664, -- 橙颈
    265335, 265523, 267338, 269667, -- 橙锤
    265526, 267335, 269669,         -- 风剑
    267340, 269665,                 -- 橙杖
    269670,                         -- 橙匕
}
local TITAN_LEGENDARY_UPGRADE_ITEM_ID_SET = {}
for _, itemID in ipairs(TITAN_LEGENDARY_UPGRADE_ITEM_IDS) do
    TITAN_LEGENDARY_UPGRADE_ITEM_ID_SET[itemID] = true
end
local TITAN_PRIMARY_PROFESSION_INFO = {
    [L["锻造"]] = { skillLineID = 164, iconFileID = 136241 },
    [L["工程学"]] = { skillLineID = 202, iconFileID = 136243 },
    [L["炼金术"]] = { skillLineID = 171, iconFileID = 136240 },
    [L["制皮"]] = { skillLineID = 165, iconFileID = 133611 },
    [L["裁缝"]] = { skillLineID = 197, iconFileID = 136249 },
    [L["附魔"]] = { skillLineID = 333, iconFileID = 136244 },
    [L["采矿"]] = { skillLineID = 186, iconFileID = 136248 },
    [L["草药学"]] = { skillLineID = 182, iconFileID = 136065 },
    [L["剥皮"]] = { skillLineID = 393, iconFileID = 134366 },
    [L["铭文"]] = { skillLineID = 773, iconFileID = 237171 },
    [L["珠宝加工"]] = { skillLineID = 755, iconFileID = 134071 },
}

local ITEM_TILE_SIZE = 22
local ITEM_TILE_GAP = 2
local ITEM_TILE_PADDING = 4
local PROFESSION_TILE_COLOR = { 0.84, 0.55, 0.18, 1 }
local RESOURCE_NUMBER_FONT = "Interface\\AddOns\\BGForge\\Media\\Fonts\\RobotoCondensed-Medium.ttf"
local RESOURCE_NUMBER_FONT_SIZE = 12
local HEADER_HORIZONTAL_PADDING = 14
local HEADER_WIDTH_SAFETY = 4
local SCREEN_EDGE_MARGIN = 32

local SMALL_UI = {
    padding = 10,
    topBarHeight = 36,
    nameWidth = 160,
    rowHeight = 24,
    raidHeaderGroupHeight = 22,
    raidHeaderSubHeight = 22,
    sectionGap = 8,
    resourceGroupHeight = 22,
    resourceSubHeaderHeight = 22,
    professionWidth = 100,
    legendaryWidth = 150,
    fragmentWidth = 100,
    upgradeWidth = 130,
    trinketWidth = 100,
    goldWidth = 88,
    emberWidth = 88,
    shardWidth = 88,
    footerHeight = 30,
    horizontalScrollHeight = 16,
}

local function CalculateItemStripLayout(cellWidth, itemCount)
    local usableWidth = max(0, cellWidth - ITEM_TILE_PADDING * 2)
    local capacity = max(0, floor((usableWidth + ITEM_TILE_GAP) / (ITEM_TILE_SIZE + ITEM_TILE_GAP)))
    local visibleCount = min(itemCount or 0, capacity)
    local stripWidth = visibleCount > 0
        and visibleCount * ITEM_TILE_SIZE + (visibleCount - 1) * ITEM_TILE_GAP or 0
    return visibleCount, (cellWidth - stripWidth) / 2, ITEM_TILE_SIZE, ITEM_TILE_GAP
end

local function GetItemTileDisplay(item, valueKey, forcedQuality, valuePrefix)
    local quality = tonumber(forcedQuality) or tonumber(item and item.quality)
    local value = item and tonumber(item[valueKey])
    local valueText = value and (valuePrefix or "") .. BG.FormatNumber(value, 0) or ""
    return quality, valueText
end

local function ShowItemTooltip(owner, item)
    if not owner or not item or not GameTooltip then
        return
    end

    local hasReference = item.link or item.itemID
    if not hasReference then
        return
    end
    local anchor = BG.ButtonIsInRight(owner) and "ANCHOR_LEFT" or "ANCHOR_RIGHT"
    GameTooltip:SetOwner(owner, anchor, 0, 0)
    GameTooltip:ClearLines()
    if item.link then
        GameTooltip:SetHyperlink(item.link)
    elseif GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(item.itemID)
    else
        GameTooltip:SetHyperlink("item:" .. item.itemID)
    end
    if item.targetCount and GameTooltip.AddLine then
        GameTooltip:AddLine(string.format(L["目标数量：%d"], item.targetCount), 1, 0.82, 0)
    end
    GameTooltip:Show()
end

local currencyIconCache = {}

local function GetCoinIconFile()
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinIcon then
        local iconFileID = C_CurrencyInfo.GetCoinIcon(10000)
        if iconFileID then
            return iconFileID
        end
    end
    return "Interface\\MoneyFrame\\UI-GoldIcon"
end

local function GetCurrencyIconFile(currencyID, fallback)
    if currencyIconCache[currencyID] then
        return currencyIconCache[currencyID]
    end
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if info and info.iconFileID then
            currencyIconCache[currencyID] = info.iconFileID
            return info.iconFileID
        end
    end
    return fallback
end

local function FormatResourceNumber(amount)
    if amount == nil then
        return ""
    end
    return tostring(BG.FormatNumber(amount, 0))
end

local function GetResourceIconMarkup(iconFile)
    if not iconFile then
        return ""
    end
    return " |T" .. iconFile .. ":13:13:0:0:64:64:4:60:4:60|t"
end

local function GetProfessionTileDisplay(profession)
    if not profession or not profession.iconFileID then
        return
    end
    return profession.iconFileID, tostring(profession.rank or 0)
end

local function FormatResourceAmount(amount, iconFile)
    return FormatResourceNumber(amount) .. GetResourceIconMarkup(iconFile)
end

local function RequestItemData(itemID)
    if itemID and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

local function GetItemIconFile(itemInfo, fallback)
    local itemID, _, _, _, iconFileID = GetItemInfoInstant(itemInfo)
    if not iconFileID then
        RequestItemData(itemID or tonumber(itemInfo))
    end
    return iconFileID or fallback
end

local function GetActualItemLevel(itemInfo)
    local itemLevel
    if C_Item and C_Item.GetDetailedItemLevelInfo then
        itemLevel = C_Item.GetDetailedItemLevelInfo(itemInfo)
    elseif GetDetailedItemLevelInfo then
        itemLevel = GetDetailedItemLevelInfo(itemInfo)
    end
    if not itemLevel then
        itemLevel = select(4, GetItemInfo(itemInfo))
    end
    return tonumber(itemLevel)
end

local function CreateItemSnapshot(itemLink, itemID, iconFileID, quality)
    itemID = itemID or (itemLink and GetItemInfoInstant(itemLink))
    if not itemID then
        return
    end
    local link = itemLink or select(2, GetItemInfo(itemID))
    local icon = GetItemIconFile(link or itemID, iconFileID)
    if not link or not icon then
        RequestItemData(itemID)
    end
    local infoQuality = select(3, GetItemInfo(link or itemID))
    quality = tonumber(quality) or tonumber(infoQuality)
    return {
        itemID = itemID,
        link = link,
        itemLevel = GetActualItemLevel(link or itemID),
        iconFileID = icon,
        quality = quality,
    }
end

local function IsLegendaryUpgradeItem(itemID)
    return itemID and TITAN_LEGENDARY_UPGRADE_ITEM_ID_SET[tonumber(itemID)] or false
end

local function IsLegendaryEquipment(itemLink, itemID, quality)
    if quality ~= LEGENDARY_ITEM_QUALITY then
        return false
    end
    local resolvedItemID, _, _, equipLoc = GetItemInfoInstant(itemLink or itemID)
    itemID = tonumber(itemID) or tonumber(resolvedItemID)
    if IsLegendaryUpgradeItem(itemID) then
        return false
    end
    if equipLoc == nil then
        RequestItemData(itemID)
    end
    return equipLoc and equipLoc ~= ""
end

local function SortItemSnapshots(items)
    sort(items, function(a, b)
        if (a.itemLevel or 0) == (b.itemLevel or 0) then
            return (a.itemID or 0) < (b.itemID or 0)
        end
        return (a.itemLevel or 0) > (b.itemLevel or 0)
    end)
    return items
end

local function MergeItemSnapshots(...)
    local merged = {}
    local seen = {}
    for listIndex = 1, select("#", ...) do
        for _, item in ipairs(select(listIndex, ...) or {}) do
            local key = tostring(item.itemID or 0) .. ":" .. tostring(item.itemLevel or 0)
            if not IsLegendaryUpgradeItem(item.itemID) and not seen[key] then
                seen[key] = true
                merged[#merged + 1] = item
            end
        end
    end
    return SortItemSnapshots(merged)
end

local function CaptureProfessionsFromPrimaryAPI()
    if not GetProfessions or not GetProfessionInfo then
        return
    end

    local professions = {}
    local profession1, profession2 = GetProfessions()
    if not profession1 and not profession2 then
        return
    end
    for _, professionIndex in ipairs({ profession1, profession2 }) do
        if professionIndex then
            local name, iconFileID, rank, maxRank, _, _, skillLineID = GetProfessionInfo(professionIndex)
            if not name or not iconFileID or not skillLineID then
                return
            end
            professions[#professions + 1] = {
                skillLineID = skillLineID,
                rank = tonumber(rank) or 0,
                maxRank = tonumber(maxRank) or 0,
                iconFileID = iconFileID,
            }
        end
    end
    return professions
end

local function CaptureProfessionsFromSkillLines()
    if not GetNumSkillLines or not GetSkillLineInfo then
        return
    end

    local numSkillLines = GetNumSkillLines()
    if not numSkillLines or numSkillLines <= 0 then
        return
    end

    local professions = {}
    local collapsedHeaders = {}
    for index = 1, numSkillLines do
        local skillName, isHeader, isExpanded, rank, _, _, maxRank = GetSkillLineInfo(index)
        if isHeader and not isExpanded then
            collapsedHeaders[#collapsedHeaders + 1] = index
        end
        local professionInfo = not isHeader and TITAN_PRIMARY_PROFESSION_INFO[skillName] or nil
        if professionInfo and #professions < 2 then
            professions[#professions + 1] = {
                skillLineID = professionInfo.skillLineID,
                rank = tonumber(rank) or 0,
                maxRank = tonumber(maxRank) or 0,
                iconFileID = professionInfo.iconFileID,
            }
        end
    end

    -- GetProfessions 由按需加载的 Blizzard 面板提供时可能尚不可用。
    -- 只有确实存在折叠分类时才逐个展开；下一次 SKILL_LINES_CHANGED 会完成采集。
    -- 绝不能反复调用 ExpandSkillHeader(0)，否则会形成事件自激循环。
    if #professions < 2 and #collapsedHeaders > 0 then
        local skillFrameVisible = SkillFrame and SkillFrame.IsVisible and SkillFrame:IsVisible()
        if not skillFrameVisible and ExpandSkillHeader then
            for index = #collapsedHeaders, 1, -1 do
                ExpandSkillHeader(collapsedHeaders[index])
            end
        end
        return
    end
    return professions
end

local function CaptureCurrentProfessions()
    return CaptureProfessionsFromPrimaryAPI() or CaptureProfessionsFromSkillLines()
end

local function IsKnownProfessionSpell(spellID)
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end
    return IsSpellKnown and IsSpellKnown(spellID) and true or false
end

local function GetActiveProfessionCooldownRemaining(spellID)
    if not GetSpellCooldown or not GetTime then
        return 0
    end

    local startTime, duration = GetSpellCooldown(spellID)
    startTime = tonumber(startTime) or 0
    duration = tonumber(duration) or 0
    -- 忽略公共冷却。这里的候选配方最短也是 20 小时，不应把 1.5 秒 GCD 写进总览。
    if startTime <= 0 or duration < 60 then
        return 0
    end

    local currentTime = GetTime()
    if startTime > currentTime then
        startTime = startTime - 2 ^ 32 / 1000
    end
    return max(0, startTime + duration - currentTime)
end

local function GetTradeSkillRecipeSpellID(index)
    if not GetTradeSkillRecipeLink then
        return
    end
    local link = GetTradeSkillRecipeLink(index)
    return link and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)")) or nil
end

local function ScanOpenTradeSkillCooldowns()
    if not GetNumTradeSkills or not GetTradeSkillInfo or not GetTradeSkillCooldown then
        return {}, false
    end

    local count = tonumber(GetNumTradeSkills()) or 0
    if count <= 0 then
        return {}, false
    end

    local snapshots = {}
    local scannedRecipe = false
    local scannedSkillLineID
    if GetTradeSkillLine then
        local tradeSkillName = GetTradeSkillLine()
        local professionInfo = tradeSkillName and TITAN_PRIMARY_PROFESSION_INFO[tradeSkillName]
        scannedSkillLineID = professionInfo and professionInfo.skillLineID or nil
    end
    for index = 1, count do
        local _, skillType = GetTradeSkillInfo(index)
        if skillType and skillType ~= "header" then
            scannedRecipe = true
            local spellID = GetTradeSkillRecipeSpellID(index)
            local definition = spellID and professionCooldownDefinitionBySpellID[spellID] or nil
            if definition then
                scannedSkillLineID = scannedSkillLineID or definition.skillLineID
                local remaining = tonumber(GetTradeSkillCooldown(index)) or 0
                local snapshot = snapshots[definition.id]
                if not snapshot or remaining > snapshot.remaining then
                    snapshots[definition.id] = {
                        spellID = spellID,
                        remaining = max(0, remaining),
                    }
                end
            end
        end
    end
    return snapshots, scannedRecipe and scannedSkillLineID or nil
end

local function CaptureEquippedTrinkets()
    local trinkets = {}
    for _, slotID in ipairs({ 13, 14 }) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local item = CreateItemSnapshot(
                link,
                GetInventoryItemID("player", slotID),
                GetInventoryItemTexture("player", slotID),
                GetInventoryItemQuality("player", slotID)
            )
            if item then
                item.slotID = slotID
                trinkets[#trinkets + 1] = item
            end
        end
    end
    return trinkets
end

local function CollectLegendaryFromContainer(containerID, target)
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then
        return
    end
    for slotID = 1, C_Container.GetContainerNumSlots(containerID) do
        local info = C_Container.GetContainerItemInfo(containerID, slotID)
        if info and IsLegendaryEquipment(info.hyperlink, info.itemID, info.quality) then
            local item = CreateItemSnapshot(info.hyperlink, info.itemID, info.iconFileID, info.quality)
            if item then
                target[#target + 1] = item
            end
        end
    end
end

local function CaptureEquippedAndBagLegendaries()
    local items = {}
    for slotID = 1, 19 do
        local link = GetInventoryItemLink("player", slotID)
        local itemID = link and GetInventoryItemID("player", slotID)
        local quality = link and GetInventoryItemQuality("player", slotID)
        if link and IsLegendaryEquipment(link, itemID, quality) then
            local item = CreateItemSnapshot(link, itemID, GetInventoryItemTexture("player", slotID), quality)
            if item then
                items[#items + 1] = item
            end
        end
    end
    for bagID = 0, NUM_BAG_SLOTS do
        CollectLegendaryFromContainer(bagID, items)
    end
    return MergeItemSnapshots(items)
end

local function CaptureLegendaryUpgradeItems()
    local items = {}
    for _, itemID in ipairs(TITAN_LEGENDARY_UPGRADE_ITEM_IDS) do
        local count
        if C_Item and C_Item.GetItemCount then
            count = C_Item.GetItemCount(itemID, true)
        elseif GetItemCount then
            count = GetItemCount(itemID, true)
        end
        if count and count > 0 then
            local link = select(2, GetItemInfo(itemID))
            items[#items + 1] = {
                itemID = itemID,
                link = link,
                count = count,
                iconFileID = GetItemIconFile(itemID),
                quality = LEGENDARY_ITEM_QUALITY,
            }
        end
    end
    return items
end

local function CaptureLegendaryFragmentItems()
    local items = {}
    for _, definition in ipairs(TITAN_LEGENDARY_FRAGMENT_DEFINITIONS) do
        local itemID = definition.itemID
        local count
        if C_Item and C_Item.GetItemCount then
            count = C_Item.GetItemCount(itemID, true)
        elseif GetItemCount then
            count = GetItemCount(itemID, true)
        end
        if count and count > 0 then
            items[#items + 1] = {
                itemID = itemID,
                link = select(2, GetItemInfo(itemID)),
                count = count,
                targetCount = definition.targetCount,
                iconFileID = GetItemIconFile(itemID, definition.iconFileID),
                quality = LEGENDARY_ITEM_QUALITY,
            }
        end
    end
    return items
end

local function DesignColor(token, alpha)
    local color = BG.UI.Token("color", token)
    if alpha ~= nil then
        color[4] = alpha
    end
    return color
end

local COLOR = {
    panel = DesignColor("canvas"),
    panelTop = DesignColor("header"),
    header = DesignColor("header"),
    headerStrong = DesignColor("raised"),
    row = DesignColor("row"),
    rowHoverWash = DesignColor("rowHoverWash"),
    current = DesignColor("focusSurface"),
    gold = DesignColor("forgeGold"),
    grid = DesignColor("borderSubtle"),
    gridStrong = DesignColor("borderStrong"),
    focus = DesignColor("focus"),
    focusText = DesignColor("focusText"),
    textPrimary = DesignColor("textPrimary"),
    textSecondary = DesignColor("textSecondary"),
    textMuted = DesignColor("textMuted"),
    complete = DesignColor("successSurface"),
    partial = DesignColor("warningSurface"),
    warning = DesignColor("warning"),
}

local function GetLockoutOptionKey(columnID)
    return RAID_OPTION_PREFIX .. columnID
end

local function GetQuestGroupOptionKey(groupID)
    return QUEST_GROUP_OPTION_PREFIX .. groupID
end

local function IsLockoutColumnVisible(column)
    local options = BiaoGe and BiaoGe.options
    local optionKey = column.groupID
        and GetQuestGroupOptionKey(column.groupID) or GetLockoutOptionKey(column.id)
    local value = options and options[optionKey]
    return value == nil or value == 1
end

local function GetVisibleLockoutColumns()
    local columns = {}
    for _, column in ipairs(LOCKOUT_COLUMNS) do
        if IsLockoutColumnVisible(column) then
            columns[#columns + 1] = column
        end
    end
    return columns
end

local function GetVisibleQuestGroups(columns)
    local visibleByGroup = {}
    for _, column in ipairs(columns or {}) do
        if column.groupID then
            visibleByGroup[column.groupID] = visibleByGroup[column.groupID] or {}
            visibleByGroup[column.groupID][#visibleByGroup[column.groupID] + 1] = column
        end
    end

    local groups = {}
    for _, definition in ipairs(QUEST_HEADER_GROUPS) do
        local groupColumns = visibleByGroup[definition.id]
        if groupColumns and #groupColumns > 0 then
            groups[#groups + 1] = {
                id = definition.id,
                name = definition.name,
                columns = groupColumns,
            }
        end
    end
    return groups
end

local function CalculateMeasuredColumnMinimums(columns, measureText)
    local widths = {}
    local totalWidth = 0
    for _, column in ipairs(columns) do
        local measuredWidth = tonumber(measureText(column.name)) or 0
        local minimumWidth = max(
            column.compactWidth or 0,
            ceil(measuredWidth + HEADER_HORIZONTAL_PADDING + HEADER_WIDTH_SAFETY)
        )
        widths[column.id] = minimumWidth
        totalWidth = totalWidth + minimumWidth
    end
    return widths, totalWidth
end

local function CalculateHorizontalViewport(contentWidth, screenWidth)
    local maximumWidth = max(320, (screenWidth or contentWidth) - SCREEN_EDGE_MARGIN)
    local viewportWidth = min(contentWidth, maximumWidth)
    return viewportWidth, max(0, contentWidth - viewportWidth)
end

local function CalculateRaidColumnWidths(raids, availableWidth, minimumWidths)
    local widths = {}
    if #raids == 0 then
        return widths, 0
    end

    local compactWidth = 0
    for _, raid in ipairs(raids) do
        compactWidth = compactWidth + (minimumWidths and minimumWidths[raid.id] or raid.compactWidth)
    end

    local extraPerRaid = max(0, availableWidth - compactWidth) / #raids
    local assignedWidth = 0
    for index, raid in ipairs(raids) do
        local minimumWidth = minimumWidths and minimumWidths[raid.id] or raid.compactWidth
        local columnWidth = minimumWidth + extraPerRaid
        if index == #raids and availableWidth >= compactWidth then
            columnWidth = availableWidth - assignedWidth
        end
        widths[raid.id] = columnWidth
        assignedWidth = assignedWidth + columnWidth
    end
    return widths, assignedWidth
end

local function CalculateResourceColumnWidths(ui, availableWidth)
    local definitions = {
        { id = "profession", width = ui.professionWidth },
        { id = "legendary", width = ui.legendaryWidth },
        { id = "fragment", width = ui.fragmentWidth },
        { id = "upgrade", width = ui.upgradeWidth },
        { id = "trinket", width = ui.trinketWidth },
        { id = "gold", width = ui.goldWidth },
        { id = "ember", width = ui.emberWidth },
        { id = "shard", width = ui.shardWidth },
    }
    local compactWidth = 0
    for _, definition in ipairs(definitions) do
        compactWidth = compactWidth + definition.width
    end

    local extraPerColumn = max(0, availableWidth - compactWidth) / #definitions
    local widths = {}
    local assignedWidth = 0
    for index, definition in ipairs(definitions) do
        local columnWidth = definition.width + extraPerColumn
        if index == #definitions and availableWidth >= compactWidth then
            columnWidth = availableWidth - assignedWidth
        end
        widths[definition.id] = columnWidth
        assignedWidth = assignedWidth + columnWidth
    end
    return widths, assignedWidth
end

local currentCharacter = {
    instances = {},
    ready = false,
    refreshing = false,
    requestSerial = 0,
    lastRequestAt = nil,
}
local deletedThisSession = {}

local overviewFrame
local hoverFrame
local hoverAnchor
local hoverEmbedded = false
local hoverFloatingFrameLevel
local hoverHideSerial = 0
local updateOverviewFrame
local updateHoverFrame

local function GetCurrentRealmID()
    return GetRealmID()
end

local function GetCurrentCharacterName()
    return UnitName("player") or BG.playerName or UNKNOWN
end

local function GetCharacterKey(realmID, characterName)
    return tostring(realmID) .. ":" .. characterName
end

local function GetDataStore()
    BiaoGe = BiaoGe or {}
    local data = BiaoGe[DATA_KEY]
    if type(data) ~= "table" or data.schemaVersion ~= DATA_VERSION then
        data = {
            schemaVersion = DATA_VERSION,
            nextResetAt = nil,
            realms = {},
        }
        BiaoGe[DATA_KEY] = data
    end
    data.realms = type(data.realms) == "table" and data.realms or {}
    data.nextResetAt = tonumber(data.nextResetAt)
    return data
end

local function GetRealmStore(realmID, create)
    local data = GetDataStore()
    local realm = data.realms[realmID]
    if not realm and create then
        realm = {
            nextOrder = 1,
            characters = {},
        }
        data.realms[realmID] = realm
    end
    if realm then
        realm.characters = type(realm.characters) == "table" and realm.characters or {}
        local nextOrder = tonumber(realm.nextOrder) or 1
        for _, character in pairs(realm.characters) do
            if type(character) == "table" and tonumber(character.order) then
                nextOrder = max(nextOrder, tonumber(character.order) + 1)
            end
        end
        realm.nextOrder = nextOrder
    end
    return realm
end

local function NormalizeQuestCompletionSnapshot(snapshot, column, now)
    if type(snapshot) ~= "table" then
        return
    end

    local resetAt = tonumber(snapshot.resetAt)
    if not resetAt or now >= resetAt or not column then
        return
    end

    local questID = tonumber(snapshot.questID)
    if snapshot.status == "incomplete" or not column.questIDSet[questID] then
        return
    end

    return {
        questID = questID,
        resetAt = resetAt,
        updatedAt = tonumber(snapshot.updatedAt),
    }
end

local function NormalizeProfessionCooldownSnapshot(snapshot, definition, now)
    if type(snapshot) ~= "table" or not definition then
        return
    end

    local spellID = tonumber(snapshot.spellID)
    if not spellID or not definition.spellIDSet[spellID] then
        return
    end

    local endTime = tonumber(snapshot.endTime)
    if endTime and endTime <= now then
        endTime = nil
    end
    return {
        spellID = spellID,
        endTime = endTime,
        observedAt = tonumber(snapshot.observedAt),
    }
end

local function ClearExpiredRaidData()
    local data = GetDataStore()
    local now = GetServerTime()
    local resetAll = data.nextResetAt and now >= data.nextResetAt
    local changed = resetAll and true or false

    for _, realm in pairs(data.realms) do
        if type(realm) == "table" and type(realm.characters) == "table" then
            for characterName, character in pairs(realm.characters) do
                if type(character) == "table" then
                    character.name = type(character.name) == "string" and character.name or characterName
                    character.specIndex = tonumber(character.specIndex)
                    character.level = tonumber(character.level)
                    character.itemLevel = tonumber(character.itemLevel)
                    character.order = tonumber(character.order)
                    character.lastRecordedAt = tonumber(character.lastRecordedAt)
                    character.isHidden = character.isHidden and true or nil
                    character.professions = type(character.professions) == "table" and character.professions or {}
                    character.legendaryItems = MergeItemSnapshots(
                        type(character.legendaryItems) == "table" and character.legendaryItems or {}
                    )
                    local normalizedFragmentItems = {}
                    for _, item in ipairs(
                        type(character.legendaryFragmentItems) == "table"
                            and character.legendaryFragmentItems or {}
                    ) do
                        local itemID = type(item) == "table" and tonumber(item.itemID)
                        local definition = itemID
                            and TITAN_LEGENDARY_FRAGMENT_DEFINITION_BY_ITEM_ID[itemID] or nil
                        local count = type(item) == "table" and tonumber(item.count)
                        if definition and count and count > 0 then
                            normalizedFragmentItems[#normalizedFragmentItems + 1] = {
                                itemID = itemID,
                                link = item.link,
                                count = count,
                                targetCount = definition.targetCount,
                                iconFileID = item.iconFileID or definition.iconFileID,
                                quality = LEGENDARY_ITEM_QUALITY,
                            }
                        end
                    end
                    character.legendaryFragmentItems = normalizedFragmentItems
                    character.bankLegendaryItems = MergeItemSnapshots(
                        type(character.bankLegendaryItems) == "table" and character.bankLegendaryItems or {}
                    )
                    character.legendaryUpgradeItems = type(character.legendaryUpgradeItems) == "table"
                        and character.legendaryUpgradeItems or {}
                    for _, item in ipairs(character.legendaryUpgradeItems) do
                        if type(item) == "table" and IsLegendaryUpgradeItem(item.itemID) then
                            item.quality = LEGENDARY_ITEM_QUALITY
                        end
                    end
                    character.trinkets = type(character.trinkets) == "table" and character.trinkets or {}
                    character.questCompletions = type(character.questCompletions) == "table"
                        and character.questCompletions or {}
                    character.professionCooldowns = type(character.professionCooldowns) == "table"
                        and character.professionCooldowns or {}
                    character.professionCooldownsUpdatedAt = tonumber(character.professionCooldownsUpdatedAt)
                    local normalizedCooldownScans = {}
                    if type(character.professionCooldownScans) == "table" then
                        for skillLineID, observedAt in pairs(character.professionCooldownScans) do
                            skillLineID = tonumber(skillLineID)
                            observedAt = tonumber(observedAt)
                            if skillLineID and observedAt and professionCooldownSkillLineSet[skillLineID] then
                                normalizedCooldownScans[skillLineID] = observedAt
                            end
                        end
                    end
                    character.professionCooldownScans = normalizedCooldownScans
                    for cooldownID, snapshot in pairs(character.professionCooldowns) do
                        local previousEndTime = type(snapshot) == "table" and tonumber(snapshot.endTime)
                        local normalized = NormalizeProfessionCooldownSnapshot(
                            snapshot,
                            professionCooldownDefinitionByID[cooldownID],
                            now
                        )
                        if normalized then
                            character.professionCooldowns[cooldownID] = normalized
                            if previousEndTime and not normalized.endTime then
                                changed = true
                            end
                        else
                            character.professionCooldowns[cooldownID] = nil
                            changed = true
                        end
                    end
                    if character.weeklyQuest ~= nil then
                        local migrated = NormalizeQuestCompletionSnapshot(
                            character.weeklyQuest,
                            questColumnByID.raidWeekly,
                            now
                        )
                        if migrated and not character.questCompletions.raidWeekly then
                            character.questCompletions.raidWeekly = migrated
                        end
                        character.weeklyQuest = nil
                        changed = true
                    end
                    for columnID, snapshot in pairs(character.questCompletions) do
                        local normalized = NormalizeQuestCompletionSnapshot(
                            snapshot,
                            questColumnByID[columnID],
                            now
                        )
                        if normalized then
                            character.questCompletions[columnID] = normalized
                        else
                            character.questCompletions[columnID] = nil
                            changed = true
                        end
                    end
                    if resetAll then
                        character.instances = {}
                    elseif type(character.instances) == "table" then
                        for raidID, lockouts in pairs(character.instances) do
                            if not raidByID[tonumber(raidID)] or type(lockouts) ~= "table" then
                                character.instances[raidID] = nil
                            else
                                for index = #lockouts, 1, -1 do
                                    local lockout = lockouts[index]
                                    local resetAt = type(lockout) == "table" and tonumber(lockout.resetAt)
                                    if not resetAt or now >= resetAt then
                                        tremove(lockouts, index)
                                    else
                                        lockout.resetAt = resetAt
                                        lockout.difficultyName = type(lockout.difficultyName) == "string"
                                            and lockout.difficultyName or UNKNOWN
                                        lockout.killedCount = tonumber(lockout.killedCount) or 0
                                        lockout.numEncounters = tonumber(lockout.numEncounters) or 0
                                        lockout.bosses = type(lockout.bosses) == "table" and lockout.bosses or {}
                                        for bossIndex = #lockout.bosses, 1, -1 do
                                            local boss = lockout.bosses[bossIndex]
                                            if type(boss) ~= "table" then
                                                tremove(lockout.bosses, bossIndex)
                                            else
                                                boss.name = type(boss.name) == "string" and boss.name or UNKNOWN
                                                boss.killed = boss.killed and true or false
                                            end
                                        end
                                    end
                                end
                                if #lockouts == 0 then
                                    character.instances[raidID] = nil
                                end
                            end
                        end
                    else
                        character.instances = {}
                    end
                else
                    realm.characters[characterName] = nil
                end
            end
        end
    end

    if resetAll then
        data.nextResetAt = nil
    end
    return changed
end

local function GetCurrentTalentIndex()
    if BG.verOver4 then
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
            return C_SpecializationInfo.GetSpecialization()
        elseif GetSpecialization then
            return GetSpecialization()
        end
        return
    end

    -- 泰坦服使用 3.8 系列客户端：以当前双天赋组中投入点数最多的天赋树作为当前专精。
    local activeGroup = GetActiveTalentGroup and GetActiveTalentGroup()
    local maxPoints = 0
    local talentIndex
    for index = 1, 3 do
        local points = select(5, GetTalentTabInfo(index, nil, nil, activeGroup))
        if points and points >= maxPoints then
            maxPoints = points
            talentIndex = index
        end
    end
    return maxPoints > 0 and talentIndex or nil
end

local function RefreshCurrentCharacterIdentity()
    currentCharacter.name = GetCurrentCharacterName()
    currentCharacter.classFile = select(2, UnitClass("player"))
    local level = UnitLevel("player")
    if level and level > 0 then
        currentCharacter.level = level
    end
    local overallItemLevel, equippedItemLevel = GetAverageItemLevel()
    currentCharacter.itemLevel = equippedItemLevel or overallItemLevel

    currentCharacter.specIndex = GetCurrentTalentIndex()
end

local function GetOrCreateCurrentCharacterStore()
    RefreshCurrentCharacterIdentity()

    local realmID = GetCurrentRealmID()
    local characterName = currentCharacter.name
    if deletedThisSession[GetCharacterKey(realmID, characterName)] then
        return
    end

    local realm = GetRealmStore(realmID, true)
    local stored = realm.characters[characterName]
    if type(stored) ~= "table" then
        stored = {
            name = characterName,
            order = realm.nextOrder,
            instances = {},
        }
        realm.nextOrder = realm.nextOrder + 1
        realm.characters[characterName] = stored
    end

    stored.name = characterName
    stored.classFile = currentCharacter.classFile
    stored.specIndex = currentCharacter.specIndex
    stored.level = currentCharacter.level or stored.level
    stored.itemLevel = currentCharacter.itemLevel
    stored.instances = type(stored.instances) == "table" and stored.instances or {}
    return stored
end

local function CaptureCurrentProfessionCooldowns(stored)
    stored = stored or GetOrCreateCurrentCharacterStore()
    if not stored then
        return false
    end

    local canInspectKnownSpells = IsPlayerSpell or IsSpellKnown
    local tradeSkillSnapshots, scannedSkillLineID = ScanOpenTradeSkillCooldowns()
    if not canInspectKnownSpells and not scannedSkillLineID then
        return false
    end

    local now = GetServerTime()
    local snapshots = type(stored.professionCooldowns) == "table" and stored.professionCooldowns or {}
    local scans = type(stored.professionCooldownScans) == "table" and stored.professionCooldownScans or {}
    if scannedSkillLineID then
        for _, definition in ipairs(PROFESSION_COOLDOWN_DEFINITIONS) do
            if definition.skillLineID == scannedSkillLineID then
                snapshots[definition.id] = nil
            end
        end
        scans[scannedSkillLineID] = now
    end

    local observedKnownSpellSkillLines = {}
    for _, definition in ipairs(PROFESSION_COOLDOWN_DEFINITIONS) do
        local tradeSkillSnapshot = tradeSkillSnapshots[definition.id]
        local knownSpellIDs = {}
        for _, spellID in ipairs(definition.spellIDs) do
            if IsKnownProfessionSpell(spellID) then
                knownSpellIDs[#knownSpellIDs + 1] = spellID
            end
        end

        if tradeSkillSnapshot and not definition.spellIDSet[tradeSkillSnapshot.spellID] then
            tradeSkillSnapshot = nil
        end
        if tradeSkillSnapshot or #knownSpellIDs > 0 then
            if #knownSpellIDs > 0 then
                observedKnownSpellSkillLines[definition.skillLineID] = true
            end
            local observedSpellID = tradeSkillSnapshot and tradeSkillSnapshot.spellID or knownSpellIDs[1]
            local remaining = tradeSkillSnapshot and tradeSkillSnapshot.remaining or 0
            for _, spellID in ipairs(knownSpellIDs) do
                remaining = max(remaining, GetActiveProfessionCooldownRemaining(spellID))
            end
            snapshots[definition.id] = {
                spellID = observedSpellID,
                endTime = remaining > 0 and (now + remaining) or nil,
                observedAt = now,
            }
        end
    end

    for skillLineID in pairs(observedKnownSpellSkillLines) do
        scans[skillLineID] = now
    end

    -- 按专业增量更新：打开珠宝窗口不能清掉炼金或裁缝已经记录的冷却。
    -- 只有打开对应专业窗口或检测到已知配方时，才更新该专业的状态。
    -- 换专业后的旧快照会由当前专业列表在展示层过滤，不在登录早期破坏性删除。
    local hasProfessionSnapshot = #(stored.professions or {}) > 0
    if hasProfessionSnapshot or scannedSkillLineID or next(snapshots) then
        stored.professionCooldowns = snapshots
        stored.professionCooldownScans = scans
        stored.professionCooldownsUpdatedAt = now
        return true
    end
    return false
end

local function GetQuestResetAt(resetType, now)
    local getSeconds
    if C_DateAndTime then
        if resetType == "daily" then
            getSeconds = C_DateAndTime.GetSecondsUntilDailyReset
        else
            getSeconds = C_DateAndTime.GetSecondsUntilWeeklyReset
        end
    end
    if not getSeconds then
        if resetType == "daily" and BG.GetNextDayTime then
            local seconds, resetAt = BG.GetNextDayTime()
            return tonumber(resetAt) or (tonumber(seconds) and now + tonumber(seconds) or nil)
        end
        return
    end

    local seconds = tonumber(getSeconds())
    if not seconds or seconds <= 0 then
        return
    end
    return now + seconds
end

local function RefreshLockoutDisplays()
    if updateOverviewFrame then
        updateOverviewFrame()
    elseif updateHoverFrame then
        updateHoverFrame()
    end
end

local function CaptureCurrentQuestProgress(turnedInQuestID)
    turnedInQuestID = tonumber(turnedInQuestID)
    local turnedInColumn = turnedInQuestID and questColumnByQuestID[turnedInQuestID] or nil
    if turnedInQuestID and not turnedInColumn then
        return false
    end

    local stored = GetOrCreateCurrentCharacterStore()
    if not stored then
        return false
    end

    local now = GetServerTime()
    stored.questCompletions = type(stored.questCompletions) == "table" and stored.questCompletions or {}

    if turnedInColumn then
        local resetAt = GetQuestResetAt(turnedInColumn.resetType, now)
        if not resetAt then
            return false
        end
        stored.questCompletions[turnedInColumn.id] = {
            questID = turnedInQuestID,
            resetAt = resetAt,
            updatedAt = now,
        }
        RefreshLockoutDisplays()
        return true
    end

    if not C_QuestLog or not C_QuestLog.IsQuestFlaggedCompleted then
        return false
    end

    local changed = false
    for _, column in ipairs(QUEST_COLUMNS) do
        local completedQuestID
        for _, questID in ipairs(column.questIDs) do
            if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                completedQuestID = questID
                break
            end
        end
        if completedQuestID then
            local resetAt = GetQuestResetAt(column.resetType, now)
            if resetAt then
                stored.questCompletions[column.id] = {
                    questID = completedQuestID,
                    resetAt = resetAt,
                    updatedAt = now,
                }
                changed = true
            end
        end
    end

    if changed then
        RefreshLockoutDisplays()
    end
    return true
end

local function CaptureCurrentResources()
    local stored = GetOrCreateCurrentCharacterStore()
    if not stored then
        return
    end

    stored.money = GetMoney and GetMoney() or stored.money
    local professions = CaptureCurrentProfessions()
    if professions then
        stored.professions = professions
    end
    CaptureCurrentProfessionCooldowns(stored)
    stored.trinkets = CaptureEquippedTrinkets()
    stored.legendaryFragmentItems = CaptureLegendaryFragmentItems()
    stored.legendaryUpgradeItems = CaptureLegendaryUpgradeItems()
    stored.legendaryItems = MergeItemSnapshots(
        CaptureEquippedAndBagLegendaries(),
        stored.bankLegendaryItems
    )
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(TITAN_EMBER_CURRENCY_ID)
        -- 登录早期可能暂时拿不到货币资料；此时保留旧快照，不能用 0 覆盖。
        if info then
            stored.titanEmbers = info.quantity
            stored.titanEmbersEarnedThisWeek = info.quantityEarnedThisWeek
            stored.titanEmbersWeeklyMax = info.maxWeeklyQuantity
            stored.titanEmberIconFileID = info.iconFileID
            currencyIconCache[TITAN_EMBER_CURRENCY_ID] = info.iconFileID
        end

        info = C_CurrencyInfo.GetCurrencyInfo(TITAN_SHARD_CURRENCY_ID)
        if info then
            stored.titanShards = info.quantity
            stored.titanShardIconFileID = info.iconFileID
            currencyIconCache[TITAN_SHARD_CURRENCY_ID] = info.iconFileID
        end
    end
    stored.resourcesUpdatedAt = GetServerTime()

    if updateHoverFrame then
        updateHoverFrame()
    end
end

local function CaptureCurrentBankLegendaries()
    if not BANK_CONTAINER then
        return
    end
    local stored = GetOrCreateCurrentCharacterStore()
    if not stored then
        return
    end

    local items = {}
    CollectLegendaryFromContainer(BANK_CONTAINER, items)
    local purchasedBankBags = GetNumBankSlots and GetNumBankSlots() or NUM_BANKBAGSLOTS or 0
    for bankBagIndex = 1, purchasedBankBags do
        CollectLegendaryFromContainer(NUM_BAG_SLOTS + bankBagIndex, items)
    end
    stored.bankLegendaryItems = MergeItemSnapshots(items)
    stored.bankResourcesUpdatedAt = GetServerTime()
    CaptureCurrentResources()
end

local resourceRefreshSerial = 0

local function CaptureAvailableResources()
    if BankFrame and BankFrame:IsShown() then
        CaptureCurrentBankLegendaries()
    else
        CaptureCurrentResources()
    end
end

local function ScheduleResourceRefresh(delay)
    resourceRefreshSerial = resourceRefreshSerial + 1
    local serial = resourceRefreshSerial
    BG.After(delay or 0.2, function()
        if serial ~= resourceRefreshSerial then
            return
        end
        CaptureAvailableResources()
    end)
end

local professionCooldownRefreshSerial = 0
local function ScheduleProfessionCooldownRefresh(delay)
    professionCooldownRefreshSerial = professionCooldownRefreshSerial + 1
    local serial = professionCooldownRefreshSerial
    BG.After(delay or 0.5, function()
        if serial ~= professionCooldownRefreshSerial then
            return
        end
        local stored = GetOrCreateCurrentCharacterStore()
        if stored and CaptureCurrentProfessionCooldowns(stored) then
            RefreshLockoutDisplays()
        end
    end)
end

local function GetCharacterSpecIcon(character)
    local classIcons = BG.talentIcon and BG.talentIcon[character.classFile]
    return classIcons and character.specIndex and classIcons[character.specIndex] or nil
end

local function GetCharacterDisplayName(character, valueType)
    local color = character.classFile and select(4, GetClassColor(character.classFile)) or "ffffffff"
    local specIcon = GetCharacterSpecIcon(character)
    local text = specIcon and ("|T" .. specIcon .. ":14:14:0:0|t ") or ""
    text = text .. "|c" .. color .. character.name .. "|r"
    local value = valueType == "level" and character.level or character.itemLevel
    if value and value > 0 then
        text = text .. " |cffb3b3b3(" .. floor(value + 0.5) .. ")|r"
    end
    return text
end

local function BuildCharacterRows(realmID)
    ClearExpiredRaidData()
    local realm = GetRealmStore(realmID, false)
    local characters = {}
    local currentRealmID = GetCurrentRealmID()
    local currentName = GetCurrentCharacterName()

    if realm then
        for name, stored in pairs(realm.characters) do
            if type(stored) == "table" and type(name) == "string" then
                local character = {
                    name = stored.name or name,
                    classFile = stored.classFile,
                    specIndex = stored.specIndex,
                    level = tonumber(stored.level),
                    itemLevel = stored.itemLevel,
                    order = tonumber(stored.order) or math.huge,
                    lastRecordedAt = stored.lastRecordedAt,
                    money = tonumber(stored.money),
                    titanEmbers = tonumber(stored.titanEmbers),
                    titanEmbersEarnedThisWeek = tonumber(stored.titanEmbersEarnedThisWeek),
                    titanEmbersWeeklyMax = tonumber(stored.titanEmbersWeeklyMax),
                    titanEmberIconFileID = stored.titanEmberIconFileID,
                    titanShards = tonumber(stored.titanShards),
                    titanShardIconFileID = stored.titanShardIconFileID,
                    professions = type(stored.professions) == "table" and stored.professions or {},
                    legendaryItems = type(stored.legendaryItems) == "table" and stored.legendaryItems or {},
                    legendaryFragmentItems = type(stored.legendaryFragmentItems) == "table"
                        and stored.legendaryFragmentItems or {},
                    legendaryUpgradeItems = type(stored.legendaryUpgradeItems) == "table"
                        and stored.legendaryUpgradeItems or {},
                    trinkets = type(stored.trinkets) == "table" and stored.trinkets or {},
                    resourcesUpdatedAt = tonumber(stored.resourcesUpdatedAt),
                    bankResourcesUpdatedAt = tonumber(stored.bankResourcesUpdatedAt),
                    instances = type(stored.instances) == "table" and stored.instances or {},
                    questCompletions = type(stored.questCompletions) == "table"
                        and stored.questCompletions or {},
                    professionCooldowns = type(stored.professionCooldowns) == "table"
                        and stored.professionCooldowns or {},
                    professionCooldownsUpdatedAt = tonumber(stored.professionCooldownsUpdatedAt),
                    professionCooldownScans = type(stored.professionCooldownScans) == "table"
                        and stored.professionCooldownScans or {},
                    ready = true,
                    isHidden = stored.isHidden and true or false,
                    isCurrent = realmID == currentRealmID and name == currentName,
                }
                character.displayName = GetCharacterDisplayName(character)
                characters[#characters + 1] = character
            end
        end
    end

    sort(characters, function(a, b)
        if a.order == b.order then
            return a.name < b.name
        end
        return a.order < b.order
    end)
    return characters
end

local function GetCharacterRows()
    local visibleCharacters = {}
    for _, character in ipairs(BuildCharacterRows(GetCurrentRealmID())) do
        if not character.isHidden then
            visibleCharacters[#visibleCharacters + 1] = character
        end
    end
    return visibleCharacters
end

local function GetRaidCharacterRows(characters)
    local raidCharacters = {}
    for _, character in ipairs(characters) do
        -- 旧快照可能暂时没有等级；只有明确低于 80 级时才过滤，避免升级数据上线后整表突然消失。
        if not character.level or character.level >= RAID_MIN_LEVEL then
            raidCharacters[#raidCharacters + 1] = character
        end
    end
    return raidCharacters
end

local function FormatResetTime(seconds)
    seconds = max(0, floor(seconds or 0))
    local days = floor(seconds / 86400)
    local hours = floor(seconds % 86400 / 3600)
    local minutes = floor(seconds % 3600 / 60)

    if days > 0 then
        return days .. L["天"] .. hours .. L["小时"]
    elseif hours > 0 then
        return hours .. L["小时"] .. minutes .. L["分钟"]
    else
        return minutes .. L["分钟"]
    end
end

local function FormatCompactCooldownTime(seconds)
    seconds = max(0, floor(seconds or 0))
    local days = floor(seconds / 86400)
    local hours = floor(seconds % 86400 / 3600)
    local minutes = floor(seconds % 3600 / 60)
    if days > 0 then
        return days .. L["天"] .. hours .. L["小时"]
    elseif hours > 0 then
        return hours .. L["小时"]
    end
    return max(1, minutes) .. L["分钟"]
end

local function GetProfessionCooldownSummary(character, now)
    now = now or GetServerTime()
    local cooldowns = character.professionCooldowns or {}
    local summary = {
        entries = {},
        total = 0,
        ready = 0,
        cooling = 0,
        earliestEndTime = nil,
        unknown = false,
        unknownProfessions = {},
    }

    local learnedSkillLines = {}
    for _, profession in ipairs(character.professions or {}) do
        local skillLineID = tonumber(profession.skillLineID)
        if skillLineID then
            learnedSkillLines[skillLineID] = true
        end
    end
    local hasProfessionSnapshot = next(learnedSkillLines) ~= nil

    for _, definition in ipairs(PROFESSION_COOLDOWN_DEFINITIONS) do
        local snapshot = cooldowns[definition.id]
        if snapshot and (not hasProfessionSnapshot or learnedSkillLines[definition.skillLineID]) then
            local endTime = tonumber(snapshot.endTime)
            local isReady = not endTime or endTime <= now
            summary.total = summary.total + 1
            summary.ready = summary.ready + (isReady and 1 or 0)
            summary.cooling = summary.cooling + (isReady and 0 or 1)
            if not isReady and (not summary.earliestEndTime or endTime < summary.earliestEndTime) then
                summary.earliestEndTime = endTime
            end
            summary.entries[#summary.entries + 1] = {
                definition = definition,
                snapshot = snapshot,
                isReady = isReady,
                remaining = isReady and 0 or (endTime - now),
            }
        end
    end
    local scans = character.professionCooldownScans or {}
    local unknownProfessionSet = {}
    for _, profession in ipairs(character.professions or {}) do
        local skillLineID = tonumber(profession.skillLineID)
        if professionCooldownSkillLineSet[skillLineID] and not scans[skillLineID] then
            summary.unknown = true
            local professionName = professionCooldownProfessionNameBySkillLineID[skillLineID]
            if professionName and not unknownProfessionSet[professionName] then
                unknownProfessionSet[professionName] = true
                summary.unknownProfessions[#summary.unknownProfessions + 1] = professionName
            end
        end
    end
    return summary
end

local function UpdateProfessionCooldownStatusDisplay(status, character)
    status.check:Hide()
    status.text:SetText("")
    if status.background then
        status.background:SetColorTexture(unpack(status.baseColor or { 0, 0, 0, 0 }))
    end

    local summary = GetProfessionCooldownSummary(character)
    if summary.unknown then
        status.text:SetText("?")
        status.text:SetTextColor(unpack(COLOR.textMuted))
    elseif summary.total == 0 then
        return
    elseif summary.ready == summary.total then
        status.check:Show()
        if status.background then
            status.background:SetColorTexture(unpack(COLOR.complete))
        end
    else
        if summary.ready > 0 then
            status.text:SetFormattedText("%d/%d", summary.ready, summary.total)
        else
            status.text:SetText(FormatCompactCooldownTime(summary.earliestEndTime - GetServerTime()))
        end
        status.text:SetTextColor(unpack(COLOR.warning))
        if status.background then
            status.background:SetColorTexture(unpack(COLOR.partial))
        end
    end
end

local function ShowProfessionCooldownTooltip(cell)
    local character = cell and cell.character
    if not character or not GameTooltip then
        return
    end

    local summary = GetProfessionCooldownSummary(character)
    if summary.total == 0 and not summary.unknown then
        return
    end

    local anchor = BG.ButtonIsInRight(cell) and "ANCHOR_LEFT" or "ANCHOR_RIGHT"
    GameTooltip:SetOwner(cell, anchor, 0, 0)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L["专业制造"] .. "（" .. character.name .. "）", 0.95, 0.67, 0.29)
    if #summary.entries > 0 then
        local previousProfession
        for _, entry in ipairs(summary.entries) do
            local definition = entry.definition
            if definition.professionName ~= previousProfession then
                if previousProfession then
                    GameTooltip:AddLine(" ")
                end
                GameTooltip:AddLine(definition.professionName, 1, 0.82, 0)
                previousProfession = definition.professionName
            end
            if entry.isReady then
                GameTooltip:AddDoubleLine(
                    definition.name,
                    L["可制造"],
                    0.9, 0.9, 0.9,
                    0.2, 1, 0.2
                )
            else
                GameTooltip:AddDoubleLine(
                    definition.name,
                    FormatResetTime(entry.remaining),
                    0.9, 0.9, 0.9,
                    1, 0.68, 0.18
                )
            end
        end
    end
    if summary.unknown then
        if #summary.entries > 0 then
            GameTooltip:AddLine(" ")
        end
        GameTooltip:AddLine(L["尚未扫描以下专业："], 0.9, 0.9, 0.9)
        for _, professionName in ipairs(summary.unknownProfessions) do
            GameTooltip:AddLine("  " .. professionName, 1, 0.82, 0)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["如何记录"], 1, 0.82, 0)
        GameTooltip:AddLine(L["登录该角色后，打开一次上述专业的制造窗口。"], 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine(L["首次扫描完成后会自动保存，以后无需重复打开。"], 0.55, 0.75, 0.55, true)
    end
    GameTooltip:Show()
end

local function GetRaidResetTime()
    ClearExpiredRaidData()
    local nextResetAt = GetDataStore().nextResetAt
    if nextResetAt and nextResetAt > GetServerTime() then
        return nextResetAt - GetServerTime()
    end
end


local function GetOverviewResetTime()
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
        local seconds = tonumber(C_DateAndTime.GetSecondsUntilWeeklyReset())
        if seconds and seconds > 0 then
            return seconds
        end
    end
    return GetRaidResetTime()
end

local function GetPrimaryLockout(lockouts)
    local primary
    for _, lockout in ipairs(lockouts or {}) do
        if not primary or lockout.killedCount > primary.killedCount then
            primary = lockout
        end
    end
    return primary
end

local function UpdateStatusDisplay(status, character, lockout, compact, blankWhenAvailable)
    status.check:Hide()

    if status.background then
        if status.baseColor then
            status.background:SetColorTexture(unpack(status.baseColor))
        else
            status.background:SetColorTexture(0, 0, 0, 0)
        end
    end

    if not character.ready then
        status.text:SetText("…")
        status.text:SetTextColor(unpack(COLOR.textMuted))
    elseif not lockout then
        status.text:SetText(blankWhenAvailable and "" or "—")
        status.text:SetTextColor(unpack(COLOR.textMuted))
    elseif compact then
        status.text:SetText("")
        if (lockout.killedCount or 0) > 0 then
            status.check:Show()
            if status.background then
                status.background:SetColorTexture(unpack(COLOR.complete))
            end
        end
    elseif lockout.numEncounters == 0 or lockout.killedCount >= lockout.numEncounters then
        status.text:SetText("")
        status.check:Show()
        if status.background then
            status.background:SetColorTexture(unpack(COLOR.complete))
        end
    else
        status.text:SetFormattedText("%d/%d", lockout.killedCount, lockout.numEncounters)
        if status.background then
            status.text:SetTextColor(unpack(COLOR.warning))
            status.background:SetColorTexture(unpack(COLOR.partial))
        else
            status.text:SetTextColor(unpack(COLOR.warning))
        end
    end
end

local function UpdateQuestStatusDisplay(status, character, column)
    status.check:Hide()
    status.text:SetText("")

    if status.background then
        if status.baseColor then
            status.background:SetColorTexture(unpack(status.baseColor))
        else
            status.background:SetColorTexture(0, 0, 0, 0)
        end
    end

    if character.ready
        and character.questCompletions
        and character.questCompletions[column.id]
    then
        status.check:Show()
        if status.background then
            status.background:SetColorTexture(unpack(COLOR.complete))
        end
    end
end

local function CreateStatusDisplay(parent, width, height, checkSize, fontSize, styled)
    local status = CreateFrame("Frame", nil, parent, styled and "BackdropTemplate" or nil)
    status:SetSize(width, height)

    if styled then
        local background = status:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(0, 0, 0, 0)
        status.background = background

        local rightBorder = status:CreateTexture(nil, "BORDER")
        rightBorder:SetPoint("TOPRIGHT")
        rightBorder:SetPoint("BOTTOMRIGHT")
        rightBorder:SetWidth(1)
        rightBorder:SetColorTexture(unpack(COLOR.grid))

        local bottomBorder = status:CreateTexture(nil, "BORDER")
        bottomBorder:SetPoint("BOTTOMLEFT")
        bottomBorder:SetPoint("BOTTOMRIGHT")
        bottomBorder:SetHeight(1)
        bottomBorder:SetColorTexture(unpack(COLOR.grid))
    end

    local text = status:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetAllPoints()
    text:SetJustifyH("CENTER")
    if fontSize then
        text:SetFont(BIAOGE_TEXT_FONT, fontSize, "OUTLINE")
    end
    status.text = text

    local check = status:CreateTexture(nil, "OVERLAY")
    check:SetSize(checkSize or 18, checkSize or 18)
    check:SetPoint("CENTER")
    check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    check:Hide()
    status.check = check

    return status
end

local function CaptureRaidInfo()
    ClearExpiredRaidData()
    RefreshCurrentCharacterIdentity()
    local instances = {}
    local capturedAt = GetServerTime()
    local nextResetAt

    for index = 1, GetNumSavedInstances() do
        local _, _, resetTime, _, locked, _, _, _, _,
        difficultyName, numEncounters, _, _, instanceID = GetSavedInstanceInfo(index)

        if locked and raidByID[instanceID] then
            local bosses = {}
            local killedCount = 0

            for encounterIndex = 1, (numEncounters or 0) do
                local bossName, _, isKilled = GetSavedInstanceEncounterInfo(index, encounterIndex)
                bosses[#bosses + 1] = {
                    name = bossName or UNKNOWN,
                    killed = isKilled and true or false,
                }
                if isKilled then
                    killedCount = killedCount + 1
                end
            end

            instances[instanceID] = instances[instanceID] or {}
            instances[instanceID][#instances[instanceID] + 1] = {
                bosses = bosses,
                difficultyName = difficultyName or UNKNOWN,
                killedCount = killedCount,
                numEncounters = numEncounters or 0,
                resetAt = resetTime and resetTime > 0 and (capturedAt + resetTime) or nil,
            }
            if resetTime and resetTime > 0 then
                local candidate = capturedAt + resetTime
                if not nextResetAt or candidate < nextResetAt then
                    nextResetAt = candidate
                end
            end
        end
    end

    currentCharacter.instances = instances
    currentCharacter.ready = true
    currentCharacter.refreshing = false
    currentCharacter.updatedAt = date("%H:%M:%S")

    local stored = GetOrCreateCurrentCharacterStore()
    if stored then
        stored.lastRecordedAt = capturedAt
        stored.instances = instances
    end

    if nextResetAt then
        GetDataStore().nextResetAt = nextResetAt
    end

    if updateOverviewFrame then
        updateOverviewFrame()
    elseif updateHoverFrame then
        updateHoverFrame()
    end
    if BG.RefreshRaidLockoutCharacterOptions then
        BG.RefreshRaidLockoutCharacterOptions()
    end
end

local function RequestCurrentRaidInfo()
    ClearExpiredRaidData()
    if currentCharacter.refreshing then
        return
    end

    currentCharacter.refreshing = true
    currentCharacter.requestSerial = currentCharacter.requestSerial + 1
    currentCharacter.lastRequestAt = GetTime()
    local requestSerial = currentCharacter.requestSerial

    if updateOverviewFrame then
        updateOverviewFrame()
    elseif updateHoverFrame then
        updateHoverFrame()
    end

    RequestRaidInfo()

    -- 极少数情况下事件可能丢失；超时后直接读取游戏当前缓存，避免界面一直转圈。
    BG.After(2, function()
        if currentCharacter.refreshing and currentCharacter.requestSerial == requestSerial then
            CaptureRaidInfo()
        end
    end)
end

local function ShowLockoutTooltip(cell)
    local character = cell.character
    local lockouts = character.instances[cell.raid.id]

    GameTooltip:SetOwner(cell, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(cell.raid.name .. "（" .. character.name .. "）", 0, 0.75, 1)

    if not character.ready then
        GameTooltip:AddLine(L["尚未收到当前角色的团本锁定数据。"], 0.7, 0.7, 0.7, true)
    elseif not lockouts then
        GameTooltip:AddLine(L["未检测到团本锁定"], 0.55, 0.55, 0.55)
    else
        for lockoutIndex, lockout in ipairs(lockouts) do
            if lockoutIndex > 1 then
                GameTooltip:AddLine(" ")
            end

            GameTooltip:AddLine(lockout.difficultyName, 1, 0.82, 0)
            GameTooltip:AddDoubleLine(
                L["已击杀"],
                format("%d/%d", lockout.killedCount, lockout.numEncounters),
                1, 1, 1, 1, 1, 1
            )
            if lockout.resetAt and lockout.resetAt > GetServerTime() then
                local remaining = max(0, lockout.resetAt - GetServerTime())
                GameTooltip:AddDoubleLine(
                    L["重置时间"],
                    FormatResetTime(remaining),
                    1, 1, 1, 1, 1, 1
                )
            end

            for _, boss in ipairs(lockout.bosses or {}) do
                GameTooltip:AddDoubleLine(
                    boss.name,
                    boss.killed and BOSS_DEAD or BOSS_ALIVE,
                    0.9, 0.9, 0.9,
                    boss.killed and 0.2 or 0.7,
                    boss.killed and 1 or 0.7,
                    boss.killed and 0.2 or 0.7
                )
            end
        end
    end

    GameTooltip:Show()
end

local function CreateOverviewFrame()
    if overviewFrame then
        return
    end

    local cellWidth = 76
    local nameWidth = 126
    local rowHeight = 34
    local headerGroupHeight = 18
    local headerSubHeight = 18
    local headerTopY = -66
    local rowsTopY = -111
    local width = 42 + nameWidth + cellWidth * #LOCKOUT_COLUMNS
    local headers = {}
    local groupHeaders = {}
    local rows = {}

    overviewFrame = CreateFrame("Frame", "BGForgeRaidLockoutOverviewFrame", UIParent, "BackdropTemplate")
    overviewFrame:SetSize(width, 180)
    overviewFrame:SetPoint("CENTER")
    overviewFrame:SetFrameStrata("DIALOG")
    overviewFrame:SetClampedToScreen(true)
    overviewFrame:SetMovable(true)
    overviewFrame:EnableMouse(true)
    overviewFrame:RegisterForDrag("LeftButton")
    overviewFrame:SetScript("OnDragStart", overviewFrame.StartMoving)
    overviewFrame:SetScript("OnDragStop", overviewFrame.StopMovingOrSizing)
    overviewFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    overviewFrame:SetBackdropColor(unpack(COLOR.panel))
    overviewFrame:SetBackdropBorderColor(unpack(COLOR.gridStrong))
    overviewFrame:Hide()
    tinsert(UISpecialFrames, overviewFrame:GetName())

    BG.CreateCloseButton(overviewFrame, 3, 3)

    local settings = CreateFrame("Button", nil, overviewFrame, "UIPanelButtonTemplate")
    settings:SetSize(64, 22)
    settings:SetPoint("TOPRIGHT", -31, -7)
    settings:SetText(L["设置"])
    settings:SetScript("OnClick", function()
        overviewFrame:Hide()
        if BG.OpenRaidLockoutOptions then
            BG.OpenRaidLockoutOptions()
        end
    end)

    local title = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText(L["所有角色团本锁定总览"])
    title:SetTextColor(unpack(COLOR.focusText))

    local subtitle = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    subtitle:SetText(L["汇总当前服务器下已在本机记录的角色本周团本进度"])
    subtitle:SetTextColor(unpack(COLOR.textSecondary))

    local refresh = CreateFrame("Button", nil, overviewFrame, "UIPanelButtonTemplate")
    refresh:SetSize(64, 22)
    refresh:SetPoint("BOTTOMRIGHT", -14, 12)
    refresh:SetText(REFRESH)
    refresh:SetScript("OnClick", function()
        CaptureCurrentQuestProgress()
        RequestCurrentRaidInfo()
    end)

    local startX = 20 + nameWidth
    local characterHeader = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    characterHeader:SetPoint("TOPLEFT", 20, headerTopY)
    characterHeader:SetWidth(nameWidth)
    characterHeader:SetHeight(headerGroupHeight + headerSubHeight)
    characterHeader:SetJustifyH("LEFT")
    characterHeader:SetTextColor(unpack(COLOR.focusText))

    for columnIndex, column in ipairs(LOCKOUT_COLUMNS) do
        local header = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetPoint("TOPLEFT", startX + (columnIndex - 1) * cellWidth, headerTopY)
        header:SetWidth(cellWidth)
        header:SetHeight(column.groupID and headerSubHeight or (headerGroupHeight + headerSubHeight))
        header:SetJustifyH("CENTER")
        header:SetText(column.name)
        header:SetTextColor(unpack(COLOR.focusText))
        headers[column.id] = header
    end
    for _, group in ipairs(QUEST_HEADER_GROUPS) do
        local header = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetHeight(headerGroupHeight)
        header:SetJustifyH("CENTER")
        header:SetText(group.name)
        header:SetTextColor(unpack(COLOR.focusText))
        header:Hide()
        groupHeaders[group.id] = header
    end

    local statusText = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("RIGHT", refresh, "LEFT", -8, 0)
    statusText:SetWidth(260)
    statusText:SetJustifyH("RIGHT")
    statusText:SetTextColor(unpack(COLOR.textSecondary))

    local function EnsureRow(rowIndex)
        if rows[rowIndex] then
            return rows[rowIndex]
        end

        local row = CreateFrame("Frame", nil, overviewFrame)
        row:SetSize(width - 40, rowHeight)
        row:SetPoint("TOPLEFT", 20, rowsTopY - (rowIndex - 1) * rowHeight)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(unpack(COLOR.current))
        highlight:Hide()
        row.highlight = highlight

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        name:SetPoint("LEFT")
        name:SetSize(nameWidth, rowHeight)
        name:SetJustifyH("LEFT")
        row.name = name
        row.cells = {}

        for _, column in ipairs(LOCKOUT_COLUMNS) do
            local cell = CreateStatusDisplay(row, cellWidth, rowHeight)
            cell:SetPoint("LEFT", nameWidth, 0)
            if column.isProfessionCooldown then
                cell:EnableMouse(true)
                cell:SetScript("OnEnter", ShowProfessionCooldownTooltip)
                cell:SetScript("OnLeave", GameTooltip_Hide)
            elseif not column.isQuest then
                cell:EnableMouse(true)
                cell.raid = column
                cell:SetScript("OnEnter", ShowLockoutTooltip)
                cell:SetScript("OnLeave", GameTooltip_Hide)
            end
            row.cells[column.id] = cell
        end

        rows[rowIndex] = row
        return row
    end

    updateOverviewFrame = function()
        local characters = GetCharacterRows()
        local visibleColumns = GetVisibleLockoutColumns()
        local rowCount = max(1, #characters)
        width = max(560, 42 + nameWidth + cellWidth * #visibleColumns)
        overviewFrame:SetWidth(width)
        characterHeader:SetFormattedText(L["角色列表（%d）"], #characters)

        for _, header in pairs(headers) do
            header:Hide()
        end
        for _, header in pairs(groupHeaders) do
            header:Hide()
        end
        local columnX = {}
        for columnIndex, column in ipairs(visibleColumns) do
            local header = headers[column.id]
            header:ClearAllPoints()
            local x = startX + (columnIndex - 1) * cellWidth
            columnX[column.id] = x
            header:SetHeight(column.groupID and headerSubHeight or (headerGroupHeight + headerSubHeight))
            header:SetPoint(
                "TOPLEFT",
                x,
                column.groupID and (headerTopY - headerGroupHeight) or headerTopY
            )
            header:Show()
        end
        for _, group in ipairs(GetVisibleQuestGroups(visibleColumns)) do
            local header = groupHeaders[group.id]
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", columnX[group.columns[1].id], headerTopY)
            header:SetWidth(cellWidth * #group.columns)
            header:Show()
        end

        for rowIndex, character in ipairs(characters) do
            local row = EnsureRow(rowIndex)
            row:Show()
            row:SetWidth(width - 40)
            row.name:SetText(GetCharacterDisplayName(character))
            row.highlight:SetShown(character.isCurrent)

            for _, cell in pairs(row.cells) do
                cell:Hide()
            end
            for columnIndex, column in ipairs(visibleColumns) do
                local cell = row.cells[column.id]
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", nameWidth + (columnIndex - 1) * cellWidth, 0)
                cell.character = character
                if column.isQuest then
                    UpdateQuestStatusDisplay(cell, character, column)
                elseif column.isProfessionCooldown then
                    UpdateProfessionCooldownStatusDisplay(cell, character)
                else
                    UpdateStatusDisplay(cell, character, GetPrimaryLockout(character.instances[column.id]), false)
                end
                cell:Show()
            end
        end

        for rowIndex = #characters + 1, #rows do
            rows[rowIndex]:Hide()
        end

        overviewFrame:SetHeight(154 + rowCount * rowHeight)

        if currentCharacter.refreshing then
            statusText:SetText(L["正在刷新当前角色的团本锁定…"])
        elseif currentCharacter.updatedAt then
            statusText:SetFormattedText(L["刷新时间：%s"], currentCharacter.updatedAt)
        else
            statusText:SetText(L["尚未收到当前角色的团本锁定数据。"])
        end

        if updateHoverFrame then
            updateHoverFrame()
        end
    end

    overviewFrame:SetScript("OnShow", function()
        CaptureCurrentQuestProgress()
        RequestCurrentRaidInfo()
    end)
    updateOverviewFrame()
end

local function CreateHoverFrame()
    if hoverFrame then
        return
    end

    local ui = SMALL_UI
    local headers = {}
    local groupHeaders = {}
    local rows = {}
    local width = 720
    local resourceTop = 0
    local resourceRowsTop = 0
    local contentFrame

    local function CreateTableCell(parent, backgroundColor, borders)
        local cell = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        cell:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
        })
        cell:SetBackdropColor(unpack(backgroundColor or COLOR.row))

        borders = borders or {}
        local function AddVerticalBorder(point)
            local line = cell:CreateTexture(nil, "BORDER")
            line:SetPoint("TOP" .. point)
            line:SetPoint("BOTTOM" .. point)
            line:SetWidth(1)
            line:SetColorTexture(unpack(COLOR.grid))
        end
        local function AddHorizontalBorder(point)
            local line = cell:CreateTexture(nil, "BORDER")
            line:SetPoint(point .. "LEFT")
            line:SetPoint(point .. "RIGHT")
            line:SetHeight(1)
            line:SetColorTexture(unpack(COLOR.grid))
        end

        if borders.left then
            AddVerticalBorder("LEFT")
        end
        if borders.top then
            AddHorizontalBorder("TOP")
        end
        if borders.right ~= false then
            AddVerticalBorder("RIGHT")
        end
        if borders.bottom ~= false then
            AddHorizontalBorder("BOTTOM")
        end
        return cell
    end

    local function CreateCellText(cell, fontObject, size, color, justify)
        local text = cell:CreateFontString(nil, "ARTWORK", fontObject or "GameFontNormal")
        text:SetPoint("LEFT", 7, 0)
        text:SetPoint("RIGHT", -7, 0)
        text:SetJustifyH(justify or "LEFT")
        text:SetWordWrap(false)
        if size then
            text:SetFont(BIAOGE_TEXT_FONT, size, "OUTLINE")
        end
        if color then
            text:SetTextColor(unpack(color))
        end
        return text
    end

    local function CreateResourceNumberText(cell)
        local text = CreateCellText(cell, nil, nil, COLOR.gold, "CENTER")
        text:SetFont(RESOURCE_NUMBER_FONT, RESOURCE_NUMBER_FONT_SIZE, "OUTLINE")
        return text
    end

    local function GetItemQualityColor(quality)
        local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        if color then
            return color.r, color.g, color.b
        end
    end

    local function CreateItemTile(cell)
        local tile = CreateFrame("Frame", nil, cell, "BackdropTemplate")
        tile:SetSize(ITEM_TILE_SIZE, ITEM_TILE_SIZE)
        tile:SetFrameLevel(hoverFrame:GetFrameLevel() + 20)
        tile:EnableMouse(true)
        tile:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        tile:SetBackdropColor(unpack(COLOR.panel))

        local icon = tile:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tile.icon = icon

        local valueText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        valueText:SetPoint("TOPLEFT", 1, -1)
        valueText:SetJustifyH("LEFT")
        valueText:SetFont(BIAOGE_TEXT_FONT, 10, "OUTLINE")
        tile.valueText = valueText
        tile:SetScript("OnEnter", function(self)
            ShowItemTooltip(self, self.item)
        end)
        tile:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        return tile
    end

    local function RenderItemStrip(cell, tiles, items, valueKey, forcedQuality, valuePrefix)
        items = items or {}
        local visibleCount, startX, iconSize, gap = CalculateItemStripLayout(cell:GetWidth(), #items)
        for index = 1, visibleCount do
            local tile = tiles[index]
            if not tile then
                tile = CreateItemTile(cell)
                tiles[index] = tile
            end

            local item = items[index]
            tile.item = item
            tile:ClearAllPoints()
            tile:SetPoint("LEFT", cell, "LEFT", startX + (index - 1) * (iconSize + gap), 0)
            tile.icon:SetTexture(item.iconFileID)
            local quality, valueText = GetItemTileDisplay(item, valueKey, forcedQuality, valuePrefix)
            local red, green, blue = GetItemQualityColor(quality)
            if red then
                tile:SetBackdropBorderColor(red, green, blue, 1)
                tile.valueText:SetTextColor(red, green, blue)
                tile.valueText:SetText(valueText)
            else
                -- 物品品质尚未加载时不猜颜色，等 GET_ITEM_INFO_RECEIVED 后再刷新。
                tile:SetBackdropBorderColor(0, 0, 0, 0)
                tile.valueText:SetText("")
            end
            tile:Show()
        end
        for index = visibleCount + 1, #tiles do
            tiles[index]:Hide()
        end
    end

    local function RenderProfessionStrip(cell, tiles, professions)
        local visibleProfessions = {}
        for _, profession in ipairs(professions or {}) do
            if profession.iconFileID then
                visibleProfessions[#visibleProfessions + 1] = profession
            end
        end

        local visibleCount, startX, iconSize, gap = CalculateItemStripLayout(
            cell:GetWidth(),
            #visibleProfessions
        )
        for index = 1, visibleCount do
            local tile = tiles[index]
            if not tile then
                tile = CreateItemTile(cell)
                tiles[index] = tile
            end

            local iconFileID, rankText = GetProfessionTileDisplay(visibleProfessions[index])
            tile.item = nil
            tile:ClearAllPoints()
            tile:SetPoint("LEFT", cell, "LEFT", startX + (index - 1) * (iconSize + gap), 0)
            tile.icon:SetTexture(iconFileID)
            tile:SetBackdropBorderColor(unpack(PROFESSION_TILE_COLOR))
            tile.valueText:SetTextColor(unpack(PROFESSION_TILE_COLOR))
            tile.valueText:SetText(rankText)
            tile:Show()
        end
        for index = visibleCount + 1, #tiles do
            tiles[index]:Hide()
        end
    end

    local function SetCellColor(cell, color)
        cell:SetBackdropColor(unpack(color))
    end

    local function CreateRowHoverOverlay(cell, overlays)
        local overlay = cell:CreateTexture(nil, "ARTWORK", nil, -8)
        overlay:SetPoint("TOPLEFT", 1, -1)
        overlay:SetPoint("BOTTOMRIGHT", -1, 1)
        overlay:SetColorTexture(unpack(COLOR.rowHoverWash))
        overlay:SetAlpha(0)
        overlays[#overlays + 1] = overlay
    end

    local function SetRowHoverAlpha(controller, alpha)
        controller.hoverAlpha = alpha
        for _, overlay in ipairs(controller.hoverOverlays) do
            overlay:SetAlpha(alpha)
        end
    end

    local function SetRowHoverVisible(controller, visible)
        SetRowHoverAlpha(controller, visible and not controller.isCurrent and 1 or 0)
    end

    local function CreateRowHoverController(overlays)
        local controller = CreateFrame("Frame", nil, contentFrame)
        controller:SetFrameLevel(hoverFrame:GetFrameLevel() + 10)
        controller:EnableMouse(true)
        controller.hoverOverlays = overlays
        controller.hoverAlpha = 0
        controller:SetScript("OnEnter", function(self)
            hoverHideSerial = hoverHideSerial + 1
            SetRowHoverVisible(self, true)
        end)
        controller:SetScript("OnLeave", function(self)
            SetRowHoverVisible(self, false)
        end)
        return controller
    end

    local function ShowButtonTooltip(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(
            button.tooltipText,
            COLOR.textPrimary[1], COLOR.textPrimary[2], COLOR.textPrimary[3]
        )
        GameTooltip:Show()
    end

    local function SetIconButtonVisual(button, background, border, iconColor)
        button:SetBackdropColor(unpack(background))
        button:SetBackdropBorderColor(unpack(border))
        button.icon:SetVertexColor(unpack(iconColor))
    end

    local function SetIconButtonBorder(button, border)
        button:SetBackdropBorderColor(unpack(border))
    end

    local function CreateIconButton(texture, tooltipText)
        local button = CreateFrame("Button", nil, hoverFrame, "BackdropTemplate")
        button:SetSize(24, 24)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexture(texture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon
        SetIconButtonVisual(button, COLOR.headerStrong, COLOR.gridStrong, COLOR.textPrimary)
        button.tooltipText = tooltipText
        button:SetScript("OnEnter", function(self)
            SetIconButtonBorder(self, COLOR.focus)
            ShowButtonTooltip(self)
        end)
        button:SetScript("OnLeave", function(self)
            SetIconButtonBorder(self, COLOR.gridStrong)
            GameTooltip_Hide()
        end)
        button:SetScript("OnMouseDown", function(self, mouseButton)
            if mouseButton == "LeftButton" then
                SetIconButtonBorder(self, COLOR.focusText)
            end
        end)
        button:SetScript("OnMouseUp", function(self, mouseButton)
            if mouseButton == "LeftButton" then
                SetIconButtonBorder(self, COLOR.focus)
            end
        end)
        return button
    end

    hoverFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    hoverFrame:SetSize(width, 540)
    hoverFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    hoverFrame:SetClampedToScreen(true)
    hoverFrame:EnableMouse(true)
    hoverFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    hoverFrame:SetBackdropColor(unpack(COLOR.panel))
    hoverFrame:Hide()
    hoverFloatingFrameLevel = hoverFrame:GetFrameLevel()

    local innerBorder = CreateFrame("Frame", nil, hoverFrame, "BackdropTemplate")
    innerBorder:SetPoint("TOPLEFT", 6, -6)
    innerBorder:SetPoint("BOTTOMRIGHT", -6, 6)
    innerBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    innerBorder:SetBackdropBorderColor(unpack(COLOR.gridStrong))

    local contentScroll = CreateFrame("ScrollFrame", nil, hoverFrame)
    contentScroll:EnableMouseWheel(true)

    contentFrame = CreateFrame("Frame", nil, contentScroll)
    contentFrame:SetSize(width, 1)
    contentFrame:SetPoint("TOPLEFT")
    contentScroll:SetScrollChild(contentFrame)

    local horizontalScrollBar = CreateFrame("Slider", nil, hoverFrame)
    horizontalScrollBar:SetOrientation("HORIZONTAL")
    horizontalScrollBar:SetHeight(12)
    horizontalScrollBar:SetPoint("BOTTOMLEFT", ui.padding, ui.padding)
    horizontalScrollBar:SetPoint("BOTTOMRIGHT", -ui.padding, ui.padding)
    horizontalScrollBar:SetMinMaxValues(0, 0)
    horizontalScrollBar:SetValue(0)
    horizontalScrollBar:SetValueStep(1)
    horizontalScrollBar:EnableMouseWheel(true)

    local scrollTrack = horizontalScrollBar:CreateTexture(nil, "BACKGROUND")
    scrollTrack:SetPoint("LEFT", 0, 0)
    scrollTrack:SetPoint("RIGHT", 0, 0)
    scrollTrack:SetHeight(3)
    scrollTrack:SetColorTexture(unpack(COLOR.gridStrong))

    horizontalScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local scrollThumb = horizontalScrollBar:GetThumbTexture()
    scrollThumb:SetSize(32, 8)
    scrollThumb:SetColorTexture(unpack(COLOR.focus))

    horizontalScrollBar:SetScript("OnValueChanged", function(_, value)
        contentScroll:SetHorizontalScroll(value)
    end)
    local function ScrollHorizontally(_, delta)
        if not horizontalScrollBar:IsShown() then
            return
        end
        local minimum, maximum = horizontalScrollBar:GetMinMaxValues()
        local value = horizontalScrollBar:GetValue() - delta * 40
        horizontalScrollBar:SetValue(max(minimum, min(maximum, value)))
    end
    horizontalScrollBar:SetScript("OnMouseWheel", ScrollHorizontally)
    contentScroll:SetScript("OnMouseWheel", ScrollHorizontally)
    horizontalScrollBar:Hide()

    local headerMeasureText = hoverFrame:CreateFontString(nil, "ARTWORK")
    headerMeasureText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    headerMeasureText:SetWordWrap(false)
    headerMeasureText:SetAlpha(0)
    local function MeasureHeaderText(text)
        headerMeasureText:SetText(text or "")
        if headerMeasureText.GetUnboundedStringWidth then
            return headerMeasureText:GetUnboundedStringWidth()
        end
        return headerMeasureText:GetStringWidth()
    end

    local topBar = CreateTableCell(hoverFrame, COLOR.panelTop, { left = true, top = true })
    topBar:SetPoint("TOPLEFT", ui.padding, -ui.padding)
    topBar:SetSize(width - ui.padding * 2, ui.topBarHeight)

    local logo = topBar:CreateTexture(nil, "ARTWORK")
    logo:SetSize(22, 22)
    logo:SetPoint("LEFT", 8, 0)
    logo:SetTexture("Interface\\AddOns\\BGForge\\Media\\icon\\icon-128.tga")

    local brandTitle = topBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    brandTitle:SetPoint("LEFT", logo, "RIGHT", 7, 0)
    brandTitle:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    brandTitle:SetText("BGForge")
    brandTitle:SetTextColor(unpack(COLOR.gold))

    local titleDivider = topBar:CreateTexture(nil, "ARTWORK")
    titleDivider:SetPoint("LEFT", brandTitle, "RIGHT", 9, 0)
    titleDivider:SetSize(1, 15)
    titleDivider:SetColorTexture(unpack(COLOR.gridStrong))

    local title = topBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleDivider, "RIGHT", 9, 0)
    title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    title:SetText(L["全角色总览"])
    title:SetTextColor(unpack(COLOR.textPrimary))

    local close = CreateIconButton("Interface\\Buttons\\UI-Panel-MinimizeButton-Up", L["关闭"])
    close:SetPoint("TOPRIGHT", -ui.padding - 6, -ui.padding - 6)
    close:SetScript("OnClick", function()
        if hoverEmbedded and BG.ClickTabButton and BG.FBMainFrameTabNum then
            BG.ClickTabButton(BG.FBMainFrameTabNum)
        else
            hoverFrame:Hide()
        end
        GameTooltip:Hide()
    end)

    local settings = CreateIconButton("Interface\\Icons\\Trade_Engineering", L["设置"])
    settings:SetPoint("RIGHT", close, "LEFT", -5, 0)
    settings:SetScript("OnClick", function()
        if not hoverEmbedded then
            hoverFrame:Hide()
        end
        GameTooltip:Hide()
        if BG.OpenRaidLockoutOptions then
            BG.OpenRaidLockoutOptions()
        end
    end)

    local refresh = CreateIconButton("Interface\\Buttons\\UI-RotationRight-Button-Up", REFRESH)
    refresh:SetPoint("RIGHT", settings, "LEFT", -5, 0)
    refresh.icon:SetTexCoord(0, 1, 0, 1)
    refresh:SetScript("OnClick", function()
        CaptureCurrentResources()
        CaptureCurrentQuestProgress()
        RequestCurrentRaidInfo()
        BG.PlaySound(1)
    end)

    local resetText = topBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    resetText:SetPoint("RIGHT", refresh, "LEFT", -10, 0)
    resetText:SetWidth(245)
    resetText:SetJustifyH("RIGHT")
    resetText:SetWordWrap(false)
    resetText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    resetText:SetTextColor(unpack(COLOR.textSecondary))

    hoverFrame.chrome = {
        innerBorder = innerBorder,
        logo = logo,
        brandTitle = brandTitle,
        titleDivider = titleDivider,
        title = title,
        close = close,
        settings = settings,
        refresh = refresh,
    }

    local raidTitleCell = CreateTableCell(contentFrame, COLOR.headerStrong, { left = true })
    raidTitleCell:SetPoint("TOPLEFT", ui.padding, 0)
    raidTitleCell:SetSize(ui.nameWidth, ui.raidHeaderGroupHeight + ui.raidHeaderSubHeight)
    local raidTitleAccent = raidTitleCell:CreateTexture(nil, "ARTWORK")
    raidTitleAccent:SetPoint("TOPLEFT", 5, -5)
    raidTitleAccent:SetPoint("BOTTOMLEFT", 5, 5)
    raidTitleAccent:SetWidth(3)
    raidTitleAccent:SetColorTexture(unpack(COLOR.focus))
    local raidTitle = CreateCellText(raidTitleCell, "GameFontNormal", 12, COLOR.textPrimary, "LEFT")
    raidTitle:ClearAllPoints()
    raidTitle:SetPoint("LEFT", 14, 0)
    raidTitle:SetPoint("RIGHT", -7, 0)

    for _, column in ipairs(LOCKOUT_COLUMNS) do
        local header = CreateTableCell(contentFrame, COLOR.header)
        header:SetSize(
            column.compactWidth,
            column.groupID and ui.raidHeaderSubHeight
                or (ui.raidHeaderGroupHeight + ui.raidHeaderSubHeight)
        )
        local text = CreateCellText(header, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
        text:SetText(column.name)
        headers[column.id] = header
    end
    for _, group in ipairs(QUEST_HEADER_GROUPS) do
        local header = CreateTableCell(contentFrame, COLOR.headerStrong)
        header:SetSize(1, ui.raidHeaderGroupHeight)
        local text = CreateCellText(header, "GameFontNormal", 12, COLOR.focusText, "CENTER")
        text:SetText(group.name)
        header:Hide()
        groupHeaders[group.id] = header
    end

    local resourceTitleCell = CreateTableCell(contentFrame, COLOR.headerStrong, { left = true, top = true })
    resourceTitleCell:SetSize(ui.nameWidth, ui.resourceGroupHeight + ui.resourceSubHeaderHeight)
    local resourceAccent = resourceTitleCell:CreateTexture(nil, "ARTWORK")
    resourceAccent:SetPoint("TOPLEFT", 5, -5)
    resourceAccent:SetPoint("BOTTOMLEFT", 5, 5)
    resourceAccent:SetWidth(3)
    resourceAccent:SetColorTexture(unpack(COLOR.focus))
    local resourceTitle = CreateCellText(resourceTitleCell, "GameFontNormal", 12, COLOR.textPrimary, "LEFT")
    resourceTitle:ClearAllPoints()
    resourceTitle:SetPoint("LEFT", 14, 0)
    resourceTitle:SetPoint("RIGHT", -7, 0)

    local professionHeader = CreateTableCell(contentFrame, COLOR.headerStrong, { top = true })
    professionHeader:SetSize(ui.professionWidth, ui.resourceGroupHeight + ui.resourceSubHeaderHeight)
    local professionHeaderText = CreateCellText(professionHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    professionHeaderText:SetText(L["专业"])

    local equipmentHeader = CreateTableCell(contentFrame, COLOR.headerStrong, { top = true })
    equipmentHeader:SetSize(
        ui.legendaryWidth + ui.fragmentWidth + ui.upgradeWidth + ui.trinketWidth,
        ui.resourceGroupHeight
    )
    local equipmentHeaderText = CreateCellText(equipmentHeader, "GameFontNormal", 12, COLOR.focusText, "CENTER")
    equipmentHeaderText:SetText(L["装备"])

    local legendaryHeader = CreateTableCell(contentFrame, COLOR.header)
    legendaryHeader:SetSize(ui.legendaryWidth, ui.resourceSubHeaderHeight)
    local legendaryHeaderText = CreateCellText(legendaryHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    legendaryHeaderText:SetText(L["橙装"])

    local fragmentHeader = CreateTableCell(contentFrame, COLOR.header)
    fragmentHeader:SetSize(ui.fragmentWidth, ui.resourceSubHeaderHeight)
    local fragmentHeaderText = CreateCellText(fragmentHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    fragmentHeaderText:SetText(L["橙武碎片"])

    local upgradeHeader = CreateTableCell(contentFrame, COLOR.header)
    upgradeHeader:SetSize(ui.upgradeWidth, ui.resourceSubHeaderHeight)
    local upgradeHeaderText = CreateCellText(upgradeHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    upgradeHeaderText:SetText(L["升级物品"])

    local trinketHeader = CreateTableCell(contentFrame, COLOR.header)
    trinketHeader:SetSize(ui.trinketWidth, ui.resourceSubHeaderHeight)
    local trinketHeaderText = CreateCellText(trinketHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    trinketHeaderText:SetText(L["饰品"])

    local commonHeader = CreateTableCell(contentFrame, COLOR.headerStrong, { top = true })
    commonHeader:SetSize(ui.goldWidth + ui.emberWidth + ui.shardWidth, ui.resourceGroupHeight)
    local commonHeaderText = CreateCellText(commonHeader, "GameFontNormal", 12, COLOR.focusText, "CENTER")
    commonHeaderText:SetText(L["通用资源"])

    local goldHeader = CreateTableCell(contentFrame, COLOR.header)
    goldHeader:SetSize(ui.goldWidth, ui.resourceSubHeaderHeight)
    local goldHeaderText = CreateCellText(goldHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    goldHeaderText:SetText(L["金币"])

    local emberHeader = CreateTableCell(contentFrame, COLOR.header)
    emberHeader:SetSize(ui.emberWidth, ui.resourceSubHeaderHeight)
    local emberHeaderText = CreateCellText(emberHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    emberHeaderText:SetText(L["泰坦余烬"])

    local shardHeader = CreateTableCell(contentFrame, COLOR.header)
    shardHeader:SetSize(ui.shardWidth, ui.resourceSubHeaderHeight)
    local shardHeaderText = CreateCellText(shardHeader, "GameFontNormal", 12, COLOR.textSecondary, "CENTER")
    shardHeaderText:SetText(L["泰坦碎片"])

    local footerText = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footerText:SetJustifyH("LEFT")
    footerText:SetWordWrap(false)
    footerText:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    footerText:SetTextColor(unpack(COLOR.textMuted))

    local function EnsureRow(rowIndex)
        if rows[rowIndex] then
            return rows[rowIndex]
        end

        local row = {
            raidCells = {},
            raidHoverOverlays = {},
            resourceHoverOverlays = {},
        }

        row.raidNameCell = CreateTableCell(contentFrame, nil, { left = true })
        row.raidNameCell:SetSize(ui.nameWidth, ui.rowHeight)
        row.raidName = CreateCellText(row.raidNameCell, "GameFontHighlightSmall", 12, nil, "LEFT")
        row.raidName:ClearAllPoints()
        row.raidName:SetPoint("LEFT", 11, 0)
        row.raidName:SetPoint("RIGHT", -7, 0)
        row.raidCurrentAccent = row.raidNameCell:CreateTexture(nil, "ARTWORK")
        row.raidCurrentAccent:SetPoint("TOPLEFT", 1, -1)
        row.raidCurrentAccent:SetPoint("BOTTOMLEFT", 1, 1)
        row.raidCurrentAccent:SetWidth(2)
        row.raidCurrentAccent:SetColorTexture(unpack(COLOR.focus))
        row.raidCurrentAccent:Hide()
        CreateRowHoverOverlay(row.raidNameCell, row.raidHoverOverlays)

        for _, column in ipairs(LOCKOUT_COLUMNS) do
            local cell = CreateStatusDisplay(contentFrame, column.compactWidth, ui.rowHeight, 15, 11, true)
            cell.column = column
            CreateRowHoverOverlay(cell, row.raidHoverOverlays)
            if column.isProfessionCooldown then
                cell:SetFrameLevel(hoverFrame:GetFrameLevel() + 11)
                cell:EnableMouse(true)
                cell:SetScript("OnEnter", function(self)
                    hoverHideSerial = hoverHideSerial + 1
                    if row.raidHover then
                        SetRowHoverVisible(row.raidHover, true)
                    end
                    ShowProfessionCooldownTooltip(self)
                end)
                cell:SetScript("OnLeave", function()
                    if row.raidHover then
                        SetRowHoverVisible(row.raidHover, false)
                    end
                    GameTooltip:Hide()
                end)
            end
            row.raidCells[column.id] = cell
        end

        row.resourceNameCell = CreateTableCell(contentFrame, nil, { left = true })
        row.resourceNameCell:SetSize(ui.nameWidth, ui.rowHeight)
        row.resourceName = CreateCellText(row.resourceNameCell, "GameFontHighlightSmall", 12, nil, "LEFT")
        row.resourceName:ClearAllPoints()
        row.resourceName:SetPoint("LEFT", 11, 0)
        row.resourceName:SetPoint("RIGHT", -7, 0)
        row.resourceCurrentAccent = row.resourceNameCell:CreateTexture(nil, "ARTWORK")
        row.resourceCurrentAccent:SetPoint("TOPLEFT", 1, -1)
        row.resourceCurrentAccent:SetPoint("BOTTOMLEFT", 1, 1)
        row.resourceCurrentAccent:SetWidth(2)
        row.resourceCurrentAccent:SetColorTexture(unpack(COLOR.focus))
        row.resourceCurrentAccent:Hide()
        CreateRowHoverOverlay(row.resourceNameCell, row.resourceHoverOverlays)

        row.professionCell = CreateTableCell(contentFrame)
        row.professionCell:SetSize(ui.professionWidth, ui.rowHeight)
        row.professionTiles = {}
        CreateRowHoverOverlay(row.professionCell, row.resourceHoverOverlays)

        row.legendaryCell = CreateTableCell(contentFrame)
        row.legendaryCell:SetSize(ui.legendaryWidth, ui.rowHeight)
        row.legendaryTiles = {}
        CreateRowHoverOverlay(row.legendaryCell, row.resourceHoverOverlays)

        row.fragmentCell = CreateTableCell(contentFrame)
        row.fragmentCell:SetSize(ui.fragmentWidth, ui.rowHeight)
        row.fragmentTiles = {}
        CreateRowHoverOverlay(row.fragmentCell, row.resourceHoverOverlays)

        row.upgradeCell = CreateTableCell(contentFrame)
        row.upgradeCell:SetSize(ui.upgradeWidth, ui.rowHeight)
        row.upgradeTiles = {}
        CreateRowHoverOverlay(row.upgradeCell, row.resourceHoverOverlays)

        row.trinketCell = CreateTableCell(contentFrame)
        row.trinketCell:SetSize(ui.trinketWidth, ui.rowHeight)
        row.trinketTiles = {}
        CreateRowHoverOverlay(row.trinketCell, row.resourceHoverOverlays)

        row.goldCell = CreateTableCell(contentFrame)
        row.goldCell:SetSize(ui.goldWidth, ui.rowHeight)
        row.gold = CreateResourceNumberText(row.goldCell)
        CreateRowHoverOverlay(row.goldCell, row.resourceHoverOverlays)

        row.emberCell = CreateTableCell(contentFrame)
        row.emberCell:SetSize(ui.emberWidth, ui.rowHeight)
        row.ember = CreateResourceNumberText(row.emberCell)
        CreateRowHoverOverlay(row.emberCell, row.resourceHoverOverlays)

        row.shardCell = CreateTableCell(contentFrame)
        row.shardCell:SetSize(ui.shardWidth, ui.rowHeight)
        row.shard = CreateResourceNumberText(row.shardCell)
        CreateRowHoverOverlay(row.shardCell, row.resourceHoverOverlays)

        row.raidHover = CreateRowHoverController(row.raidHoverOverlays)
        row.resourceHover = CreateRowHoverController(row.resourceHoverOverlays)

        rows[rowIndex] = row
        return row
    end

    local totalNameCell = CreateTableCell(contentFrame, COLOR.header, { left = true })
    totalNameCell:SetSize(ui.nameWidth, ui.rowHeight)
    local totalName = CreateCellText(totalNameCell, "GameFontNormal", 12, COLOR.gold, "CENTER")
    totalName:SetText(L["合计"])

    local totalProfessionCell = CreateTableCell(contentFrame, COLOR.header)
    totalProfessionCell:SetSize(ui.professionWidth, ui.rowHeight)

    local totalLegendaryCell = CreateTableCell(contentFrame, COLOR.header)
    totalLegendaryCell:SetSize(ui.legendaryWidth, ui.rowHeight)

    local totalFragmentCell = CreateTableCell(contentFrame, COLOR.header)
    totalFragmentCell:SetSize(ui.fragmentWidth, ui.rowHeight)
    local totalFragmentTiles = {}

    local totalUpgradeCell = CreateTableCell(contentFrame, COLOR.header)
    totalUpgradeCell:SetSize(ui.upgradeWidth, ui.rowHeight)

    local totalTrinketCell = CreateTableCell(contentFrame, COLOR.header)
    totalTrinketCell:SetSize(ui.trinketWidth, ui.rowHeight)

    local totalGoldCell = CreateTableCell(contentFrame, COLOR.header)
    totalGoldCell:SetSize(ui.goldWidth, ui.rowHeight)
    local totalGold = CreateResourceNumberText(totalGoldCell)

    local totalEmberCell = CreateTableCell(contentFrame, COLOR.header)
    totalEmberCell:SetSize(ui.emberWidth, ui.rowHeight)
    local totalEmber = CreateResourceNumberText(totalEmberCell)

    local totalShardCell = CreateTableCell(contentFrame, COLOR.header)
    totalShardCell:SetSize(ui.shardWidth, ui.rowHeight)
    local totalShard = CreateResourceNumberText(totalShardCell)

    -- Titan's Lua compiler allows at most 60 upvalues per function. Keep the
    -- renderer's module dependencies behind one context so future columns do
    -- not silently push this already-large UI callback over that limit.
    local renderContext = {
        color = COLOR,
        calculateColumnWidths = CalculateRaidColumnWidths,
        calculateHorizontalViewport = CalculateHorizontalViewport,
        calculateMeasuredColumnMinimums = CalculateMeasuredColumnMinimums,
        calculateResourceColumnWidths = CalculateResourceColumnWidths,
        ensureRow = EnsureRow,
        formatResetTime = FormatResetTime,
        formatResourceAmount = FormatResourceAmount,
        formatResourceNumber = FormatResourceNumber,
        getCharacterDisplayName = GetCharacterDisplayName,
        getCharacterRows = GetCharacterRows,
        getCoinIconFile = GetCoinIconFile,
        getCurrencyIconFile = GetCurrencyIconFile,
        getOverviewResetTime = GetOverviewResetTime,
        getPrimaryLockout = GetPrimaryLockout,
        getRaidCharacterRows = GetRaidCharacterRows,
        getResourceIconMarkup = GetResourceIconMarkup,
        getVisibleColumns = GetVisibleLockoutColumns,
        getVisibleQuestGroups = GetVisibleQuestGroups,
        legendaryItemQuality = LEGENDARY_ITEM_QUALITY,
        locale = L,
        measureHeaderText = MeasureHeaderText,
        renderItemStrip = RenderItemStrip,
        renderProfessionStrip = RenderProfessionStrip,
        setCellColor = SetCellColor,
        setRowHoverAlpha = SetRowHoverAlpha,
        titanEmberCurrencyID = TITAN_EMBER_CURRENCY_ID,
        titanShardCurrencyID = TITAN_SHARD_CURRENCY_ID,
        updateStatusDisplay = UpdateStatusDisplay,
        updateQuestStatusDisplay = UpdateQuestStatusDisplay,
        updateProfessionCooldownStatusDisplay = UpdateProfessionCooldownStatusDisplay,
    }

    updateHoverFrame = function()
        local resourceCharacters = renderContext.getCharacterRows()
        local raidCharacters = renderContext.getRaidCharacterRows(resourceCharacters)
        local visibleColumns = renderContext.getVisibleColumns()
        local raidRowCount = max(1, #raidCharacters)
        local resourceRowCount = max(1, #resourceCharacters)
        local columnMinimums, compactColumnsWidth = renderContext.calculateMeasuredColumnMinimums(
            visibleColumns,
            renderContext.measureHeaderText
        )

        local compactEquipmentWidth = ui.legendaryWidth + ui.fragmentWidth
            + ui.upgradeWidth + ui.trinketWidth
        local compactCommonWidth = ui.goldWidth + ui.emberWidth + ui.shardWidth
        local compactResourceWidth = ui.nameWidth + ui.professionWidth
            + compactEquipmentWidth + compactCommonWidth
        width = max(
            660,
            ui.padding * 2 + ui.nameWidth + compactColumnsWidth,
            ui.padding * 2 + compactResourceWidth
        )
        local viewportWidth
        local horizontalOverflow
        if hoverEmbedded and BG.MainFrame then
            local availableWidth = max(320, BG.MainFrame:GetWidth() - ui.padding * 2)
            width = max(width, availableWidth)
            viewportWidth = availableWidth
            horizontalOverflow = max(0, width - viewportWidth)
        else
            viewportWidth, horizontalOverflow = renderContext.calculateHorizontalViewport(
                width,
                UIParent:GetWidth()
            )
        end
        local columnWidths, lockoutsWidth = renderContext.calculateColumnWidths(
            visibleColumns,
            width - ui.padding * 2 - ui.nameWidth,
            columnMinimums
        )
        local resourceColumnWidths, resourceColumnsWidth = renderContext.calculateResourceColumnWidths(
            ui,
            width - ui.padding * 2 - ui.nameWidth
        )
        local professionWidth = resourceColumnWidths.profession
        local legendaryWidth = resourceColumnWidths.legendary
        local fragmentWidth = resourceColumnWidths.fragment
        local upgradeWidth = resourceColumnWidths.upgrade
        local trinketWidth = resourceColumnWidths.trinket
        local goldWidth = resourceColumnWidths.gold
        local emberWidth = resourceColumnWidths.ember
        local shardWidth = resourceColumnWidths.shard
        local equipmentWidth = legendaryWidth + fragmentWidth + upgradeWidth + trinketWidth
        local commonWidth = goldWidth + emberWidth + shardWidth
        local resourceWidth = ui.nameWidth + resourceColumnsWidth
        hoverFrame:SetWidth(viewportWidth)
        topBar:SetWidth(viewportWidth - ui.padding * 2)
        contentScroll:ClearAllPoints()
        contentScroll:SetPoint("TOPLEFT", hoverFrame, "TOPLEFT", 0, -(ui.padding + ui.topBarHeight))
        contentScroll:SetWidth(viewportWidth)
        contentFrame:SetWidth(width)
        horizontalScrollBar:SetMinMaxValues(0, horizontalOverflow)
        if horizontalOverflow > 0 then
            local trackWidth = max(1, viewportWidth - ui.padding * 2)
            scrollThumb:SetWidth(max(32, trackWidth * viewportWidth / width))
            horizontalScrollBar:Show()
            horizontalScrollBar:SetValue(min(horizontalScrollBar:GetValue(), horizontalOverflow))
        else
            horizontalScrollBar:SetValue(0)
            horizontalScrollBar:Hide()
        end
        raidTitle:SetText(renderContext.locale["副本与任务（装等）"])
        resourceTitle:SetText(renderContext.locale["角色资源（等级）"])

        for _, header in pairs(headers) do
            header:Hide()
        end
        for _, header in pairs(groupHeaders) do
            header:Hide()
        end
        local raidOffsetX = ui.padding + ui.nameWidth
        local columnX = {}
        for _, column in ipairs(visibleColumns) do
            local header = headers[column.id]
            columnX[column.id] = raidOffsetX
            header:SetWidth(columnWidths[column.id])
            header:SetHeight(
                column.groupID and ui.raidHeaderSubHeight
                    or (ui.raidHeaderGroupHeight + ui.raidHeaderSubHeight)
            )
            header:ClearAllPoints()
            header:SetPoint(
                "TOPLEFT",
                raidOffsetX,
                -(column.groupID and ui.raidHeaderGroupHeight or 0)
            )
            header:Show()
            raidOffsetX = raidOffsetX + columnWidths[column.id]
        end
        for _, group in ipairs(renderContext.getVisibleQuestGroups(visibleColumns)) do
            local header = groupHeaders[group.id]
            local groupWidth = 0
            for _, column in ipairs(group.columns) do
                groupWidth = groupWidth + columnWidths[column.id]
            end
            header:SetWidth(groupWidth)
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", columnX[group.columns[1].id], 0)
            header:Show()
        end

        local resetTime = renderContext.getOverviewResetTime()
        if resetTime then
            resetText:SetFormattedText(
                renderContext.locale["周重置 %s"],
                renderContext.formatResetTime(resetTime)
            )
        else
            resetText:SetText("")
        end

        goldHeaderText:SetText(
            renderContext.locale["金币"]
                .. renderContext.getResourceIconMarkup(renderContext.getCoinIconFile())
        )
        emberHeaderText:SetText(renderContext.locale["泰坦余烬"] .. renderContext.getResourceIconMarkup(
            renderContext.getCurrencyIconFile(renderContext.titanEmberCurrencyID)
        ))
        shardHeaderText:SetText(renderContext.locale["泰坦碎片"] .. renderContext.getResourceIconMarkup(
            renderContext.getCurrencyIconFile(renderContext.titanShardCurrencyID)
        ))

        local raidRowsTop = ui.raidHeaderGroupHeight + ui.raidHeaderSubHeight
        resourceTop = raidRowsTop + raidRowCount * ui.rowHeight + ui.sectionGap
        resourceRowsTop = resourceTop + ui.resourceGroupHeight + ui.resourceSubHeaderHeight

        resourceTitleCell:ClearAllPoints()
        resourceTitleCell:SetPoint("TOPLEFT", ui.padding, -resourceTop)

        local professionX = ui.padding + ui.nameWidth
        professionHeader:SetWidth(professionWidth)
        professionHeader:ClearAllPoints()
        professionHeader:SetPoint("TOPLEFT", professionX, -resourceTop)

        local equipmentX = professionX + professionWidth
        equipmentHeader:SetWidth(equipmentWidth)
        equipmentHeader:ClearAllPoints()
        equipmentHeader:SetPoint("TOPLEFT", equipmentX, -resourceTop)
        legendaryHeader:SetWidth(legendaryWidth)
        legendaryHeader:ClearAllPoints()
        legendaryHeader:SetPoint("TOPLEFT", equipmentX, -(resourceTop + ui.resourceGroupHeight))
        fragmentHeader:SetWidth(fragmentWidth)
        fragmentHeader:ClearAllPoints()
        fragmentHeader:SetPoint(
            "TOPLEFT",
            equipmentX + legendaryWidth,
            -(resourceTop + ui.resourceGroupHeight)
        )
        upgradeHeader:SetWidth(upgradeWidth)
        upgradeHeader:ClearAllPoints()
        upgradeHeader:SetPoint(
            "TOPLEFT",
            equipmentX + legendaryWidth + fragmentWidth,
            -(resourceTop + ui.resourceGroupHeight)
        )
        trinketHeader:SetWidth(trinketWidth)
        trinketHeader:ClearAllPoints()
        trinketHeader:SetPoint(
            "TOPLEFT",
            equipmentX + legendaryWidth + fragmentWidth + upgradeWidth,
            -(resourceTop + ui.resourceGroupHeight)
        )

        local commonX = equipmentX + equipmentWidth
        commonHeader:SetWidth(commonWidth)
        commonHeader:ClearAllPoints()
        commonHeader:SetPoint("TOPLEFT", commonX, -resourceTop)
        goldHeader:SetWidth(goldWidth)
        goldHeader:ClearAllPoints()
        goldHeader:SetPoint("TOPLEFT", commonX, -(resourceTop + ui.resourceGroupHeight))
        emberHeader:SetWidth(emberWidth)
        emberHeader:ClearAllPoints()
        emberHeader:SetPoint("TOPLEFT", commonX + goldWidth, -(resourceTop + ui.resourceGroupHeight))
        shardHeader:SetWidth(shardWidth)
        shardHeader:ClearAllPoints()
        shardHeader:SetPoint(
            "TOPLEFT",
            commonX + goldWidth + emberWidth,
            -(resourceTop + ui.resourceGroupHeight)
        )

        for rowIndex, character in ipairs(raidCharacters) do
            local row = renderContext.ensureRow(rowIndex)
            local rowColor = character.isCurrent and renderContext.color.current
                or renderContext.color.row
            local rowY = raidRowsTop + (rowIndex - 1) * ui.rowHeight

            row.raidNameCell:Show()
            row.raidNameCell:ClearAllPoints()
            row.raidNameCell:SetPoint("TOPLEFT", ui.padding, -rowY)
            renderContext.setCellColor(row.raidNameCell, rowColor)
            row.raidName:SetText(renderContext.getCharacterDisplayName(character, "itemLevel"))
            if character.isCurrent then
                row.raidCurrentAccent:Show()
            else
                row.raidCurrentAccent:Hide()
            end

            for _, cell in pairs(row.raidCells) do
                cell:Hide()
            end
            local cellOffsetX = ui.padding + ui.nameWidth
            for _, column in ipairs(visibleColumns) do
                local cell = row.raidCells[column.id]
                cell:SetWidth(columnWidths[column.id])
                cell:ClearAllPoints()
                cell:SetPoint("TOPLEFT", cellOffsetX, -rowY)
                cell.character = character
                cell.baseColor = rowColor
                if column.isQuest then
                    renderContext.updateQuestStatusDisplay(cell, character, column)
                elseif column.isProfessionCooldown then
                    renderContext.updateProfessionCooldownStatusDisplay(cell, character)
                else
                    renderContext.updateStatusDisplay(
                        cell,
                        character,
                        renderContext.getPrimaryLockout(character.instances[column.id]),
                        true,
                        true
                    )
                end
                cell:Show()
                cellOffsetX = cellOffsetX + columnWidths[column.id]
            end
            row.raidHover:ClearAllPoints()
            row.raidHover:SetPoint("TOPLEFT", ui.padding, -rowY)
            row.raidHover:SetSize(ui.nameWidth + lockoutsWidth, ui.rowHeight)
            row.raidHover.isCurrent = character.isCurrent
            row.raidHover:Show()
        end

        local goldTotal = 0
        local emberTotal = 0
        local shardTotal = 0
        local fragmentTotalsByItemID = {}
        local fragmentTotals = {}
        local latestResourceRecord
        for rowIndex, character in ipairs(resourceCharacters) do
            local row = renderContext.ensureRow(rowIndex)
            local rowColor = character.isCurrent and renderContext.color.current
                or renderContext.color.row
            local resourceRowY = resourceRowsTop + (rowIndex - 1) * ui.rowHeight
            local professionX = ui.padding + ui.nameWidth
            local legendaryX = professionX + professionWidth
            local fragmentX = legendaryX + legendaryWidth
            local upgradeX = fragmentX + fragmentWidth
            local trinketX = upgradeX + upgradeWidth
            local goldX = trinketX + trinketWidth
            local emberX = goldX + goldWidth
            local shardX = emberX + emberWidth

            row.resourceNameCell:Show()
            row.resourceNameCell:ClearAllPoints()
            row.resourceNameCell:SetPoint("TOPLEFT", ui.padding, -resourceRowY)
            renderContext.setCellColor(row.resourceNameCell, rowColor)
            row.resourceName:SetText(renderContext.getCharacterDisplayName(character, "level"))
            if character.isCurrent then
                row.resourceCurrentAccent:Show()
            else
                row.resourceCurrentAccent:Hide()
            end

            row.professionCell:Show()
            row.professionCell:SetWidth(professionWidth)
            row.professionCell:ClearAllPoints()
            row.professionCell:SetPoint("TOPLEFT", professionX, -resourceRowY)
            renderContext.setCellColor(row.professionCell, rowColor)
            renderContext.renderProfessionStrip(row.professionCell, row.professionTiles, character.professions)

            row.legendaryCell:Show()
            row.legendaryCell:SetWidth(legendaryWidth)
            row.legendaryCell:ClearAllPoints()
            row.legendaryCell:SetPoint("TOPLEFT", legendaryX, -resourceRowY)
            renderContext.setCellColor(row.legendaryCell, rowColor)
            renderContext.renderItemStrip(
                row.legendaryCell,
                row.legendaryTiles,
                character.legendaryItems,
                "itemLevel",
                renderContext.legendaryItemQuality
            )

            row.fragmentCell:Show()
            row.fragmentCell:SetWidth(fragmentWidth)
            row.fragmentCell:ClearAllPoints()
            row.fragmentCell:SetPoint("TOPLEFT", fragmentX, -resourceRowY)
            renderContext.setCellColor(row.fragmentCell, rowColor)
            renderContext.renderItemStrip(
                row.fragmentCell,
                row.fragmentTiles,
                character.legendaryFragmentItems,
                "count",
                renderContext.legendaryItemQuality,
                "×"
            )

            row.upgradeCell:Show()
            row.upgradeCell:SetWidth(upgradeWidth)
            row.upgradeCell:ClearAllPoints()
            row.upgradeCell:SetPoint("TOPLEFT", upgradeX, -resourceRowY)
            renderContext.setCellColor(row.upgradeCell, rowColor)
            renderContext.renderItemStrip(
                row.upgradeCell,
                row.upgradeTiles,
                character.legendaryUpgradeItems,
                "count",
                renderContext.legendaryItemQuality,
                "×"
            )

            row.trinketCell:Show()
            row.trinketCell:SetWidth(trinketWidth)
            row.trinketCell:ClearAllPoints()
            row.trinketCell:SetPoint("TOPLEFT", trinketX, -resourceRowY)
            renderContext.setCellColor(row.trinketCell, rowColor)
            renderContext.renderItemStrip(row.trinketCell, row.trinketTiles, character.trinkets, "itemLevel")

            row.goldCell:Show()
            row.goldCell:SetWidth(goldWidth)
            row.goldCell:ClearAllPoints()
            row.goldCell:SetPoint("TOPLEFT", goldX, -resourceRowY)
            row.goldCell.character = character
            renderContext.setCellColor(row.goldCell, rowColor)
            local gold = character.money and floor(character.money / 10000) or nil
            row.gold:SetText(renderContext.formatResourceNumber(gold))

            row.emberCell:Show()
            row.emberCell:SetWidth(emberWidth)
            row.emberCell:ClearAllPoints()
            row.emberCell:SetPoint("TOPLEFT", emberX, -resourceRowY)
            row.emberCell.character = character
            renderContext.setCellColor(row.emberCell, rowColor)
            row.ember:SetText(renderContext.formatResourceNumber(character.titanEmbers))

            row.shardCell:Show()
            row.shardCell:SetWidth(shardWidth)
            row.shardCell:ClearAllPoints()
            row.shardCell:SetPoint("TOPLEFT", shardX, -resourceRowY)
            row.shardCell.character = character
            renderContext.setCellColor(row.shardCell, rowColor)
            row.shard:SetText(renderContext.formatResourceNumber(character.titanShards))

            row.resourceHover:ClearAllPoints()
            row.resourceHover:SetPoint("TOPLEFT", ui.padding, -resourceRowY)
            row.resourceHover:SetSize(resourceWidth, ui.rowHeight)
            row.resourceHover.isCurrent = character.isCurrent
            row.resourceHover:Show()

            goldTotal = goldTotal + (gold or 0)
            emberTotal = emberTotal + (character.titanEmbers or 0)
            shardTotal = shardTotal + (character.titanShards or 0)
            for _, item in ipairs(character.legendaryFragmentItems or {}) do
                local total = fragmentTotalsByItemID[item.itemID]
                if not total then
                    total = {
                        itemID = item.itemID,
                        link = item.link,
                        count = 0,
                        targetCount = item.targetCount,
                        iconFileID = item.iconFileID,
                        quality = renderContext.legendaryItemQuality,
                    }
                    fragmentTotalsByItemID[item.itemID] = total
                    fragmentTotals[#fragmentTotals + 1] = total
                end
                total.count = total.count + (tonumber(item.count) or 0)
            end
            if character.resourcesUpdatedAt
                and (not latestResourceRecord or character.resourcesUpdatedAt > latestResourceRecord) then
                latestResourceRecord = character.resourcesUpdatedAt
            end
        end

        for rowIndex = #raidCharacters + 1, #rows do
            local row = rows[rowIndex]
            row.raidNameCell:Hide()
            row.raidHover:Hide()
            renderContext.setRowHoverAlpha(row.raidHover, 0)
            for _, cell in pairs(row.raidCells) do
                cell:Hide()
            end
        end

        for rowIndex = #resourceCharacters + 1, #rows do
            local row = rows[rowIndex]
            row.resourceNameCell:Hide()
            row.professionCell:Hide()
            row.legendaryCell:Hide()
            row.fragmentCell:Hide()
            row.upgradeCell:Hide()
            row.trinketCell:Hide()
            row.goldCell:Hide()
            row.emberCell:Hide()
            row.shardCell:Hide()
            row.resourceHover:Hide()
            renderContext.setRowHoverAlpha(row.resourceHover, 0)
        end

        local totalY = resourceRowsTop + resourceRowCount * ui.rowHeight
        local professionX = ui.padding + ui.nameWidth
        local legendaryX = professionX + professionWidth
        local fragmentX = legendaryX + legendaryWidth
        local upgradeX = fragmentX + fragmentWidth
        local trinketX = upgradeX + upgradeWidth
        local goldX = trinketX + trinketWidth
        local emberX = goldX + goldWidth
        local shardX = emberX + emberWidth
        totalNameCell:ClearAllPoints()
        totalNameCell:SetPoint("TOPLEFT", ui.padding, -totalY)
        totalProfessionCell:SetWidth(professionWidth)
        totalProfessionCell:ClearAllPoints()
        totalProfessionCell:SetPoint("TOPLEFT", professionX, -totalY)
        totalLegendaryCell:SetWidth(legendaryWidth)
        totalLegendaryCell:ClearAllPoints()
        totalLegendaryCell:SetPoint("TOPLEFT", legendaryX, -totalY)
        totalFragmentCell:SetWidth(fragmentWidth)
        totalFragmentCell:ClearAllPoints()
        totalFragmentCell:SetPoint("TOPLEFT", fragmentX, -totalY)
        renderContext.renderItemStrip(
            totalFragmentCell,
            totalFragmentTiles,
            fragmentTotals,
            "count",
            renderContext.legendaryItemQuality,
            "×"
        )
        totalUpgradeCell:SetWidth(upgradeWidth)
        totalUpgradeCell:ClearAllPoints()
        totalUpgradeCell:SetPoint("TOPLEFT", upgradeX, -totalY)
        totalTrinketCell:SetWidth(trinketWidth)
        totalTrinketCell:ClearAllPoints()
        totalTrinketCell:SetPoint("TOPLEFT", trinketX, -totalY)
        totalGoldCell:SetWidth(goldWidth)
        totalGoldCell:ClearAllPoints()
        totalGoldCell:SetPoint("TOPLEFT", goldX, -totalY)
        totalEmberCell:SetWidth(emberWidth)
        totalEmberCell:ClearAllPoints()
        totalEmberCell:SetPoint("TOPLEFT", emberX, -totalY)
        totalShardCell:SetWidth(shardWidth)
        totalShardCell:ClearAllPoints()
        totalShardCell:SetPoint("TOPLEFT", shardX, -totalY)
        totalGold:SetText(renderContext.formatResourceAmount(goldTotal, renderContext.getCoinIconFile()))
        totalEmber:SetText(renderContext.formatResourceAmount(
            emberTotal,
            renderContext.getCurrencyIconFile(renderContext.titanEmberCurrencyID)
        ))
        totalShard:SetText(renderContext.formatResourceAmount(
            shardTotal,
            renderContext.getCurrencyIconFile(renderContext.titanShardCurrencyID)
        ))

        footerText:ClearAllPoints()
        footerText:SetPoint("TOPLEFT", ui.padding + 7, -(totalY + ui.rowHeight + 8))
        if latestResourceRecord then
            footerText:SetFormattedText(
                renderContext.locale["资源最后记录：%s"],
                date("%m-%d %H:%M", latestResourceRecord)
            )
        else
            footerText:SetText(renderContext.locale["资源尚未记录"])
        end

        local contentHeight = totalY + ui.rowHeight + ui.footerHeight
        contentFrame:SetHeight(contentHeight)
        contentScroll:SetHeight(contentHeight)
        hoverFrame:SetHeight(
            ui.padding + ui.topBarHeight + contentHeight + ui.padding
                + (horizontalOverflow > 0 and ui.horizontalScrollHeight or 0)
        )
    end

    updateHoverFrame()
end

local function SetEmbeddedChrome(isEmbedded)
    local chrome = hoverFrame and hoverFrame.chrome
    if not chrome then
        return
    end

    chrome.title:ClearAllPoints()
    chrome.refresh:ClearAllPoints()
    if isEmbedded then
        chrome.innerBorder:Hide()
        chrome.logo:Hide()
        chrome.brandTitle:Hide()
        chrome.titleDivider:Hide()
        chrome.close:Hide()
        chrome.settings:Hide()
        chrome.title:SetPoint("LEFT", 10, 0)
        chrome.refresh:SetPoint("TOPRIGHT", -SMALL_UI.padding - 6, -SMALL_UI.padding - 6)
    else
        chrome.innerBorder:Show()
        chrome.logo:Show()
        chrome.brandTitle:Show()
        chrome.titleDivider:Show()
        chrome.close:Show()
        chrome.settings:Show()
        chrome.title:SetPoint("LEFT", chrome.titleDivider, "RIGHT", 9, 0)
        chrome.refresh:SetPoint("RIGHT", chrome.settings, "LEFT", -5, 0)
    end
end

local function RestoreFloatingHoverFrame()
    if not hoverFrame then
        return
    end

    hoverEmbedded = false
    hoverFrame:Hide()
    hoverFrame:SetParent(UIParent)
    hoverFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    if hoverFloatingFrameLevel then
        hoverFrame:SetFrameLevel(hoverFloatingFrameLevel)
    end
    hoverFrame:SetClampedToScreen(true)
    hoverFrame:ClearAllPoints()
    hoverFrame:SetScript("OnEnter", nil)
    hoverFrame:SetScript("OnLeave", nil)
    SetEmbeddedChrome(false)
end

local function ShowEmbeddedOverview(parent)
    CreateHoverFrame()
    hoverHideSerial = hoverHideSerial + 1
    hoverAnchor = nil
    hoverEmbedded = true

    hoverFrame:Hide()
    hoverFrame:SetParent(parent)
    hoverFrame:SetFrameStrata(BG.MainFrame:GetFrameStrata())
    hoverFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    hoverFrame:SetClampedToScreen(false)
    hoverFrame:ClearAllPoints()
    hoverFrame:SetPoint("TOP", parent, "TOP", 0, -58)
    hoverFrame:SetScript("OnEnter", nil)
    hoverFrame:SetScript("OnLeave", nil)
    SetEmbeddedChrome(true)

    CaptureCurrentQuestProgress()
    CaptureCurrentResources()
    updateHoverFrame()
    hoverFrame:Show()

    if not currentCharacter.ready
        or not currentCharacter.lastRequestAt
        or GetTime() - currentCharacter.lastRequestAt > 15
    then
        RequestCurrentRaidInfo()
    end
end

local function PositionHoverFrame(anchor)
    RestoreFloatingHoverFrame()
    hoverFrame:ClearAllPoints()

    if BG.ButtonIsInRight(anchor) then
        if BG.ButtonIsInTop(anchor) then
            hoverFrame:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, 0)
        else
            hoverFrame:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", 0, 0)
        end
    elseif BG.ButtonIsInTop(anchor) then
        hoverFrame:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, 0)
    else
        hoverFrame:SetPoint("BOTTOMLEFT", anchor, "TOPRIGHT", 0, 0)
    end
end

local function IsPointerOver(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then
        return false
    end
    if frame.IsMouseOver then
        return frame:IsMouseOver()
    end
    return MouseIsOver and MouseIsOver(frame)
end

local function ScheduleHoverHide()
    if hoverEmbedded then
        return
    end
    hoverHideSerial = hoverHideSerial + 1
    local serial = hoverHideSerial
    BG.After(0.12, function()
        if serial ~= hoverHideSerial then
            return
        end
        if IsPointerOver(hoverAnchor) or IsPointerOver(hoverFrame) then
            return
        end
        if hoverFrame then
            hoverFrame:Hide()
        end
    end)
end

function BG.ShowRaidLockoutHover(anchor)
    if not anchor or hoverEmbedded then
        return
    end

    CreateHoverFrame()
    hoverHideSerial = hoverHideSerial + 1
    hoverAnchor = anchor
    PositionHoverFrame(anchor)
    CaptureCurrentQuestProgress()
    updateHoverFrame()
    hoverFrame:Show()
    hoverFrame:SetScript("OnEnter", function()
        hoverHideSerial = hoverHideSerial + 1
    end)
    hoverFrame:SetScript("OnLeave", ScheduleHoverHide)
    CaptureCurrentResources()

    if not currentCharacter.ready
        or not currentCharacter.lastRequestAt
        or GetTime() - currentCharacter.lastRequestAt > 15
    then
        RequestCurrentRaidInfo()
    end
end

function BG.HideRaidLockoutHover()
    if hoverFrame and not hoverEmbedded then
        ScheduleHoverHide()
    end
end

function BG.GetRaidLockoutDisplayChoices()
    local choices = {}
    for _, raid in ipairs(RAIDS) do
        choices[#choices + 1] = {
            id = raid.id,
            name = raid.name,
            optionKey = GetLockoutOptionKey(raid.id),
        }
    end
    for _, group in ipairs(QUEST_HEADER_GROUPS) do
        choices[#choices + 1] = {
            id = group.id,
            name = group.name,
            optionKey = GetQuestGroupOptionKey(group.id),
        }
    end
    return choices
end

function BG.GetRaidLockoutStoredCharacters(realmID)
    return BuildCharacterRows(realmID or GetCurrentRealmID())
end

function BG.SetRaidLockoutCharacterHidden(realmID, characterName, isHidden)
    realmID = realmID or GetCurrentRealmID()
    local realm = GetRealmStore(realmID, false)
    local character = realm and realm.characters[characterName]
    if type(character) ~= "table" then
        return false
    end

    character.isHidden = isHidden and true or nil
    BG.RefreshRaidLockoutDisplays()
    if BG.RefreshRaidLockoutCharacterOptions then
        BG.RefreshRaidLockoutCharacterOptions()
    end
    return true
end

function BG.DeleteRaidLockoutCharacter(realmID, characterName)
    realmID = realmID or GetCurrentRealmID()
    local realm = GetRealmStore(realmID, false)
    if not realm or not realm.characters[characterName] then
        return false
    end

    realm.characters[characterName] = nil
    if realmID == GetCurrentRealmID() and characterName == GetCurrentCharacterName() then
        deletedThisSession[GetCharacterKey(realmID, characterName)] = true
        currentCharacter.instances = {}
        currentCharacter.ready = true
    end

    BG.RefreshRaidLockoutDisplays()
    if BG.RefreshRaidLockoutCharacterOptions then
        BG.RefreshRaidLockoutCharacterOptions()
    end
    return true
end

function BG.RefreshRaidLockoutDisplays()
    if updateOverviewFrame then
        updateOverviewFrame()
    elseif updateHoverFrame then
        updateHoverFrame()
    end
end

local function CreateRaidLockoutMainFrame()
    if BG.RaidLockoutMainFrame then
        return BG.RaidLockoutMainFrame
    end

    local mainFrame = CreateFrame("Frame", "BG.RaidLockoutMainFrame", BG.MainFrame)
    mainFrame:SetAllPoints(BG.MainFrame)
    mainFrame:Hide()
    mainFrame:SetScript("OnShow", function(self)
        BG.FrameHide(0)
        BiaoGe.lastFrame = "RaidLockout"
        if BG.TabButtonsFB then
            BG.TabButtonsFB:Hide()
        end
        if BG.NanDuDropDown then
            BG.NanDuDropDown.DropDown:Hide()
        end
        ShowEmbeddedOverview(self)
    end)
    mainFrame:SetScript("OnHide", function()
        if hoverEmbedded then
            RestoreFloatingHoverFrame()
        end
    end)
    BG.RaidLockoutMainFrame = mainFrame
    return mainFrame
end

function BG.RoleOverviewUI()
    CreateRaidLockoutMainFrame()
end

function BG.ToggleRaidLockoutOverview()
    BG.HideRaidLockoutHover()
    local mainFrame = CreateRaidLockoutMainFrame()
    if BG.MainFrame and BG.ClickTabButton and BG.RaidLockoutMainFrameTabNum then
        if BG.MainFrame:IsVisible() and mainFrame:IsVisible() then
            BG.MainFrame:Hide()
        else
            BG.MainFrame:Show()
            BG.ClickTabButton(BG.RaidLockoutMainFrameTabNum)
        end
        return
    end

    -- Initialization fallback: the primary navigation is registered later in
    -- BiaoGe.lua. This path is only reachable if another addon invokes the API
    -- during that narrow window.
    CreateOverviewFrame()
    overviewFrame:SetShown(not overviewFrame:IsShown())
end

function BG.CreateRaidLockoutMainFrameTab()
    if BG.ButtonRaidLockout or not BG.Create_TabButton then
        return
    end

    local mainFrame = CreateRaidLockoutMainFrame()
    local button = BG.Create_TabButton(
        BG.RaidLockoutMainFrameTabNum or 2,
        L["角色总览"],
        mainFrame
    )
    BG.ButtonRaidLockout = button
end

BG.RegisterEvent("UPDATE_INSTANCE_INFO", CaptureRaidInfo)

BG.RegisterEvent("QUEST_TURNED_IN", function(_, _, questID)
    CaptureCurrentQuestProgress(questID)
end)

BG.RegisterEvent("ENCOUNTER_END", function(_, _, _, _, _, _, success)
    if success == 1 then
        BG.After(0.5, RequestCurrentRaidInfo)
    end
end)

BG.RegisterEvent({
    "CURRENCY_DISPLAY_UPDATE",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_LEVEL_UP",
    "PLAYER_MONEY",
    "SKILL_LINES_CHANGED",
}, function()
    ScheduleResourceRefresh(0.2)
end)

BG.RegisterEvent({ "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE" }, function()
    ScheduleProfessionCooldownRefresh(0.2)
end)

BG.RegisterEvent("SPELL_UPDATE_COOLDOWN", function()
    if not InCombatLockdown or not InCombatLockdown() then
        ScheduleProfessionCooldownRefresh(0.5)
    end
end)

BG.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, _, unitTarget, _, spellID)
    if unitTarget == "player" and professionCooldownDefinitionBySpellID[tonumber(spellID)] then
        ScheduleProfessionCooldownRefresh(0.8)
    end
end)

BG.RegisterEvent("BAG_UPDATE_DELAYED", function()
    ScheduleResourceRefresh(0.2)
end)

BG.RegisterEvent({ "BANKFRAME_OPENED", "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED" }, function()
    ScheduleResourceRefresh(0.2)
end)

BG.RegisterEvent("GET_ITEM_INFO_RECEIVED", function(_, _, _, success)
    if not success then
        return
    end
    ScheduleResourceRefresh(0.1)
end)

BG.Init2(function()
    SlashCmdList["BGFORGERAIDLOCKOUT"] = BG.ToggleRaidLockoutOverview
    SLASH_BGFORGERAIDLOCKOUT1 = "/bgr"
    SLASH_BGFORGERAIDLOCKOUT2 = "/bgraid"

    ClearExpiredRaidData()
    ScheduleResourceRefresh(0.5)
    BG.After(3, CaptureCurrentQuestProgress)
    RequestCurrentRaidInfo()

    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(60, function()
            if ClearExpiredRaidData() then
                if not CaptureCurrentQuestProgress() then
                    BG.After(5, CaptureCurrentQuestProgress)
                end
                RefreshLockoutDisplays()
            end
        end)
    end
end)

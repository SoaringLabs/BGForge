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
    upgradeWidth = 130,
    trinketWidth = 100,
    goldWidth = 88,
    emberWidth = 88,
    shardWidth = 88,
    footerHeight = 30,
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

local COLOR = {
    panel = { 0.015, 0.055, 0.075, 0.98 },
    panelTop = { 0.02, 0.075, 0.095, 0.98 },
    header = { 0.025, 0.105, 0.13, 0.98 },
    headerStrong = { 0.035, 0.13, 0.155, 0.98 },
    rowOdd = { 0.018, 0.07, 0.09, 0.9 },
    rowEven = { 0.025, 0.095, 0.115, 0.9 },
    current = { 0.24, 0.18, 0.05, 0.7 },
    gold = { 0.84, 0.55, 0.18, 0.95 },
    goldDim = { 0.42, 0.29, 0.13, 0.82 },
    grid = { 0.34, 0.25, 0.15, 0.72 },
    complete = { 0.1, 0.31, 0.14, 0.62 },
    partial = { 0.36, 0.19, 0.035, 0.48 },
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

local function CalculateRaidColumnWidths(raids, availableWidth)
    local widths = {}
    if #raids == 0 then
        return widths, 0
    end

    local compactWidth = 0
    for _, raid in ipairs(raids) do
        compactWidth = compactWidth + raid.compactWidth
    end

    local extraPerRaid = max(0, availableWidth - compactWidth) / #raids
    local assignedWidth = 0
    for index, raid in ipairs(raids) do
        local columnWidth = raid.compactWidth + extraPerRaid
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
    stored.trinkets = CaptureEquippedTrinkets()
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
                    legendaryUpgradeItems = type(stored.legendaryUpgradeItems) == "table"
                        and stored.legendaryUpgradeItems or {},
                    trinkets = type(stored.trinkets) == "table" and stored.trinkets or {},
                    resourcesUpdatedAt = tonumber(stored.resourcesUpdatedAt),
                    bankResourcesUpdatedAt = tonumber(stored.bankResourcesUpdatedAt),
                    instances = type(stored.instances) == "table" and stored.instances or {},
                    questCompletions = type(stored.questCompletions) == "table"
                        and stored.questCompletions or {},
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
        status.text:SetTextColor(0.55, 0.55, 0.55)
    elseif not lockout then
        status.text:SetText(blankWhenAvailable and "" or "—")
        status.text:SetTextColor(0.38, 0.38, 0.38)
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
            status.text:SetTextColor(1, 0.68, 0.18)
            status.background:SetColorTexture(unpack(COLOR.partial))
        else
            -- 大界面沿用原有颜色；本轮只重构小界面。
            status.text:SetTextColor(1, 0.82, 0)
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
    overviewFrame:SetBackdropColor(0.025, 0.025, 0.035, 0.96)
    overviewFrame:SetBackdropBorderColor(0, 0.75, 1, 0.9)
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
    title:SetTextColor(0, 0.75, 1)

    local subtitle = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    subtitle:SetText(L["汇总当前服务器下已在本机记录的角色本周团本进度"])
    subtitle:SetTextColor(0.55, 0.75, 0.8)

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
    characterHeader:SetTextColor(0, 0.75, 1)

    for columnIndex, column in ipairs(LOCKOUT_COLUMNS) do
        local header = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetPoint("TOPLEFT", startX + (columnIndex - 1) * cellWidth, headerTopY)
        header:SetWidth(cellWidth)
        header:SetHeight(column.groupID and headerSubHeight or (headerGroupHeight + headerSubHeight))
        header:SetJustifyH("CENTER")
        header:SetText(column.name)
        header:SetTextColor(0, 0.75, 1)
        headers[column.id] = header
    end
    for _, group in ipairs(QUEST_HEADER_GROUPS) do
        local header = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetHeight(headerGroupHeight)
        header:SetJustifyH("CENTER")
        header:SetText(group.name)
        header:SetTextColor(0, 0.75, 1)
        header:Hide()
        groupHeaders[group.id] = header
    end

    local statusText = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("RIGHT", refresh, "LEFT", -8, 0)
    statusText:SetWidth(260)
    statusText:SetJustifyH("RIGHT")

    local function EnsureRow(rowIndex)
        if rows[rowIndex] then
            return rows[rowIndex]
        end

        local row = CreateFrame("Frame", nil, overviewFrame)
        row:SetSize(width - 40, rowHeight)
        row:SetPoint("TOPLEFT", 20, rowsTopY - (rowIndex - 1) * rowHeight)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0, 0.55, 1, 0.18)
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
            if not column.isQuest then
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

    local function CreateTableCell(parent, backgroundColor, borders)
        local cell = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        cell:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
        })
        cell:SetBackdropColor(unpack(backgroundColor or COLOR.rowOdd))

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
        local text = CreateCellText(cell, nil, nil, { 0.95, 0.67, 0.29, 1 }, "CENTER")
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
        tile:SetBackdropColor(0.02, 0.02, 0.02, 1)

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
        overlay:SetColorTexture(0.95, 0.62, 0.2, 1)
        overlay:SetAlpha(0)
        overlays[#overlays + 1] = overlay
    end

    local function SetRowHoverAlpha(controller, alpha)
        controller.hoverAlpha = alpha
        for _, overlay in ipairs(controller.hoverOverlays) do
            overlay:SetAlpha(alpha)
        end
    end

    local function AnimateRowHover(controller, targetAlpha)
        controller.hoverStartAlpha = controller.hoverAlpha or 0
        controller.hoverTargetAlpha = targetAlpha
        controller.hoverElapsed = 0
        controller:SetScript("OnUpdate", function(self, elapsed)
            self.hoverElapsed = self.hoverElapsed + elapsed
            local progress = min(1, self.hoverElapsed / 0.1)
            local eased = 1 - (1 - progress) * (1 - progress)
            SetRowHoverAlpha(
                self,
                self.hoverStartAlpha + (self.hoverTargetAlpha - self.hoverStartAlpha) * eased
            )
            if progress >= 1 then
                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    local function CreateRowHoverController(overlays)
        local controller = CreateFrame("Frame", nil, hoverFrame)
        controller:SetFrameLevel(hoverFrame:GetFrameLevel() + 10)
        controller:EnableMouse(true)
        controller.hoverOverlays = overlays
        controller.hoverAlpha = 0
        controller:SetScript("OnEnter", function(self)
            hoverHideSerial = hoverHideSerial + 1
            AnimateRowHover(self, 0.16)
        end)
        controller:SetScript("OnLeave", function(self)
            AnimateRowHover(self, 0)
        end)
        return controller
    end

    local function ShowButtonTooltip(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(button.tooltipText, 1, 0.82, 0)
        GameTooltip:Show()
    end

    local function CreateIconButton(texture, tooltipText)
        local button = CreateFrame("Button", nil, hoverFrame, "BackdropTemplate")
        button:SetSize(23, 23)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.04, 0.09, 0.1, 0.96)
        button:SetBackdropBorderColor(unpack(COLOR.goldDim))

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexture(texture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetVertexColor(0.95, 0.67, 0.28)
        button.icon = icon

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetPoint("TOPLEFT", 2, -2)
        highlight:SetPoint("BOTTOMRIGHT", -2, 2)
        highlight:SetColorTexture(1, 0.72, 0.25, 0.18)
        button.tooltipText = tooltipText
        button:SetScript("OnEnter", ShowButtonTooltip)
        button:SetScript("OnLeave", GameTooltip_Hide)
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

    local innerBorder = CreateFrame("Frame", nil, hoverFrame, "BackdropTemplate")
    innerBorder:SetPoint("TOPLEFT", 6, -6)
    innerBorder:SetPoint("BOTTOMRIGHT", -6, 6)
    innerBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    innerBorder:SetBackdropBorderColor(0.3, 0.22, 0.12, 0.82)

    local topBar = CreateTableCell(hoverFrame, COLOR.panelTop, { left = true, top = true })
    topBar:SetPoint("TOPLEFT", ui.padding, -ui.padding)
    topBar:SetSize(width - ui.padding * 2, ui.topBarHeight)

    local logo = topBar:CreateTexture(nil, "ARTWORK")
    logo:SetSize(22, 22)
    logo:SetPoint("LEFT", 8, 0)
    logo:SetTexture("Interface\\AddOns\\BGForge\\Media\\icon\\icon-128.tga")

    local title = topBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 7, 0)
    title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    title:SetText(L["BGForge · 全角色总览"])
    title:SetTextColor(unpack(COLOR.gold))

    local close = CreateIconButton("Interface\\Buttons\\UI-Panel-MinimizeButton-Up", L["关闭"])
    close:SetPoint("TOPRIGHT", -ui.padding - 6, -ui.padding - 6)
    close:SetScript("OnClick", function()
        hoverFrame:Hide()
        GameTooltip:Hide()
    end)

    local settings = CreateIconButton("Interface\\Icons\\Trade_Engineering", L["设置"])
    settings:SetPoint("RIGHT", close, "LEFT", -5, 0)
    settings:SetScript("OnClick", function()
        hoverFrame:Hide()
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
    resetText:SetTextColor(0.72, 0.66, 0.55)

    local raidTitleCell = CreateTableCell(hoverFrame, COLOR.headerStrong, { left = true })
    raidTitleCell:SetPoint("TOPLEFT", ui.padding, -(ui.padding + ui.topBarHeight))
    raidTitleCell:SetSize(ui.nameWidth, ui.raidHeaderGroupHeight + ui.raidHeaderSubHeight)
    local raidTitleAccent = raidTitleCell:CreateTexture(nil, "ARTWORK")
    raidTitleAccent:SetPoint("TOPLEFT", 5, -5)
    raidTitleAccent:SetPoint("BOTTOMLEFT", 5, 5)
    raidTitleAccent:SetWidth(3)
    raidTitleAccent:SetColorTexture(unpack(COLOR.gold))
    local raidTitle = CreateCellText(raidTitleCell, "GameFontNormal", 12, COLOR.gold, "LEFT")
    raidTitle:ClearAllPoints()
    raidTitle:SetPoint("LEFT", 14, 0)
    raidTitle:SetPoint("RIGHT", -7, 0)

    for _, column in ipairs(LOCKOUT_COLUMNS) do
        local header = CreateTableCell(hoverFrame, COLOR.header)
        header:SetSize(
            column.compactWidth,
            column.groupID and ui.raidHeaderSubHeight
                or (ui.raidHeaderGroupHeight + ui.raidHeaderSubHeight)
        )
        local text = CreateCellText(header, "GameFontNormal", 12, COLOR.gold, "CENTER")
        text:SetText(column.name)
        headers[column.id] = header
    end
    for _, group in ipairs(QUEST_HEADER_GROUPS) do
        local header = CreateTableCell(hoverFrame, COLOR.headerStrong)
        header:SetSize(1, ui.raidHeaderGroupHeight)
        local text = CreateCellText(header, "GameFontNormal", 12, COLOR.gold, "CENTER")
        text:SetText(group.name)
        header:Hide()
        groupHeaders[group.id] = header
    end

    local resourceTitleCell = CreateTableCell(hoverFrame, COLOR.headerStrong, { left = true, top = true })
    resourceTitleCell:SetSize(ui.nameWidth, ui.resourceGroupHeight + ui.resourceSubHeaderHeight)
    local resourceAccent = resourceTitleCell:CreateTexture(nil, "ARTWORK")
    resourceAccent:SetPoint("TOPLEFT", 5, -5)
    resourceAccent:SetPoint("BOTTOMLEFT", 5, 5)
    resourceAccent:SetWidth(3)
    resourceAccent:SetColorTexture(unpack(COLOR.gold))
    local resourceTitle = CreateCellText(resourceTitleCell, "GameFontNormal", 12, COLOR.gold, "LEFT")
    resourceTitle:ClearAllPoints()
    resourceTitle:SetPoint("LEFT", 14, 0)
    resourceTitle:SetPoint("RIGHT", -7, 0)

    local professionHeader = CreateTableCell(hoverFrame, COLOR.headerStrong, { top = true })
    professionHeader:SetSize(ui.professionWidth, ui.resourceGroupHeight + ui.resourceSubHeaderHeight)
    local professionHeaderText = CreateCellText(professionHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    professionHeaderText:SetText(L["专业"])

    local equipmentHeader = CreateTableCell(hoverFrame, COLOR.headerStrong, { top = true })
    equipmentHeader:SetSize(
        ui.legendaryWidth + ui.upgradeWidth + ui.trinketWidth,
        ui.resourceGroupHeight
    )
    local equipmentHeaderText = CreateCellText(equipmentHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    equipmentHeaderText:SetText(L["装备"])

    local legendaryHeader = CreateTableCell(hoverFrame, COLOR.header)
    legendaryHeader:SetSize(ui.legendaryWidth, ui.resourceSubHeaderHeight)
    local legendaryHeaderText = CreateCellText(legendaryHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    legendaryHeaderText:SetText(L["橙装"])

    local upgradeHeader = CreateTableCell(hoverFrame, COLOR.header)
    upgradeHeader:SetSize(ui.upgradeWidth, ui.resourceSubHeaderHeight)
    local upgradeHeaderText = CreateCellText(upgradeHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    upgradeHeaderText:SetText(L["升级物品"])

    local trinketHeader = CreateTableCell(hoverFrame, COLOR.header)
    trinketHeader:SetSize(ui.trinketWidth, ui.resourceSubHeaderHeight)
    local trinketHeaderText = CreateCellText(trinketHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    trinketHeaderText:SetText(L["饰品"])

    local commonHeader = CreateTableCell(hoverFrame, COLOR.headerStrong, { top = true })
    commonHeader:SetSize(ui.goldWidth + ui.emberWidth + ui.shardWidth, ui.resourceGroupHeight)
    local commonHeaderText = CreateCellText(commonHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    commonHeaderText:SetText(L["通用资源"])

    local goldHeader = CreateTableCell(hoverFrame, COLOR.header)
    goldHeader:SetSize(ui.goldWidth, ui.resourceSubHeaderHeight)
    local goldHeaderText = CreateCellText(goldHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    goldHeaderText:SetText(L["金币"])

    local emberHeader = CreateTableCell(hoverFrame, COLOR.header)
    emberHeader:SetSize(ui.emberWidth, ui.resourceSubHeaderHeight)
    local emberHeaderText = CreateCellText(emberHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    emberHeaderText:SetText(L["泰坦余烬"])

    local shardHeader = CreateTableCell(hoverFrame, COLOR.header)
    shardHeader:SetSize(ui.shardWidth, ui.resourceSubHeaderHeight)
    local shardHeaderText = CreateCellText(shardHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    shardHeaderText:SetText(L["泰坦碎片"])

    local footerText = hoverFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footerText:SetJustifyH("LEFT")
    footerText:SetWordWrap(false)
    footerText:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    footerText:SetTextColor(0.58, 0.52, 0.43)

    local function EnsureRow(rowIndex)
        if rows[rowIndex] then
            return rows[rowIndex]
        end

        local row = {
            raidCells = {},
            raidHoverOverlays = {},
            resourceHoverOverlays = {},
        }

        row.raidNameCell = CreateTableCell(hoverFrame, nil, { left = true })
        row.raidNameCell:SetSize(ui.nameWidth, ui.rowHeight)
        row.raidName = CreateCellText(row.raidNameCell, "GameFontHighlightSmall", 12, nil, "LEFT")
        CreateRowHoverOverlay(row.raidNameCell, row.raidHoverOverlays)

        for _, column in ipairs(LOCKOUT_COLUMNS) do
            local cell = CreateStatusDisplay(hoverFrame, column.compactWidth, ui.rowHeight, 15, 11, true)
            cell.column = column
            CreateRowHoverOverlay(cell, row.raidHoverOverlays)
            row.raidCells[column.id] = cell
        end

        row.resourceNameCell = CreateTableCell(hoverFrame, nil, { left = true })
        row.resourceNameCell:SetSize(ui.nameWidth, ui.rowHeight)
        row.resourceName = CreateCellText(row.resourceNameCell, "GameFontHighlightSmall", 12, nil, "LEFT")
        CreateRowHoverOverlay(row.resourceNameCell, row.resourceHoverOverlays)

        row.professionCell = CreateTableCell(hoverFrame)
        row.professionCell:SetSize(ui.professionWidth, ui.rowHeight)
        row.professionTiles = {}
        CreateRowHoverOverlay(row.professionCell, row.resourceHoverOverlays)

        row.legendaryCell = CreateTableCell(hoverFrame)
        row.legendaryCell:SetSize(ui.legendaryWidth, ui.rowHeight)
        row.legendaryTiles = {}
        CreateRowHoverOverlay(row.legendaryCell, row.resourceHoverOverlays)

        row.upgradeCell = CreateTableCell(hoverFrame)
        row.upgradeCell:SetSize(ui.upgradeWidth, ui.rowHeight)
        row.upgradeTiles = {}
        CreateRowHoverOverlay(row.upgradeCell, row.resourceHoverOverlays)

        row.trinketCell = CreateTableCell(hoverFrame)
        row.trinketCell:SetSize(ui.trinketWidth, ui.rowHeight)
        row.trinketTiles = {}
        CreateRowHoverOverlay(row.trinketCell, row.resourceHoverOverlays)

        row.goldCell = CreateTableCell(hoverFrame)
        row.goldCell:SetSize(ui.goldWidth, ui.rowHeight)
        row.gold = CreateResourceNumberText(row.goldCell)
        CreateRowHoverOverlay(row.goldCell, row.resourceHoverOverlays)

        row.emberCell = CreateTableCell(hoverFrame)
        row.emberCell:SetSize(ui.emberWidth, ui.rowHeight)
        row.ember = CreateResourceNumberText(row.emberCell)
        CreateRowHoverOverlay(row.emberCell, row.resourceHoverOverlays)

        row.shardCell = CreateTableCell(hoverFrame)
        row.shardCell:SetSize(ui.shardWidth, ui.rowHeight)
        row.shard = CreateResourceNumberText(row.shardCell)
        CreateRowHoverOverlay(row.shardCell, row.resourceHoverOverlays)

        row.raidHover = CreateRowHoverController(row.raidHoverOverlays)
        row.resourceHover = CreateRowHoverController(row.resourceHoverOverlays)

        rows[rowIndex] = row
        return row
    end

    local totalNameCell = CreateTableCell(hoverFrame, COLOR.header, { left = true })
    totalNameCell:SetSize(ui.nameWidth, ui.rowHeight)
    local totalName = CreateCellText(totalNameCell, "GameFontNormal", 12, COLOR.gold, "CENTER")
    totalName:SetText(L["合计"])

    local totalProfessionCell = CreateTableCell(hoverFrame, COLOR.header)
    totalProfessionCell:SetSize(ui.professionWidth, ui.rowHeight)

    local totalLegendaryCell = CreateTableCell(hoverFrame, COLOR.header)
    totalLegendaryCell:SetSize(ui.legendaryWidth, ui.rowHeight)

    local totalUpgradeCell = CreateTableCell(hoverFrame, COLOR.header)
    totalUpgradeCell:SetSize(ui.upgradeWidth, ui.rowHeight)

    local totalTrinketCell = CreateTableCell(hoverFrame, COLOR.header)
    totalTrinketCell:SetSize(ui.trinketWidth, ui.rowHeight)

    local totalGoldCell = CreateTableCell(hoverFrame, COLOR.header)
    totalGoldCell:SetSize(ui.goldWidth, ui.rowHeight)
    local totalGold = CreateResourceNumberText(totalGoldCell)

    local totalEmberCell = CreateTableCell(hoverFrame, COLOR.header)
    totalEmberCell:SetSize(ui.emberWidth, ui.rowHeight)
    local totalEmber = CreateResourceNumberText(totalEmberCell)

    local totalShardCell = CreateTableCell(hoverFrame, COLOR.header)
    totalShardCell:SetSize(ui.shardWidth, ui.rowHeight)
    local totalShard = CreateResourceNumberText(totalShardCell)

    -- Titan's Lua compiler allows at most 60 upvalues per function. Keep the
    -- renderer's module dependencies behind one context so future columns do
    -- not silently push this already-large UI callback over that limit.
    local renderContext = {
        color = COLOR,
        calculateColumnWidths = CalculateRaidColumnWidths,
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
        renderItemStrip = RenderItemStrip,
        renderProfessionStrip = RenderProfessionStrip,
        setCellColor = SetCellColor,
        setRowHoverAlpha = SetRowHoverAlpha,
        titanEmberCurrencyID = TITAN_EMBER_CURRENCY_ID,
        titanShardCurrencyID = TITAN_SHARD_CURRENCY_ID,
        updateStatusDisplay = UpdateStatusDisplay,
        updateQuestStatusDisplay = UpdateQuestStatusDisplay,
    }

    updateHoverFrame = function()
        local resourceCharacters = renderContext.getCharacterRows()
        local raidCharacters = renderContext.getRaidCharacterRows(resourceCharacters)
        local visibleColumns = renderContext.getVisibleColumns()
        local raidRowCount = max(1, #raidCharacters)
        local resourceRowCount = max(1, #resourceCharacters)
        local compactColumnsWidth = 0
        for _, column in ipairs(visibleColumns) do
            compactColumnsWidth = compactColumnsWidth + column.compactWidth
        end

        local compactEquipmentWidth = ui.legendaryWidth + ui.upgradeWidth + ui.trinketWidth
        local compactCommonWidth = ui.goldWidth + ui.emberWidth + ui.shardWidth
        local compactResourceWidth = ui.nameWidth + ui.professionWidth
            + compactEquipmentWidth + compactCommonWidth
        width = max(
            660,
            ui.padding * 2 + ui.nameWidth + compactColumnsWidth,
            ui.padding * 2 + compactResourceWidth
        )
        local columnWidths, lockoutsWidth = renderContext.calculateColumnWidths(
            visibleColumns,
            width - ui.padding * 2 - ui.nameWidth
        )
        local resourceColumnWidths, resourceColumnsWidth = renderContext.calculateResourceColumnWidths(
            ui,
            width - ui.padding * 2 - ui.nameWidth
        )
        local professionWidth = resourceColumnWidths.profession
        local legendaryWidth = resourceColumnWidths.legendary
        local upgradeWidth = resourceColumnWidths.upgrade
        local trinketWidth = resourceColumnWidths.trinket
        local goldWidth = resourceColumnWidths.gold
        local emberWidth = resourceColumnWidths.ember
        local shardWidth = resourceColumnWidths.shard
        local equipmentWidth = legendaryWidth + upgradeWidth + trinketWidth
        local commonWidth = goldWidth + emberWidth + shardWidth
        local resourceWidth = ui.nameWidth + resourceColumnsWidth
        hoverFrame:SetWidth(width)
        topBar:SetWidth(width - ui.padding * 2)
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
                -(ui.padding + ui.topBarHeight
                    + (column.groupID and ui.raidHeaderGroupHeight or 0))
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
            header:SetPoint("TOPLEFT", columnX[group.columns[1].id], -(ui.padding + ui.topBarHeight))
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

        local raidRowsTop = ui.padding + ui.topBarHeight + ui.raidHeaderGroupHeight + ui.raidHeaderSubHeight
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
        upgradeHeader:SetWidth(upgradeWidth)
        upgradeHeader:ClearAllPoints()
        upgradeHeader:SetPoint(
            "TOPLEFT",
            equipmentX + legendaryWidth,
            -(resourceTop + ui.resourceGroupHeight)
        )
        trinketHeader:SetWidth(trinketWidth)
        trinketHeader:ClearAllPoints()
        trinketHeader:SetPoint(
            "TOPLEFT",
            equipmentX + legendaryWidth + upgradeWidth,
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
                or (rowIndex % 2 == 0 and renderContext.color.rowEven or renderContext.color.rowOdd)
            local rowY = raidRowsTop + (rowIndex - 1) * ui.rowHeight

            row.raidNameCell:Show()
            row.raidNameCell:ClearAllPoints()
            row.raidNameCell:SetPoint("TOPLEFT", ui.padding, -rowY)
            renderContext.setCellColor(row.raidNameCell, rowColor)
            row.raidName:SetText(renderContext.getCharacterDisplayName(character, "itemLevel"))

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
            row.raidHover:Show()
        end

        local goldTotal = 0
        local emberTotal = 0
        local shardTotal = 0
        local latestResourceRecord
        for rowIndex, character in ipairs(resourceCharacters) do
            local row = renderContext.ensureRow(rowIndex)
            local rowColor = character.isCurrent and renderContext.color.current
                or (rowIndex % 2 == 0 and renderContext.color.rowEven or renderContext.color.rowOdd)
            local resourceRowY = resourceRowsTop + (rowIndex - 1) * ui.rowHeight
            local professionX = ui.padding + ui.nameWidth
            local legendaryX = professionX + professionWidth
            local upgradeX = legendaryX + legendaryWidth
            local trinketX = upgradeX + upgradeWidth
            local goldX = trinketX + trinketWidth
            local emberX = goldX + goldWidth
            local shardX = emberX + emberWidth

            row.resourceNameCell:Show()
            row.resourceNameCell:ClearAllPoints()
            row.resourceNameCell:SetPoint("TOPLEFT", ui.padding, -resourceRowY)
            renderContext.setCellColor(row.resourceNameCell, rowColor)
            row.resourceName:SetText(renderContext.getCharacterDisplayName(character, "level"))

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
            row.resourceHover:Show()

            goldTotal = goldTotal + (gold or 0)
            emberTotal = emberTotal + (character.titanEmbers or 0)
            shardTotal = shardTotal + (character.titanShards or 0)
            if character.resourcesUpdatedAt
                and (not latestResourceRecord or character.resourcesUpdatedAt > latestResourceRecord) then
                latestResourceRecord = character.resourcesUpdatedAt
            end
        end

        for rowIndex = #raidCharacters + 1, #rows do
            local row = rows[rowIndex]
            row.raidNameCell:Hide()
            row.raidHover:Hide()
            row.raidHover:SetScript("OnUpdate", nil)
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
            row.upgradeCell:Hide()
            row.trinketCell:Hide()
            row.goldCell:Hide()
            row.emberCell:Hide()
            row.shardCell:Hide()
            row.resourceHover:Hide()
            row.resourceHover:SetScript("OnUpdate", nil)
            renderContext.setRowHoverAlpha(row.resourceHover, 0)
        end

        local totalY = resourceRowsTop + resourceRowCount * ui.rowHeight
        local professionX = ui.padding + ui.nameWidth
        local legendaryX = professionX + professionWidth
        local upgradeX = legendaryX + legendaryWidth
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

        hoverFrame:SetHeight(totalY + ui.rowHeight + ui.footerHeight + ui.padding)
    end

    updateHoverFrame()
end

local function PositionHoverFrame(anchor)
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
    if not anchor then
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
    if hoverFrame then
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

function BG.RoleOverviewUI()
    CreateOverviewFrame()
end

function BG.ToggleRaidLockoutOverview()
    CreateOverviewFrame()
    BG.HideRaidLockoutHover()
    overviewFrame:SetShown(not overviewFrame:IsShown())
end

function BG.CreateRaidLockoutMainMenuButton(anchor)
    if BG.ButtonRaidLockout or not anchor then
        return
    end

    local button = CreateFrame("Button", nil, BG.MainFrame)
    button:SetPoint("LEFT", anchor, "RIGHT", BG.TopLeftButtonJianGe, 0)
    button:SetNormalFontObject(BG.FontGreen15)
    button:SetDisabledFontObject(BG.FontDis15)
    button:SetHighlightFontObject(BG.FontWhite15)
    button:SetText(L["全角色总览"])
    button:SetSize(button:GetFontString():GetWidth(), 20)
    BG.SetTextHighlightTexture(button)
    button:SetScript("OnClick", function()
        BG.ToggleRaidLockoutOverview()
        BG.PlaySound(1)
    end)
    BG.ButtonRaidLockout = button
    BG.LayoutMainMenuButtons()
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

if not BG.IsTitan then return end

local _, ns = ...

local L = ns.L
local GetItemID = ns.GetItemID
local HopeMaxb = ns.HopeMaxb

local Wishlist = {}
BG.Wishlist = Wishlist

local STORAGE_KEY = "BGForgeWishlist"
local STORAGE_VERSION = 2
local exchangeSourceCache = {}
local lastDropAlert = {}
local testItemByRaid = {}

local function NormalizeItemID(value)
    if type(value) == "number" then
        return value
    end
    if type(value) == "string" then
        return tonumber(value) or GetItemID(value)
    end
end

local function MigrateStorage(root)
    if (tonumber(root.version) or 1) >= STORAGE_VERSION then return end
    for _, realm in pairs(root.realms or {}) do
        for _, character in pairs(type(realm) == "table" and realm.characters or {}) do
            for FB, entries in pairs(type(character) == "table" and character.raids or {}) do
                local migrated = {}
                local seen = {}
                for _, entry in ipairs(type(entries) == "table" and entries or {}) do
                    local itemID = NormalizeItemID(entry.watchedItemID or entry.itemID)
                    if itemID and not seen[itemID] then
                        seen[itemID] = true
                        table.insert(migrated, {
                            itemID = itemID,
                            bossIndex = entry.bossIndex,
                        })
                    end
                end
                character.raids[FB] = migrated
            end
        end
    end
    root.version = STORAGE_VERSION
end

local function EnsureRoot()
    BiaoGe = BiaoGe or {}
    local root = BiaoGe[STORAGE_KEY]
    if type(root) ~= "table" then
        root = {}
        BiaoGe[STORAGE_KEY] = root
    end
    root.realms = root.realms or {}
    MigrateStorage(root)
    root.version = STORAGE_VERSION
    return root
end

local function GetCharacterData(create)
    local root = EnsureRoot()
    local realmID = GetRealmID()
    local player = BG.playerName
    local realm = root.realms[realmID]
    if not realm then
        if not create then return end
        realm = { characters = {} }
        root.realms[realmID] = realm
    end
    realm.characters = realm.characters or {}
    local character = realm.characters[player]
    if not character then
        if not create then return end
        character = { raids = {} }
        realm.characters[player] = character
    end
    character.raids = character.raids or {}
    return character
end

local function GetEntries(FB, create)
    local character = GetCharacterData(create)
    if not character then return end
    local entries = character.raids[FB]
    if not entries and create then
        entries = {}
        character.raids[FB] = entries
    end
    return entries
end

local function GetExchangeSourceIndex(FB)
    if exchangeSourceCache[FB] then
        return exchangeSourceCache[FB]
    end
    local index = {}
    local exchangeItems = BG.Loot[FB] and BG.Loot[FB].ExchangeItems or {}
    for sourceItemID, targetItems in pairs(exchangeItems) do
        for _, targetItemID in ipairs(targetItems) do
            index[targetItemID] = sourceItemID
        end
    end
    exchangeSourceCache[FB] = index
    return index
end

function Wishlist.GetDropSourceItemID(itemID, FB)
    itemID = NormalizeItemID(itemID)
    if not itemID then return end
    FB = FB or BG.FB1
    local exchangeItems = BG.Loot[FB] and BG.Loot[FB].ExchangeItems or {}
    if exchangeItems[itemID] then
        return itemID
    end
    return GetExchangeSourceIndex(FB)[itemID] or itemID
end

local function ContainsItem(items, itemID)
    if not items then return false end
    for _, candidate in ipairs(items) do
        if candidate == itemID then
            return true
        end
    end
    return false
end

local function BossContains(FB, bossIndex, itemID)
    local loot = BG.Loot[FB] and BG.Loot[FB].N
    if not loot then return false end
    return ContainsItem(loot["boss" .. bossIndex], itemID)
end

local function FindBoss(FB, itemID)
    for bossIndex = 1, HopeMaxb[FB] or 0 do
        if BossContains(FB, bossIndex, itemID) then
            return bossIndex
        end
    end
end

local function SortEntries(entries)
    table.sort(entries, function(left, right)
        if left.bossIndex == right.bossIndex then
            return left.itemID < right.itemID
        end
        return left.bossIndex < right.bossIndex
    end)
end

function Wishlist.GetEntries(FB)
    return GetEntries(FB or BG.FB1, false) or {}
end

function Wishlist.Add(itemID, FB, bossIndex)
    itemID = NormalizeItemID(itemID)
    FB = FB or BG.FB1
    if not itemID or not BG.Loot[FB] then
        return false, "invalid_item"
    end

    itemID = Wishlist.GetDropSourceItemID(itemID, FB)
    if not bossIndex or not BossContains(FB, bossIndex, itemID) then
        bossIndex = FindBoss(FB, itemID)
    end
    if not bossIndex then
        return false, "not_raid_drop"
    end

    local entries = GetEntries(FB, true)
    for _, entry in ipairs(entries) do
        if entry.itemID == itemID then
            entry.bossIndex = bossIndex
            testItemByRaid[FB] = itemID
            SortEntries(entries)
            Wishlist.Refresh()
            return true, entry, "updated"
        end
    end

    local entry = {
        itemID = itemID,
        bossIndex = bossIndex,
    }
    table.insert(entries, entry)
    testItemByRaid[FB] = itemID
    SortEntries(entries)
    Wishlist.Refresh()
    return true, entry, "added"
end

local function GetRelevantRaids(FB)
    if not FB then
        return BG.FBtable
    end
    return BG.phaseFBtable[FB] or { FB }
end

function Wishlist.IsWishlisted(itemID, FB)
    itemID = NormalizeItemID(itemID)
    if not itemID then return false end
    for _, raidID in ipairs(GetRelevantRaids(FB)) do
        local sourceItemID = Wishlist.GetDropSourceItemID(itemID, raidID)
        for _, entry in ipairs(GetEntries(raidID, false) or {}) do
            if entry.itemID == sourceItemID then
                return true, entry, raidID
            end
        end
    end
    return false
end

function Wishlist.Remove(itemID, FB)
    itemID = NormalizeItemID(itemID)
    if not itemID then return false end
    local removed
    for _, raidID in ipairs(GetRelevantRaids(FB)) do
        local entries = GetEntries(raidID, false)
        if entries then
            local sourceItemID = Wishlist.GetDropSourceItemID(itemID, raidID)
            for index = #entries, 1, -1 do
                local entry = entries[index]
                if entry.itemID == sourceItemID then
                    if testItemByRaid[raidID] == entry.itemID then
                        testItemByRaid[raidID] = nil
                    end
                    table.remove(entries, index)
                    removed = true
                end
            end
            if #entries == 0 then
                local character = GetCharacterData(false)
                if character then
                    character.raids[raidID] = nil
                end
            end
        end
    end
    if removed then
        Wishlist.Refresh()
    end
    return removed or false
end

function Wishlist.Clear(FB)
    FB = FB or BG.FB1
    local character = GetCharacterData(false)
    if not character or not character.raids[FB] then return false end
    character.raids[FB] = nil
    testItemByRaid[FB] = nil
    Wishlist.Refresh()
    return true
end

function BG.IsHope(itemID, FB)
    return Wishlist.IsWishlisted(itemID, FB)
end

function BG.DeleteHope(itemID, FB)
    return Wishlist.Remove(itemID, FB)
end

function BG.UpdateHopeFrame_IsLooted_All()
    Wishlist.Refresh()
end

local function GetBrowseItems(FB, bossIndex)
    local result = {}
    local seen = {}
    local loot = BG.Loot[FB] and BG.Loot[FB].N
    for _, itemID in ipairs(loot and loot["boss" .. bossIndex] or {}) do
        if not seen[itemID] then
            seen[itemID] = true
            table.insert(result, {
                itemID = itemID,
                bossIndex = bossIndex,
            })
        end
    end
    return result
end

Wishlist.GetBrowseItems = GetBrowseItems

-- The UI module replaces this no-op after this file loads. Keeping the data
-- module independently callable makes storage/reminder regression tests cheap.
function Wishlist.Refresh()
end

function Wishlist.NotifyDrop(itemID, link, level, FB, force)
    itemID = NormalizeItemID(itemID)
    FB = FB or BG.FB2
    if not itemID or not FB or not Wishlist.IsWishlisted(itemID, FB) then
        return false
    end

    local now = GetTime and GetTime() or GetServerTime()
    if not force and lastDropAlert[itemID] and now - lastDropAlert[itemID] < 2 then
        return false
    end
    if not force then
        lastDropAlert[itemID] = now
    end

    local _, itemLink, _, itemLevel, _, _, _, _, _, texture = GetItemInfo(link or itemID)
    itemLink = link or itemLink or ("#" .. itemID)
    level = level or itemLevel or "?"
    local icon = texture and ("|T" .. texture .. ":0|t") or ""
    if BG.FrameLootMsg then
        BG.FrameLootMsg:AddMessage(BG.STC_g1(string.format(L["你的心愿达成啦！！！>>>>> %s(%s) <<<<<"], icon .. itemLink, level)))
    end
    BG.PlaySound("hope")
    return true
end

local function GetTestEntry(FB)
    FB = FB or BG.FB1
    local entries = Wishlist.GetEntries(FB)
    if #entries == 0 then
        UIErrorsFrame:AddMessage(L["请先为当前副本添加一件心愿装备"], 1, 0, 0)
        return nil, FB
    end

    local entry = entries[1]
    local preferredItemID = testItemByRaid[FB]
    if preferredItemID then
        for _, candidate in ipairs(entries) do
            if candidate.itemID == preferredItemID then
                entry = candidate
                break
            end
        end
    end

    return entry, FB
end

function Wishlist.TestDrop(FB)
    local entry
    entry, FB = GetTestEntry(FB)
    if not entry then return false end

    local sourceItemID = entry.itemID
    local function Trigger()
        local _, link, _, level = GetItemInfo(sourceItemID)
        Wishlist.NotifyDrop(sourceItemID, link, level, FB, true)
    end

    if not GetItemInfo(sourceItemID) and BG.OnItemLoad then
        BG.OnItemLoad(sourceItemID):ContinueOnItemLoad(Trigger)
    else
        Trigger()
    end
    return true
end

function Wishlist.TestAuction(FB)
    local entry
    entry, FB = GetTestEntry(FB)
    if not entry then return false end
    if not BG.ShowWishlistAuctionPreview then
        UIErrorsFrame:AddMessage(L["拍卖预览尚未初始化，请重新载入界面"], 1, 0, 0)
        return false
    end

    local sourceItemID = entry.itemID
    local function Trigger()
        local _, link = GetItemInfo(sourceItemID)
        BG.ShowWishlistAuctionPreview(sourceItemID, link)
    end
    if not GetItemInfo(sourceItemID) and BG.OnItemLoad then
        BG.OnItemLoad(sourceItemID):ContinueOnItemLoad(Trigger)
    else
        Trigger()
    end
    return true
end

local function FormatToPattern(formatText, multiple)
    if not formatText then return end
    local pattern = formatText:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
    pattern = pattern:gsub("%%%%s", "(.+)")
    if multiple then
        pattern = pattern:gsub("%%%%d", "(%%d+)")
    end
    return "^" .. pattern .. "$"
end

local lootPatterns = {
    selfMultiple = FormatToPattern(LOOT_ITEM_SELF_MULTIPLE, true),
    pushedSelfMultiple = FormatToPattern(LOOT_ITEM_PUSHED_SELF_MULTIPLE, true),
    bonusSelfMultiple = FormatToPattern(LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE, true),
    self = FormatToPattern(LOOT_ITEM_SELF),
    pushedSelf = FormatToPattern(LOOT_ITEM_PUSHED_SELF),
    bonusSelf = FormatToPattern(LOOT_ITEM_BONUS_ROLL_SELF),
    multiple = FormatToPattern(LOOT_ITEM_MULTIPLE, true),
    pushedMultiple = FormatToPattern(LOOT_ITEM_PUSHED_MULTIPLE, true),
    other = FormatToPattern(LOOT_ITEM),
    pushedOther = FormatToPattern(LOOT_ITEM_PUSHED),
}

local function MatchLootMessage(msg)
    local function Match(pattern)
        if pattern then return msg:match(pattern) end
    end

    local bonusLink = Match(lootPatterns.bonusSelfMultiple)
    if not bonusLink then bonusLink = Match(lootPatterns.bonusSelf) end
    if bonusLink then return bonusLink, true end

    local link = Match(lootPatterns.selfMultiple)
    if not link then link = Match(lootPatterns.pushedSelfMultiple) end
    if not link then link = Match(lootPatterns.self) end
    if not link then link = Match(lootPatterns.pushedSelf) end
    if link then return link end

    local _, groupLink = Match(lootPatterns.multiple)
    if not groupLink then _, groupLink = Match(lootPatterns.pushedMultiple) end
    if not groupLink then _, groupLink = Match(lootPatterns.other) end
    if not groupLink then _, groupLink = Match(lootPatterns.pushedOther) end
    return groupLink
end

BG.RegisterEvent("CHAT_MSG_LOOT", function(_, _, msg)
    if not msg or (BG.IsSecret and BG.IsSecret(msg)) then return end
    local link, isBonusRoll = MatchLootMessage(msg)
    if link then
        local itemID = NormalizeItemID(link)
        Wishlist.NotifyDrop(itemID, link, nil, BG.FB2)
        if isBonusRoll and BG.CancelGuanZhuAndHopeInTrade then
            BG.CancelGuanZhuAndHopeInTrade(itemID)
        end
    end
end)

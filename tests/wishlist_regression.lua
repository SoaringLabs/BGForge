local sourcePath = "Core/Module/Wishlist.lua"

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function AssertTrue(value, message)
    if not value then
        error(message or "expected a truthy value", 2)
    end
end

local function AssertFalse(value, message)
    if value then
        error(message or "expected a falsey value", 2)
    end
end

local function ItemLink(itemID)
    return "|cff0070dd|Hitem:" .. itemID .. "::::::::|h[Test " .. itemID .. "]|h|r"
end

local currentTime = 100
local lootMessages = {}
local sounds = {}
local events = {}
local uiErrors = {}
local auctionPreviews = {}

BiaoGe = { options = { autoLoot = 0 } }
BG = {
    IsTitan = true,
    playerName = "CurrentPlayer",
    FB1 = "RAID_A",
    FB2 = "RAID_A",
    FBtable = { "RAID_A", "RAID_B" },
    phaseFBtable = {
        RAID_A = { "RAID_A" },
        RAID_B = { "RAID_B" },
    },
    Loot = {
        RAID_A = {
            N = {
                boss1 = { 100, 200 },
                boss1other = { 201, 202 },
                boss2 = { 200, 300 },
            },
            ExchangeItems = {
                [200] = { 201, 202 },
            },
        },
        RAID_B = {
            N = { boss1 = { 400 } },
            ExchangeItems = {},
        },
    },
    RegisterEvent = function(event, callback)
        events[event] = callback
    end,
    PlaySound = function(sound)
        sounds[#sounds + 1] = sound
    end,
    STC_g1 = function(text) return text end,
    FrameLootMsg = {
        AddMessage = function(_, text)
            lootMessages[#lootMessages + 1] = text
        end,
    },
}
UIErrorsFrame = {
    AddMessage = function(_, text)
        uiErrors[#uiErrors + 1] = text
    end,
}

LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
LOOT_ITEM_PUSHED_SELF_MULTIPLE = "You receive item: %sx%d."
LOOT_ITEM_SELF = "You receive loot: %s."
LOOT_ITEM_PUSHED_SELF = "You receive item: %s."
LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE = "Bonus loot: %sx%d."
LOOT_ITEM_BONUS_ROLL_SELF = "Bonus loot: %s."
LOOT_ITEM_MULTIPLE = "%s receives loot: %sx%d."
LOOT_ITEM_PUSHED_MULTIPLE = "%s receives item: %sx%d."
LOOT_ITEM = "%s receives loot: %s."
LOOT_ITEM_PUSHED = "%s receives item: %s."

GetRealmID = function() return 42 end
UnitClass = function() return "Mage", "MAGE" end
GetTime = function() return currentTime end
GetServerTime = function() return currentTime end
GetItemInfo = function(value)
    local itemID = type(value) == "number" and value or tonumber(tostring(value):match("item:(%d+)"))
    if not itemID then return end
    return "Test " .. itemID, ItemLink(itemID), 3, 232, nil, nil, nil, nil, nil, 134400 + itemID
end

local L = setmetatable({
    ["你的心愿达成啦！！！>>>>> %s(%s) <<<<<"] = "WISH %s(%s)",
}, { __index = function(_, key) return key end })

local namespace = {
    L = L,
    HopeMaxb = { RAID_A = 2, RAID_B = 1 },
    GetItemID = function(value)
        if type(value) == "number" then return value end
        return tonumber(tostring(value):match("item:(%d+)"))
    end,
}

local chunk, loadError = loadfile(sourcePath)
if not chunk then error(loadError) end
chunk("BGForge", namespace)

assert(loadfile("Core/UI/DesignSystem.lua"))("BGForge", namespace)
local uiChunk, uiLoadError = loadfile("Core/Module/WishlistUI.lua")
if not uiChunk then error(uiLoadError) end
uiChunk("BGForge", namespace)

local Wishlist = BG.Wishlist
AssertTrue(Wishlist, "wishlist module should load on Titan")
AssertTrue(events.CHAT_MSG_LOOT, "wishlist should listen for loot independently")

local bossDrops = Wishlist.GetBrowseItems("RAID_A", 1)
AssertEqual(#bossDrops, 2, "boss browse data should contain only actual drops, not exchange results")
AssertEqual(bossDrops[1].itemID, 100, "direct boss drop should remain visible")
AssertEqual(bossDrops[2].itemID, 200, "exchange token should remain visible as the boss drop")
AssertEqual(bossDrops[2].watchedItemID, nil, "browse rows should not duplicate the actual drop ID")

local browseModel = Wishlist.BuildBrowseModel("RAID_A", function(_, itemID)
    if itemID == 200 then
        return {
            isClassSet = true,
            classes = { "DRUID", "MAGE" },
            equipLoc = "INVTYPE_WRIST",
            targetCount = 2,
        }
    end
end)
AssertEqual(#browseModel.setGroups, 1, "class-set tokens should form one dedicated group")
AssertTrue(browseModel.setGroups[1].isCurrent, "the current class group should be identified")
AssertEqual(#browseModel.setGroups[1].items, 1, "the same token should be shown once across bosses")
AssertEqual(#browseModel.setGroups[1].items[1].sourceBosses, 2, "the token should retain every boss source")
AssertEqual(browseModel.setGroups[1].items[1].sourceBosses[1], 1, "the first boss source should be retained")
AssertEqual(browseModel.setGroups[1].items[1].sourceBosses[2], 2, "the second boss source should be retained")
AssertEqual(#browseModel.bosses[1].items, 1, "set tokens should be removed from the first boss's direct-drop cards")
AssertEqual(browseModel.bosses[1].items[1].itemID, 100, "the first boss's direct gear should remain")
AssertEqual(#browseModel.bosses[2].items, 1, "set tokens should be removed from the second boss's direct-drop cards")
AssertEqual(browseModel.bosses[2].items[1].itemID, 300, "the second boss's direct gear should remain")

local fallbackModel = Wishlist.BuildBrowseModel("RAID_A", function(_, itemID)
    if itemID == 200 then
        error("simulated tooltip metadata failure")
    end
end)
AssertEqual(#fallbackModel.bosses, 2, "optional set metadata failures must not abort the browse model")
AssertEqual(#fallbackModel.bosses[1].items, 2, "an unclassified token should remain selectable under its boss")
AssertEqual(fallbackModel.bosses[1].items[2].itemID, 200, "the fallback should retain the physical drop")

local ok, entry, change = Wishlist.Add(100, "RAID_A")
AssertTrue(ok, "direct boss drop should be accepted")
AssertEqual(entry.itemID, 100, "direct wish should store selected item")
AssertEqual(entry.watchedItemID, nil, "direct wish should not duplicate the actual drop ID")
AssertEqual(change, "added", "first direct wish should be added")

ok, entry, change = Wishlist.Add(201, "RAID_A")
AssertTrue(ok, "exchange result should be accepted")
AssertEqual(entry.itemID, 200, "exchange result should be canonicalized to the dropped token")
AssertEqual(entry.watchedItemID, nil, "canonical wishlist rows should store only the drop source")
AssertEqual(#Wishlist.GetEntries("RAID_A"), 2, "wishlist should contain direct drop and token wish")

ok, entry, change = Wishlist.Add(202, "RAID_A")
AssertTrue(ok, "selecting another result for the same token should work")
AssertEqual(change, "updated", "same token should update rather than duplicate")
AssertEqual(entry.itemID, 200, "updated token wish should remain the actual drop source")
AssertEqual(#Wishlist.GetEntries("RAID_A"), 2, "same token should have one wishlist row")

AssertTrue(BG.IsHope(100, "RAID_A"), "direct wish should be queryable")
AssertTrue(BG.IsHope(200, "RAID_A"), "actual token should be queryable")
AssertTrue(BG.IsHope(202, "RAID_A"), "exchange results should resolve to their source token")
AssertTrue(BG.IsHope(201, "RAID_A"), "all results of the wished token should resolve to that token")
AssertFalse(Wishlist.Add(999, "RAID_A"), "non-raid item should be rejected")

AssertTrue(BG.DeleteHope(201, "RAID_A"), "receiving an exchange result should remove its source-token wish")
AssertFalse(BG.IsHope(202, "RAID_A"), "removed token wish should no longer be queryable")

local root = BiaoGe.BGForgeWishlist
AssertEqual(root.version, 2, "storage should use the source-only schema")
AssertTrue(root.realms[42].characters.CurrentPlayer, "storage should be scoped to the current character")
AssertEqual(root.realms[42].characters.CurrentPlayer.raids.RAID_A[1].itemID, 100, "storage should contain only the remaining wish")
AssertEqual(root.realms[42].characters.CurrentPlayer.name, nil, "storage must not duplicate player identity fields")
AssertEqual(root.realms[42].characters.CurrentPlayer.guid, nil, "storage must not collect player GUIDs")

events.CHAT_MSG_LOOT(nil, "CHAT_MSG_LOOT", "You receive loot: " .. ItemLink(100) .. ".")
AssertEqual(#lootMessages, 1, "self loot should alert with auto-loot disabled")
AssertEqual(sounds[#sounds], "hope", "wishlist alert should play the hope sound")

events.CHAT_MSG_LOOT(nil, "CHAT_MSG_LOOT", "OtherPlayer receives loot: " .. ItemLink(100) .. "x2.")
AssertEqual(#lootMessages, 1, "duplicate group loot event should be deduplicated")
currentTime = currentTime + 3
events.CHAT_MSG_LOOT(nil, "CHAT_MSG_LOOT", "OtherPlayer receives loot: " .. ItemLink(100) .. "x2.")
AssertEqual(#lootMessages, 2, "group loot should alert after the deduplication window")

local bonusCancelled
BG.CancelGuanZhuAndHopeInTrade = function(itemID)
    bonusCancelled = itemID
    BG.DeleteHope(itemID, "RAID_A")
end
currentTime = currentTime + 3
events.CHAT_MSG_LOOT(nil, "CHAT_MSG_LOOT", "Bonus loot: " .. ItemLink(100) .. ".")
AssertEqual(#lootMessages, 3, "bonus-roll acquisition should alert before removal")
AssertEqual(bonusCancelled, 100, "bonus-roll acquisition should enter the reliable removal path")
AssertFalse(BG.IsHope(100, "RAID_A"), "bonus-roll acquisition should remove the wish")

Wishlist.Add(300, "RAID_A")
local beforeTestAlerts = #lootMessages
AssertTrue(Wishlist.TestDrop("RAID_A"), "temporary test button path should simulate a wishlist drop")
AssertEqual(#lootMessages, beforeTestAlerts + 1, "test drop should show the real wishlist alert")
AssertTrue(BG.IsHope(300, "RAID_A"), "test drop must not remove the wishlist item")
AssertTrue(Wishlist.TestDrop("RAID_A"), "forced test drops should bypass real-event deduplication")
AssertEqual(#lootMessages, beforeTestAlerts + 2, "each test click should produce visible feedback")
BG.ShowWishlistAuctionPreview = function(itemID, link)
    auctionPreviews[#auctionPreviews + 1] = { itemID = itemID, link = link }
end
AssertTrue(Wishlist.TestAuction("RAID_A"), "temporary auction test should open a local preview")
AssertEqual(#auctionPreviews, 1, "auction test should create one preview")
AssertEqual(auctionPreviews[1].itemID, 300, "auction preview should use the actual watched drop")
AssertTrue(BG.IsHope(300, "RAID_A"), "auction preview must not remove the wishlist item")
AssertTrue(Wishlist.Clear("RAID_A"), "clearing current raid should remove its wishlist")
AssertEqual(#Wishlist.GetEntries("RAID_A"), 0, "cleared raid should have no entries")
AssertFalse(Wishlist.TestDrop("RAID_A"), "test drop should reject an empty wishlist")
AssertEqual(#uiErrors, 1, "empty test drop should explain that a wish is required")
AssertFalse(Wishlist.TestAuction("RAID_A"), "auction preview should reject an empty wishlist")
AssertEqual(#uiErrors, 2, "empty auction preview should explain that a wish is required")

BiaoGe.BGForgeWishlist = {
    version = 1,
    realms = {
        [42] = {
            characters = {
                CurrentPlayer = {
                    raids = {
                        RAID_A = {
                            { itemID = 201, watchedItemID = 200, bossIndex = 1 },
                            { itemID = 202, watchedItemID = 200, bossIndex = 1 },
                        },
                    },
                },
            },
        },
    },
}
local migratedEntries = Wishlist.GetEntries("RAID_A")
AssertEqual(BiaoGe.BGForgeWishlist.version, 2, "v1 target wishes should migrate to the source-only schema")
AssertEqual(#migratedEntries, 1, "migration should deduplicate multiple results of the same token")
AssertEqual(migratedEntries[1].itemID, 200, "migration should retain the actual dropped token")
AssertEqual(migratedEntries[1].watchedItemID, nil, "migration should remove the redundant watched item field")

print("Wishlist regression tests passed")

local L = setmetatable({}, { __index = function(_, key) return key end })
local namespace = {
    L = L,
    HopeMaxb = { ULDtitan = 15 },
    Maxb = { ULDtitan = 16 },
    GetItemID = function(value)
        return tonumber(tostring(value):match("item:(%d+)"))
    end,
}

tinsert = table.insert
QUESTS_LABEL = "Quests"
GetRealZoneText = function(id) return tostring(id) end
GetRealmID = function() return 1 end
GetTime = function() return 100 end
IsAddOnLoaded = function() return false end
GetLootMethod = function() end
CopyTable = function(source)
    local result = {}
    for key, value in pairs(source) do
        result[key] = type(value) == "table" and CopyTable(value) or value
    end
    return result
end

BG = {
    IsTitan = true,
    playerName = "Tester",
    FB1 = "ULDtitan",
    phaseFBtable = { ULDtitan = { "ULDtitan" } },
    Loot = {},
    STC_y1 = function(text) return text end,
    AddHolidayLoot = function() end,
    RegisterEvent = function() end,
}
BiaoGe = {}
for _, raid in ipairs({ "MCtitan", "SSCtitan", "NAXXtitan", "TOCtitan", "SWtitan", "ULDtitan", "Worldtitan" }) do
    BG.Loot[raid] = {
        N = { Quest = {} },
        ExchangeItems = {},
        Team = {}, Currency = {}, Faction = {}, Profession = {}, WorldBoss = {}, World = {}, Shop = {},
    }
end

assert(loadfile("Core/DB/DB_Loot_Titan.lua"))("BGForge", namespace)
assert(loadfile("Core/DB/DB_Loot_BlackWhiteList.lua"))("BGForge", namespace)
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
assert(loadfile("Core/Module/Wishlist.lua"))("BGForge", namespace)

local loot = BG.Loot.ULDtitan
local physicalItems = {}
local dropCount = 0
for boss = 1, 15 do
    local browse = BG.Wishlist.GetBrowseItems("ULDtitan", boss)
    assert(#browse > 0, "every Ulduar boss and misc section must have browseable drops")
    for _, entry in ipairs(browse) do
        physicalItems[entry.itemID] = true
        if boss <= 14 then dropCount = dropCount + 1 end
    end
end
assert(dropCount == 360, "all 14 bosses must expose the official Titan drops")
assert(#loot.N.boss15 == 13, "misc drops must include the official P6 materials")

local sourceCount, targetCount = 0, 0
for source, targets in pairs(loot.ExchangeItems) do
    sourceCount = sourceCount + 1
    assert(physicalItems[source], "every exchange source must be an actual browseable drop")
    for _, target in ipairs(targets) do
        targetCount = targetCount + 1
        assert(not physicalItems[target], "exchange rewards must not appear as physical boss drops")
        assert(BG.Wishlist.GetDropSourceItemID(target, "ULDtitan") == source,
            "exchange rewards must resolve to their physical source")
        assert(BG.Wishlist.Add(target, "ULDtitan"), "exchange rewards must be addable as wishes")
        assert(BG.Wishlist.IsWishlisted(source, "ULDtitan"), "wishes must watch the actual dropped source")
    end
end
assert(sourceCount == 22 and targetCount == 106, "P6 must retain the complete official exchange mapping")
assert(#BG.Wishlist.GetEntries("ULDtitan") == 22, "multiple exchange rewards must deduplicate to one source wish")

for _, itemID in ipairs(loot.N.boss15) do
    assert(BG.Loot.zaXiangItems[itemID], "P6 misc items must route to the misc ledger")
end
assert(BG.Loot.noStackItems[45087], "Runed Orbs must be recorded individually")
assert(BG.Loot.whitelist[45087], "Runed Orbs must bypass ordinary quality filtering")

-- Register the real clearing functions, stopping before the unrelated button UI.
local stopBeforeUI = {}
BG.CreateButton = function() error(stopBeforeUI) end
BG.Maxi = 40
local miscCapacity = 52
BG.GetMaxi = function(_, boss) return boss == 15 and miscCapacity or 4 end
BG.playerClass = { MAGE = true }
assert(loadfile("Core/Module/ClearBiaoGe.lua"))("BGForge", namespace)
local ok, stop = pcall(BG.ClearBiaoGeUI)
assert(not ok and stop == stopBeforeUI, "clearing functions must register before button creation")

local function Cell()
    return {
        text = "old", shown = true,
        SetText = function(self, text) self.text = text end,
        Hide = function(self) self.shown = false end,
    }
end

local function SeedRows()
    BG.Frame = { ULDtitan = { boss15 = {} } }
    BG.DuiZhangFrame = { ULDtitan = { boss15 = {} } }
    BiaoGe.ULDtitan = { boss15 = {} }
    for i = 1, 52 do
        for _, field in ipairs({ "zhuangbei", "maijia", "jine", "qiankuan", "guanzhu", "loot", "itemLevel", "bindOnEquip", "MAGE" }) do
            BiaoGe.ULDtitan.boss15[field .. i] = "old"
        end
        for _, field in ipairs({ "zhuangbei", "maijia", "jine", "qiankuan", "guanzhu" }) do
            BG.Frame.ULDtitan.boss15[field .. i] = Cell()
        end
        BG.DuiZhangFrame.ULDtitan.boss15["zhuangbei" .. i] = Cell()
        BG.DuiZhangFrame.ULDtitan.boss15["myjine" .. i] = Cell()
    end
end

SeedRows()
BG.ClearBiaoGeByIndex("ULDtitan", 15)
assert(next(BiaoGe.ULDtitan.boss15) == nil, "clearing must remove all stored fields, including rows 51-52")
for i = 1, 52 do
    assert(BG.Frame.ULDtitan.boss15["zhuangbei" .. i].text == "", "all physical rows must visually clear")
    assert(not BG.Frame.ULDtitan.boss15["qiankuan" .. i].shown, "clearing must hide old debt markers")
    assert(BG.DuiZhangFrame.ULDtitan.boss15["myjine" .. i].text == "", "reconciliation must clear expanded rows")
end

miscCapacity = 12
SeedRows()
BG.ClearBiaoGeByIndex("ULDtitan", 15)
assert(BiaoGe.ULDtitan.boss15.zhuangbei50 == nil, "legacy hidden rows must still clear after a layout shrinks")

print("BGLite v1.5 Titan data, wishlist and expanded-ledger clearing regression tests passed")

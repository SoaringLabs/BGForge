local sourcePath = "Core/Module/SpecGearFilter.lua"

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

local CLASS_NAMES = {
    DEATHKNIGHT = "Death Knight",
    WARRIOR = "Warrior",
    PALADIN = "Paladin",
    HUNTER = "Hunter",
    SHAMAN = "Shaman",
    DRUID = "Druid",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    MAGE = "Mage",
    WARLOCK = "Warlock",
}

local ITEM_DATA = {
    [100] = { equipLoc = "INVTYPE_WEAPON", typeID = 2, subclassID = 15, tooltip = "Attack Power" },
    [101] = { equipLoc = "INVTYPE_2HWEAPON", typeID = 2, subclassID = 8, tooltip = "Attack Power" },
    [102] = { equipLoc = "INVTYPE_SHIELD", typeID = 4, subclassID = 6, tooltip = "Defense" },
    [103] = { equipLoc = "INVTYPE_CLOAK", typeID = 4, subclassID = 1, tooltip = "Spell Power" },
    [104] = { equipLoc = "INVTYPE_CHEST", typeID = 4, subclassID = 4, tooltip = "Strength" },
    [105] = { equipLoc = "INVTYPE_CHEST", typeID = 4, subclassID = 4, tooltip = "Strength\nDefense" },
    [106] = { equipLoc = "INVTYPE_TRINKET", typeID = 4, subclassID = 0, tooltip = "Strength" },
    [107] = { equipLoc = "", typeID = 9, subclassID = 0, tooltip = "Spell Power\nClasses: Mage" },
    [108] = { equipLoc = "INVTYPE_HOLDABLE", typeID = 4, subclassID = 0, tooltip = "Spell Power" },
    [109] = { equipLoc = "INVTYPE_TRINKET", typeID = 4, subclassID = 0, tooltip = "Spell Power" },
    [110] = { equipLoc = "INVTYPE_TRINKET", typeID = 4, subclassID = 0, tooltip = "Attack Power" },
    [111] = { equipLoc = "INVTYPE_WEAPON", typeID = 2, subclassID = 15, tooltip = "Spell Power\nBattle.net Account Bound" },
    [112] = { equipLoc = "INVTYPE_2HWEAPON", typeID = 2, subclassID = 8, tooltip = "Attack Power\nClasses: Mage" },
    [113] = { equipLoc = "INVTYPE_2HWEAPON", typeID = 2, subclassID = 8, tooltip = "Attack Power\nClasses: Warrior" },
    [114] = { equipLoc = "INVTYPE_RELIC", typeID = 4, subclassID = 7, tooltip = "Spell Power" },
    [115] = { equipLoc = "", typeID = 4, subclassID = 0, tooltip = "Classes: Mage" },
    [116] = { equipLoc = "", typeID = 4, subclassID = 0, tooltip = "Classes: Warrior" },
    [117] = { equipLoc = "INVTYPE_TRINKET", typeID = 4, subclassID = 0, tooltip = "Critical Strike\nSpell Power" },
    [118] = { equipLoc = "", typeID = 4, subclassID = 0, tooltip = "Warrior's emblem\nClasses: Mage" },
}

local function ItemLink(itemID)
    return "|cff0070dd|Hitem:" .. itemID .. "::::::::|h[Test " .. itemID .. "]|h|r"
end

local function NewCell(text)
    return {
        text = text or "",
        alpha = nil,
        GetText = function(self) return self.text end,
        SetText = function(self, value) self.text = value end,
        SetAlpha = function(self, value) self.alpha = value end,
    }
end

local function ResetEnvironment(classFile, selectedKey, asyncLoads, missingAccountBoundConstant, delayedTooltip, locale)
    BGA = nil
    BiaoGe = {
        options = {
            specGearFilterByClass = selectedKey and { [classFile] = selectedKey } or {},
        },
        FilterClassItemDB = { private = "legacy" },
        filterClassNum = { private = "legacy" },
    }

    CLASS = locale == "zhCN" and "职业：" or "Classes:"
    if missingAccountBoundConstant then
        ITEM_BIND_TO_BNETACCOUNT = nil
    else
        ITEM_BIND_TO_BNETACCOUNT = "Battle.net Account Bound"
    end
    ITEM_MOD_STRENGTH_SHORT = "Strength"
    ITEM_MOD_AGILITY_SHORT = "Agility"
    ITEM_MOD_INTELLECT_SHORT = "Intellect"
    ITEM_MOD_SPIRIT_SHORT = "Spirit"
    ITEM_MOD_MANA_REGENERATION = "Mana per 5 sec"
    HIT_LCD = "Hit"
    STAT_HASTE = "Haste"
    STAT_CRITICAL_STRIKE = "Critical Strike"
    STAT_CATEGORY_DEFENSE = "Defense"
    STAT_PARRY = "Parry"
    STAT_DODGE = "Dodge"
    STAT_BLOCK = "Block"
    ITEM_MOD_BLOCK_RATING_SHORT = "Block Rating"
    ITEM_MOD_BLOCK_VALUE_SHORT = "Block Value"
    ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power"
    STAT_EXPERTISE = "Expertise"
    ITEM_MOD_ARMOR_PENETRATION_RATING = "Armor Penetration"
    ITEM_SPELL_TRIGGER_ONPROC = "Chance on hit"
    ITEM_MOD_SPELL_POWER_SHORT = locale == "zhCN" and "法术强度" or "Spell Power"
    ITEM_MOD_SPELL_DAMAGE_DONE = "Spell damage by up to %s"
    ITEM_MOD_SPELL_HEALING_DONE = "Healing by up to %s"

    local createdButtons = {}
    local createdLabels = {}
    local pendingLoads = {}
    local pendingTooltipReads = {}
    local primedItems = {}
    local frameMethods = {}
    function frameMethods:SetSize(width, height) self.width, self.height = width, height end
    function frameMethods:SetPoint(...) self.point = { ... } end
    function frameMethods:SetAllPoints() end
    function frameMethods:SetTexture(value) self.texture = value end
    function frameMethods:SetFont(...) self.font = { ... } end
    function frameMethods:SetText(value) self.text = value end
    function frameMethods:SetTextColor(...) self.textColor = { ... } end
    function frameMethods:SetTexCoord(...) end
    function frameMethods:SetBlendMode(value) self.blendMode = value end
    function frameMethods:SetDesaturated(value) self.desaturated = value end
    function frameMethods:SetShown(value) self.shown = value end
    function frameMethods:SetScript(event, callback) self.scripts = self.scripts or {}; self.scripts[event] = callback end
    function frameMethods:CreateTexture()
        return setmetatable({}, { __index = frameMethods })
    end
    function frameMethods:CreateFontString()
        local label = setmetatable({}, { __index = frameMethods })
        table.insert(createdLabels, label)
        return label
    end

    CreateFrame = function(frameType, _, parent)
        local frame = setmetatable({ frameType = frameType, parent = parent }, { __index = frameMethods })
        if frameType == "Button" then
            table.insert(createdButtons, frame)
        end
        return frame
    end

    GameTooltip = {
        SetOwner = function() end,
        ClearLines = function() end,
        AddLine = function() end,
        Show = function() end,
        Hide = function() end,
    }

    UnitClass = function()
        return locale == "zhCN" and ({ WARRIOR = "战士", MAGE = "法师" })[classFile]
            or CLASS_NAMES[classFile], classFile
    end

    GetItemInfoInstant = function(item)
        local itemID = tonumber(tostring(item):match("item:(%d+)"))
        local data = ITEM_DATA[itemID]
        if not data then return end
        return itemID, "", "", data.equipLoc, 0, data.typeID, data.subclassID
    end

    Item = {}
    function Item:CreateFromItemLink(link)
        return {
            ContinueOnItemLoad = function(_, callback)
                if asyncLoads then
                    table.insert(pendingLoads, { link = link, callback = callback })
                else
                    callback()
                end
            end,
        }
    end

    local currentCell = NewCell("")
    local BG = {
        FB1 = "TEST",
        FBMainFrame = {},
        ButtonQingKong = {},
        Frame = { TEST = { boss1 = { zhuangbei1 = currentCell } } },
        GetMaxi = function() return 1 end,
        GetTooltipTextLeftAll = function(item)
            local itemID = tonumber(tostring(item):match("item:(%d+)"))
            return ITEM_DATA[itemID] and ITEM_DATA[itemID].tooltip or ""
        end,
        PlaySound = function() end,
        Init = function(callback) callback() end,
        After = function(_, callback)
            if delayedTooltip then
                table.insert(pendingTooltipReads, callback)
            else
                callback()
            end
        end,
        Tooltip_SetItemByID = function(item)
            table.insert(primedItems, item)
        end,
    }
    _G.BG = BG

    local L = setmetatable({}, { __index = function(_, key) return key end })
    local ns = { L = L, Maxb = { TEST = 1 } }
    assert(loadfile(sourcePath))("BGForge", ns)

    return {
        BG = BG,
        module = BG.SpecGearFilter,
        buttons = createdButtons,
        labels = createdLabels,
        pendingLoads = pendingLoads,
        pendingTooltipReads = pendingTooltipReads,
        primedItems = primedItems,
        currentCell = currentCell,
    }
end

local function TestPublicInterfaceAndMigration()
    local env = ResetEnvironment("WARRIOR", nil)
    AssertEqual(BiaoGe.FilterClassItemDB, nil, "legacy filter DB should be removed")
    AssertEqual(BiaoGe.filterClassNum, nil, "legacy filter index should be removed")
    AssertEqual(BiaoGe.options.specGearFilterCleanupVersion, 1, "cleanup version should be recorded")

    local keys = {}
    for key in pairs(env.module) do keys[key] = true end
    AssertTrue(keys.CreateUI and keys.CreateControls and keys.ApplyToCell
        and keys.ApplyToAuctionFrame and keys.RefreshCurrentTable,
        "public methods should exist")
    local count = 0
    for _ in pairs(keys) do count = count + 1 end
    AssertEqual(count, 5, "module should expose only the five supported methods")
end

local function TestFilterResultCallback()
    local env = ResetEnvironment("WARRIOR", "arms_fury")
    local filtered
    env.module.ApplyToCell(NewCell(ItemLink(100)), nil, function(result)
        filtered = result
    end)
    AssertEqual(filtered, true, "callback should report filtered items")

    env.module.ApplyToCell(NewCell(ItemLink(101)), nil, function(result)
        filtered = result
    end)
    AssertEqual(filtered, false, "callback should report allowed items")

    BiaoGe.options.specGearFilterByClass.WARRIOR = nil
    env.module.ApplyToCell(NewCell(ItemLink(100)), nil, function(result)
        filtered = result
    end)
    AssertEqual(filtered, false, "callback should report false while filtering is disabled")
end

local function NewAuctionFrame(itemID)
    local frame = {
        itemID = itemID,
        link = ItemLink(itemID),
        itemFrame = NewCell(ItemLink(itemID)),
        collapseCount = 0,
    }
    frame.hide = {
        Click = function()
            AssertEqual(frame.notClick, true, "automatic collapse should suppress normal click side effects")
            frame.IsSmallWindow = true
            frame.collapseCount = frame.collapseCount + 1
        end,
    }
    return frame
end

local function TestAuctionAutoCollapse()
    local env = ResetEnvironment("WARRIOR", "arms_fury")
    BiaoGe.options.autoAuctionFold = 1

    local filtered = NewAuctionFrame(100)
    env.module.ApplyToAuctionFrame(filtered, false)
    AssertEqual(filtered.collapseCount, 1, "filtered auction should collapse")
    AssertEqual(filtered.notClick, false, "automatic collapse should restore click state")

    env.module.ApplyToAuctionFrame(filtered)
    AssertEqual(filtered.collapseCount, 1, "an already collapsed auction should not toggle open")

    local allowed = NewAuctionFrame(101)
    env.module.ApplyToAuctionFrame(allowed, false)
    AssertEqual(allowed.collapseCount, 0, "allowed auction should stay expanded")

    local followed = NewAuctionFrame(100)
    env.module.ApplyToAuctionFrame(followed, true)
    AssertEqual(followed.collapseCount, 0, "followed or wishlisted auction should stay expanded")

    local accountBound = NewAuctionFrame(111)
    env.module.ApplyToAuctionFrame(accountBound, false)
    AssertEqual(accountBound.collapseCount, 0, "account-bound auction should stay expanded")

    BiaoGe.options.autoAuctionFold = 0
    local optionDisabled = NewAuctionFrame(100)
    env.module.ApplyToAuctionFrame(optionDisabled, false)
    AssertEqual(optionDisabled.collapseCount, 0, "disabled auto-collapse option should keep auctions expanded")

    BiaoGe.options.autoAuctionFold = 1
    BiaoGe.options.specGearFilterByClass.WARRIOR = nil
    local filterDisabled = NewAuctionFrame(100)
    env.module.ApplyToAuctionFrame(filterDisabled, false)
    AssertEqual(filterDisabled.collapseCount, 0, "disabled gear filter should keep auctions expanded")
end

local function TestAsyncAuctionAutoCollapse()
    local env = ResetEnvironment("WARRIOR", "arms_fury", true)
    BiaoGe.options.autoAuctionFold = 1

    local filtered = NewAuctionFrame(100)
    env.module.ApplyToAuctionFrame(filtered, false)
    AssertEqual(filtered.collapseCount, 0, "auction should wait for uncached item metadata")
    env.pendingLoads[1].callback()
    AssertEqual(filtered.collapseCount, 1, "auction should collapse after item metadata loads")

    local stale = NewAuctionFrame(102)
    env.module.ApplyToAuctionFrame(stale, false)
    BiaoGe.options.specGearFilterByClass.WARRIOR = nil
    env.pendingLoads[2].callback()
    AssertEqual(stale.collapseCount, 0, "stale filter result should not collapse an auction")
end

local function TestRulesAndExemption()
    local env = ResetEnvironment("WARRIOR", "arms_fury")
    local cell = NewCell(ItemLink(100))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "arms/fury should keep filtered daggers readable at reduced emphasis")

    cell:SetText(ItemLink(101))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "arms/fury should allow two-handed swords")

    cell:SetText(ItemLink(102))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "arms/fury should keep filtered shields readable at reduced emphasis")

    cell:SetText(ItemLink(103))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "cloak should bypass armor type but still use stat rules")

    cell:SetText(ItemLink(108))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "blocked offhands should dim only holdable offhands")

    cell:SetText(ItemLink(109))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "physical scheme should dim spell-power trinkets")

    cell:SetText(ItemLink(110))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "physical scheme should allow attack-power trinkets")

    cell:SetText(ItemLink(111))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "account-bound exemption should override weapon and stat rules")

    cell:SetText(ItemLink(112))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "another class restriction should dim")

    cell:SetText(ItemLink(113))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "current class restriction should remain bright")

    cell:SetText(ItemLink(107))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "recipes should always remain bright")

    cell:SetText(ItemLink(114))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "another class's relic should dim")

    cell:SetText(ItemLink(115))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "another class's tier token should dim")

    cell:SetText(ItemLink(116))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "warrior tier token should stay bright")

    cell:SetText(ItemLink(117))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "critical strike does not make spell-power gear suitable")

    cell:SetText(ItemLink(118))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "class restriction should be checked on its own tooltip line")

    local paladinEnv = ResetEnvironment("PALADIN", "class")
    local libramCell = NewCell(ItemLink(114))
    paladinEnv.module.ApplyToCell(libramCell)
    AssertEqual(libramCell.alpha, 1, "paladin class scheme should allow librams")

    local missingConstantEnv = ResetEnvironment("WARRIOR", "arms_fury", false, true)
    local missingConstantCell = NewCell(ItemLink(111))
    missingConstantEnv.module.ApplyToCell(missingConstantCell)
    AssertEqual(missingConstantCell.alpha, 0.6, "missing account-bound constant should safely skip the exemption")
end

local function TestTooltipPrimingBeforeClassification()
    local env = ResetEnvironment("WARRIOR", "arms_fury", false, false, true)
    local tooltipReady = false
    env.BG.GetTooltipTextLeftAll = function(item)
        if tonumber(tostring(item):match("item:(%d+)")) == 115 then
            return tooltipReady and "Classes: Mage" or ""
        end
        return tooltipReady and "Critical Strike\nSpell Power" or "Critical Strike"
    end

    local tierToken = NewCell(ItemLink(115))
    local casterGear = NewCell(ItemLink(117))
    env.module.ApplyToCell(tierToken)
    env.module.ApplyToCell(casterGear)
    AssertEqual(#env.primedItems, 2, "uncached item tooltips should be primed")
    AssertEqual(#env.pendingTooltipReads, 2, "classification should wait for primed tooltip text")
    AssertEqual(tierToken.alpha, 1, "pending tier token should start bright")
    AssertEqual(casterGear.alpha, 1, "pending caster gear should start bright")

    tooltipReady = true
    env.pendingTooltipReads[1]()
    env.pendingTooltipReads[2]()
    AssertEqual(#env.pendingTooltipReads, 4, "first read should be checked again before caching")
    env.pendingTooltipReads[3]()
    env.pendingTooltipReads[4]()
    AssertEqual(tierToken.alpha, 0.6, "other-class tier token should dim when tooltip is ready")
    AssertEqual(casterGear.alpha, 0.6, "critical-strike spell-power gear should dim when tooltip is ready")
end

local function TestChineseCasterAndTierTooltip()
    ITEM_DATA[19905] = {
        equipLoc = "INVTYPE_FINGER", typeID = 4, subclassID = 0,
        tooltip = "+52 智力\n装备：爆击等级提高36点。\n装备：法术强度提高70点。",
    }
    ITEM_DATA[19906] = { equipLoc = "", typeID = 4, subclassID = 0, tooltip = "职业：法师" }
    local env = ResetEnvironment("WARRIOR", "arms_fury", false, false, false, "zhCN")
    local casterItem = NewCell(ItemLink(19905))
    env.module.ApplyToCell(casterItem)
    AssertEqual(casterItem.alpha, 0.6, "Chinese critical-strike spell-power item should dim")
    local tierToken = NewCell(ItemLink(19906))
    env.module.ApplyToCell(tierToken)
    AssertEqual(tierToken.alpha, 0.6, "Chinese class-restricted tier token should dim")
end

local function TestEmptyTooltipRetryAndStaleItem()
    local env = ResetEnvironment("WARRIOR", "arms_fury", false, false, true)
    local tooltipReady = false
    env.BG.GetTooltipTextLeftAll = function()
        return tooltipReady and "Spell Power" or ""
    end
    local cell = NewCell(ItemLink(109))
    env.module.ApplyToCell(cell)
    env.pendingTooltipReads[1]()
    AssertEqual(#env.pendingTooltipReads, 2, "empty tooltip should be retried")
    tooltipReady = true
    env.pendingTooltipReads[2]()
    AssertEqual(cell.alpha, 0.6, "retry should classify newly populated tooltip")

    local stale = NewCell(ItemLink(115))
    env.module.ApplyToCell(stale)
    stale:SetText(ItemLink(110))
    env.module.ApplyToCell(stale)
    env.pendingTooltipReads[3]()
    AssertEqual(stale.alpha, 1, "stale tooltip callback should not dim replacement item")
end

local function TestPartialTooltipRetry()
    local env = ResetEnvironment("WARRIOR", "arms_fury", false, false, true)
    local complete = false
    env.BG.GetTooltipTextLeftAll = function()
        return complete and "Critical Strike\nSpell Power" or "Critical Strike"
    end
    local cell = NewCell(ItemLink(117))
    env.module.ApplyToCell(cell)
    env.pendingTooltipReads[1]()
    AssertEqual(#env.pendingTooltipReads, 2, "initial allowed result should wait for complete tooltip")
    complete = true
    env.pendingTooltipReads[2]()
    AssertEqual(cell.alpha, 0.6, "late spell-power line should still dim item")
end

local function TestTankRules()
    local env = ResetEnvironment("WARRIOR", "protection")
    local cell = NewCell(ItemLink(104))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 0.6, "tank armor without tank stats should dim")

    cell:SetText(ItemLink(105))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "tank armor with defense should remain bright")

    cell:SetText(ItemLink(106))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "trinkets should be exempt from the tank-stat requirement")
end

local function TestDisabledAndInvalidSchemes()
    local env = ResetEnvironment("WARRIOR", nil)
    local cell = NewCell(ItemLink(100))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "filter should be disabled by default")

    env = ResetEnvironment("WARRIOR", "removed_legacy_key")
    AssertEqual(BiaoGe.options.specGearFilterByClass.WARRIOR, nil, "invalid scheme should be cleared")
    cell = NewCell(ItemLink(100))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "invalid scheme should fall back to disabled")
end

local function TestSchemeButtonsAndPersistence()
    local expectedKeys = {
        DEATHKNIGHT = { "class", "blood", "frost_unholy" },
        WARRIOR = { "class", "protection", "arms_fury" },
        PALADIN = { "class", "protection", "retribution", "holy" },
        HUNTER = { "class" },
        SHAMAN = { "class", "enhancement", "elemental", "restoration" },
        DRUID = { "class", "bear", "cat", "balance", "restoration" },
        ROGUE = { "class" },
        PRIEST = { "class", "shadow", "discipline_holy" },
        MAGE = { "class" },
        WARLOCK = { "class" },
    }
    for classFile, keys in pairs(expectedKeys) do
        local env = ResetEnvironment(classFile, nil)
        env.module.CreateUI()
        AssertEqual(#env.buttons, #keys, classFile .. " button count")
        for index, key in ipairs(keys) do
            AssertEqual(env.buttons[index].scheme.key, key, classFile .. " stable scheme key " .. index)
        end
    end

    local deathKnight = ResetEnvironment("DEATHKNIGHT", nil)
    deathKnight.module.CreateUI()
    AssertEqual(deathKnight.buttons[3].scheme.icon, "Interface/Icons/spell_deathknight_frostpresence", "merged frost/unholy should reuse frost icon")
    local priest = ResetEnvironment("PRIEST", nil)
    priest.module.CreateUI()
    AssertEqual(priest.buttons[3].scheme.icon, "Interface/Icons/spell_holy_wordfortitude", "merged discipline/holy should reuse discipline icon")

    local env = ResetEnvironment("WARRIOR", nil)
    env.module.CreateUI()
    AssertEqual(env.labels[1].text, "装备过滤", "filter controls should have a short visible label")
    env.buttons[3].scripts.OnClick(env.buttons[3])
    AssertEqual(BiaoGe.options.specGearFilterByClass.WARRIOR, "arms_fury", "button should store stable scheme key")
    AssertEqual(env.labels[1].text, "装备过滤",
        "filter label should stay short when a scheme is selected")
    env.buttons[3].scripts.OnClick(env.buttons[3])
    AssertEqual(BiaoGe.options.specGearFilterByClass.WARRIOR, nil, "clicking selected scheme should disable")
    AssertEqual(env.labels[1].text, "装备过滤",
        "filter label should stay unchanged when filtering is disabled")

    BiaoGe.options.specGearFilterByClass.MAGE = "class"
    AssertEqual(BiaoGe.options.specGearFilterByClass.WARRIOR, nil, "class selections should remain independent")
    AssertEqual(BiaoGe.options.specGearFilterByClass.MAGE, "class", "another class selection should be preserved")
end

local function TestSynchronizedControlGroups()
    local env = ResetEnvironment("WARRIOR", nil)
    env.module.CreateUI()
    local wishlistControls = env.module.CreateControls({})
    AssertTrue(wishlistControls, "wishlist should be able to mount another filter control group")
    AssertEqual(#env.buttons, 6, "two warrior control groups should each expose three schemes")

    env.buttons[3].scripts.OnClick(env.buttons[3])
    AssertEqual(BiaoGe.options.specGearFilterByClass.WARRIOR, "arms_fury",
        "table controls should update the shared selected scheme")
    AssertEqual(env.buttons[3].highlight.shown, true, "table control should show the selected scheme")
    AssertEqual(env.buttons[6].highlight.shown, true, "wishlist control should mirror the selected scheme")
    AssertEqual(env.labels[1].text, "装备过滤",
        "table filter label should stay short")
    AssertEqual(env.labels[2].text, "装备过滤",
        "wishlist filter label should stay short")
    AssertEqual(env.buttons[3].icon.desaturated, false, "selected table icon should stay saturated")
    AssertEqual(env.buttons[6].icon.desaturated, false, "selected wishlist icon should stay saturated")

    env.buttons[6].scripts.OnClick(env.buttons[6])
    AssertEqual(BiaoGe.options.specGearFilterByClass.WARRIOR, nil,
        "clicking the selected wishlist scheme should disable the shared filter")
    AssertEqual(env.buttons[3].highlight.shown, false, "table controls should mirror wishlist changes")
    AssertEqual(env.buttons[6].highlight.shown, false, "wishlist selection should clear")
end

local function TestAsyncStaleCallbacks()
    local env = ResetEnvironment("WARRIOR", "arms_fury", true)
    local cell = NewCell(ItemLink(100))
    env.module.ApplyToCell(cell)
    AssertEqual(cell.alpha, 1, "pending items should start bright")

    cell:SetText(ItemLink(101))
    env.module.ApplyToCell(cell)
    env.pendingLoads[1].callback()
    AssertEqual(cell.alpha, 1, "stale callback must not dim replacement content")
    env.pendingLoads[2].callback()
    AssertEqual(cell.alpha, 1, "current callback should classify replacement content")

    local secondCell = NewCell(ItemLink(100))
    env.module.ApplyToCell(secondCell)
    BiaoGe.options.specGearFilterByClass.WARRIOR = nil
    env.pendingLoads[3].callback()
    AssertEqual(secondCell.alpha, 1, "callback from a previous scheme must be ignored")

    BiaoGe.options.specGearFilterByClass.WARRIOR = "arms_fury"
    local oldTableCell = NewCell(ItemLink(100))
    env.module.ApplyToCell(oldTableCell)
    env.BG.FB1 = "ANOTHER_TABLE"
    env.pendingLoads[4].callback()
    AssertEqual(oldTableCell.alpha, 1, "callback from a previous table must be ignored")
end

local function TestCurrentTableScope()
    local env = ResetEnvironment("WARRIOR", "arms_fury")
    env.currentCell:SetText(ItemLink(100))
    local unrelatedCell = NewCell(ItemLink(100))
    local auctionLogCell = NewCell(ItemLink(100))
    local auctioningItemFrame = NewCell(ItemLink(100))
    local auctioningFrame = {
        itemFrame = auctioningItemFrame,
        link = ItemLink(100),
    }
    BGA = { Frames = { auctioningFrame } }
    env.BG.auctionLogFrame = {
        buttons = {
            { frame = auctionLogCell, link = ItemLink(100) },
        },
    }
    local wishlistRefreshCount = 0
    env.BG.Wishlist = {
        Refresh = function() wishlistRefreshCount = wishlistRefreshCount + 1 end,
    }
    env.module.RefreshCurrentTable()
    AssertEqual(env.currentCell.alpha, 0.6, "current table cell should refresh")
    AssertEqual(auctionLogCell.alpha, 0.6, "automatic auction log item should refresh")
    AssertEqual(auctioningItemFrame.alpha, 0.6, "active auction item should refresh")
    AssertEqual(unrelatedCell.alpha, nil, "unrelated frames should remain untouched")
    AssertEqual(wishlistRefreshCount, 1, "filter changes should refresh the wishlist view")

    BiaoGe.options.specGearFilterByClass.WARRIOR = nil
    env.module.RefreshCurrentTable()
    AssertEqual(env.currentCell.alpha, 1, "disabling should restore current table opacity")
    AssertEqual(auctionLogCell.alpha, 1, "disabling should restore automatic auction log opacity")
    AssertEqual(auctioningItemFrame.alpha, 1, "disabling should restore active auction item opacity")
end

TestPublicInterfaceAndMigration()
TestFilterResultCallback()
TestAuctionAutoCollapse()
TestAsyncAuctionAutoCollapse()
TestRulesAndExemption()
TestTooltipPrimingBeforeClassification()
TestChineseCasterAndTierTooltip()
TestEmptyTooltipRetryAndStaleItem()
TestPartialTooltipRetry()
TestTankRules()
TestDisabledAndInvalidSchemes()
TestSchemeButtonsAndPersistence()
TestSynchronizedControlGroups()
TestAsyncStaleCallbacks()
TestCurrentTableScope()
print("SpecGearFilter regression tests passed")

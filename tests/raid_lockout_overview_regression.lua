local sourcePath = "Core/Module/RaidLockoutOverview.lua"

local function ResetEnvironment()
    BiaoGe = nil
    UNKNOWN = "Unknown"
    NUM_BAG_SLOTS = 4
    BANK_CONTAINER = -1
    NUM_BANKBAGSLOTS = 7
    SlashCmdList = {}

    floor = math.floor
    max = math.max
    min = math.min
    sort = table.sort
    tremove = table.remove
    unpack = table.unpack

    GetRealmID = function()
        return 100
    end
    UnitName = function()
        return "Tester"
    end
    UnitClass = function()
        return "Warrior", "WARRIOR"
    end
    GetClassColor = function()
        return 0.78, 0.61, 0.43, "ffc79c6e"
    end
    UnitLevel = function()
        return 80
    end
    GetAverageItemLevel = function()
        return 245, 245
    end
    GetActiveTalentGroup = function()
        return 1
    end
    GetTalentTabInfo = function(index)
        return nil, nil, nil, nil, index == 1 and 51 or 0
    end
    GetMoney = function()
        return 1230000
    end
    GetServerTime = function()
        return 1700000000
    end
    GetInventoryItemLink = function()
        return nil
    end
    GetInventoryItemID = function()
        return nil
    end
    GetInventoryItemTexture = function()
        return nil
    end
    GetInventoryItemQuality = function()
        return nil
    end

    C_Item = {
        GetItemCount = function()
            return 0
        end,
    }
    C_Container = {
        GetContainerNumSlots = function()
            return 0
        end,
        GetContainerItemInfo = function()
            return nil
        end,
    }
    C_CurrencyInfo = nil

    local events = {}
    local BG = {
        playerName = "Tester",
        verOver4 = false,
        FormatNumber = function(value)
            return tostring(value)
        end,
        After = function(_, callback)
            callback()
        end,
        RegisterEvent = function(eventNames, callback)
            if type(eventNames) == "table" then
                for _, eventName in ipairs(eventNames) do
                    events[eventName] = callback
                end
            else
                events[eventNames] = callback
            end
        end,
        Init2 = function(callback)
            BG.initCallback = callback
        end,
    }
    _G.BG = BG
    local L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })

    assert(loadfile(sourcePath))("BGForge", { L = L, BG = BG })
    return BG, events
end

local function GetStoredCharacter()
    return BiaoGe.BGForgeRaidLockouts.realms[100].characters.Tester
end

local function FindUpvalue(callback, targetName)
    for index = 1, 100 do
        local name, value = debug.getupvalue(callback, index)
        if not name then
            return nil
        end
        if name == targetName then
            return value
        end
    end
end

local function TestSkillLineFallbackCapturesPrimaryProfessions()
    local _, events = ResetEnvironment()
    GetProfessions = nil
    GetProfessionInfo = nil
    GetNumSkillLines = function()
        return 4
    end
    GetSkillLineInfo = function(index)
        local rows = {
            { "Professions", true },
            { "Engineering", false, 315, 315 },
            { "Cooking", false, 450, 450 },
            { "Mining", false, 300, 300 },
        }
        local row = rows[index]
        return row[1], row[2], nil, row[3], nil, nil, row[4]
    end

    assert(events.SKILL_LINES_CHANGED, "SKILL_LINES_CHANGED handler is missing")
    events.SKILL_LINES_CHANGED()

    local professions = GetStoredCharacter().professions
    assert(#professions == 2, "expected two primary professions from the skill-line fallback")
    assert(professions[1].skillLineID == 202 and professions[1].rank == 315,
        "expected Engineering rank 315")
    assert(professions[2].skillLineID == 186 and professions[2].rank == 300,
        "expected Mining rank 300")
end

local function TestUnavailableProfessionDataDoesNotEraseSnapshot()
    local _, events = ResetEnvironment()
    GetProfessions = nil
    GetProfessionInfo = nil
    GetNumSkillLines = function()
        return 0
    end
    GetSkillLineInfo = function()
        return nil
    end
    BiaoGe = {
        BGForgeRaidLockouts = {
            schemaVersion = 1,
            realms = {
                [100] = {
                    nextOrder = 2,
                    characters = {
                        Tester = {
                            name = "Tester",
                            order = 1,
                            instances = {},
                            professions = {
                                { skillLineID = 202, rank = 315, maxRank = 315, iconFileID = 136243 },
                            },
                        },
                    },
                },
            },
        },
    }

    events.SKILL_LINES_CHANGED()

    local professions = GetStoredCharacter().professions
    assert(#professions == 1 and professions[1].skillLineID == 202,
        "temporarily unavailable profession data erased the saved snapshot")
end

local function TestPrimaryProfessionAPICapturesExpectedFields()
    local _, events = ResetEnvironment()
    GetProfessions = function()
        return 7, 9
    end
    GetProfessionInfo = function(index)
        if index == 7 then
            return "Engineering", 136243, 315, 315, nil, nil, 202
        end
        return "Mining", 136248, 300, 300, nil, nil, 186
    end
    GetNumSkillLines = nil
    GetSkillLineInfo = nil

    events.SKILL_LINES_CHANGED()

    local professions = GetStoredCharacter().professions
    assert(#professions == 2, "expected two professions from the primary API")
    assert(professions[1].skillLineID == 202 and professions[1].rank == 315
        and professions[1].iconFileID == 136243, "primary API fields were mapped incorrectly")
end

local function TestIncompletePrimaryAPIUsesSkillLineFallback()
    local _, events = ResetEnvironment()
    GetProfessions = function()
        return 7, 9
    end
    GetProfessionInfo = function()
        return nil
    end
    GetNumSkillLines = function()
        return 2
    end
    GetSkillLineInfo = function(index)
        if index == 1 then
            return "Engineering", false, nil, 315, nil, nil, 315
        end
        return "Mining", false, nil, 300, nil, nil, 300
    end

    events.SKILL_LINES_CHANGED()

    local professions = GetStoredCharacter().professions
    assert(#professions == 2 and professions[1].skillLineID == 202,
        "incomplete primary API data did not use the skill-line fallback")
end

local function TestRaidColumnsFillAvailableWidth()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local calculateWidths = FindUpvalue(createHoverFrame, "CalculateRaidColumnWidths")
    assert(calculateWidths, "dynamic raid-column width calculation is missing")

    local raids = {
        { id = 1, compactWidth = 50 },
        { id = 2, compactWidth = 70 },
        { id = 3, compactWidth = 42 },
    }
    local widths, totalWidth = calculateWidths(raids, 744)
    assert(math.abs(totalWidth - 744) < 0.001, "raid columns did not fill the available width")
    assert(widths[1] > 50 and widths[2] > 70 and widths[3] > 42,
        "the available width was not distributed across every raid column")
end

local function TestEquipmentUsesIconTilesWithTopLeftValues()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local calculateLayout = FindUpvalue(createHoverFrame, "CalculateItemStripLayout")
    assert(calculateLayout, "equipment icon-tile layout is missing")

    local visibleCount, startX, iconSize = calculateLayout(100, 2)
    assert(visibleCount == 2, "both equipped trinkets should be visible")
    assert(iconSize > 16, "equipment icons were not enlarged")
    assert(startX > 0, "equipment icons should be centered in their cell")
end

local function TestCollapsedSkillHeadersExpandOnceWithoutEventLoop()
    local BG, events = ResetEnvironment()
    GetProfessions = nil
    GetProfessionInfo = nil

    local expanded = false
    GetNumSkillLines = function()
        return expanded and 3 or 1
    end
    GetSkillLineInfo = function(index)
        if index == 1 then
            return "Professions", true, expanded
        elseif index == 2 then
            return "Engineering", false, nil, 315, nil, nil, 315
        end
        return "Mining", false, nil, 300, nil, nil, 300
    end

    local callbacks = {}
    BG.After = function(_, callback)
        callbacks[#callbacks + 1] = callback
    end
    local expandCalls = 0
    ExpandSkillHeader = function()
        expandCalls = expandCalls + 1
        expanded = true
        events.SKILL_LINES_CHANGED()
    end

    events.SKILL_LINES_CHANGED()
    local processed = 0
    while #callbacks > 0 and processed < 25 do
        processed = processed + 1
        local callback = table.remove(callbacks, 1)
        callback()
    end

    assert(#callbacks == 0, "profession refresh created an unbounded event loop")
    assert(expandCalls == 1, "collapsed skill headers should be expanded exactly once")
    local professions = GetStoredCharacter().professions
    assert(#professions == 2, "professions were not captured after expanding the skill header")
end

local function TestResourceRefreshEventsAreDebounced()
    local BG, events = ResetEnvironment()
    GetProfessions = function()
        return nil, nil
    end
    GetProfessionInfo = function()
        return nil
    end
    GetNumSkillLines = function()
        return 1
    end
    GetSkillLineInfo = function()
        return "Engineering", false, nil, 315, nil, nil, 315
    end
    ExpandSkillHeader = nil

    local callbacks = {}
    BG.After = function(_, callback)
        callbacks[#callbacks + 1] = callback
    end
    local captures = 0
    GetMoney = function()
        captures = captures + 1
        return 1230000
    end

    events.PLAYER_MONEY()
    events.CURRENCY_DISPLAY_UPDATE()
    events.BAG_UPDATE_DELAYED()
    events.GET_ITEM_INFO_RECEIVED(nil, nil, nil, true)
    while #callbacks > 0 do
        local callback = table.remove(callbacks, 1)
        callback()
    end

    assert(captures == 1, "bursty resource events should produce one resource capture")
end

local function TestUpgradeItemsAreExcludedFromFinishedLegendaries()
    local _, events = ResetEnvironment()
    GetProfessions = function()
        return nil, nil
    end
    GetProfessionInfo = function()
        return nil
    end
    GetNumSkillLines = function()
        return 1
    end
    GetSkillLineInfo = function()
        return "Engineering", false, nil, 315, nil, nil, 315
    end
    ExpandSkillHeader = nil

    local function GetTestItemID(itemInfo)
        if type(itemInfo) == "number" then
            return itemInfo
        end
        return tonumber(tostring(itemInfo):match("item:(%d+)"))
    end

    GetItemInfoInstant = function(itemInfo)
        local itemID = GetTestItemID(itemInfo)
        return itemID, nil, nil, "INVTYPE_NECK", itemID and itemID + 100000
    end
    GetItemInfo = function(itemInfo)
        local itemID = GetTestItemID(itemInfo)
        return "Test Item", "item:" .. tostring(itemID), 5
    end
    C_Item = {
        GetItemCount = function(itemID)
            return itemID == 265340 and 1 or 0
        end,
        GetDetailedItemLevelInfo = function(itemInfo)
            return GetTestItemID(itemInfo) == 265340 and 1 or 251
        end,
    }
    C_Container = {
        GetContainerNumSlots = function(containerID)
            return containerID == 0 and 2 or 0
        end,
        GetContainerItemInfo = function(_, slotID)
            local itemID = slotID == 1 and 265340 or 264750
            return {
                hyperlink = "item:" .. itemID,
                itemID = itemID,
                iconFileID = itemID + 100000,
                quality = 5,
            }
        end,
    }
    BiaoGe = {
        BGForgeRaidLockouts = {
            schemaVersion = 1,
            realms = {
                [100] = {
                    nextOrder = 2,
                    characters = {
                        Tester = {
                            name = "Tester",
                            order = 1,
                            instances = {},
                            bankLegendaryItems = {
                                {
                                    itemID = 265340,
                                    link = "item:265340",
                                    itemLevel = 1,
                                    iconFileID = 365340,
                                    quality = 5,
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    events.PLAYER_MONEY()

    local stored = GetStoredCharacter()
    assert(#stored.legendaryItems == 1 and stored.legendaryItems[1].itemID == 264750,
        "upgrade items leaked into finished legendary equipment")
    assert(#stored.legendaryUpgradeItems == 1
        and stored.legendaryUpgradeItems[1].itemID == 265340
        and stored.legendaryUpgradeItems[1].count == 1,
        "the real legendary upgrade item was not counted correctly")
end

local function TestItemTileDisplayUsesRequestedQualitySemantics()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local getDisplay = FindUpvalue(createHoverFrame, "GetItemTileDisplay")
    assert(getDisplay, "item display-quality semantics are missing")

    local quality, valueText = getDisplay({ quality = 4, itemLevel = 245 }, "itemLevel")
    assert(quality == 4 and valueText == "245", "epic trinkets must use epic quality")
    quality, valueText = getDisplay({ quality = 3, itemLevel = 232 }, "itemLevel")
    assert(quality == 3 and valueText == "232", "rare trinkets must use rare quality")
    quality, valueText = getDisplay({ quality = 2, itemLevel = 251 }, "itemLevel", 5)
    assert(quality == 5 and valueText == "251", "finished legendaries must use legendary quality")
    quality, valueText = getDisplay({ quality = 2, count = 1 }, "count", 5, "×")
    assert(quality == 5 and valueText == "×1", "upgrade-item counts must be clearly marked and orange")
end

local function TestCharacterVisibilityCanBeRestored()
    local BG, events = ResetEnvironment()
    GetProfessions = function()
        return nil, nil
    end
    GetProfessionInfo = function()
        return nil
    end
    GetNumSkillLines = function()
        return 1
    end
    GetSkillLineInfo = function()
        return "Engineering", false, nil, 315, nil, nil, 315
    end
    ExpandSkillHeader = nil

    events.PLAYER_MONEY()
    assert(BG.SetRaidLockoutCharacterHidden, "character hide/restore API is missing")
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    local getVisibleRows = FindUpvalue(createHoverFrame, "GetCharacterRows")
    assert(getVisibleRows and #getVisibleRows() == 1, "recorded character should initially be visible")

    assert(BG.SetRaidLockoutCharacterHidden(100, "Tester", true), "failed to hide character")
    local storedCharacters = BG.GetRaidLockoutStoredCharacters(100)
    assert(#storedCharacters == 1 and storedCharacters[1].isHidden,
        "hidden character must remain available to the settings page")
    assert(#getVisibleRows() == 0, "hidden character still appeared in the overview")

    GetMoney = function()
        return 4560000
    end
    events.PLAYER_MONEY()
    storedCharacters = BG.GetRaidLockoutStoredCharacters(100)
    assert(storedCharacters[1].money == 4560000,
        "hidden characters must continue receiving current-character snapshots")

    assert(BG.SetRaidLockoutCharacterHidden(100, "Tester", false), "failed to restore character")
    assert(#getVisibleRows() == 1, "restored character did not return to the overview")
end

local function TestItemTilesUseNativeGameTooltip()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    local showTooltip = FindUpvalue(createHoverFrame, "ShowItemTooltip")
    assert(showTooltip, "native item-tooltip integration is missing")

    local calls = {}
    GameTooltip = {
        SetOwner = function(_, owner, anchor)
            calls.owner = owner
            calls.anchor = anchor
        end,
        ClearLines = function()
            calls.cleared = true
        end,
        SetHyperlink = function(_, link)
            calls.link = link
        end,
        SetItemByID = function(_, itemID)
            calls.itemID = itemID
        end,
        Show = function()
            calls.shown = true
        end,
    }
    local owner = {}
    BG.ButtonIsInRight = function()
        return false
    end

    showTooltip(owner, { link = "item:264750", itemID = 264750 })
    assert(calls.owner == owner and calls.anchor == "ANCHOR_RIGHT",
        "item tooltip was not anchored to the icon")
    assert(calls.link == "item:264750" and not calls.itemID,
        "complete item links must be preferred for accurate equipment details")
    assert(calls.cleared and calls.shown, "native GameTooltip was not displayed")

    calls = {}
    showTooltip(owner, { itemID = 265340 })
    assert(calls.itemID == 265340, "item ID fallback did not use GameTooltip:SetItemByID")
end

local tests = {
    fallback = TestSkillLineFallbackCapturesPrimaryProfessions,
    preserve = TestUnavailableProfessionDataDoesNotEraseSnapshot,
    primary = TestPrimaryProfessionAPICapturesExpectedFields,
    incomplete_primary = TestIncompletePrimaryAPIUsesSkillLineFallback,
    raid_width = TestRaidColumnsFillAvailableWidth,
    item_tiles = TestEquipmentUsesIconTilesWithTopLeftValues,
    collapsed_headers = TestCollapsedSkillHeadersExpandOnceWithoutEventLoop,
    debounce = TestResourceRefreshEventsAreDebounced,
    legendary_classification = TestUpgradeItemsAreExcludedFromFinishedLegendaries,
    item_quality = TestItemTileDisplayUsesRequestedQualitySemantics,
    character_visibility = TestCharacterVisibilityCanBeRestored,
    native_tooltip = TestItemTilesUseNativeGameTooltip,
}

if arg[1] then
    assert(tests[arg[1]], "unknown test: " .. tostring(arg[1]))()
else
    for _, testName in ipairs({
        "fallback", "preserve", "primary", "incomplete_primary", "raid_width", "item_tiles",
        "collapsed_headers",
        "debounce",
        "legendary_classification",
        "item_quality",
        "character_visibility",
        "native_tooltip",
    }) do
        tests[testName]()
    end
end
print("raid lockout overview regression tests passed")

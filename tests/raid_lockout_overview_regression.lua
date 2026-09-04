local sourcePath = "Core/Module/RaidLockoutOverview.lua"

local function ResetEnvironment()
    BiaoGe = nil
    UNKNOWN = "Unknown"
    NUM_BAG_SLOTS = 4
    BANK_CONTAINER = -1
    NUM_BANKBAGSLOTS = 7
    SlashCmdList = {}

    floor = math.floor
    ceil = math.ceil
    max = math.max
    min = math.min
    sort = table.sort
    tremove = table.remove
    unpack = table.unpack or unpack

    GetRealmID = function()
        return 100
    end
    UnitName = function()
        return "Tester"
    end
    UnitClass = function()
        return "Warrior", "WARRIOR"
    end
    UnitRace = function()
        return "Human", "Human", 1
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
    GetTime = function()
        return 1000
    end
    IsPlayerSpell = nil
    IsSpellKnown = nil
    GetSpellCooldown = nil
    GetNumTradeSkills = nil
    GetTradeSkillInfo = nil
    GetTradeSkillLine = nil
    GetTradeSkillRecipeLink = nil
    GetTradeSkillCooldown = nil
    EJ_GetInstanceForMap = nil
    EJ_GetEncounterInfoByIndex = nil
    InCombatLockdown = nil
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
    GetItemInfoInstant = function(itemInfo)
        local itemID = tonumber(tostring(itemInfo):match("item:(%d+)") or itemInfo)
        return itemID, nil, nil, "", nil, 15
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
    C_DateAndTime = {
        GetSecondsUntilDailyReset = function()
            return 86400
        end,
        GetSecondsUntilWeeklyReset = function()
            return 604800
        end,
    }
    C_QuestLog = {
        IsQuestFlaggedCompleted = function()
            return false
        end,
    }
    C_Timer = nil

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
    local L = setmetatable({
        ["工程学"] = "Engineering",
        ["采矿"] = "Mining",
    }, {
        __index = function(_, key)
            return key
        end,
    })

    assert(loadfile("Core/UI/DesignSystem.lua"))("BGForge", {})
    assert(loadfile(sourcePath))("BGForge", { L = L, BG = BG })
    return BG, events, L
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

    local calculateResourceWidths = FindUpvalue(createHoverFrame, "CalculateResourceColumnWidths")
    assert(calculateResourceWidths, "dynamic resource-column width calculation is missing")
    local ui = {
        professionWidth = 100,
        legendaryWidth = 150,
        fragmentWidth = 100,
        upgradeWidth = 130,
        trinketWidth = 100,
        goldWidth = 88,
        emberWidth = 88,
        shardWidth = 88,
    }
    local resourceWidths, resourceTotal = calculateResourceWidths(ui, 1000)
    assert(math.abs(resourceTotal - 1000) < 0.001,
        "resource columns did not fill the same available width as the raid table")
    assert(resourceWidths.profession > ui.professionWidth
        and resourceWidths.shard > ui.shardWidth,
        "the extra resource-table width was not distributed across its columns")
end

local function TestWideFontHeadersExpandColumns()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local calculateMinimums = FindUpvalue(createHoverFrame, "CalculateMeasuredColumnMinimums")
    assert(calculateMinimums, "runtime header-width measurement is missing")
    local calculateWidths = FindUpvalue(createHoverFrame, "CalculateRaidColumnWidths")
    assert(calculateWidths, "dynamic raid-column width calculation is missing")

    local columns = {
        { id = 1, name = "太阳井", compactWidth = 50 },
        { id = 2, name = "纳克萨玛斯", compactWidth = 70 },
    }
    local measuredWidths = {
        ["太阳井"] = 45,
        ["纳克萨玛斯"] = 75,
    }
    local minimums, minimumTotal = calculateMinimums(columns, function(text)
        return measuredWidths[text]
    end)

    assert(minimums[1] >= 63,
        "wide three-character font would still be truncated by the 50-point column")
    assert(minimums[2] >= 93,
        "wide five-character font would still be truncated by the 70-point column")

    local widths, totalWidth = calculateWidths(columns, minimumTotal, minimums)
    assert(math.abs(totalWidth - minimumTotal) < 0.001,
        "measured minimum widths changed the compact table extent")
    assert(widths[1] >= minimums[1] and widths[2] >= minimums[2],
        "column layout ignored the measured font widths")
end

local function TestWideTablesUseScreenBoundedViewport()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local calculateViewport = FindUpvalue(createHoverFrame, "CalculateHorizontalViewport")
    assert(calculateViewport, "screen-bounded horizontal viewport calculation is missing")

    local viewportWidth, overflow = calculateViewport(1200, 1024)
    assert(viewportWidth == 992 and overflow == 208,
        "wide tables must preserve their content width behind a screen-bounded viewport")

    viewportWidth, overflow = calculateViewport(900, 1024)
    assert(viewportWidth == 900 and overflow == 0,
        "tables that fit the screen must not enable horizontal overflow")
end

local function TestHoverFrameStaysWithinTitanUpvalueLimit()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local count = 0
    for index = 1, 100 do
        if not debug.getupvalue(createHoverFrame, index) then
            break
        end
        count = count + 1
    end
    assert(count <= 60, "CreateHoverFrame exceeded Titan's 60-upvalue compiler limit")
end

local function TestPerCharacterEmberWeeklyProgressFormatting()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local formatResourceNumber = FindUpvalue(createHoverFrame, "FormatResourceNumber")
    local formatResourceAmount = FindUpvalue(createHoverFrame, "FormatResourceAmount")
    assert(formatResourceNumber and formatResourceAmount,
        "resource number formatters are missing")
    assert(formatResourceNumber(146, 13, 20) == "146（13/20）",
        "per-character Titan Ember progress did not include the weekly amount")
    assert(formatResourceNumber(146) == "146",
        "resources without weekly data must keep the compact amount")
    assert(not formatResourceAmount(349, 237048):find("（", 1, true),
        "the total Titan Ember row must not include weekly progress")
end

local function TestHoverFrameUsesDesignSystemPalette()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local colors = FindUpvalue(createHoverFrame, "COLOR")
    assert(colors, "hover frame palette is missing")

    local focus = BG.UI.Token("color", "focus")
    local forgeGold = BG.UI.Token("color", "forgeGold")
    assert(colors.focus[1] == focus[1] and colors.focus[2] == focus[2]
        and colors.focus[3] == focus[3],
        "hover interactions must use the shared focus color")
    assert(colors.gold[1] == forgeGold[1] and colors.gold[2] == forgeGold[2]
        and colors.gold[3] == forgeGold[3],
        "brand and resource emphasis must use the shared forge-gold color")
    assert(colors.row and not colors.rowEven,
        "standard character rows must share one base surface")
    assert(colors.current[1] ~= colors.gold[1] or colors.current[2] ~= colors.gold[2],
        "current-character selection must not fall back to the legacy gold row tint")
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

local function TestProfessionsUseMatchingIconTilesWithFixedColor()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    assert(createHoverFrame, "CreateHoverFrame upvalue is missing")
    local getDisplay = FindUpvalue(createHoverFrame, "GetProfessionTileDisplay")
    local tileColor = FindUpvalue(createHoverFrame, "PROFESSION_TILE_COLOR")
    assert(getDisplay, "profession icon-tile display is missing")
    assert(tileColor and #tileColor == 4, "profession tiles must use one fixed border/text color")

    local iconFileID, rankText = getDisplay({ iconFileID = 136243, rank = 450 })
    assert(iconFileID == 136243 and rankText == "450",
        "profession tiles must show the profession icon with its rank in the corner")
    assert(getDisplay({ rank = 450 }) == nil, "professions without an icon should not render an empty tile")
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

local function TestEquipmentSnapshotStoresOnlyDisplayFields()
    local _, events = ResetEnvironment()
    local links = {
        [1] = "|cffa335ee|Hitem:1001:2001:3001:0:0:0:0:0|h[Test Helm]|h|r",
        [16] = "|cffa335ee|Hitem:1016:0:0:0:0:0:0:0|h[Test Weapon]|h|r",
    }
    GetInventoryItemID = function(_, slotID)
        return links[slotID] and (1000 + slotID) or nil
    end
    GetInventoryItemLink = function(_, slotID)
        return links[slotID]
    end
    C_Item.GetDetailedItemLevelInfo = function(link)
        return link == links[1] and 245 or 251
    end

    events.PLAYER_EQUIPMENT_CHANGED()
    local stored = GetStoredCharacter()
    local details = stored.details
    assert(details and details.schemaVersion == 1, "character detail schema was not created")
    assert(details.equipment.updatedAt == 1700000000,
        "equipment snapshot did not use server time")
    assert(details.equipment.slots[1].link == links[1]
        and details.equipment.slots[1].itemLevel == 245,
        "equipped head item was not captured")
    assert(details.equipment.slots[16].link == links[16]
        and details.equipment.slots[16].itemLevel == 251,
        "equipped weapon was not captured")
    assert(details.equipment.slots[1].itemID == nil
        and details.equipment.slots[1].quality == nil
        and details.equipment.slots[1].durability == nil
        and details.equipment.slots[1].enchantID == nil
        and details.equipment.slots[1].gems == nil,
        "equipment snapshot persisted fields outside the approved minimal model")
    assert(stored.raceID == 1, "current character race identity was not captured")
end

local function TestEquipmentSnapshotCommitsAtomicallyAfterItemDataLoads()
    local _, events = ResetEnvironment()
    local ready = false
    local requests = 0
    GetInventoryItemID = function(_, slotID)
        return slotID == 1 and 1001 or nil
    end
    GetInventoryItemLink = function(_, slotID)
        return slotID == 1 and ready and "item:1001:0:0:0:0:0" or nil
    end
    C_Item.GetDetailedItemLevelInfo = function()
        return 245
    end
    C_Item.RequestLoadItemDataByID = function(itemID)
        assert(itemID == 1001, "unexpected item-data request")
        requests = requests + 1
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
                            details = {
                                schemaVersion = 1,
                                equipment = {
                                    updatedAt = 1699999000,
                                    slots = { [1] = { link = "item:999", itemLevel = 238 } },
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    events.PLAYER_EQUIPMENT_CHANGED()
    local equipment = GetStoredCharacter().details.equipment
    assert(equipment.updatedAt == 1699999000 and equipment.slots[1].link == "item:999",
        "an incomplete equipment scan overwrote the last complete snapshot")
    assert(requests == 1, "missing equipment data was not requested once")

    ready = true
    events.GET_ITEM_INFO_RECEIVED(nil, nil, 1001, true)
    equipment = GetStoredCharacter().details.equipment
    assert(equipment.updatedAt == 1700000000
        and equipment.slots[1].link == "item:1001:0:0:0:0:0",
        "loaded item data did not commit a complete equipment snapshot")
end

local function TestEquipmentRefreshEventsAreDebounced()
    local BG, events = ResetEnvironment()
    local callbacks = {}
    BG.After = function(_, callback)
        callbacks[#callbacks + 1] = callback
    end
    local slotReads = 0
    GetInventoryItemID = function()
        slotReads = slotReads + 1
        return nil
    end

    events.PLAYER_EQUIPMENT_CHANGED()
    events.PLAYER_EQUIPMENT_CHANGED()
    events.PLAYER_EQUIPMENT_CHANGED()
    while #callbacks > 0 do
        table.remove(callbacks, 1)()
    end
    assert(slotReads == 19,
        "bursty equipment events should collapse into one fixed 19-slot scan")
end

local function TestBackpackSnapshotStoresOnlyMinimalDisplayFields()
    local _, events = ResetEnvironment()
    local firstLink = "|cff0070dd|Hitem:2001:0:0:0:0:0|h[Test Stack]|h|r"
    local secondLink = "|cffa335ee|Hitem:2002:0:0:0:0:0|h[Test Item]|h|r"
    local thirdLink = "|cff1eff00|Hitem:2003:0:0:0:0:0|h[Test Bag]|h|r"
    C_Container.GetContainerNumSlots = function(bagID)
        return bagID == 0 and 4 or 0
    end
    C_Container.GetContainerItemInfo = function(bagID, slotID)
        if bagID ~= 0 then
            return nil
        elseif slotID == 1 then
            return { itemID = 2001, stackCount = 3, hyperlink = firstLink, quality = 3 }
        elseif slotID == 2 then
            return { itemID = 2001, stackCount = 2, hyperlink = firstLink, quality = 3 }
        elseif slotID == 3 then
            return { itemID = 2002, stackCount = 1, hyperlink = secondLink, quality = 4 }
        elseif slotID == 4 then
            return { itemID = 2003, stackCount = 1, hyperlink = thirdLink, quality = 2 }
        end
    end
    GetItemInfoInstant = function(link)
        if link == secondLink then
            return 2002, nil, nil, "INVTYPE_CHEST", nil, 4
        elseif link == thirdLink then
            return 2003, nil, nil, "INVTYPE_BAG", nil, 1
        end
        return 2001, nil, nil, "", nil, 0
    end
    C_Item.GetDetailedItemLevelInfo = function(link)
        if link == secondLink then
            return 238
        elseif link == thirdLink then
            return 20
        end
    end

    events.BAG_UPDATE_DELAYED()

    local backpack = GetStoredCharacter().details.backpack
    assert(backpack.updatedAt == 1700000000, "backpack snapshot did not use server time")
    assert(backpack.totalSlots == 4 and backpack.usedSlots == 4,
        "backpack slot summary was not captured")
    assert(#backpack.items == 3, "identical backpack item links were not compacted")
    assert(backpack.items[1].link == firstLink and backpack.items[1].count == 5,
        "stacked backpack item counts were not merged")
    assert(backpack.items[2].link == secondLink and backpack.items[2].count == 1
        and backpack.items[2].itemLevel == 238 and backpack.items[2].isEquipment == true
        and backpack.items[2].classID == 4,
        "equippable backpack item did not retain its display item level")
    assert(backpack.items[1].itemLevel == nil and backpack.items[1].isEquipment == false
        and backpack.items[1].classID == 0,
        "ordinary backpack item was not explicitly classified without an item level")
    assert(backpack.items[3].classID == 1 and backpack.items[3].isEquipment == false
        and backpack.items[3].itemLevel == nil,
        "containers must not be classified as weapon or armor equipment")
    assert(backpack.items[1].itemID == nil
        and backpack.items[1].quality == nil
        and backpack.items[1].bagID == nil
        and backpack.items[1].slotID == nil,
        "backpack snapshot persisted fields outside the approved minimal model")
end

local function TestBackpackBadgesFollowExplicitItemType()
    local BG, _, L = ResetEnvironment()
    GetItemInfo = function()
        return nil
    end
    GetItemInfoInstant = function(link)
        if link == "item:2002" then
            return 2002, nil, nil, "INVTYPE_CHEST", 4002, 4
        elseif link == "item:2003" then
            return 2003, nil, nil, "INVTYPE_BAG", 4003, 1
        end
        return 2001, nil, nil, "", 4001, 0
    end
    assert(loadfile("Core/Module/CharacterDetails.lua"))("BGForge", { L = L })

    local renderBackpack = FindUpvalue(BG.CharacterDetails.Refresh, "RenderBackpack")
    local setBackpackItemButton = FindUpvalue(renderBackpack, "SetBackpackItemButton")
    assert(setBackpackItemButton, "backpack item-button renderer is missing")

    local button = {
        icon = {
            SetTexture = function(self, value) self.texture = value end,
            SetDesaturated = function(self, value) self.desaturated = value end,
        },
        level = {
            SetText = function(self, value) self.text = tostring(value) end,
            SetTextColor = function() end,
        },
        SetBackdropBorderColor = function() end,
    }
    setBackpackItemButton(button, {
        link = "item:2002",
        count = 1,
        itemLevel = 238,
        isEquipment = true,
        classID = 4,
    })
    assert(button.level.text == "238", "backpack equipment must display its item level")

    setBackpackItemButton(button, {
        link = "item:2001",
        count = 1,
        itemLevel = 75,
        isEquipment = false,
    })
    assert(button.level.text == "",
        "ordinary backpack items with quantity one must hide their badge")

    setBackpackItemButton(button, {
        link = "item:2001",
        count = 35,
        isEquipment = false,
    })
    assert(button.level.text == "35", "stacked ordinary backpack items must display quantity")

    setBackpackItemButton(button, {
        link = "item:2003",
        count = 2,
        itemLevel = 20,
        isEquipment = true,
        classID = 1,
    })
    assert(button.level.text == "2", "containers with equip locations must still display quantity")
end

local function TestBackpackItemsAreGroupedByStableItemClass()
    local BG, _, L = ResetEnvironment()
    assert(loadfile("Core/Module/CharacterDetails.lua"))("BGForge", { L = L })
    local renderBackpack = FindUpvalue(BG.CharacterDetails.Refresh, "RenderBackpack")
    local buildBackpackGroups = FindUpvalue(renderBackpack, "BuildBackpackGroups")
    assert(buildBackpackGroups, "backpack renderer is missing stable item-class grouping")

    local groups = buildBackpackGroups({
        { link = "item:1", count = 5, classID = 0, isEquipment = false },
        { link = "item:2", count = 2, classID = 7, isEquipment = false },
        { link = "item:3", count = 1, classID = 4, isEquipment = true, itemLevel = 238 },
    })
    assert(#groups == 3, "expected three non-empty backpack groups")
    assert(groups[1].id == "consumable" and groups[1].items[1].link == "item:1",
        "consumables were not placed in the first group")
    assert(groups[2].id == "miscellaneous" and groups[2].items[1].link == "item:2",
        "non-consumable items were not placed in the miscellaneous group")
    assert(groups[3].id == "equipment" and groups[3].items[1].link == "item:3",
        "equipment was not placed in the equipment group")
end

local function TestBackpackSnapshotCommitsAtomicallyAfterItemDataLoads()
    local _, events = ResetEnvironment()
    local ready = false
    local requests = 0
    C_Container.GetContainerNumSlots = function(bagID)
        return bagID == 0 and 1 or 0
    end
    C_Container.GetContainerItemInfo = function(bagID, slotID)
        if bagID == 0 and slotID == 1 then
            return {
                itemID = 2001,
                stackCount = 1,
                hyperlink = ready and "item:2001:0:0:0:0:0" or nil,
            }
        end
    end
    C_Item.RequestLoadItemDataByID = function(itemID)
        assert(itemID == 2001, "unexpected backpack item-data request")
        requests = requests + 1
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
                            details = {
                                schemaVersion = 1,
                                backpack = {
                                    updatedAt = 1699999000,
                                    totalSlots = 20,
                                    usedSlots = 1,
                                    items = { { link = "item:1999", count = 1 } },
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    events.BAG_UPDATE_DELAYED()
    local backpack = GetStoredCharacter().details.backpack
    assert(backpack.updatedAt == 1699999000 and backpack.items[1].link == "item:1999",
        "an incomplete backpack scan overwrote the last complete snapshot")
    assert(requests == 1, "missing backpack item data was not requested once")

    ready = true
    events.GET_ITEM_INFO_RECEIVED(nil, nil, 2001, true)
    backpack = GetStoredCharacter().details.backpack
    assert(backpack.updatedAt == 1700000000
        and backpack.items[1].link == "item:2001:0:0:0:0:0",
        "loaded item data did not commit a complete backpack snapshot")
end

local function TestBackpackRefreshEventsAreDebounced()
    local BG = ResetEnvironment()
    local callbacks = {}
    BG.After = function(_, callback)
        callbacks[#callbacks + 1] = callback
    end
    local bagReads = 0
    C_Container.GetContainerNumSlots = function()
        bagReads = bagReads + 1
        return 0
    end

    BG.RefreshCurrentCharacterBackpack()
    BG.RefreshCurrentCharacterBackpack()
    BG.RefreshCurrentCharacterBackpack()
    while #callbacks > 0 do
        table.remove(callbacks, 1)()
    end
    assert(bagReads == NUM_BAG_SLOTS + 1,
        "bursty backpack refreshes should collapse into one fixed bag scan")
end

local function TestTitanProfessionCooldownSnapshotsAndSummary()
    local BG, events = ResetEnvironment()
    IsPlayerSpell = function(spellID)
        return spellID == 47280 or spellID == 62242 or spellID == 56005 or spellID == 56003
    end
    GetSpellCooldown = function(spellID)
        if spellID == 62242 then
            return 500, 72000
        elseif spellID == 56003 then
            return 500, 99999
        end
        return 0, 0
    end

    assert(events.SPELL_UPDATE_COOLDOWN, "profession cooldown refresh event is missing")
    events.SPELL_UPDATE_COOLDOWN()

    local stored = GetStoredCharacter()
    local cooldowns = stored.professionCooldowns
    assert(cooldowns.jewelcraftingBrilliantGlass
        and cooldowns.jewelcraftingBrilliantGlass.endTime == nil,
        "ready Brilliant Glass was not retained as a known cooldown recipe")
    assert(cooldowns.jewelcraftingIcyPrism
        and cooldowns.jewelcraftingIcyPrism.endTime == 1700071500
        and cooldowns.jewelcraftingIcyPrism.duration == 72000,
        "active Icy Prism cooldown did not persist its server end time and duration")
    assert(cooldowns.tailoringGlacialBag and cooldowns.tailoringGlacialBag.endTime == nil,
        "ready Glacial Bag was not retained as a known cooldown recipe")
    assert(cooldowns.tailoringSpellweave == nil and cooldowns.titansteel == nil,
        "Titan recipes without a long cooldown leaked into the candidate snapshots")

    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    local updateCooldownStatus = FindUpvalue(createHoverFrame, "UpdateProfessionCooldownStatusDisplay")
    assert(updateCooldownStatus, "profession cooldown summary renderer is missing")
    local status = {
        check = {
            Hide = function(self) self.shown = false end,
            Show = function(self) self.shown = true end,
        },
        text = {
            SetText = function(self, value) self.value = value end,
            SetFormattedText = function(self, pattern, ...) self.value = string.format(pattern, ...) end,
            SetTextColor = function(self, ...) self.color = { ... } end,
        },
        background = {
            SetColorTexture = function(self, ...) self.color = { ... } end,
        },
        baseColor = { 0.02, 0.07, 0.09, 0.9 },
    }
    local character = BG.GetRaidLockoutStoredCharacters(100)[1]
    updateCooldownStatus(status, character)
    local warningSurface = BG.UI.Token("color", "warningSurface")
    assert(status.text.value == "2/3" and status.background.color[1] == warningSurface[1],
        "mixed cooldowns must render the compact ready/total summary")

    character.professionCooldowns.jewelcraftingIcyPrism.endTime = nil
    updateCooldownStatus(status, character)
    local successSurface = BG.UI.Token("color", "successSurface")
    assert(status.check.shown and status.background.color[1] == successSurface[1],
        "all-ready crafting cooldowns must render the semantic success state")
end

local function TestAlchemyTransmutesCollapseIntoOneSharedCooldown()
    local _, events = ResetEnvironment()
    IsPlayerSpell = function(spellID)
        return spellID == 66658 or spellID == 66660
    end
    GetSpellCooldown = function(spellID)
        if spellID == 66660 then
            return 700, 72000
        end
        return 0, 0
    end

    events.SPELL_UPDATE_COOLDOWN()
    local cooldowns = GetStoredCharacter().professionCooldowns
    local count = 0
    for _ in pairs(cooldowns) do
        count = count + 1
    end
    assert(count == 1 and cooldowns.alchemyTransmute,
        "shared alchemy transmutes must collapse into one logical overview item")
    assert(cooldowns.alchemyTransmute.endTime == 1700071700,
        "shared transmute cooldown did not keep the longest active category cooldown")
end

local function TestCharacterProgressModelOnlyIncludesRaidsAndWeeklies()
    local BG = ResetEnvironment()
    BG.Boss = {
        SWtitan = {},
        TOCtitan = {},
        NAXXtitan = {},
        SSCtitan = {},
        MCtitan = {},
    }
    local sourceCounts = {
        SWtitan = 13,
        TOCtitan = 15,
        NAXXtitan = 17,
        SSCtitan = 10,
        MCtitan = 10,
    }
    for sourceName, count in pairs(sourceCounts) do
        for index = 1, count do
            BG.Boss[sourceName]["boss" .. index] = {
                name2 = sourceName .. " source " .. index,
            }
        end
    end
    EJ_GetInstanceForMap = function(mapID)
        return mapID == 624 and 999 or nil
    end
    EJ_GetEncounterInfoByIndex = function(index, journalInstanceID)
        if journalInstanceID ~= 999 then
            return nil
        end
        return ({ "Archavon", "Emalon" })[index]
    end
    local character = {
        lastRecordedAt = 1699999900,
        professions = {
            { skillLineID = 755, rank = 450, maxRank = 450 },
        },
        instances = {
            [580] = {
                {
                    difficultyName = "25 Player",
                    killedCount = 4,
                    numEncounters = 6,
                    resetAt = 1700604800,
                    updatedAt = 1699999980,
                    bosses = {
                        { name = "Kalecgos", killed = true },
                        { name = "Brutallus", killed = false },
                    },
                },
            },
            [649] = {
                {
                    difficultyName = "10 Player",
                    killedCount = 5,
                    numEncounters = 5,
                    resetAt = 1700604800,
                    bosses = {},
                },
                {
                    difficultyName = "25 Player",
                    killedCount = 0,
                    numEncounters = 5,
                    resetAt = 1700604800,
                    bosses = {},
                },
            },
        },
        questCompletions = {
            raidWeekly = { questID = 93975, resetAt = 1700604800, updatedAt = 1699999990 },
            cookingDaily = { questID = 13114, resetAt = 1700086400, updatedAt = 1699999995 },
        },
        professionCooldowns = {
            jewelcraftingBrilliantGlass = {
                spellID = 47280,
                observedAt = 1699999997,
            },
            jewelcraftingIcyPrism = {
                spellID = 62242,
                endTime = 1700036000,
                duration = 72000,
                observedAt = 1699999997,
            },
        },
        professionCooldownScans = { [755] = 1699999997 },
        professionCooldownsUpdatedAt = 1699999997,
    }

    local model = BG.GetRaidLockoutProgressModel(character, 1700000000)
    assert(#model.raids == 11 and model.raidCount == 2,
        "progress model did not preserve all Titan raids in their configured order")
    assert(model.raids[1].id == 580 and model.raids[2].id == 568
        and model.raids[11].id == 624,
        "progress model changed the authoritative Titan raid order")
    assert(#model.raids[1].bosses == 6
        and model.raids[1].bosses[1].name == "SWtitan source 8"
        and model.raids[1].bosses[6].name == "SWtitan source 13",
        "progress model did not expose the configured Titan boss range")
    assert(#model.raids[11].bosses == 2
        and model.raids[11].bosses[1].name == "Archavon"
        and model.raids[11].bosses[2].name == "Emalon",
        "progress model did not fall back to the client encounter journal")
    for _, raid in ipairs(model.raids) do
        assert(#raid.bosses > 0,
            "every Titan raid must expose a boss roster for the expandable progress row")
    end
    assert(model.raids[1].lockouts[1].bosses[1].name == "Kalecgos"
        and model.raids[1].lockouts[1].bosses[2].name == "Brutallus",
        "progress model did not preserve encounter order")
    assert(#model.weeklies == 2 and model.weeklyCompleted == 1 and model.weeklyTotal == 2,
        "progress model did not summarize weekly quest cooldowns")
    assert(model.dailies == nil and model.professionTracks == nil and model.dailyResetAt == nil,
        "progress model leaked profession or daily cooldown data into the raid page")
    assert(model.resetAt == 1700604800,
        "progress model did not expose the shared weekly reset")
    assert(model.updatedAt == 1699999990,
        "progress model counted unrelated daily or profession cooldown snapshots")
end

local function TestOpenTradeSkillCooldownIsCapturedByRecipeIndex()
    local _, events = ResetEnvironment()
    GetNumTradeSkills = function()
        return 2
    end
    GetTradeSkillInfo = function(index)
        if index == 1 then
            return "Jewelcrafting", "header"
        end
        return "Icy Prism", "optimal"
    end
    GetTradeSkillRecipeLink = function(index)
        return index == 2 and "|cffffd000|Henchant:62242|h[Icy Prism]|h|r" or nil
    end
    GetTradeSkillCooldown = function(index)
        return index == 2 and 36000 or nil
    end

    assert(events.TRADE_SKILL_UPDATE, "trade-skill cooldown capture event is missing")
    events.TRADE_SKILL_UPDATE()
    local snapshot = GetStoredCharacter().professionCooldowns.jewelcraftingIcyPrism
    assert(snapshot and snapshot.spellID == 62242 and snapshot.endTime == 1700036000,
        "open trade-skill recipe cooldown was not captured by recipe index")
end

local function TestTradeSkillScanPreservesOtherProfessionCooldowns()
    local _, events = ResetEnvironment()
    IsPlayerSpell = function(spellID)
        return spellID == 62242 or spellID == 56005
    end
    GetSpellCooldown = function()
        return 0, 0
    end
    events.SPELL_UPDATE_COOLDOWN()

    local stored = GetStoredCharacter()
    assert(stored.professionCooldowns.jewelcraftingIcyPrism
        and stored.professionCooldowns.tailoringGlacialBag,
        "initial profession cooldown snapshots are missing")

    IsPlayerSpell = nil
    GetTradeSkillLine = function()
        return "珠宝加工"
    end
    GetNumTradeSkills = function()
        return 1
    end
    GetTradeSkillInfo = function()
        return "Icy Prism", "optimal"
    end
    GetTradeSkillRecipeLink = function()
        return "|cffffd000|Henchant:62242|h[Icy Prism]|h|r"
    end
    GetTradeSkillCooldown = function()
        return 18000
    end
    events.TRADE_SKILL_UPDATE()

    stored = GetStoredCharacter()
    assert(stored.professionCooldowns.jewelcraftingIcyPrism.endTime == 1700018000,
        "open profession scan did not refresh its own cooldown")
    assert(stored.professionCooldowns.tailoringGlacialBag,
        "opening Jewelcrafting incorrectly erased Tailoring cooldowns")
end

local function TestRelevantUnscannedProfessionRendersUnknown()
    local BG, events = ResetEnvironment()
    events.PLAYER_MONEY()
    local stored = GetStoredCharacter()
    stored.professions = { { skillLineID = 755, rank = 450, maxRank = 450 } }
    stored.professionCooldowns = {}
    stored.professionCooldownScans = {}

    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    local updateCooldownStatus = FindUpvalue(createHoverFrame, "UpdateProfessionCooldownStatusDisplay")
    local showCooldownTooltip = FindUpvalue(createHoverFrame, "ShowProfessionCooldownTooltip")
    assert(updateCooldownStatus and showCooldownTooltip,
        "profession cooldown unknown-state UI helpers are missing")
    local status = {
        check = {
            Hide = function(self) self.shown = false end,
            Show = function(self) self.shown = true end,
        },
        text = {
            SetText = function(self, value) self.value = value end,
            SetFormattedText = function(self, pattern, ...) self.value = string.format(pattern, ...) end,
            SetTextColor = function(self, ...) self.color = { ... } end,
        },
        background = {
            SetColorTexture = function(self, ...) self.color = { ... } end,
        },
        baseColor = { 0.02, 0.07, 0.09, 0.9 },
    }

    local character = BG.GetRaidLockoutStoredCharacters(100)[1]
    updateCooldownStatus(status, character)
    local muted = BG.UI.Token("color", "textMuted")
    assert(status.text.value == "?" and status.text.color[1] == muted[1],
        "a relevant but unscanned profession must render the gray unknown state")

    local tooltipLines = {}
    GameTooltip = {
        SetOwner = function() end,
        ClearLines = function()
            tooltipLines = {}
        end,
        AddLine = function(_, text)
            tooltipLines[#tooltipLines + 1] = text
        end,
        AddDoubleLine = function(_, left, right)
            tooltipLines[#tooltipLines + 1] = left .. " " .. right
        end,
        Show = function() end,
    }
    BG.ButtonIsInRight = function()
        return false
    end
    showCooldownTooltip({ character = character })
    local tooltipText = table.concat(tooltipLines, "\n")
    assert(tooltipText:find("尚未扫描以下专业：", 1, true)
        and tooltipText:find("珠宝加工", 1, true)
        and tooltipText:find("如何记录", 1, true)
        and tooltipText:find("打开一次上述专业的制造窗口", 1, true)
        and tooltipText:find("以后无需重复打开", 1, true),
        "unknown-state tooltip must identify the profession and explain the one-time action")

    stored.professionCooldownScans[755] = 1700000000
    character = BG.GetRaidLockoutStoredCharacters(100)[1]
    updateCooldownStatus(status, character)
    assert(status.text.value == "" and not status.check.shown,
        "a scanned profession with no learned cooldown recipes must render blank")
end

local function TestProfessionTracksExposeDynamicTitanCooldowns()
    local BG = ResetEnvironment()
    assert(BG.GetRaidLockoutProfessionTracks,
        "profession-resource detail model is missing")

    local tracks = BG.GetRaidLockoutProfessionTracks({
        professions = {
            { skillLineID = 773, rank = 450, maxRank = 450, iconFileID = 237171 },
            { skillLineID = 197, rank = 440, maxRank = 450, iconFileID = 136249 },
        },
        professionCooldownScans = {
            [773] = 1699999000,
            [197] = 1699999000,
        },
        professionCooldowns = {
            inscriptionNorthrendResearch = {
                spellID = 61177,
                endTime = 1700003600,
                observedAt = 1700000000,
                duration = 86400,
            },
            inscriptionMinorResearch = {
                spellID = 61288,
                observedAt = 1700000000,
            },
            tailoringGlacialBag = {
                spellID = 56005,
                observedAt = 1700000000,
            },
        },
    }, 1700000000)

    assert(#tracks == 2
        and tracks[1].skillLineID == 773
        and tracks[1].iconFileID == 237171
        and tracks[1].rank == 450
        and tracks[1].maxRank == 450,
        "profession track did not retain the client's skill-line icon and rank")
    assert(#tracks[1].entries == 2
        and tracks[1].entries[1].spellID == 61177
        and tracks[1].entries[1].state == "cooling"
        and tracks[1].entries[1].remaining == 3600
        and tracks[1].entries[1].duration == 86400
        and tracks[1].entries[2].state == "ready",
        "Inscription's two independent Titan cooldown items were not exposed")
    assert(#tracks[2].entries == 1
        and tracks[2].entries[1].spellID == 56005
        and tracks[2].entries[1].state == "ready",
        "Tailoring's tracked Titan cooldown item was not exposed")

    tracks = BG.GetRaidLockoutProfessionTracks({
        professions = {
            { skillLineID = 755, rank = 450, maxRank = 450, iconFileID = 134071 },
            { skillLineID = 202, rank = 450, maxRank = 450, iconFileID = 136243 },
        },
        professionCooldowns = {},
        professionCooldownScans = {},
    }, 1700000000)
    assert(#tracks[1].entries == 2
        and tracks[1].entries[1].state == "unknown"
        and tracks[1].entries[2].state == "unknown",
        "an unscanned Jewelcrafting track must expose both candidate recipes as unknown")
    assert(not tracks[2].hasTrackedCooldowns and #tracks[2].entries == 0,
        "a profession without Titan long cooldowns must remain an explicit empty track")
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
    local fragmentIncludedBank
    C_Item = {
        GetItemCount = function(itemID, includeBank)
            if itemID == 22726 then
                fragmentIncludedBank = includeBank
                return 17
            end
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
    assert(fragmentIncludedBank == true,
        "legendary fragments must include the current character's bank count")
    assert(#stored.legendaryFragmentItems == 1
        and stored.legendaryFragmentItems[1].itemID == 22726
        and stored.legendaryFragmentItems[1].count == 17
        and stored.legendaryFragmentItems[1].targetCount == 40,
        "Atiesh fragments were not captured as extensible legendary-fragment progress")

    local character = BG.GetRaidLockoutStoredCharacters(100)[1]
    assert(character.legendaryFragmentItems == stored.legendaryFragmentItems,
        "legendary fragment snapshots did not reach the character-overview model")
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
    quality, valueText = getDisplay({ quality = 5, count = 17, targetCount = 40 }, "count", 5, "×")
    assert(quality == 5 and valueText == "×17",
        "legendary-fragment counts must reuse the compact orange item-tile treatment")
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

    calls = {}
    GameTooltip.AddLine = function(_, line)
        calls.target = line
    end
    showTooltip(owner, { itemID = 22726, targetCount = 40 })
    assert(calls.target == "目标数量：40",
        "legendary-fragment tooltips must expose the configured completion target")
end

local function TestQuestColumnsFollowVaultInTwoGroups()
    local BG = ResetEnvironment()
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    local getColumns = FindUpvalue(createHoverFrame, "GetVisibleLockoutColumns")
    local getGroups = FindUpvalue(createHoverFrame, "GetVisibleQuestGroups")
    local updateQuestStatus = FindUpvalue(createHoverFrame, "UpdateQuestStatusDisplay")
    assert(getColumns and getGroups and updateQuestStatus, "quest column/group builders are missing")

    local columns = getColumns()
    local expected = {
        { id = "raidWeekly", groupID = "weekly" },
        { id = "zulGurubWeekly", groupID = "weekly" },
        { id = "jewelcraftingDaily", groupID = "professionDaily" },
        { id = "cookingDaily", groupID = "professionDaily" },
        { id = "fishingDaily", groupID = "professionDaily" },
        { id = "professionCooldown", groupID = "professionCooldown", isProfessionCooldown = true },
    }
    assert(columns[#columns - #expected].id == 624,
        "quest groups must appear immediately after Vault of Archavon")
    for index, expectation in ipairs(expected) do
        local column = columns[#columns - #expected + index]
        assert(column.id == expectation.id and column.groupID == expectation.groupID,
            "grouped status columns are missing or out of group order")
        if expectation.isProfessionCooldown then
            assert(column.isProfessionCooldown and not column.isQuest,
                "profession crafting must use its dedicated summary renderer")
        else
            assert(column.isQuest, "quest column lost its quest semantics")
        end
    end

    local groups = getGroups(columns)
    assert(#groups == 3, "expected weekly, profession-daily, and profession-crafting header groups")
    assert(groups[1].id == "weekly" and groups[1].name == "周常" and #groups[1].columns == 2,
        "weekly two-level header group is incorrect")
    assert(groups[2].id == "professionDaily" and groups[2].name == "专业日常"
        and #groups[2].columns == 3,
        "profession-daily two-level header group is incorrect")
    assert(groups[3].id == "professionCooldown" and groups[3].name == "专业制造"
        and #groups[3].columns == 1 and groups[3].columns[1].id == "professionCooldown",
        "profession-crafting two-level header group is incorrect")

    local choices = BG.GetRaidLockoutDisplayChoices()
    assert(#choices == 14, "settings should expose eleven raids and exactly three grouped status choices")
    local weeklyChoice = choices[#choices - 2]
    local professionDailyChoice = choices[#choices - 1]
    local professionCooldownChoice = choices[#choices]
    assert(weeklyChoice.id == "weekly"
        and weeklyChoice.name == "周常"
        and weeklyChoice.optionKey == "raidLockoutShowGroup_weekly",
        "weekly quests must be exposed as one group-level display choice")
    assert(professionDailyChoice.id == "professionDaily"
        and professionDailyChoice.name == "专业日常"
        and professionDailyChoice.optionKey == "raidLockoutShowGroup_professionDaily",
        "profession dailies must be exposed as one group-level display choice")
    assert(professionCooldownChoice.id == "professionCooldown"
        and professionCooldownChoice.name == "专业制造"
        and professionCooldownChoice.optionKey == "raidLockoutShowGroup_professionCooldown",
        "profession crafting must be exposed as one group-level display choice")

    local calculateWidths = FindUpvalue(createHoverFrame, "CalculateRaidColumnWidths")
    local widths, totalWidth = calculateWidths(columns, 900)
    assert(math.abs(totalWidth - 900) < 0.001 and widths.raidWeekly >= 60 and widths.fishingDaily >= 44,
        "grouped quest columns must still fill the available compact-table width")

    BiaoGe = {
        options = {
            raidLockoutShowGroup_weekly = 0,
        },
    }
    columns = getColumns()
    for _, column in ipairs(columns) do
        assert(column.groupID ~= "weekly",
            "disabling weekly quests must hide every weekly child column")
    end
    groups = getGroups(columns)
    assert(#groups == 2 and groups[1].id == "professionDaily" and #groups[1].columns == 3
        and groups[2].id == "professionCooldown",
        "disabling weekly quests must leave both profession groups intact")

    BiaoGe.options.raidLockoutShowGroup_professionDaily = 0
    columns = getColumns()
    assert(#getGroups(columns) == 1 and getGroups(columns)[1].id == "professionCooldown",
        "disabling both quest groups must leave profession crafting intact")
    BiaoGe.options.raidLockoutShowGroup_professionCooldown = 0
    columns = getColumns()
    for _, column in ipairs(columns) do
        assert(not column.groupID, "disabling all grouped statuses must hide every child column")
    end
    assert(#getGroups(columns) == 0, "disabled status groups must hide every parent header")

    local status = {
        check = {
            Hide = function(self) self.shown = false end,
            Show = function(self) self.shown = true end,
        },
        text = {
            SetText = function(self, value) self.value = value end,
        },
        background = {
            SetColorTexture = function(self, ...) self.color = { ... } end,
        },
        baseColor = { 0.02, 0.07, 0.09, 0.9 },
    }
    updateQuestStatus(status, { ready = true, questCompletions = {} }, { id = "fishingDaily" })
    assert(not status.check.shown and status.text.value == "",
        "unfinished profession dailies must remain blank without a red cross")
    updateQuestStatus(status, {
        ready = true,
        questCompletions = { fishingDaily = { questID = 13836 } },
    }, { id = "fishingDaily" })
    local successSurface = BG.UI.Token("color", "successSurface")
    assert(status.check.shown and status.background.color[1] == successSurface[1],
        "completed profession dailies must render a green check")
end

local function TestQuestTurnInsStoreSeparateMinimalSnapshots()
    local _, events = ResetEnvironment()
    assert(events.QUEST_TURNED_IN, "QUEST_TURNED_IN handler is missing")

    events.QUEST_TURNED_IN(nil, nil, 93975)
    events.QUEST_TURNED_IN(nil, nil, 98183)
    events.QUEST_TURNED_IN(nil, nil, 12959)
    events.QUEST_TURNED_IN(nil, nil, 13114)
    events.QUEST_TURNED_IN(nil, nil, 13836)
    local completions = GetStoredCharacter().questCompletions
    assert(completions.raidWeekly.questID == 93975
        and completions.zulGurubWeekly.questID == 98183,
        "weekly quest categories overwrote each other")
    assert(completions.jewelcraftingDaily.questID == 12959
        and completions.cookingDaily.questID == 13114
        and completions.fishingDaily.questID == 13836,
        "profession-daily categories overwrote each other")
    assert(completions.raidWeekly.resetAt == 1700604800
        and completions.jewelcraftingDaily.resetAt == 1700086400,
        "quest snapshots did not use their official weekly/daily reset boundaries")
    assert(completions.raidWeekly.updatedAt == 1700000000
        and completions.raidWeekly.player == nil
        and completions.raidWeekly.colorplayer == nil,
        "quest snapshots must remain minimal and omit redundant identity fields")

    events.QUEST_TURNED_IN(nil, nil, 123456)
    assert(GetStoredCharacter().questCompletions.raidWeekly.questID == 93975,
        "an unrelated quest overwrote a quest completion slot")
end

local function TestQuestLoginBackfillAndIndependentExpiry()
    local BG, events = ResetEnvironment()
    C_QuestLog.IsQuestFlaggedCompleted = function(questID)
        return questID == 96312 or questID == 98183 or questID == 12962 or questID == 13830
    end

    local captureQuestProgress = FindUpvalue(events.QUEST_TURNED_IN, "CaptureCurrentQuestProgress")
    assert(captureQuestProgress, "quest backfill function is missing")
    assert(captureQuestProgress(), "quest backfill did not run")
    local completions = GetStoredCharacter().questCompletions
    assert(completions.raidWeekly.questID == 96312
        and completions.zulGurubWeekly.questID == 98183,
        "login backfill did not scan both weekly quest pools")
    assert(completions.jewelcraftingDaily.questID == 12962
        and completions.fishingDaily.questID == 13830
        and completions.cookingDaily == nil,
        "login backfill did not independently scan profession-daily pools")

    GetServerTime = function()
        return 1700086401
    end
    local createHoverFrame = FindUpvalue(BG.ShowRaidLockoutHover, "CreateHoverFrame")
    local getVisibleRows = FindUpvalue(createHoverFrame, "GetCharacterRows")
    assert(getVisibleRows, "character-row builder is missing")
    getVisibleRows()
    completions = GetStoredCharacter().questCompletions
    assert(completions.jewelcraftingDaily == nil and completions.fishingDaily == nil,
        "expired daily quest snapshots survived their reset boundary")
    assert(completions.raidWeekly and completions.zulGurubWeekly,
        "daily expiry incorrectly removed weekly quest snapshots")

    GetServerTime = function()
        return 1700604801
    end
    getVisibleRows()
    completions = GetStoredCharacter().questCompletions
    assert(completions.raidWeekly == nil and completions.zulGurubWeekly == nil,
        "expired weekly quest snapshots survived their reset boundary")
end

local function TestLegacyWeeklyQuestMigratesToRaidWeekly()
    local BG = ResetEnvironment()
    BiaoGe = {
        BGForgeRaidLockouts = {
            schemaVersion = 1,
            realms = {
                [100] = {
                    characters = {
                        Tester = {
                            instances = {},
                            weeklyQuest = {
                                status = "completed",
                                questID = 93975,
                                resetAt = 1700604800,
                                updatedAt = 1699999999,
                            },
                        },
                    },
                },
            },
        },
    }

    BG.GetRaidLockoutStoredCharacters(100)
    local stored = GetStoredCharacter()
    assert(stored.weeklyQuest == nil, "legacy weeklyQuest field was not removed after migration")
    assert(stored.questCompletions.raidWeekly.questID == 93975,
        "legacy weeklyQuest completion was not migrated to raidWeekly")
end

local tests = {
    fallback = TestSkillLineFallbackCapturesPrimaryProfessions,
    preserve = TestUnavailableProfessionDataDoesNotEraseSnapshot,
    primary = TestPrimaryProfessionAPICapturesExpectedFields,
    incomplete_primary = TestIncompletePrimaryAPIUsesSkillLineFallback,
    raid_width = TestRaidColumnsFillAvailableWidth,
    wide_font_headers = TestWideFontHeadersExpandColumns,
    wide_table_viewport = TestWideTablesUseScreenBoundedViewport,
    hover_upvalues = TestHoverFrameStaysWithinTitanUpvalueLimit,
    ember_weekly = TestPerCharacterEmberWeeklyProgressFormatting,
    hover_design_system = TestHoverFrameUsesDesignSystemPalette,
    item_tiles = TestEquipmentUsesIconTilesWithTopLeftValues,
    profession_tiles = TestProfessionsUseMatchingIconTilesWithFixedColor,
    collapsed_headers = TestCollapsedSkillHeadersExpandOnceWithoutEventLoop,
    debounce = TestResourceRefreshEventsAreDebounced,
    equipment_snapshot = TestEquipmentSnapshotStoresOnlyDisplayFields,
    equipment_atomic = TestEquipmentSnapshotCommitsAtomicallyAfterItemDataLoads,
    equipment_debounce = TestEquipmentRefreshEventsAreDebounced,
    backpack_snapshot = TestBackpackSnapshotStoresOnlyMinimalDisplayFields,
    backpack_badges = TestBackpackBadgesFollowExplicitItemType,
    backpack_groups = TestBackpackItemsAreGroupedByStableItemClass,
    backpack_atomic = TestBackpackSnapshotCommitsAtomicallyAfterItemDataLoads,
    backpack_debounce = TestBackpackRefreshEventsAreDebounced,
    profession_cooldowns = TestTitanProfessionCooldownSnapshotsAndSummary,
    progress_model = TestCharacterProgressModelOnlyIncludesRaidsAndWeeklies,
    transmute_group = TestAlchemyTransmutesCollapseIntoOneSharedCooldown,
    trade_skill_cooldown = TestOpenTradeSkillCooldownIsCapturedByRecipeIndex,
    trade_skill_isolation = TestTradeSkillScanPreservesOtherProfessionCooldowns,
    profession_cooldown_unknown = TestRelevantUnscannedProfessionRendersUnknown,
    profession_tracks = TestProfessionTracksExposeDynamicTitanCooldowns,
    legendary_classification = TestUpgradeItemsAreExcludedFromFinishedLegendaries,
    item_quality = TestItemTileDisplayUsesRequestedQualitySemantics,
    character_visibility = TestCharacterVisibilityCanBeRestored,
    native_tooltip = TestItemTilesUseNativeGameTooltip,
    quest_columns = TestQuestColumnsFollowVaultInTwoGroups,
    quest_turnin = TestQuestTurnInsStoreSeparateMinimalSnapshots,
    quest_backfill = TestQuestLoginBackfillAndIndependentExpiry,
    quest_migration = TestLegacyWeeklyQuestMigratesToRaidWeekly,
}

if arg[1] then
    assert(tests[arg[1]], "unknown test: " .. tostring(arg[1]))()
else
    for _, testName in ipairs({
        "fallback", "preserve", "primary", "incomplete_primary", "raid_width",
        "wide_font_headers", "item_tiles",
        "wide_table_viewport",
        "hover_upvalues",
        "ember_weekly",
        "hover_design_system",
        "profession_tiles",
        "collapsed_headers",
        "debounce",
        "equipment_snapshot",
        "equipment_atomic",
        "equipment_debounce",
        "backpack_snapshot",
        "backpack_badges",
        "backpack_groups",
        "backpack_atomic",
        "backpack_debounce",
        "profession_cooldowns",
        "progress_model",
        "transmute_group",
        "trade_skill_cooldown",
        "trade_skill_isolation",
        "profession_cooldown_unknown",
        "profession_tracks",
        "legendary_classification",
        "item_quality",
        "character_visibility",
        "native_tooltip",
        "quest_columns",
        "quest_turnin",
        "quest_backfill",
        "quest_migration",
    }) do
        tests[testName]()
    end
end
print("raid lockout overview regression tests passed")

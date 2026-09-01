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

    local calculateResourceWidths = FindUpvalue(createHoverFrame, "CalculateResourceColumnWidths")
    assert(calculateResourceWidths, "dynamic resource-column width calculation is missing")
    local ui = {
        professionWidth = 100,
        legendaryWidth = 150,
        upgradeWidth = 130,
        trinketWidth = 100,
        goldWidth = 88,
        emberWidth = 88,
        shardWidth = 88,
    }
    local resourceWidths, resourceTotal = calculateResourceWidths(ui, 800)
    assert(math.abs(resourceTotal - 800) < 0.001,
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
        and cooldowns.jewelcraftingIcyPrism.endTime == 1700071500,
        "active Icy Prism cooldown did not persist its server end time")
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
    assert(status.text.value == "2/3" and status.background.color[1] == 0.36,
        "mixed cooldowns must render the compact ready/total summary")

    character.professionCooldowns.jewelcraftingIcyPrism.endTime = nil
    updateCooldownStatus(status, character)
    assert(status.check.shown and status.background.color[1] == 0.1,
        "all-ready crafting cooldowns must render the existing green-check state")
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
    assert(status.text.value == "?" and status.text.color[1] == 0.48,
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
    assert(status.check.shown and status.background.color[1] == 0.1,
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
    item_tiles = TestEquipmentUsesIconTilesWithTopLeftValues,
    profession_tiles = TestProfessionsUseMatchingIconTilesWithFixedColor,
    collapsed_headers = TestCollapsedSkillHeadersExpandOnceWithoutEventLoop,
    debounce = TestResourceRefreshEventsAreDebounced,
    profession_cooldowns = TestTitanProfessionCooldownSnapshotsAndSummary,
    transmute_group = TestAlchemyTransmutesCollapseIntoOneSharedCooldown,
    trade_skill_cooldown = TestOpenTradeSkillCooldownIsCapturedByRecipeIndex,
    trade_skill_isolation = TestTradeSkillScanPreservesOtherProfessionCooldowns,
    profession_cooldown_unknown = TestRelevantUnscannedProfessionRendersUnknown,
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
        "profession_tiles",
        "collapsed_headers",
        "debounce",
        "profession_cooldowns",
        "transmute_group",
        "trade_skill_cooldown",
        "trade_skill_isolation",
        "profession_cooldown_unknown",
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

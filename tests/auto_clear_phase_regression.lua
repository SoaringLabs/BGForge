local sourcePath = "Core/Module/ClearBiaoGe.lua"

format = string.format
GetRealmID = function() return 100 end
IsAddOnLoaded = function() return false end
GetLootMethod = function() return nil end

local messages = {}
local calls = { click = 0, clear = 0, sound = 0 }
BG = {
    IsBlackListPlayer = false,
    playerName = "Tester",
    FBIDtable = {
        [409] = "MCtitan",
        [548] = "SSCtitan",
        [550] = "SSCtitan",
        [533] = "NAXXtitan",
        [615] = "NAXXtitan",
        [616] = "NAXXtitan",
        [309] = "TOCtitan",
        [649] = "TOCtitan",
        [568] = "SWtitan",
        [580] = "SWtitan",
        [603] = "ULDtitan",
    },
    bossPositionStartEnd = {
        [409] = { 1, 10 },
        [548] = { 1, 6 },
        [550] = { 7, 10 },
        [533] = { 1, 15 },
        [615] = { 16, 16 },
        [616] = { 17, 17 },
        [309] = { 1, 10 },
        [649] = { 11, 15 },
        [568] = { 1, 7 },
        [580] = { 8, 13 },
        [603] = { 1, 14 },
    },
    ClickFBbutton = function(FB)
        calls.click = calls.click + 1
        calls.clickedFB = FB
    end,
    ClearBiaoGe = function(kind, FB)
        calls.clear = calls.clear + 1
        calls.clearKind = kind
        calls.clearedFB = FB
        return 25
    end,
    SendSystemMessage = function(message)
        messages[#messages + 1] = message
    end,
    GetFBinfo = function(FB)
        return FB
    end,
    PlaySound = function(sound)
        calls.sound = calls.sound + 1
        calls.soundName = sound
    end,
}

local L = setmetatable({}, { __index = function(_, key) return key end })
assert(loadfile(sourcePath))("BGForge", {
    L = L,
    SetClassCFF = function(value) return value end,
    AddTexture = function() return "" end,
    Maxb = {
        MCtitan = 12,
        SSCtitan = 12,
        NAXXtitan = 19,
        TOCtitan = 17,
        SWtitan = 15,
        ULDtitan = 16,
    },
    HopeMaxn = {},
    HopeMaxi = 0,
})

local function FindUpvalue(func, targetName)
    for index = 1, 100 do
        local name, value = debug.getupvalue(func, index)
        if not name then break end
        if name == targetName then return value end
    end
    error("Missing upvalue: " .. targetName)
end

local CheckAutoClearForInstance = FindUpvalue(BG.ClearBiaoGeUI, "CheckAutoClearForInstance")
local GetAutoClearDecision = FindUpvalue(CheckAutoClearForInstance, "GetAutoClearDecision")
local ClearCurrentStage = FindUpvalue(CheckAutoClearForInstance, "ClearCurrentStage")
local GetStageCycleEnd = FindUpvalue(CheckAutoClearForInstance, "GetStageCycleEnd")
local GetCheckedStageCycleEnd = FindUpvalue(CheckAutoClearForInstance, "GetCheckedStageCycleEnd")
local MarkStageChecked = FindUpvalue(CheckAutoClearForInstance, "MarkStageChecked")

BiaoGe = {}
GetServerTime = function() return 1000 end
C_DateAndTime = { GetSecondsUntilWeeklyReset = function() return 99000 end }
assert(GetStageCycleEnd() == 100000, "weekly reset boundary must use server time")
MarkStageChecked("TOCtitan", 100000)
assert(GetCheckedStageCycleEnd("TOCtitan") == 100000, "stage check must persist for this character")
assert(GetCheckedStageCycleEnd("SWtitan") == nil, "checking P4 must not mark P5")
C_DateAndTime = nil
BG.GetNextWeekTime = function() return 199000, 200000 end
assert(GetStageCycleEnd() == 200000, "stage cycle must use the existing reset fallback")

local function SavedInfo(rows)
    return function(index)
        local row = rows[index]
        return nil, nil, nil, nil, row.locked, nil, nil, nil, nil, nil, nil, nil, nil, row.instanceID
    end
end

local function Decide(currentInstanceID, rows, hasStageData, cycleEnd, checkedCycleEnd)
    local function HasLedgerItem(FB, mode, instanceID)
        assert(mode == "onlyboss", "automatic clear must inspect the whole stage's boss rows")
        assert(FB == BG.FBIDtable[currentInstanceID], "automatic clear inspected the wrong shared ledger")
        assert(instanceID == nil, "stage check must not be limited to the entered instance")
        return hasStageData == true
    end
    return GetAutoClearDecision(currentInstanceID, #rows, SavedInfo(rows), HasLedgerItem, cycleEnd, checkedCycleEnd)
end

local function AssertDecision(expected, reason, currentInstanceID, rows, hasStageData, message, cycleEnd, checkedCycleEnd)
    local decision = Decide(currentInstanceID, rows, hasStageData, cycleEnd, checkedCycleEnd)
    assert(decision.shouldClear == expected, message)
    assert(decision.reason == reason, message .. ": unexpected reason " .. tostring(decision.reason))
    if BG.FBIDtable[currentInstanceID] then
        assert(decision.FB == BG.FBIDtable[currentInstanceID], message .. ": wrong shared ledger")
    end
    return decision
end

AssertDecision(true, "stage-has-old-data", 568, {}, true,
    "a new ZA lockout with old SW rows must clear the whole P5 table")
AssertDecision(true, "stage-has-old-data", 580, {}, true,
    "a new SW lockout with old ZA rows must clear the whole P5 table")
AssertDecision(true, "stage-has-old-data", 548, {}, true,
    "a new SSC lockout with old TK rows must clear the whole P2 table")
AssertDecision(true, "stage-has-old-data", 550, {}, true,
    "a new TK lockout with old SSC rows must clear the whole P2 table")
AssertDecision(true, "stage-has-old-data", 615, {}, true,
    "a new OS lockout with old Naxx rows must clear the whole P3 table")
AssertDecision(true, "stage-has-old-data", 616, {}, true,
    "a new EOE lockout with old Naxx rows must clear the whole P3 table")
AssertDecision(true, "stage-has-old-data", 309, {}, true,
    "a new ZG lockout with old TOC rows must clear the whole P4 table")
AssertDecision(true, "stage-has-old-data", 649, {}, true,
    "a new TOC lockout with old ZG rows must clear the whole P4 table")
AssertDecision(false, "stage-already-checked", 649, {}, true,
    "switching to the other instance in the same reset must preserve new P4 rows", 100000, 100001)
AssertDecision(true, "stage-has-old-data", 649, {}, true,
    "the next reset must permit clearing the P4 table again", 704800, 100000)
AssertDecision(false, "stage-locked", 580, { { locked = true, instanceID = 568 } }, true,
    "a ZA lockout must preserve the SW ledger even when SW rows look stale")
AssertDecision(false, "stage-locked", 568, { { locked = true, instanceID = 580 } }, true,
    "a SW lockout must preserve the ZA ledger even when ZA rows look stale")
AssertDecision(false, "stage-locked", 615, { { locked = true, instanceID = 533 } }, true,
    "a Naxx lockout must preserve an OS entry")
AssertDecision(false, "stage-locked", 616, { { locked = true, instanceID = 615 } }, true,
    "an OS lockout must preserve an EOE entry")
AssertDecision(false, "stage-locked", 533, { { locked = true, instanceID = 533 } }, true,
    "the current instance lockout must preserve its ledger")
AssertDecision(false, "stage-locked", 550, { { locked = true, instanceID = 548 } }, true,
    "an SSC lockout must preserve the TK ledger")
AssertDecision(false, "stage-locked", 649, { { locked = true, instanceID = 309 } }, true,
    "a ZG lockout must preserve the TOC ledger")
AssertDecision(true, "stage-has-old-data", 568, { { locked = true, instanceID = 603 } }, true,
    "an unrelated phase lockout must not block stale ZA rows from clearing")
AssertDecision(true, "stage-has-old-data", 568, { { locked = false, instanceID = 580 } }, true,
    "unlocked saved rows must be ignored")
AssertDecision(false, "stage-empty", 568, {}, false,
    "an empty stage must not trigger destructive side effects")
AssertDecision(false, "unknown-instance", 999999, {}, true,
    "unknown instances must not clear")

BG.FBIDtable[777777] = "SWtitan"
AssertDecision(false, "unknown-boss-range", 777777, {}, true,
    "instances without a boss range must not clear")
BG.FBIDtable[777777] = nil

local decision = Decide(568, {}, true)
if decision.shouldClear then ClearCurrentStage(decision) end
assert(calls.click == 1 and calls.clickedFB == "SWtitan", "clear path must select the shared ledger once")
assert(calls.clear == 1 and calls.clearKind == "biaoge" and calls.clearedFB == "SWtitan",
    "clear path must clear the full shared ledger once")
assert(#messages == 2, "clear path must emit one success message and one reason message")
assert(messages[2]:find("BOSS编号（1%-13）", 1, false), "clear reason must include the whole stage boss range")
assert(calls.sound == 1 and calls.soundName == "qingkong", "clear path must play the clear sound once")

calls = { click = 0, clear = 0, sound = 0 }
messages = {}
decision = Decide(580, { { locked = true, instanceID = 568 } }, true)
if decision.shouldClear then ClearCurrentStage(decision) end
assert(calls.click == 0 and calls.clear == 0 and calls.sound == 0 and #messages == 0,
    "preserve path must have no clear side effects")

calls = { click = 0, clear = 0, sound = 0 }
messages = {}
decision = Decide(580, {}, false)
if decision.shouldClear then ClearCurrentStage(decision) end
assert(calls.click == 0 and calls.clear == 0 and calls.sound == 0 and #messages == 0,
    "empty current range must not switch the visible ledger or clear metadata")

-- Exercise the same path used by the raid-info event, including persisted cycle marking.
BiaoGe = {}
calls = { click = 0, clear = 0, sound = 0 }
messages = {}
local now = 1000
local nextReset = 100000
GetServerTime = function() return now end
C_DateAndTime = { GetSecondsUntilWeeklyReset = function() return nextReset - now end }
GetNumSavedInstances = function() return 0 end
BG.BiaoGeHavedItem = function(FB, mode)
    assert(FB == "TOCtitan" and mode == "onlyboss", "P4 must inspect the whole stage")
    return true -- Only the sibling instance has old boss rows on the first entry.
end
decision = CheckAutoClearForInstance(309)
assert(decision.shouldClear and calls.clear == 1 and calls.clearedFB == "TOCtitan",
    "entering ZG must clear old TOC data from the full P4 table")
now = now + 10
decision = CheckAutoClearForInstance(649)
assert(not decision.shouldClear and decision.reason == "stage-already-checked" and calls.clear == 1,
    "entering TOC in the same reset must preserve new P4 data")
now = 100001
nextReset = 704800
decision = CheckAutoClearForInstance(649)
assert(decision.shouldClear and calls.clear == 2,
    "the next weekly reset must allow the P4 table to clear again")

BiaoGe = {}
calls = { click = 0, clear = 0, sound = 0 }
BG.BiaoGeHavedItem = function() return false end
decision = CheckAutoClearForInstance(548)
assert(decision.reason == "stage-empty" and calls.clear == 0,
    "entering an empty P2 stage must not clear")
BG.BiaoGeHavedItem = function() return true end
decision = CheckAutoClearForInstance(550)
assert(decision.reason == "stage-already-checked" and calls.clear == 0,
    "new P2 data added after the first entry must survive switching instances")

print("Stage-level automatic clear regression tests passed")

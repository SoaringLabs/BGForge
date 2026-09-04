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
    Maxb = {},
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

local GetAutoClearDecision = FindUpvalue(BG.ClearBiaoGeUI, "GetAutoClearDecision")
local ClearCurrentStage = FindUpvalue(BG.ClearBiaoGeUI, "ClearCurrentStage")

local function SavedInfo(rows)
    return function(index)
        local row = rows[index]
        return nil, nil, nil, nil, row.locked, nil, nil, nil, nil, nil, nil, nil, nil, row.instanceID
    end
end

local function Decide(currentInstanceID, rows, hasCurrentInstanceData)
    local function HasLedgerItem(FB, mode, instanceID)
        assert(mode == "autoQingKong", "automatic clear inspected data outside the current instance range")
        assert(FB == BG.FBIDtable[currentInstanceID], "automatic clear inspected the wrong shared ledger")
        assert(instanceID == currentInstanceID, "automatic clear inspected the wrong instance range")
        return hasCurrentInstanceData == true
    end
    return GetAutoClearDecision(currentInstanceID, #rows, SavedInfo(rows), HasLedgerItem)
end

local function AssertDecision(expected, reason, currentInstanceID, rows, hasCurrentInstanceData, message)
    local decision = Decide(currentInstanceID, rows, hasCurrentInstanceData)
    assert(decision.shouldClear == expected, message)
    assert(decision.reason == reason, message .. ": unexpected reason " .. tostring(decision.reason))
    if BG.FBIDtable[currentInstanceID] then
        assert(decision.FB == BG.FBIDtable[currentInstanceID], message .. ": wrong shared ledger")
    end
    return decision
end

AssertDecision(true, "current-instance-has-old-data", 568, {}, true,
    "a new ZA lockout with stale ZA rows must clear")
AssertDecision(false, "current-instance-empty", 568, {}, false,
    "a new ZA lockout without stale ZA rows must preserve sibling-only data")
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
AssertDecision(true, "current-instance-has-old-data", 568, { { locked = true, instanceID = 603 } }, true,
    "an unrelated phase lockout must not block stale ZA rows from clearing")
AssertDecision(true, "current-instance-has-old-data", 568, { { locked = false, instanceID = 580 } }, true,
    "unlocked saved rows must be ignored")
AssertDecision(false, "current-instance-empty", 568, {}, false,
    "an empty current instance range must not trigger destructive side effects")
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
assert(messages[2]:find("BOSS编号（1%-7）", 1, false), "clear reason must include the current instance boss range")
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

print("Stage-level automatic clear regression tests passed")

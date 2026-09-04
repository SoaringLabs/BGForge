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

local ShouldAutoClearStage = FindUpvalue(BG.ClearBiaoGeUI, "ShouldAutoClearStage")
local ClearCurrentStage = FindUpvalue(BG.ClearBiaoGeUI, "ClearCurrentStage")

local function SavedInfo(rows)
    return function(index)
        local row = rows[index]
        return nil, nil, nil, nil, row.locked, nil, nil, nil, nil, nil, nil, nil, nil, row.instanceID
    end
end

local function Decide(currentInstanceID, rows)
    return ShouldAutoClearStage(currentInstanceID, #rows, SavedInfo(rows))
end

local function AssertDecision(expected, currentInstanceID, rows, message)
    local actual = Decide(currentInstanceID, rows)
    assert(actual == expected, message)
end

AssertDecision(true, 568, {}, "P5 without lockouts must clear")
AssertDecision(false, 580, { { locked = true, instanceID = 568 } }, "ZA lockout must preserve the SW ledger")
AssertDecision(false, 568, { { locked = true, instanceID = 580 } }, "SW lockout must preserve the ZA ledger")
AssertDecision(false, 615, { { locked = true, instanceID = 533 } }, "Naxx lockout must preserve an OS entry")
AssertDecision(false, 616, { { locked = true, instanceID = 615 } }, "OS lockout must preserve an EOE entry")
AssertDecision(false, 533, { { locked = true, instanceID = 533 } }, "the current instance lockout must preserve its ledger")
AssertDecision(true, 568, { { locked = true, instanceID = 603 } }, "an unrelated phase lockout must not block clearing")
AssertDecision(true, 568, { { locked = false, instanceID = 580 } }, "unlocked saved rows must be ignored")
AssertDecision(true, 568, {}, "an unbound re-entry remains eligible to clear")
AssertDecision(false, 999999, {}, "unknown instances must not clear")

local shouldClear, FB = Decide(568, {})
if shouldClear then ClearCurrentStage(FB) end
assert(calls.click == 1 and calls.clickedFB == "SWtitan", "clear path must select the shared ledger once")
assert(calls.clear == 1 and calls.clearKind == "biaoge" and calls.clearedFB == "SWtitan",
    "clear path must clear the full shared ledger once")
assert(#messages == 1, "clear path must emit exactly one success message")
assert(calls.sound == 1 and calls.soundName == "qingkong", "clear path must play the clear sound once")

calls = { click = 0, clear = 0, sound = 0 }
messages = {}
shouldClear, FB = Decide(580, { { locked = true, instanceID = 568 } })
if shouldClear then ClearCurrentStage(FB) end
assert(calls.click == 0 and calls.clear == 0 and calls.sound == 0 and #messages == 0,
    "preserve path must have no clear side effects")

print("Stage-level automatic clear regression tests passed")

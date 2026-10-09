local sourcePath = "Core/Module/RurutiaSuiteCompat.lua"

-- RurutiaSuite 4.2.9 publishes its Runtime namespace without AceAddon-3.0.
LibStub = nil
C_AddOns = {
    GetAddOnMetadata = function() return "4.2.9" end,
}

local toggles = 0
BG = {
    ToggleMainFrame = function()
        toggles = toggles + 1
        return true
    end,
}

local function NewWatcher()
    local frame = { events = {}, scripts = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    function frame:SetScript(script, callback) self.scripts[script] = callback end
    return frame
end

local watcher
function CreateFrame()
    watcher = NewWatcher()
    return watcher
end

local originalCalls = 0
local function NewChatBar()
    return {
        HandleButtonClick = function(_, info, mouseButton)
            originalCalls = originalCalls + 1
            return mouseButton, info
        end,
    }
end

-- BGForge loads first; the public namespace is populated on ADDON_LOADED.
RurutiaSuite = nil
assert(loadfile(sourcePath))("BGForge", {})
assert(watcher.events.ADDON_LOADED, "must wait for RurutiaSuite to load")
local chatBar = NewChatBar()
RurutiaSuite = { ChatBar = chatBar }
watcher.scripts.OnEvent(watcher, "ADDON_LOADED", "RurutiaSuite")

local gold = { key = "goldLedger", text = "金", action = "addon" }
assert(chatBar:HandleButtonClick(gold, "LeftButton") == true and toggles == 1,
    "4.2.9 gold click must open BGForge without AceAddon-3.0")
assert(chatBar:HandleButtonClick(gold, "RightButton") == true and toggles == 2,
    "new Runtime must preserve the existing right-click toggle")
assert(originalCalls == 0, "gold clicks must bypass the original addon lookup")
assert(watcher.events.ADDON_LOADED == nil, "must stop watching after installation")

local wrapped = chatBar.HandleButtonClick
assert(BG.InstallRurutiaSuiteGoldLedgerCompat() == true)
assert(chatBar.HandleButtonClick == wrapped, "installation must remain idempotent")

local other = { key = "loot", action = "loot" }
local button, info = chatBar:HandleButtonClick(other, "LeftButton")
assert(button == "LeftButton" and info == other and originalCalls == 1,
    "other buttons must retain all original return values")
chatBar:HandleButtonClick({ key = "goldLedger", action = "open" }, "LeftButton")
chatBar:HandleButtonClick(nil, "LeftButton")
assert(toggles == 2 and originalCalls == 3, "only the gold addon action may be intercepted")

-- RurutiaSuite already loaded, with the same module available through Runtime.
chatBar = NewChatBar()
RurutiaSuite = {
    Runtime = {
        GetModule = function(_, name)
            assert(name == "ChatBar")
            return chatBar
        end,
    },
}
assert(loadfile(sourcePath))("BGForge", {})
assert(watcher.events.ADDON_LOADED == nil, "already loaded Runtime needs no watcher")
assert(chatBar:HandleButtonClick(gold, "LeftButton") == true and toggles == 3,
    "Runtime module lookup must work when RurutiaSuite loads first")

print("RurutiaSuite Runtime gold-ledger compatibility regression tests passed")

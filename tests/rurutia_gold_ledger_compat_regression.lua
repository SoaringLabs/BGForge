local sourcePath = "Core/Module/RurutiaSuiteCompat.lua"

local visible = false
local toggleCount = 0
BG = {
    ToggleMainFrame = function()
        visible = not visible
        toggleCount = toggleCount + 1
        return true
    end,
}

C_AddOns = {
    GetAddOnMetadata = function(addonName, field)
        assert(addonName == "RurutiaSuite")
        assert(field == "Version")
        return "3.7.2"
    end,
}

local originalCalls = {}
local chatBar = {}
function chatBar:HandleButtonClick(info, mouseButton)
    originalCalls[#originalCalls + 1] = { info = info, mouseButton = mouseButton }
    return "original-result"
end

local rurutiaLoaded = false
local rurutia = {}
function rurutia:GetModule(name, silent)
    assert(name == "ChatBar")
    assert(silent == true)
    return chatBar
end

local aceAddon = {}
function aceAddon:GetAddon(name, silent)
    assert(name == "RurutiaSuite")
    assert(silent == true)
    if rurutiaLoaded then return rurutia end
end

LibStub = setmetatable({
    GetLibrary = function(_, name, silent)
        assert(name == "AceAddon-3.0")
        assert(silent == true)
        return aceAddon
    end,
}, {
    __call = function(_, name, silent)
        assert(name == "AceAddon-3.0")
        assert(silent == true)
        return aceAddon
    end,
})

local eventFrame = { events = {}, scripts = {} }
function eventFrame:RegisterEvent(event)
    self.events[event] = true
end
function eventFrame:UnregisterEvent(event)
    self.events[event] = nil
end
function eventFrame:SetScript(script, callback)
    self.scripts[script] = callback
end
function CreateFrame(frameType)
    assert(frameType == "Frame")
    return eventFrame
end

assert(loadfile(sourcePath))("BGForge", {})

assert(eventFrame.events.ADDON_LOADED == true,
    "compatibility watcher must wait when RurutiaSuite has not loaded yet")

eventFrame.scripts.OnEvent(eventFrame, "ADDON_LOADED", "SomeOtherAddon")
assert(chatBar.__BGForgeGoldLedgerCompat == nil,
    "unrelated addon loads must not install the compatibility wrapper")

rurutiaLoaded = true
eventFrame.scripts.OnEvent(eventFrame, "ADDON_LOADED", "RurutiaSuite")
assert(chatBar.__BGForgeGoldLedgerCompat == true,
    "RurutiaSuite load must install the gold-ledger compatibility wrapper")
assert(eventFrame.events.ADDON_LOADED == nil,
    "successful installation must remove the one-shot addon watcher")

chatBar:HandleButtonClick({ key = "goldLedger", type = "addon" }, "LeftButton")
assert(visible == true and toggleCount == 1,
    "left-clicking RurutiaSuite's gold ledger must open BGForge")
assert(#originalCalls == 0,
    "the intercepted gold-ledger click must not call RurutiaSuite's original handler")

chatBar:HandleButtonClick({ key = "goldLedger", type = "addon" }, "RightButton")
assert(visible == false and toggleCount == 2,
    "the compatibility wrapper must preserve the existing both-buttons toggle behavior")

local result = chatBar:HandleButtonClick({ key = "loot", type = "loot" }, "LeftButton")
assert(result == "original-result" and #originalCalls == 1,
    "non-gold buttons must retain RurutiaSuite's original behavior and return value")

local wrapped = chatBar.HandleButtonClick
assert(BG.InstallRurutiaSuiteGoldLedgerCompat() == true,
    "reinstalling an existing compatibility wrapper must report success")
assert(chatBar.HandleButtonClick == wrapped,
    "compatibility installation must be idempotent")

print("RurutiaSuite gold-ledger compatibility regression tests passed")

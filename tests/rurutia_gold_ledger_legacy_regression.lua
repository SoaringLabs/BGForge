local sourcePath = "Core/Module/RurutiaSuiteCompat.lua"

BG = {
    ToggleMainFrame = function()
        error("BGForge must not intercept legacy RurutiaSuite clicks")
    end,
}

C_AddOns = {
    GetAddOnMetadata = function(addonName, field)
        assert(addonName == "RurutiaSuite")
        assert(field == "Version")
        return "3.7.1"
    end,
}

local originalCalls = 0
local chatBar = {}
function chatBar:HandleButtonClick(info, mouseButton)
    originalCalls = originalCalls + 1
    return info.key .. ":" .. mouseButton
end
local original = chatBar.HandleButtonClick

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
    return rurutia
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

local eventFrame = { registered = false }
function eventFrame:RegisterEvent()
    self.registered = true
end
function eventFrame:UnregisterEvent()
    self.registered = false
end
function eventFrame:SetScript() end
function CreateFrame(frameType)
    assert(frameType == "Frame")
    return eventFrame
end

assert(loadfile(sourcePath))("BGForge", {})

assert(chatBar.HandleButtonClick == original,
    "legacy RurutiaSuite must retain its original click handler")
assert(chatBar.__BGForgeGoldLedgerCompat == nil,
    "legacy RurutiaSuite must not receive the BGForge compatibility marker")
assert(eventFrame.registered == false,
    "a detected legacy version must not leave an addon watcher running")

local result = chatBar:HandleButtonClick({ key = "biaoge", type = "addon" }, "LeftButton")
assert(result == "biaoge:LeftButton" and originalCalls == 1,
    "legacy gold-button behavior must pass through unchanged")

print("Legacy RurutiaSuite compatibility regression tests passed")

-- RurutiaSuite compatibility.
-- Its v3.7.2 chat-bar gold button only recognizes BGLite/BGNext by addon name,
-- so route that one button to BGForge without changing the third-party addon.

local _, ns = ...
local BG = _G.BG
if not BG then return end

local AFFECTED_RURUTIA_VERSION = "3.7.2"

local function GetRurutiaVersion()
    local getMetadata = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
    if type(getMetadata) ~= "function" then return end
    return getMetadata("RurutiaSuite", "Version")
end

local function IsAffectedRurutiaVersion()
    local version = GetRurutiaVersion()
    if type(version) ~= "string" then return false end
    local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
    if not major then return false end
    return table.concat({ major, minor, patch }, ".") == AFFECTED_RURUTIA_VERSION
end

local function GetRurutiaChatBar()
    local libStub = _G.LibStub
    if not libStub or type(libStub.GetLibrary) ~= "function" then return end

    local aceAddon = libStub:GetLibrary("AceAddon-3.0", true)
    if not aceAddon or type(aceAddon.GetAddon) ~= "function" then return end

    local rurutia = aceAddon:GetAddon("RurutiaSuite", true)
    if not rurutia or type(rurutia.GetModule) ~= "function" then return end

    return rurutia:GetModule("ChatBar", true)
end

local function ToggleBGForgeMainFrame()
    if type(BG.ToggleMainFrame) == "function" then
        return BG.ToggleMainFrame()
    end

    local frame = BG.MainFrame
    if not frame or type(frame.SetShown) ~= "function" or type(frame.IsVisible) ~= "function" then
        return false
    end
    frame:SetShown(not frame:IsVisible())
    return true
end

function BG.InstallRurutiaSuiteGoldLedgerCompat()
    local chatBar = GetRurutiaChatBar()
    if not chatBar then return false end
    if not IsAffectedRurutiaVersion() then return true end
    if chatBar.__BGForgeGoldLedgerCompat then return true end

    local original = chatBar.HandleButtonClick
    if type(original) ~= "function" then return false end

    chatBar.HandleButtonClick = function(self, info, ...)
        if info and info.key == "goldLedger" and info.type == "addon" then
            return ToggleBGForgeMainFrame()
        end
        return original(self, info, ...)
    end
    chatBar.__BGForgeGoldLedgerCompat = true
    return true
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function(self, _, addonName)
    if addonName ~= "RurutiaSuite" then return end
    BG.InstallRurutiaSuiteGoldLedgerCompat()
    self:UnregisterEvent("ADDON_LOADED")
end)

if not BG.InstallRurutiaSuiteGoldLedgerCompat() then
    watcher:RegisterEvent("ADDON_LOADED")
end

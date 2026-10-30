local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local CHANNEL_ORDER = { "RAID", "GUILD", "SAY", "YELL" }

local function AddChannelButton(menu, channelName, current)
    local menuItem = LibBG:UIDropDownMenu_CreateInfo()
    menuItem.text = _G[channelName]
    menuItem.func = function()
        BiaoGe.NotifyChannel = channelName
        LibBG:UIDropDownMenu_SetText(menu, _G[BiaoGe.NotifyChannel])
    end
    if current == channelName then
        menuItem.checked = true
    end
    LibBG:UIDropDownMenu_AddButton(menuItem)
end

local function InitChannelMenu(menu, title, current)
    local menuItem = LibBG:UIDropDownMenu_CreateInfo()
    menuItem.text = title
    menuItem.isTitle = true
    menuItem.notCheckable = true
    LibBG:UIDropDownMenu_AddButton(menuItem)
    for _, channelName in ipairs(CHANNEL_ORDER) do
        AddChannelButton(menu, channelName, current)
    end
end

function BG.NotifyChannelUI(previousButton)
    BiaoGe.NotifyChannel = BiaoGe.NotifyChannel or "RAID"
    if not _G[BiaoGe.NotifyChannel] then
        BiaoGe.NotifyChannel = "RAID"
    end

    local menu = LibBG:Create_UIDropDownMenu(nil, BG.ButtonZhangDan)
    BG.dropDownToggle(menu)
    menu:SetPoint("LEFT", previousButton, "RIGHT", -5, -3)
    LibBG:UIDropDownMenu_SetWidth(menu, 50)
    LibBG:UIDropDownMenu_SetAnchor(menu, 0, 0, "BOTTOM", menu, "TOP")
    LibBG:UIDropDownMenu_SetText(menu, _G[BiaoGe.NotifyChannel])
    LibBG:UIDropDownMenu_Initialize(menu, function(tmpValue, itemLevel, tmpValue2)
        InitChannelMenu(menu, L["通报频道"], BiaoGe.NotifyChannel)
    end)
end

BG = {
    IsTitan = true,
    GSN = function(name)
        return name and name:match("^[^-]+")
    end,
    IsSecret = function()
        return false
    end,
}

strlen = string.len
tinsert = table.insert
unpack = unpack or table.unpack

local eventHandlers = {}
function BG.RegisterEvent(event, callback)
    eventHandlers[event] = callback
end

local filters = {}
function ChatFrame_AddMessageEventFilter(event, callback)
    filters[event] = callback
end

local setItemRefHook
function hooksecurefunc(name, callback)
    assert(name == "SetItemRef")
    setItemRefHook = callback
end

function strsplit(separator, value)
    local fields = {}
    local from = 1
    while true do
        local first, last = value:find(separator, from, true)
        if not first then
            table.insert(fields, value:sub(from))
            break
        end
        table.insert(fields, value:sub(from, first - 1))
        from = last + 1
    end
    return unpack(fields)
end

local serverTime = 1000
function GetServerTime()
    return serverTime
end

local inRaid = true
function IsInRaid()
    return inRaid
end

function GetNumGroupMembers()
    return 2
end

function UnitIsGroupLeader(unit)
    return unit == "raid1"
end

function GetUnitName(unit)
    if unit == "raid1" then return "Leader-Realm" end
    return "Assistant-Realm"
end

local editBox = {
    text = "",
    cursor = 0,
    highlighted = false,
}
function editBox:GetText()
    return self.text
end
function editBox:SetText(value)
    self.text = value
    self.cursor = #value
end
function editBox:HighlightText()
    self.highlighted = true
end
function editBox:GetCursorPosition()
    return self.cursor
end
function editBox:Insert(value)
    self.text = self.text:sub(1, self.cursor) .. value .. self.text:sub(self.cursor + 1)
    self.cursor = self.cursor + #value
end

function ChatEdit_ChooseBoxForSend()
    return editBox
end
function ChatEdit_ActivateChat() end

dofile("Core/Module/ChatYYLink.lua")

local function Link(yy)
    return "|cff00BFFF|Hgarrmission:BGForgeYY:copy:" .. yy .. "|h[YY:" .. yy .. "]|h|r"
end

local function AssertEqual(actual, expected, name)
    if actual ~= expected then
        error(name .. "\nexpected: " .. tostring(expected) .. "\nactual:   " .. tostring(actual))
    end
end

AssertEqual(BG.ChatYYLink.LinkifyMessage("YY:12345 开组", false), Link("12345") .. " 开组", "basic YY label")
AssertEqual(BG.ChatYYLink.LinkifyMessage("yy号：12 345", false), Link("12345"), "YY number label with spaces")
AssertEqual(BG.ChatYYLink.LinkifyMessage("歪歪9876", false), Link("9876"), "Chinese YY label")
AssertEqual(BG.ChatYYLink.LinkifyMessage("9876YY", false), Link("9876"), "reverse YY label")
AssertEqual(BG.ChatYYLink.LinkifyMessage("abcYY12345xyz", false), "abcYY12345xyz", "ASCII word boundaries")
AssertEqual(BG.ChatYYLink.LinkifyMessage("YY123", false), "YY123", "minimum length")
AssertEqual(BG.ChatYYLink.LinkifyMessage("YY1234567890123", false), "YY1234567890123", "maximum length")
AssertEqual(BG.ChatYYLink.LinkifyMessage("12345", false), "12345", "pure number disabled")
AssertEqual(BG.ChatYYLink.LinkifyMessage(" 12 345 ", true), Link("12345"), "pure number enabled")

local existing = "|Hitem:123|h[YY:9999]|h"
AssertEqual(BG.ChatYYLink.LinkifyMessage(existing .. " YY5678", false), existing .. " " .. Link("5678"), "existing hyperlink protection")

eventHandlers.GROUP_JOINED()
local _, linked = filters.CHAT_MSG_RAID_LEADER(nil, "CHAT_MSG_RAID_LEADER", "12345", "Leader-Realm")
AssertEqual(linked, Link("12345"), "leader pure number during join window")

serverTime = serverTime + 601
AssertEqual(filters.CHAT_MSG_RAID_LEADER(nil, "CHAT_MSG_RAID_LEADER", "12345", "Leader-Realm"), nil,
    "leader pure number after join window")

local _, warning = filters.CHAT_MSG_RAID_WARNING(nil, "CHAT_MSG_RAID_WARNING", "YY12345", "Leader-Realm")
AssertEqual(warning, Link("12345"), "raid leader warning")
AssertEqual(filters.CHAT_MSG_RAID_WARNING(nil, "CHAT_MSG_RAID_WARNING", "YY12345", "Assistant-Realm"), nil,
    "assistant raid warning ignored")
local _, instanceLink = filters.CHAT_MSG_INSTANCE_CHAT_LEADER(nil, "CHAT_MSG_INSTANCE_CHAT_LEADER", "YY54321", "Leader-Realm")
AssertEqual(instanceLink, Link("54321"), "instance leader chat")

editBox.text = ""
editBox.cursor = 0
editBox.highlighted = false
setItemRefHook("garrmission:BGForgeYY:copy:12345")
AssertEqual(editBox.text, "12345", "empty chat edit insertion")
AssertEqual(editBox.highlighted, true, "empty chat edit selection")

editBox.text = "已有草稿"
editBox.cursor = #editBox.text
editBox.highlighted = false
setItemRefHook("garrmission:BGForgeYY:copy:67890")
AssertEqual(editBox.text, "已有草稿 67890", "existing chat draft preservation")
AssertEqual(editBox.highlighted, false, "existing draft is not selected")

print("Chat YY link regression tests passed")

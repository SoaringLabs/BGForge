if not BG.IsTitan then return end

local PURE_NUMBER_WINDOW_SECONDS = 10 * 60
local MIN_YY_DIGITS = 4
local MAX_YY_DIGITS = 12
local LINK_TYPE = "BGForgeYY"

local ChatYYLink = {}
BG.ChatYYLink = ChatYYLink

local forwardPatterns = {
    "[yY][yY]号[：:_/%-%s]*([%d%s][%d%s][%d%s][%d%s]*%d+)",
    "[yY][yY][：:_/%-%s]*([%d%s][%d%s][%d%s][%d%s]*%d+)",
    "歪歪号[：:_/%-%s]*([%d%s][%d%s][%d%s][%d%s]*%d+)",
    "歪歪[：:_/%-%s]*([%d%s][%d%s][%d%s][%d%s]*%d+)",
}

local reversePatterns = {
    "(%d+[%d%s][%d%s][%d%s][%d%s]*)[：:_/%-%s]*[yY][yY]",
    "(%d+[%d%s][%d%s][%d%s][%d%s]*)[：:_/%-%s]*歪歪",
}

local function NormalizeYY(value)
    if type(value) ~= "string" then return end
    local yy = value:gsub("%s", "")
    if not yy:match("^%d+$") then return end
    if strlen(yy) < MIN_YY_DIGITS or strlen(yy) > MAX_YY_DIGITS then return end
    return yy
end

local function IsAsciiWordAt(text, index)
    if index < 1 or index > strlen(text) then return false end
    return text:sub(index, index):match("[%w_]") ~= nil
end

local function CreateLink(yy)
    return "|cff00BFFF|Hgarrmission:" .. LINK_TYPE .. ":copy:" .. yy .. "|h[YY:" .. yy .. "]|h|r"
end

local function FindPattern(text, pattern, from)
    local searchFrom = from
    while searchFrom <= strlen(text) do
        local first, last, captured = text:find(pattern, searchFrom)
        if not first then return end
        local yy = NormalizeYY(captured)
        if yy and not IsAsciiWordAt(text, first - 1) and not IsAsciiWordAt(text, last + 1) then
            return first, last, yy
        end
        searchFrom = first + 1
    end
end

local function FindNextYY(text, from)
    local bestFirst, bestLast, bestYY
    local function Consider(pattern)
        local first, last, yy = FindPattern(text, pattern, from)
        if first and (not bestFirst or first < bestFirst or (first == bestFirst and last > bestLast)) then
            bestFirst, bestLast, bestYY = first, last, yy
        end
    end
    for _, pattern in ipairs(forwardPatterns) do
        Consider(pattern)
    end
    for _, pattern in ipairs(reversePatterns) do
        Consider(pattern)
    end
    return bestFirst, bestLast, bestYY
end

local function LinkifyPlainText(text)
    local output = {}
    local cursor = 1
    while cursor <= strlen(text) do
        local first, last, yy = FindNextYY(text, cursor)
        if not first then
            tinsert(output, text:sub(cursor))
            break
        end
        tinsert(output, text:sub(cursor, first - 1))
        tinsert(output, CreateLink(yy))
        cursor = last + 1
    end
    return table.concat(output)
end

local function LinkifyOutsideExistingLinks(message)
    local output = {}
    local cursor = 1
    while cursor <= strlen(message) do
        local linkStart = message:find("|H", cursor, true)
        if not linkStart then
            tinsert(output, LinkifyPlainText(message:sub(cursor)))
            break
        end

        tinsert(output, LinkifyPlainText(message:sub(cursor, linkStart - 1)))
        local firstLinkEnd = message:find("|h", linkStart + 2, true)
        local secondLinkEnd = firstLinkEnd and message:find("|h", firstLinkEnd + 2, true)
        if not secondLinkEnd then
            tinsert(output, message:sub(linkStart))
            break
        end
        tinsert(output, message:sub(linkStart, secondLinkEnd + 1))
        cursor = secondLinkEnd + 2
    end
    return table.concat(output)
end

function ChatYYLink.LinkifyMessage(message, allowPureNumber)
    if type(message) ~= "string" then return message end
    if allowPureNumber and not message:find("|H", 1, true) then
        local yy = NormalizeYY(message)
        if yy then
            return CreateLink(yy)
        end
    end
    return LinkifyOutsideExistingLinks(message)
end

local pureNumberUntil
BG.RegisterEvent("GROUP_JOINED", function()
    if IsInRaid(1) then
        pureNumberUntil = GetServerTime() + PURE_NUMBER_WINDOW_SECONDS
    end
end)
BG.RegisterEvent("GROUP_ROSTER_UPDATE", function()
    if not IsInRaid(1) then
        pureNumberUntil = nil
    end
end)

local function IsLeaderMessage(event, sender)
    if event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_PARTY_LEADER"
        or event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
        return true
    end
    if event ~= "CHAT_MSG_RAID_WARNING" or not sender then return false end

    local senderName = BG.GSN(sender)
    local prefix = IsInRaid(1) and "raid" or "party"
    local count = GetNumGroupMembers()
    for i = 1, count do
        local unit = prefix .. i
        if UnitIsGroupLeader(unit) and BG.GSN(GetUnitName(unit, true)) == senderName then
            return true
        end
    end
    return false
end

local function FilterLeaderMessage(_, event, message, sender, ...)
    if BG.IsSecret(message) or not IsLeaderMessage(event, sender) then return end
    local allowPureNumber = pureNumberUntil and GetServerTime() <= pureNumberUntil
    local linkedMessage = ChatYYLink.LinkifyMessage(message, allowPureNumber)
    if linkedMessage == message then return end
    return false, linkedMessage, sender, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", FilterLeaderMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", FilterLeaderMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", FilterLeaderMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", FilterLeaderMessage)

local function InsertIntoChat(yy)
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then return end
    ChatEdit_ActivateChat(editBox)

    local text = editBox:GetText() or ""
    if text == "" then
        editBox:SetText(yy)
        editBox:HighlightText()
        return
    end

    local cursor = editBox:GetCursorPosition() or strlen(text)
    local insertion = yy
    if cursor > 0 and not text:sub(cursor, cursor):match("%s") then
        insertion = " " .. insertion
    end
    if cursor < strlen(text) and not text:sub(cursor + 1, cursor + 1):match("%s") then
        insertion = insertion .. " "
    end
    editBox:Insert(insertion)
end

hooksecurefunc("SetItemRef", function(link)
    local linkKind, linkType, action, yy = strsplit(":", link)
    if linkKind ~= "garrmission" or linkType ~= LINK_TYPE or action ~= "copy" then return end
    yy = NormalizeYY(yy)
    if yy then
        InsertIntoChat(yy)
    end
end)

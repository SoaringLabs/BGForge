local _, ns = ...

local L = ns.L

-- 隐私边界：只保存本机实际登录过的角色及其团本锁定快照。
-- 不发送插件消息，也不读取战网账号、GUID、好友、公会或其他设备的数据。
local RAIDS = {
    { id = 580, name = L["太阳井"], compactWidth = 50 },
    { id = 568, name = L["祖阿曼"], compactWidth = 50 },
    { id = 649, name = L["十字军"], compactWidth = 50 },
    { id = 309, name = L["祖格"], compactWidth = 42 },
    { id = 533, name = L["纳克萨玛斯"], compactWidth = 70 },
    { id = 615, name = L["黑曜石"], compactWidth = 50 },
    { id = 616, name = L["永恒"], compactWidth = 42 },
    { id = 548, name = L["毒蛇"], compactWidth = 42 },
    { id = 550, name = L["风暴"], compactWidth = 42 },
    { id = 409, name = L["熔火"], compactWidth = 42 },
    { id = 624, name = L["宝库"], compactWidth = 42 },
}

local raidByID = {}
for _, raid in ipairs(RAIDS) do
    raidByID[raid.id] = raid
end

local RAID_OPTION_PREFIX = "raidLockoutShow_"
local DATA_VERSION = 1
local DATA_KEY = "BGForgeRaidLockouts"

local function GetRaidOptionKey(raidID)
    return RAID_OPTION_PREFIX .. raidID
end

local function IsRaidVisible(raid)
    local options = BiaoGe and BiaoGe.options
    local value = options and options[GetRaidOptionKey(raid.id)]
    return value == nil or value == 1
end

local function GetVisibleRaids()
    local raids = {}
    for _, raid in ipairs(RAIDS) do
        if IsRaidVisible(raid) then
            raids[#raids + 1] = raid
        end
    end
    return raids
end

local currentCharacter = {
    instances = {},
    ready = false,
    refreshing = false,
    requestSerial = 0,
    lastRequestAt = nil,
}
local deletedThisSession = {}

local overviewFrame
local hoverFrame
local updateOverviewFrame
local updateHoverFrame

local function GetCurrentRealmID()
    return GetRealmID()
end

local function GetCurrentCharacterName()
    return UnitName("player") or BG.playerName or UNKNOWN
end

local function GetCharacterKey(realmID, characterName)
    return tostring(realmID) .. ":" .. characterName
end

local function GetDataStore()
    BiaoGe = BiaoGe or {}
    local data = BiaoGe[DATA_KEY]
    if type(data) ~= "table" or data.schemaVersion ~= DATA_VERSION then
        data = {
            schemaVersion = DATA_VERSION,
            nextResetAt = nil,
            realms = {},
        }
        BiaoGe[DATA_KEY] = data
    end
    data.realms = type(data.realms) == "table" and data.realms or {}
    data.nextResetAt = tonumber(data.nextResetAt)
    return data
end

local function GetRealmStore(realmID, create)
    local data = GetDataStore()
    local realm = data.realms[realmID]
    if not realm and create then
        realm = {
            nextOrder = 1,
            characters = {},
        }
        data.realms[realmID] = realm
    end
    if realm then
        realm.characters = type(realm.characters) == "table" and realm.characters or {}
        local nextOrder = tonumber(realm.nextOrder) or 1
        for _, character in pairs(realm.characters) do
            if type(character) == "table" and tonumber(character.order) then
                nextOrder = max(nextOrder, tonumber(character.order) + 1)
            end
        end
        realm.nextOrder = nextOrder
    end
    return realm
end

local function ClearExpiredRaidData()
    local data = GetDataStore()
    local now = GetServerTime()
    local resetAll = data.nextResetAt and now >= data.nextResetAt

    for _, realm in pairs(data.realms) do
        if type(realm) == "table" and type(realm.characters) == "table" then
            for characterName, character in pairs(realm.characters) do
                if type(character) == "table" then
                    character.name = type(character.name) == "string" and character.name or characterName
                    character.specIndex = tonumber(character.specIndex)
                    character.itemLevel = tonumber(character.itemLevel)
                    character.order = tonumber(character.order)
                    character.lastRecordedAt = tonumber(character.lastRecordedAt)
                    if resetAll then
                        character.instances = {}
                    elseif type(character.instances) == "table" then
                        for raidID, lockouts in pairs(character.instances) do
                            if not raidByID[tonumber(raidID)] or type(lockouts) ~= "table" then
                                character.instances[raidID] = nil
                            else
                                for index = #lockouts, 1, -1 do
                                    local lockout = lockouts[index]
                                    local resetAt = type(lockout) == "table" and tonumber(lockout.resetAt)
                                    if not resetAt or now >= resetAt then
                                        tremove(lockouts, index)
                                    else
                                        lockout.resetAt = resetAt
                                        lockout.difficultyName = type(lockout.difficultyName) == "string"
                                            and lockout.difficultyName or UNKNOWN
                                        lockout.killedCount = tonumber(lockout.killedCount) or 0
                                        lockout.numEncounters = tonumber(lockout.numEncounters) or 0
                                        lockout.bosses = type(lockout.bosses) == "table" and lockout.bosses or {}
                                        for bossIndex = #lockout.bosses, 1, -1 do
                                            local boss = lockout.bosses[bossIndex]
                                            if type(boss) ~= "table" then
                                                tremove(lockout.bosses, bossIndex)
                                            else
                                                boss.name = type(boss.name) == "string" and boss.name or UNKNOWN
                                                boss.killed = boss.killed and true or false
                                            end
                                        end
                                    end
                                end
                                if #lockouts == 0 then
                                    character.instances[raidID] = nil
                                end
                            end
                        end
                    else
                        character.instances = {}
                    end
                else
                    realm.characters[characterName] = nil
                end
            end
        end
    end

    if resetAll then
        data.nextResetAt = nil
    end
    return resetAll
end

local function GetCurrentTalentIndex()
    if BG.verOver4 then
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
            return C_SpecializationInfo.GetSpecialization()
        elseif GetSpecialization then
            return GetSpecialization()
        end
        return
    end

    -- 泰坦服使用 3.8 系列客户端：以当前双天赋组中投入点数最多的天赋树作为当前专精。
    local activeGroup = GetActiveTalentGroup and GetActiveTalentGroup()
    local maxPoints = 0
    local talentIndex
    for index = 1, 3 do
        local points = select(5, GetTalentTabInfo(index, nil, nil, activeGroup))
        if points and points >= maxPoints then
            maxPoints = points
            talentIndex = index
        end
    end
    return maxPoints > 0 and talentIndex or nil
end

local function RefreshCurrentCharacterIdentity()
    currentCharacter.name = GetCurrentCharacterName()
    currentCharacter.classFile = select(2, UnitClass("player"))
    local overallItemLevel, equippedItemLevel = GetAverageItemLevel()
    currentCharacter.itemLevel = equippedItemLevel or overallItemLevel

    currentCharacter.specIndex = GetCurrentTalentIndex()
end

local function GetCharacterSpecIcon(character)
    local classIcons = BG.talentIcon and BG.talentIcon[character.classFile]
    return classIcons and character.specIndex and classIcons[character.specIndex] or nil
end

local function GetCharacterDisplayName(character)
    local color = character.classFile and select(4, GetClassColor(character.classFile)) or "ffffffff"
    local specIcon = GetCharacterSpecIcon(character)
    local text = specIcon and ("|T" .. specIcon .. ":14:14:0:0|t ") or ""
    text = text .. "|c" .. color .. character.name .. "|r"
    if character.itemLevel and character.itemLevel > 0 then
        text = text .. " |cffb3b3b3(" .. floor(character.itemLevel + 0.5) .. ")|r"
    end
    return text
end

local function BuildCharacterRows(realmID)
    ClearExpiredRaidData()
    local realm = GetRealmStore(realmID, false)
    local characters = {}
    local currentRealmID = GetCurrentRealmID()
    local currentName = GetCurrentCharacterName()

    if realm then
        for name, stored in pairs(realm.characters) do
            if type(stored) == "table" and type(name) == "string" then
                local character = {
                    name = stored.name or name,
                    classFile = stored.classFile,
                    specIndex = stored.specIndex,
                    itemLevel = stored.itemLevel,
                    order = tonumber(stored.order) or math.huge,
                    lastRecordedAt = stored.lastRecordedAt,
                    instances = type(stored.instances) == "table" and stored.instances or {},
                    ready = true,
                    isCurrent = realmID == currentRealmID and name == currentName,
                }
                character.displayName = GetCharacterDisplayName(character)
                characters[#characters + 1] = character
            end
        end
    end

    sort(characters, function(a, b)
        if a.order == b.order then
            return a.name < b.name
        end
        return a.order < b.order
    end)
    return characters
end

local function GetCharacterRows()
    return BuildCharacterRows(GetCurrentRealmID())
end

local function FormatResetTime(seconds)
    seconds = max(0, floor(seconds or 0))
    local days = floor(seconds / 86400)
    local hours = floor(seconds % 86400 / 3600)
    local minutes = floor(seconds % 3600 / 60)

    if days > 0 then
        return days .. L["天"] .. hours .. L["小时"]
    elseif hours > 0 then
        return hours .. L["小时"] .. minutes .. L["分钟"]
    else
        return minutes .. L["分钟"]
    end
end

local function GetRaidResetTime()
    ClearExpiredRaidData()
    local nextResetAt = GetDataStore().nextResetAt
    if nextResetAt and nextResetAt > GetServerTime() then
        return nextResetAt - GetServerTime()
    end
end

local function GetPrimaryLockout(lockouts)
    local primary
    for _, lockout in ipairs(lockouts or {}) do
        if not primary or lockout.killedCount > primary.killedCount then
            primary = lockout
        end
    end
    return primary
end

local function UpdateStatusDisplay(status, character, lockout, compact)
    status.check:Hide()

    if not character.ready then
        status.text:SetText("…")
        status.text:SetTextColor(0.55, 0.55, 0.55)
    elseif not lockout then
        status.text:SetText("—")
        status.text:SetTextColor(0.38, 0.38, 0.38)
    elseif compact or lockout.numEncounters == 0 or lockout.killedCount >= lockout.numEncounters then
        status.text:SetText("")
        status.check:Show()
    else
        status.text:SetFormattedText("%d/%d", lockout.killedCount, lockout.numEncounters)
        status.text:SetTextColor(1, 0.82, 0)
    end
end

local function CreateStatusDisplay(parent, width, height, checkSize, fontSize)
    local status = CreateFrame("Frame", nil, parent)
    status:SetSize(width, height)

    local text = status:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetAllPoints()
    text:SetJustifyH("CENTER")
    if fontSize then
        text:SetFont(BIAOGE_TEXT_FONT, fontSize, "OUTLINE")
    end
    status.text = text

    local check = status:CreateTexture(nil, "OVERLAY")
    check:SetSize(checkSize or 18, checkSize or 18)
    check:SetPoint("CENTER")
    check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    check:Hide()
    status.check = check

    return status
end

local function CaptureRaidInfo()
    ClearExpiredRaidData()
    RefreshCurrentCharacterIdentity()
    local instances = {}
    local capturedAt = GetServerTime()
    local nextResetAt

    for index = 1, GetNumSavedInstances() do
        local _, _, resetTime, _, locked, _, _, _, _,
        difficultyName, numEncounters, _, _, instanceID = GetSavedInstanceInfo(index)

        if locked and raidByID[instanceID] then
            local bosses = {}
            local killedCount = 0

            for encounterIndex = 1, (numEncounters or 0) do
                local bossName, _, isKilled = GetSavedInstanceEncounterInfo(index, encounterIndex)
                bosses[#bosses + 1] = {
                    name = bossName or UNKNOWN,
                    killed = isKilled and true or false,
                }
                if isKilled then
                    killedCount = killedCount + 1
                end
            end

            instances[instanceID] = instances[instanceID] or {}
            instances[instanceID][#instances[instanceID] + 1] = {
                bosses = bosses,
                difficultyName = difficultyName or UNKNOWN,
                killedCount = killedCount,
                numEncounters = numEncounters or 0,
                resetAt = resetTime and resetTime > 0 and (capturedAt + resetTime) or nil,
            }
            if resetTime and resetTime > 0 then
                local candidate = capturedAt + resetTime
                if not nextResetAt or candidate < nextResetAt then
                    nextResetAt = candidate
                end
            end
        end
    end

    currentCharacter.instances = instances
    currentCharacter.ready = true
    currentCharacter.refreshing = false
    currentCharacter.updatedAt = date("%H:%M:%S")

    local realmID = GetCurrentRealmID()
    local characterName = currentCharacter.name
    local characterKey = GetCharacterKey(realmID, characterName)
    if not deletedThisSession[characterKey] then
        local realm = GetRealmStore(realmID, true)
        local stored = realm.characters[characterName]
        if type(stored) ~= "table" then
            stored = {
                name = characterName,
                order = realm.nextOrder,
            }
            realm.nextOrder = realm.nextOrder + 1
            realm.characters[characterName] = stored
        end
        stored.name = characterName
        stored.classFile = currentCharacter.classFile
        stored.specIndex = currentCharacter.specIndex
        stored.itemLevel = currentCharacter.itemLevel
        stored.lastRecordedAt = capturedAt
        stored.instances = instances
    end

    if nextResetAt then
        GetDataStore().nextResetAt = nextResetAt
    end

    if updateOverviewFrame then
        updateOverviewFrame()
    elseif updateHoverFrame then
        updateHoverFrame()
    end
    if BG.RefreshRaidLockoutCharacterOptions then
        BG.RefreshRaidLockoutCharacterOptions()
    end
end

local function RequestCurrentRaidInfo()
    ClearExpiredRaidData()
    if currentCharacter.refreshing then
        return
    end

    currentCharacter.refreshing = true
    currentCharacter.requestSerial = currentCharacter.requestSerial + 1
    currentCharacter.lastRequestAt = GetTime()
    local requestSerial = currentCharacter.requestSerial

    if updateOverviewFrame then
        updateOverviewFrame()
    elseif updateHoverFrame then
        updateHoverFrame()
    end

    RequestRaidInfo()

    -- 极少数情况下事件可能丢失；超时后直接读取游戏当前缓存，避免界面一直转圈。
    BG.After(2, function()
        if currentCharacter.refreshing and currentCharacter.requestSerial == requestSerial then
            CaptureRaidInfo()
        end
    end)
end

local function ShowLockoutTooltip(cell)
    local character = cell.character
    local lockouts = character.instances[cell.raid.id]

    GameTooltip:SetOwner(cell, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(cell.raid.name .. "（" .. character.name .. "）", 0, 0.75, 1)

    if not character.ready then
        GameTooltip:AddLine(L["尚未收到当前角色的团本锁定数据。"], 0.7, 0.7, 0.7, true)
    elseif not lockouts then
        GameTooltip:AddLine(L["未检测到团本锁定"], 0.55, 0.55, 0.55)
    else
        for lockoutIndex, lockout in ipairs(lockouts) do
            if lockoutIndex > 1 then
                GameTooltip:AddLine(" ")
            end

            GameTooltip:AddLine(lockout.difficultyName, 1, 0.82, 0)
            GameTooltip:AddDoubleLine(
                L["已击杀"],
                format("%d/%d", lockout.killedCount, lockout.numEncounters),
                1, 1, 1, 1, 1, 1
            )
            if lockout.resetAt and lockout.resetAt > GetServerTime() then
                local remaining = max(0, lockout.resetAt - GetServerTime())
                GameTooltip:AddDoubleLine(
                    L["重置时间"],
                    FormatResetTime(remaining),
                    1, 1, 1, 1, 1, 1
                )
            end

            for _, boss in ipairs(lockout.bosses or {}) do
                GameTooltip:AddDoubleLine(
                    boss.name,
                    boss.killed and BOSS_DEAD or BOSS_ALIVE,
                    0.9, 0.9, 0.9,
                    boss.killed and 0.2 or 0.7,
                    boss.killed and 1 or 0.7,
                    boss.killed and 0.2 or 0.7
                )
            end
        end
    end

    GameTooltip:Show()
end

local function CreateOverviewFrame()
    if overviewFrame then
        return
    end

    local cellWidth = 76
    local nameWidth = 126
    local rowHeight = 34
    local width = 42 + nameWidth + cellWidth * #RAIDS
    local headers = {}
    local rows = {}

    overviewFrame = CreateFrame("Frame", "BGForgeRaidLockoutOverviewFrame", UIParent, "BackdropTemplate")
    overviewFrame:SetSize(width, 180)
    overviewFrame:SetPoint("CENTER")
    overviewFrame:SetFrameStrata("DIALOG")
    overviewFrame:SetClampedToScreen(true)
    overviewFrame:SetMovable(true)
    overviewFrame:EnableMouse(true)
    overviewFrame:RegisterForDrag("LeftButton")
    overviewFrame:SetScript("OnDragStart", overviewFrame.StartMoving)
    overviewFrame:SetScript("OnDragStop", overviewFrame.StopMovingOrSizing)
    overviewFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    overviewFrame:SetBackdropColor(0.025, 0.025, 0.035, 0.96)
    overviewFrame:SetBackdropBorderColor(0, 0.75, 1, 0.9)
    overviewFrame:Hide()
    tinsert(UISpecialFrames, overviewFrame:GetName())

    BG.CreateCloseButton(overviewFrame, 3, 3)

    local settings = CreateFrame("Button", nil, overviewFrame, "UIPanelButtonTemplate")
    settings:SetSize(64, 22)
    settings:SetPoint("TOPRIGHT", -31, -7)
    settings:SetText(L["设置"])
    settings:SetScript("OnClick", function()
        overviewFrame:Hide()
        if BG.OpenRaidLockoutOptions then
            BG.OpenRaidLockoutOptions()
        end
    end)

    local title = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText(L["所有角色团本锁定总览"])
    title:SetTextColor(0, 0.75, 1)

    local subtitle = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    subtitle:SetText(L["汇总当前服务器下已在本机记录的角色本周团本进度"])
    subtitle:SetTextColor(0.55, 0.75, 0.8)

    local refresh = CreateFrame("Button", nil, overviewFrame, "UIPanelButtonTemplate")
    refresh:SetSize(64, 22)
    refresh:SetPoint("BOTTOMRIGHT", -14, 12)
    refresh:SetText(REFRESH)
    refresh:SetScript("OnClick", RequestCurrentRaidInfo)

    local startX = 20 + nameWidth
    local characterHeader = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    characterHeader:SetPoint("TOPLEFT", 20, -66)
    characterHeader:SetWidth(nameWidth)
    characterHeader:SetJustifyH("LEFT")
    characterHeader:SetTextColor(0, 0.75, 1)

    for raidIndex, raid in ipairs(RAIDS) do
        local header = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetPoint("TOPLEFT", startX + (raidIndex - 1) * cellWidth, -66)
        header:SetWidth(cellWidth)
        header:SetJustifyH("CENTER")
        header:SetText(raid.name)
        header:SetTextColor(0, 0.75, 1)
        headers[raid.id] = header
    end

    local statusText = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("RIGHT", refresh, "LEFT", -8, 0)
    statusText:SetWidth(260)
    statusText:SetJustifyH("RIGHT")

    local function EnsureRow(rowIndex)
        if rows[rowIndex] then
            return rows[rowIndex]
        end

        local row = CreateFrame("Frame", nil, overviewFrame)
        row:SetSize(width - 40, rowHeight)
        row:SetPoint("TOPLEFT", 20, -89 - (rowIndex - 1) * rowHeight)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0, 0.55, 1, 0.18)
        highlight:Hide()
        row.highlight = highlight

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        name:SetPoint("LEFT")
        name:SetSize(nameWidth, rowHeight)
        name:SetJustifyH("LEFT")
        row.name = name
        row.cells = {}

        for _, raid in ipairs(RAIDS) do
            local cell = CreateStatusDisplay(row, cellWidth, rowHeight)
            cell:SetPoint("LEFT", nameWidth, 0)
            cell:EnableMouse(true)
            cell.raid = raid
            cell:SetScript("OnEnter", ShowLockoutTooltip)
            cell:SetScript("OnLeave", GameTooltip_Hide)
            row.cells[raid.id] = cell
        end

        rows[rowIndex] = row
        return row
    end

    updateOverviewFrame = function()
        local characters = GetCharacterRows()
        local visibleRaids = GetVisibleRaids()
        local rowCount = max(1, #characters)
        width = max(560, 42 + nameWidth + cellWidth * #visibleRaids)
        overviewFrame:SetWidth(width)
        characterHeader:SetFormattedText(L["角色列表（%d）"], #characters)

        for _, header in pairs(headers) do
            header:Hide()
        end
        for raidIndex, raid in ipairs(visibleRaids) do
            local header = headers[raid.id]
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", startX + (raidIndex - 1) * cellWidth, -66)
            header:Show()
        end

        for rowIndex, character in ipairs(characters) do
            local row = EnsureRow(rowIndex)
            row:Show()
            row:SetWidth(width - 40)
            row.name:SetText(GetCharacterDisplayName(character))
            row.highlight:SetShown(character.isCurrent)

            for _, cell in pairs(row.cells) do
                cell:Hide()
            end
            for raidIndex, raid in ipairs(visibleRaids) do
                local cell = row.cells[raid.id]
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", nameWidth + (raidIndex - 1) * cellWidth, 0)
                cell.character = character
                UpdateStatusDisplay(cell, character, GetPrimaryLockout(character.instances[raid.id]), false)
                cell:Show()
            end
        end

        for rowIndex = #characters + 1, #rows do
            rows[rowIndex]:Hide()
        end

        overviewFrame:SetHeight(132 + rowCount * rowHeight)

        if currentCharacter.refreshing then
            statusText:SetText(L["正在刷新当前角色的团本锁定…"])
        elseif currentCharacter.updatedAt then
            statusText:SetFormattedText(L["刷新时间：%s"], currentCharacter.updatedAt)
        else
            statusText:SetText(L["尚未收到当前角色的团本锁定数据。"])
        end

        if updateHoverFrame then
            updateHoverFrame()
        end
    end

    overviewFrame:SetScript("OnShow", RequestCurrentRaidInfo)
    updateOverviewFrame()
end

local function CreateHoverFrame()
    if hoverFrame then
        return
    end

    local nameWidth = 130
    local rowHeight = 24
    local raidsWidth = 0
    for _, raid in ipairs(RAIDS) do
        raidsWidth = raidsWidth + raid.compactWidth
    end
    local width = 30 + nameWidth + raidsWidth
    local headers = {}
    local rows = {}

    hoverFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    hoverFrame:SetSize(width, 98)
    hoverFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    hoverFrame:SetClampedToScreen(true)
    hoverFrame:EnableMouse(false)
    hoverFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    hoverFrame:SetBackdropColor(0.02, 0.02, 0.03, 0.94)
    hoverFrame:SetBackdropBorderColor(0, 0.75, 1, 0.9)
    hoverFrame:Hide()

    local title = hoverFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", 15, -11)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
    title:SetText(L["< 角色团本CD总览 >"])
    title:SetTextColor(0.2, 1, 0.2)

    local resetText = hoverFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    resetText:SetPoint("LEFT", title, "RIGHT", 6, 0)
    resetText:SetJustifyH("LEFT")
    resetText:SetWordWrap(false)
    resetText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    resetText:SetTextColor(0.72, 0.72, 0.72)

    local characterCount = hoverFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    characterCount:SetPoint("TOPLEFT", 15, -39)
    characterCount:SetWidth(nameWidth)
    characterCount:SetJustifyH("LEFT")
    characterCount:SetWordWrap(false)
    characterCount:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    characterCount:SetTextColor(0, 0.75, 1)

    local raidOffsetX = 15 + nameWidth
    for _, raid in ipairs(RAIDS) do
        local header = hoverFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetPoint("TOPLEFT", raidOffsetX, -39)
        header:SetWidth(raid.compactWidth)
        header:SetJustifyH("CENTER")
        header:SetWordWrap(false)
        header:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
        header:SetText(raid.name)
        header:SetTextColor(0, 0.75, 1)
        headers[raid.id] = header
        raidOffsetX = raidOffsetX + raid.compactWidth
    end

    local function EnsureRow(rowIndex)
        if rows[rowIndex] then
            return rows[rowIndex]
        end

        local row = CreateFrame("Frame", nil, hoverFrame)
        row:SetSize(width - 30, rowHeight)
        row:SetPoint("TOPLEFT", 15, -61 - (rowIndex - 1) * rowHeight)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0, 0.55, 1, 0.18)
        highlight:Hide()
        row.highlight = highlight

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        name:SetPoint("LEFT")
        name:SetSize(nameWidth, rowHeight)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        name:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
        row.name = name
        row.cells = {}

        local cellOffsetX = nameWidth
        for _, raid in ipairs(RAIDS) do
            local cell = CreateStatusDisplay(row, raid.compactWidth, rowHeight, 16, 12)
            cell:SetPoint("LEFT", cellOffsetX, 0)
            row.cells[raid.id] = cell
            cellOffsetX = cellOffsetX + raid.compactWidth
        end

        rows[rowIndex] = row
        return row
    end

    updateHoverFrame = function()
        local characters = GetCharacterRows()
        local visibleRaids = GetVisibleRaids()
        local rowCount = max(1, #characters)
        raidsWidth = 0
        for _, raid in ipairs(visibleRaids) do
            raidsWidth = raidsWidth + raid.compactWidth
        end
        width = max(420, 30 + nameWidth + raidsWidth)
        hoverFrame:SetWidth(width)
        characterCount:SetFormattedText(L["角色列表（%d）"], #characters)

        for _, header in pairs(headers) do
            header:Hide()
        end
        raidOffsetX = 15 + nameWidth
        for _, raid in ipairs(visibleRaids) do
            local header = headers[raid.id]
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", raidOffsetX, -39)
            header:Show()
            raidOffsetX = raidOffsetX + raid.compactWidth
        end

        local resetTime = GetRaidResetTime()
        if resetTime then
            resetText:SetFormattedText(L["（团本重置时间：%s）"], FormatResetTime(resetTime))
        else
            resetText:SetText("")
        end

        for rowIndex, character in ipairs(characters) do
            local row = EnsureRow(rowIndex)
            row:Show()
            row:SetWidth(width - 30)
            row.name:SetText(GetCharacterDisplayName(character))
            row.highlight:SetShown(character.isCurrent)

            for _, cell in pairs(row.cells) do
                cell:Hide()
            end
            local cellOffsetX = nameWidth
            for _, raid in ipairs(visibleRaids) do
                local cell = row.cells[raid.id]
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", cellOffsetX, 0)
                UpdateStatusDisplay(
                    cell,
                    character,
                    GetPrimaryLockout(character.instances[raid.id]),
                    true
                )
                cell:Show()
                cellOffsetX = cellOffsetX + raid.compactWidth
            end
        end

        for rowIndex = #characters + 1, #rows do
            rows[rowIndex]:Hide()
        end

        hoverFrame:SetHeight(74 + rowCount * rowHeight)
    end

    updateHoverFrame()
end

local function PositionHoverFrame(anchor)
    hoverFrame:ClearAllPoints()

    if BG.ButtonIsInRight(anchor) then
        if BG.ButtonIsInTop(anchor) then
            hoverFrame:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, 0)
        else
            hoverFrame:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", 0, 0)
        end
    elseif BG.ButtonIsInTop(anchor) then
        hoverFrame:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, 0)
    else
        hoverFrame:SetPoint("BOTTOMLEFT", anchor, "TOPRIGHT", 0, 0)
    end
end

function BG.ShowRaidLockoutHover(anchor)
    if not anchor then
        return
    end

    CreateHoverFrame()
    PositionHoverFrame(anchor)
    updateHoverFrame()
    hoverFrame:Show()

    if not currentCharacter.ready
        or not currentCharacter.lastRequestAt
        or GetTime() - currentCharacter.lastRequestAt > 15
    then
        RequestCurrentRaidInfo()
    end
end

function BG.HideRaidLockoutHover()
    if hoverFrame then
        hoverFrame:Hide()
    end
end

function BG.GetRaidLockoutDisplayChoices()
    local choices = {}
    for _, raid in ipairs(RAIDS) do
        choices[#choices + 1] = {
            id = raid.id,
            name = raid.name,
            optionKey = GetRaidOptionKey(raid.id),
        }
    end
    return choices
end

function BG.GetRaidLockoutStoredCharacters(realmID)
    return BuildCharacterRows(realmID or GetCurrentRealmID())
end

function BG.DeleteRaidLockoutCharacter(realmID, characterName)
    realmID = realmID or GetCurrentRealmID()
    local realm = GetRealmStore(realmID, false)
    if not realm or not realm.characters[characterName] then
        return false
    end

    realm.characters[characterName] = nil
    if realmID == GetCurrentRealmID() and characterName == GetCurrentCharacterName() then
        deletedThisSession[GetCharacterKey(realmID, characterName)] = true
        currentCharacter.instances = {}
        currentCharacter.ready = true
    end

    BG.RefreshRaidLockoutDisplays()
    if BG.RefreshRaidLockoutCharacterOptions then
        BG.RefreshRaidLockoutCharacterOptions()
    end
    return true
end

function BG.RefreshRaidLockoutDisplays()
    if updateOverviewFrame then
        updateOverviewFrame()
    elseif updateHoverFrame then
        updateHoverFrame()
    end
end

function BG.RoleOverviewUI()
    CreateOverviewFrame()
end

function BG.ToggleRaidLockoutOverview()
    CreateOverviewFrame()
    BG.HideRaidLockoutHover()
    overviewFrame:SetShown(not overviewFrame:IsShown())
end

function BG.CreateRaidLockoutMainMenuButton(anchor)
    if BG.ButtonRaidLockout or not anchor then
        return
    end

    local button = CreateFrame("Button", nil, BG.MainFrame)
    button:SetPoint("LEFT", anchor, "RIGHT", BG.TopLeftButtonJianGe, 0)
    button:SetNormalFontObject(BG.FontGreen15)
    button:SetDisabledFontObject(BG.FontDis15)
    button:SetHighlightFontObject(BG.FontWhite15)
    button:SetText(L["查看团本CD"])
    button:SetSize(button:GetFontString():GetWidth(), 20)
    BG.SetTextHighlightTexture(button)
    button:SetScript("OnClick", function()
        BG.ToggleRaidLockoutOverview()
        BG.PlaySound(1)
    end)
    BG.ButtonRaidLockout = button
end

BG.RegisterEvent("UPDATE_INSTANCE_INFO", CaptureRaidInfo)

BG.RegisterEvent("ENCOUNTER_END", function(_, _, _, _, _, _, success)
    if success == 1 then
        BG.After(0.5, RequestCurrentRaidInfo)
    end
end)

BG.Init2(function()
    SlashCmdList["BGFORGERAIDLOCKOUT"] = BG.ToggleRaidLockoutOverview
    SLASH_BGFORGERAIDLOCKOUT1 = "/bgr"
    SLASH_BGFORGERAIDLOCKOUT2 = "/bgraid"

    ClearExpiredRaidData()
    RequestCurrentRaidInfo()
end)

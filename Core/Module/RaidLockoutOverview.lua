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
local TITAN_EMBER_CURRENCY_ID = 3403
local TITAN_SHARD_CURRENCY_ID = 3406

local SMALL_UI = {
    padding = 10,
    topBarHeight = 36,
    nameWidth = 184,
    rowHeight = 24,
    raidHeaderHeight = 30,
    sectionGap = 8,
    resourceGroupHeight = 22,
    resourceSubHeaderHeight = 22,
    goldWidth = 100,
    emberWidth = 100,
    shardWidth = 100,
    footerHeight = 30,
}

local currencyIconCache = {}

local function GetCoinIconFile()
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinIcon then
        local iconFileID = C_CurrencyInfo.GetCoinIcon(10000)
        if iconFileID then
            return iconFileID
        end
    end
    return "Interface\\MoneyFrame\\UI-GoldIcon"
end

local function GetCurrencyIconFile(currencyID, fallback)
    if currencyIconCache[currencyID] then
        return currencyIconCache[currencyID]
    end
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if info and info.iconFileID then
            currencyIconCache[currencyID] = info.iconFileID
            return info.iconFileID
        end
    end
    return fallback
end

local function FormatResourceNumber(amount)
    if amount == nil then
        return ""
    end
    return tostring(BG.FormatNumber(amount, 0))
end

local function GetResourceIconMarkup(iconFile)
    if not iconFile then
        return ""
    end
    return " |T" .. iconFile .. ":13:13:0:0:64:64:4:60:4:60|t"
end

local function FormatResourceAmount(amount, iconFile)
    return FormatResourceNumber(amount) .. GetResourceIconMarkup(iconFile)
end

local COLOR = {
    panel = { 0.015, 0.055, 0.075, 0.98 },
    panelTop = { 0.02, 0.075, 0.095, 0.98 },
    header = { 0.025, 0.105, 0.13, 0.98 },
    headerStrong = { 0.035, 0.13, 0.155, 0.98 },
    rowOdd = { 0.018, 0.07, 0.09, 0.9 },
    rowEven = { 0.025, 0.095, 0.115, 0.9 },
    current = { 0.24, 0.18, 0.05, 0.7 },
    gold = { 0.84, 0.55, 0.18, 0.95 },
    goldDim = { 0.42, 0.29, 0.13, 0.82 },
    grid = { 0.34, 0.25, 0.15, 0.72 },
    complete = { 0.1, 0.31, 0.14, 0.62 },
    partial = { 0.36, 0.19, 0.035, 0.48 },
}

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
local hoverAnchor
local hoverHideSerial = 0
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

local function GetOrCreateCurrentCharacterStore()
    RefreshCurrentCharacterIdentity()

    local realmID = GetCurrentRealmID()
    local characterName = currentCharacter.name
    if deletedThisSession[GetCharacterKey(realmID, characterName)] then
        return
    end

    local realm = GetRealmStore(realmID, true)
    local stored = realm.characters[characterName]
    if type(stored) ~= "table" then
        stored = {
            name = characterName,
            order = realm.nextOrder,
            instances = {},
        }
        realm.nextOrder = realm.nextOrder + 1
        realm.characters[characterName] = stored
    end

    stored.name = characterName
    stored.classFile = currentCharacter.classFile
    stored.specIndex = currentCharacter.specIndex
    stored.itemLevel = currentCharacter.itemLevel
    stored.instances = type(stored.instances) == "table" and stored.instances or {}
    return stored
end

local function CaptureCurrentResources()
    local stored = GetOrCreateCurrentCharacterStore()
    if not stored then
        return
    end

    stored.money = GetMoney and GetMoney() or stored.money
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(TITAN_EMBER_CURRENCY_ID)
        -- 登录早期可能暂时拿不到货币资料；此时保留旧快照，不能用 0 覆盖。
        if info then
            stored.titanEmbers = info.quantity
            stored.titanEmbersEarnedThisWeek = info.quantityEarnedThisWeek
            stored.titanEmbersWeeklyMax = info.maxWeeklyQuantity
            stored.titanEmberIconFileID = info.iconFileID
            currencyIconCache[TITAN_EMBER_CURRENCY_ID] = info.iconFileID
        end

        info = C_CurrencyInfo.GetCurrencyInfo(TITAN_SHARD_CURRENCY_ID)
        if info then
            stored.titanShards = info.quantity
            stored.titanShardIconFileID = info.iconFileID
            currencyIconCache[TITAN_SHARD_CURRENCY_ID] = info.iconFileID
        end
    end
    stored.resourcesUpdatedAt = GetServerTime()

    if updateHoverFrame then
        updateHoverFrame()
    end
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
                    money = tonumber(stored.money),
                    titanEmbers = tonumber(stored.titanEmbers),
                    titanEmbersEarnedThisWeek = tonumber(stored.titanEmbersEarnedThisWeek),
                    titanEmbersWeeklyMax = tonumber(stored.titanEmbersWeeklyMax),
                    titanEmberIconFileID = stored.titanEmberIconFileID,
                    titanShards = tonumber(stored.titanShards),
                    titanShardIconFileID = stored.titanShardIconFileID,
                    resourcesUpdatedAt = tonumber(stored.resourcesUpdatedAt),
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

local function UpdateStatusDisplay(status, character, lockout, compact, blankWhenAvailable)
    status.check:Hide()

    if status.background then
        if status.baseColor then
            status.background:SetColorTexture(unpack(status.baseColor))
        else
            status.background:SetColorTexture(0, 0, 0, 0)
        end
    end

    if not character.ready then
        status.text:SetText("…")
        status.text:SetTextColor(0.55, 0.55, 0.55)
    elseif not lockout then
        status.text:SetText(blankWhenAvailable and "" or "—")
        status.text:SetTextColor(0.38, 0.38, 0.38)
    elseif compact then
        status.text:SetText("")
        if (lockout.killedCount or 0) > 0 then
            status.check:Show()
            if status.background then
                status.background:SetColorTexture(unpack(COLOR.complete))
            end
        end
    elseif lockout.numEncounters == 0 or lockout.killedCount >= lockout.numEncounters then
        status.text:SetText("")
        status.check:Show()
        if status.background then
            status.background:SetColorTexture(unpack(COLOR.complete))
        end
    else
        status.text:SetFormattedText("%d/%d", lockout.killedCount, lockout.numEncounters)
        if status.background then
            status.text:SetTextColor(1, 0.68, 0.18)
            status.background:SetColorTexture(unpack(COLOR.partial))
        else
            -- 大界面沿用原有颜色；本轮只重构小界面。
            status.text:SetTextColor(1, 0.82, 0)
        end
    end
end

local function CreateStatusDisplay(parent, width, height, checkSize, fontSize, styled)
    local status = CreateFrame("Frame", nil, parent, styled and "BackdropTemplate" or nil)
    status:SetSize(width, height)

    if styled then
        local background = status:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(0, 0, 0, 0)
        status.background = background

        local rightBorder = status:CreateTexture(nil, "BORDER")
        rightBorder:SetPoint("TOPRIGHT")
        rightBorder:SetPoint("BOTTOMRIGHT")
        rightBorder:SetWidth(1)
        rightBorder:SetColorTexture(unpack(COLOR.grid))

        local bottomBorder = status:CreateTexture(nil, "BORDER")
        bottomBorder:SetPoint("BOTTOMLEFT")
        bottomBorder:SetPoint("BOTTOMRIGHT")
        bottomBorder:SetHeight(1)
        bottomBorder:SetColorTexture(unpack(COLOR.grid))
    end

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

    local stored = GetOrCreateCurrentCharacterStore()
    if stored then
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

    local ui = SMALL_UI
    local headers = {}
    local rows = {}
    local width = 720
    local resourceTop = 0
    local resourceRowsTop = 0

    local function CreateTableCell(parent, backgroundColor, borders)
        local cell = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        cell:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
        })
        cell:SetBackdropColor(unpack(backgroundColor or COLOR.rowOdd))

        borders = borders or {}
        local function AddVerticalBorder(point)
            local line = cell:CreateTexture(nil, "BORDER")
            line:SetPoint("TOP" .. point)
            line:SetPoint("BOTTOM" .. point)
            line:SetWidth(1)
            line:SetColorTexture(unpack(COLOR.grid))
        end
        local function AddHorizontalBorder(point)
            local line = cell:CreateTexture(nil, "BORDER")
            line:SetPoint(point .. "LEFT")
            line:SetPoint(point .. "RIGHT")
            line:SetHeight(1)
            line:SetColorTexture(unpack(COLOR.grid))
        end

        if borders.left then
            AddVerticalBorder("LEFT")
        end
        if borders.top then
            AddHorizontalBorder("TOP")
        end
        if borders.right ~= false then
            AddVerticalBorder("RIGHT")
        end
        if borders.bottom ~= false then
            AddHorizontalBorder("BOTTOM")
        end
        return cell
    end

    local function CreateCellText(cell, fontObject, size, color, justify)
        local text = cell:CreateFontString(nil, "ARTWORK", fontObject or "GameFontNormal")
        text:SetPoint("LEFT", 7, 0)
        text:SetPoint("RIGHT", -7, 0)
        text:SetJustifyH(justify or "LEFT")
        text:SetWordWrap(false)
        if size then
            text:SetFont(BIAOGE_TEXT_FONT, size, "OUTLINE")
        end
        if color then
            text:SetTextColor(unpack(color))
        end
        return text
    end

    local function SetCellColor(cell, color)
        cell:SetBackdropColor(unpack(color))
    end

    local function ShowButtonTooltip(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(button.tooltipText, 1, 0.82, 0)
        GameTooltip:Show()
    end

    local function CreateIconButton(texture, tooltipText)
        local button = CreateFrame("Button", nil, hoverFrame, "BackdropTemplate")
        button:SetSize(23, 23)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.04, 0.09, 0.1, 0.96)
        button:SetBackdropBorderColor(unpack(COLOR.goldDim))

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexture(texture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetVertexColor(0.95, 0.67, 0.28)
        button.icon = icon

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetPoint("TOPLEFT", 2, -2)
        highlight:SetPoint("BOTTOMRIGHT", -2, 2)
        highlight:SetColorTexture(1, 0.72, 0.25, 0.18)
        button.tooltipText = tooltipText
        button:SetScript("OnEnter", ShowButtonTooltip)
        button:SetScript("OnLeave", GameTooltip_Hide)
        return button
    end

    hoverFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    hoverFrame:SetSize(width, 540)
    hoverFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    hoverFrame:SetClampedToScreen(true)
    hoverFrame:EnableMouse(true)
    hoverFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    hoverFrame:SetBackdropColor(unpack(COLOR.panel))
    hoverFrame:Hide()

    local innerBorder = CreateFrame("Frame", nil, hoverFrame, "BackdropTemplate")
    innerBorder:SetPoint("TOPLEFT", 6, -6)
    innerBorder:SetPoint("BOTTOMRIGHT", -6, 6)
    innerBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    innerBorder:SetBackdropBorderColor(0.3, 0.22, 0.12, 0.82)

    local topBar = CreateTableCell(hoverFrame, COLOR.panelTop, { left = true, top = true })
    topBar:SetPoint("TOPLEFT", ui.padding, -ui.padding)
    topBar:SetSize(width - ui.padding * 2, ui.topBarHeight)

    local logo = topBar:CreateTexture(nil, "ARTWORK")
    logo:SetSize(22, 22)
    logo:SetPoint("LEFT", 8, 0)
    logo:SetTexture("Interface\\AddOns\\BGForge\\Media\\icon\\icon.tga")

    local title = topBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 7, 0)
    title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    title:SetText(L["BGForge · 全角色总览"])
    title:SetTextColor(unpack(COLOR.gold))

    local close = CreateIconButton("Interface\\Buttons\\UI-Panel-MinimizeButton-Up", L["关闭"])
    close:SetPoint("TOPRIGHT", -ui.padding - 6, -ui.padding - 6)
    close:SetScript("OnClick", function()
        hoverFrame:Hide()
        GameTooltip:Hide()
    end)

    local settings = CreateIconButton("Interface\\Icons\\Trade_Engineering", L["设置"])
    settings:SetPoint("RIGHT", close, "LEFT", -5, 0)
    settings:SetScript("OnClick", function()
        hoverFrame:Hide()
        GameTooltip:Hide()
        if BG.OpenRaidLockoutOptions then
            BG.OpenRaidLockoutOptions()
        end
    end)

    local refresh = CreateIconButton("Interface\\Buttons\\UI-RotationRight-Button-Up", REFRESH)
    refresh:SetPoint("RIGHT", settings, "LEFT", -5, 0)
    refresh.icon:SetTexCoord(0, 1, 0, 1)
    refresh:SetScript("OnClick", function()
        CaptureCurrentResources()
        RequestCurrentRaidInfo()
        BG.PlaySound(1)
    end)

    local resetText = topBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    resetText:SetPoint("RIGHT", refresh, "LEFT", -10, 0)
    resetText:SetWidth(245)
    resetText:SetJustifyH("RIGHT")
    resetText:SetWordWrap(false)
    resetText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    resetText:SetTextColor(0.72, 0.66, 0.55)

    local raidTitleCell = CreateTableCell(hoverFrame, COLOR.headerStrong, { left = true })
    raidTitleCell:SetPoint("TOPLEFT", ui.padding, -(ui.padding + ui.topBarHeight))
    raidTitleCell:SetSize(ui.nameWidth, ui.raidHeaderHeight)
    local raidTitleAccent = raidTitleCell:CreateTexture(nil, "ARTWORK")
    raidTitleAccent:SetPoint("TOPLEFT", 5, -5)
    raidTitleAccent:SetPoint("BOTTOMLEFT", 5, 5)
    raidTitleAccent:SetWidth(3)
    raidTitleAccent:SetColorTexture(unpack(COLOR.gold))
    local raidTitle = CreateCellText(raidTitleCell, "GameFontNormal", 13, COLOR.gold, "LEFT")
    raidTitle:ClearAllPoints()
    raidTitle:SetPoint("LEFT", 14, 0)
    raidTitle:SetPoint("RIGHT", -7, 0)

    for _, raid in ipairs(RAIDS) do
        local header = CreateTableCell(hoverFrame, COLOR.header)
        header:SetSize(raid.compactWidth, ui.raidHeaderHeight)
        local text = CreateCellText(header, "GameFontNormal", 12, COLOR.gold, "CENTER")
        text:SetText(raid.name)
        headers[raid.id] = header
    end

    local resourceTitleCell = CreateTableCell(hoverFrame, COLOR.headerStrong, { left = true, top = true })
    resourceTitleCell:SetSize(ui.nameWidth, ui.resourceGroupHeight + ui.resourceSubHeaderHeight)
    local resourceAccent = resourceTitleCell:CreateTexture(nil, "ARTWORK")
    resourceAccent:SetPoint("TOPLEFT", 5, -5)
    resourceAccent:SetPoint("BOTTOMLEFT", 5, 5)
    resourceAccent:SetWidth(3)
    resourceAccent:SetColorTexture(unpack(COLOR.gold))
    local resourceTitle = CreateCellText(resourceTitleCell, "GameFontNormal", 13, COLOR.gold, "LEFT")
    resourceTitle:ClearAllPoints()
    resourceTitle:SetPoint("LEFT", 14, 0)
    resourceTitle:SetPoint("RIGHT", -7, 0)

    local commonHeader = CreateTableCell(hoverFrame, COLOR.headerStrong, { top = true })
    commonHeader:SetSize(ui.goldWidth + ui.emberWidth + ui.shardWidth, ui.resourceGroupHeight)
    local commonHeaderText = CreateCellText(commonHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    commonHeaderText:SetText(L["通用资源"])

    local goldHeader = CreateTableCell(hoverFrame, COLOR.header)
    goldHeader:SetSize(ui.goldWidth, ui.resourceSubHeaderHeight)
    local goldHeaderText = CreateCellText(goldHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    goldHeaderText:SetText(L["金币"])

    local emberHeader = CreateTableCell(hoverFrame, COLOR.header)
    emberHeader:SetSize(ui.emberWidth, ui.resourceSubHeaderHeight)
    local emberHeaderText = CreateCellText(emberHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    emberHeaderText:SetText(L["泰坦余烬"])

    local shardHeader = CreateTableCell(hoverFrame, COLOR.header)
    shardHeader:SetSize(ui.shardWidth, ui.resourceSubHeaderHeight)
    local shardHeaderText = CreateCellText(shardHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    shardHeaderText:SetText(L["泰坦碎片"])

    local legendaryHeader = CreateTableCell(hoverFrame, COLOR.headerStrong, { top = true })
    local legendaryHeaderText = CreateCellText(legendaryHeader, "GameFontNormal", 12, COLOR.gold, "CENTER")
    legendaryHeaderText:SetText(L["橙装进度"])

    local footerText = hoverFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footerText:SetJustifyH("LEFT")
    footerText:SetWordWrap(false)
    footerText:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    footerText:SetTextColor(0.58, 0.52, 0.43)

    local function ShowResourceTooltip(cell)
        local character = cell.character
        if not character then
            return
        end
        GameTooltip:SetOwner(cell, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(cell.resourceName .. "（" .. character.name .. "）", 1, 0.82, 0)
        if cell.resourceType == "ember" and character.titanEmbersWeeklyMax
            and character.titanEmbersWeeklyMax > 0 then
            GameTooltip:AddDoubleLine(
                L["本周已获取"],
                format("%d/%d", character.titanEmbersEarnedThisWeek or 0, character.titanEmbersWeeklyMax),
                0.75, 0.75, 0.75, 1, 1, 1
            )
        end
        if character.resourcesUpdatedAt then
            GameTooltip:AddDoubleLine(
                L["最后记录"],
                date("%m-%d %H:%M", character.resourcesUpdatedAt),
                0.75, 0.75, 0.75, 0.75, 0.75, 0.75
            )
        end
        GameTooltip:Show()
    end

    local function EnsureRow(rowIndex)
        if rows[rowIndex] then
            return rows[rowIndex]
        end

        local row = {
            raidCells = {},
        }

        row.raidNameCell = CreateTableCell(hoverFrame, nil, { left = true })
        row.raidNameCell:SetSize(ui.nameWidth, ui.rowHeight)
        row.raidName = CreateCellText(row.raidNameCell, "GameFontHighlightSmall", 12, nil, "LEFT")

        for _, raid in ipairs(RAIDS) do
            local cell = CreateStatusDisplay(hoverFrame, raid.compactWidth, ui.rowHeight, 15, 11, true)
            cell:EnableMouse(true)
            cell.raid = raid
            cell:SetScript("OnEnter", ShowLockoutTooltip)
            cell:SetScript("OnLeave", GameTooltip_Hide)
            row.raidCells[raid.id] = cell
        end

        row.resourceNameCell = CreateTableCell(hoverFrame, nil, { left = true })
        row.resourceNameCell:SetSize(ui.nameWidth, ui.rowHeight)
        row.resourceName = CreateCellText(row.resourceNameCell, "GameFontHighlightSmall", 12, nil, "LEFT")

        row.goldCell = CreateTableCell(hoverFrame)
        row.goldCell:SetSize(ui.goldWidth, ui.rowHeight)
        row.gold = CreateCellText(row.goldCell, "NumberFontNormal", nil, { 0.95, 0.67, 0.29, 1 }, "CENTER")
        row.goldCell.resourceType = "gold"
        row.goldCell.resourceName = L["金币"]
        row.goldCell:EnableMouse(true)
        row.goldCell:SetScript("OnEnter", ShowResourceTooltip)
        row.goldCell:SetScript("OnLeave", GameTooltip_Hide)

        row.emberCell = CreateTableCell(hoverFrame)
        row.emberCell:SetSize(ui.emberWidth, ui.rowHeight)
        row.ember = CreateCellText(row.emberCell, "NumberFontNormal", nil, { 0.95, 0.67, 0.29, 1 }, "CENTER")
        row.emberCell.resourceType = "ember"
        row.emberCell.resourceName = L["泰坦余烬"]
        row.emberCell:EnableMouse(true)
        row.emberCell:SetScript("OnEnter", ShowResourceTooltip)
        row.emberCell:SetScript("OnLeave", GameTooltip_Hide)

        row.shardCell = CreateTableCell(hoverFrame)
        row.shardCell:SetSize(ui.shardWidth, ui.rowHeight)
        row.shard = CreateCellText(row.shardCell, "NumberFontNormal", nil, { 0.95, 0.67, 0.29, 1 }, "CENTER")
        row.shardCell.resourceType = "shard"
        row.shardCell.resourceName = L["泰坦碎片"]
        row.shardCell:EnableMouse(true)
        row.shardCell:SetScript("OnEnter", ShowResourceTooltip)
        row.shardCell:SetScript("OnLeave", GameTooltip_Hide)

        row.legendaryCell = CreateTableCell(hoverFrame)
        row.legendaryCell:SetHeight(ui.rowHeight)

        rows[rowIndex] = row
        return row
    end

    local totalNameCell = CreateTableCell(hoverFrame, COLOR.header, { left = true })
    totalNameCell:SetSize(ui.nameWidth, ui.rowHeight)
    local totalName = CreateCellText(totalNameCell, "GameFontNormal", 12, COLOR.gold, "CENTER")
    totalName:SetText(L["合计"])

    local totalGoldCell = CreateTableCell(hoverFrame, COLOR.header)
    totalGoldCell:SetSize(ui.goldWidth, ui.rowHeight)
    local totalGold = CreateCellText(totalGoldCell, "NumberFontNormal", nil, { 0.95, 0.67, 0.29, 1 }, "CENTER")

    local totalEmberCell = CreateTableCell(hoverFrame, COLOR.header)
    totalEmberCell:SetSize(ui.emberWidth, ui.rowHeight)
    local totalEmber = CreateCellText(totalEmberCell, "NumberFontNormal", nil, { 0.95, 0.67, 0.29, 1 }, "CENTER")

    local totalShardCell = CreateTableCell(hoverFrame, COLOR.header)
    totalShardCell:SetSize(ui.shardWidth, ui.rowHeight)
    local totalShard = CreateCellText(totalShardCell, "NumberFontNormal", nil, { 0.95, 0.67, 0.29, 1 }, "CENTER")

    local totalLegendaryCell = CreateTableCell(hoverFrame, COLOR.header)
    totalLegendaryCell:SetHeight(ui.rowHeight)

    updateHoverFrame = function()
        local characters = GetCharacterRows()
        local visibleRaids = GetVisibleRaids()
        local rowCount = max(1, #characters)
        local raidsWidth = 0
        for _, raid in ipairs(visibleRaids) do
            raidsWidth = raidsWidth + raid.compactWidth
        end

        width = max(660, ui.padding * 2 + ui.nameWidth + raidsWidth)
        hoverFrame:SetWidth(width)
        topBar:SetWidth(width - ui.padding * 2)
        raidTitle:SetFormattedText(L["本周团本 CD · %d个角色"], #characters)
        resourceTitle:SetFormattedText(L["角色资源总览 · %d个角色"], #characters)

        for _, header in pairs(headers) do
            header:Hide()
        end
        local raidOffsetX = ui.padding + ui.nameWidth
        for _, raid in ipairs(visibleRaids) do
            local header = headers[raid.id]
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", raidOffsetX, -(ui.padding + ui.topBarHeight))
            header:Show()
            raidOffsetX = raidOffsetX + raid.compactWidth
        end

        local resetTime = GetRaidResetTime()
        if resetTime then
            resetText:SetFormattedText(L["距重置 %s"], FormatResetTime(resetTime))
        else
            resetText:SetText("")
        end

        goldHeaderText:SetText(L["金币"] .. GetResourceIconMarkup(GetCoinIconFile()))
        emberHeaderText:SetText(L["泰坦余烬"] .. GetResourceIconMarkup(
            GetCurrencyIconFile(TITAN_EMBER_CURRENCY_ID)
        ))
        shardHeaderText:SetText(L["泰坦碎片"] .. GetResourceIconMarkup(
            GetCurrencyIconFile(TITAN_SHARD_CURRENCY_ID)
        ))

        local raidRowsTop = ui.padding + ui.topBarHeight + ui.raidHeaderHeight
        resourceTop = raidRowsTop + rowCount * ui.rowHeight + ui.sectionGap
        resourceRowsTop = resourceTop + ui.resourceGroupHeight + ui.resourceSubHeaderHeight
        local legendaryWidth = width - ui.padding * 2 - ui.nameWidth
            - ui.goldWidth - ui.emberWidth - ui.shardWidth

        resourceTitleCell:ClearAllPoints()
        resourceTitleCell:SetPoint("TOPLEFT", ui.padding, -resourceTop)
        commonHeader:ClearAllPoints()
        commonHeader:SetPoint("TOPLEFT", ui.padding + ui.nameWidth, -resourceTop)
        goldHeader:ClearAllPoints()
        goldHeader:SetPoint("TOPLEFT", ui.padding + ui.nameWidth, -(resourceTop + ui.resourceGroupHeight))
        emberHeader:ClearAllPoints()
        emberHeader:SetPoint("TOPLEFT", ui.padding + ui.nameWidth + ui.goldWidth, -(resourceTop + ui.resourceGroupHeight))
        shardHeader:ClearAllPoints()
        shardHeader:SetPoint(
            "TOPLEFT",
            ui.padding + ui.nameWidth + ui.goldWidth + ui.emberWidth,
            -(resourceTop + ui.resourceGroupHeight)
        )
        legendaryHeader:ClearAllPoints()
        legendaryHeader:SetPoint(
            "TOPLEFT",
            ui.padding + ui.nameWidth + ui.goldWidth + ui.emberWidth + ui.shardWidth,
            -resourceTop
        )
        legendaryHeader:SetSize(legendaryWidth, ui.resourceGroupHeight + ui.resourceSubHeaderHeight)

        local goldTotal = 0
        local emberTotal = 0
        local shardTotal = 0
        local latestResourceRecord
        for rowIndex, character in ipairs(characters) do
            local row = EnsureRow(rowIndex)
            local rowColor = character.isCurrent and COLOR.current
                or (rowIndex % 2 == 0 and COLOR.rowEven or COLOR.rowOdd)
            local rowY = raidRowsTop + (rowIndex - 1) * ui.rowHeight
            local resourceRowY = resourceRowsTop + (rowIndex - 1) * ui.rowHeight

            row.raidNameCell:Show()
            row.raidNameCell:ClearAllPoints()
            row.raidNameCell:SetPoint("TOPLEFT", ui.padding, -rowY)
            SetCellColor(row.raidNameCell, rowColor)
            row.raidName:SetText(GetCharacterDisplayName(character))

            for _, cell in pairs(row.raidCells) do
                cell:Hide()
            end
            local cellOffsetX = ui.padding + ui.nameWidth
            for _, raid in ipairs(visibleRaids) do
                local cell = row.raidCells[raid.id]
                cell:ClearAllPoints()
                cell:SetPoint("TOPLEFT", cellOffsetX, -rowY)
                cell.character = character
                cell.baseColor = rowColor
                UpdateStatusDisplay(
                    cell,
                    character,
                    GetPrimaryLockout(character.instances[raid.id]),
                    true,
                    true
                )
                cell:Show()
                cellOffsetX = cellOffsetX + raid.compactWidth
            end

            row.resourceNameCell:Show()
            row.resourceNameCell:ClearAllPoints()
            row.resourceNameCell:SetPoint("TOPLEFT", ui.padding, -resourceRowY)
            SetCellColor(row.resourceNameCell, rowColor)
            row.resourceName:SetText(GetCharacterDisplayName(character))

            row.goldCell:Show()
            row.goldCell:ClearAllPoints()
            row.goldCell:SetPoint("TOPLEFT", ui.padding + ui.nameWidth, -resourceRowY)
            row.goldCell.character = character
            SetCellColor(row.goldCell, rowColor)
            local gold = character.money and floor(character.money / 10000) or nil
            row.gold:SetText(FormatResourceNumber(gold))

            row.emberCell:Show()
            row.emberCell:ClearAllPoints()
            row.emberCell:SetPoint("TOPLEFT", ui.padding + ui.nameWidth + ui.goldWidth, -resourceRowY)
            row.emberCell.character = character
            SetCellColor(row.emberCell, rowColor)
            row.ember:SetText(FormatResourceNumber(character.titanEmbers))

            row.shardCell:Show()
            row.shardCell:ClearAllPoints()
            row.shardCell:SetPoint(
                "TOPLEFT",
                ui.padding + ui.nameWidth + ui.goldWidth + ui.emberWidth,
                -resourceRowY
            )
            row.shardCell.character = character
            SetCellColor(row.shardCell, rowColor)
            row.shard:SetText(FormatResourceNumber(character.titanShards))

            row.legendaryCell:Show()
            row.legendaryCell:ClearAllPoints()
            row.legendaryCell:SetPoint(
                "TOPLEFT",
                ui.padding + ui.nameWidth + ui.goldWidth + ui.emberWidth + ui.shardWidth,
                -resourceRowY
            )
            row.legendaryCell:SetSize(legendaryWidth, ui.rowHeight)
            SetCellColor(row.legendaryCell, rowColor)

            goldTotal = goldTotal + (gold or 0)
            emberTotal = emberTotal + (character.titanEmbers or 0)
            shardTotal = shardTotal + (character.titanShards or 0)
            if character.resourcesUpdatedAt
                and (not latestResourceRecord or character.resourcesUpdatedAt > latestResourceRecord) then
                latestResourceRecord = character.resourcesUpdatedAt
            end
        end

        for rowIndex = #characters + 1, #rows do
            local row = rows[rowIndex]
            row.raidNameCell:Hide()
            row.resourceNameCell:Hide()
            row.goldCell:Hide()
            row.emberCell:Hide()
            row.shardCell:Hide()
            row.legendaryCell:Hide()
            for _, cell in pairs(row.raidCells) do
                cell:Hide()
            end
        end

        local totalY = resourceRowsTop + rowCount * ui.rowHeight
        totalNameCell:ClearAllPoints()
        totalNameCell:SetPoint("TOPLEFT", ui.padding, -totalY)
        totalGoldCell:ClearAllPoints()
        totalGoldCell:SetPoint("TOPLEFT", ui.padding + ui.nameWidth, -totalY)
        totalEmberCell:ClearAllPoints()
        totalEmberCell:SetPoint("TOPLEFT", ui.padding + ui.nameWidth + ui.goldWidth, -totalY)
        totalShardCell:ClearAllPoints()
        totalShardCell:SetPoint(
            "TOPLEFT",
            ui.padding + ui.nameWidth + ui.goldWidth + ui.emberWidth,
            -totalY
        )
        totalLegendaryCell:ClearAllPoints()
        totalLegendaryCell:SetPoint(
            "TOPLEFT",
            ui.padding + ui.nameWidth + ui.goldWidth + ui.emberWidth + ui.shardWidth,
            -totalY
        )
        totalLegendaryCell:SetSize(legendaryWidth, ui.rowHeight)
        totalGold:SetText(FormatResourceAmount(goldTotal, GetCoinIconFile()))
        totalEmber:SetText(FormatResourceAmount(emberTotal, GetCurrencyIconFile(TITAN_EMBER_CURRENCY_ID)))
        totalShard:SetText(FormatResourceAmount(shardTotal, GetCurrencyIconFile(TITAN_SHARD_CURRENCY_ID)))

        footerText:ClearAllPoints()
        footerText:SetPoint("TOPLEFT", ui.padding + 7, -(totalY + ui.rowHeight + 8))
        if latestResourceRecord then
            footerText:SetFormattedText(L["资源最后记录：%s"], date("%m-%d %H:%M", latestResourceRecord))
        else
            footerText:SetText(L["资源尚未记录"])
        end

        hoverFrame:SetHeight(totalY + ui.rowHeight + ui.footerHeight + ui.padding)
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

local function IsPointerOver(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then
        return false
    end
    if frame.IsMouseOver then
        return frame:IsMouseOver()
    end
    return MouseIsOver and MouseIsOver(frame)
end

local function ScheduleHoverHide()
    hoverHideSerial = hoverHideSerial + 1
    local serial = hoverHideSerial
    BG.After(0.12, function()
        if serial ~= hoverHideSerial then
            return
        end
        if IsPointerOver(hoverAnchor) or IsPointerOver(hoverFrame) then
            return
        end
        if hoverFrame then
            hoverFrame:Hide()
        end
    end)
end

function BG.ShowRaidLockoutHover(anchor)
    if not anchor then
        return
    end

    CreateHoverFrame()
    hoverHideSerial = hoverHideSerial + 1
    hoverAnchor = anchor
    PositionHoverFrame(anchor)
    updateHoverFrame()
    hoverFrame:Show()
    hoverFrame:SetScript("OnEnter", function()
        hoverHideSerial = hoverHideSerial + 1
    end)
    hoverFrame:SetScript("OnLeave", ScheduleHoverHide)
    CaptureCurrentResources()

    if not currentCharacter.ready
        or not currentCharacter.lastRequestAt
        or GetTime() - currentCharacter.lastRequestAt > 15
    then
        RequestCurrentRaidInfo()
    end
end

function BG.HideRaidLockoutHover()
    if hoverFrame then
        ScheduleHoverHide()
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

BG.RegisterEvent({ "CURRENCY_DISPLAY_UPDATE", "PLAYER_MONEY" }, function()
    BG.After(0.2, CaptureCurrentResources)
end)

BG.Init2(function()
    SlashCmdList["BGFORGERAIDLOCKOUT"] = BG.ToggleRaidLockoutOverview
    SLASH_BGFORGERAIDLOCKOUT1 = "/bgr"
    SLASH_BGFORGERAIDLOCKOUT2 = "/bgraid"

    ClearExpiredRaidData()
    BG.After(0.5, CaptureCurrentResources)
    RequestCurrentRaidInfo()
end)

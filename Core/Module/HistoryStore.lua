if BG.IsBlackListPlayer then return end
if not BG.IsTitan then return end
if not BG.HistoryFeatureEnabled then return end
local _, ns = ...

local Maxb = ns.Maxb

local Store = {}
BG.HistoryStore = Store

local DEFAULT_RETENTION_DAYS = 90
local DEFAULT_MAX_RECORDS = 50
local SCHEMA_VERSION = 1
local VALID_RETENTION_DAYS = {
    [0] = true,
    [30] = true,
    [90] = true,
    [180] = true,
}
local VALID_SOURCES = {
    manual = true,
    ["auto-clear"] = true,
}

local function IsSupportedRaid(FB)
    if not BG.IsTitan or not FB then return false end
    for _, value in ipairs(BG.FBtable) do
        if value == FB then
            return true
        end
    end
    return false
end

local function Ensure(FB)
    if not IsSupportedRaid(FB) then return end
    BiaoGe.History = type(BiaoGe.History) == "table" and BiaoGe.History or {}
    BiaoGe.HistoryList = type(BiaoGe.HistoryList) == "table" and BiaoGe.HistoryList or {}
    BiaoGe.History[FB] = type(BiaoGe.History[FB]) == "table" and BiaoGe.History[FB] or {}
    BiaoGe.HistoryList[FB] = type(BiaoGe.HistoryList[FB]) == "table" and BiaoGe.HistoryList[FB] or {}
    return true
end

local function CopyTextValue(value)
    local valueType = type(value)
    if valueType == "string" or valueType == "number" then
        return value
    end
end

local function CopyDebtValue(value)
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        return value
    end
end

local function CopyColor(value)
    if type(value) ~= "table" then return end
    local r, g, b = tonumber(value[1]), tonumber(value[2]), tonumber(value[3])
    if not (r and g and b) then return end
    return {
        max(0, min(1, r)),
        max(0, min(1, g)),
        max(0, min(1, b)),
    }
end

-- This is the sole persistence seam for history rows. It deliberately ignores
-- every field outside the local ledger display: no roster, trade log, auction
-- log, leader profile, GUID, guild, race, faction, or game-flavor metadata.
function Store.Sanitize(FB, source)
    if not IsSupportedRaid(FB) or type(source) ~= "table" then return end

    local snapshot = {}
    local hasData = false
    for b = 1, Maxb[FB] + 2 do
        local sourceBoss = type(source["boss" .. b]) == "table" and source["boss" .. b] or {}
        local boss = {}
        snapshot["boss" .. b] = boss
        for i = 1, BG.GetMaxi(FB, b) do
            for _, field in ipairs({ "zhuangbei", "maijia", "jine" }) do
                local value = CopyTextValue(sourceBoss[field .. i])
                if value ~= nil and value ~= "" then
                    boss[field .. i] = value
                    hasData = true
                end
            end
            local debt = CopyDebtValue(sourceBoss["qiankuan" .. i])
            if debt ~= nil and debt ~= "" then
                boss["qiankuan" .. i] = debt
                hasData = true
            end
            local color = CopyColor(sourceBoss["color" .. i])
            if color then
                boss["color" .. i] = color
            end
        end
    end
    return snapshot, hasData
end

local function Fingerprint(FB, snapshot)
    local hash1, hash2, length = 5381, 52711, 0
    local function Add(value)
        local valueType = type(value)
        local text
        if valueType == "number" then
            text = format("%.6f", value)
        elseif valueType == "nil" then
            text = ""
        else
            text = tostring(value)
        end
        local token = valueType .. ":" .. #text .. ":" .. text .. ";"
        length = length + #token
        for index = 1, #token do
            local byte = string.byte(token, index)
            hash1 = (hash1 * 131 + byte) % 2147483647
            hash2 = (hash2 * 137 + byte) % 2147483629
        end
    end

    for b = 1, Maxb[FB] + 2 do
        local boss = snapshot["boss" .. b] or {}
        for i = 1, BG.GetMaxi(FB, b) do
            for _, field in ipairs({ "zhuangbei", "maijia", "jine", "qiankuan" }) do
                Add(boss[field .. i])
            end
            local color = boss["color" .. i]
            Add(color and color[1])
            Add(color and color[2])
            Add(color and color[3])
        end
    end
    return format("%08x-%08x-%x", hash1, hash2, length)
end

local function SnapshotsEqual(FB, left, right)
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    for b = 1, Maxb[FB] + 2 do
        local leftBoss = left["boss" .. b] or {}
        local rightBoss = right["boss" .. b] or {}
        for i = 1, BG.GetMaxi(FB, b) do
            for _, field in ipairs({ "zhuangbei", "maijia", "jine", "qiankuan" }) do
                if leftBoss[field .. i] ~= rightBoss[field .. i] then return false end
            end
            local leftColor = leftBoss["color" .. i]
            local rightColor = rightBoss["color" .. i]
            for colorIndex = 1, 3 do
                local leftValue = leftColor and leftColor[colorIndex]
                local rightValue = rightColor and rightColor[colorIndex]
                if leftValue ~= rightValue then return false end
            end
        end
    end
    return true
end

local function ResolveRecord(FB, id)
    if not Ensure(FB) then return end
    local history = BiaoGe.History[FB]
    if history[id] then return history[id], id end
    local numberID = tonumber(id)
    if numberID and history[numberID] then return history[numberID], numberID end
    local stringID = tostring(id)
    if history[stringID] then return history[stringID], stringID end
end

local function NewID(FB, serverTime)
    local base = tonumber(date("%y%m%d%H%M%S", serverTime))
    if not base then return end
    base = base * 1000
    for counter = 0, 999 do
        local id = base + counter
        if not ResolveRecord(FB, id) then
            return id
        end
    end
end

local function FindLatestDuplicate(FB, snapshot, fingerprint)
    for _, entry in ipairs(BiaoGe.HistoryList[FB]) do
        local record = type(entry) == "table" and ResolveRecord(FB, entry[1]) or nil
        local meta = record and record._bgforge
        if type(meta) == "table" and tonumber(meta.schema) == SCHEMA_VERSION then
            local sanitized = Store.Sanitize(FB, record)
            local storedFingerprint = meta.fingerprint or Fingerprint(FB, sanitized)
            if storedFingerprint == fingerprint and SnapshotsEqual(FB, sanitized, snapshot) then
                return entry[1]
            end
            return nil
        end
    end
end

function Store.GetList(FB)
    if not Ensure(FB) then return {} end
    return BiaoGe.HistoryList[FB]
end

function Store.Load(FB, id)
    local record = ResolveRecord(FB, id)
    if not record then return end
    return Store.Sanitize(FB, record)
end

function Store.LoadByIndex(FB, index)
    local list = Store.GetList(FB)
    local entry = list[index]
    if type(entry) ~= "table" then return end
    return Store.Load(FB, entry[1]), entry[1], entry
end

function Store.Prune(FB, now)
    if not Ensure(FB) then return 0 end
    local days = tonumber(BiaoGe.options.historyRetentionDays) or DEFAULT_RETENTION_DAYS
    if days <= 0 then return 0 end

    local maxRecords = tonumber(BiaoGe.options.historyMaxRecords) or DEFAULT_MAX_RECORDS
    now = now or GetServerTime()
    local list = BiaoGe.HistoryList[FB]
    local remove = {}
    local bgforgeCount = 0

    for index, entry in ipairs(list) do
        local record = type(entry) == "table" and ResolveRecord(FB, entry[1]) or nil
        local meta = record and record._bgforge
        if type(meta) == "table" and tonumber(meta.schema) == SCHEMA_VERSION then
            bgforgeCount = bgforgeCount + 1
            local savedAt = tonumber(meta.savedAt) or tonumber(entry[3])
            local expired = savedAt and now - savedAt > days * 86400
            if expired or bgforgeCount > maxRecords then
                remove[#remove + 1] = index
            end
        end
    end

    for i = #remove, 1, -1 do
        local index = remove[i]
        local entry = list[index]
        local _, key = ResolveRecord(FB, entry[1])
        if key ~= nil then
            BiaoGe.History[FB][key] = nil
        end
        table.remove(list, index)
    end
    return #remove
end

function Store.Save(FB, source, title, serverTime, options)
    if not Ensure(FB) then return nil, "unsupported" end
    local snapshot, hasData = Store.Sanitize(FB, source)
    if not hasData then return nil, "empty" end

    options = type(options) == "table" and options or {}
    serverTime = tonumber(serverTime) or GetServerTime()
    Store.Prune(FB, serverTime)
    local fingerprint = Fingerprint(FB, snapshot)
    if options.dedupe then
        local duplicateID = FindLatestDuplicate(FB, snapshot, fingerprint)
        if duplicateID then
            return duplicateID, "duplicate"
        end
    end
    local id = NewID(FB, serverTime)
    if not id then return nil, "collision" end

    local sourceName = VALID_SOURCES[options.source] and options.source or nil
    snapshot._bgforge = {
        schema = SCHEMA_VERSION,
        savedAt = serverTime,
        source = sourceName,
        fingerprint = fingerprint,
    }
    BiaoGe.History[FB][id] = snapshot
    table.insert(BiaoGe.HistoryList[FB], 1, {
        id,
        tostring(title or ""),
        serverTime,
        sourceName,
    })
    Store.Prune(FB, serverTime)
    return id, "saved"
end

function Store.Rename(FB, index, title)
    local list = Store.GetList(FB)
    if type(list[index]) ~= "table" then return false end
    title = tostring(title or "")
    if title == "" then return false end
    list[index][2] = title
    return true
end

function Store.Delete(FB, index)
    local list = Store.GetList(FB)
    local entry = list[index]
    if type(entry) ~= "table" then return false end
    local _, key = ResolveRecord(FB, entry[1])
    if key ~= nil then
        BiaoGe.History[FB][key] = nil
    end
    table.remove(list, index)
    return true
end

function Store.Clear(FB)
    if not Ensure(FB) then return false end
    wipe(BiaoGe.History[FB])
    wipe(BiaoGe.HistoryList[FB])
    return true
end

BG.Init(function()
    BiaoGe.options = type(BiaoGe.options) == "table" and BiaoGe.options or {}
    local retentionDays = tonumber(BiaoGe.options.historyRetentionDays)
    BiaoGe.options.historyRetentionDays = VALID_RETENTION_DAYS[retentionDays]
        and retentionDays or DEFAULT_RETENTION_DAYS
    local maxRecords = tonumber(BiaoGe.options.historyMaxRecords)
    BiaoGe.options.historyMaxRecords = maxRecords and maxRecords >= 1
        and math.floor(maxRecords) or DEFAULT_MAX_RECORDS
    for _, FB in ipairs(BG.FBtable) do
        Ensure(FB)
        Store.Prune(FB)
    end
end)

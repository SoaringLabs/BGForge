local AddonName, ns = ...



local RR = "|r"
ns.RR = RR
local NN = "\n"
ns.NN = NN
local RN = "|r\n"
ns.RN = RN

BG = {}

----------tbl元素个数----------
local function Size(t)
    local s = 0
    for k, v in pairs(t) do
        if v ~= nil then s = s + 1 end
    end
    return s
end
ns.Size = Size

----------将16进制色值换算成0到1范围的RGB分量----------
local function RGB(hex, Alpha)
    local red = hex:sub(1, 2)
    local green = hex:sub(3, 4)
    local blue = hex:sub(5, 6)

    red = tonumber(red, 16) / 255
    green = tonumber(green, 16) / 255
    blue = tonumber(blue, 16) / 255

    if Alpha then
        return red, green, blue, Alpha
    else
        return red, green, blue
    end
end
ns.RGB = RGB

----------向DB_Loot补充职业任务说明文本----------
local function ClassQuest(classID)
    local className, classFile, classID = GetClassInfo(classID)
    local color = select(4, GetClassColor(classFile))
    return "|c" .. color .. className .. "|r" .. BG.STC_y1(QUESTS_LABEL)
end
ns.ClassQuest = ClassQuest


-- 注册事件
do
    local LIFECYCLE = {
        { event = "ADDON_LOADED", guard = function(name) return type(name) == "string" and name:lower() == AddonName:lower() end },
        { event = "PLAYER_ENTERING_WORLD" },
        { event = "PLAYER_LOGIN" },
    }
    local lifecycle = {}
    for i = 1, #LIFECYCLE do
        local spec = LIFECYCLE[i]
        local queue = {}
        lifecycle[i] = queue
        local frame = CreateFrame("Frame")
        frame:RegisterEvent(spec.event)
        frame:SetScript("OnEvent", function(self, _, ...)
            if spec.guard and not spec.guard(...) then return end
            self:UnregisterEvent(spec.event)
            for j = 1, #queue do
                securecall(queue[j])
            end
        end)
    end

    function BG.Init(func)
        tinsert(lifecycle[1], func)
    end
    function BG.Init2(func)
        tinsert(lifecycle[2], func)
    end
    function BG.Init3(func)
        tinsert(lifecycle[3], func)
    end

    local events = {}
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(_, event, ...)
        for _, func in ipairs(events[event]) do
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                securecall(func, f, event, CombatLogGetCurrentEventInfo())
            else
                securecall(func, f, event, ...)
            end
        end
    end)
    local function RegisterOneEvent(event, func)
        if not events[event] then
            events[event] = {}
            f:RegisterEvent(event)
        end
        tinsert(events[event], func)
    end
    function BG.RegisterEvent(event, func)
        if type(event) == "table" then
            for _, e in ipairs(event) do
                RegisterOneEvent(e, func)
            end
        else
            RegisterOneEvent(event, func)
        end
    end
end

-- 版本号
local ver = select(4, GetBuildInfo())
local isTW = GetCurrentRegion() ~= 5
if isTW then
    BG.IsTW = true
end

local function ApplyVersion(ver)
    BG.verLess2 = ver < 30000
    BG.verOver3 = ver >= 30000
    BG.verOver4 = ver >= 40000
    BG.verLess3 = ver < 40000
    BG.verOver5 = ver >= 50000
    BG.verLess4 = ver < 50000

    local rules = {
        { lt = 20000, flags = { "IsVanilla" }, hard = true, vanilla = true },
        { min = 20000, lt = 30000, flags = { "IsTBC" }, hard = true },
        { min = 30000, lt = 38000, flags = { "IsWLK", "IsWLK_80" } },
        { min = 38000, lt = 40000, flags = { "IsWLK", "IsTitan" }, hard = true },
        { min = 40000, lt = 50000, flags = { "IsCTM" } },
        { min = 50000, lt = 60000, flags = { "IsMOP" }, mop = true },
        { min = 110000, lt = math.huge, flags = { "IsRetail" } },
    }
    for _, rule in ipairs(rules) do
        if ver >= (rule.min or 0) and ver < rule.lt then
            for _, flag in ipairs(rule.flags) do
                BG[flag] = true
            end
            if rule.hard then
                BG.onlyOneHard = true
            end
            if rule.vanilla then
                if C_Engraving and C_Engraving.IsEngravingEnabled() then
                    BG.IsVanilla_Sod = true
                else
                    BG.IsVanilla_60 = true
                end
            end
            if rule.mop then
                BG[BG.IsTW and "IsMOP_TW" or "IsMOP_CN"] = true
            end
            break
        end
    end
end
ApplyVersion(ver)

BG.IsNewUI = true



function BG.IsWLKFB(FB)
    local FB = FB or BG.FB1
    if (FB == "NAXX" and not BG.IsVanilla) or FB == "ULD" or FB == "TOC" or FB == "ICC" then
        return true
    end
end

local tbl = { "SW", "BT", "HS", "TK", "SSC", "ZA", "KZ", "BWL", "TAQ", }
function BG.IsTBCFB(FB)
    if not BG.IsWLK then return false end
    local FB = FB or BG.FB1
    for _, _FB in ipairs(tbl) do
        if FB == _FB then
            return true
        end
    end
end

-- 阵营
if UnitFactionGroup("player") == "Alliance" then
    BG.IsAlliance = true
end

if UnitFactionGroup("player") == "Horde" then
    BG.IsHorde = true
end

function BG.GN(unit)
    unit = unit or "player"
    if unit == "t" then
        unit = "target"
    end
    return GetUnitName(unit, true)
end

BG.playerName = BG.GN()
BG.realmName = GetRealmName():gsub(" ", ""):gsub("%-", "")
BG.realmID = GetRealmID()

function BG.GFN(name)
    if not name then return end
    local name, realm = strsplit("-", name)
    realm = realm or BG.realmName
    return name .. "-" .. realm
end

function BG.GSN(name)
    if not name then return end
    local name, realm = strsplit("-", name)
    if not realm or realm == "" or realm == BG.realmName then
        return name
    else
        return name .. "-" .. realm
    end
end

function BG.SPN(name)
    if not name then return end
    if BG.IsSecret(name) then return end
    return strsplit("-", name, 2)
end

-- 增加节日掉落
function BG.AddHolidayLoot(lootInfo)
    BG.hasHolidayLoot = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
    f:SetScript("OnEvent", function(self, event, isLogin, isReload)
        if event == "PLAYER_ENTERING_WORLD" then
            if isLogin then
                return
            else
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            end
        end

        local all = {}

        local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
        local day = currentCalendarTime.monthDay
        local numEvents = C_Calendar.GetNumDayEvents(0, day)
        if numEvents <= 0 then
            return
        end

        for i = 1, numEvents do
            local event = C_Calendar.GetDayEvent(0, day, i)
            if event and lootInfo[event.eventID] then
                BG.hasHoliday = true
                tinsert(all, lootInfo[event.eventID])
            end
        end

        for _, FB in pairs(BG.FBtable) do
            BG.Loot[FB].Holiday = all
        end
    end)
end

-- 特殊兑换物
function BG.InsertExLoot(FB, tbl)
    for exItem, loot in pairs(tbl) do
        BG.Loot[FB].ExchangeItems[exItem] = BG.Loot[FB].ExchangeItems[exItem] or {}
        for _, itemID in pairs(loot.items) do
            tinsert(BG.Loot[FB].ExchangeItems[exItem], itemID)
            for _, bossInfo in pairs(loot.boss) do
                local boss, hard = strsplit("-", bossInfo)
                BG.Loot[FB][hard]["boss" .. boss .. "other"] =
                    BG.Loot[FB][hard]["boss" .. boss .. "other"] or {}
                tinsert(BG.Loot[FB][hard]["boss" .. boss .. "other"], itemID)
            end
        end
    end
end

-- 套装相关
function BG.InsertSetLoot(FB, tbl)
    for boss, loot in pairs(tbl) do
        for hard, _loot in pairs(loot) do
            BG.Loot[FB][hard]["boss" .. boss .. "other"] =
                BG.Loot[FB][hard]["boss" .. boss .. "other"] or {}
            for exItemID, items in pairs(_loot) do
                BG.Loot[FB].ExchangeItems[exItemID] = items
                for _, itemID in pairs(items) do
                    tinsert(BG.Loot[FB][hard]["boss" .. boss .. "other"], itemID)
                end
            end
        end
    end
end

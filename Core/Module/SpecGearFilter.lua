local AddonName, ns = ...

local L = ns.L
local Maxb = ns.Maxb

local SpecGearFilter = {}
BG.SpecGearFilter = SpecGearFilter

local ALPHA_ALLOWED = 1
local ALPHA_FILTERED = 0.4
local CLEANUP_VERSION = 1

local metadataCache = {}
local buttons = {}
local uiFrame

local function SetOf(...)
    local result = {}
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "table" then
            for key in pairs(value) do
                result[key] = true
            end
        elseif value ~= nil then
            result[value] = true
        end
    end
    return result
end

local WEAPON = {
    oneHandAxe = 0,
    twoHandAxe = 1,
    bow = 2,
    gun = 3,
    oneHandMace = 4,
    twoHandMace = 5,
    polearm = 6,
    oneHandSword = 7,
    twoHandSword = 8,
    staff = 10,
    fist = 13,
    dagger = 15,
    thrown = 16,
    crossbow = 18,
    wand = 19,
    fishingPole = 20,
}

local ARMOR = {
    offhand = 0,
    cloth = 1,
    leather = 2,
    mail = 3,
    plate = 4,
    shield = 6,
    libram = 7,
    idol = 8,
    totem = 9,
    sigil = 10,
}

local ALL_WEAPONS = SetOf(
    WEAPON.oneHandAxe, WEAPON.twoHandAxe, WEAPON.bow, WEAPON.gun,
    WEAPON.oneHandMace, WEAPON.twoHandMace, WEAPON.polearm,
    WEAPON.oneHandSword, WEAPON.twoHandSword, WEAPON.staff,
    WEAPON.fist, WEAPON.dagger, WEAPON.thrown, WEAPON.crossbow,
    WEAPON.wand, WEAPON.fishingPole
)
local ALL_ARMOR = SetOf(
    ARMOR.offhand, ARMOR.cloth, ARMOR.leather, ARMOR.mail, ARMOR.plate,
    ARMOR.shield, ARMOR.libram, ARMOR.idol, ARMOR.totem, ARMOR.sigil
)

local CAN_USE = {
    DEATHKNIGHT = {
        weapon = SetOf(WEAPON.oneHandAxe, WEAPON.twoHandAxe, WEAPON.oneHandMace, WEAPON.twoHandMace,
            WEAPON.polearm, WEAPON.oneHandSword, WEAPON.twoHandSword),
        armor = SetOf(ARMOR.leather, ARMOR.mail, ARMOR.plate, ARMOR.sigil),
    },
    WARRIOR = {
        weapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandAxe, WEAPON.twoHandAxe,
            WEAPON.oneHandMace, WEAPON.twoHandMace, WEAPON.oneHandSword, WEAPON.twoHandSword,
            WEAPON.polearm, WEAPON.staff, WEAPON.bow, WEAPON.crossbow, WEAPON.gun, WEAPON.thrown),
        armor = SetOf(ARMOR.leather, ARMOR.mail, ARMOR.plate, ARMOR.shield),
    },
    PALADIN = {
        weapon = SetOf(WEAPON.oneHandAxe, WEAPON.twoHandAxe, WEAPON.oneHandMace, WEAPON.twoHandMace,
            WEAPON.oneHandSword, WEAPON.twoHandSword, WEAPON.polearm),
        armor = SetOf(ARMOR.cloth, ARMOR.leather, ARMOR.mail, ARMOR.plate, ARMOR.shield,
            ARMOR.offhand, ARMOR.libram),
    },
    HUNTER = {
        weapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandAxe, WEAPON.twoHandAxe,
            WEAPON.oneHandSword, WEAPON.twoHandSword, WEAPON.polearm, WEAPON.staff,
            WEAPON.bow, WEAPON.crossbow, WEAPON.gun),
        armor = SetOf(ARMOR.leather, ARMOR.mail),
    },
    SHAMAN = {
        weapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandAxe, WEAPON.twoHandAxe,
            WEAPON.oneHandMace, WEAPON.twoHandMace, WEAPON.staff),
        armor = SetOf(ARMOR.cloth, ARMOR.leather, ARMOR.mail, ARMOR.shield, ARMOR.offhand, ARMOR.totem),
    },
    DRUID = {
        weapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandMace, WEAPON.twoHandMace,
            WEAPON.polearm, WEAPON.staff),
        armor = SetOf(ARMOR.cloth, ARMOR.leather, ARMOR.offhand, ARMOR.idol),
    },
    ROGUE = {
        weapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandAxe, WEAPON.oneHandMace,
            WEAPON.oneHandSword, WEAPON.bow, WEAPON.crossbow, WEAPON.gun, WEAPON.thrown),
        armor = SetOf(ARMOR.leather),
    },
    PRIEST = {
        weapon = SetOf(WEAPON.dagger, WEAPON.oneHandMace, WEAPON.staff, WEAPON.wand),
        armor = SetOf(ARMOR.cloth, ARMOR.offhand),
    },
    MAGE = {
        weapon = SetOf(WEAPON.dagger, WEAPON.oneHandSword, WEAPON.staff, WEAPON.wand),
        armor = SetOf(ARMOR.cloth, ARMOR.offhand),
    },
    WARLOCK = {
        weapon = SetOf(WEAPON.dagger, WEAPON.oneHandSword, WEAPON.staff, WEAPON.wand),
        armor = SetOf(ARMOR.cloth, ARMOR.offhand),
    },
}

local T0 = SetOf("crit", "haste", "hit", "defense", "dodge", "attackPower", "expertise", "armorPen", "proc")
local T1 = SetOf(T0, "strength", "agility", "parry")
local T2 = SetOf(T1, "block")
local T3 = SetOf(T0, "strength", "agility")
local DPS0 = SetOf("crit", "haste", "hit", "attackPower", "expertise", "armorPen", "proc")
local DPS1 = SetOf(DPS0, "strength", "agility", "intellect")
local DPS2 = SetOf(DPS0, "strength", "agility")
local DPS3 = SetOf(DPS1, "spellPower")
local LR1 = SetOf("crit", "haste", "agility", "hit", "attackPower", "armorPen", "proc", "intellect")
local FX1 = SetOf("crit", "haste", "intellect", "hit", "spellPower", "spirit")
local FX2 = SetOf("crit", "haste", "intellect", "hit", "spellPower", "mp5")
local N1 = SetOf("crit", "haste", "intellect", "mp5", "spellPower", "spirit")
local N2 = SetOf("crit", "haste", "intellect", "mp5", "spellPower")

local SCHEMES = {
    DEATHKNIGHT = {
        { key = "class", name = L["死亡骑士"], icon = "Interface/Icons/spell_deathknight_classicon", stats = SetOf(T1, DPS1) },
        { key = "blood", name = L["死亡骑士-鲜血"], icon = "Interface/Icons/spell_deathknight_bloodpresence", stats = T1, tank = true,
            noWeapon = SetOf(WEAPON.oneHandAxe, WEAPON.oneHandMace, WEAPON.oneHandSword),
            noArmor = SetOf(ARMOR.leather, ARMOR.mail) },
        { key = "frost_unholy", name = L["死亡骑士-冰霜/邪恶"], icon = "Interface/Icons/spell_deathknight_frostpresence", stats = DPS1 },
    },
    WARRIOR = {
        { key = "class", name = L["战士"], icon = "Interface/Icons/classicon_WARRIOR", stats = SetOf(T2, DPS1) },
        { key = "protection", name = L["战士-防御"], icon = "Interface/Icons/ability_warrior_defensivestance", stats = T2, tank = true,
            noWeapon = SetOf(WEAPON.twoHandAxe, WEAPON.twoHandMace, WEAPON.twoHandSword, WEAPON.polearm, WEAPON.staff),
            noArmor = SetOf(ARMOR.leather, ARMOR.mail) },
        { key = "arms_fury", name = L["战士-武器/狂怒"], icon = "Interface/Icons/ability_warrior_savageblow", stats = DPS1,
            noWeapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandAxe, WEAPON.oneHandMace, WEAPON.oneHandSword),
            noArmor = SetOf(ARMOR.shield) },
    },
    PALADIN = {
        { key = "class", name = L["圣骑士"], icon = "Interface/Icons/classicon_paladin", stats = SetOf(T2, DPS1, N1) },
        { key = "protection", name = L["圣骑士-防御"], icon = "Interface/Icons/spell_holy_devotionaura", stats = T2, tank = true,
            noWeapon = SetOf(WEAPON.twoHandAxe, WEAPON.twoHandMace, WEAPON.twoHandSword, WEAPON.polearm),
            noArmor = SetOf(ARMOR.cloth, ARMOR.leather, ARMOR.mail, ARMOR.offhand) },
        { key = "retribution", name = L["圣骑士-惩戒"], icon = "Interface/Icons/spell_holy_auraoflight", stats = DPS1,
            noWeapon = SetOf(WEAPON.oneHandAxe, WEAPON.oneHandMace, WEAPON.oneHandSword),
            noArmor = SetOf(ARMOR.cloth, ARMOR.shield, ARMOR.offhand) },
        { key = "holy", name = L["圣骑士-神圣"], icon = "Interface/Icons/spell_holy_holybolt", stats = N2,
            noWeapon = SetOf(WEAPON.twoHandAxe, WEAPON.twoHandMace, WEAPON.twoHandSword, WEAPON.polearm) },
    },
    HUNTER = {
        { key = "class", name = L["猎人"], icon = "Interface/Icons/classicon_HUNTER", stats = LR1 },
    },
    SHAMAN = {
        { key = "class", name = L["萨满"], icon = "Interface/Icons/classicon_SHAMAN", stats = SetOf(DPS3, FX2, N2) },
        { key = "enhancement", name = L["萨满-增强"], icon = "Interface/Icons/spell_nature_lightningshield", stats = DPS3,
            noArmor = SetOf(ARMOR.shield, ARMOR.offhand) },
        { key = "elemental", name = L["萨满-元素"], icon = "Interface/Icons/spell_nature_lightning", stats = FX2,
            noWeapon = SetOf(WEAPON.twoHandAxe, WEAPON.twoHandMace) },
        { key = "restoration", name = L["萨满-恢复"], icon = "Interface/Icons/spell_nature_magicimmunity", stats = N2,
            noWeapon = SetOf(WEAPON.twoHandAxe, WEAPON.twoHandMace) },
    },
    DRUID = {
        { key = "class", name = L["德鲁伊"], icon = "Interface/Icons/classicon_DRUID", stats = SetOf(T3, DPS2, FX1, N1) },
        { key = "bear", name = L["德鲁伊-巨熊"], icon = "Interface/Icons/ability_racial_bearform", stats = T3, tank = true,
            noWeapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandMace),
            noArmor = SetOf(ARMOR.cloth, ARMOR.offhand) },
        { key = "cat", name = L["德鲁伊-猎豹"], icon = "Interface/Icons/ability_druid_catform", stats = DPS2,
            noWeapon = SetOf(WEAPON.dagger, WEAPON.fist, WEAPON.oneHandMace),
            noArmor = SetOf(ARMOR.cloth, ARMOR.offhand) },
        { key = "balance", name = L["德鲁伊-平衡"], icon = "Interface/Icons/spell_nature_starfall", stats = FX1,
            noWeapon = SetOf(WEAPON.twoHandMace, WEAPON.polearm) },
        { key = "restoration", name = L["德鲁伊-恢复"], icon = "Interface/Icons/spell_nature_healingtouch", stats = N1,
            noWeapon = SetOf(WEAPON.twoHandMace, WEAPON.polearm) },
    },
    ROGUE = {
        { key = "class", name = L["盗贼"], icon = "Interface/Icons/classicon_rogue", stats = DPS2 },
    },
    PRIEST = {
        { key = "class", name = L["牧师"], icon = "Interface/Icons/classicon_PRIEST", stats = SetOf(FX1, N1) },
        { key = "shadow", name = L["牧师-暗影"], icon = "Interface/Icons/spell_shadow_shadowwordpain", stats = FX1 },
        { key = "discipline_holy", name = L["牧师-戒律/神圣"], icon = "Interface/Icons/spell_holy_wordfortitude", stats = N1 },
    },
    MAGE = {
        { key = "class", name = L["法师"], icon = "Interface/Icons/classicon_mage", stats = FX1 },
    },
    WARLOCK = {
        { key = "class", name = L["术士"], icon = "Interface/Icons/classicon_warlock", stats = FX1 },
    },
}

local function CopyWithout(source, removed)
    local result = {}
    for id in pairs(source) do
        if not (removed and removed[id]) then
            result[id] = true
        end
    end
    return result
end

local function CompileSchemes()
    for classFile, classSchemes in pairs(SCHEMES) do
        local usable = CAN_USE[classFile]
        for _, scheme in ipairs(classSchemes) do
            local allowedWeapon = CopyWithout(usable.weapon, scheme.noWeapon)
            local allowedArmor = CopyWithout(usable.armor, scheme.noArmor)
            scheme.blockedWeapon = {}
            scheme.blockedArmor = {}
            for id in pairs(ALL_WEAPONS) do
                if not allowedWeapon[id] then
                    scheme.blockedWeapon[id] = true
                end
            end
            for id in pairs(ALL_ARMOR) do
                if not allowedArmor[id] then
                    scheme.blockedArmor[id] = true
                end
            end
        end
    end
end
CompileSchemes()

local function CurrentClass()
    local className, classFile = UnitClass("player")
    return classFile, className
end

local function FindScheme(classFile, key)
    if not key then return end
    for _, scheme in ipairs(SCHEMES[classFile] or {}) do
        if scheme.key == key then
            return scheme
        end
    end
end

local function EnsureStorage()
    if type(BiaoGe) ~= "table" then BiaoGe = {} end
    if type(BiaoGe.options) ~= "table" then BiaoGe.options = {} end

    local cleanupVersion = tonumber(BiaoGe.options.specGearFilterCleanupVersion) or 0
    if cleanupVersion < CLEANUP_VERSION then
        BiaoGe.FilterClassItemDB = nil
        BiaoGe.filterClassNum = nil
        BiaoGe.options.specGearFilterCleanupVersion = CLEANUP_VERSION
    end

    if type(BiaoGe.options.specGearFilterByClass) ~= "table" then
        BiaoGe.options.specGearFilterByClass = {}
    end
    local classFile = CurrentClass()
    local key = BiaoGe.options.specGearFilterByClass[classFile]
    if key and not FindScheme(classFile, key) then
        BiaoGe.options.specGearFilterByClass[classFile] = nil
    end
end

local function SelectedKey()
    EnsureStorage()
    local classFile = CurrentClass()
    return BiaoGe.options.specGearFilterByClass[classFile]
end

local function PlainPattern(value)
    if type(value) ~= "string" or value == "" then return end
    return value:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function FormatPattern(value)
    if type(value) ~= "string" or value == "" then return end
    value = value:gsub("%%s", "\001"):gsub("%%d", "\002")
    value = PlainPattern(value)
    return value:gsub("\001", ".+"):gsub("\002", "%%d+")
end

local function Patterns(...)
    local result = {}
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "table" then
            for _, nested in ipairs(value) do
                local pattern = FormatPattern(nested)
                if pattern then table.insert(result, pattern) end
            end
        else
            local pattern = FormatPattern(value)
            if pattern then table.insert(result, pattern) end
        end
    end
    return result
end

local ATTRIBUTE_PATTERNS = {
    strength = Patterns(ITEM_MOD_STRENGTH_SHORT),
    agility = Patterns(ITEM_MOD_AGILITY_SHORT),
    intellect = Patterns(ITEM_MOD_INTELLECT_SHORT),
    spirit = Patterns(ITEM_MOD_SPIRIT_SHORT),
    mp5 = Patterns(ITEM_MOD_MANA_REGENERATION),
    hit = Patterns(HIT_LCD),
    haste = Patterns(STAT_HASTE),
    crit = Patterns(STAT_CRITICAL_STRIKE),
    defense = Patterns(STAT_CATEGORY_DEFENSE),
    parry = Patterns(STAT_PARRY),
    dodge = Patterns(STAT_DODGE),
    block = Patterns(ITEM_MOD_BLOCK_RATING_SHORT, ITEM_MOD_BLOCK_VALUE_SHORT),
    attackPower = Patterns(ITEM_MOD_ATTACK_POWER_SHORT),
    expertise = Patterns(STAT_EXPERTISE),
    armorPen = Patterns(ITEM_MOD_ARMOR_PENETRATION_RATING),
    proc = Patterns(ITEM_SPELL_TRIGGER_ONPROC),
    spellPower = Patterns(ITEM_MOD_SPELL_POWER_SHORT, ITEM_MOD_SPELL_DAMAGE_DONE, ITEM_MOD_SPELL_HEALING_DONE),
}

local TANK_PATTERNS = Patterns(STAT_CATEGORY_DEFENSE, STAT_PARRY, STAT_DODGE, STAT_BLOCK)
local CLASS_PATTERN = PlainPattern(CLASS)
local ACCOUNT_BOUND_PATTERN = PlainPattern(ITEM_BIND_TO_BNETACCOUNT)

local function ContainsAny(text, patterns)
    for _, pattern in ipairs(patterns) do
        if text:find(pattern) then
            return true
        end
    end
    return false
end

local function ReadMetadata(itemLink)
    local itemString = itemLink and itemLink:match("(item:[%d%-:]+)")
    if not itemString then return end
    if metadataCache[itemString] then
        return metadataCache[itemString]
    end

    local itemID, _, _, equipLoc, _, typeID, subclassID = GetItemInfoInstant(itemString)
    if not itemID then return end
    local metadata = {
        itemID = itemID,
        equipLoc = equipLoc,
        typeID = typeID,
        subclassID = subclassID,
        tooltipText = BG.GetTooltipTextLeftAll(itemString) or "",
    }
    metadataCache[itemString] = metadata
    return metadata
end

local function ShouldFilter(metadata, scheme, className)
    if not metadata or not scheme then return false end
    local tooltipText = metadata.tooltipText
    if ACCOUNT_BOUND_PATTERN and tooltipText:find(ACCOUNT_BOUND_PATTERN) then
        return false
    end
    if metadata.typeID == 9 then return false end

    if metadata.typeID == 4 and metadata.equipLoc ~= "INVTYPE_CLOAK" then
        if scheme.blockedArmor[metadata.subclassID] then
            if metadata.subclassID ~= ARMOR.offhand or metadata.equipLoc == "INVTYPE_HOLDABLE" then
                return true
            end
        end
    elseif metadata.typeID == 2 and scheme.blockedWeapon[metadata.subclassID] then
        return true
    end

    for attribute, patterns in pairs(ATTRIBUTE_PATTERNS) do
        if not scheme.stats[attribute] and ContainsAny(tooltipText, patterns) then
            return true
        end
    end

    if CLASS_PATTERN and tooltipText:find(CLASS_PATTERN) then
        local classPattern = PlainPattern(className)
        if classPattern and not tooltipText:find(classPattern) then
            return true
        end
    end

    if scheme.tank and metadata.typeID == 4
        and metadata.equipLoc ~= "INVTYPE_TRINKET"
        and metadata.equipLoc ~= "INVTYPE_RELIC"
        and #TANK_PATTERNS > 0
        and not ContainsAny(tooltipText, TANK_PATTERNS)
    then
        return true
    end

    return false
end

local function UpdateButtons()
    local selected = SelectedKey()
    for _, button in ipairs(buttons) do
        local active = button.scheme.key == selected
        button.icon:SetDesaturated(not active)
        button.highlight:SetShown(active)
    end
end

local function CreateControls(parent)
    EnsureStorage()

    local classFile = CurrentClass()
    local classSchemes = SCHEMES[classFile]
    if not classSchemes or #classSchemes == 0 then return end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(#classSchemes * 35 - 10, 25)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetPoint("RIGHT", frame, "LEFT", -10, 0)
    label:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
    label:SetTextColor(1, 0.82, 0)
    label:SetText(L["装备过滤："])

    for index, scheme in ipairs(classSchemes) do
        local button = CreateFrame("Button", nil, frame)
        button:SetSize(25, 25)
        button:SetPoint("LEFT", (index - 1) * 35, 0)
        button.scheme = scheme

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(scheme.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local highlight = button:CreateTexture(nil, "OVERLAY")
        highlight:SetPoint("TOPLEFT", -4, 4)
        highlight:SetPoint("BOTTOMRIGHT", 4, -4)
        highlight:SetTexture("Interface/Buttons/ButtonHilight-Square")
        highlight:SetBlendMode("ADD")
        button.highlight = highlight

        button:SetScript("OnClick", function(self)
            local currentClass = CurrentClass()
            local selected = BiaoGe.options.specGearFilterByClass[currentClass]
            if selected == self.scheme.key then
                BiaoGe.options.specGearFilterByClass[currentClass] = nil
            else
                BiaoGe.options.specGearFilterByClass[currentClass] = self.scheme.key
            end
            UpdateButtons()
            SpecGearFilter.RefreshCurrentTable()
            if BG.PlaySound then BG.PlaySound(1) end
        end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.scheme.name, 1, 1, 1)
            GameTooltip:AddLine(L["不适合该方案的装备会被置灰。"], 1, 0.82, 0, true)
            if SelectedKey() == self.scheme.key then
                GameTooltip:AddLine(L["再次点击可关闭装备过滤。"], 0, 1, 0, true)
            else
                GameTooltip:AddLine(L["点击启用该装备过滤方案。"], 0, 1, 0, true)
            end
            GameTooltip:AddLine(L["战网账号绑定装备始终保持高亮。"], 0.6, 0.8, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        table.insert(buttons, button)
    end

    UpdateButtons()
    return frame
end

function SpecGearFilter.ApplyToCell(cell, explicitLink, onApplied)
    if not cell or not cell.SetAlpha then return end

    cell._bgForgeSpecGearFilterRequest = (cell._bgForgeSpecGearFilterRequest or 0) + 1
    local request = cell._bgForgeSpecGearFilterRequest
    local link = explicitLink or (cell.GetText and cell:GetText()) or ""
    local classFile, className = CurrentClass()
    local key = SelectedKey()
    local scheme = FindScheme(classFile, key)
    local tableKey = BG.FB1

    if not scheme or type(link) ~= "string" or not link:find("item:", 1, true) then
        cell:SetAlpha(ALPHA_ALLOWED)
        if onApplied then onApplied(false) end
        return
    end

    local itemString = link:match("(item:[%d%-:]+)")
    local itemID = itemString and GetItemInfoInstant(itemString)
    if not itemID then
        cell:SetAlpha(ALPHA_ALLOWED)
        if onApplied then onApplied(false) end
        return
    end
    cell:SetAlpha(ALPHA_ALLOWED)

    local function ApplyLoadedItem()
        if cell._bgForgeSpecGearFilterRequest ~= request then return end
        if BG.FB1 ~= tableKey then return end
        local currentLink = explicitLink or (cell.GetText and cell:GetText()) or ""
        if currentLink ~= link or SelectedKey() ~= key then return end

        local metadata = ReadMetadata(link)
        local filtered = ShouldFilter(metadata, scheme, className)
        cell:SetAlpha(filtered and ALPHA_FILTERED or ALPHA_ALLOWED)
        if onApplied then onApplied(filtered) end
    end

    if metadataCache[itemString] then
        ApplyLoadedItem()
        return
    end

    local item
    if Item and Item.CreateFromItemLink then
        item = Item:CreateFromItemLink(itemString)
    elseif Item and Item.CreateFromItemID then
        item = Item:CreateFromItemID(itemID)
    end
    if item and item.ContinueOnItemLoad then
        item:ContinueOnItemLoad(ApplyLoadedItem)
    else
        ApplyLoadedItem()
    end
end

function SpecGearFilter.ApplyToAuctionFrame(auctionFrame, keepExpanded)
    if not auctionFrame then return end
    if keepExpanded ~= nil then
        auctionFrame._bgForgeSpecGearFilterKeepExpanded = keepExpanded and true or false
    end

    local target = auctionFrame.itemFrame or auctionFrame
    local link = auctionFrame.link or (auctionFrame.itemID and ("item:" .. auctionFrame.itemID))
    if not link then return end

    SpecGearFilter.ApplyToCell(target, link, function(filtered)
        if not filtered or BiaoGe.options.autoAuctionFold ~= 1 then return end
        if auctionFrame._bgForgeSpecGearFilterKeepExpanded then return end
        if auctionFrame.IsEnd or auctionFrame.IsSmallWindow then return end
        if not auctionFrame.hide or type(auctionFrame.hide.Click) ~= "function" then return end

        auctionFrame.notClick = true
        auctionFrame.hide:Click()
        auctionFrame.notClick = false
    end)
end

function SpecGearFilter.RefreshCurrentTable()
    local FB = BG.FB1
    if FB and BG.Frame and BG.Frame[FB] and Maxb[FB] then
        for bossIndex = 1, Maxb[FB] do
            local bossFrame = BG.Frame[FB]["boss" .. bossIndex]
            if bossFrame then
                for rowIndex = 1, BG.GetMaxi(FB, bossIndex) do
                    local cell = bossFrame["zhuangbei" .. rowIndex]
                    if cell then
                        SpecGearFilter.ApplyToCell(cell)
                    end
                end
            end
        end
    end

    if BG.auctionLogFrame and BG.auctionLogFrame.buttons then
        for _, button in ipairs(BG.auctionLogFrame.buttons) do
            if button.frame and button.link then
                SpecGearFilter.ApplyToCell(button.frame, button.link)
            end
        end
    end

    if BGA and BGA.Frames then
        for _, auctionFrame in pairs(BGA.Frames) do
            SpecGearFilter.ApplyToAuctionFrame(auctionFrame)
        end
    end

    if BG.Wishlist and BG.Wishlist.Refresh then
        BG.Wishlist.Refresh()
    end
end

function SpecGearFilter.CreateControls(parent)
    return CreateControls(parent)
end

function SpecGearFilter.CreateUI()
    if uiFrame or not BG.ButtonQingKong then return end
    uiFrame = CreateControls(BG.FBMainFrame)
    if not uiFrame then return end
    uiFrame:SetPoint("LEFT", BG.ButtonQingKong, "RIGHT", 100, 0)
    SpecGearFilter.RefreshCurrentTable()
end

BG.Init(EnsureStorage)

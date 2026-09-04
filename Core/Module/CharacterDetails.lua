local _, ns = ...

local L = ns.L
local UI = BG.UI
local M = {}
BG.CharacterDetails = M

-- 角色详情只读取 RaidLockoutOverview 为当前区服、本机登录角色保存的快照。
-- 本模块不扫描单位、不通信，也不在界面刷新时重新采集数据。
local SLOT_DEFINITIONS = {
    { id = 1, token = "HeadSlot", label = L["头部"] },
    { id = 2, token = "NeckSlot", label = L["颈部"] },
    { id = 3, token = "ShoulderSlot", label = L["肩部"] },
    { id = 15, token = "BackSlot", label = L["背部"] },
    { id = 5, token = "ChestSlot", label = L["胸部"] },
    { id = 4, token = "ShirtSlot", label = L["衬衣"] },
    { id = 19, token = "TabardSlot", label = L["战袍"] },
    { id = 9, token = "WristSlot", label = L["手腕"] },
    { id = 10, token = "HandsSlot", label = L["手"] },
    { id = 6, token = "WaistSlot", label = L["腰部"] },
    { id = 7, token = "LegsSlot", label = L["腿部"] },
    { id = 8, token = "FeetSlot", label = L["脚"] },
    { id = 11, token = "Finger0Slot", label = L["手指"] },
    { id = 12, token = "Finger1Slot", label = L["手指"] },
    { id = 13, token = "Trinket0Slot", label = L["饰品"] },
    { id = 14, token = "Trinket1Slot", label = L["饰品"] },
    { id = 16, token = "MainHandSlot", label = L["主手"] },
    { id = 17, token = "SecondaryHandSlot", label = L["副手"] },
    { id = 18, token = "RangedSlot", label = L["远程"] },
}

local PAPER_DOLL_LEFT = { 1, 2, 3, 15, 5, 4, 19, 9 }
local PAPER_DOLL_RIGHT = { 10, 6, 7, 8, 11, 12, 13, 14 }
local PAPER_DOLL_BOTTOM = { 16, 17, 18 }
local PAPER_DOLL_WIDTH = 420
local PAPER_DOLL_SLOT_TOP = 64
local BACKPACK_COLUMNS = 16
local BACKPACK_ITEM_SIZE = 35
local BACKPACK_ITEM_GAP = 8
local BACKPACK_GROUP_HEADER_HEIGHT = 26
local BACKPACK_GROUP_GAP = 8
local CHARACTER_ROW_HEIGHT = 56
local CHARACTER_ROW_STRIDE = 58
local MAX_CHARACTER_ROWS = 10
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local EMPTY_SLOT_TEXTURE = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local ENCHANT_TEXTURE = "Interface\\Icons\\Trade_Engraving"
local BACK_TEXTURE = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up"
local UNKNOWN_SPEC_TEXTURE = "Interface\\Icons\\INV_Misc_QuestionMark"
-- “专业与资源”只使用客户端可渲染资源：专业/日常的官方 fileID、配方法术
-- 纹理、货币与物品快照图标，以及 Blizzard 自带状态和金币纹理。
local READY_STATUS_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local WAITING_STATUS_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local UNKNOWN_STATUS_TEXTURE = "Interface\\FriendsFrame\\InformationIcon"
local ALERT_STATUS_TEXTURE_PATH = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
local ALERT_STATUS_TEXTURE = (GetFileIDFromPath and GetFileIDFromPath(ALERT_STATUS_TEXTURE_PATH))
    or WAITING_STATUS_TEXTURE
local GOLD_TEXTURE = "Interface\\MoneyFrame\\UI-GoldIcon"
local GOLD_ATLAS = "auctionhouse-icon-coin-gold"
local DAILY_DEFINITIONS = {
    { id = "jewelcraftingDaily", name = L["珠宝日常"], iconFileID = 134071, skillLineID = 755 },
    { id = "cookingDaily", name = L["烹饪日常"], iconFileID = 133971 },
    { id = "fishingDaily", name = L["钓鱼日常"], iconFileID = 136245 },
}
local PROFESSION_TRACK_COUNT = 2
local PROFESSION_COOLDOWN_CELL_COUNT = 2
local PROFESSION_TRACK_HEIGHT = 96
local PROFESSION_TRACK_GAP = 10
local PROFESSION_TRACK_TOP = 140
local PROFESSION_RESOURCES_HEIGHT = 150
local PROFESSION_RESOURCES_TOP = PROFESSION_TRACK_TOP
    + PROFESSION_TRACK_COUNT * (PROFESSION_TRACK_HEIGHT + PROFESSION_TRACK_GAP)
local PROFESSION_PANEL_HEIGHT = PROFESSION_RESOURCES_TOP + PROFESSION_RESOURCES_HEIGHT
local RESOURCE_UPGRADE_ICON_COUNT = 5

local frame
local selectedRealmID
local selectedCharacterName
local backCallback
local suppressBackCallback
local characterOffset = 0
local activeView = "equipment"
local SetActiveView

local function Token(name)
    return UI.Token("color", name)
end

local function SetTextColor(text, token)
    text:SetTextColor(unpack(Token(token)))
end

local function GetCharacters()
    if not BG.GetRaidLockoutStoredCharacters or not selectedRealmID then
        return {}
    end
    local visible = {}
    for _, character in ipairs(BG.GetRaidLockoutStoredCharacters(selectedRealmID)) do
        if not character.isHidden then
            visible[#visible + 1] = character
        end
    end
    return visible
end

local function FindCharacter(characters, name)
    for _, character in ipairs(characters) do
        if character.name == name then
            return character
        end
    end
end

local function GetClassColorHex(classFile)
    if not classFile or not GetClassColor then
        return "ffffffff"
    end
    return select(4, GetClassColor(classFile)) or "ffffffff"
end

local function GetClassName(classFile)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]) or classFile or UNKNOWN
end

local function GetCharacterSpecIcon(character)
    local classIcons = character and BG.talentIcon and BG.talentIcon[character.classFile]
    return classIcons and character.specIndex and classIcons[character.specIndex]
end

local function GetRaceName(raceID)
    if raceID and C_CreatureInfo and C_CreatureInfo.GetRaceInfo then
        local info = C_CreatureInfo.GetRaceInfo(raceID)
        return info and info.raceName
    end
end

local function GetCharacterUpdatedAt(character)
    local details = character and character.details
    local equipmentUpdatedAt = details and details.equipment
        and tonumber(details.equipment.updatedAt)
    local backpackUpdatedAt = details and details.backpack
        and tonumber(details.backpack.updatedAt)
    if equipmentUpdatedAt and backpackUpdatedAt then
        return max(equipmentUpdatedAt, backpackUpdatedAt)
    end
    return equipmentUpdatedAt or backpackUpdatedAt
end

local function GetItemIcon(link)
    if not link or not GetItemInfoInstant then
        return
    end
    return select(5, GetItemInfoInstant(link))
end

local function ParseItemEnhancements(link)
    if not link then
        return nil, {}
    end
    local enchantID, gem1, gem2, gem3, gem4 = link:match(
        "item:%-?%d+:(%-?%d*):(%-?%d*):(%-?%d*):(%-?%d*):(%-?%d*)"
    )
    local gems = {}
    for _, value in ipairs({ gem1, gem2, gem3, gem4 }) do
        local gemID = tonumber(value)
        if gemID and gemID > 0 then
            gems[#gems + 1] = gemID
        end
    end
    enchantID = tonumber(enchantID)
    return enchantID and enchantID > 0 and enchantID or nil, gems
end

local function ShowItemTooltip(owner, link)
    if not link then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end

local function CreateSurface(parent, role)
    return UI.Create("surface", parent, { role = role or "panel" })
end

local function CreateText(parent, role, text)
    return UI.Create("text", parent, { role = role, text = text })
end

local function GetSpellIcon(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return
    end
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end
    if GetSpellTexture then
        return GetSpellTexture(spellID)
    end
    if GetSpellInfo then
        return select(3, GetSpellInfo(spellID))
    end
end

local function FormatCompactNumber(value)
    value = floor(tonumber(value) or 0)
    return BreakUpLargeNumbers and BreakUpLargeNumbers(value) or tostring(value)
end

local function FormatOptionalNumber(value)
    return value == nil and "—" or FormatCompactNumber(value)
end

local function FormatWeeklyResourceDetail(earned, maximum)
    earned = tonumber(earned)
    maximum = tonumber(maximum)
    if earned == nil or maximum == nil or maximum <= 0 then
        return
    end
    return format("（%s/%s）", FormatCompactNumber(earned), FormatCompactNumber(maximum))
end

local function FormatProfessionCooldownTime(seconds)
    seconds = max(0, floor(tonumber(seconds) or 0))
    local days = floor(seconds / 86400)
    local hours = floor(seconds % 86400 / 3600)
    local minutes = floor(seconds % 3600 / 60)
    if days > 0 then
        return format("%d%s %d%s", days, L["天"], hours, L["小时"])
    elseif hours > 0 then
        return format("%d%s %d%s", hours, L["小时"], minutes, L["分钟"])
    end
    return format("%d%s", max(1, minutes), L["分钟"])
end

local function ShowSpellTooltip(owner, spellID)
    if not spellID then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if GameTooltip.SetSpellByID then
        GameTooltip:SetSpellByID(spellID)
    else
        GameTooltip:SetHyperlink("spell:" .. spellID)
    end
    GameTooltip:Show()
end

local function CreateGameIcon(parent, size)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    button:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = WHITE_TEXTURE,
        edgeSize = 1,
    })
    button:SetBackdropColor(unpack(Token("panel")))
    button:SetBackdropBorderColor(unpack(Token("borderStrong")))
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetScript("OnEnter", function(self)
        if self.link then
            ShowItemTooltip(self, self.link)
        elseif self.spellID then
            ShowSpellTooltip(self, self.spellID)
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function(self)
        if self.link and HandleModifiedItemClick then
            HandleModifiedItemClick(self.link)
        end
    end)
    return button
end

local function SetGameIcon(button, texture, atlas)
    if button.icon.SetAtlas then
        button.icon:SetAtlas(nil)
    end
    if atlas and button.icon.SetAtlas then
        local atlasReady = pcall(button.icon.SetAtlas, button.icon, atlas)
        if atlasReady then
            return
        end
    end
    button.icon:SetTexture(texture or UNKNOWN_SPEC_TEXTURE)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

local function CreateTab(parent, text, selected, enabled)
    local button = UI.Create("tab", parent, {
        text = text,
        state = selected and "selected" or (enabled and "default" or "disabled"),
        height = 32,
    })
    button:SetEnabled(enabled)
    return button
end

local function CreateItemButton(parent, size, iconInset)
    iconInset = iconInset or 2
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    button:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = WHITE_TEXTURE,
        edgeSize = 1,
    })
    button:SetBackdropColor(unpack(Token("panel")))
    button:SetBackdropBorderColor(unpack(Token("borderSubtle")))
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", iconInset, -iconInset)
    button.icon:SetPoint("BOTTOMRIGHT", -iconInset, iconInset)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.level = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.level:SetPoint("TOPLEFT", 2, -2)
    button.level:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
    button:SetScript("OnEnter", function(self)
        ShowItemTooltip(self, self.link)
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function(self)
        if self.link and HandleModifiedItemClick then
            HandleModifiedItemClick(self.link)
        end
    end)
    return button
end

local function GetItemDisplayColor(link)
    local quality = link and GetItemInfo and select(3, GetItemInfo(link))
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color then
        return color
    end
    local redHex, greenHex, blueHex = link
        and link:match("|c%x%x(%x%x)(%x%x)(%x%x)")
    if redHex then
        return {
            r = tonumber(redHex, 16) / 255,
            g = tonumber(greenHex, 16) / 255,
            b = tonumber(blueHex, 16) / 255,
        }
    end
end

local function SetItemButton(button, item)
    button.link = item and item.link or nil
    local icon = item and GetItemIcon(item.link)
    button.icon:SetTexture(icon or EMPTY_SLOT_TEXTURE)
    button.icon:SetDesaturated(not icon)
    button.level:SetText(item and item.itemLevel and floor(item.itemLevel + 0.5) or "")
    if item then
        local color = GetItemDisplayColor(item.link)
        if color then
            button:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            button.level:SetTextColor(color.r, color.g, color.b, 1)
        else
            button:SetBackdropBorderColor(unpack(Token("borderStrong")))
            button.level:SetTextColor(unpack(Token("textPrimary")))
        end
    else
        button:SetBackdropBorderColor(unpack(Token("borderSubtle")))
        button.level:SetTextColor(unpack(Token("textMuted")))
    end
end

local function IsBackpackEquipment(item)
    if not item then
        return false
    end
    if type(item.isEquipment) == "boolean" then
        local classID = tonumber(item.classID)
        return item.isEquipment and (classID == 2 or classID == 4)
    end
    if item.link and GetItemInfoInstant then
        local _, _, _, equipLoc, _, classID = GetItemInfoInstant(item.link)
        classID = tonumber(classID)
        if equipLoc ~= nil and classID then
            return equipLoc ~= "" and (classID == 2 or classID == 4)
        end
    end
    return false
end

local function SetBackpackItemButton(button, item)
    button.link = item and item.link or nil
    local icon = item and GetItemIcon(item.link)
    local isEquipment = IsBackpackEquipment(item)
    local badgeText = ""
    if item then
        if isEquipment then
            badgeText = item.itemLevel and floor(item.itemLevel + 0.5) or ""
        else
            badgeText = item.count and item.count > 1 and item.count or ""
        end
    end
    button.icon:SetTexture(icon or EMPTY_SLOT_TEXTURE)
    button.icon:SetDesaturated(not icon)
    button.level:SetText(badgeText)
    button.level:SetTextColor(1, 1, 1, 1)
    if item then
        local color = GetItemDisplayColor(item.link)
        if color then
            button:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            if isEquipment then
                button.level:SetTextColor(color.r, color.g, color.b, 1)
            end
        else
            button:SetBackdropBorderColor(unpack(Token("borderStrong")))
        end
    else
        button:SetBackdropBorderColor(unpack(Token("borderSubtle")))
    end
end

local function CreateEnhancementButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(18, 18)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return button
end

local function CreateEquipmentRow(parent, index)
    local row = CreateSurface(parent, "row")
    row:SetHeight(27)
    row.slot = CreateText(row, "label")
    row.slot:SetPoint("LEFT", 8, 0)
    row.slot:SetWidth(58)
    row.slot:SetJustifyH("LEFT")

    row.itemButton = CreateFrame("Button", nil, row)
    row.itemButton:SetPoint("LEFT", 70, 0)
    row.itemButton:SetPoint("RIGHT", -178, 0)
    row.itemButton:SetHeight(25)
    row.itemButton.text = CreateText(row.itemButton, "body")
    row.itemButton.text:SetAllPoints()
    row.itemButton.text:SetJustifyH("LEFT")
    row.itemButton.text:SetWordWrap(false)
    row.itemButton:SetScript("OnEnter", function(self)
        ShowItemTooltip(self, self.link)
    end)
    row.itemButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    row.itemButton:SetScript("OnClick", function(self)
        if self.link and HandleModifiedItemClick then
            HandleModifiedItemClick(self.link)
        end
    end)

    row.itemLevel = CreateText(row, "number")
    row.itemLevel:SetPoint("RIGHT", -130, 0)
    row.itemLevel:SetWidth(45)
    row.itemLevel:SetJustifyH("CENTER")
    row.enhancements = {}
    for enhancementIndex = 1, 5 do
        local button = CreateEnhancementButton(row)
        button:SetPoint("RIGHT", -8 - (enhancementIndex - 1) * 21, 0)
        row.enhancements[enhancementIndex] = button
    end
    row.index = index
    return row
end

local function SetEquipmentRow(row, definition, item)
    row.slot:SetText(definition.label)
    row.itemButton.link = item and item.link or nil
    row.itemButton.text:SetText(item and item.link or "—")
    row.itemLevel:SetText(item and item.itemLevel and floor(item.itemLevel + 0.5) or "—")

    for _, button in ipairs(row.enhancements) do
        button:Hide()
        button.link = nil
        button.itemID = nil
    end
    if not item then
        return
    end

    local enchantID, gems = ParseItemEnhancements(item.link)
    local enhancementIndex = 1
    if enchantID then
        local button = row.enhancements[enhancementIndex]
        button.link = item.link
        button.icon:SetTexture(ENCHANT_TEXTURE)
        button:SetScript("OnEnter", function(self)
            ShowItemTooltip(self, self.link)
        end)
        button:Show()
        enhancementIndex = enhancementIndex + 1
    end
    for _, gemID in ipairs(gems) do
        local button = row.enhancements[enhancementIndex]
        if not button then
            break
        end
        button.itemID = gemID
        button.icon:SetTexture(GetItemIcon(gemID))
        button:SetScript("OnEnter", function(self)
            if not self.itemID then
                return
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemID)
            GameTooltip:Show()
        end)
        button:Show()
        enhancementIndex = enhancementIndex + 1
    end
end

local function CreateCharacterRow(parent, index)
    local row = UI.Create("button", parent, {
        variant = "secondary",
        state = "default",
        height = CHARACTER_ROW_HEIGHT,
    })

    row.selectedBackground = row:CreateTexture(nil, "ARTWORK", nil, -8)
    row.selectedBackground:SetPoint("TOPLEFT", 1, -1)
    row.selectedBackground:SetPoint("BOTTOMRIGHT", -1, 1)
    row.selectedBackground:SetTexture(WHITE_TEXTURE)
    row.selectedBackground:SetVertexColor(unpack(Token("focusSurface")))
    row.selectedBackground:Hide()

    row.selectedAccent = row:CreateTexture(nil, "ARTWORK", nil, 7)
    row.selectedAccent:SetPoint("TOPLEFT", 1, -1)
    row.selectedAccent:SetPoint("BOTTOMLEFT", 1, 1)
    row.selectedAccent:SetWidth(3)
    row.selectedAccent:SetTexture(WHITE_TEXTURE)
    row.selectedAccent:SetVertexColor(unpack(Token("focus")))
    row.selectedAccent:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT", 8, 0)
    row.icon:SetSize(28, 28)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.textGroup = CreateFrame("Frame", nil, row)
    row.textGroup:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.textGroup:SetPoint("RIGHT", row, "RIGHT", -45, 0)
    row.textGroup:SetHeight(40)

    row.name = CreateText(row.textGroup, "body")
    row.name:SetPoint("TOPLEFT", row.textGroup, "TOPLEFT", 0, -1)
    row.name:SetPoint("TOPRIGHT", row.textGroup, "TOPRIGHT", 0, -1)
    row.name:SetJustifyH("LEFT")
    row.info = CreateText(row.textGroup, "caption")
    row.info:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
    row.info:SetPoint("RIGHT", row.textGroup, "RIGHT", 0, 0)
    row.info:SetJustifyH("LEFT")
    row.updatedAt = CreateText(row.textGroup, "caption")
    row.updatedAt:SetPoint("TOPLEFT", row.info, "BOTTOMLEFT", 0, -1)
    row.updatedAt:SetPoint("RIGHT", row.textGroup, "RIGHT", 0, 0)
    row.updatedAt:SetJustifyH("LEFT")
    row.itemLevel = CreateText(row, "numberCompact")
    SetTextColor(row.itemLevel, "forgeGold")
    row.itemLevel:SetPoint("RIGHT", -8, 0)
    row.itemLevel:SetWidth(38)
    row:SetScript("OnClick", function(self)
        if self.character then
            selectedCharacterName = self.character.name
            M.Refresh()
        end
    end)
    row.index = index
    return row
end

local function CreateDailyCard(parent)
    local card = CreateSurface(parent, "canvas")
    card:SetSize(286, 64)
    card.iconButton = CreateGameIcon(card, 38)
    card.iconButton:SetPoint("LEFT", 10, 0)
    card.name = CreateText(card, "heading")
    card.name:SetPoint("TOPLEFT", card.iconButton, "TOPRIGHT", 10, 0)
    card.meta = CreateText(card, "caption", L["每日重置"])
    card.meta:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -2)
    card.statusIcon = card:CreateTexture(nil, "ARTWORK")
    card.statusIcon:SetPoint("TOPLEFT", card.meta, "BOTTOMLEFT", 0, -2)
    card.statusIcon:SetSize(14, 14)
    card.status = CreateText(card, "label")
    card.status:SetPoint("LEFT", card.statusIcon, "RIGHT", 4, 0)
    card.status:SetPoint("RIGHT", -8, 0)
    card.status:SetJustifyH("LEFT")
    return card
end

local function CreateCooldownCell(parent)
    local cell = CreateSurface(parent, "canvas")
    cell:SetSize(302, 72)
    cell.iconButton = CreateGameIcon(cell, 38)
    cell.iconButton:SetPoint("LEFT", 10, 4)
    cell.name = CreateText(cell, "heading")
    cell.name:SetPoint("TOPLEFT", cell.iconButton, "TOPRIGHT", 10, -5)
    cell.name:SetPoint("RIGHT", -8, 0)
    cell.name:SetJustifyH("LEFT")
    cell.statusIcon = cell:CreateTexture(nil, "ARTWORK")
    cell.statusIcon:SetPoint("TOPLEFT", cell.name, "BOTTOMLEFT", 0, -6)
    cell.statusIcon:SetSize(15, 15)
    cell.status = CreateText(cell, "label")
    cell.status:SetPoint("LEFT", cell.statusIcon, "RIGHT", 4, 0)
    cell.status:SetPoint("RIGHT", -8, 0)
    cell.status:SetJustifyH("LEFT")
    cell.progress = cell:CreateTexture(nil, "BORDER")
    cell.progress:SetPoint("BOTTOMLEFT", cell.iconButton, "BOTTOMRIGHT", 10, 8)
    cell.progress:SetSize(218, 3)
    cell.progress:SetColorTexture(unpack(Token("borderSubtle")))
    cell.progressFill = cell:CreateTexture(nil, "ARTWORK")
    cell.progressFill:SetPoint("TOPLEFT", cell.progress, "TOPLEFT", 0, 0)
    cell.progressFill:SetPoint("BOTTOMLEFT", cell.progress, "BOTTOMLEFT", 0, 0)
    cell.progressFill:SetColorTexture(unpack(Token("warning")))
    cell.progress:Hide()
    cell.progressFill:Hide()
    return cell
end

local function CreateProfessionTrack(parent)
    local track = CreateSurface(parent, "panel")
    track:SetHeight(PROFESSION_TRACK_HEIGHT)
    track.accent = track:CreateTexture(nil, "ARTWORK")
    track.accent:SetPoint("TOPLEFT", 1, -1)
    track.accent:SetPoint("BOTTOMLEFT", 1, 1)
    track.accent:SetWidth(3)
    track.accent:SetColorTexture(unpack(Token("focus")))
    track.iconButton = CreateGameIcon(track, 42)
    track.iconButton:SetPoint("LEFT", 12, 0)
    track.name = CreateText(track, "title")
    track.name:SetPoint("TOPLEFT", track.iconButton, "TOPRIGHT", 12, -2)
    SetTextColor(track.name, "focusText")
    track.rank = CreateText(track, "number")
    track.rank:SetPoint("TOPLEFT", track.name, "BOTTOMLEFT", 0, -7)
    track.rank:SetJustifyH("LEFT")
    track.divider = UI.Create("divider", track, {
        color = "borderStrong",
        width = 1,
        height = 68,
    })
    track.divider:SetPoint("LEFT", 180, 0)
    track.cooldowns = {}
    for index = 1, PROFESSION_COOLDOWN_CELL_COUNT do
        local cell = CreateCooldownCell(track)
        if index == 1 then
            cell:SetPoint("LEFT", 194, 0)
        else
            cell:SetPoint("LEFT", 508, 0)
            cell:SetPoint("RIGHT", -12, 0)
        end
        track.cooldowns[index] = cell
    end
    track.empty = CreateText(track, "body")
    track.empty:SetPoint("LEFT", 204, 0)
    SetTextColor(track.empty, "textMuted")
    track.empty:Hide()
    return track
end

local function CreateResourceTile(parent, width)
    local tile = CreateFrame("Frame", nil, parent)
    tile:SetSize(width, 54)
    tile.iconButton = CreateGameIcon(tile, 38)
    tile.iconButton:SetPoint("LEFT", 0, 0)
    tile.name = CreateText(tile, "label")
    tile.name:SetPoint("TOPLEFT", tile.iconButton, "TOPRIGHT", 9, -2)
    tile.name:SetPoint("RIGHT", 0, 0)
    tile.name:SetJustifyH("LEFT")
    tile.value = CreateText(tile, "numberStrong")
    tile.value:SetPoint("TOPLEFT", tile.name, "BOTTOMLEFT", 0, -5)
    tile.value:SetJustifyH("LEFT")
    tile.detail = CreateText(tile, "body")
    tile.detail:SetPoint("BOTTOMLEFT", tile.value, "BOTTOMRIGHT", 2, 0)
    SetTextColor(tile.detail, "forgeGold")
    tile.detail:Hide()
    return tile
end

local function EnsureProfessionResourcesView()
    if frame.professionResourcesPanel then
        return
    end

    local panel = CreateSurface(frame.right, "panel")
    panel:SetPoint("TOPLEFT", 8, -50)
    panel:SetPoint("TOPRIGHT", -8, -50)
    panel:SetHeight(PROFESSION_PANEL_HEIGHT)
    panel:Hide()
    frame.professionResourcesPanel = panel

    local daily = CreateSurface(panel, "panel")
    daily:SetPoint("TOPLEFT", 0, 0)
    daily:SetPoint("TOPRIGHT", 0, 0)
    daily:SetHeight(130)
    local professionTitle = CreateText(daily, "heading", L["专业轨道"])
    professionTitle:SetPoint("TOPLEFT", 12, -9)
    local dailyTitle = CreateText(daily, "label", L["每日事项"])
    dailyTitle:SetPoint("TOPLEFT", 12, -35)
    local dailyReset = CreateText(daily, "caption", L["每日重置"])
    dailyReset:SetPoint("TOPRIGHT", -12, -35)
    frame.professionDailyCards = {}
    for index = 1, #DAILY_DEFINITIONS do
        local card = CreateDailyCard(daily)
        card:SetPoint("TOPLEFT", 12 + (index - 1) * 298, -60)
        frame.professionDailyCards[index] = card
    end

    frame.professionTracks = {}
    for index = 1, PROFESSION_TRACK_COUNT do
        local track = CreateProfessionTrack(panel)
        local offset = -PROFESSION_TRACK_TOP
            - (index - 1) * (PROFESSION_TRACK_HEIGHT + PROFESSION_TRACK_GAP)
        track:SetPoint("TOPLEFT", 0, offset)
        track:SetPoint("TOPRIGHT", 0, offset)
        frame.professionTracks[index] = track
    end
    frame.professionEmpty = CreateText(panel, "body", L["专业尚未记录"])
    frame.professionEmpty:SetPoint("CENTER", 0, 28)
    SetTextColor(frame.professionEmpty, "textMuted")
    frame.professionEmpty:Hide()

    local resources = CreateSurface(panel, "panel")
    resources:SetPoint("TOPLEFT", 0, -PROFESSION_RESOURCES_TOP)
    resources:SetPoint("TOPRIGHT", 0, -PROFESSION_RESOURCES_TOP)
    resources:SetHeight(PROFESSION_RESOURCES_HEIGHT)
    local resourceTitle = CreateText(resources, "heading", L["资源总览"])
    resourceTitle:SetPoint("TOPLEFT", 12, -9)
    frame.resourceUpdatedAt = CreateText(resources, "caption")
    frame.resourceUpdatedAt:SetPoint("TOPRIGHT", -12, -11)

    local resourceStrip = CreateSurface(resources, "canvas")
    resourceStrip:SetPoint("TOPLEFT", 12, -42)
    resourceStrip:SetPoint("TOPRIGHT", -12, -42)
    resourceStrip:SetHeight(78)
    frame.resourceStrip = resourceStrip

    frame.resourceGold = CreateResourceTile(resourceStrip, 150)
    frame.resourceGold:SetPoint("LEFT", 12, 0)
    frame.resourceEmbers = CreateResourceTile(resourceStrip, 150)
    frame.resourceEmbers:SetPoint("LEFT", frame.resourceGold, "RIGHT", 12, 0)
    frame.resourceShards = CreateResourceTile(resourceStrip, 150)
    frame.resourceShards:SetPoint("LEFT", frame.resourceEmbers, "RIGHT", 12, 0)
    frame.resourceFragments = CreateResourceTile(resourceStrip, 170)
    frame.resourceFragments:SetPoint("LEFT", frame.resourceShards, "RIGHT", 12, 0)

    frame.resourceUpgrades = CreateFrame("Frame", nil, resourceStrip)
    frame.resourceUpgrades:SetPoint("TOPLEFT", frame.resourceFragments, "TOPRIGHT", 12, 2)
    frame.resourceUpgrades:SetPoint("RIGHT", -10, 0)
    frame.resourceUpgrades:SetHeight(58)
    frame.resourceUpgrades.name = CreateText(frame.resourceUpgrades, "label", L["传说级升级材料"])
    frame.resourceUpgrades.name:SetPoint("TOPLEFT", 0, 0)
    SetTextColor(frame.resourceUpgrades.name, "forgeGold")
    frame.resourceUpgrades.icons = {}
    for index = 1, RESOURCE_UPGRADE_ICON_COUNT do
        local icon = CreateGameIcon(frame.resourceUpgrades, 30)
        icon:SetPoint("BOTTOMLEFT", (index - 1) * 36, 0)
        icon.count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        icon.count:SetPoint("BOTTOMRIGHT", -1, 1)
        icon.count:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
        frame.resourceUpgrades.icons[index] = icon
    end
    frame.resourceUpgrades.empty = CreateText(frame.resourceUpgrades, "number", "—")
    frame.resourceUpgrades.empty:SetPoint("BOTTOMLEFT", 0, 5)

    frame.resourceDividers = {}
    for index, tile in ipairs({
        frame.resourceGold,
        frame.resourceEmbers,
        frame.resourceShards,
        frame.resourceFragments,
    }) do
        local divider = UI.Create("divider", resourceStrip, {
            color = "borderSubtle",
            width = 1,
            height = 54,
        })
        divider:SetPoint("LEFT", tile, "RIGHT", 5, 0)
        frame.resourceDividers[index] = divider
    end
end

local function SetDailyCard(card, definition, character, learnedSkillLines)
    SetGameIcon(card.iconButton, definition.iconFileID)
    card.iconButton.spellID = nil
    card.iconButton.link = nil
    card.name:SetText(definition.name)
    local completed = character.questCompletions
        and character.questCompletions[definition.id] ~= nil
    local notApplicable = #(character.professions or {}) > 0 and definition.skillLineID
        and not learnedSkillLines[definition.skillLineID]
    if completed then
        card.meta:SetText(L["每日重置"])
        card.statusIcon:SetTexture(READY_STATUS_TEXTURE)
        card.statusIcon:SetVertexColor(unpack(Token("success")))
        card.status:SetText(L["已完成"])
        SetTextColor(card.status, "success")
    elseif notApplicable then
        card.meta:SetText(L["未学习珠宝加工"])
        card.statusIcon:SetTexture(UNKNOWN_STATUS_TEXTURE)
        card.statusIcon:SetVertexColor(unpack(Token("textMuted")))
        card.status:SetText(L["不适用"])
        SetTextColor(card.status, "textMuted")
    else
        card.meta:SetText(L["每日重置"])
        card.statusIcon:SetTexture(ALERT_STATUS_TEXTURE)
        card.statusIcon:SetVertexColor(1, 1, 1, 1)
        card.status:SetText(L["未完成"])
        SetTextColor(card.status, "warning")
    end
end

local function SetCooldownCell(cell, entry)
    if not entry then
        cell:Hide()
        return
    end
    SetGameIcon(cell.iconButton, GetSpellIcon(entry.spellID))
    cell.iconButton.spellID = entry.spellID
    cell.iconButton.link = nil
    cell.name:SetText(entry.name)
    cell.progress:Hide()
    cell.progressFill:Hide()
    if entry.state == "ready" then
        cell.statusIcon:SetTexture(READY_STATUS_TEXTURE)
        cell.statusIcon:SetVertexColor(unpack(Token("success")))
        cell.status:SetText(L["可制造"])
        SetTextColor(cell.status, "success")
    elseif entry.state == "cooling" then
        cell.statusIcon:SetTexture(WAITING_STATUS_TEXTURE)
        cell.statusIcon:SetVertexColor(unpack(Token("warning")))
        cell.status:SetText(L["冷却中"] .. " · " .. FormatProfessionCooldownTime(entry.remaining))
        SetTextColor(cell.status, "warning")
        if entry.duration and entry.duration > 0 then
            local ratio = max(0, min(1, entry.remaining / entry.duration))
            cell.progressFill:SetWidth(max(2, 218 * ratio))
            cell.progress:Show()
            cell.progressFill:Show()
        end
    else
        cell.statusIcon:SetTexture(UNKNOWN_STATUS_TEXTURE)
        cell.statusIcon:SetVertexColor(unpack(Token("textMuted")))
        cell.status:SetText(L["未扫描"])
        SetTextColor(cell.status, "textMuted")
    end
    cell:Show()
end

local function SetProfessionTrack(track, profession)
    if not profession then
        track:Hide()
        return
    end
    SetGameIcon(track.iconButton, profession.iconFileID)
    track.iconButton.spellID = nil
    track.iconButton.link = nil
    track.name:SetText(profession.name)
    track.rank:SetFormattedText("%d / %d", profession.rank or 0, profession.maxRank or 0)
    local entryCount = min(#profession.entries, PROFESSION_COOLDOWN_CELL_COUNT)
    track.empty:ClearAllPoints()
    if profession.hasTrackedCooldowns and not profession.scanned then
        for index = 1, PROFESSION_COOLDOWN_CELL_COUNT do
            track.cooldowns[index]:Hide()
        end
        track.empty:SetText(format(L["打开%s窗口刷新"], profession.name))
        track.empty:SetPoint("LEFT", 204, 0)
        track.empty:Show()
    else
        for index = 1, PROFESSION_COOLDOWN_CELL_COUNT do
            SetCooldownCell(track.cooldowns[index], profession.entries[index])
        end
    end
    if (profession.scanned and entryCount == 0)
        or not profession.hasTrackedCooldowns
    then
        track.empty:SetText(L["本专业无长 CD 项"])
        track.empty:SetPoint("LEFT", 204, 0)
        track.empty:Show()
    elseif profession.scanned then
        track.empty:Hide()
    end
    track:Show()
end

local function SetResourceTile(tile, iconFileID, name, value, link, atlas, borderToken, detail)
    SetGameIcon(tile.iconButton, iconFileID, atlas)
    tile.iconButton.link = link
    tile.iconButton.spellID = nil
    tile.name:SetText(name)
    tile.value:SetText(value)
    local hasDetail = detail ~= nil and detail ~= ""
    tile.detail:SetText(hasDetail and detail or "")
    tile.detail:SetShown(hasDetail)
    local color = GetItemDisplayColor(link)
    if color then
        tile.iconButton:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    else
        tile.iconButton:SetBackdropBorderColor(unpack(Token(borderToken or "borderStrong")))
    end
end

local function RenderProfessionResources(character)
    EnsureProfessionResourcesView()
    local learnedSkillLines = {}
    for _, profession in ipairs(character.professions or {}) do
        local skillLineID = tonumber(profession.skillLineID)
        if skillLineID then
            learnedSkillLines[skillLineID] = true
        end
    end
    for index, definition in ipairs(DAILY_DEFINITIONS) do
        SetDailyCard(frame.professionDailyCards[index], definition, character, learnedSkillLines)
    end

    local tracks = BG.GetRaidLockoutProfessionTracks
        and BG.GetRaidLockoutProfessionTracks(character) or {}
    for index = 1, PROFESSION_TRACK_COUNT do
        SetProfessionTrack(frame.professionTracks[index], tracks[index])
    end
    frame.professionEmpty:SetShown(#tracks == 0)

    local updatedAt = max(
        tonumber(character.resourcesUpdatedAt) or 0,
        tonumber(character.professionCooldownsUpdatedAt) or 0
    )
    frame.updatedAt:SetText(updatedAt > 0
        and (L["资源更新"] .. " " .. date("%m-%d %H:%M", updatedAt))
        or L["资源尚未记录"])
    frame.resourceUpdatedAt:SetText(updatedAt > 0
        and (L["更新"] .. " " .. date("%m-%d %H:%M", updatedAt)) or "")

    local money = tonumber(character.money)
    SetResourceTile(
        frame.resourceGold,
        GOLD_TEXTURE,
        L["金币"],
        money
            and FormatCompactNumber(floor(money / 10000))
            or "—",
        nil,
        GOLD_ATLAS,
        "forgeGold"
    )
    SetResourceTile(
        frame.resourceEmbers,
        character.titanEmberIconFileID,
        L["泰坦余烬"],
        FormatOptionalNumber(character.titanEmbers),
        nil,
        nil,
        "forgeGold",
        FormatWeeklyResourceDetail(
            character.titanEmbersEarnedThisWeek,
            character.titanEmbersWeeklyMax
        )
    )
    SetResourceTile(
        frame.resourceShards,
        character.titanShardIconFileID,
        L["泰坦碎片"],
        FormatOptionalNumber(character.titanShards),
        nil,
        nil,
        "focus"
    )
    local fragment = character.legendaryFragmentItems and character.legendaryFragmentItems[1]
    local fragmentValue = fragment and FormatCompactNumber(fragment.count)
        or (character.resourcesUpdatedAt and "0" or "—")
    if fragment and fragment.targetCount then
        fragmentValue = fragmentValue .. " / " .. FormatCompactNumber(fragment.targetCount)
    end
    SetResourceTile(
        frame.resourceFragments,
        fragment and fragment.iconFileID or 134888,
        L["橙武碎片"],
        fragmentValue,
        fragment and fragment.link,
        nil,
        "forgeGold"
    )

    local upgrades = character.legendaryUpgradeItems or {}
    frame.resourceUpgrades.empty:SetShown(#upgrades == 0)
    for index, icon in ipairs(frame.resourceUpgrades.icons) do
        local item = upgrades[index]
        if item then
            SetGameIcon(icon, item.iconFileID or GetItemIcon(item.link))
            icon.link = item.link
            icon.spellID = nil
            icon.count:SetText(item.count and item.count > 1 and item.count or "")
            local color = GetItemDisplayColor(item.link)
            if color then
                icon:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            else
                icon:SetBackdropBorderColor(unpack(Token("forgeGold")))
            end
            icon:Show()
        else
            icon:Hide()
        end
    end
end

local function CreateFrameContents(parent)
    frame = CreateFrame("Frame", "BGForgeCharacterDetailsFrame", parent, "BackdropTemplate")
    UI.Style(frame, "surface", { role = "canvas" })
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -58)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 12)
    frame:SetFrameLevel(parent:GetFrameLevel() + 2)
    frame:Hide()

    local header = CreateSurface(frame, "header")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(54)
    frame.header = header

    local back = UI.Create("button", header, {
        variant = "secondary",
        text = L["全角色总览"],
        width = 126,
        height = 32,
    })
    back:SetPoint("LEFT", 10, 0)
    back.icon = back:CreateTexture(nil, "ARTWORK")
    back.icon:SetPoint("LEFT", 7, 0)
    back.icon:SetSize(24, 24)
    back.icon:SetTexture(BACK_TEXTURE)
    local backText = back:GetFontString()
    backText:ClearAllPoints()
    backText:SetPoint("LEFT", 34, 0)
    backText:SetPoint("RIGHT", -8, 0)
    backText:SetJustifyH("LEFT")
    back:SetScript("OnClick", function()
        frame:Hide()
    end)

    local backDivider = UI.Create("divider", header, {
        color = "borderStrong",
        width = 1,
        height = 26,
    })
    backDivider:SetPoint("LEFT", back, "RIGHT", 12, 0)

    frame.characterTitle = CreateText(header, "title")
    frame.characterTitle:SetPoint("LEFT", backDivider, "RIGHT", 18, 0)
    frame.characterMeta = CreateText(header, "body")
    frame.characterMeta:SetPoint("LEFT", frame.characterTitle, "RIGHT", 18, 0)
    frame.updatedAt = CreateText(header, "caption")
    frame.updatedAt:SetPoint("RIGHT", -12, 0)
    frame.updatedAt:SetJustifyH("RIGHT")

    local left = CreateSurface(frame, "panel")
    left:SetPoint("TOPLEFT", 0, -62)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(270)
    frame.left = left
    local listTitle = CreateText(left, "heading", L["选择角色"])
    listTitle:SetPoint("TOPLEFT", 12, -10)
    frame.listCount = CreateText(left, "caption")
    frame.listCount:SetPoint("TOPRIGHT", -12, -12)

    frame.characterRows = {}
    for index = 1, MAX_CHARACTER_ROWS do
        local row = CreateCharacterRow(left, index)
        row:SetPoint("TOPLEFT", 8, -34 - (index - 1) * CHARACTER_ROW_STRIDE)
        row:SetPoint("RIGHT", -8, 0)
        frame.characterRows[index] = row
    end
    left:EnableMouseWheel(true)
    left:SetScript("OnMouseWheel", function(_, delta)
        local characters = GetCharacters()
        characterOffset = max(0, min(characterOffset - delta, max(0, #characters - MAX_CHARACTER_ROWS)))
        M.Refresh()
    end)

    local right = CreateSurface(frame, "panel")
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 8, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.right = right

    local tabs = CreateSurface(right, "header")
    tabs:SetPoint("TOPLEFT", 0, 0)
    tabs:SetPoint("TOPRIGHT", 0, 0)
    tabs:SetHeight(42)
    local tabLabels = { L["装备"], L["背包"], L["专业与资源"], L["进度"] }
    local previous
    frame.tabs = {}
    for index, label in ipairs(tabLabels) do
        local enabled = index <= 3
        local tab = CreateTab(tabs, label, index == 1, enabled)
        tab:SetWidth(index == 3 and 132 or 102)
        if previous then
            tab:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            tab:SetPoint("LEFT", 10, 0)
        end
        if index == 1 then
            tab:SetScript("OnClick", function()
                SetActiveView("equipment")
            end)
        elseif index == 2 then
            tab:SetScript("OnClick", function()
                SetActiveView("backpack")
            end)
        elseif index == 3 then
            tab:SetScript("OnClick", function()
                SetActiveView("professionResources")
            end)
        end
        frame.tabs[index] = tab
        previous = tab
    end

    local paperDoll = CreateSurface(right, "raised")
    paperDoll:SetPoint("TOPLEFT", 8, -50)
    paperDoll:SetPoint("BOTTOMLEFT", 8, 8)
    paperDoll:SetWidth(PAPER_DOLL_WIDTH)
    frame.paperDoll = paperDoll

    frame.paperDollName = CreateText(paperDoll, "heading")
    frame.paperDollName:SetPoint("TOPLEFT", 70, -10)
    frame.paperDollName:SetPoint("TOPRIGHT", -70, -10)
    frame.paperDollName:SetJustifyH("CENTER")
    frame.paperDollName:SetTextColor(1, 1, 1, 1)
    frame.paperDollMeta = CreateText(paperDoll, "body")
    frame.paperDollMeta:SetPoint("TOPLEFT", 70, -31)
    frame.paperDollMeta:SetPoint("TOPRIGHT", -70, -31)
    frame.paperDollMeta:SetJustifyH("CENTER")

    frame.paperDollButtons = {}
    for _, slotID in ipairs(PAPER_DOLL_LEFT) do
        frame.paperDollButtons[slotID] = CreateItemButton(paperDoll, 42)
    end
    for _, slotID in ipairs(PAPER_DOLL_RIGHT) do
        frame.paperDollButtons[slotID] = CreateItemButton(paperDoll, 42)
    end
    for _, slotID in ipairs(PAPER_DOLL_BOTTOM) do
        frame.paperDollButtons[slotID] = CreateItemButton(paperDoll, 42)
    end
    for index, slotID in ipairs(PAPER_DOLL_LEFT) do
        frame.paperDollButtons[slotID]:SetPoint("TOPLEFT", 16, -PAPER_DOLL_SLOT_TOP - (index - 1) * 48)
    end
    for index, slotID in ipairs(PAPER_DOLL_RIGHT) do
        frame.paperDollButtons[slotID]:SetPoint("TOPRIGHT", -16, -PAPER_DOLL_SLOT_TOP - (index - 1) * 48)
    end
    for index, slotID in ipairs(PAPER_DOLL_BOTTOM) do
        frame.paperDollButtons[slotID]:SetPoint("BOTTOM", (index - 2) * 52, 16)
    end

    local tablePanel = CreateSurface(right, "raised")
    tablePanel:SetPoint("TOPLEFT", paperDoll, "TOPRIGHT", 8, 0)
    tablePanel:SetPoint("BOTTOMRIGHT", -8, 8)
    frame.tablePanel = tablePanel
    local tableHeader = CreateSurface(tablePanel, "header")
    tableHeader:SetPoint("TOPLEFT", 0, 0)
    tableHeader:SetPoint("TOPRIGHT", 0, 0)
    tableHeader:SetHeight(28)
    local slotHeader = CreateText(tableHeader, "label", L["部位"])
    slotHeader:SetPoint("LEFT", 8, 0)
    local itemHeader = CreateText(tableHeader, "label", L["物品"])
    itemHeader:SetPoint("LEFT", 70, 0)
    local levelHeader = CreateText(tableHeader, "label", L["物品等级"])
    levelHeader:SetPoint("RIGHT", -126, 0)
    local enhancementHeader = CreateText(tableHeader, "label", L["附魔 / 宝石"])
    enhancementHeader:SetPoint("RIGHT", -10, 0)

    frame.equipmentRows = {}
    for index, definition in ipairs(SLOT_DEFINITIONS) do
        local row = CreateEquipmentRow(tablePanel, index)
        row:SetPoint("TOPLEFT", 0, -29 - (index - 1) * 28)
        row:SetPoint("RIGHT", 0, 0)
        frame.equipmentRows[index] = row
        definition.nativeSlotID = GetInventorySlotInfo and GetInventorySlotInfo(definition.token)
            or definition.id
    end

    frame:SetScript("OnHide", function()
        local callback = backCallback
        backCallback = nil
        GameTooltip:Hide()
        if not suppressBackCallback and callback then
            callback()
        end
    end)
    if frame.EnableKeyboard and frame.SetPropagateKeyboardInput then
        frame:EnableKeyboard(true)
        frame:SetPropagateKeyboardInput(true)
        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                self:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)
        frame:SetScript("OnKeyUp", function(self)
            self:SetPropagateKeyboardInput(true)
        end)
    end
    if UISpecialFrames then
        tinsert(UISpecialFrames, "BGForgeCharacterDetailsFrame")
    end
end

local function RenderCharacterList(characters)
    frame.listCount:SetFormattedText("%d " .. L["个角色"], #characters)
    characterOffset = min(characterOffset, max(0, #characters - MAX_CHARACTER_ROWS))
    for poolIndex, row in ipairs(frame.characterRows) do
        local character = characters[characterOffset + poolIndex]
        row.character = character
        if character then
            row.name:SetText("|c" .. GetClassColorHex(character.classFile) .. character.name .. "|r")
            row.info:SetFormattedText("%s %s", character.level or "—", GetClassName(character.classFile))
            local updatedAt = GetCharacterUpdatedAt(character)
            row.updatedAt:SetText(updatedAt
                and (L["更新"] .. "：" .. date("%m-%d %H:%M", updatedAt))
                or L["尚未记录"])
            row.itemLevel:SetText(character.itemLevel and floor(character.itemLevel + 0.5) or "—")
            local specIcon = GetCharacterSpecIcon(character)
            row.icon:SetTexture(specIcon or UNKNOWN_SPEC_TEXTURE)
            row.icon:SetDesaturated(not specIcon)
            UI.SetState(row, "default")
            local selected = character.name == selectedCharacterName
            row.selectedBackground:SetShown(selected)
            row.selectedAccent:SetShown(selected)
            row:Show()
        else
            row:Hide()
        end
    end
end

local function RenderEquipment(character)
    local equipment = character.details and character.details.equipment or nil
    local slots = equipment and equipment.slots or {}
    frame.updatedAt:SetText(equipment and equipment.updatedAt
        and (L["装备更新"] .. " " .. date("%m-%d %H:%M", equipment.updatedAt))
        or L["装备尚未记录"])
    for index, definition in ipairs(SLOT_DEFINITIONS) do
        local item = slots[definition.nativeSlotID or definition.id]
        SetEquipmentRow(frame.equipmentRows[index], definition, item)
        SetItemButton(frame.paperDollButtons[definition.id], item)
    end
end

local function EnsureBackpackView()
    if frame.backpackPanel then
        return
    end

    local panel = CreateSurface(frame.right, "raised")
    panel:SetPoint("TOPLEFT", 8, -50)
    panel:SetPoint("BOTTOMRIGHT", -8, 8)
    panel:Hide()
    frame.backpackPanel = panel

    local header = CreateSurface(panel, "header")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(42)
    local title = CreateText(header, "heading", L["背包"])
    title:SetPoint("LEFT", 12, 0)
    frame.backpackSummary = CreateText(header, "caption")
    frame.backpackSummary:SetPoint("RIGHT", -12, 0)
    frame.backpackSummary:SetJustifyH("RIGHT")

    frame.backpackEmpty = CreateText(panel, "body", L["背包尚未记录"])
    frame.backpackEmpty:SetPoint("CENTER", 0, 10)
    frame.backpackEmpty:SetJustifyH("CENTER")
    frame.backpackItemButtons = {}
    frame.backpackGroupHeaders = {}
end

local BACKPACK_GROUP_DEFINITIONS = {
    { id = "consumable", label = L["消耗品"] },
    { id = "miscellaneous", label = L["杂货"] },
    { id = "equipment", label = L["装备"] },
}

local function GetBackpackCategory(item)
    if IsBackpackEquipment(item) then
        return "equipment"
    end
    return tonumber(item and item.classID) == 0 and "consumable" or "miscellaneous"
end

local function BuildBackpackGroups(items)
    local itemsByGroup = {}
    for _, definition in ipairs(BACKPACK_GROUP_DEFINITIONS) do
        itemsByGroup[definition.id] = {}
    end
    for _, item in ipairs(items or {}) do
        local groupItems = itemsByGroup[GetBackpackCategory(item)]
        groupItems[#groupItems + 1] = item
    end

    local groups = {}
    for _, definition in ipairs(BACKPACK_GROUP_DEFINITIONS) do
        local groupItems = itemsByGroup[definition.id]
        if #groupItems > 0 then
            groups[#groups + 1] = {
                id = definition.id,
                label = definition.label,
                items = groupItems,
            }
        end
    end
    return groups
end

local function RenderBackpack(character)
    EnsureBackpackView()
    local backpack = character.details and character.details.backpack or nil
    local items = backpack and backpack.items or {}
    frame.updatedAt:SetText(backpack and backpack.updatedAt
        and (L["背包更新"] .. " " .. date("%m-%d %H:%M", backpack.updatedAt))
        or L["背包尚未记录"])
    if backpack then
        frame.backpackSummary:SetFormattedText(
            "%d / %d   %d %s",
            backpack.usedSlots or 0,
            backpack.totalSlots or 0,
            #items,
            L["物品"]
        )
    else
        frame.backpackSummary:SetText("")
    end
    frame.backpackEmpty:SetShown(not backpack or #items == 0)
    if backpack and #items == 0 then
        frame.backpackEmpty:SetText(L["背包为空"])
    else
        frame.backpackEmpty:SetText(L["背包尚未记录"])
    end

    local groups = BuildBackpackGroups(items)
    local buttonIndex = 0
    local yOffset = 52
    for groupIndex, group in ipairs(groups) do
        local groupHeader = frame.backpackGroupHeaders[groupIndex]
        if not groupHeader then
            groupHeader = CreateSurface(frame.backpackPanel, "header")
            groupHeader:SetHeight(BACKPACK_GROUP_HEADER_HEIGHT)
            groupHeader.text = CreateText(groupHeader, "heading")
            groupHeader.text:SetPoint("LEFT", 10, 0)
            SetTextColor(groupHeader.text, "forgeGold")
            frame.backpackGroupHeaders[groupIndex] = groupHeader
        end
        groupHeader:ClearAllPoints()
        groupHeader:SetPoint("TOPLEFT", 8, -yOffset)
        groupHeader:SetPoint("TOPRIGHT", -8, -yOffset)
        groupHeader.text:SetText(group.label)
        groupHeader:Show()
        yOffset = yOffset + BACKPACK_GROUP_HEADER_HEIGHT + BACKPACK_GROUP_GAP

        for groupItemIndex, item in ipairs(group.items) do
            buttonIndex = buttonIndex + 1
            local button = frame.backpackItemButtons[buttonIndex]
            if not button then
                button = CreateItemButton(frame.backpackPanel, BACKPACK_ITEM_SIZE, 1)
                button.level:ClearAllPoints()
                button.level:SetPoint("BOTTOMRIGHT", -2, 2)
                button.level:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                frame.backpackItemButtons[buttonIndex] = button
            end
            local column = (groupItemIndex - 1) % BACKPACK_COLUMNS
            local row = floor((groupItemIndex - 1) / BACKPACK_COLUMNS)
            button:ClearAllPoints()
            button:SetPoint(
                "TOPLEFT",
                14 + column * (BACKPACK_ITEM_SIZE + BACKPACK_ITEM_GAP),
                -yOffset - row * (BACKPACK_ITEM_SIZE + BACKPACK_ITEM_GAP)
            )
            SetBackpackItemButton(button, item)
            button:Show()
        end
        yOffset = yOffset
            + ceil(#group.items / BACKPACK_COLUMNS) * (BACKPACK_ITEM_SIZE + BACKPACK_ITEM_GAP)
            + BACKPACK_GROUP_GAP
    end
    for index = #groups + 1, #frame.backpackGroupHeaders do
        frame.backpackGroupHeaders[index]:Hide()
    end
    for index = buttonIndex + 1, #frame.backpackItemButtons do
        frame.backpackItemButtons[index]:Hide()
    end
end

SetActiveView = function(view)
    activeView = view == "backpack" and "backpack"
        or (view == "professionResources" and "professionResources" or "equipment")
    local showEquipment = activeView == "equipment"
    frame.paperDoll:SetShown(showEquipment)
    frame.tablePanel:SetShown(showEquipment)
    if activeView == "backpack" then
        EnsureBackpackView()
    elseif activeView == "professionResources" then
        EnsureProfessionResourcesView()
    end
    if frame.backpackPanel then
        frame.backpackPanel:SetShown(activeView == "backpack")
    end
    if frame.professionResourcesPanel then
        frame.professionResourcesPanel:SetShown(activeView == "professionResources")
    end
    UI.SetState(frame.tabs[1], showEquipment and "selected" or "default")
    UI.SetState(frame.tabs[2], activeView == "backpack" and "selected" or "default")
    UI.SetState(frame.tabs[3], activeView == "professionResources" and "selected" or "default")
    if frame:IsShown() then
        M.Refresh()
    end
end

function M.Refresh()
    if not frame or not frame:IsShown() then
        return
    end
    local characters = GetCharacters()
    local character = FindCharacter(characters, selectedCharacterName) or characters[1]
    if not character then
        M.Hide(false)
        return
    end
    selectedCharacterName = character.name
    RenderCharacterList(characters)

    frame.characterTitle:SetText(
        "|c" .. GetClassColorHex(character.classFile) .. character.name .. "|r"
    )
    local raceName = GetRaceName(character.raceID)
    local identity = (character.level and tostring(character.level) or "—")
        .. " " .. (raceName and (raceName .. " ") or "") .. GetClassName(character.classFile)
    local itemLevel = character.itemLevel and floor(character.itemLevel + 0.5)
    frame.characterMeta:SetText(identity .. (itemLevel and ("   " .. L["装等"] .. " " .. itemLevel) or ""))
    local classColorHex = GetClassColorHex(character.classFile)
    frame.paperDollName:SetText(character.name)
    frame.paperDollMeta:SetText(
        "|cffffd200" .. L["等级"] .. (character.level or "—") .. "|r  "
            .. "|c" .. classColorHex .. GetClassName(character.classFile) .. "|r"
    )
    if activeView == "backpack" then
        RenderBackpack(character)
    elseif activeView == "professionResources" then
        RenderProfessionResources(character)
    else
        RenderEquipment(character)
    end
end

function M.Show(parent, realmID, characterName, onBack)
    if not frame then
        CreateFrameContents(parent)
    elseif frame:GetParent() ~= parent then
        frame:SetParent(parent)
        frame:SetFrameLevel(parent:GetFrameLevel() + 2)
    end
    selectedRealmID = realmID
    selectedCharacterName = characterName
    backCallback = onBack
    suppressBackCallback = false
    if frame.SetPropagateKeyboardInput then
        frame:SetPropagateKeyboardInput(true)
    end
    frame:Show()
    SetActiveView("equipment")
end

function M.Hide(suppressBack)
    if not frame or not frame:IsShown() then
        return
    end
    suppressBackCallback = suppressBack and true or false
    frame:Hide()
    suppressBackCallback = false
end

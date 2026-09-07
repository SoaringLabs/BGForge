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
local CHARACTER_ROW_STRIDE = CHARACTER_ROW_HEIGHT
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
local PROGRESS_STATUS_TEXTURE = "Interface\\COMMON\\Indicator-Yellow"
local ALERT_STATUS_TEXTURE_PATH = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
local ALERT_STATUS_TEXTURE = (GetFileIDFromPath and GetFileIDFromPath(ALERT_STATUS_TEXTURE_PATH))
    or WAITING_STATUS_TEXTURE
local GOLD_TEXTURE = "Interface\\MoneyFrame\\UI-GoldIcon"
local GOLD_ATLAS = "auctionhouse-icon-coin-gold"
local DAILY_DEFINITIONS = {
    {
        id = "jewelcraftingDaily", name = L["珠宝日常"], professionName = L["珠宝加工"],
        iconFileID = 134071, skillLineID = 755,
    },
    {
        id = "cookingDaily", name = L["烹饪日常"], professionName = L["烹饪"],
        iconFileID = 133971, skillLineID = 185, secondarySkill = true, minLevel = 65, minRank = 350,
    },
    {
        id = "fishingDaily", name = L["钓鱼日常"], professionName = L["钓鱼"],
        iconFileID = 136245, skillLineID = 356, secondarySkill = true, minLevel = 70, minRank = 1,
    },
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
local PROGRESS_RAID_ROW_HEIGHT = 38
local PROGRESS_RAID_ROW_GAP = 2
local PROGRESS_BOSS_ROW_HEIGHT = 28
local PROGRESS_HEADER_HEIGHT = 46
local PROGRESS_WEEKLY_HEIGHT = 70
local PROGRESS_MAX_SEGMENTS = 20
-- “今日”页严格按已选中的三线战备舱效果图布局。比例来自目标图内容区：
-- 左 25.2%、中 39.6%、右侧使用剩余宽度；列间只保留 8px 设计系统间距。
-- 集中维护这些尺寸，避免各模块自行微调后逐渐偏离视觉基准。
local TODAY_PANEL_MIN_HEIGHT = 620
local TODAY_COLUMN_GAP = 8
local TODAY_LEFT_COLUMN_RATIO = 0.252
local TODAY_RAID_COLUMN_RATIO = 0.396
local TODAY_COLUMN_TITLE_HEIGHT = 38
local TODAY_SUMMARY_HEIGHT = 52
local TODAY_SECTION_TITLE_HEIGHT = 34
local TODAY_TASK_ROW_HEIGHT = 52
local TODAY_RESOURCE_ROW_HEIGHT = 37
local TODAY_RESOURCE_DETAIL_GAP = 4
local TODAY_PREVIEW_HEIGHT = 64
local TODAY_RAID_PROGRESS_WIDTH = 170
local TODAY_RAID_MAX_SEGMENTS = 20
local TODAY_RAID_ROW_HEIGHT = 40
local TODAY_RAID_ROW_STRIDE = TODAY_RAID_ROW_HEIGHT
local TODAY_RAID_COMPLETED_TOP = 72
local TODAY_RAID_GROUP_GAP = 32

local frame
local selectedRealmID
local selectedCharacterName
local backCallback
local suppressBackCallback
local characterOffset = 0
local activeView = "today"
local SetActiveView
local selectedProgressRaidID
local progressSelectionCharacterName
local renderedCharacters
local RenderCharacterList
local selectedEquipmentSlot = 1
local backpackFilter = "all"
local backpackSearch = ""

local function Text(key)
    local value = L[key]
    return value == true and key or value or key
end

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

-- 角色详情的页签是轻量导航：只用文字和底部焦点线表达状态。
-- 它故意不复用通用方块 Tab，避免在信息密集的详情页再增加一层边框。
local function CreateDetailTab(parent, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(42)
    button.label = CreateText(button, "body", text)
    button.label:SetAllPoints()
    button.label:SetJustifyH("CENTER")
    button.line = button:CreateTexture(nil, "ARTWORK")
    button.line:SetPoint("BOTTOMLEFT", 8, 0)
    button.line:SetPoint("BOTTOMRIGHT", -8, 0)
    button.line:SetHeight(2)
    button.line:SetColorTexture(unpack(Token("focus")))
    button.line:Hide()
    button:SetScript("OnEnter", function(self)
        if not self.selected then
            SetTextColor(self.label, "textPrimary")
        end
    end)
    button:SetScript("OnLeave", function(self)
        if not self.selected then
            SetTextColor(self.label, "textSecondary")
        end
    end)
    return button
end

local function SetDetailTabState(tab, selected)
    tab.selected = selected and true or false
    SetTextColor(tab.label, tab.selected and "focusText" or "textSecondary")
    tab.line:SetShown(tab.selected)
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
    button:SetScript("OnEnter", function(self)
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemID)
            GameTooltip:Show()
        elseif self.link then
            ShowItemTooltip(self, self.link)
        end
    end)
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
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", 66, 0)
    row.itemButton:ClearAllPoints()
    row.itemButton:SetPoint("LEFT", 94, 0)
    row.itemButton:SetPoint("RIGHT", -178, 0)
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
        if self.link and IsModifiedClick and IsModifiedClick() and HandleModifiedItemClick then
            HandleModifiedItemClick(self.link)
        else
            selectedEquipmentSlot = index
            M.Refresh()
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
    row.icon:SetTexture(item and (item.iconFileID or GetItemIcon(item.link)) or EMPTY_SLOT_TEXTURE)
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
    local enhancementIndex = 2
    if enchantID then
        local button = row.enhancements[1]
        button.link = item.link
        button.icon:SetTexture(ENCHANT_TEXTURE)
        button:Show()
    end
    for _, gemID in ipairs(gems) do
        local button = row.enhancements[enhancementIndex]
        if not button then
            break
        end
        button.itemID = gemID
        button.icon:SetTexture(GetItemIcon(gemID))
        button:Show()
        enhancementIndex = enhancementIndex + 1
    end
end

local function CreateCharacterRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    UI.Style(row, "surface", { role = "row" })
    row:SetHeight(CHARACTER_ROW_HEIGHT)
    -- 列表是一张连续的表，而不是一摞独立卡片。每行只画自己的底部分隔线，
    -- 避免相邻边框叠成粗线；选中态由底色和左侧焦点线表达。
    row:SetBackdropBorderColor(0, 0, 0, 0)
    row.divider = UI.Create("divider", row, {
        color = "borderSubtle",
        height = 1,
    })
    row.divider:SetPoint("BOTTOMLEFT", 0, 0)
    row.divider:SetPoint("BOTTOMRIGHT", 0, 0)

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
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(Token("hover")))
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(Token("row")))
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
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", 8, -50)
    panel:SetPoint("BOTTOMRIGHT", -8, 8)
    daily:ClearAllPoints()
    daily:SetPoint("TOPLEFT")
    daily:SetPoint("TOPRIGHT", panel, "TOP", 70, 0)
    daily:SetHeight(280)
    for index, card in ipairs(frame.professionDailyCards) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", 12, -60 - (index - 1) * 68)
        card:SetPoint("TOPRIGHT", -12, -60 - (index - 1) * 68)
    end
    for index, track in ipairs(frame.professionTracks) do
        track:ClearAllPoints()
        track:SetPoint("TOPLEFT", daily, "BOTTOMLEFT", 0, -8 - (index - 1) * 158)
        track:SetPoint("RIGHT", daily, "RIGHT")
        track:SetHeight(150)
        track.divider:Hide()
        track.iconButton:ClearAllPoints()
        track.iconButton:SetPoint("TOPLEFT", 12, -12)
        for i, cell in ipairs(track.cooldowns) do
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", 12 + (i - 1) * 260, -66)
            cell:SetWidth(250)
        end
        track.empty:ClearAllPoints()
        track.empty:SetPoint("TOPLEFT", 12, -78)
    end
    resources:ClearAllPoints()
    resources:SetPoint("TOPLEFT", daily, "TOPRIGHT", 12, 0)
    resources:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT")
    resourceStrip:ClearAllPoints()
    resourceStrip:SetPoint("TOPLEFT", 12, -48)
    resourceStrip:SetPoint("BOTTOMRIGHT", -12, 12)
    for index, tile in ipairs({ frame.resourceGold, frame.resourceEmbers,
        frame.resourceShards, frame.resourceFragments, frame.resourceUpgrades }) do
        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", 12, -12 - (index - 1) * 92)
        tile:SetPoint("RIGHT", -12, 0)
        if tile.detail then
            tile.detail:ClearAllPoints()
            tile.detail:SetPoint("TOPLEFT", tile.value, "BOTTOMLEFT", 0, -4)
        end
    end
    for _, divider in ipairs(frame.resourceDividers) do divider:Hide() end
end

local function GetDailyApplicability(character, definition, learnedSkillLines)
    if definition.secondarySkill then
        local skills = character.dailyProfessionSkills
        if type(skills) ~= "table" then
            return nil, L["资格尚未记录"], "unknown"
        end
        local skill = skills[definition.skillLineID]
        if type(skill) ~= "table" then
            return false, L["尚未学习"], "unlearned"
        end
        local level = tonumber(character.level)
        if definition.minLevel and (not level or level < definition.minLevel) then
            return false, format(L["角色等级需达到 %d"], definition.minLevel), "locked"
        end
        if definition.minRank and (tonumber(skill.rank) or 0) < definition.minRank then
            return false, format(L["技能需达到 %d"], definition.minRank), "locked"
        end
        return true, nil, "eligible"
    end

    local professionSnapshotKnown = character.dailyProfessionSkillsUpdatedAt
        or #(character.professions or {}) > 0
    if definition.skillLineID and professionSnapshotKnown
        and not learnedSkillLines[definition.skillLineID]
    then
        return false, L["未学习珠宝加工"], "unlearned"
    end
    return true, nil, "eligible"
end

local function SetDailyCard(card, definition, character, learnedSkillLines)
    SetGameIcon(card.iconButton, definition.iconFileID)
    card.iconButton.spellID = nil
    card.iconButton.link = nil
    card.name:SetText(definition.name)
    local completed = character.questCompletions
        and character.questCompletions[definition.id] ~= nil
    local applicable, ineligibleReason = GetDailyApplicability(character, definition, learnedSkillLines)
    if completed then
        card.meta:SetText(L["每日重置"])
        card.statusIcon:SetTexture(READY_STATUS_TEXTURE)
        card.statusIcon:SetVertexColor(unpack(Token("success")))
        card.status:SetText(L["已完成"])
        SetTextColor(card.status, "success")
    elseif applicable == nil then
        card.meta:SetText(ineligibleReason or L["资格尚未记录"])
        card.statusIcon:SetTexture(UNKNOWN_STATUS_TEXTURE)
        card.statusIcon:SetVertexColor(unpack(Token("textMuted")))
        card.status:SetText(L["未扫描"])
        SetTextColor(card.status, "textMuted")
    elseif not applicable then
        card.meta:SetText(ineligibleReason or L["资格尚未记录"])
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
        track.empty:SetPoint("TOPLEFT", 12, -78)
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
        track.empty:SetPoint("TOPLEFT", 12, -78)
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

local function FormatProgressResetAt(resetAt, now)
    resetAt = tonumber(resetAt)
    now = tonumber(now) or GetServerTime()
    if not resetAt or resetAt <= now then
        return "—"
    end
    return FormatProfessionCooldownTime(resetAt - now)
end

local function GetPrimaryProgressLockout(entry)
    local primary
    for _, lockout in ipairs(entry and entry.lockouts or {}) do
        local killedCount = tonumber(lockout.killedCount) or 0
        local primaryKilledCount = primary and (tonumber(primary.killedCount) or 0) or -1
        if not primary or killedCount > primaryKilledCount then
            primary = lockout
        end
    end
    return primary
end

local function GetProgressBosses(entry)
    local lockout = GetPrimaryProgressLockout(entry)
    if lockout and type(lockout.bosses) == "table" and #lockout.bosses > 0 then
        return lockout, lockout.bosses
    end

    local bosses = {}
    local killedCount = lockout and (tonumber(lockout.killedCount) or 0) or 0
    for index, boss in ipairs(entry and entry.bosses or {}) do
        bosses[index] = {
            name = boss.name,
            killed = index <= killedCount,
        }
    end
    return lockout, bosses
end

local function SetProgressSegment(segment, completed)
    local color = Token(completed and "success" or "borderStrong")
    segment:SetColorTexture(color[1], color[2], color[3], completed and 0.95 or 0.72)
end

local function CreateProgressRaidRow(parent)
    local row = UI.Create("button", parent, {
        variant = "quiet",
        state = "default",
        height = PROGRESS_RAID_ROW_HEIGHT,
    })
    row._bgforgeText:Hide()

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

    row.toggle = row:CreateTexture(nil, "ARTWORK")
    row.toggle:SetPoint("LEFT", 8, 0)
    row.toggle:SetSize(18, 18)
    row.toggle:SetTexCoord(0, 1, 0, 1)

    row.statusIcon = row:CreateTexture(nil, "ARTWORK")
    row.statusIcon:SetPoint("LEFT", 34, 0)
    row.statusIcon:SetSize(16, 16)

    row.name = CreateText(row, "body")
    row.name:SetPoint("LEFT", 58, 0)
    row.name:SetWidth(102)
    row.name:SetJustifyH("LEFT")

    row.segments = {}
    for index = 1, PROGRESS_MAX_SEGMENTS do
        local segment = row:CreateTexture(nil, "ARTWORK")
        segment:SetSize(14, 6)
        segment:SetPoint("LEFT", 174 + (index - 1) * 17, 0)
        segment:Hide()
        row.segments[index] = segment
    end

    -- 状态可能是中文，不能使用只覆盖数字字形的 number 字体。
    row.status = CreateText(row, "label")
    row.status:SetPoint("RIGHT", -12, 0)
    row.status:SetWidth(92)
    row.status:SetJustifyH("RIGHT")
    row.kills = CreateText(row, "number")
    row.kills:SetPoint("RIGHT", -108, 0)

    row:SetScript("OnClick", function(self)
        if not self.canExpand then
            return
        end
        if selectedProgressRaidID == self.raidID then
            selectedProgressRaidID = nil
        else
            selectedProgressRaidID = self.raidID
        end
        M.Refresh()
    end)
    return row
end

local function SetProgressRaidRow(row, entry, selected)
    local lockout, bosses = GetProgressBosses(entry)
    local killedCount = lockout and (tonumber(lockout.killedCount) or 0) or 0
    local encounterCount = lockout and (tonumber(lockout.numEncounters) or #bosses) or 0
    local complete = killedCount > 0

    row.raidID = entry.id
    row.canExpand = true
    row.name:SetText(entry.name)
    row.toggle:SetShown(row.canExpand)
    if row.canExpand then
        row.toggle:SetTexture(selected
            and "Interface\\Buttons\\UI-MinusButton-Up"
            or "Interface\\Buttons\\UI-PlusButton-Up")
        row.toggle:SetDesaturated(false)
        row.toggle:SetVertexColor(1, 1, 1, 1)
    end

    if not lockout or killedCount == 0 then
        row.statusIcon:SetTexture(PROGRESS_STATUS_TEXTURE)
        row.statusIcon:SetDesaturated(true)
        row.statusIcon:SetVertexColor(1, 1, 1, 1)
        row.statusIcon:SetAlpha(0.5)
        row.status:SetText(L["未开始"])
        SetTextColor(row.status, "textMuted")
    elseif complete then
        row.statusIcon:SetTexture(READY_STATUS_TEXTURE)
        row.statusIcon:SetDesaturated(false)
        row.statusIcon:SetVertexColor(unpack(Token("success")))
        row.statusIcon:SetAlpha(1)
        row.status:SetText(L["已完成"])
        SetTextColor(row.status, "success")
    else
        row.statusIcon:SetTexture(PROGRESS_STATUS_TEXTURE)
        row.statusIcon:SetDesaturated(false)
        row.statusIcon:SetVertexColor(1, 1, 1, 1)
        row.statusIcon:SetAlpha(1)
        row.status:SetFormattedText("%d/%d", killedCount, encounterCount)
        SetTextColor(row.status, "warning")
    end

    row.kills:SetText(lockout and format("%d/%d", killedCount, encounterCount) or "—")
    for _, segment in ipairs(row.segments) do segment:Hide() end

    UI.SetState(row, "default")
    row.selectedBackground:SetShown(selected)
    row.selectedAccent:SetShown(selected)
    row:Show()
    return lockout, bosses
end

local function CreateProgressBossRow(parent)
    local row = CreateSurface(parent, "row")
    row:SetHeight(PROGRESS_BOSS_ROW_HEIGHT)
    row.index = CreateText(row, "numberCompact")
    row.index:SetPoint("LEFT", 8, 0)
    row.index:SetWidth(24)
    row.index:SetJustifyH("RIGHT")
    row.statusIcon = row:CreateTexture(nil, "ARTWORK")
    row.statusIcon:SetPoint("LEFT", 42, 0)
    row.statusIcon:SetSize(14, 14)
    row.name = CreateText(row, "label")
    row.name:SetPoint("LEFT", row.statusIcon, "RIGHT", 7, 0)
    row.name:SetPoint("RIGHT", -104, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.status = CreateText(row, "label")
    row.status:SetPoint("RIGHT", -8, 0)
    row.status:SetWidth(88)
    row.status:SetJustifyH("RIGHT")
    return row
end

local function SetProgressBossRow(row, boss, index)
    row.index:SetText(index)
    row.name:SetText(boss.name or UNKNOWN)
    if boss.killed then
        row.statusIcon:SetTexture(READY_STATUS_TEXTURE)
        row.statusIcon:SetVertexColor(unpack(Token("success")))
        row.status:SetText(L["已击杀"])
        SetTextColor(row.status, "success")
    else
        row.statusIcon:SetTexture(UNKNOWN_STATUS_TEXTURE)
        row.statusIcon:SetVertexColor(unpack(Token("textMuted")))
        row.status:SetText(L["未击杀"])
        SetTextColor(row.status, "textMuted")
    end
    row:Show()
end

local function SetProgressBossPanel(panel, entry, lockout, bosses)
    if not entry then
        panel:Hide()
        return 0
    end

    panel.title:SetText(entry.name .. " · " .. L["首领进度"])
    if lockout then
        panel.summary:SetFormattedText(
            "%d/%d",
            tonumber(lockout.killedCount) or 0,
            tonumber(lockout.numEncounters) or #bosses
        )
    elseif #bosses > 0 then
        panel.summary:SetFormattedText("0/%d", #bosses)
    else
        panel.summary:SetText("—")
    end
    panel.empty:SetShown(#bosses == 0)
    local rowsPerColumn = #bosses
    for index = #panel.rows + 1, #bosses do
        panel.rows[index] = CreateProgressBossRow(panel)
    end
    for index, row in ipairs(panel.rows) do
        local boss = bosses[index]
        if boss then
            row:ClearAllPoints()
            local column = index > rowsPerColumn and 2 or 1
            local rowIndex = column == 1 and index or index - rowsPerColumn
            local top = -36 - (rowIndex - 1) * (PROGRESS_BOSS_ROW_HEIGHT + 2)
            if column == 1 then
                row:SetPoint("TOPLEFT", 12, top)
                row:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, top)
            else
                row:SetPoint("TOPLEFT", panel, "TOP", 4, top)
                row:SetPoint("TOPRIGHT", -12, top)
            end
            SetProgressBossRow(row, boss, index)
        else
            row:Hide()
        end
    end

    local height = #bosses > 0
        and (44 + rowsPerColumn * (PROGRESS_BOSS_ROW_HEIGHT + 2)) or 74
    panel:SetHeight(height)
    panel:Show()
    return height
end

local function CreateProgressWeeklyCell(parent)
    local cell = CreateSurface(parent, "row")
    cell:SetHeight(34)
    cell.statusIcon = cell:CreateTexture(nil, "ARTWORK")
    cell.statusIcon:SetPoint("LEFT", 10, 0)
    cell.statusIcon:SetSize(16, 16)
    cell.name = CreateText(cell, "body")
    cell.name:SetPoint("LEFT", cell.statusIcon, "RIGHT", 8, 0)
    cell.name:SetPoint("RIGHT", -106, 0)
    cell.name:SetJustifyH("LEFT")
    cell.status = CreateText(cell, "label")
    cell.status:SetPoint("RIGHT", -10, 0)
    cell.status:SetWidth(92)
    cell.status:SetJustifyH("RIGHT")
    return cell
end

local function SetProgressWeeklyCell(cell, entry)
    cell.name:SetText(entry.name)
    if entry.completed then
        cell.statusIcon:SetTexture(READY_STATUS_TEXTURE)
        cell.statusIcon:SetVertexColor(unpack(Token("success")))
        cell.status:SetText(L["已完成"])
        SetTextColor(cell.status, "success")
    else
        cell.statusIcon:SetTexture(ALERT_STATUS_TEXTURE)
        cell.statusIcon:SetVertexColor(1, 1, 1, 1)
        cell.status:SetText(L["未完成"])
        SetTextColor(cell.status, "warning")
    end
    cell:Show()
end

local function UpdateProgressScrollRange()
    if not frame.progressScroll or not frame.progressScrollBar then
        return
    end
    local viewportHeight = frame.progressScroll:GetHeight() or 0
    local maximum = max(0, (frame.progressContentHeight or 0) - viewportHeight)
    local scrollBar = frame.progressScrollBar
    scrollBar:SetMinMaxValues(0, maximum)
    scrollBar:SetValue(min(scrollBar:GetValue() or 0, maximum))
    scrollBar:SetShown(maximum > 0)
end

local function EnsureProgressView()
    if frame.progressPanel then
        return
    end

    local panel = CreateSurface(frame.right, "panel")
    panel:SetPoint("TOPLEFT", 8, -50)
    panel:SetPoint("BOTTOMRIGHT", -8, 8)
    panel:Hide()
    frame.progressPanel = panel

    local summary = CreateSurface(panel, "raised")
    summary:SetPoint("TOPLEFT", 0, 0)
    summary:SetPoint("TOPRIGHT", 0, 0)
    summary:SetHeight(PROGRESS_HEADER_HEIGHT)
    local summaryTitle = CreateText(summary, "heading", L["本周进度"])
    summaryTitle:SetPoint("LEFT", 12, 0)
    frame.progressSummary = CreateText(summary, "body")
    frame.progressSummary:SetPoint("LEFT", summaryTitle, "RIGHT", 18, 0)
    frame.progressReset = CreateText(summary, "body")
    frame.progressReset:SetPoint("RIGHT", -12, 0)
    frame.progressReset:SetJustifyH("RIGHT")
    SetTextColor(frame.progressReset, "focusText")

    local weekly = CreateSurface(panel, "raised")
    weekly:SetPoint("BOTTOMLEFT", 0, 0)
    weekly:SetPoint("BOTTOMRIGHT", 0, 0)
    weekly:SetHeight(PROGRESS_WEEKLY_HEIGHT)
    local weeklyTitle = CreateText(weekly, "heading", L["周常"])
    weeklyTitle:SetPoint("TOPLEFT", 10, -8)
    weekly.cells = {}
    for index = 1, 2 do
        local cell = CreateProgressWeeklyCell(weekly)
        if index == 1 then
            cell:SetPoint("TOPLEFT", 8, -29)
            cell:SetPoint("TOPRIGHT", weekly, "TOP", -4, -29)
        else
            cell:SetPoint("TOPLEFT", weekly, "TOP", 4, -29)
            cell:SetPoint("TOPRIGHT", -8, -29)
        end
        weekly.cells[index] = cell
    end
    frame.progressWeekly = weekly

    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", 0, -PROGRESS_HEADER_HEIGHT - 8)
    scroll:SetPoint("BOTTOMRIGHT", -16, PROGRESS_WEEKLY_HEIGHT + 8)
    scroll:EnableMouseWheel(true)
    frame.progressScroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    content:SetPoint("TOPLEFT")
    scroll:SetScrollChild(content)
    frame.progressScrollContent = content
    frame.progressRaidRows = {}

    local bossPanel = CreateSurface(panel, "panel")
    bossPanel.title = CreateText(bossPanel, "heading")
    bossPanel.title:SetPoint("TOPLEFT", 12, -10)
    bossPanel.summary = CreateText(bossPanel, "number")
    bossPanel.summary:SetPoint("TOPRIGHT", -12, -10)
    SetTextColor(bossPanel.summary, "warning")
    bossPanel.empty = CreateText(bossPanel, "body", L["暂无首领数据"])
    bossPanel.empty:SetPoint("TOPLEFT", 12, -40)
    SetTextColor(bossPanel.empty, "textMuted")
    bossPanel.rows = {}
    bossPanel:Hide()
    frame.progressBossPanel = bossPanel
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", 0, -PROGRESS_HEADER_HEIGHT - 8)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOM", 64, PROGRESS_WEEKLY_HEIGHT + 8)
    bossPanel:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 16, 0)
    bossPanel:SetPoint("RIGHT", panel, "RIGHT", -8, 0)

    local scrollBar = CreateFrame("Slider", nil, panel)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 2, -2)
    scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 2, 2)
    scrollBar:SetWidth(10)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(1)
    local track = scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOP", 0, 0)
    track:SetPoint("BOTTOM", 0, 0)
    track:SetWidth(2)
    track:SetColorTexture(unpack(Token("borderStrong")))
    scrollBar:SetThumbTexture(WHITE_TEXTURE)
    local thumb = scrollBar:GetThumbTexture()
    thumb:SetSize(8, 36)
    thumb:SetColorTexture(unpack(Token("focus")))
    scrollBar:SetScript("OnValueChanged", function(_, value)
        scroll:SetVerticalScroll(value)
    end)
    scrollBar:Hide()
    frame.progressScrollBar = scrollBar

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local minimum, maximum = scrollBar:GetMinMaxValues()
        local value = scrollBar:GetValue() - delta * (PROGRESS_RAID_ROW_HEIGHT * 2)
        scrollBar:SetValue(max(minimum, min(maximum, value)))
    end)
    scroll:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(max(1, width))
        UpdateProgressScrollRange()
    end)
end

local function RenderProgress(character)
    EnsureProgressView()
    local now = GetServerTime()
    local model = BG.GetRaidLockoutProgressModel
        and BG.GetRaidLockoutProgressModel(character, now) or nil
    if not model then
        return
    end
    local ordered, completed = {}, 0
    for _, entry in ipairs(model.raids) do
        ordered[#ordered + 1] = entry
        local lockout = GetPrimaryProgressLockout(entry)
        if lockout and (tonumber(lockout.killedCount) or 0) > 0 then completed = completed + 1 end
    end
    table.sort(ordered, function(a, b)
        local al, bl = GetPrimaryProgressLockout(a), GetPrimaryProgressLockout(b)
        local ac = al and (tonumber(al.killedCount) or 0) > 0 or false
        local bc = bl and (tonumber(bl.killedCount) or 0) > 0 or false
        if ac ~= bc then return not ac end
        return tostring(a.id) < tostring(b.id)
    end)
    model.raids = ordered

    frame.updatedAt:SetText(model.updatedAt > 0
        and (L["进度更新"] .. " " .. date("%m-%d %H:%M", model.updatedAt))
        or L["进度尚未记录"])
    frame.progressSummary:SetFormattedText(
        L["副本 %d/%d · 周常 %d/%d"],
        completed,
        #model.raids,
        model.weeklyCompleted,
        model.weeklyTotal
    )
    frame.progressReset:SetFormattedText(
        L["统一重置 %s"],
        FormatProgressResetAt(model.resetAt or model.weeklyResetAt, now)
    )

    if progressSelectionCharacterName ~= character.name then
        progressSelectionCharacterName = character.name
        selectedProgressRaidID = nil
        frame.progressScrollBar:SetValue(0)
    end

    local selectedEntry
    local selectedLockout
    local selectedBosses
    for _, entry in ipairs(model.raids) do
        if entry.id == selectedProgressRaidID then
            local lockout, bosses = GetProgressBosses(entry)
            selectedEntry = entry
            selectedLockout = lockout
            selectedBosses = bosses
            break
        end
    end

    for index = #frame.progressRaidRows + 1, #model.raids do
        frame.progressRaidRows[index] = CreateProgressRaidRow(frame.progressScrollContent)
    end

    local bossPanelHeight = SetProgressBossPanel(
        frame.progressBossPanel,
        selectedEntry,
        selectedLockout,
        selectedBosses or {}
    )
    local yOffset = 0
    for index, row in ipairs(frame.progressRaidRows) do
        local entry = model.raids[index]
        if entry then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -yOffset)
            row:SetPoint("TOPRIGHT", 0, -yOffset)
            SetProgressRaidRow(row, entry, entry.id == selectedProgressRaidID)
            yOffset = yOffset + PROGRESS_RAID_ROW_HEIGHT + PROGRESS_RAID_ROW_GAP
        else
            row:Hide()
        end
    end
    frame.progressContentHeight = max(1, yOffset)
    frame.progressScrollContent:SetHeight(frame.progressContentHeight)

    for index, cell in ipairs(frame.progressWeekly.cells) do
        local entry = model.weeklies[index]
        if entry then
            SetProgressWeeklyCell(cell, entry)
        else
            cell:Hide()
        end
    end
    UpdateProgressScrollRange()
end

local function CreateFrameContents(parent)
    frame = CreateFrame("Frame", "BGForgeCharacterDetailsFrame", parent, "BackdropTemplate")
    UI.Style(frame, "surface", { role = "canvas" })
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -58)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 12)
    frame:SetFrameLevel(parent:GetFrameLevel() + 2)
    frame:Hide()

    local header = CreateSurface(frame, "header")
    header:SetPoint("TOPLEFT", 228, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(82)
    -- Header 与下方内容区相邻时，只由内容区绘制共享分隔线。
    -- 否则两个 1px Backdrop 边框会分别向内绘制，看起来像一条粗线。
    header:SetBackdropBorderColor(0, 0, 0, 0)
    header.accent = header:CreateTexture(nil, "ARTWORK")
    header.accent:SetPoint("TOPLEFT", 0, -1)
    header.accent:SetPoint("BOTTOMLEFT", 0, 1)
    header.accent:SetWidth(3)
    header.accent:SetColorTexture(unpack(Token("focus")))
    frame.header = header

    local leftHeader = CreateSurface(frame, "header")
    leftHeader:SetPoint("TOPLEFT", 0, 0)
    leftHeader:SetWidth(220)
    leftHeader:SetHeight(54)
    leftHeader:SetBackdropBorderColor(0, 0, 0, 0)
    frame.leftHeader = leftHeader

    local back = UI.Create("button", leftHeader, {
        variant = "secondary",
        text = L["全角色总览"],
        width = 196,
        height = 32,
    })
    back:SetPoint("LEFT", 12, 0)
    frame.back = back
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

    frame.characterTitle = CreateText(header, "title")
    frame.portrait = CreateGameIcon(header, 54)
    frame.portrait:SetPoint("LEFT", 12, 0)
    frame.characterTitle:SetPoint("TOPLEFT", 80, -11)
    frame.characterMeta = CreateText(header, "body")
    frame.characterMeta:SetPoint("TOPLEFT", 80, -35)
    frame.updatedAt = CreateText(header, "caption")
    frame.updatedAt:SetPoint("TOPLEFT", 80, -58)
    frame.updatedAt:SetPoint("RIGHT", -12, 0)
    frame.updatedAt:SetJustifyH("LEFT")

    local left = CreateSurface(frame, "panel")
    left:SetPoint("TOPLEFT", leftHeader, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(220)
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
        local characters = renderedCharacters or GetCharacters()
        characterOffset = max(0, min(characterOffset - delta, max(0, #characters - MAX_CHARACTER_ROWS)))
        RenderCharacterList(characters)
    end)

    local right = CreateSurface(frame, "panel")
    right:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.right = right

    local tabs = CreateFrame("Frame", nil, right)
    tabs:SetPoint("TOPLEFT", 0, 0)
    tabs:SetPoint("TOPRIGHT", 0, 0)
    tabs:SetHeight(42)
    local tabsDivider = UI.Create("divider", tabs, {
        color = "borderSubtle",
        height = 1,
    })
    tabsDivider:SetPoint("BOTTOMLEFT", 0, 0)
    tabsDivider:SetPoint("BOTTOMRIGHT", 0, 0)
    local tabLabels = { L["装备"], L["背包"], L["专业与资源"], L["进度"] }
    local todayTab = CreateDetailTab(tabs, Text("今日"))
    todayTab:SetWidth(84)
    todayTab:SetPoint("LEFT", 8, 0)
    todayTab:SetScript("OnClick", function() SetActiveView("today") end)
    local previous = todayTab
    frame.tabs = {}
    frame.todayTab = todayTab
    for index, label in ipairs(tabLabels) do
        local tab = CreateDetailTab(tabs, label)
        tab:SetWidth(index == 3 and 132 or 102)
        if previous then
            tab:SetPoint("LEFT", previous, "RIGHT", 2, 0)
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
        elseif index == 4 then
            tab:SetScript("OnClick", function()
                SetActiveView("progress")
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
    paperDoll:Hide()
    tablePanel:ClearAllPoints()
    tablePanel:SetPoint("TOPLEFT", 8, -50)
    tablePanel:SetPoint("BOTTOMRIGHT", -258, 8)
    frame.equipmentInspector = CreateSurface(right, "panel")
    frame.equipmentInspector:SetPoint("TOPLEFT", tablePanel, "TOPRIGHT", 8, 0)
    frame.equipmentInspector:SetPoint("BOTTOMRIGHT", -8, 8)
    local inspectorTitle = CreateText(frame.equipmentInspector, "heading", Text("物品详情"))
    inspectorTitle:SetPoint("TOPLEFT", 12, -14)
    frame.inspectorIcon = CreateItemButton(frame.equipmentInspector, 56)
    frame.inspectorIcon:SetPoint("TOPLEFT", 12, -48)
    frame.inspectorName = CreateText(frame.equipmentInspector, "body")
    frame.inspectorName:SetPoint("TOPLEFT", 12, -118)
    frame.inspectorName:SetPoint("RIGHT", -12, 0)
    frame.inspectorMeta = CreateText(frame.equipmentInspector, "body")
    frame.inspectorMeta:SetPoint("TOPLEFT", 12, -168)
    frame.inspectorEnhancements = {}
    for i = 1, 5 do
        local icon = CreateEnhancementButton(frame.equipmentInspector)
        icon:SetSize(28, 28)
        icon:SetPoint("TOPLEFT", 12 + (i - 1) * 38, -214)
        frame.inspectorEnhancements[i] = icon
    end
    local tableHeader = CreateSurface(tablePanel, "header")
    tableHeader:SetPoint("TOPLEFT", 0, 0)
    tableHeader:SetPoint("TOPRIGHT", 0, 0)
    tableHeader:SetHeight(28)
    local slotHeader = CreateText(tableHeader, "label", L["部位"])
    slotHeader:SetPoint("LEFT", 8, 0)
    local itemHeader = CreateText(tableHeader, "label", L["物品"])
    itemHeader:SetPoint("LEFT", 94, 0)
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

RenderCharacterList = function(characters)
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
        local row = frame.equipmentRows[index]
        row:SetBackdropColor(unpack(Token(index == selectedEquipmentSlot and "focusSurface" or "panel")))
        if index == selectedEquipmentSlot then
            SetItemButton(frame.inspectorIcon, item)
            frame.inspectorName:SetText(item and item.link or Text("尚未记录"))
            frame.inspectorMeta:SetText(definition.label .. "  ·  " .. L["物品等级"] .. " "
                .. (item and item.itemLevel and floor(item.itemLevel + 0.5) or "—"))
            for i, icon in ipairs(frame.inspectorEnhancements) do
                local source = row.enhancements[i]
                icon.link, icon.itemID = source.link, source.itemID
                icon.icon:SetTexture(source.icon:GetTexture())
                icon:SetShown(source:IsShown())
            end
        end
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
    local search = CreateFrame("EditBox", nil, header, "InputBoxTemplate")
    search:SetSize(180, 24)
    search:SetPoint("LEFT", 64, 0)
    search:SetAutoFocus(false)
    search:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Text("搜索背包物品"))
        GameTooltip:Show()
    end)
    search:SetScript("OnLeave", function() GameTooltip:Hide() end)
    search:SetScript("OnTextChanged", function(self)
        backpackSearch = self:GetText() or ""
        M.Refresh()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    frame.backpackSearch = search
    local filters = { {"all", "全部"}, {"consumable", "消耗品"},
        {"miscellaneous", "杂货"}, {"equipment", "装备"} }
    frame.backpackFilters = {}
    for i, entry in ipairs(filters) do
        local key = entry[1]
        local tab = CreateTab(panel, Text(entry[2]), key == backpackFilter, true)
        tab:SetSize(78, 28)
        tab:SetPoint("TOPLEFT", 12 + (i - 1) * 84, -48)
        tab:SetScript("OnClick", function() backpackFilter = key; M.Refresh() end)
        frame.backpackFilters[key] = tab
    end
    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", 0, -86)
    scroll:SetPoint("BOTTOMRIGHT", -220, 8)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(max(0, min(max(0, content:GetHeight() - self:GetHeight()),
            self:GetVerticalScroll() - delta * 40)))
    end)
    frame.backpackScroll, frame.backpackContent = scroll, content
    frame.backpackInfo = CreateText(panel, "body")
    frame.backpackInfo:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 16, -12)
    frame.backpackInfo:SetPoint("RIGHT", -12, 0)
    frame.backpackInfo:SetJustifyH("LEFT")
    frame.backpackInfo:SetJustifyV("TOP")
    frame.backpackSelected = CreateText(panel, "body")
    frame.backpackSelected:SetPoint("TOPLEFT", frame.backpackInfo, "BOTTOMLEFT", 0, -36)
    frame.backpackSelected:SetPoint("RIGHT", -12, 0)
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

    local filtered = {}
    for _, item in ipairs(items) do
        local name = item.name or (item.link and GetItemInfo and GetItemInfo(item.link)) or item.link or ""
        if (backpackFilter == "all" or GetBackpackCategory(item) == backpackFilter)
            and string.find(string.lower(name), string.lower(backpackSearch), 1, true) then
            filtered[#filtered + 1] = item
        end
    end
    if backpack and #items > 0 then
        frame.backpackEmpty:SetShown(#filtered == 0)
        frame.backpackEmpty:SetText(Text("没有匹配的物品"))
    end
    for key, tab in pairs(frame.backpackFilters) do
        UI.SetState(tab, key == backpackFilter and "selected" or "default")
    end
    frame.backpackInfo:SetText(backpack and format("%s\n\n%d / %d\n\n%s %d\n\n%d %s",
        Text("背包"), backpack.usedSlots or 0, backpack.totalSlots or 0, Text("剩余格数"),
        max(0, (backpack.totalSlots or 0) - (backpack.usedSlots or 0)), #items, Text("种物品")) or Text("背包尚未记录"))
    frame.backpackSelected:SetText("")
    local groups = BuildBackpackGroups(filtered)
    local columns = max(1, floor((frame.backpackScroll:GetWidth() - 28) / (BACKPACK_ITEM_SIZE + BACKPACK_ITEM_GAP)))
    frame.backpackContent:SetWidth(max(1, frame.backpackScroll:GetWidth()))
    local buttonIndex = 0
    local yOffset = 0
    for groupIndex, group in ipairs(groups) do
        local groupHeader = frame.backpackGroupHeaders[groupIndex]
        if not groupHeader then
            groupHeader = CreateSurface(frame.backpackContent, "header")
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
                button = CreateItemButton(frame.backpackContent, BACKPACK_ITEM_SIZE, 1)
                button:HookScript("OnEnter", function(self)
                    frame.backpackSelected:SetText(self.link or "")
                end)
                button.level:ClearAllPoints()
                button.level:SetPoint("BOTTOMRIGHT", -2, 2)
                button.level:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                frame.backpackItemButtons[buttonIndex] = button
            end
            local column = (groupItemIndex - 1) % columns
            local row = floor((groupItemIndex - 1) / columns)
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
            + ceil(#group.items / columns) * (BACKPACK_ITEM_SIZE + BACKPACK_ITEM_GAP)
            + BACKPACK_GROUP_GAP
    end
    for index = #groups + 1, #frame.backpackGroupHeaders do
        frame.backpackGroupHeaders[index]:Hide()
    end
    for index = buttonIndex + 1, #frame.backpackItemButtons do
        frame.backpackItemButtons[index]:Hide()
    end
    frame.backpackContent:SetHeight(max(1, yOffset))
    frame.backpackScroll:SetVerticalScroll(min(frame.backpackScroll:GetVerticalScroll(),
        max(0, yOffset - frame.backpackScroll:GetHeight())))
end

local function CreateTodaySection(parent, title, metaRole)
    local section = CreateFrame("Frame", nil, parent)
    section.title = CreateText(section, "heading", title)
    section.title:SetPoint("TOPLEFT", 12, -9)
    section.meta = CreateText(section, metaRole or "caption")
    section.meta:SetPoint("TOPRIGHT", -12, -11)
    section.meta:SetJustifyH("RIGHT")
    section.divider = UI.Create("divider", section, {
        color = "borderSubtle",
        height = 1,
    })
    section.divider:SetPoint("BOTTOMLEFT", 0, 0)
    section.divider:SetPoint("BOTTOMRIGHT", 0, 0)
    return section
end

local function CreateTodayRow(parent)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    UI.Style(row, "surface", { role = "row" })
    row:SetBackdropBorderColor(0, 0, 0, 0)
    row:SetHeight(TODAY_TASK_ROW_HEIGHT)
    row.divider = UI.Create("divider", row, {
        color = "borderSubtle",
        height = 1,
    })
    row.divider:SetPoint("BOTTOMLEFT", 0, 0)
    row.divider:SetPoint("BOTTOMRIGHT", 0, 0)
    row.iconButton = CreateGameIcon(row, 32)
    row.iconButton:SetPoint("LEFT", 8, 0)
    row.name = CreateText(row, "body")
    row.name:SetPoint("TOPLEFT", row.iconButton, "TOPRIGHT", 9, -1)
    row.name:SetJustifyH("LEFT")
    row.detail = CreateText(row, "caption")
    row.detail:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    row.detail:SetJustifyH("LEFT")
    row.status = CreateText(row, "label")
    row.status:SetPoint("RIGHT", -48, 0)
    row.status:SetWidth(72)
    row.status:SetJustifyH("RIGHT")
    row.action = CreateText(row, "label", Text("查看"))
    row.action:SetPoint("RIGHT", -8, 0)
    row.action:SetWidth(34)
    row.action:SetJustifyH("RIGHT")
    SetTextColor(row.action, "focusText")
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(Token(self.interactive and "hover" or "panel")))
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(Token("panel")))
    end)
    return row
end

local function SetTodayRow(row, icon, name, detail, status, statusToken, view)
    SetGameIcon(row.iconButton, icon)
    row.iconButton.icon:SetDesaturated(false)
    row.iconButton:SetAlpha(1)
    row.name:SetText(name or "—")
    SetTextColor(row.name, "textPrimary")
    row.detail:SetText(detail or "")
    SetTextColor(row.detail, "textMuted")
    row.status:SetText(status or "")
    SetTextColor(row.status, statusToken or "textSecondary")
    row.view = view
    row.interactive = view ~= nil
    row.action:SetShown(view ~= nil)
    row:SetScript("OnClick", function(self)
        if self.view then SetActiveView(self.view) end
    end)
    row:Show()
end

local function SetTodayUnavailableRow(row, definition, detail, status)
    SetTodayRow(row, definition.iconFileID, definition.name, detail, status,
        "textMuted", nil)
    row.iconButton.icon:SetDesaturated(true)
    row.iconButton:SetAlpha(0.45)
    SetTextColor(row.name, "textMuted")
    SetTextColor(row.detail, "textDisabled")
end

local function CreateTodayRaidRow(parent)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    UI.Style(row, "surface", { role = "row" })
    row:SetBackdropBorderColor(0, 0, 0, 0)
    row:SetHeight(TODAY_RAID_ROW_HEIGHT)
    row.divider = UI.Create("divider", row, {
        color = "borderSubtle",
        height = 1,
    })
    row.divider:SetPoint("BOTTOMLEFT", 12, 0)
    row.divider:SetPoint("BOTTOMRIGHT", -12, 0)
    row.statusIcon = row:CreateTexture(nil, "ARTWORK")
    row.statusIcon:SetPoint("LEFT", 9, 0)
    row.statusIcon:SetSize(18, 18)
    row.statusIcon:SetTexCoord(0, 1, 0, 1)

    row.action = CreateText(row, "label", Text("查看"))
    row.action:SetPoint("RIGHT", -9, 0)
    SetTextColor(row.action, "focusText")
    row.kills = CreateText(row, "numberCompact")
    row.kills:SetPoint("RIGHT", -48, 0)
    row.kills:SetWidth(48)
    row.kills:SetJustifyH("RIGHT")

    row.progress = CreateFrame("Frame", nil, row)
    row.progress:SetPoint("RIGHT", -106, 0)
    row.progress:SetSize(TODAY_RAID_PROGRESS_WIDTH, 7)
    row.segments = {}
    for index = 1, TODAY_RAID_MAX_SEGMENTS do
        local segment = row.progress:CreateTexture(nil, "ARTWORK")
        segment:SetHeight(7)
        row.segments[index] = segment
    end

    row.name = CreateText(row, "body")
    row.name:SetPoint("LEFT", 36, 0)
    row.name:SetPoint("RIGHT", row.progress, "LEFT", -10, 0)
    row.name:SetJustifyH("LEFT")
    row.status = CreateText(row, "caption")
    -- 分组标题、状态图标和进度数字共同表达状态，不再为重复文案占一行。
    -- FontString 仍保留文本，供状态测试和辅助提示使用。
    row.status:Hide()
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(Token("hover")))
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(Token("panel")))
    end)
    row:SetScript("OnClick", function()
        SetActiveView("progress")
    end)
    return row
end

local function SetTodayRaidRow(row, entry)
    local lockout, bosses = GetProgressBosses(entry)
    local killedCount = lockout and (tonumber(lockout.killedCount) or 0) or 0
    local encounterCount = lockout and (tonumber(lockout.numEncounters) or #bosses) or #bosses
    encounterCount = max(encounterCount, #bosses)
    local completed = killedCount > 0

    row.name:SetText(entry.name or "—")
    row.status:SetText(completed and L["已完成"] or L["未开始"])
    SetTextColor(row.status, completed and "success" or "textMuted")
    row.statusIcon:SetTexture(completed and READY_STATUS_TEXTURE or WAITING_STATUS_TEXTURE)
    row.statusIcon:SetVertexColor(unpack(Token(completed and "success" or "textMuted")))
    row.kills:SetText(encounterCount > 0 and format("%d/%d", killedCount, encounterCount) or "—")
    SetTextColor(row.kills, completed and "success" or "textMuted")

    local segmentCount = min(encounterCount, TODAY_RAID_MAX_SEGMENTS)
    local segmentGap = segmentCount > 12 and 1 or 2
    local segmentWidth = segmentCount > 0
        and max(2, floor((TODAY_RAID_PROGRESS_WIDTH - (segmentCount - 1) * segmentGap) / segmentCount)) or 0
    local representedKills = encounterCount > TODAY_RAID_MAX_SEGMENTS
        and floor((killedCount / encounterCount) * segmentCount + 0.5) or killedCount
    for index, segment in ipairs(row.segments) do
        if index <= segmentCount then
            segment:ClearAllPoints()
            segment:SetPoint("LEFT", (index - 1) * (segmentWidth + segmentGap), 0)
            segment:SetWidth(segmentWidth)
            local boss = encounterCount <= TODAY_RAID_MAX_SEGMENTS and bosses[index] or nil
            local killed
            if boss then
                -- boss.killed=false 是有效的逐 Boss 结果，不能再回退到击杀总数。
                -- 否则前 killedCount 个未击杀 Boss 也会被错误点亮。
                killed = boss.killed and true or false
            else
                killed = index <= representedKills
            end
            SetProgressSegment(segment, killed)
            segment:Show()
        else
            segment:Hide()
        end
    end
    row.progress:SetShown(segmentCount > 0)
    row:Show()
end

local function CreateTodayResourceRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(TODAY_RESOURCE_ROW_HEIGHT)
    row.iconButton = CreateGameIcon(row, 26)
    row.iconButton:SetPoint("LEFT", 0, 0)
    row.name = CreateText(row, "body")
    row.name:SetPoint("LEFT", row.iconButton, "RIGHT", 9, 0)
    row.detail = CreateText(row, "number")
    row.detail:SetPoint("RIGHT", -72, 0)
    row.detail:SetJustifyH("RIGHT")
    row.value = CreateText(row, "number")
    row.value:SetPoint("RIGHT", 0, 0)
    row.value:SetWidth(66)
    row.value:SetJustifyH("RIGHT")
    return row
end

local function SetTodayPreviewHover(group, hovered)
    group:SetBackdropColor(unpack(Token(hovered and "hover" or "raised")))
    group.hoverAccent:SetShown(hovered)
end

local function CreateTodayPreview(parent, title, view)
    local group = CreateFrame("Button", nil, parent, "BackdropTemplate")
    UI.Style(group, "surface", { role = "raised" })
    -- 快捷入口用底色区分为两个可点击区域，不额外增加边框。
    -- 悬停时同时抬高底色并显示左侧焦点线，点击范围仍覆盖整块。
    group:SetBackdropBorderColor(0, 0, 0, 0)
    group:SetHeight(TODAY_PREVIEW_HEIGHT)
    group.hoverAccent = group:CreateTexture(nil, "ARTWORK")
    group.hoverAccent:SetPoint("TOPLEFT", 0, 0)
    group.hoverAccent:SetPoint("BOTTOMLEFT", 0, 0)
    group.hoverAccent:SetWidth(2)
    group.hoverAccent:SetTexture(WHITE_TEXTURE)
    group.hoverAccent:SetVertexColor(unpack(Token("focus")))
    group.hoverAccent:Hide()
    group.title = CreateText(group, "body", title)
    group.title:SetPoint("TOPLEFT", 10, -7)
    group.summary = CreateText(group, "caption")
    group.summary:SetPoint("TOPRIGHT", -10, -9)
    group.items = {}
    for index = 1, 5 do
        local button = CreateItemButton(group, 32, 1)
        button:SetPoint("BOTTOMLEFT", 10 + (index - 1) * 38, 5)
        button:HookScript("OnEnter", function() SetTodayPreviewHover(group, true) end)
        button:HookScript("OnLeave", function() SetTodayPreviewHover(group, false) end)
        group.items[index] = button
    end
    group.link = CreateText(group, "label", view == "equipment" and Text("查看装备") or Text("查看背包"))
    group.link:SetPoint("BOTTOMRIGHT", -10, 12)
    SetTextColor(group.link, "focusText")
    group:SetScript("OnEnter", function(self)
        SetTodayPreviewHover(self, true)
    end)
    group:SetScript("OnLeave", function(self)
        SetTodayPreviewHover(self, false)
    end)
    group:SetScript("OnClick", function() SetActiveView(view) end)
    return group
end

local function CreateTodayColumn(parent, title)
    local column = CreateSurface(parent, "panel")
    column.header = CreateFrame("Frame", nil, column)
    column.header:SetPoint("TOPLEFT", 0, 0)
    column.header:SetPoint("TOPRIGHT", 0, 0)
    column.header:SetHeight(TODAY_COLUMN_TITLE_HEIGHT)
    column.title = CreateText(column.header, "heading", title)
    column.title:SetPoint("LEFT", 12, 0)
    column.title:SetJustifyV("MIDDLE")
    column.meta = CreateText(column.header, "caption")
    column.meta:SetPoint("RIGHT", -12, 0)
    column.meta:SetJustifyH("RIGHT")
    column.meta:SetJustifyV("MIDDLE")
    column.headerDivider = UI.Create("divider", column, {
        color = "borderSubtle",
        height = 1,
    })
    column.headerDivider:SetPoint("BOTTOMLEFT", column.header, "BOTTOMLEFT", 12, 0)
    column.headerDivider:SetPoint("BOTTOMRIGHT", column.header, "BOTTOMRIGHT", -12, 0)
    return column
end

local function LayoutTodayColumns(panel, width)
    width = max(1, width or panel:GetWidth())
    local leftWidth = floor(width * TODAY_LEFT_COLUMN_RATIO + 0.5)
    local raidWidth = floor(width * TODAY_RAID_COLUMN_RATIO + 0.5)
    local minimumRightWidth = 260
    if width - leftWidth - raidWidth - TODAY_COLUMN_GAP * 2 < minimumRightWidth then
        local available = max(1, width - minimumRightWidth - TODAY_COLUMN_GAP * 2)
        leftWidth = floor(available * 0.39 + 0.5)
        raidWidth = available - leftWidth
    end
    panel.actionColumn:SetWidth(leftWidth)
    panel.raidSection:SetWidth(raidWidth)
end

local function EnsureTodayView()
    if frame.todayPanel then return end
    local scroll = CreateFrame("ScrollFrame", nil, frame.right)
    scroll:SetPoint("TOPLEFT", 8, -50)
    scroll:SetPoint("BOTTOMRIGHT", -8, 8)
    frame.todayScroll = scroll
    local panel = CreateFrame("Frame", nil, scroll)
    panel:SetSize(max(1, scroll:GetWidth()), TODAY_PANEL_MIN_HEIGHT)
    panel.requiredHeight = TODAY_PANEL_MIN_HEIGHT
    scroll:SetScrollChild(panel)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(max(0, min(max(0, panel:GetHeight() - self:GetHeight()),
            self:GetVerticalScroll() - delta * 42)))
    end)
    scroll:SetScript("OnSizeChanged", function(_, width, height)
        panel:SetWidth(max(1, width))
        panel:SetHeight(max(panel.requiredHeight or TODAY_PANEL_MIN_HEIGHT, height))
        LayoutTodayColumns(panel, width)
    end)
    frame.todayPanel = panel

    -- 仅三列容器保留 1px 外边框。模块和数据行通过单条分隔线组织，
    -- 不再叠加独立 Surface 边框。
    local actions = CreateTodayColumn(panel, Text("今日任务"))
    actions:SetPoint("TOPLEFT", 0, 0)
    actions:SetPoint("BOTTOMLEFT", 0, 0)
    panel.actionColumn = actions

    local raid = CreateTodayColumn(panel, Text("团队副本"))
    raid:SetPoint("TOPLEFT", actions, "TOPRIGHT", TODAY_COLUMN_GAP, 0)
    raid:SetPoint("BOTTOMLEFT", actions, "BOTTOMRIGHT", TODAY_COLUMN_GAP, 0)
    panel.raidSection = raid

    local operations = CreateTodayColumn(panel, Text("资源与快捷入口"))
    operations:SetPoint("TOPLEFT", raid, "TOPRIGHT", TODAY_COLUMN_GAP, 0)
    operations:SetPoint("BOTTOMRIGHT", 0, 0)
    panel.operationsColumn = operations

    local summary = CreateFrame("Frame", nil, actions)
    summary:SetPoint("TOPLEFT", 12, -TODAY_COLUMN_TITLE_HEIGHT)
    summary:SetPoint("TOPRIGHT", -12, -TODAY_COLUMN_TITLE_HEIGHT)
    summary:SetHeight(TODAY_SUMMARY_HEIGHT)
    summary.icon = summary:CreateTexture(nil, "ARTWORK")
    summary.icon:SetPoint("LEFT", 0, 0)
    summary.icon:SetSize(24, 24)
    summary.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_05")
    summary.icon:SetVertexColor(unpack(Token("textSecondary")))
    summary.count = CreateText(summary, "numberStrong")
    summary.count:SetPoint("LEFT", summary.icon, "RIGHT", 8, 0)
    SetTextColor(summary.count, "warning")
    summary.label = CreateText(summary, "body", Text("项待完成"))
    summary.label:SetPoint("LEFT", summary.count, "RIGHT", 7, 0)
    summary.weekly = CreateText(summary, "body")
    summary.weekly:SetPoint("RIGHT", 0, 0)
    summary.weekly:SetJustifyH("RIGHT")
    summary.weekly:Hide()
    summary.divider = UI.Create("divider", summary, {
        color = "borderSubtle",
        height = 1,
    })
    -- 这条线分隔的是完整的“今日任务”概览与下方每日任务模块，
    -- 因此抵消 summary 的 12px 内容内边距，贯穿整列而不是跟随文字缩进。
    summary.divider:SetPoint("BOTTOMLEFT", -12, 0)
    summary.divider:SetPoint("BOTTOMRIGHT", 12, 0)
    panel.todaySummary = summary

    panel.dailySection = CreateTodaySection(actions, Text("专业日常"), "heading")
    panel.dailySection:SetPoint("TOPLEFT", 0, -TODAY_COLUMN_TITLE_HEIGHT - TODAY_SUMMARY_HEIGHT)
    panel.dailySection:SetPoint("TOPRIGHT", 0, -TODAY_COLUMN_TITLE_HEIGHT - TODAY_SUMMARY_HEIGHT)
    panel.dailySection:SetHeight(204)
    panel.dailyRows = {}
    for index = 1, #DAILY_DEFINITIONS do
        local row = CreateTodayRow(panel.dailySection)
        row:SetPoint("TOPLEFT", 12, -TODAY_SECTION_TITLE_HEIGHT - (index - 1) * TODAY_TASK_ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", -12, -TODAY_SECTION_TITLE_HEIGHT - (index - 1) * TODAY_TASK_ROW_HEIGHT)
        -- 模块底部已有独立边界线，最后一个日常不再重复绘制行分隔线。
        row.divider:SetShown(index < #DAILY_DEFINITIONS)
        panel.dailyRows[index] = row
    end
    panel.weeklySection = CreateTodaySection(actions, Text("周常任务"), "heading")
    panel.weeklySection:SetPoint("TOPLEFT", panel.dailySection, "BOTTOMLEFT", 0, 0)
    panel.weeklySection:SetPoint("TOPRIGHT", panel.dailySection, "BOTTOMRIGHT", 0, 0)
    panel.weeklySection:SetHeight(148)
    panel.weeklyRows = {}
    for index = 1, 2 do
        local row = CreateTodayRow(panel.weeklySection)
        row:SetPoint("TOPLEFT", 12, -TODAY_SECTION_TITLE_HEIGHT - (index - 1) * TODAY_TASK_ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", -12, -TODAY_SECTION_TITLE_HEIGHT - (index - 1) * TODAY_TASK_ROW_HEIGHT)
        -- 周常与未开始团本共用等待状态语义。图标放在原 32px 图标槽中居中，
        -- 避免放大的黄色感叹号抢过任务名称。
        row.iconButton:Hide()
        row.iconButton:SetBackdropBorderColor(0, 0, 0, 0)
        row.weeklyStatusIcon = row:CreateTexture(nil, "ARTWORK")
        row.weeklyStatusIcon:SetPoint("CENTER", row.iconButton, "CENTER", 0, 0)
        row.weeklyStatusIcon:SetSize(18, 18)
        row.weeklyStatusIcon:SetTexCoord(0, 1, 0, 1)
        panel.weeklyRows[index] = row
    end
    panel.weeklySection.divider:Hide()

    panel.raidRows = {}
    panel.raidCompletedLabel = CreateText(raid, "heading", Text("已有进度"))
    panel.raidCompletedLabel:SetPoint("TOPLEFT", 12, -52)
    SetTextColor(panel.raidCompletedLabel, "success")
    panel.raidPendingLabel = CreateText(raid, "heading", Text("尚未开始"))
    panel.raidPendingLabel:SetPoint("TOPLEFT", 12, -340)
    SetTextColor(panel.raidPendingLabel, "textSecondary")

    panel.resourceSection = CreateTodaySection(operations, Text("资源总览"))
    panel.resourceSection:SetPoint("TOPLEFT", 0, -TODAY_COLUMN_TITLE_HEIGHT)
    panel.resourceSection:SetPoint("TOPRIGHT", 0, -TODAY_COLUMN_TITLE_HEIGHT)
    panel.resourceSection:SetHeight(230)
    panel.resourceRows = {}
    for index = 1, 5 do
        local row = CreateTodayResourceRow(panel.resourceSection)
        row:SetPoint("TOPLEFT", 12, -40 - (index - 1) * TODAY_RESOURCE_ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", -12, -40 - (index - 1) * TODAY_RESOURCE_ROW_HEIGHT)
        panel.resourceRows[index] = row
    end

    panel.professionSection = CreateTodaySection(operations, Text("专业技能"))
    panel.professionSection:SetPoint("TOPLEFT", panel.resourceSection, "BOTTOMLEFT", 0, 0)
    panel.professionSection:SetPoint("TOPRIGHT", panel.resourceSection, "BOTTOMRIGHT", 0, 0)
    panel.professionSection:SetHeight(142)
    panel.professionRows = {}
    for index = 1, PROFESSION_TRACK_COUNT do
        local row = CreateTodayRow(panel.professionSection)
        row:SetPoint("TOPLEFT", 12, -TODAY_SECTION_TITLE_HEIGHT - (index - 1) * TODAY_TASK_ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", -12, -TODAY_SECTION_TITLE_HEIGHT - (index - 1) * TODAY_TASK_ROW_HEIGHT)
        row.name:SetPoint("TOPRIGHT", row.status, "TOPLEFT", -8, -1)
        row.name:SetJustifyH("LEFT")
        row.detail:SetPoint("RIGHT", row.status, "LEFT", -8, 0)
        row.detail:SetJustifyH("LEFT")
        row.status:SetWidth(138)
        panel.professionRows[index] = row
    end

    panel.quickSection = CreateTodaySection(operations, Text("快速查看"))
    panel.quickSection:SetPoint("TOPLEFT", panel.professionSection, "BOTTOMLEFT", 0, 0)
    panel.quickSection:SetPoint("BOTTOMRIGHT", operations, "BOTTOMRIGHT", 0, 0)
    panel.quickSection.divider:Hide()
    panel.equipmentPreview = CreateTodayPreview(panel.quickSection, L["装备"], "equipment")
    panel.equipmentPreview:SetPoint("TOPLEFT", 12, -TODAY_SECTION_TITLE_HEIGHT)
    panel.equipmentPreview:SetPoint("TOPRIGHT", -12, -TODAY_SECTION_TITLE_HEIGHT)
    panel.backpackPreview = CreateTodayPreview(panel.quickSection, L["背包"], "backpack")
    panel.backpackPreview:SetPoint("TOPLEFT", panel.equipmentPreview, "BOTTOMLEFT", 0, -10)
    panel.backpackPreview:SetPoint("TOPRIGHT", panel.equipmentPreview, "BOTTOMRIGHT", 0, -10)

    LayoutTodayColumns(panel, scroll:GetWidth())
end

local function RenderToday(character)
    EnsureTodayView()
    local panel = frame.todayPanel
    local learned = {}
    for _, profession in ipairs(character.professions or {}) do
        if profession.skillLineID then learned[tonumber(profession.skillLineID)] = true end
    end
    local dailyEligibleCount = 0
    local dailyCompletedCount = 0
    local dailyIncompleteCount = 0
    for index, definition in ipairs(DAILY_DEFINITIONS) do
        local row = panel.dailyRows[index]
        local completed = character.questCompletions and character.questCompletions[definition.id] ~= nil
        local applicable, ineligibleReason, eligibilityState = GetDailyApplicability(
            character, definition, learned
        )
        if applicable then
            dailyEligibleCount = dailyEligibleCount + 1
            if completed then
                dailyCompletedCount = dailyCompletedCount + 1
            else
                dailyIncompleteCount = dailyIncompleteCount + 1
            end
            SetTodayRow(row, definition.iconFileID, definition.name, L["每日重置"],
                completed and L["已完成"] or L["未完成"],
                completed and "success" or "warning", "professionResources")
        elseif eligibilityState == "unlearned" then
            SetTodayUnavailableRow(row, definition,
                format(L["未学习%s"], definition.professionName or definition.name),
                L["未学习"])
        elseif eligibilityState == "locked" then
            SetTodayUnavailableRow(row, definition, ineligibleReason, L["暂不可做"])
        else
            SetTodayUnavailableRow(row, definition,
                ineligibleReason or L["资格尚未记录"], L["未扫描"])
        end
    end
    panel.dailySection.meta:SetFormattedText("%d/%d", dailyCompletedCount, dailyEligibleCount)

    local now = GetServerTime()
    local model = BG.GetRaidLockoutProgressModel and BG.GetRaidLockoutProgressModel(character, now)
        or { raids = {}, weeklies = {}, weeklyCompleted = 0, weeklyTotal = 0 }
    for index, row in ipairs(panel.weeklyRows) do
        local entry = model.weeklies[index]
        if entry then
            SetTodayRow(row, WAITING_STATUS_TEXTURE, entry.name, Text("每周重置"),
                entry.completed and L["已完成"] or L["未完成"],
                entry.completed and "success" or "warning", "progress")
            row.weeklyStatusIcon:SetTexture(entry.completed and READY_STATUS_TEXTURE or WAITING_STATUS_TEXTURE)
            row.weeklyStatusIcon:SetVertexColor(unpack(Token(entry.completed and "success" or "warning")))
        else
            row:Hide()
        end
    end
    panel.weeklySection.meta:SetFormattedText("%d/%d", model.weeklyCompleted or 0, model.weeklyTotal or 0)
    local weeklyIncompleteCount = max(0, (model.weeklyTotal or 0) - (model.weeklyCompleted or 0))
    panel.todaySummary.count:SetText(tostring(dailyIncompleteCount + weeklyIncompleteCount))

    local orderedRaids = {}
    for index, entry in ipairs(model.raids or {}) do
        orderedRaids[index] = entry
    end
    table.sort(orderedRaids, function(a, b)
        local aLockout = GetPrimaryProgressLockout(a)
        local bLockout = GetPrimaryProgressLockout(b)
        local aCompleted = aLockout and (tonumber(aLockout.killedCount) or 0) > 0 or false
        local bCompleted = bLockout and (tonumber(bLockout.killedCount) or 0) > 0 or false
        if aCompleted ~= bCompleted then return aCompleted end
        return tostring(a.id) < tostring(b.id)
    end)
    local completedCount = 0
    for _, entry in ipairs(orderedRaids) do
        local lockout = GetPrimaryProgressLockout(entry)
        if lockout and (tonumber(lockout.killedCount) or 0) > 0 then
            completedCount = completedCount + 1
        end
    end
    local pendingHeaderTop = completedCount > 0
        and (TODAY_RAID_COMPLETED_TOP + completedCount * TODAY_RAID_ROW_STRIDE + TODAY_RAID_GROUP_GAP)
        or TODAY_RAID_COMPLETED_TOP
    panel.raidCompletedLabel:SetShown(completedCount > 0)
    panel.raidPendingLabel:ClearAllPoints()
    panel.raidPendingLabel:SetPoint("TOPLEFT", 12, -pendingHeaderTop + 18)
    panel.raidPendingLabel:SetShown(completedCount < #orderedRaids)
    local completedIndex, pendingIndex = 0, 0
    for index, entry in ipairs(orderedRaids) do
        local row = panel.raidRows[index]
        if not row then
            row = CreateTodayRaidRow(panel.raidSection)
            panel.raidRows[index] = row
        end
        local lockout = GetPrimaryProgressLockout(entry)
        local completed = lockout and (tonumber(lockout.killedCount) or 0) > 0 or false
        local top
        if completed then
            completedIndex = completedIndex + 1
            top = TODAY_RAID_COMPLETED_TOP + (completedIndex - 1) * TODAY_RAID_ROW_STRIDE
        else
            pendingIndex = pendingIndex + 1
            top = pendingHeaderTop + (pendingIndex - 1) * TODAY_RAID_ROW_STRIDE
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 10, -top)
        row:SetPoint("TOPRIGHT", -10, -top)
        row.divider:ClearAllPoints()
        local groupBoundary = completed and completedIndex == completedCount
            and completedCount < #orderedRaids
        -- 分组边界与列标题下方的分隔线同宽：row 本身内缩 10px，
        -- 因此边界线只再内缩 2px；普通行仍保持原来的 12px 内容缩进。
        row.divider:SetPoint("BOTTOMLEFT", groupBoundary and 2 or 12, 0)
        row.divider:SetPoint("BOTTOMRIGHT", groupBoundary and -2 or -12, 0)
        SetTodayRaidRow(row, entry)
    end
    for index = #orderedRaids + 1, #panel.raidRows do panel.raidRows[index]:Hide() end
    panel.raidSection.meta:SetFormattedText(L["副本 %d/%d"],
        completedCount, #(model.raids or {}))
    panel.requiredHeight = max(TODAY_PANEL_MIN_HEIGHT,
        pendingHeaderTop + pendingIndex * TODAY_RAID_ROW_STRIDE + 12)
    panel:SetHeight(max(panel.requiredHeight, frame.todayScroll:GetHeight()))

    local resources = panel.resourceRows
    local fragment = character.legendaryFragmentItems and character.legendaryFragmentItems[1]
    local upgrades = character.legendaryUpgradeItems or {}
    local upgradeCount = 0
    for _, item in ipairs(upgrades) do upgradeCount = upgradeCount + (tonumber(item.count) or 1) end
    local resourceData = {
        { GOLD_TEXTURE, GOLD_ATLAS, L["金币"], character.money and FormatCompactNumber(floor(character.money / 10000)) or "—", "" },
        { character.titanEmberIconFileID, nil, L["泰坦余烬"], FormatOptionalNumber(character.titanEmbers),
            FormatWeeklyResourceDetail(character.titanEmbersEarnedThisWeek, character.titanEmbersWeeklyMax) or "" },
        { character.titanShardIconFileID, nil, L["泰坦碎片"], FormatOptionalNumber(character.titanShards), "" },
        { fragment and fragment.iconFileID or 134888, nil, L["橙武碎片"],
            fragment and FormatOptionalNumber(fragment.count) or (character.resourcesUpdatedAt and "0" or "—"), "" },
        { upgrades[1] and upgrades[1].iconFileID or UNKNOWN_SPEC_TEXTURE, nil, L["传说级升级材料"],
            #upgrades == 0 and "—" or FormatCompactNumber(upgradeCount), "" },
    }
    local emberEarned = tonumber(character.titanEmbersEarnedThisWeek)
    local emberMaximum = tonumber(character.titanEmbersWeeklyMax)
    local emberCapped = emberEarned and emberMaximum and emberMaximum > 0
        and emberEarned >= emberMaximum
    for index, data in ipairs(resourceData) do
        local row = resources[index]
        SetGameIcon(row.iconButton, data[1], data[2])
        row.name:SetText(data[3])
        row.value:SetText(data[4])
        row.detail:SetText(data[5])
        row.detail:ClearAllPoints()
        row.detail:SetPoint("RIGHT", row.value, "RIGHT",
            -row.value:GetStringWidth() - TODAY_RESOURCE_DETAIL_GAP, 0)
        SetTextColor(row.detail, index == 2 and data[5] ~= ""
            and (emberCapped and "danger" or "success") or "textMuted")
        SetTextColor(row.value, index <= 2 and "forgeGold" or "textPrimary")
    end
    local resourceUpdatedAt = max(tonumber(character.resourcesUpdatedAt) or 0,
        tonumber(character.professionCooldownsUpdatedAt) or 0)
    panel.resourceSection.meta:SetText("")
    -- 资源、专业、装备与背包的更新时间并不一致，列标题不再挂一个含义模糊的时间。
    -- 最新快照时间仍统一保留在角色头部。
    panel.operationsColumn.meta:SetText("")

    local tracks = BG.GetRaidLockoutProfessionTracks and BG.GetRaidLockoutProfessionTracks(character) or {}
    local visibleProfessionCount = min(#tracks, #panel.professionRows)
    for index, row in ipairs(panel.professionRows) do
        local track = tracks[index]
        if track then
            local status = L["本专业无长 CD 项"]
            local statusToken = "textMuted"
            if track.hasTrackedCooldowns and not track.scanned then
                status = format(L["打开%s窗口刷新"], track.name)
            elseif track.entries and #track.entries > 0 then
                local entry = track.entries[1]
                status = entry.state == "ready" and L["可制造"]
                    or entry.state == "cooling" and (L["冷却中"] .. " · " .. FormatProfessionCooldownTime(entry.remaining))
                    or L["未扫描"]
                statusToken = entry.state == "ready" and "success"
                    or entry.state == "cooling" and "warning" or "textMuted"
            end
            SetTodayRow(row, track.iconFileID, track.name,
                format("%d / %d", track.rank or 0, track.maxRank or 0), status, statusToken,
                "professionResources")
            -- 模块自身已有底部分隔线，最后一个专业不再重复画一条紧邻边框。
            row.divider:SetShown(index < visibleProfessionCount)
        else
            row:Hide()
            row.divider:Hide()
        end
    end

    local equipment = character.details and character.details.equipment
    local slots = equipment and equipment.slots or {}
    local equipmentItems = {}
    for _, definition in ipairs(SLOT_DEFINITIONS) do
        local item = slots[definition.nativeSlotID or definition.id]
        if item then equipmentItems[#equipmentItems + 1] = item end
    end
    for index, button in ipairs(panel.equipmentPreview.items) do
        SetItemButton(button, equipmentItems[index])
        button:SetShown(equipmentItems[index] ~= nil)
    end
    panel.equipmentPreview.summary:SetText(L["装等"] .. " "
        .. (character.itemLevel and floor(character.itemLevel + 0.5) or "—"))
    local backpack = character.details and character.details.backpack
    local bagItems = backpack and backpack.items or {}
    for index, button in ipairs(panel.backpackPreview.items) do
        SetBackpackItemButton(button, bagItems[index])
        button:SetShown(bagItems[index] ~= nil)
    end
    panel.backpackPreview.summary:SetText(backpack
        and format("%d/%d · %d %s", backpack.usedSlots or 0, backpack.totalSlots or 0,
            #bagItems, L["物品"]) or L["背包尚未记录"])

    local latest = max(tonumber(model.updatedAt) or 0, resourceUpdatedAt,
        equipment and tonumber(equipment.updatedAt) or 0,
        backpack and tonumber(backpack.updatedAt) or 0)
    frame.updatedAt:SetText(latest > 0 and (Text("数据快照") .. "：" .. date("%m-%d %H:%M", latest))
        or L["尚未记录"])
    frame.todayScroll:Show()
end

SetActiveView = function(view)
    local wasProgress = activeView == "progress"
    activeView = view == "backpack" and "backpack"
        or (view == "professionResources" and "professionResources")
        or (view == "today" and "today")
        or (view == "progress" and "progress" or "equipment")
    if activeView == "progress" and not wasProgress then
        selectedProgressRaidID = nil
        progressSelectionCharacterName = selectedCharacterName
    end
    local showEquipment = activeView == "equipment"
    frame.paperDoll:Hide()
    frame.equipmentInspector:SetShown(showEquipment)
    frame.tablePanel:SetShown(showEquipment)
    if activeView == "backpack" then
        EnsureBackpackView()
    elseif activeView == "professionResources" then
        EnsureProfessionResourcesView()
    elseif activeView == "progress" then
        EnsureProgressView()
    end
    if frame.backpackPanel then
        frame.backpackPanel:SetShown(activeView == "backpack")
    end
    if frame.professionResourcesPanel then
        frame.professionResourcesPanel:SetShown(activeView == "professionResources")
    end
    if frame.progressPanel then
        frame.progressPanel:SetShown(activeView == "progress")
    end
    if frame.todayPanel then frame.todayPanel:SetShown(activeView == "today") end
    if frame.todayScroll then frame.todayScroll:SetShown(activeView == "today") end
    SetDetailTabState(frame.todayTab, activeView == "today")
    SetDetailTabState(frame.tabs[1], showEquipment)
    SetDetailTabState(frame.tabs[2], activeView == "backpack")
    SetDetailTabState(frame.tabs[3], activeView == "professionResources")
    SetDetailTabState(frame.tabs[4], activeView == "progress")
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
    SetGameIcon(frame.portrait, GetCharacterSpecIcon(character) or UNKNOWN_SPEC_TEXTURE)
    renderedCharacters = characters
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
    if activeView == "today" then
        RenderToday(character)
    elseif activeView == "backpack" then
        RenderBackpack(character)
    elseif activeView == "professionResources" then
        RenderProfessionResources(character)
    elseif activeView == "progress" then
        RenderProgress(character)
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
    renderedCharacters = nil
    backCallback = onBack
    suppressBackCallback = false
    if frame.SetPropagateKeyboardInput then
        frame:SetPropagateKeyboardInput(true)
    end
    frame:Show()
    SetActiveView("today")
end

function M.Hide(suppressBack)
    if not frame or not frame:IsShown() then
        return
    end
    suppressBackCallback = suppressBack and true or false
    frame:Hide()
    suppressBackCallback = false
end

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
local PAPER_DOLL_DETAIL = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18 }
-- “装备”页严格使用已选中的经典纸娃娃构图：左右各八个贴边部位，
-- 三个武器位固定在底部，中央只承载当前选中物品。所有尺寸集中维护，
-- 避免实现时逐项微调而偏离效果图。
local PAPER_DOLL_PANEL_INSET = 8
local PAPER_DOLL_SLOT_SIZE = 44
local PAPER_DOLL_CONTENT_INSET = 12
local PAPER_DOLL_DETAIL_WIDTH = 520
local PAPER_DOLL_COLUMN_GAP = 12
local PAPER_DOLL_SIDE_WIDTH = 48
local PAPER_DOLL_SIDE_HEIGHT = 48
local PAPER_DOLL_SIDE_TOP = 16
local PAPER_DOLL_SIDE_STRIDE = 58
local PAPER_DOLL_BOTTOM_WIDTH = 104
local PAPER_DOLL_BOTTOM_HEIGHT = 72
local PAPER_DOLL_BOTTOM_GAP = 20
local PAPER_DOLL_BOTTOM_INSET = 16
local PAPER_DOLL_INSPECTOR_ICON_SIZE = 64
local PAPER_DOLL_ENHANCEMENT_SIZE = 28
local PAPER_DOLL_ENHANCEMENT_GAP = 8
local PAPER_DOLL_WATERMARK_SIZE = 240
local EQUIPMENT_DETAIL_HEADER_HEIGHT = 38
local EQUIPMENT_DETAIL_ROW_HEIGHT = 32
local EQUIPMENT_DETAIL_ENHANCEMENT_SIZE = 18
local EQUIPMENT_DETAIL_ENHANCEMENT_GAP = 4
local EQUIPMENT_DETAIL_ENHANCEMENT_LEFT = 406
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
-- “今日”的专业与资源区域只使用客户端可渲染资源：专业/日常的官方 fileID、
-- 货币与物品快照图标，以及 Blizzard 自带状态和金币纹理。
local READY_STATUS_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local WAITING_STATUS_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Waiting"
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

local function SetItemButton(button, item, emptyTexture)
    button.link = item and item.link or nil
    local icon = item and GetItemIcon(item.link)
    button.icon:SetTexture(icon or emptyTexture or EMPTY_SLOT_TEXTURE)
    button.icon:SetDesaturated(not icon)
    button.icon:SetAlpha(icon and 1 or 0.38)
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

local function GetItemDisplayName(item)
    if not item then
        return "—"
    end
    local name = item.link and GetItemInfo and GetItemInfo(item.link)
    return name or item.name or item.link or "—"
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

local function SelectEquipmentSlot(index, link)
    if link and IsModifiedClick and IsModifiedClick() and HandleModifiedItemClick then
        HandleModifiedItemClick(link)
        return
    end
    selectedEquipmentSlot = index
    M.Refresh()
end

local function SetPaperDollSlotHover(group, hovered)
    group.hoverBackground:SetShown(hovered)
end

local function CreatePaperDollSlot(parent, definition, index, orientation)
    local group = CreateFrame("Button", nil, parent)
    if orientation == "bottom" then
        group:SetSize(PAPER_DOLL_BOTTOM_WIDTH, PAPER_DOLL_BOTTOM_HEIGHT)
    else
        group:SetSize(PAPER_DOLL_SIDE_WIDTH, PAPER_DOLL_SIDE_HEIGHT)
    end
    group.definition = definition
    group.slotIndex = index

    -- 槽位之间不画行框；悬停只使用设计系统的填充色，保持整页是一张纸娃娃底板。
    group.hoverBackground = group:CreateTexture(nil, "BACKGROUND")
    group.hoverBackground:SetAllPoints()
    group.hoverBackground:SetColorTexture(unpack(Token("hover")))
    group.hoverBackground:Hide()

    group.itemButton = CreateItemButton(group, PAPER_DOLL_SLOT_SIZE)
    group.slotLabel = CreateText(group, "caption", definition.label)
    group.itemName = CreateText(group, "body")
    group.itemLevel = CreateText(group, "number")
    group.itemName:SetWordWrap(false)

    if orientation == "bottom" then
        group.slotLabel:SetPoint("TOPLEFT", 0, 0)
        group.slotLabel:SetPoint("TOPRIGHT", 0, 0)
        group.slotLabel:SetJustifyH("CENTER")
        group.itemButton:SetPoint("TOP", 0, -16)
        group.itemName:Hide()
        group.itemLevel:Hide()
    else
        group.itemButton:SetPoint("CENTER", 0, 0)
        group.slotLabel:Hide()
        group.itemName:Hide()
        group.itemLevel:Hide()
    end

    local function OnEnter()
        SetPaperDollSlotHover(group, true)
    end
    local function OnLeave()
        SetPaperDollSlotHover(group, false)
        GameTooltip:Hide()
    end
    local function OnClick()
        SelectEquipmentSlot(group.slotIndex, group.item and group.item.link)
    end
    group:SetScript("OnEnter", OnEnter)
    group:SetScript("OnLeave", OnLeave)
    group:SetScript("OnClick", OnClick)
    group.itemButton:SetScript("OnEnter", function(self)
        OnEnter()
        ShowItemTooltip(self, self.link)
    end)
    group.itemButton:SetScript("OnLeave", OnLeave)
    group.itemButton:SetScript("OnClick", OnClick)
    return group
end

local function SetPaperDollSlot(group, item)
    group.item = item
    SetItemButton(group.itemButton, item, group.definition.emptyTexture)
    group.itemName:SetText(GetItemDisplayName(item))
    group.itemLevel:SetText(item and item.itemLevel and floor(item.itemLevel + 0.5) or "—")
    if item then
        local color = GetItemDisplayColor(item.link)
        if color then
            group.itemName:SetTextColor(color.r, color.g, color.b, 1)
        else
            SetTextColor(group.itemName, "textPrimary")
        end
        SetTextColor(group.itemLevel, "textPrimary")
    else
        SetTextColor(group.itemName, "textMuted")
        SetTextColor(group.itemLevel, "textMuted")
    end
end

local function SetPaperDollInspector(definition, item)
    SetItemButton(frame.inspectorIcon, item, definition.emptyTexture)
    frame.inspectorName:SetText(item and GetItemDisplayName(item) or Text("尚未记录"))
    frame.inspectorMeta:SetText(definition.label .. "  ·  " .. L["物品等级"] .. " "
        .. (item and item.itemLevel and floor(item.itemLevel + 0.5) or "—"))

    local color = item and GetItemDisplayColor(item.link)
    if color then
        frame.inspectorName:SetTextColor(color.r, color.g, color.b, 1)
    else
        SetTextColor(frame.inspectorName, item and "textPrimary" or "textMuted")
    end

    for _, icon in ipairs(frame.inspectorEnhancements) do
        icon:Hide()
        icon.link = nil
        icon.itemID = nil
    end
    if not item then
        return
    end

    local visible = {}
    local enchantID, gems = ParseItemEnhancements(item.link)
    if enchantID then
        local icon = frame.inspectorEnhancements[1]
        icon.link = item.link
        icon.icon:SetTexture(ENCHANT_TEXTURE)
        visible[#visible + 1] = icon
    end
    local sourceIndex = 2
    for _, gemID in ipairs(gems) do
        local icon = frame.inspectorEnhancements[sourceIndex]
        if not icon then
            break
        end
        icon.itemID = gemID
        icon.icon:SetTexture(GetItemIcon(gemID))
        visible[#visible + 1] = icon
        sourceIndex = sourceIndex + 1
    end

    local totalWidth = #visible * PAPER_DOLL_ENHANCEMENT_SIZE
        + max(0, #visible - 1) * PAPER_DOLL_ENHANCEMENT_GAP
    for visibleIndex, icon in ipairs(visible) do
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", frame.paperDollStage, "CENTER",
            -totalWidth / 2 + (visibleIndex - 1)
                * (PAPER_DOLL_ENHANCEMENT_SIZE + PAPER_DOLL_ENHANCEMENT_GAP), -82)
        icon:Show()
    end
end

local function CreateEquipmentDetailRow(parent, definition, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(EQUIPMENT_DETAIL_ROW_HEIGHT)
    row.definition = definition
    row.slotIndex = index

    row.selectedBackground = row:CreateTexture(nil, "BACKGROUND")
    row.selectedBackground:SetAllPoints()
    row.selectedBackground:SetColorTexture(unpack(Token("focusSurfaceSubtle")))
    row.selectedBackground:Hide()
    row.hoverBackground = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.hoverBackground:SetAllPoints()
    row.hoverBackground:SetColorTexture(unpack(Token("hover")))
    row.hoverBackground:Hide()
    row.selectedAccent = row:CreateTexture(nil, "ARTWORK")
    row.selectedAccent:SetPoint("TOPLEFT", 0, -1)
    row.selectedAccent:SetPoint("BOTTOMLEFT", 0, 1)
    row.selectedAccent:SetWidth(2)
    row.selectedAccent:SetColorTexture(unpack(Token("focus")))
    row.selectedAccent:Hide()

    row.slot = CreateText(row, "label", definition.label)
    row.slot:SetPoint("LEFT", 8, 0)
    row.slot:SetWidth(46)
    row.slot:SetJustifyH("LEFT")
    row.itemLevel = CreateText(row, "number")
    row.itemLevel:SetPoint("LEFT", 58, 0)
    row.itemLevel:SetWidth(42)
    row.itemLevel:SetJustifyH("LEFT")
    row.itemName = CreateText(row, "body")
    row.itemName:SetPoint("LEFT", 104, 0)
    row.itemName:SetPoint("RIGHT", -118, 0)
    row.itemName:SetJustifyH("LEFT")
    row.itemName:SetWordWrap(false)

    row.enhancements = {}
    for enhancementIndex = 1, 5 do
        local icon = CreateEnhancementButton(row)
        icon:SetSize(EQUIPMENT_DETAIL_ENHANCEMENT_SIZE, EQUIPMENT_DETAIL_ENHANCEMENT_SIZE)
        icon:SetPoint("LEFT",
            EQUIPMENT_DETAIL_ENHANCEMENT_LEFT
                + (enhancementIndex - 1)
                    * (EQUIPMENT_DETAIL_ENHANCEMENT_SIZE + EQUIPMENT_DETAIL_ENHANCEMENT_GAP),
            0)
        icon:Hide()
        row.enhancements[enhancementIndex] = icon
    end

    row.divider = UI.Create("divider", row, {
        color = "borderSubtle",
        height = 1,
    })
    row.divider:SetPoint("BOTTOMLEFT", 0, 0)
    row.divider:SetPoint("BOTTOMRIGHT", 0, 0)

    row:SetScript("OnEnter", function(self)
        self.hoverBackground:Show()
        ShowItemTooltip(self, self.item and self.item.link)
    end)
    row:SetScript("OnLeave", function(self)
        self.hoverBackground:Hide()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        SelectEquipmentSlot(self.slotIndex, self.item and self.item.link)
    end)
    return row
end

local function SetEquipmentDetailRow(row, item, selected)
    row.item = item
    row.itemLevel:SetText(item and item.itemLevel and floor(item.itemLevel + 0.5) or "—")
    row.itemName:SetText(item and GetItemDisplayName(item) or Text("尚未记录"))
    row.selectedBackground:SetShown(selected)
    row.selectedAccent:SetShown(selected)

    local color = item and GetItemDisplayColor(item.link)
    if color then
        row.itemName:SetTextColor(color.r, color.g, color.b, 1)
        SetTextColor(row.slot, "focusText")
        SetTextColor(row.itemLevel, "textPrimary")
    else
        SetTextColor(row.itemName, "textMuted")
        SetTextColor(row.slot, "textMuted")
        SetTextColor(row.itemLevel, "textMuted")
    end

    for _, icon in ipairs(row.enhancements) do
        icon:Hide()
        icon.link = nil
        icon.itemID = nil
    end
    if not item then
        return
    end

    local enchantID, gems = ParseItemEnhancements(item.link)
    local enhancementIndex = 1
    if enchantID then
        local icon = row.enhancements[enhancementIndex]
        icon.link = item.link
        icon.icon:SetTexture(ENCHANT_TEXTURE)
        icon:Show()
        enhancementIndex = enhancementIndex + 1
    end
    for _, gemID in ipairs(gems) do
        local icon = row.enhancements[enhancementIndex]
        if not icon then
            break
        end
        icon.itemID = gemID
        icon.icon:SetTexture(GetItemIcon(gemID))
        icon:Show()
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
    local tabLabels = { L["装备"], L["背包"] }
    local todayTab = CreateDetailTab(tabs, Text("今日"))
    todayTab:SetWidth(84)
    todayTab:SetPoint("LEFT", 8, 0)
    todayTab:SetScript("OnClick", function() SetActiveView("today") end)
    local previous = todayTab
    frame.tabs = {}
    frame.todayTab = todayTab
    for index, label in ipairs(tabLabels) do
        local tab = CreateDetailTab(tabs, label)
        tab:SetWidth(102)
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
        end
        frame.tabs[index] = tab
        previous = tab
    end

    -- 装备页与“今日”三栏共用同一 panel 层级，避免切换页签时整块底色突然变亮。
    local paperDoll = CreateSurface(right, "panel")
    paperDoll:SetPoint("TOPLEFT", PAPER_DOLL_PANEL_INSET, -50)
    paperDoll:SetPoint("BOTTOMRIGHT", -PAPER_DOLL_PANEL_INSET, PAPER_DOLL_PANEL_INSET)
    frame.paperDoll = paperDoll

    local equipmentDetail = CreateFrame("Frame", nil, paperDoll)
    equipmentDetail:SetPoint("TOPRIGHT", -PAPER_DOLL_CONTENT_INSET, -PAPER_DOLL_CONTENT_INSET)
    equipmentDetail:SetPoint("BOTTOMRIGHT", -PAPER_DOLL_CONTENT_INSET, PAPER_DOLL_CONTENT_INSET)
    equipmentDetail:SetWidth(PAPER_DOLL_DETAIL_WIDTH)
    frame.equipmentDetail = equipmentDetail

    local paperDollStage = CreateFrame("Frame", nil, paperDoll)
    paperDollStage:SetPoint("TOPLEFT", PAPER_DOLL_CONTENT_INSET, -PAPER_DOLL_CONTENT_INSET)
    paperDollStage:SetPoint("BOTTOMLEFT", PAPER_DOLL_CONTENT_INSET, PAPER_DOLL_CONTENT_INSET)
    paperDollStage:SetPoint("TOPRIGHT", equipmentDetail, "TOPLEFT", -PAPER_DOLL_COLUMN_GAP, 0)
    paperDollStage:SetPoint("BOTTOMRIGHT", equipmentDetail, "BOTTOMLEFT", -PAPER_DOLL_COLUMN_GAP, 0)
    frame.paperDollStage = paperDollStage

    frame.equipmentDetailDivider = paperDoll:CreateTexture(nil, "ARTWORK")
    frame.equipmentDetailDivider:SetPoint("TOPLEFT", equipmentDetail, "TOPLEFT",
        -PAPER_DOLL_COLUMN_GAP / 2, 0)
    frame.equipmentDetailDivider:SetPoint("BOTTOMLEFT", equipmentDetail, "BOTTOMLEFT",
        -PAPER_DOLL_COLUMN_GAP / 2, 0)
    frame.equipmentDetailDivider:SetWidth(1)
    frame.equipmentDetailDivider:SetColorTexture(unpack(Token("borderSubtle")))

    local detailHeader = CreateFrame("Frame", nil, equipmentDetail)
    detailHeader:SetPoint("TOPLEFT", 0, 0)
    detailHeader:SetPoint("TOPRIGHT", 0, 0)
    detailHeader:SetHeight(EQUIPMENT_DETAIL_HEADER_HEIGHT)
    frame.equipmentDetailTitle = CreateText(detailHeader, "heading", Text("装备明细"))
    frame.equipmentDetailTitle:SetPoint("LEFT", 0, 0)
    frame.equipmentDetailSummary = CreateText(detailHeader, "number")
    frame.equipmentDetailSummary:SetPoint("RIGHT", 0, 0)
    frame.equipmentDetailSummary:SetJustifyH("RIGHT")
    local detailHeaderDivider = UI.Create("divider", detailHeader, {
        color = "borderSubtle",
        height = 1,
    })
    detailHeaderDivider:SetPoint("BOTTOMLEFT", 0, 0)
    detailHeaderDivider:SetPoint("BOTTOMRIGHT", 0, 0)

    frame.paperDollWatermark = paperDollStage:CreateTexture(nil, "BACKGROUND")
    frame.paperDollWatermark:SetPoint("CENTER", 0, 38)
    frame.paperDollWatermark:SetSize(PAPER_DOLL_WATERMARK_SIZE, PAPER_DOLL_WATERMARK_SIZE)
    frame.paperDollWatermark:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.paperDollWatermark:SetDesaturated(true)
    frame.paperDollWatermark:SetAlpha(0.055)

    frame.inspectorName = CreateText(paperDollStage, "heading")
    frame.inspectorName:SetPoint("CENTER", 0, 96)
    frame.inspectorName:SetWidth(300)
    frame.inspectorName:SetJustifyH("CENTER")
    frame.inspectorIcon = CreateItemButton(paperDollStage, PAPER_DOLL_INSPECTOR_ICON_SIZE)
    frame.inspectorIcon:SetPoint("CENTER", 0, 34)
    frame.inspectorMeta = CreateText(paperDollStage, "body")
    frame.inspectorMeta:SetPoint("CENTER", 0, -18)
    frame.inspectorMeta:SetWidth(300)
    frame.inspectorMeta:SetJustifyH("CENTER")
    frame.inspectorEnhancements = {}
    for i = 1, 5 do
        local icon = CreateEnhancementButton(paperDollStage)
        icon:SetSize(PAPER_DOLL_ENHANCEMENT_SIZE, PAPER_DOLL_ENHANCEMENT_SIZE)
        icon:Hide()
        frame.inspectorEnhancements[i] = icon
    end

    local definitionByID = {}
    for index, definition in ipairs(SLOT_DEFINITIONS) do
        local nativeSlotID, emptyTexture
        if GetInventorySlotInfo then
            nativeSlotID, emptyTexture = GetInventorySlotInfo(definition.token)
        end
        definition.nativeSlotID = nativeSlotID or definition.id
        definition.emptyTexture = emptyTexture or EMPTY_SLOT_TEXTURE
        definition.index = index
        definitionByID[definition.id] = definition
    end

    frame.paperDollSlotGroups = {}
    frame.paperDollButtons = {}
    for sideIndex, slotID in ipairs(PAPER_DOLL_LEFT) do
        local definition = definitionByID[slotID]
        local group = CreatePaperDollSlot(paperDollStage, definition, definition.index, "side")
        group:SetPoint("TOPLEFT", 0,
            -PAPER_DOLL_SIDE_TOP - (sideIndex - 1) * PAPER_DOLL_SIDE_STRIDE)
        frame.paperDollSlotGroups[slotID] = group
        frame.paperDollButtons[slotID] = group.itemButton
    end
    for sideIndex, slotID in ipairs(PAPER_DOLL_RIGHT) do
        local definition = definitionByID[slotID]
        local group = CreatePaperDollSlot(paperDollStage, definition, definition.index, "side")
        group:SetPoint("TOPRIGHT", 0,
            -PAPER_DOLL_SIDE_TOP - (sideIndex - 1) * PAPER_DOLL_SIDE_STRIDE)
        frame.paperDollSlotGroups[slotID] = group
        frame.paperDollButtons[slotID] = group.itemButton
    end
    for bottomIndex, slotID in ipairs(PAPER_DOLL_BOTTOM) do
        local definition = definitionByID[slotID]
        local group = CreatePaperDollSlot(paperDollStage, definition, definition.index, "bottom")
        group:SetPoint("BOTTOM", paperDollStage, "BOTTOM",
            (bottomIndex - 2) * (PAPER_DOLL_BOTTOM_WIDTH + PAPER_DOLL_BOTTOM_GAP),
            PAPER_DOLL_BOTTOM_INSET)
        frame.paperDollSlotGroups[slotID] = group
        frame.paperDollButtons[slotID] = group.itemButton
    end

    frame.equipmentDetailRows = {}
    for detailIndex, slotID in ipairs(PAPER_DOLL_DETAIL) do
        local definition = definitionByID[slotID]
        local row = CreateEquipmentDetailRow(equipmentDetail, definition, definition.index)
        row:SetPoint("TOPLEFT", detailHeader, "BOTTOMLEFT", 0,
            -(detailIndex - 1) * EQUIPMENT_DETAIL_ROW_HEIGHT)
        row:SetPoint("RIGHT", 0, 0)
        row.divider:SetShown(detailIndex < #PAPER_DOLL_DETAIL)
        frame.equipmentDetailRows[detailIndex] = row
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
    frame.paperDollWatermark:SetTexture(GetCharacterSpecIcon(character) or UNKNOWN_SPEC_TEXTURE)

    for index, definition in ipairs(SLOT_DEFINITIONS) do
        local item = slots[definition.nativeSlotID or definition.id]
        SetPaperDollSlot(frame.paperDollSlotGroups[definition.id], item)
        if index == selectedEquipmentSlot then
            SetPaperDollInspector(definition, item)
        end
    end
    frame.equipmentDetailSummary:SetText(L["装等"] .. " "
        .. (character.itemLevel and floor(character.itemLevel + 0.5) or "—"))
    for _, row in ipairs(frame.equipmentDetailRows) do
        local definition = row.definition
        local item = slots[definition.nativeSlotID or definition.id]
        SetEquipmentDetailRow(row, item, row.slotIndex == selectedEquipmentSlot)
    end
end

local function EnsureBackpackView()
    if frame.backpackPanel then
        return
    end

    -- 背包和“今日 / 装备”共用同一层 panel 底色；内部只保留承担层级作用的分割线，
    -- 不再用 header surface 和方块 Tab 叠出额外的框。
    local panel = CreateSurface(frame.right, "panel")
    panel:SetPoint("TOPLEFT", 8, -50)
    panel:SetPoint("BOTTOMRIGHT", -8, 8)
    panel:Hide()
    frame.backpackPanel = panel

    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(42)
    header.divider = header:CreateTexture(nil, "ARTWORK")
    header.divider:SetPoint("BOTTOMLEFT", 12, 0)
    header.divider:SetPoint("BOTTOMRIGHT", -12, 0)
    header.divider:SetHeight(1)
    header.divider:SetColorTexture(unpack(Token("borderSubtle")))
    frame.backpackHeader = header
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
        local tab = CreateDetailTab(panel, Text(entry[2]))
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
    frame.backpackInfoDivider = panel:CreateTexture(nil, "ARTWORK")
    frame.backpackInfoDivider:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 8, 0)
    frame.backpackInfoDivider:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 8, 0)
    frame.backpackInfoDivider:SetWidth(1)
    frame.backpackInfoDivider:SetColorTexture(unpack(Token("borderSubtle")))
    frame.backpackInfo = CreateText(panel, "body")
    frame.backpackInfo:SetPoint("TOPLEFT", frame.backpackInfoDivider, "TOPRIGHT", 12, -12)
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
        SetDetailTabState(tab, key == backpackFilter)
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
            groupHeader = CreateFrame("Frame", nil, frame.backpackContent)
            groupHeader:SetHeight(BACKPACK_GROUP_HEADER_HEIGHT)
            groupHeader.text = CreateText(groupHeader, "heading")
            groupHeader.text:SetPoint("LEFT", 10, 0)
            SetTextColor(groupHeader.text, "textPrimary")
            groupHeader.divider = groupHeader:CreateTexture(nil, "ARTWORK")
            groupHeader.divider:SetPoint("BOTTOMLEFT", 0, 0)
            groupHeader.divider:SetPoint("BOTTOMRIGHT", 0, 0)
            groupHeader.divider:SetHeight(1)
            groupHeader.divider:SetColorTexture(unpack(Token("borderSubtle")))
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
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
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

    row.kills = CreateText(row, "numberCompact")
    row.kills:SetPoint("RIGHT", -9, 0)
    row.kills:SetWidth(48)
    row.kills:SetJustifyH("RIGHT")

    row.progress = CreateFrame("Frame", nil, row)
    row.progress:SetPoint("RIGHT", -67, 0)
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
                completed and "success" or "warning", nil)
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
                entry.completed and "success" or "warning", nil)
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
                format("%d / %d", track.rank or 0, track.maxRank or 0), status, statusToken, nil)
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
    activeView = view == "backpack" and "backpack"
        or (view == "today" and "today" or "equipment")
    local showEquipment = activeView == "equipment"
    frame.paperDoll:SetShown(showEquipment)
    if activeView == "backpack" then
        EnsureBackpackView()
    end
    if frame.backpackPanel then
        frame.backpackPanel:SetShown(activeView == "backpack")
    end
    if frame.todayPanel then frame.todayPanel:SetShown(activeView == "today") end
    if frame.todayScroll then frame.todayScroll:SetShown(activeView == "today") end
    SetDetailTabState(frame.todayTab, activeView == "today")
    SetDetailTabState(frame.tabs[1], showEquipment)
    SetDetailTabState(frame.tabs[2], activeView == "backpack")
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
    if activeView == "today" then
        RenderToday(character)
    elseif activeView == "backpack" then
        RenderBackpack(character)
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

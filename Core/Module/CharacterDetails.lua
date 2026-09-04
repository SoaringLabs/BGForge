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
local BACKPACK_ITEM_SIZE = 42
local BACKPACK_ITEM_GAP = 8
local CHARACTER_ROW_HEIGHT = 56
local CHARACTER_ROW_STRIDE = 58
local MAX_CHARACTER_ROWS = 10
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local EMPTY_SLOT_TEXTURE = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local ENCHANT_TEXTURE = "Interface\\Icons\\Trade_Engraving"
local BACK_TEXTURE = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up"
local UNKNOWN_SPEC_TEXTURE = "Interface\\Icons\\INV_Misc_QuestionMark"

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

local function CreateTab(parent, text, selected, enabled)
    local button = UI.Create("tab", parent, {
        text = text,
        state = selected and "selected" or (enabled and "default" or "disabled"),
        height = 32,
    })
    button:SetEnabled(enabled)
    return button
end

local function CreateItemButton(parent, size)
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
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
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

local function SetBackpackItemButton(button, item)
    button.link = item and item.link or nil
    local icon = item and GetItemIcon(item.link)
    button.icon:SetTexture(icon or EMPTY_SLOT_TEXTURE)
    button.icon:SetDesaturated(not icon)
    button.level:SetText(item and item.itemLevel and floor(item.itemLevel + 0.5)
        or (item and item.count and item.count > 1 and item.count or ""))
    button.level:SetTextColor(1, 1, 1, 1)
    if item then
        local color = GetItemDisplayColor(item.link)
        if color then
            button:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            if item.itemLevel then
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
    row.itemLevel = CreateText(row, "number")
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
        local enabled = index <= 2
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

    for index, item in ipairs(items) do
        local button = frame.backpackItemButtons[index]
        if not button then
            button = CreateItemButton(frame.backpackPanel, BACKPACK_ITEM_SIZE)
            button.level:ClearAllPoints()
            button.level:SetPoint("BOTTOMRIGHT", -2, 2)
            button.level:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            local column = (index - 1) % BACKPACK_COLUMNS
            local row = floor((index - 1) / BACKPACK_COLUMNS)
            button:SetPoint(
                "TOPLEFT",
                14 + column * (BACKPACK_ITEM_SIZE + BACKPACK_ITEM_GAP),
                -56 - row * (BACKPACK_ITEM_SIZE + BACKPACK_ITEM_GAP)
            )
            frame.backpackItemButtons[index] = button
        end
        SetBackpackItemButton(button, item)
        button:Show()
    end
    for index = #items + 1, #frame.backpackItemButtons do
        frame.backpackItemButtons[index]:Hide()
    end
end

SetActiveView = function(view)
    activeView = view == "backpack" and "backpack" or "equipment"
    local showEquipment = activeView == "equipment"
    frame.paperDoll:SetShown(showEquipment)
    frame.tablePanel:SetShown(showEquipment)
    if activeView == "backpack" then
        EnsureBackpackView()
    end
    if frame.backpackPanel then
        frame.backpackPanel:SetShown(activeView == "backpack")
    end
    UI.SetState(frame.tabs[1], showEquipment and "selected" or "default")
    UI.SetState(frame.tabs[2], activeView == "backpack" and "selected" or "default")
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

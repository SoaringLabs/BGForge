if not BG.IsTitan then return end

local AddonName, ns = ...

local L = ns.L
local HopeMaxb = ns.HopeMaxb
local Wishlist = BG.Wishlist

if not Wishlist then return end

local SURFACE = { 0.018, 0.055, 0.065, 0.94 }
local SURFACE_RAISED = { 0.025, 0.085, 0.095, 0.96 }
local BORDER = { 0.42, 0.30, 0.13, 0.72 }
local GOLD = { 1.00, 0.63, 0.12 }
local CYAN = { 0.00, 0.75, 1.00 }
local MUTED = { 0.63, 0.67, 0.68 }
local WHITE = { 0.94, 0.96, 0.96 }
-- 沿用“全角色总览”的棕色语言，但拉开层级：选中更亮，悬停更暗。
local ITEM_SELECTED = { 0.36, 0.25, 0.06, 0.82 }
local ITEM_HOVER = { 0.28, 0.18, 0.05, 0.26 }

local ITEM_HEIGHT = 34
local ITEM_GAP = 6
local BOSS_ITEM_HEIGHT = 42
local SUMMARY_ITEM_HEIGHT = 42
local COLUMN_GAP = 10
local BOSS_ROW_HEIGHT = 36
local BOSS_DIRECTORY_GAP = 8
local BOSS_WORKBENCH_MIN_HEIGHT = 520

local tokenMetadata = {}
local pendingItemLoads = {}
local refreshScheduled
local classCatalog

local function SendFeedback(text)
    if BG.SendSystemMessage then
        BG.SendSystemMessage(text)
    else
        print(text)
    end
end

local function ScheduleRefresh()
    if refreshScheduled then return end
    refreshScheduled = true
    local function Run()
        refreshScheduled = nil
        Wishlist.Refresh()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, Run)
    elseif BG.After then
        BG.After(0.05, Run)
    else
        Run()
    end
end

local function GetClassCatalog()
    if classCatalog then return classCatalog end
    classCatalog = { byFile = {}, byName = {}, rank = {} }
    if not GetNumClasses or not GetClassInfo then return classCatalog end
    for index = 1, GetNumClasses() do
        local className, classFile = GetClassInfo(index)
        if className and classFile then
            local info = { name = className, file = classFile, rank = index }
            classCatalog.byFile[classFile] = info
            classCatalog.byName[className] = info
            classCatalog.rank[classFile] = index
        end
    end
    return classCatalog
end

local function GetAllowedClasses(itemID)
    local classes = {}
    local seen = {}
    if not ITEM_CLASSES_ALLOWED or not BG.Tooltip_SetItemByID or not BiaoGeTooltip then
        return classes
    end
    local catalog = GetClassCatalog()
    local matchText = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
    BG.Tooltip_SetItemByID(itemID)
    for lineIndex = 1, BiaoGeTooltip:NumLines() do
        local line = _G["BiaoGeTooltipTextLeft" .. lineIndex]
        local text = line and line:GetText()
        local allowedText = text and text:match(matchText)
        if allowedText then
            for className, info in pairs(catalog.byName) do
                if allowedText:find(className, 1, true) and not seen[info.file] then
                    seen[info.file] = true
                    table.insert(classes, info.file)
                end
            end
            break
        end
    end
    table.sort(classes, function(left, right)
        return (catalog.rank[left] or 99) < (catalog.rank[right] or 99)
    end)
    return classes
end

local function QueueMetadataLoad(FB, sourceItemID, targetItemID)
    if not BG.OnItemLoad then return end
    local key = FB .. ":" .. sourceItemID .. ":" .. targetItemID
    if pendingItemLoads[key] then return end
    pendingItemLoads[key] = true
    BG.OnItemLoad(targetItemID):ContinueOnItemLoad(function()
        pendingItemLoads[key] = nil
        if tokenMetadata[FB] then
            tokenMetadata[FB][sourceItemID] = nil
        end
        ScheduleRefresh()
    end)
end

local function ResolveTokenMetadata(FB, sourceItemID)
    tokenMetadata[FB] = tokenMetadata[FB] or {}
    if tokenMetadata[FB][sourceItemID] then
        return tokenMetadata[FB][sourceItemID]
    end

    local targets = BG.Loot[FB] and BG.Loot[FB].ExchangeItems and
        BG.Loot[FB].ExchangeItems[sourceItemID]
    if not targets then return end

    local isClassSet
    local classes = {}
    local classSeen = {}
    local equipLoc
    local waiting
    for _, targetItemID in ipairs(targets) do
        local name, _, _, _, _, _, _, _, targetEquipLoc, _, _, _, _, _, _, setID = GetItemInfo(targetItemID)
        if not name then
            waiting = true
            QueueMetadataLoad(FB, sourceItemID, targetItemID)
        else
            if setID then
                isClassSet = true
                for _, classFile in ipairs(GetAllowedClasses(targetItemID)) do
                    if not classSeen[classFile] then
                        classSeen[classFile] = true
                        table.insert(classes, classFile)
                    end
                end
            end
            if targetEquipLoc and targetEquipLoc ~= "" then
                if not equipLoc then
                    equipLoc = targetEquipLoc
                elseif equipLoc ~= targetEquipLoc then
                    equipLoc = nil
                end
            end
        end
    end
    if waiting then return end

    local catalog = GetClassCatalog()
    table.sort(classes, function(left, right)
        return (catalog.rank[left] or 99) < (catalog.rank[right] or 99)
    end)
    local metadata = {
        isClassSet = isClassSet and #classes > 0 or false,
        classes = classes,
        equipLoc = equipLoc,
        targetCount = #targets,
    }
    tokenMetadata[FB][sourceItemID] = metadata
    return metadata
end

local function ContainsClass(classes, classFile)
    for _, candidate in ipairs(classes or {}) do
        if candidate == classFile then return true end
    end
    return false
end

-- Pure browse model: class-set tokens are deduplicated across bosses and the
-- remaining physical drops stay under their source boss. Tests may inject a
-- metadata resolver without needing to construct WoW frames/tooltips.
function Wishlist.BuildBrowseModel(FB, metadataResolver)
    metadataResolver = metadataResolver or ResolveTokenMetadata
    local model = { setGroups = {}, bosses = {} }
    local exchangeItems = BG.Loot[FB] and BG.Loot[FB].ExchangeItems or {}
    local setTokens = {}

    for bossIndex = 1, HopeMaxb[FB] or 0 do
        local bossModel = {
            bossIndex = bossIndex,
            items = {},
            setTokens = {},
            totalCount = 0,
        }
        local setSeen = {}
        for _, entry in ipairs(Wishlist.GetBrowseItems(FB, bossIndex)) do
            bossModel.totalCount = bossModel.totalCount + 1
            local metadata
            if exchangeItems[entry.itemID] then
                -- Set grouping is optional presentation metadata. A malformed or
                -- temporarily unavailable tooltip must not blank the whole page;
                -- keep the physical token under its source boss as the fallback.
                local resolved, result = pcall(metadataResolver, FB, entry.itemID)
                if resolved then
                    metadata = result
                end
            end
            if metadata and metadata.isClassSet then
                local token = setTokens[entry.itemID]
                if not token then
                    token = {
                        itemID = entry.itemID,
                        classes = metadata.classes,
                        equipLoc = metadata.equipLoc,
                        targetCount = metadata.targetCount,
                        sourceBosses = {},
                    }
                    setTokens[entry.itemID] = token
                end
                table.insert(token.sourceBosses, bossIndex)
                if not setSeen[entry.itemID] then
                    setSeen[entry.itemID] = true
                    table.insert(bossModel.setTokens, token)
                end
            else
                table.insert(bossModel.items, entry)
            end
        end
        if bossModel.totalCount > 0 then
            table.insert(model.bosses, bossModel)
        end
    end

    local playerClass = UnitClass and select(2, UnitClass("player"))
    local groupIndex = {}
    for _, token in pairs(setTokens) do
        local key = table.concat(token.classes, ",")
        local group = groupIndex[key]
        if not group then
            group = {
                key = key,
                classes = token.classes,
                isCurrent = ContainsClass(token.classes, playerClass),
                items = {},
            }
            groupIndex[key] = group
            table.insert(model.setGroups, group)
        end
        table.insert(group.items, token)
    end
    for _, group in ipairs(model.setGroups) do
        table.sort(group.items, function(left, right)
            if left.equipLoc == right.equipLoc then
                return left.itemID < right.itemID
            end
            return tostring(left.equipLoc) < tostring(right.equipLoc)
        end)
    end
    table.sort(model.setGroups, function(left, right)
        if left.isCurrent ~= right.isCurrent then return left.isCurrent end
        return left.key < right.key
    end)
    return model
end

Wishlist.GetSetTokenMetadata = ResolveTokenMetadata

local BOSS_PORTRAITS = {
    MCtitan = {
        [1] = "MCtitan/b1.png", [2] = "MCtitan/b2.png",
        [3] = "MCtitan/b3.png", [4] = "MCtitan/b4.png",
        [5] = "MCtitan/b5.png", [6] = "MCtitan/b6.png",
        [7] = "MCtitan/b7.png", [8] = "MCtitan/b8.png",
        [9] = "MCtitan/b9.png", [10] = "MCtitan/b10.png",
    },
    SSCtitan = {
        [1] = "SSCtitan/b1.png", [2] = "SSCtitan/b2.png",
        [3] = "SSCtitan/b3.png", [4] = "SSCtitan/b4.png",
        [5] = "SSCtitan/b5.png", [6] = "SSCtitan/b6.png",
        [7] = "SSCtitan/b7.png", [8] = "SSCtitan/b8.png",
        [9] = "SSCtitan/b9.png", [10] = "SSCtitan/b10.png",
    },
    NAXXtitan = {
        [1] = "NAXXtitan/b1.png", [2] = "NAXXtitan/b2.png",
        [3] = "NAXXtitan/b3.png", [4] = "NAXXtitan/b4.png",
        [5] = "NAXXtitan/b5.png", [6] = "NAXXtitan/b6.png",
        [7] = "NAXXtitan/b7.png", [8] = "NAXXtitan/b8.png",
        [9] = "NAXXtitan/b9.png", [10] = "NAXXtitan/b10.png",
        [11] = "NAXXtitan/b11.png", [12] = "NAXXtitan/b12.png",
        [13] = "NAXXtitan/b13.png", [14] = "NAXXtitan/b14.png",
        [15] = "NAXXtitan/b15.png", [16] = "NAXXtitan/b16.png",
        [17] = "NAXXtitan/b17.png",
    },
    TOCtitan = {
        [1] = "ZUGtitan/b1.png", [2] = "ZUGtitan/b2.png",
        [3] = "ZUGtitan/b3.png", [4] = "ZUGtitan/b4.png",
        [5] = "ZUGtitan/b5.png", [6] = "ZUGtitan/b6.png",
        [7] = "ZUGtitan/b7.png", [8] = "ZUGtitan/b8.png",
        [9] = "ZUGtitan/b9.png", [10] = "ZUGtitan/b10.png",
        [11] = "TOC/b1.png", [12] = "TOC/b2.png",
        [13] = "TOC/b3.png", [14] = "TOC/b4.png",
        [15] = "TOC/b5.png",
    },
    SWtitan = {
        [1] = "SWtitan/b1.png", [2] = "SWtitan/b2.png",
        [3] = "SWtitan/b3.png", [4] = "SWtitan/b4.png",
        [5] = "SWtitan/b5.png", [6] = "SWtitan/b6.png",
        [8] = "SWtitan/b8.png", [9] = "SWtitan/b9.png",
        [10] = "SWtitan/b10.png", [11] = "SWtitan/b11.png",
        [12] = "SWtitan/b12.png", [13] = "SWtitan/b13.png",
    },
}

local function GetBossPortrait(FB, bossIndex)
    local relative = BOSS_PORTRAITS[FB] and BOSS_PORTRAITS[FB][bossIndex]
    if relative then
        return "Interface\\AddOns\\" .. AddonName .. "\\Media\\icon\\" .. relative:gsub("/", "\\"), true
    end
    return "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", false
end

local function GetQualityColor(quality)
    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    if color then return color.r, color.g, color.b end
    return 0.72, 0.72, 0.72
end

local function RGBToHex(r, g, b)
    return string.format("%02x%02x%02x", math.floor((r or 1) * 255 + 0.5),
        math.floor((g or 1) * 255 + 0.5), math.floor((b or 1) * 255 + 0.5))
end

local function GetClassColorHex(classFile)
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then
        local hex = color.colorStr or RGBToHex(color.r, color.g, color.b)
        return #hex == 8 and hex:sub(3) or hex
    end
    return "d6b35a"
end

local function GetFirstUTF8Character(text)
    text = tostring(text or "")
    local firstByte = text:byte(1)
    if not firstByte then return "" end
    local length = firstByte < 0x80 and 1
        or firstByte < 0xE0 and 2
        or firstByte < 0xF0 and 3
        or 4
    return text:sub(1, length)
end

local function FormatClassGroup(classes)
    local catalog = GetClassCatalog()
    local icons = ""
    local names = {}
    for _, classFile in ipairs(classes) do
        icons = icons .. "|A:GarrMission_ClassIcon-" .. classFile .. ":18:18|a"
        local info = catalog.byFile[classFile]
        local className = info and info.name or classFile
        table.insert(names, "|cff" .. GetClassColorHex(classFile)
            .. GetFirstUTF8Character(className) .. "|r")
    end
    return icons .. "  " .. table.concat(names, "·")
end

local function GetBossInfo(FB, bossIndex)
    return BG.Boss[FB] and BG.Boss[FB]["boss" .. bossIndex]
end

local function NormalizeBossName(name)
    return tostring(name or ""):gsub("\n", "")
end

local AUXILIARY_DROP_SOURCE_NAMES = {
    [NormalizeBossName(L["限时宝箱"])] = true,
    [NormalizeBossName(L["杂\n\n项"])] = true,
    [NormalizeBossName(L["罚\n\n款"])] = true,
    [NormalizeBossName(L["支\n\n出"])] = true,
    [NormalizeBossName(L["总\n览"])] = true,
}

local function IsAuxiliaryDropSource(boss)
    return AUXILIARY_DROP_SOURCE_NAMES[NormalizeBossName(boss and boss.name2)] == true
end

local function OrderBossDropSources(FB, bosses)
    local ordered = {}
    for _, bossModel in ipairs(bosses or {}) do
        table.insert(ordered, bossModel)
    end
    table.sort(ordered, function(left, right)
        local leftAuxiliary = IsAuxiliaryDropSource(GetBossInfo(FB, left.bossIndex))
        local rightAuxiliary = IsAuxiliaryDropSource(GetBossInfo(FB, right.bossIndex))
        if leftAuxiliary ~= rightAuxiliary then
            return not leftAuxiliary
        end
        return left.bossIndex < right.bossIndex
    end)
    return ordered
end

local function GetBossDisplayName(FB, bossIndex, boss)
    local name = boss and boss.name2 or (L["首领"] .. " " .. bossIndex)
    if not boss then return name end
    if IsAuxiliaryDropSource(boss) then return name end
    return string.format(L["%d号 · %s"], bossIndex, name)
end

local function FormatBossNames(FB, bossIndexes)
    local names = {}
    for _, bossIndex in ipairs(bossIndexes or {}) do
        local boss = GetBossInfo(FB, bossIndex)
        table.insert(names, boss and boss.name2 or (L["首领"] .. " " .. bossIndex))
    end
    return table.concat(names, " · ")
end

local ui = {
    itemButtons = {}, panels = {}, headers = {}, labels = {}, bossRows = {},
    itemIndex = 0, panelIndex = 0, headerIndex = 0, labelIndex = 0, bossRowIndex = 0,
    activeSetGroup = {}, activeBoss = {},
}

local function BeginRender()
    for _, pool in ipairs({ ui.itemButtons, ui.panels, ui.headers, ui.labels, ui.bossRows }) do
        for _, region in ipairs(pool) do region:Hide() end
    end
    ui.itemIndex, ui.panelIndex, ui.headerIndex, ui.labelIndex, ui.bossRowIndex = 0, 0, 0, 0, 0
end

local function AcquireLabel(parent)
    ui.labelIndex = ui.labelIndex + 1
    local label = ui.labels[ui.labelIndex]
    if not label then
        -- Panels are real frames, so font strings created directly on the
        -- scroll child can sit behind their opaque backdrops. Keep all loose
        -- labels on one overlay frame above cards and panels.
        label = (ui.labelLayer or parent):CreateFontString(nil, "OVERLAY")
        ui.labels[ui.labelIndex] = label
    end
    label:ClearAllPoints()
    -- Titan's FontString rejects SetText until a font has been assigned.
    -- Callers override this default with their section-specific size/color.
    label:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    label:SetText("")
    label:Show()
    return label
end

local function AcquirePanel(parent)
    ui.panelIndex = ui.panelIndex + 1
    local panel = ui.panels[ui.panelIndex]
    if not panel then
        panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        panel:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        ui.panels[ui.panelIndex] = panel
    end
    panel:ClearAllPoints()
    panel:SetBackdropColor(unpack(SURFACE))
    panel:SetBackdropBorderColor(unpack(BORDER))
    panel:SetFrameLevel(parent:GetFrameLevel() + 1)
    panel:Show()
    return panel
end

local function CreateCollapseHeader(parent)
    local header = CreateFrame("Button", nil, parent, "BackdropTemplate")
    header:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8x8",
        edgeFile = "Interface/Buttons/WHITE8x8",
        edgeSize = 1,
    })
    header:RegisterForClicks("AnyUp")

    header.stripe = header:CreateTexture(nil, "ARTWORK")
    header.stripe:SetTexture("Interface/Buttons/WHITE8x8")
    header.stripe:SetPoint("TOPLEFT", 0, -1)
    header.stripe:SetPoint("BOTTOMLEFT", 0, 1)
    header.stripe:SetWidth(3)

    header.portrait = header:CreateTexture(nil, "ARTWORK")
    header.portrait:SetSize(42, 42)
    header.portrait:SetPoint("LEFT", 10, 0)
    header.portrait:SetTexCoord(unpack(BG.iconTexCoord or { 0.07, 0.93, 0.07, 0.93 }))

    header.title = header:CreateFontString(nil, "OVERLAY")
    header.title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    header.title:SetJustifyH("LEFT")

    header.subtitle = header:CreateFontString(nil, "OVERLAY")
    header.subtitle:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    header.subtitle:SetTextColor(unpack(MUTED))
    header.subtitle:SetJustifyH("LEFT")

    header.arrow = header:CreateFontString(nil, "OVERLAY")
    header.arrow:SetPoint("RIGHT", -14, 0)
    header.arrow:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
    header.arrow:SetTextColor(unpack(CYAN))

    header.checkmark = header:CreateTexture(nil, "ARTWORK")
    header.checkmark:SetPoint("RIGHT", -13, 0)
    header.checkmark:SetSize(18, 18)
    header.checkmark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    header.checkmark:SetVertexColor(0.27, 1.00, 0.87, 1)
    header.checkmark:Hide()

    header:SetScript("OnClick", function(self)
        if self.action then self.action() end
    end)
    header:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(CYAN))
    end)
    header:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(self.restingBorderColor or BORDER))
    end)
    return header
end

local function AcquireHeader(parent)
    ui.headerIndex = ui.headerIndex + 1
    local header = ui.headers[ui.headerIndex]
    if not header then
        header = CreateCollapseHeader(parent)
        ui.headers[ui.headerIndex] = header
    end
    header:ClearAllPoints()
    header.action = nil
    header.isSetGroupHeader = nil
    header.isBossDetailHeader = nil
    header.arrow:SetText("")
    header.checkmark:Hide()
    header.restingBorderColor = BORDER
    header:SetFrameLevel(parent:GetFrameLevel() + 3)
    header:SetBackdropColor(unpack(SURFACE_RAISED))
    header:SetBackdropBorderColor(unpack(BORDER))
    header:Show()
    return header
end

local function CreateBossRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("AnyUp")

    row.hoverBackground = row:CreateTexture(nil, "BACKGROUND")
    row.hoverBackground:SetAllPoints()
    row.hoverBackground:SetTexture("Interface/Buttons/WHITE8x8")
    row.hoverBackground:SetVertexColor(unpack(ITEM_HOVER))
    row:SetHighlightTexture(row.hoverBackground)

    row.selectedBackground = row:CreateTexture(nil, "BACKGROUND")
    row.selectedBackground:SetAllPoints()
    row.selectedBackground:SetTexture("Interface/Buttons/WHITE8x8")
    row.selectedBackground:SetVertexColor(unpack(ITEM_SELECTED))
    row.selectedBackground:Hide()

    row.portrait = row:CreateTexture(nil, "ARTWORK")
    row.portrait:SetPoint("LEFT", 7, 0)
    row.portrait:SetSize(24, 24)

    row.count = row:CreateFontString(nil, "OVERLAY")
    row.count:SetPoint("RIGHT", -8, 0)
    row.count:SetWidth(24)
    row.count:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    row.count:SetJustifyH("RIGHT")

    row.title = row:CreateFontString(nil, "OVERLAY")
    row.title:SetPoint("LEFT", row.portrait, "RIGHT", 8, 0)
    row.title:SetPoint("RIGHT", row.count, "LEFT", -6, 0)
    row.title:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)

    row.divider = row:CreateTexture(nil, "ARTWORK")
    row.divider:SetPoint("BOTTOMLEFT", 0, 0)
    row.divider:SetPoint("BOTTOMRIGHT", 0, 0)
    row.divider:SetHeight(1)
    row.divider:SetTexture("Interface/Buttons/WHITE8x8")
    row.divider:SetVertexColor(unpack(BORDER))

    row:SetScript("OnClick", function(self)
        if self.action then self.action() end
    end)
    return row
end

local function AcquireBossRow(parent)
    ui.bossRowIndex = ui.bossRowIndex + 1
    local row = ui.bossRows[ui.bossRowIndex]
    if not row then
        row = CreateBossRow(parent)
        ui.bossRows[ui.bossRowIndex] = row
    end
    row:ClearAllPoints()
    row.action = nil
    row.isBossDirectoryRow = true
    row:SetFrameLevel(parent:GetFrameLevel() + 1)
    row:Show()
    return row
end

local function SetBossRow(row, FB, bossModel, wishCount, selected)
    local bossIndex = bossModel.bossIndex
    local boss = GetBossInfo(FB, bossIndex)
    local portraitTexture, cropPortrait = GetBossPortrait(FB, bossIndex)
    row.bossIndex = bossIndex
    row.wishCount = wishCount
    row.selected = selected and true or false
    row.portrait:SetTexture(portraitTexture)
    if cropPortrait then
        row.portrait:SetTexCoord(unpack(BG.iconTexCoord or { 0.07, 0.93, 0.07, 0.93 }))
    else
        row.portrait:SetTexCoord(0, 1, 0, 1)
    end
    row.portrait:SetVertexColor(1, 1, 1, 1)
    row.title:SetText(GetBossDisplayName(FB, bossIndex, boss))
    row.title:SetTextColor(unpack(selected and GOLD or WHITE))
    row.count:SetText(tostring(wishCount))
    row.count:SetTextColor(unpack(wishCount > 0 and CYAN or MUTED))
    row.selectedBackground:SetShown(selected)
end

local function ApplyItemVisual(button)
    if not button.qualityR then return end
    button.qualityBorder:SetVertexColor(button.qualityR, button.qualityG, button.qualityB, 1)
    button.name:SetTextColor(button.qualityR, button.qualityG, button.qualityB)
    button.selectedBackground:SetShown(button.selected and not button.isSummary)
    button.summaryBackground:SetShown(button.isSummary)
    button.divider:SetShown(button.isSummary)
    button.removeIcon:SetShown(button.isSummary)
end

local function ResolveItemTexture(itemID, texture)
    if texture then return texture end
    if C_Item and C_Item.GetItemIconByID then
        texture = C_Item.GetItemIconByID(itemID)
    elseif GetItemIcon then
        texture = GetItemIcon(itemID)
    end
    return texture
end

local function CreateItemButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:RegisterForClicks("AnyUp")

    local hover = button:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetTexture("Interface/Buttons/WHITE8x8")
    hover:SetVertexColor(unpack(ITEM_HOVER))
    button.hoverBackground = hover
    button:SetHighlightTexture(hover)

    button.selectedBackground = button:CreateTexture(nil, "BACKGROUND")
    button.selectedBackground:SetAllPoints()
    button.selectedBackground:SetTexture("Interface/Buttons/WHITE8x8")
    button.selectedBackground:SetVertexColor(unpack(ITEM_SELECTED))
    button.selectedBackground:Hide()

    button.summaryBackground = button:CreateTexture(nil, "BACKGROUND")
    button.summaryBackground:SetAllPoints()
    button.summaryBackground:SetTexture("Interface/Buttons/WHITE8x8")
    button.summaryBackground:SetVertexColor(0.02, 0.12, 0.14, 0.34)
    button.summaryBackground:Hide()

    button.qualityBorder = button:CreateTexture(nil, "BACKGROUND")
    button.qualityBorder:SetTexture("Interface/Buttons/WHITE8x8")
    button.qualityBorder:SetPoint("LEFT", 3, 0)
    button.qualityBorder:SetSize(32, 32)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("CENTER", button.qualityBorder)
    button.icon:SetSize(30, 30)
    button.icon:SetTexCoord(unpack(BG.iconTexCoord or { 0.07, 0.93, 0.07, 0.93 }))

    button.level = button:CreateFontString(nil, "OVERLAY")
    button.level:SetPoint("TOPLEFT", button.icon, "TOPLEFT", 1, -1)
    button.level:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    button.level:SetJustifyH("LEFT")

    button.name = button:CreateFontString(nil, "OVERLAY")
    button.name:SetPoint("LEFT", button.qualityBorder, "RIGHT", 8, 0)
    button.name:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    button.name:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
    button.name:SetJustifyH("LEFT")
    button.name:SetWordWrap(false)

    button.meta = button:CreateFontString(nil, "OVERLAY")
    button.meta:SetFont(BIAOGE_TEXT_FONT, 10, "OUTLINE")
    button.meta:SetTextColor(0.82, 0.84, 0.84)
    button.meta:SetJustifyH("LEFT")
    button.meta:SetWordWrap(false)
    button.meta:Hide()

    button.divider = button:CreateTexture(nil, "ARTWORK")
    button.divider:SetPoint("BOTTOMLEFT", 3, 0)
    button.divider:SetPoint("BOTTOMRIGHT", -3, 0)
    button.divider:SetHeight(1)
    button.divider:SetTexture("Interface/Buttons/WHITE8x8")
    button.divider:SetVertexColor(unpack(BORDER))
    button.divider:Hide()

    button.removeIcon = button:CreateTexture(nil, "OVERLAY")
    button.removeIcon:SetPoint("RIGHT", -8, 0)
    button.removeIcon:SetSize(16, 16)
    button.removeIcon:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    button.removeIcon:SetTexCoord(0.20, 0.80, 0.20, 0.80)
    button.removeIcon:SetDesaturated(true)
    button.removeIcon:SetVertexColor(unpack(CYAN))
    button.removeIcon:Hide()

    button:SetScript("OnClick", function(self)
        if self.action then self.action() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        local _, itemLink = GetItemInfo(self.itemID)
        if itemLink then
            GameTooltip:SetHyperlink(itemLink)
        else
            GameTooltip:AddLine("#" .. tostring(self.itemID), 1, 1, 1)
        end
        if self.sourceBosses and #self.sourceBosses > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format(L["来源：%s"], FormatBossNames(self.FB, self.sourceBosses)), 0, 0.75, 1, true)
        end
        GameTooltip:AddLine(self.selected and L["再次点击取消心愿"] or L["点击设为心愿"], 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        ApplyItemVisual(self)
        GameTooltip:Hide()
    end)
    return button
end

local function AcquireItemButton(parent)
    ui.itemIndex = ui.itemIndex + 1
    local button = ui.itemButtons[ui.itemIndex]
    if not button then
        button = CreateItemButton(parent)
        ui.itemButtons[ui.itemIndex] = button
    end
    button:SetParent(parent)
    button:ClearAllPoints()
    button.action = nil
    button.isSummary = false
    button:SetFrameLevel(parent:GetFrameLevel() + 4)
    button:Show()
    return button
end

local function SetItemButtonStyle(button, style)
    button.isSummary = style == "summary"
    button.showsMetadata = style == "bossDetail"
    button.name:ClearAllPoints()
    button.meta:ClearAllPoints()
    if button.showsMetadata then
        button.name:SetPoint("TOPLEFT", button.qualityBorder, "TOPRIGHT", 8, -1)
        button.name:SetPoint("TOPRIGHT", button, "TOPRIGHT", -4, -1)
        button.meta:SetPoint("BOTTOMLEFT", button.qualityBorder, "BOTTOMRIGHT", 8, 1)
        button.meta:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 1)
        button.meta:Show()
    else
        button.name:SetPoint("LEFT", button.qualityBorder, "RIGHT", 8, 0)
        button.meta:Hide()
    end
    if button.isSummary then
        button.name:SetPoint("RIGHT", button, "RIGHT", -30, 0)
    elseif not button.showsMetadata then
        button.name:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    end
end

local function FormatItemMetadata(itemType, itemSubType, equipLoc)
    local slot
    if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
        slot = _G[equipLoc] or equipLoc
    end
    local category = itemSubType
    if not category or category == "" then category = itemType end
    if category == slot then category = nil end
    if slot and category then
        return string.format(L["%s，%s"], slot, category)
    end
    return slot or category or ""
end

local function SetItemButton(button, entry, FB, selected)
    local itemID = entry.itemID
    button.itemID = itemID
    button.FB = FB
    button.selected = selected and true or false
    button.sourceBosses = entry.sourceBosses

    local waitingForItem
    local function Update()
        if button.itemID ~= itemID then return end
        local name, _, quality, itemLevel, _, itemType, itemSubType, _, equipLoc, texture = GetItemInfo(itemID)
        texture = ResolveItemTexture(itemID, texture)
        waitingForItem = not name or not texture
        local r, g, b = GetQualityColor(quality)
        button.qualityR, button.qualityG, button.qualityB = r, g, b
        button.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        button.name:SetText((name or ("#" .. itemID)))
        button.meta:SetText(FormatItemMetadata(itemType, itemSubType, equipLoc))
        button.level:SetText(itemLevel and tostring(itemLevel) or "")
        button.level:SetTextColor(r, g, b)
        ApplyItemVisual(button)
        if BG.SpecGearFilter and BG.SpecGearFilter.ApplyToCell then
            BG.SpecGearFilter.ApplyToCell(button, "item:" .. itemID)
        else
            button:SetAlpha(1)
        end
    end
    Update()
    if waitingForItem and BG.OnItemLoad then
        local item = BG.OnItemLoad(itemID)
        if item and item.ContinueOnItemLoad then
            item:ContinueOnItemLoad(Update)
        end
    end
end

local function ToggleWish(FB, entry, bossIndex)
    local selected = Wishlist.IsWishlisted(entry.itemID, FB)
    local _, link = GetItemInfo(entry.itemID)
    link = link or ("#" .. entry.itemID)
    if selected then
        if Wishlist.Remove(entry.itemID, FB) then
            SendFeedback(string.format(L["已移除心愿：%s"], link))
            BG.PlaySound(1)
        end
        return
    end

    local ok = Wishlist.Add(entry.itemID, FB, bossIndex)
    if ok then
        SendFeedback(string.format(L["已加入心愿：%s"], link))
        BG.PlaySound(2)
    else
        UIErrorsFrame:AddMessage(L["只能选择Titan团本BOSS正常掉落的装备"], 1, 0, 0)
    end
end

local function AddSectionTitle(parent, x, y, titleText)
    local title = AcquireLabel(parent)
    title:SetPoint("TOPLEFT", x, y)
    title:SetFont(BIAOGE_TEXT_FONT, 16, "OUTLINE")
    title:SetTextColor(unpack(GOLD))
    title:SetText(titleText)
    return y - 30
end

local function RenderItemGrid(parent, FB, entries, x, y, width, columns, actionFactory, style)
    if #entries == 0 then return y end
    local isSummary = style == "summary"
    local rowHeight = isSummary and SUMMARY_ITEM_HEIGHT
        or style == "bossDetail" and BOSS_ITEM_HEIGHT
        or ITEM_HEIGHT
    local rowGap = isSummary and 0 or ITEM_GAP
    local buttonWidth = math.floor((width - ITEM_GAP * (columns - 1)) / columns)
    for index, entry in ipairs(entries) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local item = entry
        local selected = Wishlist.IsWishlisted(item.itemID, FB)
        local button = AcquireItemButton(parent)
        button:SetSize(buttonWidth, rowHeight)
        button:SetPoint("TOPLEFT", x + column * (buttonWidth + ITEM_GAP), y - row * (rowHeight + rowGap))
        SetItemButtonStyle(button, style)
        SetItemButton(button, item, FB, selected)
        button.action = actionFactory(item, selected)
    end
    return y - math.ceil(#entries / columns) * (rowHeight + rowGap)
end

local function RenderSummary(parent, FB, entries, x, y, width, height)
    local top = y
    local panel = AcquirePanel(parent)
    panel:SetPoint("TOPLEFT", x, top)
    panel:SetSize(width, height)

    y = y - 12
    local title = AcquireLabel(parent)
    title:SetPoint("TOPLEFT", x + 12, y)
    title:SetWidth(math.max(1, width - 24))
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
    title:SetTextColor(unpack(CYAN))
    title:SetText(string.format(L["本阶段心愿（%d）"], #entries))
    y = y - 32

    if #entries == 0 then
        if ui.summaryScroll then
            ui.summaryScroll:Hide()
            ui.summaryScroll.ScrollBar:Hide()
            ui.summaryScroll:EnableMouseWheel(false)
            ui.summaryScroll:SetVerticalScroll(0)
        end
        ui.summaryScrollKey = nil
        local empty = AcquireLabel(parent)
        empty:SetPoint("TOPLEFT", x + 12, y)
        empty:SetWidth(width - 24)
        empty:SetJustifyH("LEFT")
        empty:SetWordWrap(true)
        empty:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
        empty:SetTextColor(unpack(MUTED))
        empty:SetText(L["当前阶段尚无心愿；可以从职业套装或首领掉落中选择。"])
    else
        local scroll = ui.summaryScroll
        local child = ui.summaryChild
        local viewportWidth = math.max(1, width - 16)
        local viewportHeight = math.max(1, height - 89)
        local itemsHeight = #entries * SUMMARY_ITEM_HEIGHT
        local hasOverflow = itemsHeight > viewportHeight
        local contentWidth = math.max(1, viewportWidth - (hasOverflow and 22 or 0))
        local contentHeight = math.max(viewportHeight, itemsHeight)
        local oldOffset = ui.summaryScrollKey == FB and scroll:GetVerticalScroll() or 0

        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", x + 8, y)
        scroll:SetSize(viewportWidth, viewportHeight)
        scroll:Show()
        child:SetSize(contentWidth, contentHeight)
        RenderItemGrid(child, FB, entries, 0, 0, contentWidth, 1, function(item)
            return function() ToggleWish(FB, item, item.bossIndex) end
        end, "summary")
        scroll:UpdateScrollChildRect()
        local maxOffset = math.max(0, contentHeight - viewportHeight)
        scroll:SetVerticalScroll(hasOverflow and math.min(oldOffset, maxOffset) or 0)
        scroll.ScrollBar:SetShown(hasOverflow)
        scroll:EnableMouseWheel(hasOverflow)
        ui.summaryScrollKey = FB
    end

    return height, panel
end

local function RenderSetGroups(parent, FB, groups, x, y, width)
    local top = y
    local panel = AcquirePanel(parent)
    panel:SetPoint("TOPLEFT", x, top)
    panel:SetWidth(width)
    y = AddSectionTitle(parent, x + 12, y - 12, L["职业套装"])

    if #groups == 0 then
        local empty = AcquireLabel(parent)
        empty:SetPoint("TOPLEFT", x + 12, y)
        empty:SetWidth(width - 24)
        empty:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
        empty:SetTextColor(unpack(MUTED))
        empty:SetText(L["当前阶段没有可用的职业套装兑换物。"])
        y = y - 36
        panel:SetHeight(top - y)
        return top - y, panel
    end

    local activeKey = ui.activeSetGroup[FB]
    local activeGroup
    if activeKey then
        for _, group in ipairs(groups) do
            if group.key == activeKey then
                activeGroup = group
                break
            end
        end
    end
    if not activeGroup then
        for _, group in ipairs(groups) do
            if group.isCurrent then
                activeGroup = group
                break
            end
        end
        activeGroup = activeGroup or groups[1]
        activeKey = activeGroup and activeGroup.key
        ui.activeSetGroup[FB] = activeKey
    end

    for _, group in ipairs(groups) do
        local currentGroup = group
        local selected = activeKey == group.key
        local header = AcquireHeader(parent)
        header.isSetGroupHeader = true
        header:SetPoint("TOPLEFT", x + 8, y)
        header:SetSize(width - 16, 44)
        header.portrait:Hide()
        header.title:ClearAllPoints()
        header.title:SetPoint("LEFT", 13, 0)
        header.title:SetPoint("RIGHT", -42, 0)
        header.title:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        header.title:SetWordWrap(false)
        header.title:SetText(FormatClassGroup(group.classes))
        header.title:SetTextColor(unpack(WHITE))
        header.subtitle:Hide()
        header.arrow:SetText("")
        header.checkmark:SetShown(selected)
        header.restingBorderColor = selected and CYAN or BORDER
        header:SetBackdropBorderColor(unpack(header.restingBorderColor))
        header.stripe:SetVertexColor(selected and CYAN[1] or GOLD[1],
            selected and CYAN[2] or GOLD[2], selected and CYAN[3] or GOLD[3], 1)
        header.action = function()
            ui.activeSetGroup[FB] = currentGroup.key
            Wishlist.Refresh()
        end
        y = y - 50
    end

    y = y - 2
    local count = AcquireLabel(parent)
    count:SetPoint("TOPLEFT", x + 12, y)
    count:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    count:SetTextColor(unpack(MUTED))
    count:SetText(string.format(L["%d 件套装兑换物"], #activeGroup.items))
    y = y - 26

    local displayItems = {}
    for _, token in ipairs(activeGroup.items) do
        table.insert(displayItems, token)
    end
    y = RenderItemGrid(parent, FB, displayItems, x + 8, y, width - 16, 1, function(item)
        local firstBoss = item.sourceBosses[1]
        return function() ToggleWish(FB, item, firstBoss) end
    end)

    y = y - 10
    panel:SetHeight(top - y)
    return top - y, panel
end

local function RenderBossDetail(parent, FB, bossModel, x, y, width, height)
    local top = y
    local bossIndex = bossModel.bossIndex
    local boss = GetBossInfo(FB, bossIndex)
    local bossColor = boss and boss.color or "FFD100"
    local r = tonumber(bossColor:sub(1, 2), 16) / 255
    local g = tonumber(bossColor:sub(3, 4), 16) / 255
    local b = tonumber(bossColor:sub(5, 6), 16) / 255

    local panel = AcquirePanel(parent)
    panel:SetPoint("TOPLEFT", x, top)
    panel:SetSize(width, height)

    local header = AcquireHeader(parent)
    header.isBossDetailHeader = true
    header:SetPoint("TOPLEFT", x, y)
    header:SetSize(width, 44)
    header.portrait:Show()
    header.portrait:SetSize(34, 34)
    local portraitTexture, cropPortrait = GetBossPortrait(FB, bossIndex)
    header.portrait:SetTexture(portraitTexture)
    if cropPortrait then
        header.portrait:SetTexCoord(unpack(BG.iconTexCoord or { 0.07, 0.93, 0.07, 0.93 }))
    else
        header.portrait:SetTexCoord(0, 1, 0, 1)
    end
    header.portrait:SetVertexColor(1, 1, 1, 1)
    header.title:ClearAllPoints()
    header.title:SetPoint("LEFT", header.portrait, "RIGHT", 10, 0)
    header.title:SetPoint("RIGHT", header, "RIGHT", -12, 0)
    header.title:SetText(GetBossDisplayName(FB, bossIndex, boss))
    header.title:SetTextColor(r, g, b)
    header.subtitle:Hide()
    header.arrow:SetText("")
    header.checkmark:Hide()
    header.stripe:SetVertexColor(r, g, b, 1)
    y = y - 52

    if #bossModel.items > 0 then
        local scroll = ui.bossDetailScroll
        local child = ui.bossDetailChild
        local viewportWidth = math.max(1, width - 16)
        local viewportHeight = math.max(1, height - 58)
        local rowCount = math.ceil(#bossModel.items / 2)
        local itemsHeight = rowCount * BOSS_ITEM_HEIGHT + math.max(0, rowCount - 1) * ITEM_GAP
        local hasOverflow = itemsHeight > viewportHeight
        local contentWidth = math.max(1, viewportWidth - (hasOverflow and 22 or 0))
        local contentHeight = math.max(viewportHeight, itemsHeight)
        local detailKey = FB .. ":" .. bossIndex
        local oldOffset = ui.bossDetailKey == detailKey and scroll:GetVerticalScroll() or 0

        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", x + 8, y)
        scroll:SetSize(viewportWidth, viewportHeight)
        scroll:Show()
        child:SetSize(contentWidth, contentHeight)
        RenderItemGrid(child, FB, bossModel.items, 0, 0, contentWidth, 2, function(item)
            return function() ToggleWish(FB, item, bossIndex) end
        end, "bossDetail")
        scroll:UpdateScrollChildRect()
        local maxOffset = math.max(0, contentHeight - viewportHeight)
        scroll:SetVerticalScroll(hasOverflow and math.min(oldOffset, maxOffset) or 0)
        scroll.ScrollBar:SetShown(hasOverflow)
        scroll:EnableMouseWheel(hasOverflow)
        ui.bossDetailKey = detailKey
    else
        if ui.bossDetailScroll then
            ui.bossDetailScroll:Hide()
            ui.bossDetailScroll.ScrollBar:Hide()
            ui.bossDetailScroll:EnableMouseWheel(false)
            ui.bossDetailScroll:SetVerticalScroll(0)
        end
        ui.bossDetailKey = nil
        local note = AcquireLabel(parent)
        note:SetPoint("TOPLEFT", x + 12, y)
        note:SetWidth(width - 24)
        note:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
        note:SetTextColor(unpack(MUTED))
        note:SetText(L["此首领的可选物品均已归入上方职业套装模块。"])
    end
    return height, panel
end

local function CountBossWishes(entries, bosses)
    local selectedItems = {}
    for _, entry in ipairs(entries or {}) do
        selectedItems[entry.itemID] = true
    end
    local counts = {}
    for _, bossModel in ipairs(bosses or {}) do
        local count = 0
        for _, item in ipairs(bossModel.items or {}) do
            if selectedItems[item.itemID] then count = count + 1 end
        end
        counts[bossModel.bossIndex] = count
    end
    return counts
end

local function ResolveActiveBoss(FB, bosses, counts)
    local activeBoss = tonumber(ui.activeBoss[FB])
    for _, bossModel in ipairs(bosses) do
        if bossModel.bossIndex == activeBoss then return bossModel end
    end
    for _, bossModel in ipairs(bosses) do
        if (counts[bossModel.bossIndex] or 0) > 0 then
            ui.activeBoss[FB] = bossModel.bossIndex
            return bossModel
        end
    end
    local firstBoss = bosses[1]
    ui.activeBoss[FB] = firstBoss and firstBoss.bossIndex or nil
    return firstBoss
end

local function RenderBossDirectory(FB, bosses, counts, activeBoss, x, y, width, height)
    local scroll = ui.bossDirectoryScroll
    local child = ui.bossDirectoryChild
    if not scroll or not child then return end

    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", x, y)
    scroll:SetSize(width, height)
    scroll:Show()

    local rowsHeight = #bosses * BOSS_ROW_HEIGHT
    local hasOverflow = rowsHeight > height
    local contentWidth = math.max(1, width - (hasOverflow and 22 or 0))
    local contentHeight = math.max(height, rowsHeight)
    child:SetSize(contentWidth, contentHeight)
    for index, bossModel in ipairs(bosses) do
        local bossIndex = bossModel.bossIndex
        local row = AcquireBossRow(child)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * BOSS_ROW_HEIGHT)
        row:SetSize(contentWidth, BOSS_ROW_HEIGHT)
        SetBossRow(row, FB, bossModel, counts[bossIndex] or 0,
            activeBoss and activeBoss.bossIndex == bossIndex)
        row.action = function()
            ui.activeBoss[FB] = bossIndex
            Wishlist.Refresh()
        end
    end
    scroll:UpdateScrollChildRect()
    local maxOffset = math.max(0, contentHeight - height)
    scroll:SetVerticalScroll(hasOverflow and math.min(scroll:GetVerticalScroll(), maxOffset) or 0)
    scroll.ScrollBar:SetShown(hasOverflow)
    scroll:EnableMouseWheel(hasOverflow)
end

local function RenderBosses(parent, FB, bosses, entries, x, y, width, minimumHeight)
    local top = y
    local panel = AcquirePanel(parent)
    panel:SetPoint("TOPLEFT", x, top)
    panel:SetWidth(width)
    y = AddSectionTitle(parent, x + 12, y - 12, L["首领掉落"])

    local orderedBosses = OrderBossDropSources(FB, bosses)
    local counts = CountBossWishes(entries, orderedBosses)
    local activeBoss = ResolveActiveBoss(FB, orderedBosses, counts)
    local innerX = x + 8
    local innerWidth = width - 16
    local directoryWidth = math.max(185, math.min(230, math.floor(innerWidth * 0.30)))
    local detailX = innerX + directoryWidth + BOSS_DIRECTORY_GAP
    local detailWidth = innerWidth - directoryWidth - BOSS_DIRECTORY_GAP
    local requestedHeight = math.max(BOSS_WORKBENCH_MIN_HEIGHT, minimumHeight or 0)
    local bodyTop = y
    local bodyHeight = math.max(420, requestedHeight - (top - bodyTop) - 8)

    local directoryPanel = AcquirePanel(parent)
    directoryPanel:SetPoint("TOPLEFT", innerX, bodyTop)
    directoryPanel:SetWidth(directoryWidth)

    if not activeBoss then
        if ui.bossDirectoryScroll then ui.bossDirectoryScroll:Hide() end
        if ui.bossDetailScroll then ui.bossDetailScroll:Hide() end
        local detailPanel = AcquirePanel(parent)
        detailPanel:SetPoint("TOPLEFT", detailX, bodyTop)
        detailPanel:SetSize(detailWidth, bodyHeight)
        local empty = AcquireLabel(parent)
        empty:SetPoint("TOPLEFT", detailX + 12, bodyTop - 14)
        empty:SetWidth(detailWidth - 24)
        empty:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
        empty:SetTextColor(unpack(MUTED))
        empty:SetText(L["当前副本没有可供选择的首领掉落。"])
    else
        RenderBossDetail(parent, FB, activeBoss, detailX, bodyTop, detailWidth, bodyHeight)
    end

    directoryPanel:SetHeight(bodyHeight)
    if activeBoss then
        RenderBossDirectory(FB, orderedBosses, counts, activeBoss, innerX + 1, bodyTop - 1,
            directoryWidth - 2, bodyHeight - 2)
    end
    y = bodyTop - bodyHeight - 8
    panel:SetHeight(top - y)
    return top - y, panel
end

local function GetWorkbenchColumns(width)
    local left = math.max(250, math.floor(width * 0.22))
    local right = math.max(250, math.floor(width * 0.21))
    local center = width - left - right - COLUMN_GAP * 2
    if center < 520 then
        local deficit = 520 - center
        left = math.max(220, left - math.ceil(deficit / 2))
        right = math.max(220, right - math.floor(deficit / 2))
        center = width - left - right - COLUMN_GAP * 2
    end
    return left, center, right
end

function Wishlist.Refresh()
    local frame = BG.WishlistMainFrame
    if not frame or not frame:IsShown() or not frame.child then return end
    local FB = BG.FB1
    local child = frame.child
    local scroll = frame.scroll
    local oldOffset = scroll:GetVerticalScroll()
    local viewportWidth = scroll:GetWidth()
    local width = child:GetWidth()
    if viewportWidth and viewportWidth > 60 then
        width = viewportWidth - 28
        if math.abs(child:GetWidth() - width) > 1 then
            child:SetWidth(width)
        end
    end
    width = math.max(980, width or 0)
    local leftWidth, centerWidth, rightWidth = GetWorkbenchColumns(width)
    local centerX = leftWidth + COLUMN_GAP
    local rightX = centerX + centerWidth + COLUMN_GAP
    local top = 0

    BeginRender()
    local entries = Wishlist.GetEntries(FB)
    local model = Wishlist.BuildBrowseModel(FB)
    frame.clearButton:SetShown(#entries > 0)

    local leftHeight, leftPanel = RenderSetGroups(child, FB, model.setGroups, 0, top, leftWidth)
    local workbenchHeight = math.max(BOSS_WORKBENCH_MIN_HEIGHT, (scroll:GetHeight() or 0) - 14)
    local centerHeight, centerPanel = RenderBosses(child, FB, model.bosses, entries,
        centerX, top, centerWidth, workbenchHeight)
    local rightHeight, rightPanel = RenderSummary(child, FB, entries, rightX, top, rightWidth, workbenchHeight)
    local contentHeight = math.max(leftHeight, centerHeight, rightHeight)
    leftPanel:SetHeight(contentHeight)
    centerPanel:SetHeight(contentHeight)
    rightPanel:SetHeight(contentHeight)

    frame.clearButton:ClearAllPoints()
    frame.clearButton:SetPoint("TOPLEFT", child, "TOPLEFT", rightX + 10, -rightHeight + 37)
    frame.clearButton:SetSize(rightWidth - 20, 25)

    child:SetHeight(math.max(1, contentHeight + 14))
    scroll:UpdateScrollChildRect()
    scroll:SetVerticalScroll(math.min(oldOffset, math.max(0, child:GetHeight() - scroll:GetHeight())))
end

function Wishlist.CreateUI()
    if BG.WishlistMainFrame then return end
    local frame = CreateFrame("Frame", "BG.WishlistMainFrame", BG.MainFrame)
    BG.WishlistMainFrame = frame
    frame:Hide()

    local headerSurface = frame:CreateTexture(nil, "BACKGROUND")
    headerSurface:SetTexture("Interface/Buttons/WHITE8x8")
    local navigationHeight = BG.MainNavigationHeight or 0
    headerSurface:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 18, -48 - navigationHeight)
    headerSurface:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -18, -48 - navigationHeight)
    headerSurface:SetHeight(66)
    headerSurface:SetVertexColor(0.015, 0.055, 0.065, 0.88)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetTexture("Interface/Buttons/WHITE8x8")
    accent:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 18, -48 - navigationHeight)
    accent:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -18, -48 - navigationHeight)
    accent:SetHeight(1)
    accent:SetVertexColor(unpack(GOLD))

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 30, -61 - navigationHeight)
    title:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
    title:SetTextColor(unpack(GOLD))
    title:SetText(L["个人心愿单"])

    local description = frame:CreateFontString(nil, "OVERLAY")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
    description:SetTextColor(unpack(MUTED))
    description:SetText(L["按职业套装与首领掉落建立心愿；实际掉落会提醒，拍卖时保持展开。"])

    if BG.SpecGearFilter and BG.SpecGearFilter.CreateControls then
        local filterControls = BG.SpecGearFilter.CreateControls(frame)
        if filterControls then
            filterControls:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -34, -68 - navigationHeight)
            frame.filterControls = filterControls
        end
    end

    local clearButton = BG.CreateButton(frame)
    clearButton:SetSize(112, 25)
    clearButton:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -28, -58 - navigationHeight)
    clearButton:SetText(L["清空当前副本"])
    frame.clearButton = clearButton

    StaticPopupDialogs["BGFORGE_WISHLIST_CLEAR"] = {
        text = L["确定清空当前副本的全部心愿？"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(_, data)
            local FB = data or BG.FB1
            if Wishlist.Clear(FB) then
                SendFeedback(string.format(L["已清空%s的心愿。"], BG.GetFBinfo(FB, "shortName")))
                BG.PlaySound(2)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
    }
    clearButton:SetScript("OnClick", function()
        StaticPopup_Show("BGFORGE_WISHLIST_CLEAR", nil, nil, BG.FB1)
        BG.PlaySound(1)
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 28, -126 - navigationHeight)
    scroll:SetPoint("BOTTOMRIGHT", BG.MainFrame, "BOTTOMRIGHT", -38, 54)
    scroll.ScrollBar.scrollStep = BG.scrollStep
    BG.CreateSrollBarBackdrop(scroll.ScrollBar)
    frame.scroll = scroll

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(math.max(1, BG.MainFrame:GetWidth() - 86))
    child:SetHeight(1)
    scroll:SetScrollChild(child)
    frame.child = child
    clearButton:SetParent(child)
    clearButton:SetFrameLevel(child:GetFrameLevel() + 8)

    local labelLayer = CreateFrame("Frame", nil, child)
    labelLayer:SetAllPoints(child)
    labelLayer:SetFrameLevel(child:GetFrameLevel() + 6)
    child.labelLayer = labelLayer
    ui.labelLayer = labelLayer

    -- The boss index owns its own scroll position so long raids no longer
    -- force the entire wishlist page to scroll past every boss card.
    local bossDirectoryScroll = CreateFrame("ScrollFrame", nil, child, "UIPanelScrollFrameTemplate")
    bossDirectoryScroll:SetFrameLevel(child:GetFrameLevel() + 7)
    bossDirectoryScroll.ScrollBar.scrollStep = BOSS_ROW_HEIGHT * 2
    bossDirectoryScroll.ScrollBar:ClearAllPoints()
    bossDirectoryScroll.ScrollBar:SetPoint("TOPRIGHT", bossDirectoryScroll, "TOPRIGHT", -2, -16)
    bossDirectoryScroll.ScrollBar:SetPoint("BOTTOMRIGHT", bossDirectoryScroll, "BOTTOMRIGHT", -2, 16)
    bossDirectoryScroll.ScrollBar:Hide()
    BG.CreateSrollBarBackdrop(bossDirectoryScroll.ScrollBar)
    bossDirectoryScroll:EnableMouseWheel(false)
    ui.bossDirectoryScroll = bossDirectoryScroll
    frame.bossDirectoryScroll = bossDirectoryScroll

    local bossDirectoryChild = CreateFrame("Frame", nil, bossDirectoryScroll)
    bossDirectoryChild:SetSize(1, 1)
    bossDirectoryChild:SetFrameLevel(bossDirectoryScroll:GetFrameLevel() + 1)
    bossDirectoryScroll:SetScrollChild(bossDirectoryChild)
    ui.bossDirectoryChild = bossDirectoryChild
    frame.bossDirectoryChild = bossDirectoryChild
    bossDirectoryScroll:SetScript("OnMouseWheel", function(self, delta)
        if not self.ScrollBar:IsShown() then return end
        local maxOffset = math.max(0, bossDirectoryChild:GetHeight() - self:GetHeight())
        local offset = self:GetVerticalScroll() - delta * BOSS_ROW_HEIGHT * 2
        self:SetVerticalScroll(math.max(0, math.min(maxOffset, offset)))
    end)

    -- Keep the selected boss header fixed while only its drop grid scrolls.
    local bossDetailScroll = CreateFrame("ScrollFrame", nil, child, "UIPanelScrollFrameTemplate")
    bossDetailScroll:SetFrameLevel(child:GetFrameLevel() + 7)
    bossDetailScroll.ScrollBar.scrollStep = (BOSS_ITEM_HEIGHT + ITEM_GAP) * 2
    bossDetailScroll.ScrollBar:ClearAllPoints()
    bossDetailScroll.ScrollBar:SetPoint("TOPRIGHT", bossDetailScroll, "TOPRIGHT", -2, -16)
    bossDetailScroll.ScrollBar:SetPoint("BOTTOMRIGHT", bossDetailScroll, "BOTTOMRIGHT", -2, 16)
    bossDetailScroll.ScrollBar:Hide()
    BG.CreateSrollBarBackdrop(bossDetailScroll.ScrollBar)
    bossDetailScroll:EnableMouseWheel(false)
    bossDetailScroll:Hide()
    ui.bossDetailScroll = bossDetailScroll
    frame.bossDetailScroll = bossDetailScroll

    local bossDetailChild = CreateFrame("Frame", nil, bossDetailScroll)
    bossDetailChild:SetSize(1, 1)
    bossDetailChild:SetFrameLevel(bossDetailScroll:GetFrameLevel() + 1)
    bossDetailScroll:SetScrollChild(bossDetailChild)
    ui.bossDetailChild = bossDetailChild
    frame.bossDetailChild = bossDetailChild
    bossDetailScroll:SetScript("OnMouseWheel", function(self, delta)
        if not self.ScrollBar:IsShown() then return end
        local maxOffset = math.max(0, bossDetailChild:GetHeight() - self:GetHeight())
        local offset = self:GetVerticalScroll() - delta * (BOSS_ITEM_HEIGHT + ITEM_GAP) * 2
        self:SetVerticalScroll(math.max(0, math.min(maxOffset, offset)))
    end)

    -- Keep the wishlist count/title and clear button fixed around a scrolling item list.
    local summaryScroll = CreateFrame("ScrollFrame", nil, child, "UIPanelScrollFrameTemplate")
    summaryScroll:SetFrameLevel(child:GetFrameLevel() + 7)
    summaryScroll.ScrollBar.scrollStep = SUMMARY_ITEM_HEIGHT * 2
    summaryScroll.ScrollBar:ClearAllPoints()
    summaryScroll.ScrollBar:SetPoint("TOPRIGHT", summaryScroll, "TOPRIGHT", -2, -16)
    summaryScroll.ScrollBar:SetPoint("BOTTOMRIGHT", summaryScroll, "BOTTOMRIGHT", -2, 16)
    summaryScroll.ScrollBar:Hide()
    BG.CreateSrollBarBackdrop(summaryScroll.ScrollBar)
    summaryScroll:EnableMouseWheel(false)
    summaryScroll:Hide()
    ui.summaryScroll = summaryScroll
    frame.summaryScroll = summaryScroll

    local summaryChild = CreateFrame("Frame", nil, summaryScroll)
    summaryChild:SetSize(1, 1)
    summaryChild:SetFrameLevel(summaryScroll:GetFrameLevel() + 1)
    summaryScroll:SetScrollChild(summaryChild)
    ui.summaryChild = summaryChild
    frame.summaryChild = summaryChild
    summaryScroll:SetScript("OnMouseWheel", function(self, delta)
        if not self.ScrollBar:IsShown() then return end
        local maxOffset = math.max(0, summaryChild:GetHeight() - self:GetHeight())
        local offset = self:GetVerticalScroll() - delta * SUMMARY_ITEM_HEIGHT * 2
        self:SetVerticalScroll(math.max(0, math.min(maxOffset, offset)))
    end)

    scroll:SetScript("OnSizeChanged", function(self, width)
        local newWidth = math.max(1, width - 28)
        if math.abs(child:GetWidth() - newWidth) > 1 then
            child:SetWidth(newWidth)
            Wishlist.Refresh()
        end
    end)

    frame:SetScript("OnShow", function()
        BG.FrameHide(0)
        BiaoGe.lastFrame = "Wishlist"
        BG.TabButtonsFB:Show()
        for _, FB in ipairs(BG.FBtable) do
            BG["Button" .. FB]:SetEnabled(FB ~= BG.FB1)
        end
        if BG.NanDuDropDown then BG.NanDuDropDown.DropDown:Hide() end
        Wishlist.Refresh()
    end)

    BG.Create_TabButton(BG.WishlistMainFrameTabNum, L["心愿清单"], frame)
end

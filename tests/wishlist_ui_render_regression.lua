local frames = {}
local regions = {}
unpack = unpack or table.unpack

local Region = {}
Region.__index = function(_, key)
    return Region[key] or function() end
end

local function NewRegion()
    local region = setmetatable({ shown = true }, Region)
    table.insert(regions, region)
    return region
end

function Region:Show() self.shown = true end
function Region:Hide() self.shown = false end
function Region:IsShown() return self.shown end
function Region:SetFont(font, size, flags)
    self.font = font
    self.fontSize = size
    self.fontFlags = flags
end
function Region:SetText(text)
    if rawget(self, "regionType") == "FontString" and not rawget(self, "font") then
        error("FontString:SetText(): Font not set")
    end
    self.text = text
end
function Region:GetText() return self.text end
function Region:SetWidth(width) self.width = width end
function Region:SetHeight(height) self.height = height end
function Region:SetSize(width, height) self.width, self.height = width, height end
function Region:SetTexture(texture) self.texture = texture end
function Region:SetVertexColor(r, g, b, a) self.vertexColor = { r, g, b, a } end
function Region:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a } end
function Region:SetAlpha(alpha) self.alpha = alpha end
function Region:SetWordWrap(enabled) self.wordWrap = enabled end
function Region:SetHighlightTexture(texture) self.highlightTexture = texture end
function Region:GetWidth() return rawget(self, "width") or 1275 end
function Region:GetHeight() return rawget(self, "height") or 800 end
function Region:GetFrameLevel() return rawget(self, "frameLevel") or 1 end
function Region:SetFrameLevel(level) self.frameLevel = level end
function Region:SetParent(parent) self.parent = parent end
function Region:GetParent() return rawget(self, "parent") end
function Region:SetShown(shown) self.shown = shown end
function Region:SetEnabled(enabled) self.enabled = enabled end
function Region:EnableMouseWheel(enabled) self.mouseWheelEnabled = enabled end
function Region:ClearAllPoints() self.pointCalls = {} end
function Region:SetPoint(...)
    local points = rawget(self, "pointCalls") or {}
    self.pointCalls = points
    table.insert(points, { ... })
end
function Region:SetScript(script, callback)
    local scripts = rawget(self, "scripts") or {}
    self.scripts = scripts
    scripts[script] = callback
end
function Region:CreateTexture(_, layer)
    local region = NewRegion()
    region.drawLayer = layer
    return region
end
function Region:CreateFontString()
    local region = NewRegion()
    region.regionType = "FontString"
    region.parent = self
    return region
end
function Region:GetVerticalScroll() return rawget(self, "verticalScroll") or 0 end
function Region:SetVerticalScroll(offset) self.verticalScroll = offset end
function Region:SetScrollChild(child) self.scrollChild = child end
function Region:UpdateScrollChildRect() end
function Region:Show()
    self.shown = true
    local scripts = rawget(self, "scripts")
    if scripts and scripts.OnShow then scripts.OnShow(self) end
end

local function NewFrame(parent)
    local frame = NewRegion()
    frame.parent = parent
    frame.ScrollBar = NewRegion()
    table.insert(frames, frame)
    return frame
end

CreateFrame = function(_, _, parent)
    return NewFrame(parent)
end

BIAOGE_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
YES, NO = "Yes", "No"
StaticPopupDialogs = {}
StaticPopup_Show = function() end
UIErrorsFrame = NewRegion()
GameTooltip = NewRegion()
ITEM_QUALITY_COLORS = {
    [1] = { r = 1, g = 1, b = 1 },
    [3] = { r = 0, g = 0.44, b = 0.87 },
    [4] = { r = 0.64, g = 0.21, b = 0.93 },
    [5] = { r = 1, g = 0.5, b = 0 },
}
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92, colorStr = "ff40c7eb" } }
INVTYPE_WRIST = "手腕"

GetRealmID = function() return 42 end
UnitClass = function() return "Mage", "MAGE" end
local classInfo = {
    { "战士", "WARRIOR" }, { "圣骑士", "PALADIN" }, { "猎人", "HUNTER" },
    { "潜行者", "ROGUE" }, { "牧师", "PRIEST" }, { "死亡骑士", "DEATHKNIGHT" },
    { "萨满祭司", "SHAMAN" }, { "法师", "MAGE" }, { "德鲁伊", "DRUID" },
}
GetNumClasses = function() return #classInfo end
GetClassInfo = function(index) return unpack(classInfo[index]) end
GetItemInfo = function(itemID)
    itemID = tonumber(itemID)
    local texture
    if itemID ~= 100 then texture = 134400 + itemID end
    return "Item " .. itemID, "|Hitem:" .. itemID .. "|h[Item " .. itemID .. "]|h", 4, 245,
        80, "护甲", "板甲", 1, "INVTYPE_WRIST", texture
end
C_Item = {
    GetItemIconByID = function(itemID)
        return "Interface\\Icons\\Resolved" .. itemID
    end,
}

BiaoGe = { options = {} }
BG = {
    IsTitan = true,
    playerName = "CurrentPlayer",
    FB1 = "RAID_A",
    FB2 = "RAID_A",
    FBtable = { "RAID_A" },
    phaseFBtable = { RAID_A = { "RAID_A" } },
    iconTexCoord = { 0.07, 0.93, 0.07, 0.93 },
    scrollStep = 80,
    Loot = {
        RAID_A = {
            N = {
                boss1 = { 100, 200 },
                boss2 = { 130 },
                boss3 = { 110, 120 },
            },
            ExchangeItems = { [200] = { 201 } },
        },
        encounterID = {
            RAID_A = {
                [1] = { 9001 },
                [2] = { 0 },
                [3] = { 9003 },
            },
        },
    },
    Boss = { RAID_A = {
        boss1 = { name2 = "Test Boss", color = "FFD100" },
        boss2 = { name2 = "限时宝箱", color = "FFFF00" },
        boss3 = { name2 = "Second Boss", color = "7CFF72" },
    } },
    RegisterEvent = function() end,
    MainFrame = NewFrame(),
    TabButtonsFB = NewRegion(),
    ButtonRAID_A = NewRegion(),
    FrameHide = function() end,
    CreateButton = function(parent) return NewFrame(parent) end,
    CreateSrollBarBackdrop = function() end,
    Create_TabButton = function() end,
    GetFBinfo = function() return "Raid A" end,
    PlaySound = function() end,
}
-- The real main frame can briefly report a tiny width while its anchored
-- children are settling. Rendering must use the visible scroll viewport and
-- never create negative-width item buttons.
BG.MainFrame:SetSize(1, 900)

local filterControlMounts = 0
BG.SpecGearFilter = {
    CreateControls = function(parent)
        filterControlMounts = filterControlMounts + 1
        local controls = NewFrame(parent)
        controls.isWishlistFilterControls = true
        return controls
    end,
    ApplyToCell = function(button, link)
        button.appliedFilterLink = link
        button:SetAlpha(link == "item:100" and 0.4 or 1)
    end,
}

local L = setmetatable({}, { __index = function(_, key) return key end })
local namespace = {
    L = L,
    HopeMaxb = { RAID_A = 3 },
    GetItemID = function(value) return tonumber(value) end,
}

local dataChunk = assert(loadfile("Core/Module/Wishlist.lua"))
dataChunk("BGForge", namespace)
local uiChunk = assert(loadfile("Core/Module/WishlistUI.lua"))
uiChunk("BGForge", namespace)

local buildBrowseModel = BG.Wishlist.BuildBrowseModel
BG.Wishlist.BuildBrowseModel = function(FB)
    local model = buildBrowseModel(FB, function() end)
    model.setGroups = {
        {
            key = "MAGE,ROGUE,PALADIN",
            classes = { "MAGE", "ROGUE", "PALADIN" },
            isCurrent = true,
            items = { { itemID = 301, sourceBosses = { 1 } } },
        },
        {
            key = "DEATHKNIGHT,DRUID,PRIEST",
            classes = { "DEATHKNIGHT", "DRUID", "PRIEST" },
            isCurrent = false,
            items = { { itemID = 302, sourceBosses = { 1 } } },
        },
        {
            key = "HUNTER,SHAMAN,WARRIOR",
            classes = { "HUNTER", "SHAMAN", "WARRIOR" },
            isCurrent = false,
            items = { { itemID = 303, sourceBosses = { 1 } } },
        },
    }
    return model
end

assert(BG.Wishlist.Add(100, "RAID_A", 1), "test wishlist item should be selectable")
BG.Wishlist.CreateUI()
BG.WishlistMainFrame:Show()

local visibleItems = 0
local selectedBrowseItem
local setBrowseItem
local summaryItem
local genericBossPortrait
local bossDetailHeader
local bossRows = {}
local setHeaders = {}
local summaryTitle
for _, region in ipairs(regions) do
    if rawget(region, "regionType") == "FontString"
        and rawget(region, "text") == "本阶段心愿（1）" then
        summaryTitle = region
        break
    end
end
for _, frame in ipairs(frames) do
    if rawget(frame, "itemID") and frame:IsShown() then
        visibleItems = visibleItems + 1
        if rawget(frame, "itemID") == 100 then
            if rawget(frame, "isSummary") then
                summaryItem = frame
            else
                selectedBrowseItem = frame
            end
        elseif rawget(frame, "itemID") == 301 then
            setBrowseItem = frame
        end
        assert(frame:GetWidth() > 0, "wishlist item cards must keep a positive width")
    end
    local portrait = rawget(frame, "portrait")
    if rawget(frame, "isBossDirectoryRow") and frame:IsShown() then
        table.insert(bossRows, frame)
    elseif rawget(frame, "isBossDetailHeader") and frame:IsShown() then
        genericBossPortrait = rawget(portrait, "texture")
        bossDetailHeader = frame
    elseif rawget(frame, "isSetGroupHeader") and frame:IsShown() then
        table.insert(setHeaders, frame)
    end
end

assert(BG.WishlistMainFrame.child:GetHeight() > 1, "wishlist scroll child should have rendered content height")
assert(filterControlMounts == 1 and BG.WishlistMainFrame.filterControls,
    "wishlist header should mount one shared gear-filter control group")
local filterPoints = BG.WishlistMainFrame.filterControls.pointCalls
assert(filterPoints and filterPoints[1][1] == "TOPRIGHT"
    and filterPoints[1][2] == BG.MainFrame and filterPoints[1][3] == "TOPRIGHT",
    "wishlist gear-filter controls should be anchored in the header's top-right area")
assert(BG.WishlistMainFrame.child.labelLayer:GetFrameLevel() > BG.WishlistMainFrame.child:GetFrameLevel(),
    "wishlist labels should render above opaque panels")
assert(BG.WishlistMainFrame.bossDirectoryScroll:IsShown(),
    "the boss directory should use its own visible scroll frame")
assert(BG.WishlistMainFrame.bossDirectoryScroll.scrollChild == BG.WishlistMainFrame.bossDirectoryChild,
    "the compact boss rows should live inside the independent directory scroller")
assert(BG.WishlistMainFrame.bossDetailScroll:IsShown(),
    "the selected boss drop grid should use its own visible scroll frame")
assert(BG.WishlistMainFrame.bossDetailScroll.scrollChild == BG.WishlistMainFrame.bossDetailChild,
    "boss-detail items should live inside the independent detail scroller")
assert(not BG.WishlistMainFrame.bossDetailScroll.ScrollBar:IsShown(),
    "the boss-detail scrollbar should stay hidden when all drops fit")
assert(BG.WishlistMainFrame.summaryScroll:IsShown(),
    "the current wishlist should use its own visible scroll frame")
assert(BG.WishlistMainFrame.summaryScroll.scrollChild == BG.WishlistMainFrame.summaryChild,
    "wishlist items should live inside the independent summary scroller")
assert(not BG.WishlistMainFrame.summaryScroll.ScrollBar:IsShown(),
    "the wishlist scrollbar should stay hidden when all entries fit")
assert(not BG.WishlistMainFrame.bossDirectoryScroll.ScrollBar:IsShown(),
    "the boss-directory scrollbar should stay hidden when all boss rows fit")
local scrollBarPoints = BG.WishlistMainFrame.bossDirectoryScroll.ScrollBar.pointCalls
assert(scrollBarPoints and scrollBarPoints[1][1] == "TOPRIGHT"
    and scrollBarPoints[1][2] == BG.WishlistMainFrame.bossDirectoryScroll
    and scrollBarPoints[1][3] == "TOPRIGHT"
    and scrollBarPoints[1][4] == -2,
    "the boss-directory scrollbar should be anchored inside the directory's right edge")
assert(visibleItems > 0, "wishlist should render at least one visible item card")
assert(selectedBrowseItem.appliedFilterLink == "item:100" and selectedBrowseItem.alpha == 0.4,
    "boss-detail items that do not match the selected filter should be dimmed")
assert(summaryItem.appliedFilterLink == "item:100" and summaryItem.alpha == 0.4,
    "current wishlist items that do not match the selected filter should be dimmed")
assert(setBrowseItem.appliedFilterLink == "item:301" and setBrowseItem.alpha == 1,
    "wishlist items that match the selected filter should remain fully visible")
assert(summaryTitle, "wishlist summary should render its title")
assert(summaryTitle:GetWidth() > 0 and summaryTitle:GetWidth() < 250,
    "wishlist summary title should be constrained to the narrow right column")
assert(summaryTitle.wordWrap == false,
    "wishlist summary title should stay on one line inside its column")
assert(summaryTitle:GetParent() ~= BG.WishlistMainFrame.summaryChild,
    "the wishlist summary title should remain outside the scrolling item list")
assert(selectedBrowseItem:GetHeight() == 42,
    "boss-detail item rows should make room for one compact metadata line")
assert(selectedBrowseItem:GetParent() == BG.WishlistMainFrame.bossDetailChild,
    "boss-detail item rows should be clipped by the detail scroll child")
assert(selectedBrowseItem.meta:IsShown(),
    "boss-detail item rows should show slot and equipment type metadata")
assert(selectedBrowseItem.meta:GetText() == "手腕，板甲",
    "boss-detail metadata should combine the localized slot and item subtype")
assert(setBrowseItem:GetHeight() == 34 and not setBrowseItem.meta:IsShown(),
    "class-set items should keep the original compact single-line treatment")
assert(rawget(selectedBrowseItem, "qualityBorder"), "item quality color should frame only the icon")
assert(selectedBrowseItem.qualityBorder:GetWidth() == 32,
    "item quality frame should leave only a one-pixel border around the icon")
assert(selectedBrowseItem.icon:GetWidth() == 30, "item icon should be smaller than its quality frame")
assert(rawget(selectedBrowseItem.qualityBorder, "drawLayer") == "BACKGROUND",
    "the quality frame must render behind the item icon")
assert(rawget(selectedBrowseItem.icon, "drawLayer") == "ARTWORK", "the item icon must render above its quality frame")
assert(rawget(selectedBrowseItem.icon, "texture") == "Interface\\Icons\\Resolved100",
    "partially cached items should resolve their icon through C_Item; got " ..
    tostring(rawget(selectedBrowseItem.icon, "texture")))
assert(not rawget(selectedBrowseItem, "detail"), "compact item rows should not render slot details")
assert(selectedBrowseItem.level:GetText() == "245", "item level should be embedded in the item icon")
assert(not rawget(selectedBrowseItem, "check"), "selected items should not render a glyph over the item icon")
assert(selectedBrowseItem.selectedBackground:IsShown(),
    "selected browse items should keep a persistent row highlight")
assert(selectedBrowseItem.selectedBackground.vertexColor[1] == 0.36
    and selectedBrowseItem.selectedBackground.vertexColor[2] == 0.25
    and selectedBrowseItem.selectedBackground.vertexColor[3] == 0.06
    and selectedBrowseItem.selectedBackground.vertexColor[4] == 0.82,
    "selected browse items should use the brighter brown selected state")
assert(selectedBrowseItem.highlightTexture == selectedBrowseItem.hoverBackground,
    "browse item rows should register their hover background as the highlight texture")
assert(selectedBrowseItem.hoverBackground.vertexColor[1] == 0.28
    and selectedBrowseItem.hoverBackground.vertexColor[2] == 0.18
    and selectedBrowseItem.hoverBackground.vertexColor[3] == 0.05
    and selectedBrowseItem.hoverBackground.vertexColor[4] == 0.26,
    "item hover should use the darker brown hover overlay")
assert(selectedBrowseItem.name.textColor[1] == ITEM_QUALITY_COLORS[4].r
    and selectedBrowseItem.name.textColor[2] == ITEM_QUALITY_COLORS[4].g
    and selectedBrowseItem.name.textColor[3] == ITEM_QUALITY_COLORS[4].b,
    "selected item names should keep their quality color")
selectedBrowseItem.sourceBosses = rawget(selectedBrowseItem, "sourceBosses") or {}
selectedBrowseItem.scripts.OnEnter(selectedBrowseItem)
assert(selectedBrowseItem.name.textColor[1] == ITEM_QUALITY_COLORS[4].r
    and selectedBrowseItem.name.textColor[2] == ITEM_QUALITY_COLORS[4].g
    and selectedBrowseItem.name.textColor[3] == ITEM_QUALITY_COLORS[4].b,
    "hovering an item should not replace its quality-colored name")
selectedBrowseItem.scripts.OnLeave(selectedBrowseItem)
assert(summaryItem:GetHeight() == 42, "wishlist summary items should use separated action rows")
assert(summaryItem:GetParent() == BG.WishlistMainFrame.summaryChild,
    "wishlist summary items should be clipped by the summary scroll child")
assert(not summaryItem.meta:IsShown(),
    "wishlist summary rows should not duplicate the boss-detail metadata line")
assert(summaryItem.summaryBackground:IsShown(), "wishlist summary rows should use their own subtle surface")
assert(summaryItem.divider:IsShown(), "wishlist summary rows should have separators")
assert(summaryItem.removeIcon:IsShown(), "wishlist summary rows should expose a remove icon")
assert(summaryItem.removeIcon.texture == "Interface\\Buttons\\UI-Panel-MinimizeButton-Up",
    "wishlist summary removal should use Blizzard's close-button texture")
assert(not summaryItem.selectedBackground:IsShown(),
    "wishlist summary rows should use a remove affordance instead of the browse selection highlight")
assert(genericBossPortrait == "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
    "bosses without portraits should use the neutral built-in boss marker")
assert(bossDetailHeader:GetHeight() == 44, "the selected boss detail should use a compact single-line header")
assert(bossDetailHeader:GetParent() == BG.WishlistMainFrame.child,
    "the selected boss header should remain outside the scrolling drop grid")
assert(bossDetailHeader.title:GetText() == "1号 · Test Boss",
    "the selected boss detail should prefix the database boss number")
assert(not bossDetailHeader.subtitle:IsShown(), "boss detail headers should hide loot counts")
assert(rawget(bossDetailHeader, "action") == nil, "the selected boss detail should not act as an accordion")
assert(bossDetailHeader.arrow:GetText() == "", "boss detail headers should not render accordion symbols")
assert(#bossRows == 3, "the boss directory should render one compact row per drop source")
assert(bossRows[1].bossIndex == 1 and bossRows[2].bossIndex == 3 and bossRows[3].bossIndex == 2,
    "real bosses should keep raid order while non-boss drop sources move to the end")
table.sort(bossRows, function(left, right) return left.bossIndex < right.bossIndex end)
assert(bossRows[1]:GetHeight() == 36 and bossRows[2]:GetHeight() == 36 and bossRows[3]:GetHeight() == 36,
    "boss directory rows should stay dense")
assert(bossRows[1].title:GetText() == "1号 · Test Boss"
    and bossRows[2].title:GetText() == "限时宝箱"
    and bossRows[3].title:GetText() == "3号 · Second Boss",
    "boss directory rows should number bosses but not auxiliary drop sources")
assert(bossRows[1].count:GetText() == "1" and bossRows[2].count:GetText() == "0"
    and bossRows[3].count:GetText() == "0",
    "boss directory trailing numbers should count wishes attributed to each boss")
assert(bossRows[1].selectedBackground:IsShown() and not bossRows[2].selectedBackground:IsShown()
    and not bossRows[3].selectedBackground:IsShown(),
    "the active boss should use the persistent selected-row background")
assert(bossRows[1].count.textColor[1] == 0 and bossRows[1].count.textColor[2] == 0.75,
    "non-zero boss wish counts should use cyan emphasis")
assert(bossRows[2].count.textColor[1] == 0.63 and bossRows[2].count.textColor[2] == 0.67,
    "zero boss wish counts should stay muted")

bossRows[3].action()
local refreshedBossRows = {}
local refreshedBossHeader
local bossOneBrowseVisible = false
local bossTwoBrowseVisible = false
for _, frame in ipairs(frames) do
    if rawget(frame, "isBossDirectoryRow") and frame:IsShown() then
        table.insert(refreshedBossRows, frame)
    elseif rawget(frame, "isBossDetailHeader") and frame:IsShown() then
        refreshedBossHeader = frame
    elseif rawget(frame, "itemID") and frame:IsShown() and not rawget(frame, "isSummary") then
        if rawget(frame, "itemID") == 100 then bossOneBrowseVisible = true end
        if rawget(frame, "itemID") == 110 or rawget(frame, "itemID") == 120 then bossTwoBrowseVisible = true end
    end
end
table.sort(refreshedBossRows, function(left, right) return left.bossIndex < right.bossIndex end)
assert(not refreshedBossRows[1].selectedBackground:IsShown()
    and not refreshedBossRows[2].selectedBackground:IsShown()
    and refreshedBossRows[3].selectedBackground:IsShown(),
    "clicking the boss directory should move the active-row highlight")
assert(refreshedBossHeader.title:GetText() == "3号 · Second Boss",
    "clicking a boss should replace the detail header")
assert(not bossOneBrowseVisible and bossTwoBrowseVisible,
    "the detail grid should show only the active boss's drops")
refreshedBossRows[1].action()

setHeaders = {}
for _, frame in ipairs(frames) do
    if rawget(frame, "isSetGroupHeader") and frame:IsShown() then
        table.insert(setHeaders, frame)
    end
end
assert(#setHeaders == 3, "the set module should render all three class categories")
local firstSetX
local previousSetY
for _, header in ipairs(setHeaders) do
    local topLeft = rawget(header, "pointCalls") and header.pointCalls[1]
    assert(topLeft and topLeft[1] == "TOPLEFT", "set category headers should have a top-left column anchor")
    local x, y = topLeft[2], topLeft[3]
    firstSetX = firstSetX or x
    assert(x == firstSetX, "all set category headers should share the left workbench column")
    if previousSetY then assert(y < previousSetY, "set category headers should stack vertically") end
    previousSetY = y
end
assert(setHeaders[1].checkmark:IsShown(), "the active set category should use a real checkmark texture")
assert(not setHeaders[2].checkmark:IsShown() and not setHeaders[3].checkmark:IsShown(),
    "inactive set categories should not look selected")
assert(setHeaders[1].arrow:GetText() == "" and setHeaders[2].arrow:GetText() == "",
    "set categories should not use expand or collapse symbols")
local activeSetTitle = setHeaders[1].title:GetText()
assert(not activeSetTitle:find("法师", 1, true)
    and not activeSetTitle:find("潜行者", 1, true)
    and not activeSetTitle:find("圣骑士", 1, true),
    "class-set category labels should not render full class names")
assert(activeSetTitle:find("法|r", 1, true)
    and activeSetTitle:find("潜|r", 1, true)
    and activeSetTitle:find("圣|r", 1, true),
    "class-set category labels should render the first UTF-8 character of each class name")
assert(not activeSetTitle:find(" · ", 1, true)
    and activeSetTitle:find("|r·|cff", 1, true),
    "class-set category abbreviations should use compact separators without surrounding spaces")

setHeaders[2].action()
local firstGroupVisible
local secondGroupVisible
local refreshedSetHeaders = {}
for _, frame in ipairs(frames) do
    if rawget(frame, "itemID") == 301 then firstGroupVisible = frame:IsShown() end
    if rawget(frame, "itemID") == 302 then secondGroupVisible = frame:IsShown() end
    if rawget(frame, "isSetGroupHeader") and frame:IsShown() then
        table.insert(refreshedSetHeaders, frame)
    end
end
assert(not firstGroupVisible and secondGroupVisible,
    "clicking a set category should switch the shared item area to that group")
assert(not refreshedSetHeaders[1].checkmark:IsShown() and refreshedSetHeaders[2].checkmark:IsShown(),
    "switching class categories should move the single selection checkmark")

local currentSummaryItem
for _, frame in ipairs(frames) do
    if rawget(frame, "isSummary") and rawget(frame, "itemID") == 100 and frame:IsShown() then
        currentSummaryItem = frame
        break
    end
end
assert(currentSummaryItem, "the selected wishlist item should still be present before removal")
currentSummaryItem.action()
assert(not BG.Wishlist.IsWishlisted(100, "RAID_A"),
    "clicking a wishlist summary row should remove that item")

namespace.HopeMaxb.RAID_A = 30
for bossIndex = 4, 30 do
    BG.Loot.RAID_A.N["boss" .. bossIndex] = { 400 + bossIndex }
    BG.Loot.encounterID.RAID_A[bossIndex] = { 9000 + bossIndex }
    BG.Boss.RAID_A["boss" .. bossIndex] = {
        name2 = "Overflow Boss " .. bossIndex,
        color = "FFD100",
    }
end
BG.Wishlist.Refresh()
assert(BG.WishlistMainFrame.bossDirectoryScroll.ScrollBar:IsShown(),
    "the boss-directory scrollbar should appear when boss rows exceed the available height")
assert(BG.WishlistMainFrame.bossDirectoryChild:GetWidth()
    == BG.WishlistMainFrame.bossDirectoryScroll:GetWidth() - 22,
    "overflowing boss rows should reserve scrollbar width inside the directory")

local pageHeightBeforeDetailOverflow = BG.WishlistMainFrame.child:GetHeight()
local overflowItems = {}
for itemIndex = 1, 60 do
    table.insert(overflowItems, 1000 + itemIndex)
end
BG.Loot.RAID_A.N.boss1 = overflowItems
bossRows[1].action()
assert(BG.WishlistMainFrame.bossDetailScroll.ScrollBar:IsShown(),
    "the boss-detail scrollbar should appear when the selected boss has too many drops")
assert(BG.WishlistMainFrame.bossDetailChild:GetHeight()
    > BG.WishlistMainFrame.bossDetailScroll:GetHeight(),
    "overflowing boss drops should expand only the detail scroll child")
assert(BG.WishlistMainFrame.bossDetailChild:GetWidth()
    == BG.WishlistMainFrame.bossDetailScroll:GetWidth() - 22,
    "overflowing boss drops should reserve scrollbar width inside the detail area")
assert(BG.WishlistMainFrame.child:GetHeight() == pageHeightBeforeDetailOverflow,
    "boss-drop overflow should not increase the outer wishlist page height")

local overflowBossItem
local fixedBossHeader
for _, frame in ipairs(frames) do
    if rawget(frame, "itemID") == overflowItems[1] and frame:IsShown() then
        overflowBossItem = frame
    elseif rawget(frame, "isBossDetailHeader") and frame:IsShown() then
        fixedBossHeader = frame
    end
end
assert(overflowBossItem and overflowBossItem:GetParent() == BG.WishlistMainFrame.bossDetailChild,
    "overflowing boss items should remain inside the detail scroll child")
assert(fixedBossHeader and fixedBossHeader:GetParent() == BG.WishlistMainFrame.child,
    "the boss title should remain fixed outside the overflowing detail scroll child")
local oldDetailOffset = BG.WishlistMainFrame.bossDetailScroll:GetVerticalScroll()
BG.WishlistMainFrame.bossDetailScroll.scripts.OnMouseWheel(BG.WishlistMainFrame.bossDetailScroll, -1)
assert(BG.WishlistMainFrame.bossDetailScroll:GetVerticalScroll() > oldDetailOffset,
    "mouse-wheel input over the boss detail should scroll only its item grid")

local pageHeightBeforeSummaryOverflow = BG.WishlistMainFrame.child:GetHeight()
for itemIndex = 1, 20 do
    assert(BG.Wishlist.Add(overflowItems[itemIndex], "RAID_A", 1),
        "overflow test drops should be selectable as wishlist entries")
end
assert(BG.WishlistMainFrame.summaryScroll.ScrollBar:IsShown(),
    "the wishlist scrollbar should appear when the current entries exceed its item area")
assert(BG.WishlistMainFrame.summaryChild:GetHeight() > BG.WishlistMainFrame.summaryScroll:GetHeight(),
    "wishlist overflow should expand only the summary scroll child")
assert(BG.WishlistMainFrame.summaryChild:GetWidth()
    == BG.WishlistMainFrame.summaryScroll:GetWidth() - 22,
    "overflowing wishlist entries should reserve scrollbar width inside the summary area")
assert(BG.WishlistMainFrame.child:GetHeight() == pageHeightBeforeSummaryOverflow,
    "wishlist overflow should not increase the outer wishlist page height")

local overflowSummaryItem
local fixedSummaryTitle
for _, frame in ipairs(frames) do
    if rawget(frame, "isSummary") and rawget(frame, "itemID") == overflowItems[1] and frame:IsShown() then
        overflowSummaryItem = frame
    end
end
for _, region in ipairs(regions) do
    if rawget(region, "regionType") == "FontString"
        and rawget(region, "text") == "本阶段心愿（20）" then
        fixedSummaryTitle = region
        break
    end
end
assert(overflowSummaryItem and overflowSummaryItem:GetParent() == BG.WishlistMainFrame.summaryChild,
    "overflowing wishlist items should remain inside the summary scroll child")
assert(fixedSummaryTitle and fixedSummaryTitle:GetParent() ~= BG.WishlistMainFrame.summaryChild,
    "the wishlist title should remain fixed outside the overflowing summary scroll child")
assert(BG.WishlistMainFrame.clearButton:GetParent() == BG.WishlistMainFrame.child,
    "the clear-wishlist button should remain outside the scrolling summary item list")
local oldSummaryOffset = BG.WishlistMainFrame.summaryScroll:GetVerticalScroll()
BG.WishlistMainFrame.summaryScroll.scripts.OnMouseWheel(BG.WishlistMainFrame.summaryScroll, -1)
assert(BG.WishlistMainFrame.summaryScroll:GetVerticalScroll() > oldSummaryOffset,
    "mouse-wheel input over the wishlist should scroll only its item list")

print("Wishlist UI render regression tests passed")

unpack = unpack or table.unpack

local Region = {}
Region.__index = Region

local function NewRegion(parent)
    return setmetatable({ parent = parent, hooks = {}, scripts = {}, textures = {}, shown = true }, Region)
end

function Region:SetBackdrop(backdrop) self.backdrop = backdrop end
function Region:SetBackdropColor(...) self.backdropColor = { ... } end
function Region:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
function Region:SetTexture(texture) self.texture = texture end
function Region:SetColorTexture(...) self.colorTexture = { ... } end
function Region:SetVertexColor(...) self.vertexColor = { ... } end
function Region:SetGradient(...) self.gradient = { ... } end
function Region:SetBlendMode(mode) self.blendMode = mode end
function Region:SetAlpha(alpha) self.alpha = alpha end
function Region:SetPoint(...)
    self.pointCalls = self.pointCalls or {}
    table.insert(self.pointCalls, { ... })
end
function Region:SetAllPoints() self.allPoints = true end
function Region:SetSize(width, height) self.width, self.height = width, height end
function Region:SetWidth(width) self.width = width end
function Region:SetHeight(height) self.height = height end
function Region:SetJustifyH(value) self.justifyH = value end
function Region:SetJustifyV(value) self.justifyV = value end
function Region:SetWordWrap(value) self.wordWrap = value end
function Region:SetFont(font, size, flags) self.font, self.fontSize, self.fontFlags = font, size, flags end
function Region:SetTextColor(...) self.textColor = { ... } end
function Region:SetShadowColor(...) self.shadowColor = { ... } end
function Region:SetShadowOffset(...) self.shadowOffset = { ... } end
function Region:SetText(text) self.text = text end
function Region:GetText() return self.text or "" end
function Region:SetAutoFocus(value) self.autoFocus = value end
function Region:SetTextInsets(left, right, top, bottom) self.textInsets = { left, right, top, bottom } end
function Region:SetMaxLetters(value) self.maxLetters = value end
function Region:SetDesaturated(value) self.desaturated = value end
function Region:SetTexCoord(...) self.texCoord = { ... } end
function Region:SetShown(value) self.shown = value end
function Region:Show() self.shown = true end
function Region:Hide() self.shown = false end
function Region:IsShown() return self.shown end
function Region:ClearFocus() self.hasFocus = false end
function Region:SetFontString(fontString) self.fontString = fontString end
function Region:GetFontString() return self.fontString end
function Region:IsMouseOver() return self.mouseOver end
function Region:SetScript(name, callback) self.scripts[name] = callback end
function Region:HookScript(name, callback)
    self.hooks[name] = self.hooks[name] or {}
    table.insert(self.hooks[name], callback)
end
function Region:Fire(name, ...)
    if self.scripts[name] then self.scripts[name](self, ...) end
    for _, callback in ipairs(self.hooks[name] or {}) do
        callback(self, ...)
    end
end
function Region:CreateTexture()
    local texture = NewRegion(self)
    table.insert(self.textures, texture)
    return texture
end
function Region:CreateFontString()
    return NewRegion(self)
end

CreateFrame = function(_, _, parent)
    return NewRegion(parent)
end
CreateColor = function(...)
    return { ... }
end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
BIAOGE_TEXT_FONT = "Fonts\\ARHei.TTF"
BG = {}

local chunk = assert(loadfile("Core/UI/DesignSystem.lua"))
chunk("BGForge", {})

local function NearlyEqual(left, right)
    return math.abs(left - right) < 0.0001
end

local focus = BG.UI.Token("color", "focus")
focus[1] = 0
assert(BG.UI.Token("color", "focus")[1] > 0, "Token returned a mutable source table")
assert(BG.UI.Token("spacing", "sm") == 8, "Unexpected spacing token")

local function AssertColor(token, red, green, blue)
    local color = BG.UI.Token("color", token)
    assert(NearlyEqual(color[1], red / 255), token .. " red channel drifted")
    assert(NearlyEqual(color[2], green / 255), token .. " green channel drifted")
    assert(NearlyEqual(color[3], blue / 255), token .. " blue channel drifted")
end

AssertColor("canvas", 0x0B, 0x11, 0x18)
AssertColor("panel", 0x10, 0x18, 0x20)
AssertColor("focusSurface", 0x24, 0x30, 0x45)
AssertColor("focusSurfaceSubtle", 0x18, 0x26, 0x34)
AssertColor("focus", 0x5D, 0x8F, 0xB2)
AssertColor("forgeGold", 0xD3, 0xA2, 0x3A)
AssertColor("success", 0x62, 0xC9, 0x78)
AssertColor("successSurface", 0x17, 0x38, 0x24)
AssertColor("rowHoverWash", 0xA7, 0xB3, 0xBD)
assert(NearlyEqual(BG.UI.Token("color", "rowHoverWash")[4], 0.055),
    "Row hover wash opacity drifted")

local parent = NewRegion()
local panel = BG.UI.Create("surface", parent, { role = "panel" })
assert(panel.backdrop and panel.backdrop.bgFile, "Panel backdrop was not applied")

local title = BG.UI.Create("text", panel, { role = "title", text = "BGForge" })
assert(title.font == BIAOGE_TEXT_FONT and title.fontSize == 16, "Title typography was not applied")
assert(title.text == "BGForge", "Title text was not set")

local compactNumber = BG.UI.Create("text", panel, { role = "numberCompact", text = "238" })
assert(compactNumber.fontSize == 12, "Compact number typography must remain smaller than row text")
assert(compactNumber.font == BIAOGE_TEXT_FONT, "Numeric typography must use the selected game font")
local number = BG.UI.Create("text", panel, { role = "number", text = "238" })
local strongNumber = BG.UI.Create("text", panel, { role = "numberStrong", text = "238" })
assert(number.font == BIAOGE_TEXT_FONT and strongNumber.font == BIAOGE_TEXT_FONT,
    "All numeric typography roles must use the selected game font")

local expectedFocus = BG.UI.Token("color", "focus")
local pageHeader = BG.UI.CreatePageHeader(parent, {
    title = "全角色总览",
    subtitle = "点击角色名称可查看装备、背包、专业、资源与进度",
    contentRightInset = 260,
})
assert(pageHeader._bgforgeKind == "pageHeader" and pageHeader.height == 72,
    "Shared page header should use the standard page-header height")
assert(pageHeader.title.text == "全角色总览" and pageHeader.title.fontSize == 18,
    "Shared page header should apply title content and typography")
assert(pageHeader.subtitle.wordWrap == false and pageHeader.subtitle.fontSize == 14,
    "Shared page-header subtitles should stay readable and single-line")
assert(pageHeader.accent.width == 3 and pageHeader.accent.height == 40,
    "Shared page header should use the short page-header accent")
assert(pageHeader.title.pointCalls[1][1] == "BOTTOMLEFT"
    and pageHeader.title.pointCalls[1][3] == "LEFT"
    and pageHeader.title.pointCalls[1][4] == 18
    and pageHeader.title.pointCalls[2][3] == "RIGHT"
    and pageHeader.subtitle.pointCalls[1][1] == "TOPLEFT"
    and pageHeader.subtitle.pointCalls[1][3] == "LEFT"
    and pageHeader.subtitle.pointCalls[2][3] == "RIGHT"
    and pageHeader.subtitle.pointCalls[1][4] == 18,
    "Shared page-header copy should span the header edges with a positive width")
assert(NearlyEqual(pageHeader.accent.vertexColor[1], expectedFocus[1]),
    "Shared page-header accent should use the focus color")

BiaoGe = { options = { alpha = 0.35 } }
local alphaHeader = BG.UI.CreatePageHeader(parent, {
    title = "透明度联动",
    backgroundAlpha = true,
})
local alphaPanel = BG.UI.Create("surface", parent, { role = "panel" })
BG.UI.BindBackgroundAlpha(alphaPanel, "SetBackdropColor", "panel")
assert(NearlyEqual(alphaHeader.background.vertexColor[4], 0.35)
    and NearlyEqual(alphaPanel.backdropColor[4], 0.35),
    "Opted-in page and module backgrounds should use the shared material opacity")
BiaoGe.options.alpha = 0
BG.UI.RefreshBackgroundAlpha()
assert(alphaHeader.background.vertexColor[4] == 0 and alphaPanel.backdropColor[4] == 0,
    "Background opacity refresh must preserve an explicit zero value")
BiaoGe.options.alpha = 0.8

local tab = BG.UI.Create("tab", panel, {
    text = "纳克萨玛斯",
    state = "selected",
    width = 120,
    height = 28,
})
assert(NearlyEqual(tab.backdropBorderColor[1], expectedFocus[1]), "Selected tab is missing focus border")
assert(tab._bgforgeFocusAccent.alpha == 1, "Selected tab is missing the static focus line")
assert(tab.hooks.OnUpdate == nil, "Persistent selection must not install an OnUpdate animation")

BG.UI.SetState(tab, "default")
tab:Fire("OnEnter")
assert(tab._bgforgeRenderedState == "hover", "Tab hover state was not applied")
tab:Fire("OnLeave")
assert(tab._bgforgeRenderedState == "default", "Tab did not restore its base state")

local button = BG.UI.Create("button", panel, { variant = "primary", text = "保存本行" })
button:Fire("OnMouseDown", "LeftButton")
assert(button._bgforgeRenderedState == "pressed", "Primary button press state was not applied")
button:Fire("OnDisable")
assert(button._bgforgeRenderedState == "disabled", "Disabled button state was not applied")

local dangerButton = BG.UI.Create("button", panel, { variant = "danger", text = "清空当前副本" })
local borderSubtle = BG.UI.Token("color", "borderSubtle")
local textSecondary = BG.UI.Token("color", "textSecondary")
local danger = BG.UI.Token("color", "danger")
assert(NearlyEqual(dangerButton.backdropBorderColor[1], borderSubtle[1])
    and NearlyEqual(dangerButton.fontString.textColor[1], textSecondary[1]),
    "Destructive tools should rest quietly instead of showing a permanent red outline")
dangerButton:Fire("OnEnter")
assert(NearlyEqual(dangerButton.backdropBorderColor[1], danger[1])
    and NearlyEqual(dangerButton.fontString.textColor[1], danger[1]),
    "Destructive tools should reveal danger emphasis on hover")

local input = BG.UI.Create("input", panel, { width = 180, height = 28 })
assert(input.autoFocus == false, "Design-system input should not steal focus")
input:Fire("OnEditFocusGained")
assert(input._bgforgeRenderedState == "focus", "Input focus state was not applied")
BG.UI.SetState(input, "error")
input:Fire("OnEditFocusLost")
assert(input._bgforgeRenderedState == "error", "Input error state was not persistent")

local searchText
local search = BG.UI.CreateSearchInput(panel, {
    width = 220,
    placeholder = "搜索装备名称",
    onTextChanged = function(_, text) searchText = text end,
})
assert(search._bgforgeKind == "input" and search._bgforgeSearchInput
    and search.width == 220 and search.height == 28,
    "Shared search inputs should use the standard design-system input geometry")
assert(search.placeholder.text == "搜索装备名称" and search.placeholder:IsShown()
    and not search.clearButton:IsShown()
    and search.clearButton.width == 24 and search.clearButton.height == 24
    and search.clearButton.icon.width == 14 and search.clearButton.icon.height == 14,
    "Shared search inputs should expose one consistent placeholder and clear affordance")
search:SetText("Needle")
search:Fire("OnTextChanged")
assert(searchText == "Needle" and not search.placeholder:IsShown()
    and search.clearButton:IsShown(),
    "Shared search affordances should react to entered text")
search.clearButton:Fire("OnClick")
assert(search:GetText() == "" and search.placeholder:IsShown()
    and not search.clearButton:IsShown(),
    "Shared search clear buttons should reset the field and its affordances")

print("BGForge design-system regression tests passed")

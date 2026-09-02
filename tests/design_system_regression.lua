unpack = unpack or table.unpack

local Region = {}
Region.__index = Region

local function NewRegion(parent)
    return setmetatable({ parent = parent, hooks = {}, textures = {} }, Region)
end

function Region:SetBackdrop(backdrop) self.backdrop = backdrop end
function Region:SetBackdropColor(...) self.backdropColor = { ... } end
function Region:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
function Region:SetTexture(texture) self.texture = texture end
function Region:SetColorTexture(...) self.colorTexture = { ... } end
function Region:SetGradient(...) self.gradient = { ... } end
function Region:SetBlendMode(mode) self.blendMode = mode end
function Region:SetAlpha(alpha) self.alpha = alpha end
function Region:SetPoint(...) end
function Region:SetAllPoints() self.allPoints = true end
function Region:SetSize(width, height) self.width, self.height = width, height end
function Region:SetWidth(width) self.width = width end
function Region:SetHeight(height) self.height = height end
function Region:SetJustifyH(value) self.justifyH = value end
function Region:SetJustifyV(value) self.justifyV = value end
function Region:SetFont(font, size, flags) self.font, self.fontSize, self.fontFlags = font, size, flags end
function Region:SetTextColor(...) self.textColor = { ... } end
function Region:SetShadowColor(...) self.shadowColor = { ... } end
function Region:SetShadowOffset(...) self.shadowOffset = { ... } end
function Region:SetText(text) self.text = text end
function Region:SetAutoFocus(value) self.autoFocus = value end
function Region:SetFontString(fontString) self.fontString = fontString end
function Region:GetFontString() return self.fontString end
function Region:IsMouseOver() return self.mouseOver end
function Region:HookScript(name, callback)
    self.hooks[name] = self.hooks[name] or {}
    table.insert(self.hooks[name], callback)
end
function Region:Fire(name, ...)
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
AssertColor("focus", 0x5D, 0x8F, 0xB2)
AssertColor("forgeGold", 0xD3, 0xA2, 0x3A)
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

local tab = BG.UI.Create("tab", panel, {
    text = "纳克萨玛斯",
    state = "selected",
    width = 120,
    height = 28,
})
local expectedFocus = BG.UI.Token("color", "focus")
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

local input = BG.UI.Create("input", panel, { width = 180, height = 28 })
assert(input.autoFocus == false, "Design-system input should not steal focus")
input:Fire("OnEditFocusGained")
assert(input._bgforgeRenderedState == "focus", "Input focus state was not applied")
BG.UI.SetState(input, "error")
input:Fire("OnEditFocusLost")
assert(input._bgforgeRenderedState == "error", "Input error state was not persistent")

print("BGForge design-system regression tests passed")

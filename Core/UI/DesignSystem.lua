local _, ns = ...

-- BGForge design-system seam.
--
-- Callers describe intent (panel, tab, primary button, selected state). This
-- module owns the concrete colors, fonts, borders, focus layers, and input
-- feedback so the visual language can change without editing every screen.

local UI = {}
BG.UI = UI

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local NUMBER_FONT = "Interface\\AddOns\\BGForge\\Media\\Fonts\\RobotoCondensed-Medium.ttf"
local BACKDROP = {
    bgFile = WHITE_TEXTURE,
    edgeFile = WHITE_TEXTURE,
    edgeSize = 1,
}

local function HexColor(hex, alpha)
    return {
        tonumber(hex:sub(1, 2), 16) / 255,
        tonumber(hex:sub(3, 4), 16) / 255,
        tonumber(hex:sub(5, 6), 16) / 255,
        alpha == nil and 1 or alpha,
    }
end

local TOKENS = {
    color = {
        -- Arcane Archive: near-black ink surfaces with restrained steel-blue
        -- interaction states. The opacity is deliberate: dense cells must stay
        -- readable over bright and strongly tinted game environments.
        canvas = HexColor("0B1118", 0.97),
        panel = HexColor("101820", 0.95),
        raised = HexColor("18232D", 0.98),
        header = HexColor("131D27", 0.98),
        row = HexColor("101820", 0.96),
        rowAlternate = HexColor("141D27", 0.96),
        hover = HexColor("1A2937", 0.98),
        -- Table rows use this as a very low-alpha neutral lift. Keeping the
        -- wash separate from Rune Blue prevents hover from looking selected.
        rowHoverWash = HexColor("A7B3BD", 0.055),
        pressed = HexColor("1D3142", 0.98),
        focusSurface = HexColor("243045", 0.96),
        overlay = HexColor("070B10", 0.98),

        borderSubtle = HexColor("243644", 0.86),
        borderStrong = HexColor("3A5266", 0.96),
        focus = HexColor("5D8FB2", 1),
        focusText = HexColor("6FB1D0", 1),
        forgeGold = HexColor("D3A23A", 1),

        textPrimary = HexColor("DCE3E8", 1),
        textSecondary = HexColor("ABB6BF", 1),
        textMuted = HexColor("73818C", 1),
        textDisabled = HexColor("56636D", 1),

        success = HexColor("6BC56D", 1),
        successSurface = HexColor("173824", 0.96),
        warning = HexColor("D7A549", 1),
        warningSurface = HexColor("3A2E18", 0.96),
        danger = HexColor("DF6A70", 1),
        dangerSurface = HexColor("3A1F24", 0.96),
    },
    spacing = {
        hairline = 1,
        xxs = 2,
        xs = 4,
        sm = 8,
        md = 12,
        lg = 16,
        xl = 24,
        xxl = 32,
    },
    size = {
        controlCompact = 24,
        control = 28,
        controlComfortable = 32,
        iconSmall = 12,
        icon = 16,
        iconLarge = 20,
        logo = 24,
        focusLine = 2,
    },
}

local TEXT_STYLES = {
    display = { size = 18, color = "textPrimary" },
    title = { size = 16, color = "textPrimary" },
    heading = { size = 14, color = "textPrimary" },
    body = { size = 14, color = "textPrimary" },
    label = { size = 12, color = "textSecondary" },
    caption = { size = 11, color = "textMuted" },
    numberCompact = { size = 12, color = "textPrimary", font = NUMBER_FONT },
    number = { size = 14, color = "textPrimary", font = NUMBER_FONT },
    numberStrong = { size = 16, color = "forgeGold", font = NUMBER_FONT },
}

local SURFACES = {
    canvas = { background = "canvas", border = "borderSubtle" },
    panel = { background = "panel", border = "borderSubtle" },
    raised = { background = "raised", border = "borderStrong" },
    header = { background = "header", border = "borderSubtle" },
    row = { background = "row", border = "borderSubtle" },
    rowAlternate = { background = "rowAlternate", border = "borderSubtle" },
    selected = { background = "focusSurface", border = "focus" },
    overlay = { background = "overlay", border = "borderStrong" },
}

local INTERACTIONS = {
    tab = {
        default = { background = "header", border = "borderSubtle", text = "textSecondary" },
        hover = { background = "hover", border = "borderStrong", text = "textPrimary" },
        pressed = { background = "pressed", border = "focus", text = "textPrimary", wash = 0.10 },
        selected = {
            background = "focusSurface", border = "focus", text = "focusText",
            wash = 0.18, accent = 1,
        },
        disabled = { background = "panel", border = "borderSubtle", text = "textDisabled" },
    },
    primary = {
        default = { background = "focusSurface", border = "focus", text = "textPrimary", wash = 0.12 },
        hover = { background = "hover", border = "focusText", text = "textPrimary", wash = 0.18 },
        pressed = { background = "pressed", border = "focus", text = "textPrimary", wash = 0.08 },
        disabled = { background = "panel", border = "borderSubtle", text = "textDisabled" },
    },
    secondary = {
        default = { background = "raised", border = "borderStrong", text = "textSecondary" },
        hover = { background = "hover", border = "focus", text = "textPrimary" },
        pressed = { background = "pressed", border = "focus", text = "textPrimary" },
        disabled = { background = "panel", border = "borderSubtle", text = "textDisabled" },
    },
    quiet = {
        default = { background = "panel", border = "borderSubtle", text = "textSecondary" },
        hover = { background = "hover", border = "borderStrong", text = "textPrimary" },
        pressed = { background = "pressed", border = "focus", text = "textPrimary" },
        disabled = { background = "panel", border = "borderSubtle", text = "textDisabled" },
    },
    danger = {
        default = { background = "panel", border = "danger", text = "danger" },
        hover = { background = "raised", border = "danger", text = "textPrimary", washColor = "danger", wash = 0.10 },
        pressed = { background = "pressed", border = "danger", text = "textPrimary", washColor = "danger", wash = 0.16 },
        disabled = { background = "panel", border = "borderSubtle", text = "textDisabled" },
    },
    input = {
        default = { background = "canvas", border = "borderStrong", text = "textPrimary" },
        focus = { background = "panel", border = "focus", text = "textPrimary", accent = 1 },
        error = { background = "panel", border = "danger", text = "textPrimary" },
        disabled = { background = "panel", border = "borderSubtle", text = "textDisabled" },
    },
}

local function Copy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nested in pairs(value) do
        copy[key] = Copy(nested)
    end
    return copy
end

local function GetColor(name)
    local color = TOKENS.color[name]
    assert(color, "Unknown BGForge color token: " .. tostring(name))
    return color
end

local function SetRegionColor(region, method, colorName, alphaOverride)
    local color = GetColor(colorName)
    region[method](region, color[1], color[2], color[3], alphaOverride or color[4])
end

local function GetTextFont(style)
    return style.font or BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT
end

local function ApplyText(fontString, role, colorOverride)
    local style = TEXT_STYLES[role or "body"]
    assert(style, "Unknown BGForge text role: " .. tostring(role))
    fontString:SetFont(GetTextFont(style), style.size, "OUTLINE")
    SetRegionColor(fontString, "SetTextColor", colorOverride or style.color)
    if fontString.SetShadowColor then
        fontString:SetShadowColor(0, 0, 0, 0.86)
        fontString:SetShadowOffset(1, -1)
    end
end

local function ApplyBackdrop(frame, backgroundName, borderName)
    assert(frame.SetBackdrop, "BGForge styled frames require BackdropTemplate")
    frame:SetBackdrop(BACKDROP)
    SetRegionColor(frame, "SetBackdropColor", backgroundName)
    SetRegionColor(frame, "SetBackdropBorderColor", borderName)
end

local function EnsureFocusLayers(frame)
    if frame._bgforgeFocusWash then
        return
    end

    local wash = frame:CreateTexture(nil, "BORDER", nil, 2)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    wash:SetTexture(WHITE_TEXTURE)
    if wash.SetBlendMode then
        wash:SetBlendMode("ADD")
    end
    wash:SetAlpha(0)
    frame._bgforgeFocusWash = wash

    local accent = frame:CreateTexture(nil, "ARTWORK", nil, 7)
    accent:SetPoint("BOTTOMLEFT", 1, 1)
    accent:SetPoint("BOTTOMRIGHT", -1, 1)
    accent:SetHeight(TOKENS.size.focusLine)
    SetRegionColor(accent, "SetColorTexture", "focus")
    accent:SetAlpha(0)
    frame._bgforgeFocusAccent = accent
end

local function SetFocusWash(frame, colorName, alpha)
    local texture = frame._bgforgeFocusWash
    local color = GetColor(colorName or "focus")
    texture:SetColorTexture(color[1], color[2], color[3], 1)
    texture:SetAlpha(alpha or 0)
end

local function GetInteractionStyle(widget, state)
    local family = INTERACTIONS[widget._bgforgeVariant]
    assert(family, "Unknown BGForge interaction variant: " .. tostring(widget._bgforgeVariant))
    local style = family[state]
    assert(style, "Unsupported BGForge state: " .. tostring(state))
    return style
end

local function ApplyInteractionState(widget, state)
    local style = GetInteractionStyle(widget, state)
    ApplyBackdrop(widget, style.background, style.border)
    EnsureFocusLayers(widget)
    SetFocusWash(widget, style.washColor or "focus", style.wash or 0)
    widget._bgforgeFocusAccent:SetAlpha(style.accent or 0)

    local text = widget._bgforgeText
    if text then
        SetRegionColor(text, "SetTextColor", style.text)
    elseif widget.SetTextColor then
        SetRegionColor(widget, "SetTextColor", style.text)
    end
    widget._bgforgeRenderedState = state
end

local function IsPersistentState(state)
    return state == "selected" or state == "disabled" or state == "error"
end

local function HookPointerStates(widget)
    if widget._bgforgeStateHooks then
        return
    end
    widget._bgforgeStateHooks = true

    widget:HookScript("OnEnter", function(self)
        if not IsPersistentState(self._bgforgeState) then
            ApplyInteractionState(self, "hover")
        end
    end)
    widget:HookScript("OnLeave", function(self)
        ApplyInteractionState(self, self._bgforgeState)
    end)
    widget:HookScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not IsPersistentState(self._bgforgeState) then
            ApplyInteractionState(self, "pressed")
        end
    end)
    widget:HookScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and not IsPersistentState(self._bgforgeState) then
            ApplyInteractionState(self, self.IsMouseOver and self:IsMouseOver() and "hover" or self._bgforgeState)
        end
    end)
    widget:HookScript("OnDisable", function(self)
        self._bgforgeStateBeforeDisable = self._bgforgeState
        self._bgforgeState = "disabled"
        ApplyInteractionState(self, "disabled")
    end)
    widget:HookScript("OnEnable", function(self)
        if self._bgforgeState == "disabled" then
            self._bgforgeState = self._bgforgeStateBeforeDisable or "default"
            ApplyInteractionState(self, self._bgforgeState)
        end
    end)
end

local function HookInputStates(widget)
    if widget._bgforgeStateHooks then
        return
    end
    widget._bgforgeStateHooks = true
    widget:HookScript("OnEditFocusGained", function(self)
        if self._bgforgeState ~= "disabled" and self._bgforgeState ~= "error" then
            ApplyInteractionState(self, "focus")
        end
    end)
    widget:HookScript("OnEditFocusLost", function(self)
        ApplyInteractionState(self, self._bgforgeState)
    end)
    widget:HookScript("OnDisable", function(self)
        self._bgforgeStateBeforeDisable = self._bgforgeState
        self._bgforgeState = "disabled"
        ApplyInteractionState(self, "disabled")
    end)
    widget:HookScript("OnEnable", function(self)
        if self._bgforgeState == "disabled" then
            self._bgforgeState = self._bgforgeStateBeforeDisable or "default"
            ApplyInteractionState(self, self._bgforgeState)
        end
    end)
end

function UI.Token(group, name)
    local tokenGroup = TOKENS[group]
    assert(tokenGroup, "Unknown BGForge token group: " .. tostring(group))
    local value = tokenGroup[name]
    assert(value ~= nil, "Unknown BGForge token: " .. tostring(group) .. "." .. tostring(name))
    return Copy(value)
end

function UI.Style(widget, kind, options)
    assert(widget, "BGForge UI.Style requires a widget")
    options = options or {}
    widget._bgforgeKind = kind

    if kind == "surface" then
        local role = options.role or "panel"
        local style = SURFACES[role]
        assert(style, "Unknown BGForge surface role: " .. tostring(role))
        ApplyBackdrop(widget, style.background, style.border)
    elseif kind == "text" then
        ApplyText(widget, options.role or "body", options.color)
        if options.text ~= nil then
            widget:SetText(options.text)
        end
    elseif kind == "divider" then
        SetRegionColor(widget, "SetColorTexture", options.color or "borderSubtle")
    elseif kind == "tab" or kind == "button" then
        widget._bgforgeVariant = kind == "tab" and "tab" or (options.variant or "secondary")
        widget._bgforgeText = widget.GetFontString and widget:GetFontString() or widget._bgforgeText
        if not widget._bgforgeText then
            local text = widget:CreateFontString(nil, "OVERLAY")
            text:SetAllPoints()
            text:SetJustifyH("CENTER")
            text:SetJustifyV("MIDDLE")
            widget:SetFontString(text)
            widget._bgforgeText = text
        end
        ApplyText(widget._bgforgeText, options.textRole or "label")
        if options.text ~= nil then
            widget:SetText(options.text)
        end
        HookPointerStates(widget)
        UI.SetState(widget, options.state or "default")
    elseif kind == "input" then
        widget._bgforgeVariant = "input"
        ApplyText(widget, options.textRole or "body")
        if widget.SetAutoFocus then
            widget:SetAutoFocus(false)
        end
        HookInputStates(widget)
        UI.SetState(widget, options.state or "default")
    else
        error("Unknown BGForge widget kind: " .. tostring(kind))
    end

    if options.width and options.height then
        widget:SetSize(options.width, options.height)
    elseif options.width then
        widget:SetWidth(options.width)
    elseif options.height then
        widget:SetHeight(options.height)
    end
    return widget
end

function UI.Create(kind, parent, options)
    assert(parent, "BGForge UI.Create requires a parent")
    options = options or {}
    local widget
    if kind == "text" then
        widget = parent:CreateFontString(nil, options.layer or "ARTWORK", options.template)
    elseif kind == "divider" then
        widget = parent:CreateTexture(nil, options.layer or "BORDER")
        widget:SetTexture(WHITE_TEXTURE)
    elseif kind == "tab" or kind == "button" then
        widget = CreateFrame("Button", nil, parent, "BackdropTemplate")
    elseif kind == "input" then
        widget = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    elseif kind == "surface" then
        widget = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    else
        error("Unknown BGForge widget kind: " .. tostring(kind))
    end
    return UI.Style(widget, kind, options)
end

function UI.SetState(widget, state)
    assert(widget and widget._bgforgeVariant, "BGForge UI.SetState requires an interactive styled widget")
    GetInteractionStyle(widget, state)
    widget._bgforgeState = state
    ApplyInteractionState(widget, state)
    return widget
end

# BGForge Design System

Status: approved direction, foundation v1.1  
Target: Titan Reforged Classic only  
Visual direction: Arcane Archive (selected color concept 1)

## 1. Brand foundation

BGForge is a raid operations tool. It should feel precise, calm, trustworthy, and native beside World of Warcraft without imitating Blizzard ornament.

The interface has three jobs:

1. Make dense raid information scannable under time pressure.
2. Make the current selection and next action unmistakable.
3. Keep financial and character data credible by showing state, scope, and recency clearly.

### Brand attributes

- **Precise:** aligned columns, stable numbers, explicit state labels.
- **Calm:** dark low-noise surfaces; no ambient glow or decorative motion.
- **Operational:** controls look actionable and feedback is immediate.
- **Forged:** gold identifies BGForge and value, without turning every label yellow.
- **Arcane archive:** restrained steel blue identifies focus, selection, and interaction.

### Brand hierarchy

- **Rune Blue** means interaction: selected navigation, keyboard/edit focus, active cell, primary action.
- **Forge Gold** means identity or value: logo, product name, major currency totals.
- **Semantic colors** mean status only: success, warning, danger.
- Character class colors and item-quality colors remain content data. They must not color global navigation or structural headings.

## 2. Logo

Use the approved square mark from `docs/brand/bgforge-logo/`.

- Runtime source: `Media/icon/icon-128.tga`.
- Standard header size: 24 UI pixels.
- Compact size: 20 UI pixels; never smaller than 16.
- Clear space: at least one quarter of the displayed logo width.
- Do not recolor, stretch, crop, add a glow, or place the mark on a competing gold/Rune Blue field.
- In product chrome, pair the mark with `BGForge`; feature names are secondary.

## 3. Color tokens

All runtime color values live in `Core/UI/DesignSystem.lua`. Callers use semantic names, not local RGBA literals.

| Token | Hex | Purpose |
| --- | --- | --- |
| `canvas` | `#0B1118` | Window background |
| `panel` | `#101820` | Primary content surface |
| `raised` | `#18232D` | Inspector, toolbar, raised control |
| `header` | `#131D27` | Header and inactive tab |
| `hover` | `#1A2937` | Pointer hover |
| `rowHoverWash` | `#A7B3BD` at 5.5% | Neutral table-row hover wash |
| `pressed` | `#1D3142` | Pointer press |
| `focusSurface` | `#243045` | Selected tab, row, or active cell |
| `borderSubtle` | `#243644` | Grid and quiet boundary |
| `borderStrong` | `#3A5266` | Raised boundary |
| `focus` | `#5D8FB2` | Focus border and active line |
| `focusText` | `#6FB1D0` | Selected label and group heading |
| `forgeGold` | `#D3A23A` | Brand and high-value totals |
| `textPrimary` | `#DCE3E8` | Primary text |
| `textSecondary` | `#ABB6BF` | Secondary text |
| `textMuted` | `#73818C` | Metadata; avoid on lighter surfaces |
| `textDisabled` | `#56636D` | Disabled content |
| `success` | `#6BC56D` | Completed, paid, valid foreground |
| `successSurface` | `#173824` | Completed-cell background |
| `warning` | `#D7A549` | Waiting, partial, attention foreground |
| `warningSurface` | `#3A2E18` | Partial-state background |
| `danger` | `#DF6A70` | Error, failed auction, destructive foreground |
| `dangerSurface` | `#3A1F24` | Error-state background |

Primary and secondary text exceed 4.5:1 contrast on all standard surfaces. Status colors exceed 4.5:1 on `panel`. `textMuted` is reserved for non-essential metadata and must not carry required instructions.

### Color rules

- Do not use color alone. Pair status color with a text label, icon, check, dash, or row treatment.
- Use one Rune Blue selection treatment per hierarchy level.
- Table-row hover is a neutral luminance lift, not a blue selection fill. It must preserve semantic status cells.
- A selected row keeps its selected surface while hovered; hover does not stack another fill on top.
- Gold is scarce. If navigation, headings, buttons, borders, and numbers are all gold, nothing is gold.
- Item-quality colors may appear on item names/icons only.
- Class colors may appear on character identity only.

## 4. Typography

BGForge keeps the user's configured WoW font for Chinese and general UI text. Tabular values use the bundled `RobotoCondensed-Medium.ttf`.

| Role | Size | Use |
| --- | ---: | --- |
| `display` | 18 | Rare, top-level empty/error state |
| `title` | 16 | Window title, primary section title |
| `heading` | 14 | Section and table group heading |
| `body` | 14 | Main labels and values |
| `label` | 12 | Tabs, column headers, compact buttons |
| `caption` | 11 | Timestamp and non-essential metadata |
| `number` | 14 | Money, counts, item levels, timers |
| `numberStrong` | 16 | Net income and other major totals |

- Use `OUTLINE` consistently for in-game readability.
- Right-align numeric columns and keep units adjacent.
- Avoid center-aligned body data except binary status cells.
- Never shrink required text below 12 to make a layout fit; collapse or scroll the lower-priority region instead.

## 5. Spacing and geometry

Base rhythm: 4 UI pixels. Primary grouping rhythm: 8 UI pixels.

| Token | Value | Use |
| --- | ---: | --- |
| `xxs` | 2 | Icon/number micro-gap |
| `xs` | 4 | Internal compact padding |
| `sm` | 8 | Standard gap and padding |
| `md` | 12 | Control horizontal padding |
| `lg` | 16 | Section inset |
| `xl` | 24 | Major group separation |
| `xxl` | 32 | Screen edge or overlay clearance |

- Rectangular geometry only; BGForge does not fake unsupported rounded corners.
- Standard control height is 28; compact table controls may use 24; primary controls may use 32.
- Borders are 1 pixel. Active bottom lines are 2 pixels.
- Separate sections first with spacing and alignment, then dividers, then surface tint. Do not box every row.

## 6. Interaction states

Every interactive control supports stable states without changing its bounds:

| State | Treatment |
| --- | --- |
| Default | Quiet surface, readable secondary label |
| Hover | Lighter ink-blue surface, stronger border, primary label |
| Pressed | Darker steel-blue surface, focus border |
| Selected | `focusSurface`, Rune Blue border and label, 2px bottom line, subtle static inner wash |
| Disabled | Low-emphasis surface and text; no action |
| Error | Danger border plus explicit error text |

The selected-tab effect is static. It uses a backdrop, a low-alpha color layer, and a 2px line. It does not run an `OnUpdate` animation. `LibCustomGlow` is reserved for short-lived, high-priority attention states such as an auction event—not navigation selection.

### Feedback

- Hover/press feedback should appear immediately.
- Avoid ambient animation. Use motion only to explain open, close, expand, collapse, or completion.
- Operations longer than roughly 300 ms show a busy state or progress message.
- Destructive actions remain spatially separated and require confirmation when recovery is difficult.

## 7. Core component catalog

### Surface

Roles: canvas, panel, raised, header, row, alternate row, selected, overlay.

Use surfaces to establish hierarchy, not to create cards within cards. A table is one surface with rows and dividers.

### Tab

- Minimum height 28; compact minimum 24.
- Selected state uses Rune Blue and a bottom line.
- A tab label remains visible; icon-only primary navigation is not allowed.
- Selection is communicated by fill, border, text, and line—not color alone.

### Button

Variants: primary, secondary, quiet, danger.

- One primary action per working context.
- Primary uses Rune Blue; secondary actions use neutral surfaces.
- Danger is not filled red by default; it gains danger emphasis on hover/confirmation.
- Icon buttons require a tooltip and a practical hit area of at least 24×24.

### Input

- Visible label or column header is required; placeholder-only fields are not sufficient.
- Focus uses a Rune Blue border and bottom line.
- Error uses a danger border and adjacent recovery text.
- Read-only values look different from disabled controls.
- Numeric inputs use the number typography role and right alignment.

### Data table

- Keep column positions stable while values change.
- Use alternating rows only where dense scanning benefits from it.
- Selected row uses the full selected treatment, not only a blue text label.
- Group rows may collapse. They must show an arrow plus item count or summary.
- Empty rows collapse into a named empty state rather than dozens of blank boxes.
- Sticky summaries remain visually distinct from editable rows.

### Status

Use label + semantic color + optional icon:

- Success: `已交易`, `已完成`, `已同步`.
- Warning: `待记录`, `部分完成`, `即将重置`.
- Danger: `流拍`, `错误`, `逾期`.
- Neutral: `未拍`, `无记录`, `不适用`.

### Tooltip and overlay

- Tooltip anchors away from the active cell and never covers the next likely action.
- Overlay opacity must isolate foreground content from the game world.
- Every overlay has an obvious close route and supports Escape where the WoW frame permits it.

## 8. Information hierarchy

Use the same vertical order across major surfaces:

1. Product identity and global window actions.
2. Current scope: instance, boss/group, filter, reset/recency.
3. Primary data workspace.
4. Context inspector or contextual controls.
5. Totals, status, and secondary actions.

Do not mix global navigation, table filters, and record actions in one undifferentiated row.

## 9. Accessibility and WoW constraints

- Required information has a 4.5:1 contrast target.
- Do not rely on hover for the only access to a critical action. The character overview may open on hover, but its pin/open behavior remains available.
- Preserve keyboard actions already supported by WoW EditBox and frame templates.
- Item and character meaning cannot rely only on quality/class color.
- Keep the active control visible with a border/line even for users who cannot distinguish Rune Blue from surrounding hues.
- Avoid repeated animated glows, large alpha animations, and per-row `OnUpdate` handlers.
- Use native item icons and existing raster assets. Do not introduce SVG, blur, CSS effects, or runtime-generated decorative art.

## 10. Lua interface

The design system is a deep module at `BG.UI`:

```lua
local panel = BG.UI.Create("surface", parent, { role = "panel" })
local title = BG.UI.Create("text", panel, { role = "title", text = "BGForge" })
local tab = BG.UI.Create("tab", panel, { text = "纳克萨玛斯", state = "selected" })
local save = BG.UI.Create("button", panel, { variant = "primary", text = "保存本行" })

BG.UI.SetState(tab, "default")
BG.UI.Style(existingFrame, "surface", { role = "raised" })
local gap = BG.UI.Token("spacing", "sm")
```

Callers should not read internal palette tables or duplicate state logic. `BG.UI.Token` returns a copy so callers cannot mutate the source of truth.

## 11. Migration rules

1. Migrate shared chrome and tabs first.
2. Migrate table/input primitives second.
3. Move character overview colors into semantic tokens without changing its data collection or content.
4. Recompose the auction workspace only after the primitives are stable.
5. Remove legacy styling helpers only after every caller has moved and regression coverage proves parity.

The design-system layer stores no player data, sends no messages, and introduces no game-flavor state.

## 12. Anti-patterns

- Rainbow navigation or headings.
- Gold used as the default text color.
- Animated glow for persistent selection.
- Blank input grids shown before they are relevant.
- Cards nested inside cards.
- Controls that move or resize between hover and pressed states.
- Icon-only navigation without a tooltip or label.
- Hard-coded RGBA values inside feature modules.
- Reintroducing BiaoGe player collection or synchronization while migrating UI.

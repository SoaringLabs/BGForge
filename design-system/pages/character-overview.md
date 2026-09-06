# Character Overview — Small Interface

This file overrides `design-system/MASTER.md` only for the character-overview **small interface**: the floating panel shown by hovering the BGForge minimap icon.

The character-overview **large interface** is the full page shown by selecting the “角色总览” tab inside the BGForge main frame. It reuses the same renderer, but its main-frame placement and navigation rules are defined in `pages/auction-workspace.md`.

## Outcome

Let the user answer three questions quickly:

1. Which characters still have important raid/weekly work?
2. Which character has the resource or item needed next?
3. How fresh is this local snapshot?

The content, local-account scope, and privacy boundary stay unchanged.

## Implemented pilot

The small interface now acts as the first production reference for Arcane Archive:

- Forge Gold is limited to the BGForge wordmark, resource values, and totals.
- Rune Blue marks section accents, button hover/press borders, the scrollbar thumb,
  and the current-character selection.
- The current character uses the quiet `focusSurfaceSubtle` surface and a 2px leading marker.
- Standard character rows share one base surface; only status, hover, and current-character
  states introduce a fill change. A completed status stays on the row surface rather than adding
  a full green cell fill.
- Hover uses the low-alpha neutral `rowHoverWash`, never the Rune Blue focus color.
- The current-character row does not receive the hover wash, keeping active and hover states distinct.
- Header icon buttons use a raised default surface and strong border so they read as controls
  before hover. Hover and press change only the border; the background and icon remain stable.
- Row hover is a static texture overlay; it does not allocate per-row `OnUpdate` animation work.
- Existing table structure, data fields, tooltips, refresh, settings, and close behavior remain intact.

## Layout

- Keep the compact matrix: characters are rows; raid/weekly states are columns.
- Do not alternate standard row fills in the small interface. The dense grid already provides enough
  tracking support, and a single base surface protects the meaning of selected and status fills.
- Keep resources as a second section rather than mixing them into lockout cells.
- Use a shared 36px product header with logo, title, reset time, refresh, settings, and close/pin controls.
- Draw reset time inside the product header so its translucent surface cannot cover the text;
  reuse the standard table-header font and `textSecondary` color.
- Show only the Titan Ember total in the small interface; keep weekly acquisition progress in the large interface.
- Freeze the character column visually when horizontal scrolling is required.
- Current character uses a selected-row treatment plus an explicit current marker; gold tint alone is insufficient.
- Empty or unavailable values use a neutral dash. Question marks require a tooltip explaining why the value is unknown.

## State mapping

- Completed: compact muted-success check on the neutral row surface; no green cell fill.
- Partial/in progress: warning color + numeric progress or label.
- Available: neutral empty cell, not green.
- Current character: focus border/line + row tint.
- Hidden character: controlled from settings; do not silently remove it from storage.

## Interaction

- Hover may show the small interface immediately, preserving the current entry point.
- Moving between minimap icon and panel must not accidentally close it.
- Clicking a character name opens that character's detail page in the large interface. The small
  interface keeps its existing whole-row hover treatment and does not show a navigation chevron.
- Pin/open remains available for deliberate inspection and keyboard/mouse stability.
- Refresh shows immediate pressed feedback and updates the recency caption when complete.

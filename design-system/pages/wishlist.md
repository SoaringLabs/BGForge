# Wishlist

This file applies `design-system/MASTER.md` to the full-page wishlist workspace.

## Outcome

Let the player build and review a per-instance wishlist without losing the relationship between class-set tokens, boss sources, and the current selection.

The browse model, saved data, item filtering, loot reminders, and add/remove/clear behavior stay unchanged.

## Layout

- Preserve the existing three-part workbench: class-set categories, boss directory/detail, and current wishlist summary.
- Keep the instance selector as contextual navigation above the page.
- Keep the page title, short instruction, gear filter, and destructive clear action in one compact header.
- Let the embedded page header span the main content width. The raid-navigation rule is its top separator; use a vertical Rune Blue marker rather than drawing a second horizontal rule.
- Keep independent scrolling for the boss directory, boss item grid, and wishlist summary.
- Recalculate the workbench after the host frame finishes resizing, and reset stale scroll offsets when the selected raid changes.

## Visual mapping

- Standard panels use `panel`; compact headers and summary rows use `header` or `raised`.
- Section titles use `focusText`, not Forge Gold.
- Selected set categories, bosses, and browse items use `focusSurface` plus a Rune Blue border or 2px marker.
- Row hover uses `rowHoverWash`; it is suppressed on an already-selected row.
- Item names, item-level borders, and class abbreviations retain their quality/class colors as content data.
- Boss names do not create rainbow structural headings; the selected boss header uses primary text and a Rune Blue marker.
- Non-zero wishlist counts use `focusText`; empty counts and supporting copy use `textMuted`.
- “Clear current instance” uses the danger button variant and still requires confirmation.
- Forge Gold is not used on this page's structural headings, navigation, selection, or borders.

## Lua constraints

- Structural colors come from `BG.UI.Token`; the module must not maintain a private theme palette.
- Shared primitives use `BG.UI.Style` where the widget shape permits it.
- Selection and hover are static textures. Do not add per-row `OnUpdate` work or animated glow.
- No data collection, synchronization, game-flavor state, or wishlist persistence changes are part of this migration.

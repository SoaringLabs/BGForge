# Wishlist

This file applies `design-system/MASTER.md` to the full-page wishlist workspace.

## Outcome

Let the player build and review a per-instance wishlist without losing the relationship between class-set tokens, boss sources, and the current selection.

The browse model, saved data, item filtering, loot reminders, and add/remove/clear behavior stay unchanged.

## Layout

- Preserve the existing three-part workbench: class-set categories, boss directory/detail, and current wishlist summary.
- Keep all three workbench panels at a stable shared height. Do not resize a panel when its contents change.
- Keep the summary rail at a stable 240px width in empty and populated states; the boss-detail grid remains two columns.
- Keep the instance selector as contextual navigation above the page.
- Keep the page title, readable instruction, and gear filter in the shared page header. Keep the destructive clear action in the summary heading row so its scope is explicit.
- Keep a 220px design-system search input on the right side of the Boss Drops heading. Search the current raid's direct boss drops by item name (or item ID), render matches in the existing two-column detail area, and show each match's boss source in its metadata line. Choosing a boss clears the search and restores that boss's detail view.
- Let the embedded page header span the main content width. Keep its title and instruction close to the short Rune Blue marker; the raid-navigation rule is its top separator, and the marker must not become a second full-height border.
- Keep independent scrolling for the boss directory, boss item grid, and wishlist summary.
- Recalculate the workbench after the host frame finishes resizing, and reset stale scroll offsets when the selected raid changes.

## Visual mapping

- Standard panels use `panel`; compact headers and summary rows use `header` or `raised`.
- Section titles use `focusText`, not Forge Gold.
- Pooled section-title FontStrings must reset width, horizontal alignment, and wrapping on every render; asynchronous metadata must never shift a later heading.
- Selected set categories, bosses, and browse items use the quiet `focusSurfaceSubtle` surface plus one 2px Rune Blue leading marker. Selection never uses the success color.
- Row hover uses `rowHoverWash`; it is suppressed on an already-selected row.
- Item names, item-level borders, and class abbreviations retain their quality/class colors as content data.
- Item-quality frames render above the selected row surface and below the item icon, so the quality edge remains visible in every selection state.
- Boss names do not create rainbow structural headings; the selected boss header uses primary text and a Rune Blue marker.
- Non-zero wishlist counts use `focusText`; zero boss counts are hidden.
- Filtered items remain readable at reduced emphasis. Their icon stays fully opaque and is darkened with a neutral desaturated tint, preventing the quality border underneath from bleeding into and recoloring the item art.
- “Clear current instance” uses the compact danger button variant in the summary heading row and still requires confirmation. Its resting state stays quiet (`panel` + `borderSubtle` + `textSecondary`); danger color appears on hover and press instead of competing permanently with the summary title.
- Forge Gold is not used on this page's structural headings, navigation, selection, or borders.

## Lua constraints

- Structural colors come from `BG.UI.Token`; the module must not maintain a private theme palette.
- Shared primitives use `BG.UI.Style` where the widget shape permits it.
- Selection and hover are static textures. Do not add per-row `OnUpdate` work or animated glow.
- No data collection, synchronization, game-flavor state, or wishlist persistence changes are part of this migration.

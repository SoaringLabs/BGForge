**Source visual truth**

- Selected three-column workbench concept: `/Users/liushuxiang/.codex/generated_images/01a0490f-2b78-7c41-91ca-d69e45cd840c/exec-9cf4df1e-41ec-47dc-aa2d-ffdd925e1e2f.png`
- User correction for the class-category control: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-afcadc80-7492-4d2e-9fc6-618b79d30262.png`
- Desired persistent selected-row treatment: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-014b9521-347f-420e-8af2-6fd0352c5644.png`
- Desired wishlist remove-row treatment: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-1c1e8b23-23e4-4c3a-8cb2-b47775553509.png`
- Selected/hover color reference from Character Overview: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-413754e2-4e77-47a0-865c-5c60f5e7b4df.png`
- Thin item-quality-border reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-ab85028d-92eb-4faf-923b-57d02b57ac42.png`
- Selected boss master-detail concept: `/Users/liushuxiang/.codex/generated_images/01a0490f-2b78-7c41-91ca-d69e45cd840c/exec-074d1c60-1a9f-4722-a008-5acbad846eba.png`
- Boss item metadata reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-64d3a514-d2e7-42e4-9280-42620fa5318a.png`.

**Implementation evidence**

- Pre-fix in-client implementation screenshot: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-849ef30b-f13c-42a3-b791-65661bdfe039.png`.
- Master-detail implementation before scrollbar correction: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-cf3a35ef-2efb-4b60-bf97-9b1d756cf1d5.png`.
- Master-detail implementation after scrollbar correction and before item-metadata expansion: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-dee4b01e-c9ec-4b3e-b248-838a3cc718f3.png`.
- Post-fix implementation screenshot: unavailable until the addon is reloaded in the Titan client.
- Source pixels: 1536 × 980 for the selected full-screen concept; 614 × 702 for the selected-row detail; 352 × 667 for the wishlist-row detail.
- Pre-fix implementation pixels: 3688 × 2466. UI scale and density normalization are unknown.
- Intended state: P5 wishlist page with one class-token category selected, a scrollable boss directory beside the active boss's drop grid, and the current wishlist pinned on the right.
- Structural evidence: `tests/wishlist_ui_render_regression.lua` passed through the Fengari Lua runtime.
- Interaction evidence: class-category switching moves the single checkmark and swaps the token list; boss-directory switching moves the active-row highlight and replaces the detail grid; boss wish counts update from the selected direct drops; selected browse items keep a persistent row highlight; wishlist rows expose a close texture and remove the item when clicked.
- Console errors: not available without the game client.

**Full-view comparison evidence**

Blocked. The addon cannot be rendered or captured faithfully by the local Lua frame harness.

**Focused-region comparison evidence**

Blocked for the same reason. The harness verifies frame structure, dimensions, anchors, textures, and interaction state, but not Blizzard's final font and texture rendering.

**Findings**

- [P1] A post-change in-client screenshot is still required.
  Location: full wishlist screen.
  Evidence: the pre-fix client capture is available, but there is no Titan client capture after the boss master-detail conversion.
  Impact: the boss-directory density, inner scrollbar alignment, selected-row opacity, detail-grid width, and interaction affordance cannot be judged visually.
  Fix: reload BGForge in Titan, open a populated P5 wishlist, and capture the full frame at the same UI scale as the reference.

**Comparison history**

- Iteration 1: replaced the previous single vertical flow with a left class-token column, a central two-column boss board, and a right persistent wishlist column.
- Iteration 1: removed boss accordion behavior so each boss card exposes its equipment grid immediately.
- Iteration 1: changed class-category state from expand/collapse symbols to a single Blizzard checkbox texture on the selected category; selecting the active category no longer collapses it.
- Iteration 1: aligned the three outer column surfaces to one content height and moved the clear action to the bottom of the wishlist column.
- Iteration 2: removed the icon-corner selection glyph that rendered as a green missing-resource box.
- Iteration 2: added a persistent cyan row background and cyan item name for selected boss/set items, matching the existing hover language.
- Iteration 2: gave each wishlist item a subtle row surface, 1px divider, and Blizzard close-button texture on the right; the whole row remains clickable to remove.
- Iteration 3: replaced the cyan selected state with Character Overview's dark-brown current-row color (`0.24, 0.18, 0.05, 0.70`).
- Iteration 3: replaced the cyan hover state with Character Overview's light gold-brown overlay (`0.95, 0.62, 0.20, 0.16`) and kept item names in their quality colors in every state.
- Iteration 4: increased the selected brown to (`0.36, 0.25, 0.06, 0.82`) and darkened hover to (`0.28, 0.18, 0.05, 0.26`), making selection visually dominant over transient hover.
- Iteration 5: reduced the item quality frame from 34×34 to 32×32 while retaining a 30×30 icon, producing a one-pixel quality border on every side.
- Iteration 6: abbreviated every class name in the class-set selector to its first UTF-8 character, preserving class colors and separators while preventing title truncation.
- Iteration 7: removed the spaces around class-category separators, producing compact labels such as `圣·潜·萨`.
- Iteration 8: prefixed real boss headers with their loot-table slot number (for example `1号 · 埃基尔松`), while leaving non-boss entries such as `限时宝箱` and `杂项` unnumbered.
- Iteration 9: replaced the all-boss two-column card board with a master-detail selector: an independently scrollable compact boss directory on the left and only the active boss's two-column drop grid on the right.
- Iteration 9: added a right-aligned per-boss count for direct-drop items already on the wishlist, using cyan for non-zero counts and muted gray for zero; the active boss row uses the established bright-brown selected state.
- Iteration 10: made the boss-directory scrollbar conditional on actual overflow, anchored it inside the directory boundary, and reserved row width for it only while visible.
- Iteration 11: added a compact second line to boss-detail items using localized live item data (`部位，护甲/武器类型`) while preserving the existing icon size and two-column density; class-set and wishlist-summary rows remain single-line.
- Post-fix structural evidence: Lua 5.1 syntax parsing, wishlist UI render regression, wishlist data regression, and integration/privacy regression all passed.
- Post-fix visual evidence: blocked pending an in-client screenshot.

**Implementation checklist**

- [x] Three-column workbench layout.
- [x] Vertically stacked class-category selector in the left column.
- [x] Exactly one selected class category, represented by a real checkmark texture.
- [x] Selected token items shown below the category selector.
- [x] Independently scrollable boss directory with compact numbered rows.
- [x] Active-boss detail area with a compact two-column item grid.
- [x] Boss-directory trailing counts show selected direct-drop wishes per boss.
- [x] Boss detail headers show only portrait and name, with no accordion symbol.
- [x] Boss-detail item rows show localized slot and armor/weapon subtype metadata.
- [x] Persistent one-column wishlist on the right.
- [x] Clear action anchored at the bottom of the wishlist column.
- [x] Existing data, wishlist persistence, drop reminder, auction preview, and privacy constraints preserved.
- [x] Selected browse items use persistent row highlighting instead of an icon-corner marker.
- [x] Browse-item selected and hover colors reuse the Character Overview state palette.
- [x] Item quality borders are limited to one pixel around the icon.
- [x] Class-set selector labels use one-character localized class abbreviations.
- [x] Boss-drop card headers show boss numbers without numbering non-boss entries.
- [x] Wishlist summary items have distinct rows, separators, and an explicit remove icon.
- [ ] Capture and compare the revised in-client view.

final result: blocked

# Character Overview profession cooldown QA — 2026-09-01

**Source visual truth**

- Current Character Overview reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-0ea67c2a-452f-4f5c-b09c-bdefe93d20f2.png`.
- Source pixels: 3102 × 1434.
- Required state: keep the existing dark-blue/gold grouped table; retain `专业日常` with `珠宝 / 烹饪 / 钓鱼`; add one adjacent `专业制造 / 制造 CD` summary column.

**Implementation evidence**

- Production implementation: `Core/Module/RaidLockoutOverview.lua`.
- Localization: `Locales/zhCN.lua`, `Locales/zhTW.lua`, and `Locales/enUS.lua`.
- Structural regression: `tests/raid_lockout_overview_regression.lua` passes under the Fengari Lua runtime.
- Compatibility guard: the Character Overview frame remains within Titan's 60-upvalue function limit.
- State coverage: all ready, mixed ready/cooling, all cooling, relevant-but-unscanned, no learned cooldown recipe, shared alchemy cooldown collapse, and per-profession scan isolation.
- Client test copy: the changed module and locale files are synchronized into the installed Titan addon.
- Post-change implementation screenshot: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-5b54b7af-5f75-4073-a82c-d87bbdc2e575.png` (1312 × 1002).
- In-client visual evidence: user-confirmed the temporary mixed/all-cooling/all-ready/cross-profession mock states, grouped tooltip, status colors, and table fit rendered correctly; the mock has since been removed.

**Fidelity surfaces**

- Typography: reuses the existing `BIAOGE_TEXT_FONT`, 12px grouped headers, and the current status-cell text sizing.
- Layout: reuses the current grouped header, grid cell, row height, horizontal overflow, and responsive width calculations; the new compact column starts at 70px.
- Colors: reuses `COLOR.header`, `COLOR.headerStrong`, `COLOR.complete`, `COLOR.partial`, `COLOR.current`, and the existing gold text palette.
- Images: no new artwork; all-ready uses the existing ReadyCheck check texture.
- Interaction: the summary cell reuses row-hover behavior and a native `GameTooltip`, with details grouped by profession. The unknown state names each unscanned profession, gives the exact one-time action, and explains that subsequent scans are automatic.
- Copy: all new labels and tooltip strings are localized for Simplified Chinese, Traditional Chinese, and English.

**Findings**

- No blocking findings remain for the profession cooldown column. The in-client mock capture confirms the grouped table, compact states, tooltip hierarchy, font rendering, and horizontal fit.

**Current implementation checklist**

- [x] Three profession dailies remain one grouped header.
- [x] Manufacturing cooldowns use one grouped summary column.
- [x] All-ready, partial, cooling, unknown, and blank states are distinct.
- [x] Tooltip details are grouped by profession.
- [x] Unknown-state Tooltip explains which professions need scanning and how to complete the one-time scan.
- [x] Opening one profession does not erase another profession's stored cooldowns.
- [x] Titan recipes without a current long cooldown are excluded.
- [x] Existing styling primitives are reused; no parallel visual system was introduced.
- [x] Static and cross-module regression suites pass.
- [x] Temporary display-only mock covered mixed, all-cooling, all-ready, and cross-profession tooltip states.
- [x] Temporary profession cooldown mock removed after visual approval.
- [x] Capture and compare the reloaded in-client view.

## Historical wishlist QA

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

historical result: blocked

final result: passed

## Character Details · Professions & Resources — 2026-09-04

**Source visual truth**

- Selected state-and-hierarchy reference: `/Users/liushuxiang/.codex/generated_images/01a06bd9-f1fe-7491-af67-5f708e8a8c7e/exec-62e74b32-79ff-402f-978c-4493df6c3835.png`.
- Source pixels: 2001 × 786.
- Intended state: daily Jewelcrafting/Cooking/Fishing summary, two dynamic primary-profession tracks with 0–2 Titan crafting cooldowns each, and the approved full-width horizontal resource overview.
- Asset correction from the user: mock artwork is not implementation truth. Every visible icon must resolve from a usable in-game file ID, spell texture, currency snapshot, item snapshot, or Blizzard UI texture.

**Implementation evidence**

- Production UI: `Core/Module/CharacterDetails.lua`.
- Profession/cooldown display model and optional cooldown duration: `Core/Module/RaidLockoutOverview.lua`.
- Localization: `Locales/zhCN.lua`, `Locales/zhTW.lua`, and `Locales/enUS.lua`.
- Automated evidence: Character Details integration, Raid Lockout Overview regression, Design System regression, and Lua 5.1 syntax loading all pass.
- Pre-fix implementation screenshot: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-718d057c-e638-49ca-b42e-a2e646798c1d.png`.
- Implementation pixels: 3502 × 2322. The target addon frame is the Titan main-frame `大界面`; CSS viewport and browser density are not applicable.
- Width-normalized full comparison: `/Users/liushuxiang/.codex/visualizations/2026/09/04/01a06bd9-f1fe-7491-af67-5f708e8a8c7e/profession-reference-vs-actual.png` (2001 × 2129; reference first, implementation second).
- Width-normalized focused comparison: `/Users/liushuxiang/.codex/visualizations/2026/09/04/01a06bd9-f1fe-7491-af67-5f708e8a8c7e/profession-content-reference-vs-actual.png` (1668 × 1898; reference first, implementation second).
- Compared state: reference uses Inscription/Tailoring; implementation uses Jewelcrafting/Blacksmithing. Profession-specific content and real client icons therefore differ intentionally, while composition, density, hierarchy, and resource-strip treatment remain directly comparable.

**Full-view comparison evidence**

The pre-fix implementation diverges materially from the reference. The resource overview is pinned to the bottom of a much taller inherited raid frame, leaving a large empty vertical region between the second profession and the resources. The implementation also uses a brighter raised surface for the profession rows, making them read as large empty containers rather than compact tracks.

**Focused-region comparison evidence**

The focused comparison confirms that the reference uses a narrow profession identity column, a cyan left-edge accent, asymmetric cooldown space, and one enclosed resource strip with internal dividers. The pre-fix implementation has a wider identity column, equal fixed-width cooldown cards, no track accent, and loose resource tiles without a shared inner surface.

**Findings**

- [P1] Large vertical void breaks the intended compact overview.
  Location: Character Overview `大界面` → `专业与资源`.
  Evidence: the pre-fix resource section is pinned near the frame bottom, hundreds of pixels below the second profession; the reference places it immediately after the tracks.
  Impact: the screen feels unfinished and forces the eye to cross empty space to reach related information.
  Fix applied: the profession/resource content now owns a compact fixed-height surface and the resource section follows the second profession at a fixed rhythm.
- [P2] Profession rows use the wrong surface hierarchy.
  Location: both profession tracks.
  Evidence: the pre-fix rows use the brighter `raised` token and lack the reference's cyan left accent.
  Impact: the tracks dominate the page while their actual status content feels sparse.
  Fix applied: changed the outer content and tracks to the darker `panel` surface, cooldown cards to `canvas`, and added the design-system `focus` accent.
- [P2] Resource overview lacks a coherent horizontal strip.
  Location: bottom resource section.
  Evidence: the pre-fix resources float independently on the panel with large irregular gaps and no internal separators.
  Impact: values do not scan as one resource summary.
  Fix applied: added one inset `canvas` strip, consistent item widths, vertical dividers, quality-aware borders, and Forge Gold emphasis for values and the upgrade-material group.
- [P2] Daily and status hierarchy is too abbreviated.
  Location: daily cards and unknown cooldown states.
  Evidence: the pre-fix cards omit “日常” and the reset/status lines are collapsed; unknown states use the same question-mark treatment as unfinished dailies.
  Impact: daily cadence and data confidence are harder to distinguish.
  Fix applied: restored the full daily names, added a reset/eligibility meta line, and separated Blizzard ready, waiting, and information textures.
- [P2] A revised in-client capture is still required.
  Location: full revised screen.
  Evidence: code and structural checks pass, but the new layout cannot be rendered by the local Lua harness.
  Impact: post-fix font wrapping, atlas availability, and final UI-scale fit remain unverified.
  Fix: reload BGForge and capture the same screen again.

**Required fidelity surfaces**

- Typography: the existing BGForge font roles and sizes are retained; the pre-fix capture shows readable weights, but revised wrapping needs a new capture.
- Spacing/layout: the major vertical-gap and resource-grouping defects were corrected in code; post-fix visual confirmation is pending.
- Colors/tokens: tracks now use `panel`/`canvas`, Rune Blue `focus`, semantic success/warning, and Forge Gold instead of the over-bright raised blocks.
- Image quality/assets: profession and daily icons remain client file IDs; recipes remain spell textures; resources remain currency/item textures. Gold now prefers Blizzard's `auctionhouse-icon-coin-gold` atlas with the game texture as fallback. No mock artwork is referenced.
- Copy/content: daily names, reset/eligibility context, scan guidance, cooldown states, and the “传说级升级材料” label now match the chosen hierarchy more closely.

**Implementation checklist**

- [x] Third tab is enabled and navigable.
- [x] Daily status cards use real in-game profession textures and Blizzard status textures.
- [x] Profession tracks derive their icon and rank from the saved client profession snapshot.
- [x] Recipe cards derive their icon from the tracked spell ID at runtime.
- [x] Alchemy, Inscription, Jewelcrafting, and Tailoring may each expose their Titan cooldown definitions; other professions render an explicit no-long-CD state.
- [x] Ready, cooling, unscanned, and no-long-CD states are distinct.
- [x] Cooling progress is shown only when the client supplied a valid long-cooldown duration.
- [x] Horizontal resource overview uses gold, currency, fragment-item, and upgrade-item game textures.
- [x] No generated mock artwork is referenced by addon code.
- [x] Snapshot-only privacy boundary is preserved.
- [x] Resource strip follows the profession tracks instead of the inherited frame bottom.
- [x] Profession surfaces, left accents, and identity-column proportions are corrected.
- [x] Resource strip has one containing surface, dividers, and semantic borders.
- [ ] Capture and compare the revised in-client view.

**Comparison history**

- Implementation pass 1: enabled the third tab, added daily cards, two dynamic profession tracks, explicit cooldown states, and the horizontal resource strip.
- Implementation pass 2: replaced every mock-icon assumption with an explicit game-resource source and added regression guards against generated-image paths.
- Implementation pass 3: preserved real cooldown duration so the amber progress rail does not invent timing precision.
- Visual QA iteration 1: the first in-client capture exposed the bottom-pinned resource strip, large empty middle region, bright profession surfaces, missing accents, and loose resource grouping.
- Visual QA iteration 1 fixes: converted the screen to a compact content-owned surface, moved resources directly below the tracks, darkened the hierarchy, narrowed the identity column, let the second cooldown region absorb remaining width, and rebuilt resources as one divided strip.
- Post-fix visual evidence: blocked pending the next in-client capture.

final result: blocked

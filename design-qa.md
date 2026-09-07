# Character Details · Progress page removal QA — 2026-09-08

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Implementation evidence**

- The `进度` tab, route, panel construction, accordion, boss panel, scroll state, and page-only helpers are removed.
- The shared raid/weekly progress model and the Today-specific boss-segment renderer remain intact.
- Today raid and weekly rows are non-interactive summaries; their obsolete `查看` actions and hover states are removed.
- Large-interface character details now exposes exactly `今日`, `装备`, and `背包`.

**Verification**

- [x] Runtime navigation asserts exactly three visible destinations and exercises Equipment and Backpack.
- [x] Static integration rejects retained Progress routes, panels, renderers, or page-only state.
- [x] Today raid/weekly model, sorting, exact boss-state segments, and summary assertions remain active.
- [ ] In-client focused navigation comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · Professions/Resources page removal QA — 2026-09-08

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- Removal target: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-608df489-34cf-4b31-848b-914f2bb79e63.png`.
- Source pixels: 1612 × 336.
- Intended state: large-interface character details navigation containing only `今日`,
  `装备`, and `背包` after the subsequent Progress-page removal.

**Implementation evidence**

- The `专业与资源` tab, route, panel construction, renderer, and page-only component helpers are removed.
- Today remains the sole UI owner of professional dailies, profession status/cooldowns,
  currencies, fragments, and upgrade-material summaries.
- Page-level data collection and storage are unchanged; removing the presentation does not
  remove snapshots still required by Today.
- Profession daily and profession status rows no longer expose a dead `查看` action or hover state.
- Equipment and Backpack quick links remain functional.

**Verification**

- [x] Runtime navigation asserts exactly three visible destinations and exercises Equipment and Backpack.
- [x] Static integration rejects any retained profession/resources route, panel, renderer, or page component.
- [x] Today profession/resource content and snapshot assertions remain active.
- [ ] In-client focused navigation comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · Backpack visual-system alignment QA — 2026-09-08

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Comparison target**

- Pre-alignment Backpack capture: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-76bd5a0d-3f7a-4618-9ba4-082c88164e3b.png`.
- Today palette and hierarchy reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-7e05b238-ca3e-4e62-8324-b5663d6e8923.png`.
- Equipment panel and detail-rail reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-3666f7e1-8059-4f15-bcaf-147520b5f41b.png`.
- Source pixels: 2920 × 2456, 2882 × 2318, and 2912 × 2378 respectively.
- Implementation screenshot: unavailable because this iteration does not operate the game client.
- Intended state: large-interface character details, Backpack tab, `全部` selected.

**Findings**

- [P2] Final font and spacing comparison remains pending
  Location: category filters, grouped item grid, and capacity summary rail.
  Evidence: runtime assertions verify the shared panel palette, unchanged 78 × 28px filter
  hit areas, 35px item icons, 26px group headings, single-divider treatment, and preserved
  search/filter interactions. Without a post-change Titan client capture, WoW UI scaling
  and final glyph metrics cannot be compared against the references.
  Impact: implementation structure is deterministic, but optical alignment cannot be signed off.
  Fix: reload BGForge and capture the full Backpack tab at the same UI scale.

**Required fidelity surfaces**

- Colors: Backpack now uses the same `panel`, `borderSubtle`, focus, and text roles as Today and Equipment.
- Borders: the outer panel, header divider, group dividers, one grid/summary divider, input border, and native item-quality borders are the only visible outlines.
- Dimensions: search, filters, grid, summary width, item size, item gap, and heading height are unchanged.
- Interaction: search, category selection, item hover/tooltips, and modified clicks remain active.
- Data/privacy: no collection, storage, synchronization, or player-data field changed.

**Verification**

- [x] Runtime assertions cover palette inheritance, lightweight filters, borderless group headings, the summary divider, unchanged item size, and search behavior.
- [x] Static integration checks reject restoration of bordered block filters.
- [ ] In-client full-view and focused-region comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · Equipment palette and detail rail QA — 2026-09-08

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Comparison target**

- Today palette reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-7e05b238-ca3e-4e62-8324-b5663d6e8923.png`.
- Pre-fix Equipment capture: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-3666f7e1-8059-4f15-bcaf-147520b5f41b.png`.
- Detail-list treatment reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-21d836af-f468-469b-a780-68c44852ebd2.png`.
- Source pixels: 2882 × 2318, 2912 × 2378, and 1824 × 1330 respectively.
- Implementation screenshot: unavailable because this iteration does not operate the game client.
- Implementation pixels, CSS size, and density normalization: unavailable for the same reason.
- Intended state: large-interface character details, Equipment tab, first occupied slot selected.

**Findings**

- [P2] Final proportion and font-metric comparison is pending
  Location: paper-doll stage and right equipment-detail rail.
  Evidence: the source references are open and readable, while there is no post-change Titan client capture to combine with them. Runtime assertions verify a 520px detail rail, 44px paper-doll icons inside unchanged 48px slot geometry, 32px detail rows, 17 functional detail positions, enhancement ordering, and borderless hover/selection states; they cannot verify WoW's final UI-scale rendering.
  Impact: the exact stage/list balance, long-name truncation, and live optical alignment cannot be signed off from code alone.
  Fix: reload BGForge, capture the Equipment tab at the same UI scale, then compare the complete panel and a focused detail-row crop with both references.

**Required fidelity surfaces**

- Fonts and typography: existing Arcane Archive roles are preserved; live glyph metrics and long-name truncation remain unverified.
- Spacing and layout rhythm: fixed measurements and column anchors pass runtime assertions; in-client proportions remain unverified.
- Colors and visual tokens: the equipment surface now uses the same `panel` background and `borderSubtle` roles as the Today lanes; only existing `hover`, `focusSurfaceSubtle`, `focus`, text, and item-quality colors supplement it.
- Image quality and asset fidelity: all item, empty-slot, spec, enchant, and gem imagery comes from Blizzard/client data; no generated artwork is referenced by addon code.
- Copy and content: detail rows show slot, item level, resolved item name, enchant, and gem data; shirt and tabard remain in the paper doll but are intentionally omitted from the functional detail list.

**Full-view comparison evidence**

- Blocked because no rendered post-change implementation capture is available.

**Focused region comparison evidence**

- Blocked for the same reason; a crop containing the detail header and several occupied/empty rows is required.

**Comparison history**

- Initial paper-doll implementation used the complete width and repeated names beside each side icon.
- Current implementation converts the paper doll to an icon-led stage, adds one vertical divider, and uses the reclaimed right side for a continuous 17-row equipment-detail rail with enchant/gem icons.
- The first in-client capture exposed a brighter gray-blue Equipment surface than the Today lanes. The Equipment surface was changed from `raised` to the exact same `panel` role used by `CreateTodayColumn`; runtime assertions now compare their rendered RGBA values directly.
- The next focused capture showed the perimeter item icons reading too large. Their artwork was reduced from 48px to 44px while preserving every rail anchor, stride, and the 48px interaction slot.
- Runtime, navigation, design-system, privacy, synchronization, and Lua syntax checks pass.
- Post-fix visual evidence remains unavailable pending an in-game capture.

**Implementation checklist**

- Reload the addon in Titan Reforged Classic.
- Capture the complete Equipment tab at the current UI scale.
- Compare the stage/list width balance and a focused group of detail rows.
- Adjust only measured layout or typography values if the client capture exposes drift.

**Follow-up polish**

- Revisit the fixed 520px rail only if real long item names consistently truncate at the user's UI scale.

final result: blocked

# Character Details · raid-header metadata QA — 2026-09-07

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-bb5f6418-537b-4f90-985a-58cfbb5d5124.png`.

**Implementation evidence**

- The `团队副本` header metadata contains only `副本 completed/total`.
- Weekly progress remains in the dedicated `周常任务` section and is no longer duplicated.
- Header height, right anchor, typography, divider, raid ordering, and progress semantics are unchanged.

**Verification**

- [x] Runtime assertion rejects weekly copy in the Today raid header.
- [x] Static integration and all three locale checks cover the dedicated raid-only format.
- [x] `git diff --check`.
- [ ] In-client focused-region comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · Ember weekly-progress emphasis QA — 2026-09-07

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-932aa44a-04a6-4d00-94a7-d68a1c263a55.png`.

**Implementation evidence**

- Weekly Ember progress uses the existing 14px `number` role, matching the current Ember quantity.
- Its right edge is positioned from the rendered quantity width with one existing 4px `xs` spacing token between the two strings.
- The existing `success` token is used below cap and `danger` at or above cap; missing weekly data remains empty.
- Resource row height, quantity alignment box, icon, outer border, and all other resource rows are unchanged.

**Verification**

- [x] Runtime assertions cover cap red, below-cap green, equal font size, and exact 4px text gap.
- [x] Static integration checks cover the design-system roles and semantic color rule.
- [x] `git diff --check`.
- [ ] In-client focused-region comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · Today count hierarchy QA — 2026-09-07

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-e36d67f3-fb2c-48cb-8e9b-7f0868df1ebc.png`.

**Implementation evidence**

- The overview band shows only the combined pending count; its weekly-only right label is hidden.
- `专业日常` and `周常任务` each use the same existing 14px `heading` role as their left-hand title for the `completed/total` value.
- The profession-daily denominator includes eligible rows only, so unlearned, locked, and unknown rows cannot distort the pending-total breakdown.
- Existing header heights, row heights, icons, dividers, colors, and horizontal anchors are unchanged.

**Verification**

- [x] Runtime assertions cover `0/1`, `0/2`, `0/3`, and `1/3` profession-daily states plus the hidden overview breakdown.
- [x] Static integration guard rejects the old weekly-only overview label.
- [x] `git diff --check`.
- [ ] In-client focused-region comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · operations timestamp removal QA — 2026-09-07

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-5b6df433-b765-4408-85e8-b023a11f0bc7.png`.

**Implementation evidence**

- The `资源与快捷入口` header metadata is always empty; its title, fixed 38px header,
  divider, and lane geometry are unchanged.
- The consolidated latest snapshot remains in the character identity header.
- No spacing, border, row, icon, or typography changes were introduced.

**Verification**

- [x] Static integration guard rejects the old resource-timestamp assignment.
- [x] Runtime assertion verifies the operations header metadata is empty.
- [x] `git diff --check`.
- [ ] In-client focused-region comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · raid/profession divider polish QA — 2026-09-07

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- Raid lane and group boundary: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-9de53a9f-99eb-4d2a-81f6-0fd902774d6c.png`.
- Focused raid-row treatment: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-979180ae-cd55-4925-a742-6befddf8b4e6.png`.
- Profession/quick-view boundary: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-921bebea-e504-49f9-83a1-774c5aa88a25.png`.
- Profession-daily/weekly boundary: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-bfe353e1-4608-4ebe-9e46-2cb1a49377f4.png`.

**Implementation evidence**

- The last `已有进度` row extends its bottom divider from the row's normal 22px lane inset to the same 12px lane inset used by the `团队副本` header divider.
- All ordinary raid rows retain their prior dimensions and narrower divider inset.
- The final visible profession row hides its own divider; the profession section boundary remains unchanged, leaving exactly one line above `快速查看`.
- The fixed final profession-daily row follows the same rule, leaving exactly one section boundary above `周常任务`.
- No row height, icon size, typography, outer border, local color, or section geometry changed.

**Verification**

- [x] Static integration checks cover both divider rules.
- [x] Runtime assertions verify the group-boundary width, ordinary row inset, and final-profession divider suppression.
- [x] `git diff --check`.
- [ ] In-client focused-region comparison. This iteration does not operate the game client.

final result: blocked

# Character Details · fixed profession-daily catalog QA — 2026-09-07

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- Selected direction 1: `/Users/liushuxiang/.codex/generated_images/01a07b24-851f-76e3-a764-9a2238d8d18a/exec-cbb95c66-61c6-4bf2-8835-2fda52bef4be.png`.
- Required state: a fixed `珠宝日常 / 烹饪日常 / 钓鱼日常` list; eligible rows remain full-strength and interactive, while unlearned rows are visibly subordinate without changing row geometry.

**Implementation evidence**

- The list always renders the same three definitions in the same order; unavailable entries are no longer removed or replaced by a synthetic completion row.
- Existing 52px rows, 32px icon slots, 1px dividers, typography roles, and spacing are unchanged.
- Unlearned rows use 45%-alpha icons plus existing muted/disabled text tokens, show `未学习{专业}` and `未学习`, and omit both hover emphasis and `查看`.
- Learned but locked rows reuse that geometry with the exact requirement and `暂不可做`; unknown snapshots show `未扫描`.
- No badges, new containers, local colors, gradients, shadows, or borders were introduced.

**Verification**

- [x] Static integration checks cover the fixed catalog and prohibit the old synthetic placeholder.
- [x] Runtime assertions cover learned unfinished, learned completed, unlearned, locked, and unknown eligibility states.
- [x] `git diff --check`.
- [ ] In-client full-view and focused-region comparison. The user explicitly asked not to operate the client for this iteration.

final result: blocked

# Character Details · Today focused polish QA — 2026-09-07

**Result: blocked for final in-client visual comparison; structural implementation passed**

**Source visual truth**

- Daily eligibility note: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-4c9da7b3-83a0-4ec4-88ee-655012517996.png`.
- Weekly status icon: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-db2fb00f-6eab-41b8-9712-dbf4b287b6f3.png` and the proposed centered treatment in `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-dacef9b6-1be0-4b97-b9f9-affcd0d3c179.png`.
- Lane-title baseline: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-cf4dc71a-ffae-4f5a-8d82-716511743149.png`.
- Profession alignment: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-a481e5a1-8f79-4b76-a49d-1259527798c8.png`.
- Quick previews: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-8aae0a6f-2ade-4424-9f72-7fb408e811df.png`.
- Full-width summary divider: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-74ca2c2d-7e1e-46b4-bbcf-c3488ce5a216.png`.

**Implementation evidence**

- Inapplicable daily notes are removed from Today; exact eligibility reasons remain on `专业与资源`.
- Weekly rows use the same Blizzard ready/waiting textures as raid rows. The artwork is fixed at 18 × 18 and centered in the unchanged 32px icon slot.
- All three lane headings and their metadata are children of one fixed 38px header frame and use middle vertical justification.
- Profession name and rank text use explicit left justification and terminate before the right-hand status region.
- Equipment and backpack remain fixed 64px previews with 32px item icons. They are separate borderless `raised` surfaces with a 10px gap; hover changes the whole background and reveals a 2px focus accent.
- No new local colors, gradients, shadows, rounded containers, or card borders were introduced.
- The divider above `每日任务` cancels the summary's 12px left/right content inset and spans the complete Today-task lane; its height and vertical position are unchanged.

**Verification**

- [x] Static character-details integration checks.
- [x] Runtime frame assertions cover hidden eligibility notes, weekly icon texture/size, title-header centering, profession alignment, fixed preview dimensions, and preview hover state.
- [x] `git diff --check`.
- [ ] In-client full-view and focused-region comparison. The user explicitly asked not to operate the client for this iteration.

final result: blocked

# Character Details · Today three-lane QA — 2026-09-07

**Result: passed**

**Source visual truth**

- Selected third concept: `/Users/liushuxiang/Desktop/Personal/BGForge/docs/design/character-details-today-three-lane.png` (1396 × 1127).
- Required state: `大界面` → character details → `今日`, preserving every existing task, raid, resource, profession, equipment, and bag entry shown by the source.
- Fidelity contract: three outer lanes only; 8px lane gaps; 25.2% / 39.6% / remaining-width columns; no per-row frames; 1px hairline dividers; fixed task, raid, resource, and preview dimensions.

**Implementation evidence**

- Production UI: `Core/Module/CharacterDetails.lua`.
- Localization: `Locales/zhCN.lua`, `Locales/zhTW.lua`, and `Locales/enUS.lua`.
- Design-system contract: `design-system/pages/auction-workspace.md`.
- Post-fix in-client screenshot: `/Users/liushuxiang/Desktop/Personal/BGForge/docs/design/character-details-today-inclient-2026-09-07.jpg` (3840 × 2160).
- Captured state: Titan client, current character `凋零序曲`, BGForge `大界面`, `今日` tab, live task/raid/resource data.
- The implementation screenshot is a full-client capture. The BGForge detail surface is centered and remains readable at source comparison scale; the surrounding game UI and character selector are host context rather than part of the selected concept.

**Full-view comparison evidence**

- The reference and implementation were inspected together at original source resolution and full 4K client resolution.
- Overall composition matches: character header and navigation remain unchanged, followed by three equal-height outer lanes with the task lane narrowest, raid lane widest, and operations lane between them.
- All source content groups are present in the same order: daily/weekly tasks; completed/not-started raids; resources; professions; equipment; bag.
- No clipping, overlap, unintended wrapping, missing texture, or extra row container is visible in the captured state.

**Focused-region comparison evidence**

- Borders: exactly the three outer lane surfaces use the design-system border; rows use only bottom hairline dividers. No decorative card borders were added.
- Dimensions: lane gaps are 8px; the fixed row dimensions are task 52px, raid 40px, resource 37px, preview 64px; task icons and preview icons are 32px; the raid progress track is 170 × 7px.
- Typography: existing BGForge title, body, secondary, warning, success, and link roles are reused. Names, values, reset copy, and actions remain legible in the live client.
- Colors: the implementation uses the existing panel/canvas/border/focus and semantic status tokens. Gold, cyan, green, warning yellow, and secondary gray retain their established meanings.
- Image quality: all item, profession, currency, and status artwork comes from live Blizzard textures or the saved game snapshot. No generated mock asset is referenced by addon code.
- Copy/content: the live implementation contains `今日任务`, the pending-count summary, `专业日常`, `周常任务`, `团队副本`, `已有进度`, `尚未开始`, `资源与快捷入口`, `资源总览`, `专业技能`, and `快速查看`, with the same underlying records as the previous page.

**Interaction evidence**

- `今日` tab opens and renders with live data.
- Profession-daily, profession-skill, weekly, and raid summaries do not expose dead `查看` or hover states.
- Equipment and Backpack quick-preview surfaces remain interactive.
- Returning to `今日` restores the three-lane view without errors.

**Comparison history**

- Iteration 1: replaced the previous two-column card wall with three measured outer lanes while preserving all existing content and shortcuts.
- Iteration 1: removed row borders and retained only lane outlines plus shared hairline dividers.
- Iteration 1: separated completed and pending raids into labeled groups and moved completion state into icon, color, progress, and count rather than a redundant status line.
- Iteration 1: promoted the task summary to a compact overview band and kept daily and weekly sections in one scan path.
- Iteration 1: consolidated resources, professions, equipment, and bag into one operations lane with precise fixed heights.
- Post-fix evidence: in-client 4K capture matches the selected hierarchy and measured proportions; structural and integration regressions pass.

**Verification**

- [x] `tests/character_details_integration.sh`
- [x] `tests/design_system_integration.sh`
- [x] `tests/character_overview_status_visual_integration.sh`
- [x] `tests/character_overview_reset_visibility_integration.sh`
- [x] `tests/bglite_v13_sync_integration.sh`
- [x] `tests/character_details_render_regression.lua` under Fengari
- [x] `tests/design_system_regression.lua` under Fengari
- [x] `tests/raid_lockout_overview_regression.lua` under Fengari
- [x] `git diff --check`
- [ ] Native Lua 5.1 compiler check is unavailable on this machine; Fengari successfully loads and exercises the changed Lua modules.

final result: passed

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

## Page Header QA — 2026-09-06

**Comparison Target**

- Source visual truth: `/Users/liushuxiang/.codex/generated_images/01a07691-b072-7c93-be08-524cc89a70f2/exec-7d82907b-b41e-42e5-9a67-5b50e5adf0d0.png`
- Source pixels: 1448 × 1086
- Implementation screenshot: unavailable; the WoW/Titan client runtime is not available in this workspace session
- Implementation pixels: unavailable
- CSS size and density normalization: not applicable to the WoW UI runtime; source density is an image-generation preview
- Intended state: embedded “角色总览” and “心愿清单” large interfaces at the viewport shown in the supplied full-page references

**Findings**

- [P2] Runtime visual comparison is pending
  Location: shared page header in both embedded large interfaces.
  Evidence: the source mock is open and readable, but there is no post-change WoW client screenshot to place beside it. Static layout assertions confirm the intended 72px height, 18px title, 14px instruction, 3×40px accent, and per-page content baseline; they cannot prove final font metrics after WoW UI scaling.
  Impact: wrapping, optical vertical centering, and the exact relationship to the live table/workbench cannot be signed off from source code alone.
  Fix: reload the addon in Titan Reforged Classic, capture both large interfaces at the same UI scale as the references, and compare those captures with the selected mock.

**Required Fidelity Surfaces**

- Fonts and typography: statically matched to the selected design tokens (18px title, 14px instruction, existing WoW font and outline); live font metrics remain unverified.
- Spacing and layout rhythm: statically matched to a 72px header, centered two-line group, 3×40px accent, and content-aligned insets; live scaling remains unverified.
- Colors and visual tokens: existing Arcane Archive `header`, `focus`, `textPrimary`, and `textSecondary` tokens are preserved.
- Image quality and asset fidelity: no new image assets were introduced; existing item icons and product chrome are unchanged.
- Copy and content: existing localized page titles and instructions are preserved.

**Full-view Comparison Evidence**

- Blocked because no rendered implementation capture is available.

**Focused Region Comparison Evidence**

- Blocked for the same reason; the page-header region needs a post-reload in-game crop.

**Comparison History**

- Initial implementation: changed the shared page-header geometry and typography, then added page-specific baseline insets.
- In-client feedback exposed an invisible text region: both horizontal anchors targeted the header center, producing a negative-width FontString.
- Fix: retain the vertically centered composition while anchoring the left edge to the header's `LEFT` and the right edge to its `RIGHT`; a regression assertion now rejects center-to-center or otherwise inverted spans.
- In-client spacing feedback: reduced both page headers to the shared 18px leading inset so the title group sits closer to the Rune Blue marker.
- Automated verification: design-system, wishlist render, raid-lockout overview, character-details, wishlist integration, and privacy checks pass.
- Post-fix visual evidence: unavailable pending an in-game capture.

**Implementation Checklist**

- Reload BGForge in Titan Reforged Classic.
- Capture the large “角色总览” page.
- Capture the large “心愿清单” page.
- Compare both headers with the selected source mock at the same UI scale.

**Follow-up Polish**

- Adjust only the vertical offsets or per-page inset if the WoW font's live optical bounds differ from the test harness.

final result: blocked

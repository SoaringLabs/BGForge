# Auction Workspace

This file overrides `design-system/MASTER.md` for the primary auction/accounting frame.

## Outcome

Let the raid operator record an item, buyer, and amount with minimal pointer travel while continuously seeing auction status and financial totals.

All existing content and business effects remain available. The redesign changes hierarchy and interaction, not accounting behavior.

## Layout direction

Use the selected Arcane Archive structure:

1. Compact identity/status bar.
2. Horizontal instance selector.
3. One unified ledger with boss/group rows.
4. Right context inspector for the selected record or summary.
5. Collapsible recent-auction tray along the bottom.
6. Bottom search, equipment filters, and secondary actions.

## Header navigation

- Keep the auction-record toggle as the only frequent task destination on the left.
- Keep low-frequency utilities on the right: notification positioning, about, then settings.
- The raid-leader-only auction-generation selector sits immediately before the utility group.
- Utility anchors are independent of the selector so gaining or losing raid-leader status does not move them.
- Close remains the rightmost control and is not mixed into either navigation group.

## Character details — Today

The selected visual truth for the large-interface character-details Today page is
[`../../docs/design/character-details-today-three-lane.png`](../../docs/design/character-details-today-three-lane.png).

The implementation must preserve its three-lane composition:

1. Today tasks: 25.2% of the available content width.
2. Raid progress: 39.6% of the available content width.
3. Resources and shortcuts: the remaining width.

Use an 8px gap between lanes. Only the three lane surfaces draw outer 1px borders.
Sections inside a lane are borderless and use a single shared divider where the visual
truth shows one. Task, profession, and raid rows never draw a complete rectangle.

The following measurements are fixed fidelity constraints rather than suggestions:

| Element | Size |
| --- | ---: |
| Lane heading | 38px high |
| Today summary | 52px high |
| Inner section heading | 34px high |
| Task and profession row | 52px high |
| Resource row | 37px high |
| Raid row | 40px high |
| Raid progress track | 170px wide × 7px high |
| Task/profession icon | 32px |
| Weekly status icon | 18px, centered in the existing 32px icon slot |
| Quick-preview icon | 32px |
| Quick-preview group | 64px high |

Raid rows are grouped as `已有进度` and `尚未开始`. The group label, status icon,
segmented progress track, and exact kill count communicate state together; do not add a
second status line or a status badge. Preserve every daily, weekly, raid, resource,
profession, equipment, backpack, timestamp, and summary already in the Today data model.
Preserve navigation only where a destination still exists.

The `团队副本` lane header metadata shows only `副本 completed/total`. Weekly progress
belongs exclusively to the `周常任务` section and must not be repeated in the raid header.

The divider beneath the final `已有进度` raid is the group boundary above `尚未开始`.
It spans from 12px inside the raid lane to 12px inside the opposite edge, matching the
lane-header divider. Ordinary raid-row dividers keep their narrower row-content inset.
In `专业技能`, the final visible profession row suppresses its own divider so that only
the section boundary remains; `专业日常` follows the same rule for its fixed final row.
Never render two adjacent horizontal lines at either module boundary.

The `专业日常` section is a fixed catalog: always render `珠宝日常`, `烹饪日常`, and
`钓鱼日常` in that order. Eligible rows retain the 32px full-color icon, reset copy, and
semantic completion state. An unlearned row keeps the same 52px
geometry but uses a 45%-alpha icon, muted name/detail/status, detail copy `未学习{专业}`,
status `未学习`, and no hover action. A learned character below a level or skill threshold
uses the same de-emphasized treatment with the exact reason and status `暂不可做`; unknown
legacy snapshots use `未扫描`. Only eligible unfinished rows contribute to `项待完成`.
Do not add badges, cards, borders, or an eligibility footnote. Weekly rows reuse the same
Blizzard ready/waiting status artwork as raid rows, with the 18px artwork centered inside
the unchanged task-icon slot.

The separate `专业与资源` detail tab and page no longer exist. Their profession-daily,
profession-skill, cooldown, currency, fragment, and upgrade-material summaries are owned
by Today. Consequently, profession-daily and profession-skill rows do not render a `查看`
action or an interactive hover state. The separate `进度` detail tab and page no longer
exist either: raid and weekly rows are complete summaries inside Today, so they also do not
render a `查看` action or interactive hover state. Equipment and Backpack shortcuts remain
interactive.

The divider beneath the Today summary spans the full width of the task lane. It marks the
summary above as a complete `今日任务` module before the independent `专业日常` module begins;
unlike row dividers, it does not inherit the lane's 12px content inset.

The Today summary contains only the combined `N 项待完成` value; do not repeat a weekly-only
count on its right. Put the breakdown beside the corresponding section titles using the
same 14px `heading` role as the title: `专业日常` shows completed/eligible dailies and excludes unlearned,
locked, or unknown rows from its denominator; `周常任务` shows completed/total weeklies.
The two incomplete counts must add up to the combined pending total.

Each lane title and its optional metadata are vertically centered inside the same fixed
38px header frame. Profession names and rank details are left-aligned immediately after
the icon slot; reserving room for the right-hand cooldown status must not center the name.
The `资源与快捷入口` lane does not render header metadata: its resources, profession
cooldowns, equipment, and backpack have different snapshot times, so one timestamp there
would be ambiguous. The consolidated latest snapshot remains in the character header.

In the `泰坦余烬` resource row, weekly acquisition progress is secondary to but visually
paired with the current quantity. It uses the same 14px `number` role, and its right edge
sits one `xs` (4px) token before the rendered quantity text rather than before the quantity's
fixed-width alignment box. Use `success` while earned is below the weekly maximum and
`danger` once earned reaches or exceeds that maximum. Missing or invalid weekly data remains hidden.

Equipment and backpack remain separate 64px quick-preview groups with a 10px gap. Each is
a borderless `raised` surface, and whole-block hover changes the surface to `hover` while
revealing a 2px Rune Blue leading accent. This is the only new interaction emphasis; do
not add card outlines around either group.

Use only Arcane Archive tokens. Do not add local colors, gradients, decorative textures,
rounded containers, drop shadows, or additional borders while implementing this page.

## Character details — Equipment

The large-interface character-details Equipment page combines the selected paper-doll
direction in
[`../../docs/design/character-details-equipment-paper-doll.png`](../../docs/design/character-details-equipment-paper-doll.png)
with the compact equipment-detail treatment in
[`../../docs/design/character-details-equipment-detail-reference.png`](../../docs/design/character-details-equipment-detail-reference.png).

Use one continuous `panel` equipment surface inset 8px from the content area, matching
the exact background and border roles used by the three Today lanes. Its left
side is a fluid paper-doll stage and its right side is a fixed-width equipment-detail
rail, separated by one 1px vertical divider. Do not restore the old multi-column table
or a separately bordered item-inspector card. The only repeated outlines are the native
item-quality borders around item icons; slot groups and detail rows remain borderless and
use the Arcane Archive `hover` fill on hover.

The slot mapping follows the conventional 19-slot paper doll:

1. Left rail: head, neck, shoulder, back, chest, shirt, tabard, wrist.
2. Right rail: hands, waist, legs, feet, finger 1, finger 2, trinket 1, trinket 2.
3. Bottom rail: main hand, off hand, ranged.

The paper-doll stage is intentionally icon-led: side rails show 44px item icons only,
while the bottom rail keeps a compact slot label above each weapon icon. Names and item
levels are not duplicated beside those icons. Empty slots preserve the Blizzard slot
silhouette at 38% alpha and remain in place, so the anatomical mapping never shifts with
missing data.

The detail rail contains the 17 functional equipment positions in standard order and
omits shirt and tabard. Each 32px row has fixed columns for slot, item level, item name,
then up to five recorded enchant/gem icons. The selected row uses only the subtle focus
fill and a 2px leading Rune Blue accent; hover adds a fill without another outline. The
list reads the existing equipment snapshot and must not introduce any new collection,
storage, synchronization, or player-data fields.

The following measurements are fixed fidelity constraints:

| Element | Size |
| --- | ---: |
| Equipment surface inset | 8px |
| Inner content inset | 12px |
| Detail rail | 520px wide |
| Stage/detail gap | 12px with one centered 1px divider |
| Item icon | 44px |
| Side slot group | 48 × 48px |
| Side rail top inset | 16px |
| Side slot stride | 58px |
| Bottom slot group | 104 × 72px |
| Bottom slot gap | 20px |
| Bottom rail inset | 16px |
| Selected-item icon | 64px |
| Enchant/gem icon | 28px, 8px gap |
| Class/spec watermark | 240px, 5.5% alpha |
| Detail header | 38px high |
| Detail row | 32px high |
| Detail enchant/gem icon | 18px, 4px gap |

The central area displays only the selected item's quality-colored name, 64px icon,
slot and item-level line, and recorded enchant/gem icons. Use the character's real
Blizzard class/spec artwork as the subdued watermark; it is context, not another data
card. Clicking an occupied or empty paper-doll slot or detail row updates both the center
detail and the detail-row selection without changing the geometry. Modified item clicks
keep the game's native item-link behavior.

## Character details — Backpack

The large-interface Backpack page keeps the information architecture shown in the
approved pre-alignment reference: search, four category filters, grouped item grid,
capacity summary, and hovered item link. It reuses the same continuous `panel` surface
as Today and Equipment; do not introduce a brighter page-specific canvas.

The 42px Backpack header is a raw frame with one inset bottom divider. Search remains in
the header and keeps its existing 180 × 24px input geometry. The summary remains right
aligned. Category filters keep their existing 78 × 28px hit areas and positions, but use
the shared character-detail text-navigation treatment: secondary text at rest, Rune Blue
text plus a 2px underline when selected, and no filled tab background or outline.

Each non-empty item category uses a 26px raw heading row with one full-width bottom
divider. Do not wrap headings in header surfaces or bordered strips. Item icons remain
35px with an 8px gap and retain their native item-quality border, count/item-level badge,
tooltip, modified-click behavior, filtering, and search behavior. Empty categories remain
omitted, matching the existing data behavior.

The item grid and the 220px summary rail share the same panel background. Separate them
with exactly one 1px `borderSubtle` vertical divider positioned 8px after the grid; the
summary text begins 12px after that divider. Do not add a summary card or another outer
border. Use only Arcane Archive tokens and preserve all existing Backpack copy and data.

## Character details — Navigation

The large-interface detail navigation contains exactly three destinations in this order:
`今日`, `装备`, `背包`. All three use the shared lightweight text-and-underline treatment.
Do not recreate `专业与资源` or `进度` tabs, and do not retain hidden routes for either page;
attempting to select an unknown view falls back to Equipment as before.

## Primary module navigation

- Place the full-page module tabs directly below the global header and above the instance selector.
- Keep the module order: table, character overview, wishlist, reconciliation, then mail history.
- The character-overview **large interface** is a full-page workspace module. Selecting its “角色总览” tab replaces the current module inside the BGForge main frame, like wishlist and reconciliation; it must not open another overlay.
- The large interface uses the shared 72px page header. Its 18px title and 14px instruction sit 18px from the leading edge, while a short Rune Blue marker identifies the page without drawing another full-height edge.
- Hide the contextual instance selector while the large interface is selected. The character-overview **small interface** remains an independent quick-access surface opened by hovering the minimap icon; both interfaces reuse the same renderer.
- In both overview tables, hovering a large-interface row applies the neutral row wash across every column. Hovering the character-name region replaces that wash with the existing name-only highlight and navigation cue; clicking it opens character details.
- Treat the instance selector as contextual secondary navigation beneath the module tabs.
- The migration changes position only; existing class-color default, hover, and selected treatments remain until the tab styling migration is approved separately.
- Remove the former bottom attachment point so the primary navigation remains visible before users scan the workspace.

## Ledger

- Use stable columns for item, equipment/meta, buyer, amount, status, expense/subsidy, net, split count, wage, and note where applicable.
- Boss/group headers collapse their child rows and expose a count plus subtotal.
- The selected row uses Rune Blue fill, border, and left/bottom indicator.
- Editing occurs in place for the common path. The inspector exposes details that do not fit safely in a dense row.
- Do not render large blocks of empty edit boxes. Collapsed or empty groups show one named empty row and an add action.

## Auction tray

- Default height shows the most recent three records.
- The tray can collapse without losing the selected ledger state.
- Record states always use a label in addition to color.
- Search covers item, buyer, and amount as it does today.

## Totals and actions

- Keep total income, expense, net, split count, and wage visible at the ledger edge.
- Use Forge Gold for major positive value, semantic danger for loss/error, and primary text for neutral totals.
- Present one context-sensitive primary action. Bill, failed-auction, expense, debt, report, and team actions remain secondary.
- Destructive clear/reset actions are visually separated from reporting actions.

## Migration constraint

During implementation, each migrated ledger field must map to an existing BGForge behavior before legacy UI is removed. No new player identity, roster, synchronization, or cross-flavor data may be added for layout convenience.

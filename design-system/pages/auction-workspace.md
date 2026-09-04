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

## Primary module navigation

- Place the full-page module tabs directly below the global header and above the instance selector.
- Keep the module order: table, character overview, wishlist, reconciliation, then mail history.
- The character-overview **large interface** is a full-page workspace module. Selecting its “角色总览” tab replaces the current module inside the BGForge main frame, like wishlist and reconciliation; it must not open another overlay.
- Hide the contextual instance selector while the large interface is selected. The character-overview **small interface** remains an independent quick-access surface opened by hovering the minimap icon; both interfaces reuse the same renderer.
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

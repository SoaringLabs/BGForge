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

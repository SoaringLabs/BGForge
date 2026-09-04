#!/usr/bin/env bash

set -euo pipefail

minimap_module="Core/Module/minimap.lua"
overview_module="Core/Module/RaidLockoutOverview.lua"

onclick_body="$(sed -n '/^function plugin:OnClick(button)/,/^end$/p' "$minimap_module")"
hide_line="$(printf '%s\n' "$onclick_body" | rg -n -m1 'BG\.HideRaidLockoutHover\(true\)' | cut -d: -f1 || true)"
branch_line="$(printf '%s\n' "$onclick_body" | rg -n -m1 'if button == "LeftButton"' | cut -d: -f1 || true)"

if [[ -z "$hide_line" || -z "$branch_line" || "$hide_line" -ge "$branch_line" ]]; then
    echo "minimap click does not immediately dismiss the hover overview before handling the click" >&2
    exit 1
fi

if ! rg -q 'function BG\.HideRaidLockoutHover\(immediate\)' "$overview_module" \
    || ! sed -n '/function BG\.HideRaidLockoutHover(immediate)/,/^end$/p' "$overview_module" \
        | rg -q 'if immediate then' \
    || ! sed -n '/function BG\.HideRaidLockoutHover(immediate)/,/^end$/p' "$overview_module" \
        | rg -q 'hoverFrame:Hide\(\)'; then
    echo "raid-lockout hover API does not provide an immediate dismissal path" >&2
    exit 1
fi

echo "minimap hover click regression tests passed"

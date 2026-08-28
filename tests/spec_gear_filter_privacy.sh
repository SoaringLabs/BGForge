#!/usr/bin/env bash
set -euo pipefail

module="Core/Module/SpecGearFilter.lua"

if rg -n 'UnitName|GetRealmID|UnitGUID|SendAddonMessage|RegisterAddonMessagePrefix|BNGet|C_BattleNet|raidRosterInfo|GetActiveTalentGroup|GetSpecialization' "$module"; then
    echo "privacy-sensitive API found in $module" >&2
    exit 1
fi

if rg -n 'SpecGearFilter' \
    Core/FBUI/HistoryUIfunction.lua \
    Core/Module/Loot.lua \
    Core/Module/AuctionWA.lua; then
    echo "out-of-scope SpecGearFilter mount point found" >&2
    exit 1
fi

if ! rg -q 'SpecGearFilter\.ApplyToCell' Core/Module/AuctionLog.lua; then
    echo "automatic auction log does not apply SpecGearFilter when rows are created" >&2
    exit 1
fi

if ! rg -q 'SpecGearFilter\.ApplyToAuctionFrame' Core/Module/Auction.lua; then
    echo "active auction does not apply SpecGearFilter auto-collapse when a bid frame is created" >&2
    exit 1
fi

if ! rg -q 'autoAuctionFold.*default = 0' Core/Options.lua; then
    echo "filtered auction auto-collapse option is missing or not disabled by default" >&2
    exit 1
fi

echo "SpecGearFilter privacy and scope checks passed"

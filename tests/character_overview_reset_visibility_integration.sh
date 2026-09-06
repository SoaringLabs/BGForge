#!/usr/bin/env bash
set -euo pipefail

overview="Core/Module/RaidLockoutOverview.lua"

# The reset timer must be drawn inside the top bar, not underneath its
# translucent backdrop, and should reuse the standard table-header treatment.
rg -Fq 'local resetText = topBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")' "$overview"
rg -Fq 'resetText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")' "$overview"
rg -Fq 'resetText:SetTextColor(unpack(COLOR.textSecondary))' "$overview"
rg -Fq 'resetText:SetPoint("RIGHT", settings, "LEFT", -10, 0)' "$overview"
rg -Fq 'title:SetJustifyH("LEFT")' "$overview"

if rg -Fq 'local refresh = CreateIconButton("Interface\\Buttons\\UI-RotationRight-Button-Up", REFRESH)' "$overview"; then
    echo "Character overview must rely on automatic refresh instead of a toolbar refresh button" >&2
    exit 1
fi

echo "Character overview reset visibility integration checks passed"

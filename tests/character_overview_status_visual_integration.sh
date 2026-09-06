#!/usr/bin/env bash
set -euo pipefail

design_system="Core/UI/DesignSystem.lua"
overview="Core/Module/RaidLockoutOverview.lua"
overview_spec="design-system/pages/character-overview.md"

if ! rg -Fq 'focusSurfaceSubtle = HexColor("182634", 0.96)' "$design_system" \
    || ! rg -Fq 'success = HexColor("62C978", 1)' "$design_system"; then
    echo "quiet current-row or muted-success design tokens are missing" >&2
    exit 1
fi

if ! rg -Fq 'current = DesignColor("focusSurfaceSubtle")' "$overview" \
    || ! rg -Fq 'success = DesignColor("success")' "$overview" \
    || ! rg -Fq 'check:SetVertexColor(unpack(COLOR.success))' "$overview" \
    || ! rg -Fq 'CreateStatusDisplay(contentFrame, column.compactWidth, ui.rowHeight, 14, 11, true)' "$overview" \
    || ! rg -Fq 'resetText:SetTextColor(unpack(COLOR.textSecondary))' "$overview"; then
    echo "character overview does not use the selected clean success treatment" >&2
    exit 1
fi

if ! rg -Fq 'local emberEarnedThisWeek = hoverEmbedded and character.titanEmbersEarnedThisWeek or nil' "$overview" \
    || ! rg -Fq 'local emberWeeklyMax = hoverEmbedded and character.titanEmbersWeeklyMax or nil' "$overview"; then
    echo "floating character overview still includes Titan Ember weekly progress" >&2
    exit 1
fi

if rg -Fq 'check:SetDesaturated(true)' "$overview"; then
    echo "completion checks are still being dimmed by desaturation" >&2
    exit 1
fi

if rg -q 'status\.background:SetColorTexture\(unpack\((status\.completeColor|COLOR\.complete)' "$overview"; then
    echo "completed cells reintroduced a full green background fill" >&2
    exit 1
fi

if ! rg -Fq 'no green cell fill' "$overview_spec"; then
    echo "character overview design guidance does not document the clean completion state" >&2
    exit 1
fi

echo "Character overview status visual integration checks passed"

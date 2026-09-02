#!/usr/bin/env bash

set -euo pipefail

module="Core/UI/DesignSystem.lua"
overview="Core/Module/RaidLockoutOverview.lua"

if ! rg -q '^Core\\UI\\DesignSystem\.lua$' BGForge.toc; then
    echo "Design-system module is not loaded by BGForge.toc" >&2
    exit 1
fi

db_line="$(rg -n '^Core\\DB\\DB\.xml$' BGForge.toc | cut -d: -f1)"
ui_line="$(rg -n '^Core\\UI\\DesignSystem\.lua$' BGForge.toc | cut -d: -f1)"
functions_line="$(rg -n '^Core\\function1\.lua$' BGForge.toc | cut -d: -f1)"
if [[ -z "$db_line" || -z "$ui_line" || -z "$functions_line" ]] \
    || (( db_line >= ui_line || ui_line >= functions_line )); then
    echo "Design system must load after BG initialization and before feature UI helpers" >&2
    exit 1
fi

rg -q 'function UI\.Token' "$module"
rg -q 'function UI\.Style' "$module"
rg -q 'function UI\.Create' "$module"
rg -q 'function UI\.SetState' "$module"
rg -q 'widget\._bgforgeFocusAccent:SetAlpha' "$module"

if rg -q 'OnUpdate|SendAddonMessage|SendCommMessage|UnitGUID|GetRaidRosterInfo|GetGuildRosterInfo|gameFlavor|flavor' "$module"; then
    echo "Design system introduced animation work, data collection, synchronization, or cross-flavor state" >&2
    exit 1
fi

rg -Fq 'DesignColor("focus")' "$overview"
rg -Fq 'DesignColor("rowHoverWash")' "$overview"
rg -Fq 'visible and not controller.isCurrent and 1 or 0' "$overview"
rg -Fq 'raidCurrentAccent:SetColorTexture(unpack(COLOR.focus))' "$overview"
rg -Fq 'resourceCurrentAccent:SetColorTexture(unpack(COLOR.focus))' "$overview"
rg -Fq 'SetIconButtonVisual(button, COLOR.headerStrong, COLOR.gridStrong, COLOR.textPrimary)' "$overview"
rg -Fq 'SetIconButtonBorder(self, COLOR.focus)' "$overview"
if rg -q 'SetTextColor\(0, 0\.75, 1\)|SetBackdropBorderColor\(0, 0\.75, 1' "$overview"; then
    echo "Character overview reintroduced the legacy bright-cyan palette" >&2
    exit 1
fi
if rg -Fq 'SetIconButtonVisual(self' "$overview"; then
    echo "Header icon hover must not recolor the button interior" >&2
    exit 1
fi
if rg -Fq 'DesignColor("rowAlternate")' "$overview"; then
    echo "Character-overview pilot reintroduced alternating base-row fills" >&2
    exit 1
fi
if rg -q 'local function AnimateRowHover' "$overview"; then
    echo "Character-overview pilot reintroduced per-row hover animation work" >&2
    exit 1
fi
if rg -Fq 'overlay:SetColorTexture(unpack(COLOR.focus))' "$overview"; then
    echo "Character-overview row hover must not reuse the selected-state color" >&2
    exit 1
fi

echo "BGForge design-system integration and privacy regression tests passed"

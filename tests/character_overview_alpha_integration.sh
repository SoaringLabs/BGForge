#!/usr/bin/env bash
set -euo pipefail

options="Core/Options.lua"
overview="Core/Module/RaidLockoutOverview.lua"
details="Core/Module/CharacterDetails.lua"
wishlist="Core/Module/WishlistUI.lua"
design_system="Core/UI/DesignSystem.lua"

if [[ "$(rg -c 'CreateBackgroundAlphaSlider\((raidLockout|biaoge)' "$options")" -ne 2 ]] \
    || ! rg -Fq 'CreateBackgroundAlphaSlider(raidLockout, 15, -35, "buttonRaidLockoutAlpha")' "$options" \
    || ! rg -Fq 'CreateBackgroundAlphaSlider(biaoge, 220, height - h, "buttonalpha")' "$options"; then
    echo "table and character-overview settings do not expose the shared opacity slider" >&2
    exit 1
fi

if ! rg -Fq 'local backgroundAlphaSliders = {}' "$options" \
    || ! rg -Fq 'BiaoGe.options.alpha = alpha' "$options" \
    || ! rg -Fq 'BG.UI.RefreshBackgroundAlpha()' "$options" \
    || ! rg -Fq 'BG.RefreshRaidLockoutBackgroundAlpha()' "$options"; then
    echo "background opacity controls are not synchronized through one saved value" >&2
    exit 1
fi

if ! rg -Fq 'local alpha = BiaoGe and BiaoGe.options and tonumber(BiaoGe.options.alpha)' "$overview" \
    || ! rg -Fq 'function BG.RefreshRaidLockoutBackgroundAlpha()' "$overview" \
    || rg -Fq 'local FLOATING_COLOR = {' "$overview"; then
    echo "character-overview surfaces do not consume the shared background opacity" >&2
    exit 1
fi

if ! rg -Fq 'function UI.BindBackgroundAlpha' "$design_system" \
    || ! rg -Fq 'function UI.RefreshBackgroundAlpha' "$design_system" \
    || ! rg -Fq 'backgroundAlpha = true' "$overview" \
    || ! rg -Fq 'backgroundAlpha = true' "$wishlist" \
    || ! rg -Fq 'UI.BindBackgroundAlpha(surface, "SetBackdropColor", role)' "$details"; then
    echo "overview headers, character details, and wishlist modules do not share the material opacity" >&2
    exit 1
fi

echo "Character overview background opacity integration checks passed"

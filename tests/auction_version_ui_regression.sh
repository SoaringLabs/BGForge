#!/usr/bin/env bash
set -euo pipefail

auction_module="Core/Module/Auction.lua"
main_frame="Core/BiaoGe.lua"

if ! rg -q 'BiaoGe\.Auction\.gen ~= 1 and BiaoGe\.Auction\.gen ~= 2' "$auction_module" \
    || ! rg -q 'BiaoGe\.Auction\.gen = 2' "$auction_module"; then
    echo "second-generation auction is not the default for an unset/invalid saved value" >&2
    exit 1
fi

if ! rg -q 'BiaoGe\.Auction\.mod = "normal"' "$auction_module"; then
    echo "auction mode is not pinned to the supported normal mode" >&2
    exit 1
fi

if rg -q -- '-- 拍卖模式|-- 拍卖版本' Core/Options.lua; then
    echo "auction settings still expose a version or mode selector" >&2
    exit 1
fi

if rg -q 'mainFrame\.Text[12]|mainFrame\.dropDown2|\|cffFFD100拍卖模式\|r' "$auction_module"; then
    echo "per-item auction popup still contains auction version or mode controls" >&2
    exit 1
fi

if ! rg -q 'BG\.ButtonAuctionVersion = button' "$auction_module" \
    || ! rg -q 'button:SetPoint\("RIGHT", BG\.MainFrame\.CloseButton, "LEFT", -2, 0\)' "$auction_module" \
    || ! rg -q 'panel:SetPoint\("TOPRIGHT", button, "BOTTOMRIGHT", 0, -2\)' "$auction_module"; then
    echo "right-aligned main-table auction version switch is missing" >&2
    exit 1
fi

if rg -q '"ButtonAuctionVersion"' "$main_frame"; then
    echo "auction version switch was incorrectly left in the system navigation" >&2
    exit 1
fi

if ! rg -q 'IsInRaid\(1\) and UnitIsGroupLeader\("player"\)' "$auction_module" \
    || ! rg -q 'if not IsAuctionVersionLeader\(\) or \(gen ~= 1 and gen ~= 2\)' "$auction_module" \
    || ! rg -q 'button:Hide\(\)' "$auction_module"; then
    echo "auction version visibility or switching is not restricted to the raid leader" >&2
    exit 1
fi

for copy in \
    '仅团长可见并切换。需要暂停/恢复拍卖等功能时，请选择第二代拍卖' \
    '第二代拍卖新增' \
    '团队兼容检测' \
    '名团员支持第二代拍卖' \
    '当有团员不支持时，建议使用第一代拍卖' \
    '需团员使用基于 BGLite 的版本'; do
    if ! rg -Fq "L[\"$copy\"]" "$auction_module"; then
        echo "auction version panel is missing copy: $copy" >&2
        exit 1
    fi
done

if ! rg -q 'CreateFrame\("StatusBar", nil, panel\)' "$auction_module"; then
    echo "second-generation compatibility progress is missing" >&2
    exit 1
fi

if ! rg -q 'local PANEL_WIDTH = 304' "$auction_module" \
    || ! rg -q 'local SECTION_TITLE_SIZE = 16' "$auction_module"; then
    echo "auction version panel width or section title sizing regressed" >&2
    exit 1
fi

if [[ "$(rg -c 'SECTION_TITLE_SIZE, COLOR_GOLD' "$auction_module")" -ne 3 ]]; then
    echo "auction version panel section titles are not using one shared size" >&2
    exit 1
fi

if [[ "$(rg -c 'CreateText\(panel, 10, COLOR_GOLD, "●"\)' "$auction_module")" -ne 2 ]] \
    || ! rg -q 'Interface\\\\FriendsFrame\\\\InformationIcon' "$auction_module"; then
    echo "auction version panel feature markers or information icon are missing" >&2
    exit 1
fi

if ! rg -q 'supported >= total' "$auction_module" \
    || ! rg -q '\|cff33ff40%d / %d\|r %s' "$auction_module" \
    || ! rg -q '\|cffff4033%d / %d\|r %s' "$auction_module" \
    || ! rg -q 'compatibilityText:SetTextColor\(1, 1, 1\)' "$auction_module"; then
    echo "auction compatibility count-only state colors are missing" >&2
    exit 1
fi

if [[ "$(rg -c 'panel:CreateAnimationGroup\(\)' "$auction_module")" -ne 2 ]] \
    || ! rg -q 'fadeInAlpha:SetDuration\(0\.14\)' "$auction_module" \
    || ! rg -q 'fadeOutAlpha:SetDuration\(0\.11\)' "$auction_module"; then
    echo "auction version panel transition animation is missing" >&2
    exit 1
fi

if ! rg -q 'mainFrame\.itemFrame, "BOTTOMLEFT", 10, -2' "$auction_module" \
    || ! rg -q 'mainFrame\.Text3, "RIGHT", 18, 0' "$auction_module"; then
    echo "auction popup fields were not reflowed after removing the selectors" >&2
    exit 1
fi

echo "Auction version UI regression checks passed"

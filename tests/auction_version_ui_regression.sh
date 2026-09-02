#!/usr/bin/env bash
set -euo pipefail

auction_module="Core/Module/Auction.lua"
main_frame="Core/BiaoGe.lua"
overview_module="Core/Module/RaidLockoutOverview.lua"

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
    || ! rg -q 'local function LayoutAuctionVersionButton\(\)' "$auction_module" \
    || ! rg -q 'BG\.ButtonMove or BG\.MainFrame\.CloseButton' "$auction_module" \
    || ! rg -q 'BG\.LayoutMainMenuButtons\(\)' "$auction_module" \
    || ! rg -q 'panel:SetPoint\("TOPRIGHT", button, "BOTTOMRIGHT", 0, -2\)' "$auction_module"; then
    echo "auction version switch is not anchored before the right-side utility group" >&2
    exit 1
fi

if rg -q '"ButtonAuctionVersion"' "$main_frame"; then
    echo "auction version switch was incorrectly left in the system navigation" >&2
    exit 1
fi

if ! rg -Fq 'local leftMenuButtonNames = {' "$main_frame" \
    || ! rg -Fq 'local rightMenuButtonNames = {' "$main_frame" \
    || ! rg -q 'previousButton = BG\.MainFrame\.CloseButton' "$main_frame" \
    || ! rg -q 'button:SetPoint\("RIGHT", previousButton, "LEFT", -BG\.TopLeftButtonJianGe, 0\)' "$main_frame"; then
    echo "main header task and utility groups are not independently anchored" >&2
    exit 1
fi

left_menu="$(sed -n '/local leftMenuButtonNames = {/,/}/p' "$main_frame")"
right_menu="$(sed -n '/local rightMenuButtonNames = {/,/}/p' "$main_frame")"
if [[ "$left_menu" != *'"ButtonAuctionLog"'* ]] \
    || [[ "$left_menu" == *'"ButtonMove"'* || "$left_menu" == *'"ShuoMingShu"'* || "$left_menu" == *'"ButtonSheZhi"'* ]]; then
    echo "left header group must contain only the auction-record destination" >&2
    exit 1
fi
if [[ "$left_menu" == *'"ButtonRaidLockout"'* ]]; then
    echo "character overview was incorrectly left in the global header" >&2
    exit 1
fi
if [[ "$right_menu" != *'"ButtonSheZhi"'* || "$right_menu" != *'"ShuoMingShu"'* \
    || "$right_menu" != *'"ButtonMove"'* || "$right_menu" == *'"ButtonAuctionLog"'* \
    || "$right_menu" == *'"ButtonRaidLockout"'* ]]; then
    echo "right header group must contain only the low-frequency utilities" >&2
    exit 1
fi

if ! rg -q 'BG\.MainNavigationHeight = 30' "$main_frame" \
    || ! rg -q 'BG\.TabButtonsMain:SetPoint\("TOP", BG\.MainFrame, "TOP", 0, -24\)' "$main_frame" \
    || ! rg -q 'BG\.TabButtonsFB:SetPoint\("TOP", BG\.MainFrame, "TOP", 0, -28 - BG\.MainNavigationHeight\)' "$main_frame" \
    || ! rg -q 'CreateFrame\("Button", nil, BG\.TabButtonsMain, "BackdropTemplate"\)' "$main_frame" \
    || rg -q 'BG\.MainFrame, "BOTTOM", -95' "$main_frame"; then
    echo "primary module navigation is not above the contextual instance selector" >&2
    exit 1
fi

if ! rg -q 'SetColor\(bt, true, 1\)' "$main_frame" \
    || ! rg -q 'GetClassRGB\(nil, "player"\)' "$main_frame"; then
    echo "primary module navigation no longer preserves the existing class-color states" >&2
    exit 1
fi

table_line="$(rg -n 'BG\.Create_TabButton\(BG\.FBMainFrameTabNum' "$main_frame" | cut -d: -f1)"
overview_line="$(rg -n 'BG\.CreateRaidLockoutMainFrameTab\(\)' "$main_frame" | cut -d: -f1)"
wishlist_line="$(rg -n 'BG\.Wishlist\.CreateUI\(\)' "$main_frame" | cut -d: -f1)"
if [[ -z "$table_line" || -z "$overview_line" || -z "$wishlist_line" ]] \
    || (( table_line >= overview_line || overview_line >= wishlist_line )); then
    echo "character overview is not immediately after the table in primary navigation" >&2
    exit 1
fi
if ! rg -q 'BG\.Create_TabButton\(' "$overview_module" \
    || ! rg -q 'BG\.RaidLockoutMainFrameTabNum or 2' "$overview_module" \
    || ! rg -q 'BiaoGe\.lastFrame = "RaidLockout"' "$overview_module" \
    || ! rg -q 'ShowEmbeddedOverview\(self\)' "$overview_module" \
    || ! rg -q 'BG\.ClickTabButton\(BG\.RaidLockoutMainFrameTabNum\)' "$overview_module" \
    || ! rg -q 'SetEmbeddedChrome\(true\)' "$overview_module" \
    || rg -q 'BG\.Create_MainNavigationAction\(L\["角色总览"\]' "$overview_module" \
    || rg -q 'button:SetText\(L\["全角色总览"\]\)' "$overview_module"; then
    echo "character overview is not a full-page main-frame module" >&2
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

#!/usr/bin/env bash

set -euo pipefail

module="Core/Module/Wishlist.lua"
ui_module="Core/Module/WishlistUI.lua"

if ! rg -q $'^Core\\\\Module\\\\Wishlist\\.lua\\r?$' BGForge.toc; then
    echo "Wishlist module is not loaded by BGForge.toc" >&2
    exit 1
fi
if ! rg -q $'^Core\\\\Module\\\\WishlistUI\\.lua\\r?$' BGForge.toc; then
    echo "Wishlist UI module is not loaded by BGForge.toc" >&2
    exit 1
fi

wishlist_line="$(rg -n $'^Core\\\\Module\\\\Wishlist\\.lua\\r?$' BGForge.toc | cut -d: -f1)"
wishlist_ui_line="$(rg -n $'^Core\\\\Module\\\\WishlistUI\\.lua\\r?$' BGForge.toc | cut -d: -f1)"
main_line="$(rg -n $'^Core\\\\BiaoGe\\.lua\\r?$' BGForge.toc | cut -d: -f1)"
if (( wishlist_line >= wishlist_ui_line || wishlist_ui_line >= main_line )); then
    echo "Wishlist data and UI must load in order before BiaoGe creates the main tabs" >&2
    exit 1
fi

rg -q 'BG\.Wishlist\.CreateUI' Core/BiaoGe.lua
rg -q 'hasHope = BG\.IsHope\(itemID\)' Core/Module/Auction.lua
rg -q 'BG\.DeleteHope and BG\.DeleteHope\(itemID\)' Core/Module/Trade.lua
rg -q 'BG\.RegisterEvent\("CHAT_MSG_LOOT"' "$module"
rg -q 'BiaoGe\[STORAGE_KEY\]' "$module"
rg -q 'Wishlist\.NotifyDrop\(sourceItemID, link, level, FB, true\)' "$module"
rg -q 'BG\.ShowWishlistAuctionPreview\(sourceItemID, link\)' "$module"
rg -q 'function Wishlist\.BuildBrowseModel' "$ui_module"
rg -q 'ITEM_QUALITY_COLORS' "$ui_module"
rg -q 'GarrMission_ClassIcon-' "$ui_module"
rg -q 'function BG\.ShowWishlistAuctionPreview' Core/Module/AuctionWAEvent.lua
rg -q 'if not isPreview then' Core/Module/AuctionWAEvent.lua
rg -q 'if not f\.isPreview then' Core/Module/Auction.lua

if rg -q 'testDropButton|testAuctionButton|测试掉落（临时）|测试拍卖（临时）' "$ui_module"; then
    echo "Temporary wishlist test buttons are still exposed in the UI" >&2
    exit 1
fi

if rg -q 'BG\.StartAuction|BG\.SendStartAuctionMsg|SendAddonMessage' "$module" "$ui_module"; then
    echo "Wishlist test controls must not start or broadcast auctions" >&2
    exit 1
fi

if rg -q 'SendAddonMessage|SendCommMessage|UnitGUID|GetRaidRosterInfo|GetGuildRosterInfo|BNGet|BattleNet|gameFlavor|flavor' "$module" "$ui_module"; then
    echo "Wishlist introduced synchronization, unrelated player collection, or cross-flavor state" >&2
    exit 1
fi

if rg -q 'BiaoGe\.options\.autoLoot' "$module" "$ui_module"; then
    echo "Wishlist drop reminders must remain independent from auto-loot" >&2
    exit 1
fi

echo "Wishlist integration and privacy regression tests passed"

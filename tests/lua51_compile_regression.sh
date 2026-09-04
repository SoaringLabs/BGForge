#!/usr/bin/env bash

set -euo pipefail

compiler="${LUA51_LUAC:-}"
if [[ -z "$compiler" ]]; then
    for candidate in luac5.1 lua5.1-luac luac; do
        if command -v "$candidate" >/dev/null 2>&1; then
            compiler="$(command -v "$candidate")"
            break
        fi
    done
fi

if [[ -z "$compiler" || ! -x "$compiler" ]]; then
    echo "Lua 5.1 compiler not found; set LUA51_LUAC to a Lua 5.1 luac executable." >&2
    exit 2
fi

version="$($compiler -v 2>&1)"
if [[ "$version" != *"Lua 5.1"* ]]; then
    echo "Expected Lua 5.1 compiler, got: $version" >&2
    exit 2
fi

files=(
    Core/UI/DesignSystem.lua
    Core/Module/HistoryStore.lua
    Core/Module/History.lua
    Core/Module/ClearBiaoGe.lua
    Core/Module/AuctionMSG.lua
    Core/Module/AuctionLog.lua
    Core/Module/RaidLockoutOverview.lua
    Core/Module/CharacterDetails.lua
    Core/Module/Wishlist.lua
    Core/Module/WishlistUI.lua
    Core/BiaoGe.lua
    Core/Module/Auction.lua
    Core/Module/AuctionWA.lua
    Core/Module/AuctionWAEvent.lua
    Core/Module/Loot.lua
    Core/Module/Trade.lua
    Core/Options.lua
)

for file in "${files[@]}"; do
    "$compiler" -p "$file"
done
echo "Lua 5.1 compile regression tests passed"

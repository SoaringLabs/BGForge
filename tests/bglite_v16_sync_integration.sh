#!/usr/bin/env bash
set -euo pipefail

constants='Core/Protocol/Constants.lua'
gateway='Core/Protocol/SendGateway.lua'
constants_line=$(rg -n -F 'Core\Protocol\Constants.lua' BGForge.toc | cut -d: -f1)
gateway_line=$(rg -n -F 'Core\Protocol\SendGateway.lua' BGForge.toc | cut -d: -f1)
database_line=$(rg -n -F 'Core\DB\DB.xml' BGForge.toc | cut -d: -f1)
(( constants_line < gateway_line && gateway_line < database_line ))
rg -q '^## X-Upstream-Release: v1\.6\r?$' BGForge.toc
rg -q '^## X-Upstream-Version: 2\.4\.4\r?$' BGForge.toc
[[ ! -e addon_version.txt && ! -e dd_author.toc && ! -e BGLite.toc ]]

# The audit gateway is the sole owner of direct chat/addon transport.
if rg -n 'C_ChatInfo\.SendAddonMessage\(|(^|[^[:alnum:]_.])SendChatMessage\(|ChatThrottleLib:SendAddonMessage\(' Core -g '*.lua' -g '!SendGateway.lua'; then
    echo 'Direct transport outside SendGateway' >&2
    exit 1
fi
# Private feature modules must remain unable to use the new gateway as well.
if rg -n 'SendGateway|ns\.Protocol' Core/Module/Wishlist.lua Core/Module/WishlistUI.lua Core/Module/SpecGearFilter.lua Core/Module/RaidLockoutOverview.lua Core/Module/CharacterDetails.lua Core/Module/HistoryStore.lua Core/Module/History.lua; then
    echo 'Private feature introduced protocol coupling' >&2
    exit 1
fi
if rg -n '^(<<<<<<<|=======|>>>>>>>|\|\|\|\|\|\|\|)' Core Locales BGForge.toc; then
    echo 'Unresolved merge markers' >&2
    exit 1
fi
printf '%s\n' 'BGLite v1.6 loading, provenance, transport and privacy integration passed'

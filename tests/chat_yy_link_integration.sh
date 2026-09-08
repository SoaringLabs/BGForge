#!/usr/bin/env bash

set -euo pipefail

module="Core/Module/ChatYYLink.lua"

rg -Fq 'Core\Module\ChatYYLink.lua' BGForge.toc
rg -Fq 'if not BG.IsTitan then return end' "$module"
rg -Fq 'ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER"' "$module"
rg -Fq 'ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING"' "$module"
rg -Fq 'ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER"' "$module"
rg -Fq 'ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER"' "$module"
rg -Fq 'if BG.IsSecret(message)' "$module"
rg -Fq 'message:find("|H", 1, true)' "$module"
rg -Fq 'editBox:Insert(insertion)' "$module"

if rg -n 'SavedVariables|YYdb|raidRoster|GetRaidRosterInfo|SendAddonMessage|SendCommMessage|SendChatMessage|RegisterAddonMessagePrefix|gameFlavor|flavor' "$module"; then
    echo "Chat YY links must not persist, collect, transmit, or add cross-flavor behavior" >&2
    exit 1
fi

echo "Chat YY link integration and privacy checks passed"

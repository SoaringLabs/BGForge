#!/usr/bin/env bash

set -euo pipefail

store="Core/Module/HistoryStore.lua"
module="Core/Module/History.lua"
clear_module="Core/Module/ClearBiaoGe.lua"
db="Core/DB/DB.lua"

store_line="$(rg -n '^Core\\Module\\HistoryStore\.lua$' BGForge.toc | cut -d: -f1)"
module_line="$(rg -n '^Core\\Module\\History\.lua$' BGForge.toc | cut -d: -f1)"
main_line="$(rg -n '^Core\\BiaoGe\.lua$' BGForge.toc | cut -d: -f1)"
db_line="$(rg -n '^Core\\DB\\DB\.xml$' BGForge.toc | cut -d: -f1)"
if [[ -z "$db_line" || -z "$store_line" || -z "$module_line" || -z "$main_line" ]] \
    || (( db_line >= store_line || store_line >= module_line || module_line >= main_line )); then
    echo "History store and UI must load in order before BiaoGe creates the main frames" >&2
    exit 1
fi

rg -q 'BG\.HistoryFeatureEnabled = false' "$db"
rg -q 'if not BG\.HistoryFeatureEnabled then return end' "$store"
rg -q 'if not BG\.HistoryFeatureEnabled then return end' "$module"
rg -q 'if not BG\.HistoryFeatureEnabled then return end' Core/FBUI/HistoryUIfunction.lua
rg -q 'if BG\.IsTitan and BG\.HistoryFeatureEnabled then' Core/BiaoGe.lua
if [[ "$(rg -c 'if BG\.IsTitan and BG\.HistoryFeatureEnabled then' Core/Options.lua)" -ne 2 ]]; then
    echo "History settings are not guarded by the soft-disable flag" >&2
    exit 1
fi
rg -q 'if BG\.HistoryFeatureEnabled and BiaoGe\.options\.autoQingKongSaveHistory == 1 then' "$clear_module"

# The dormant implementation stays available for a future policy change.
rg -q '<Script file="HistoryUIfunction.lua"/>' Core/FBUI/FBUI.xml
rg -q 'elseif type == "History" then' Core/FBUI/CreateFBUI.lua
rg -q 'securecall\(BG\.HistoryUI\)' Core/BiaoGe.lua
rg -q 'function BG\.SaveBiaoGe' "$module"
rg -q 'function BG\.SetBiaoGeFormHistory' "$module"
rg -q 'local name = "historyRetentionDays"' Core/Options.lua
rg -q 'BG\.options\[name \.\. "reset"\] = 90' Core/Options.lua
rg -q 'schema = SCHEMA_VERSION' "$store"
rg -q 'record\._bgforge' "$store"
rg -q 'fingerprint = fingerprint' "$store"
rg -q 'source = sourceName' "$store"
rg -q 'FindLatestDuplicate' "$store"
rg -q 'SnapshotsEqual' "$store"
rg -q 'BiaoGe\.options\.autoQingKongSaveHistory = 1' "$store"
rg -q 'local name = "autoQingKongSaveHistory"' Core/Options.lua
rg -q -F 'saved, historyStatus = BG.SaveBiaoGe(FB, {' "$clear_module"
rg -q 'source = "auto-clear"' "$clear_module"
rg -q 'dedupe = true' "$clear_module"
rg -q 'silent = true' "$clear_module"
rg -q '历史表格保存失败，已取消自动清空，当前表格仍然保留' "$clear_module"
rg -q 'type\(BG\.raidRosterInfo\) == "table"' "$clear_module"
rg -q 'if currentCount == 0 then' "$clear_module"
rg -q "本次不会自动清空" "$clear_module"
rg -q 'type\(savedRosterInfo\.roster\) == "table"' "$clear_module"
rg -q 'type\(current\.auctionLog\) == "table"' "$module"
rg -q 'type\(current\.tradeTbl\) == "table"' "$module"
rg -q '确定应用历史表格' "$module"
rg -q 'entry\[4\] == "manual"' "$module"
rg -q 'entry\[4\] == "auto-clear"' "$module"

auto_save_line="$(rg -n -F 'saved, historyStatus = BG.SaveBiaoGe(FB, {' "$clear_module" | cut -d: -f1)"
auto_clear_line="$(rg -n -F 'local num = BG.ClearBiaoGe("biaoge", FB)' "$clear_module" | cut -d: -f1)"
if [[ -z "$auto_save_line" || -z "$auto_clear_line" ]] || (( auto_save_line >= auto_clear_line )); then
    echo "New-lockout clearing must save history successfully before clearing the current ledger" >&2
    exit 1
fi

if rg -n 'SendAddonMessage|SendCommMessage|SendChatMessage|RegisterAddonMessagePrefix|BG\.InsertLink|HistorySummary|GetHistoryMoney|SetHistoryMoney|BG\.ClearBiaoGe' \
    "$store" "$module" Core/FBUI/HistoryUIfunction.lua; then
    echo "History reintroduced sharing, secondary-use aggregation, or save-and-clear behavior" >&2
    exit 1
fi

if rg -n 'tradeTbl|raidRoster|auctionLog|leaderInfo|UnitGUID|GetRaidRosterInfo|GetGuildRosterInfo|gameFlavor' "$store"; then
    echo "History persistence contains a non-whitelisted player or activity field" >&2
    exit 1
fi

if ! rg -q 'for _, field in ipairs\(\{ "zhuangbei", "maijia", "jine" \}\)' "$store" \
    || ! rg -q 'sourceBoss\["qiankuan" \.\. i\]' "$store"; then
    echo "History persistence whitelist is missing or no longer explicit" >&2
    exit 1
fi

if ! rg -q '当前表格不会被清空' "$module"; then
    echo "History save no longer communicates its non-destructive behavior" >&2
    exit 1
fi

echo "History soft-disable, integration, and privacy regression tests passed"

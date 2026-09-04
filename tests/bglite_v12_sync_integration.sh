#!/usr/bin/env bash

set -euo pipefail

toc="BGForge.toc"
db="Core/DB/DB.lua"
options="Core/Options.lua"
clear_module="Core/Module/ClearBiaoGe.lua"
auction_msg="Core/Module/AuctionMSG.lua"
auction_log="Core/Module/AuctionLog.lua"
history_store="Core/Module/HistoryStore.lua"
utf8_data="Libs/UTF8/utf8data.lua"

rg -q $'^## Version: 1\\.1\\.0\\r?$' "$toc"
rg -q $'^## X-Upstream-Version: 2\\.4\\.1\\r?$' "$toc"
rg -q $'^Core\\\\Module\\\\CharacterDetails\\.lua\\r?$' "$toc"
[[ ! -e addon_version.txt ]]

rg -q 'BiaoGe\.options\.autoQingKong = 1' "$db"
if rg -n 'local name = "autoQingKong"|buttonautoQingKong|进本自动清空表格' "$options"; then
    echo "The removed automatic-clear option is still exposed" >&2
    exit 1
fi
if rg -n 'BiaoGe\.options\["autoQingKong"\] ~= 1|IsNotSameTeam|raidRosterInfo|clearType|BG\.SaveBiaoGe' "$clear_module"; then
    echo "Automatic clearing still depends on an old option, roster, content, or history backup" >&2
    exit 1
fi
rg -q 'BG\.FBIDtable\[savedInstanceID\] == FB' "$clear_module"
rg -q 'if locked and BG\.FBIDtable\[savedInstanceID\] == FB then' "$clear_module"

rg -q 'local name = "retainExpenses"' "$options"
rg -q 'local name = "retainExpensesMoney"' "$options"
rg -q 'O\.CreateCheckButton\(name, L\["清空表格时保留支出金额"\], biaoge, 40,' "$options"

if rg -n 'auctionMSGhistory' "$auction_msg"; then
    echo "Auction chat is still persisted across sessions" >&2
    exit 1
fi
rg -q 'BG\.FrameAuctionMSG:AddMessage\(msg\)' "$auction_msg"

rg -q 'if db and db\[index\] and db\[index\]\.type == 2 then' "$auction_log"
rg -q 'for index, v in ipairs\(tbl or \{\}\) do' "$auction_log"
if [[ "$(rg -c $'^\\s*if not BiaoGe\\[FB\\]\\.auctionLog then return end\\r?$' "$auction_log")" -lt 2 ]]; then
    echo "Auction log is missing upstream nil-table guards" >&2
    exit 1
fi
rg -q 'if not BiaoGe\[FB\]\.auctionLog or not BiaoGe\[FB\]\.auctionLog\[i\] then return end' "$auction_log"

if rg -n 'autoQingKongSaveHistory' "$clear_module" "$options" "$history_store"; then
    echo "Automatic history backup coupling was not fully removed" >&2
    exit 1
fi
rg -q '\["auto-clear"\] = true' "$history_store"

if [[ "$(LC_ALL=C head -c 3 "$utf8_data")" == $'\xEF\xBB\xBF' ]]; then
    echo "UTF-8 lookup data still contains the BOM removed by BGLite v1.2" >&2
    exit 1
fi
rg -q '支持常规 BiaoGe 拍卖协议' Locales/zhCN.lua
rg -q 'Supports the standard BiaoGe auction protocol' Locales/enUS.lua
rg -q '支援常規 BiaoGe 拍賣協議' Locales/zhTW.lua
rg -q 'L\["总欠款："\] = true' Locales/zhCN.lua
rg -q 'L\["总欠款："\] = "Total amount owed:"' Locales/enUS.lua
rg -q 'L\["总欠款："\] = "總欠款："' Locales/zhTW.lua
if rg -n '自动清空表格时保存表格|进本自动清空表格|当前团队名单暂不可用|自动清空表格的原因' Locales; then
    echo "Removed automatic-clear or roster copy is still localized" >&2
    exit 1
fi

echo "BGLite v1.2 synchronization integration checks passed"

#!/usr/bin/env bash

set -euo pipefail

dialog_module="Core/DB/DB.lua"

rg -Fq 'local conflictingAddons = {}' "$dialog_module"
rg -Fq '{ "BGLite", "BiaoGe" }' "$dialog_module"
rg -Fq 'tinsert(conflictingAddons, addonName)' "$dialog_module"
rg -Fq "local frameName = 'BGForgeConflictError'" "$dialog_module"
rg -Fq 'button2 = L["暂不处理"]' "$dialog_module"
rg -Fq 'C_AddOns.DisableAddOn(addonName)' "$dialog_module"
rg -Fq 'ReloadUI()' "$dialog_module"
rg -Fq 'hideOnEscape = true' "$dialog_module"

if rg -Fq 'enterClicksFirstButton = true' "$dialog_module"; then
    echo "Conflict dialog must not disable addons on an accidental Enter press" >&2
    exit 1
fi

for locale in Locales/zhCN.lua Locales/zhTW.lua Locales/enUS.lua; do
    rg -Fq '检测到 %s 与 BGForge 同时启用。它们会争用相同的全局变量、界面对象和存档变量，可能导致界面错乱、功能失效或账本数据混乱。建议禁用冲突插件并立即重载界面。' "$locale"
    rg -Fq '暂时禁用 %s 并重载' "$locale"
    rg -Fq '暂时禁用冲突插件并重载' "$locale"
    rg -Fq '暂不处理' "$locale"
done

echo "Addon conflict dialog integration checks passed"

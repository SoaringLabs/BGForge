#!/usr/bin/env bash

set -euo pipefail

module="Core/Module/CharacterDetails.lua"
overview="Core/Module/RaidLockoutOverview.lua"

rg -Fq 'Core\Module\CharacterDetails.lua' BGForge.toc
rg -Fq 'function M.Show(parent, realmID, characterName, onBack)' "$module"
rg -Fq 'function M.Refresh()' "$module"
rg -Fq 'function M.Hide(suppressBack)' "$module"
rg -Fq 'BG.CharacterDetails.Show(parent, GetCurrentRealmID(), character.name' "$overview"
rg -Fq 'detailsHint:SetText(L["提示：点击角色名称可查看装备和背包"])' "$overview"
rg -Fq 'detailsHint:SetPoint("LEFT", title, "RIGHT", 18, 0)' "$overview"
rg -Fq 'detailsHint:SetPoint("RIGHT", resetText, "LEFT", -12, 0)' "$overview"
rg -Fq 'chrome.detailsHint:Show()' "$overview"
rg -Fq 'chrome.detailsHint:Hide()' "$overview"
rg -Fq 'ScheduleEquipmentRefresh(0.2)' "$overview"
rg -Fq 'for slotID = 1, 19 do' "$overview"
rg -Fq 'schemaVersion = CHARACTER_DETAILS_VERSION' "$overview"

if rg -q 'UI\.SetState\(row,.*"selected"' "$module"; then
    echo "Character list rows must not request the unsupported secondary selected state" >&2
    exit 1
fi
rg -Fq 'UI.SetState(row, "default")' "$module"
rg -Fq 'local specIcon = GetCharacterSpecIcon(character)' "$module"
rg -Fq 'row.selectedBackground:SetShown(selected)' "$module"
rg -Fq 'row.selectedAccent:SetShown(selected)' "$module"
rg -Fq 'UI-SpellbookIcon-PrevPage-Up' "$module"
rg -Fq 'backDivider:SetPoint("LEFT", back, "RIGHT", 12, 0)' "$module"
rg -Fq 'button.level:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")' "$module"
rg -Fq 'button.level:SetTextColor(color.r, color.g, color.b, 1)' "$module"
rg -Fq 'local PAPER_DOLL_WIDTH = 420' "$module"
rg -Fq 'paperDoll:SetWidth(PAPER_DOLL_WIDTH)' "$module"
rg -Fq 'frame.paperDollName = CreateText(paperDoll, "heading")' "$module"
rg -Fq 'frame.paperDollName:SetTextColor(1, 1, 1, 1)' "$module"
rg -Fq 'frame.paperDollName:SetText(character.name)' "$module"
rg -Fq 'frame.paperDollMeta = CreateText(paperDoll, "body")' "$module"
rg -Fq 'local PAPER_DOLL_SLOT_TOP = 64' "$module"
rg -Fq 'local function EnsureBackpackView()' "$module"
rg -Fq 'local function RenderBackpack(character)' "$module"
rg -Fq 'SetActiveView("backpack")' "$module"
rg -Fq 'frame.backpackItemButtons' "$module"
rg -Fq 'button.level:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")' "$module"
rg -Fq 'item.itemLevel and floor(item.itemLevel + 0.5)' "$module"
rg -Fq 'button.level:SetTextColor(color.r, color.g, color.b, 1)' "$module"
rg -Fq 'local function GetItemDisplayColor(link)' "$module"
rg -Fq 'link:match("|c%x%x(%x%x)(%x%x)(%x%x)")' "$module"
rg -Fq 'local CHARACTER_ROW_HEIGHT = 56' "$module"
rg -Fq 'local CHARACTER_ROW_STRIDE = 58' "$module"
rg -Fq 'local MAX_CHARACTER_ROWS = 10' "$module"
rg -Fq 'row.icon:SetSize(28, 28)' "$module"
rg -Fq 'row.textGroup = CreateFrame("Frame", nil, row)' "$module"
rg -Fq 'row.textGroup:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)' "$module"
rg -Fq 'row.textGroup:SetHeight(40)' "$module"
rg -Fq 'row.name = CreateText(row.textGroup, "body")' "$module"
rg -Fq 'row.updatedAt = CreateText(row.textGroup, "caption")' "$module"
rg -Fq 'local function GetCharacterUpdatedAt(character)' "$module"
rg -Fq 'row.itemLevel = CreateText(row, "number")' "$module"
rg -Fq 'SetTextColor(row.itemLevel, "forgeGold")' "$module"

for locale in Locales/zhCN.lua Locales/zhTW.lua Locales/enUS.lua; do
    rg -Fq 'L["提示：点击角色名称可查看装备和背包"]' "$locale"
done

if rg -q 'frame\.classIcon|SetClassIcon\(' "$module"; then
    echo "Character details must not render the redundant center class icon" >&2
    exit 1
fi

if rg -q 'OnUpdate|SendAddonMessage|SendCommMessage|UnitGUID|GetRaidRosterInfo|GetGuildRosterInfo|BiaoGeAccounts|BGAI' "$module"; then
    echo "Character details introduced continuous work, synchronization, or other-player data" >&2
    exit 1
fi

if rg -q 'BANK_CONTAINER|NUM_BANKBAGSLOTS|MAIL|GetContainerNumSlots|GetContainerItemInfo' "$module"; then
    echo "Character details UI crossed the approved snapshot-only boundary" >&2
    exit 1
fi

rg -Fq 'ScheduleBackpackRefresh(0.3)' "$overview"
rg -Fq 'function BG.RefreshCurrentCharacterBackpack()' "$overview"
if rg -q 'details\.backpack.*BANK_CONTAINER|details\.backpack.*MAIL' "$overview"; then
    echo "Backpack details must not collect bank or mail contents" >&2
    exit 1
fi

if [[ "$(rg -c 'PLAYER_EQUIPMENT_CHANGED' "$overview")" -ne 1 ]] \
    || rg -Uq '"CURRENCY_DISPLAY_UPDATE",\n[[:space:]]+"PLAYER_EQUIPMENT_CHANGED"' "$overview"; then
    echo "Equipment changes must not be wired back into the broad resource scan" >&2
    exit 1
fi

echo "Character details navigation, performance, and privacy integration tests passed"

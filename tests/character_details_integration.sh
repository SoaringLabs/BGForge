#!/usr/bin/env bash

set -euo pipefail

module="Core/Module/CharacterDetails.lua"
overview="Core/Module/RaidLockoutOverview.lua"

rg -Fq '## Version: 1.4.2' BGForge.toc
rg -Fq '当前版本：`1.4.2`' README.md
rg -Fq 'Core\Module\CharacterDetails.lua' BGForge.toc
rg -Fq 'function M.Show(parent, realmID, characterName, onBack)' "$module"
rg -Fq 'function M.Refresh()' "$module"
rg -Fq 'function M.Hide(suppressBack)' "$module"
rg -Fq 'BG.CharacterDetails.Show(parent, GetCurrentRealmID(), character.name' "$overview"
rg -Fq 'local pageHeader = BG.UI.CreatePageHeader(hoverFrame, {' "$overview"
rg -Fq 'subtitle = L["提示：点击角色名称可查看装备和背包"]' "$overview"
rg -Fq 'chrome.topBar:Hide()' "$overview"
rg -Fq 'chrome.pageHeader:Show()' "$overview"
rg -Fq 'local verticalScrollBar = CreateFrame("Slider", nil, hoverFrame)' "$overview"
rg -Fq 'calculateVerticalViewport = CalculateVerticalViewport' "$overview"
rg -Fq 'verticalScrollBar:SetPoint("TOPRIGHT", contentScroll, "TOPRIGHT", -2, 0)' "$overview"
rg -Fq 'if verticalScrollBar:IsShown() and not (IsShiftKeyDown and IsShiftKeyDown()) then' "$overview"
rg -Fq 'resetVerticalScroll = function()' "$overview"
rg -Fq 'local CHARACTER_DETAILS_CHEVRON_TEXTURE = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"' "$overview"
rg -Fq 'local CHARACTER_DETAILS_CHEVRON_SIZE = 16' "$overview"
rg -Fq 'row.raidChevron:SetTexture(CHARACTER_DETAILS_CHEVRON_TEXTURE)' "$overview"
rg -Fq 'row.resourceChevron:SetTexture(CHARACTER_DETAILS_CHEVRON_TEXTURE)' "$overview"
rg -Fq 'local function CreateCharacterNameButton(rowController, identityOverlay, navigationIndicator)' "$overview"
rg -Fq 'row.raidHover:SetSize(nameWidth + lockoutsWidth, raidRowHeight)' "$overview"
rg -Fq 'row.resourceHover:SetSize(resourceWidth, resourceRowHeight)' "$overview"
rg -Fq 'SetRowHoverVisible(self.rowController, false)' "$overview"
rg -Fq 'self.identityOverlay:SetAlpha(self.rowController.isCurrent and 0 or 1)' "$overview"
rg -Fq 'row.raidChevron:SetShown(hoverEmbedded)' "$overview"
rg -Fq 'row.resourceChevron:SetShown(hoverEmbedded)' "$overview"
rg -Fq 'BG.MainFrame:Show()' "$overview"
rg -Fq 'BG.ClickTabButton(BG.RaidLockoutMainFrameTabNum)' "$overview"
rg -Fq 'tile.rowHoverController = cell.rowHoverController' "$overview"
if rg -q 'row\.(raid|resource)Hover:SetSize\(hoverEmbedded and nameWidth' "$overview"; then
    echo "Embedded character overview row hover must cover the complete row" >&2
    exit 1
fi
if rg -Fq 'if mouseButton == "LeftButton" and hoverEmbedded then' "$overview"; then
    echo "Small character overview names must remain clickable" >&2
    exit 1
fi
if rg -Fq 'SetText("›")' "$overview"; then
    echo "Character overview navigation indicators must not depend on a font glyph" >&2
    exit 1
fi
if rg -q 'chrome\.refresh:' "$overview"; then
    echo "Embedded character overview must not keep the redundant manual refresh control" >&2
    exit 1
fi
rg -Fq 'ScheduleEquipmentRefresh(0.2)' "$overview"
rg -Fq 'for slotID = 1, 19 do' "$overview"
rg -Fq 'schemaVersion = CHARACTER_DETAILS_VERSION' "$overview"

if rg -q 'UI\.SetState\(row,.*"selected"' "$module"; then
    echo "Character list rows must not request the unsupported secondary selected state" >&2
    exit 1
fi
rg -Fq 'local specIcon = GetCharacterSpecIcon(character)' "$module"
rg -Fq 'row.selectedBackground:SetShown(selected)' "$module"
rg -Fq 'row.selectedAccent:SetShown(selected)' "$module"
rg -Fq 'UI-SpellbookIcon-PrevPage-Up' "$module"
rg -Fq 'local leftHeader = CreateSurface(frame, "header")' "$module"
rg -Fq 'leftHeader:SetHeight(54)' "$module"
if [[ "$(rg -Fc 'SetBackdropBorderColor(0, 0, 0, 0)' "$module")" -lt 3 ]]; then
    echo "Character rows and adjacent detail headers must suppress duplicate backdrop borders" >&2
    exit 1
fi
rg -Fq 'header.accent:SetPoint("BOTTOMLEFT", 0, 1)' "$module"
rg -Fq 'header.accent:SetWidth(3)' "$module"
rg -Fq 'header.accent:SetColorTexture(unpack(Token("focus")))' "$module"
rg -Fq 'back:SetPoint("LEFT", 12, 0)' "$module"
rg -Fq 'left:SetPoint("TOPLEFT", leftHeader, "BOTTOMLEFT", 0, 0)' "$module"
rg -Fq 'frame.updatedAt:SetPoint("TOPLEFT", 80, -58)' "$module"
rg -Fq 'frame.updatedAt:SetJustifyH("LEFT")' "$module"
rg -Fq 'button.level:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")' "$module"
rg -Fq 'button.level:SetTextColor(color.r, color.g, color.b, 1)' "$module"
rg -Fq 'local PAPER_DOLL_PANEL_INSET = 8' "$module"
rg -Fq 'local PAPER_DOLL_SLOT_SIZE = 44' "$module"
rg -Fq 'local PAPER_DOLL_DETAIL_WIDTH = 520' "$module"
rg -Fq 'local PAPER_DOLL_SIDE_WIDTH = 48' "$module"
rg -Fq 'local PAPER_DOLL_SIDE_HEIGHT = 48' "$module"
rg -Fq 'local PAPER_DOLL_SIDE_STRIDE = 58' "$module"
rg -Fq 'local PAPER_DOLL_BOTTOM_WIDTH = 104' "$module"
rg -Fq 'local PAPER_DOLL_BOTTOM_HEIGHT = 72' "$module"
rg -Fq 'local EQUIPMENT_DETAIL_ROW_HEIGHT = 32' "$module"
rg -Fq 'local paperDoll = CreateSurface(right, "panel")' "$module"
if rg -Fq 'local paperDoll = CreateSurface(right, "raised")' "$module"; then
    echo "Equipment must share Today's dark panel surface instead of using the brighter raised role" >&2
    exit 1
fi
rg -Fq 'paperDoll:SetPoint("BOTTOMRIGHT", -PAPER_DOLL_PANEL_INSET, PAPER_DOLL_PANEL_INSET)' "$module"
rg -Fq 'equipmentDetail:SetWidth(PAPER_DOLL_DETAIL_WIDTH)' "$module"
rg -Fq 'paperDollStage:SetPoint("TOPRIGHT", equipmentDetail, "TOPLEFT", -PAPER_DOLL_COLUMN_GAP, 0)' "$module"
rg -Fq 'frame.equipmentDetailDivider:SetWidth(1)' "$module"
rg -Fq 'frame.paperDollSlotGroups = {}' "$module"
rg -Fq 'CreatePaperDollSlot(paperDollStage, definition, definition.index, "side")' "$module"
rg -Fq 'CreatePaperDollSlot(paperDollStage, definition, definition.index, "bottom")' "$module"
rg -Fq 'frame.paperDollWatermark:SetAlpha(0.055)' "$module"
rg -Fq 'frame.inspectorIcon = CreateItemButton(paperDollStage, PAPER_DOLL_INSPECTOR_ICON_SIZE)' "$module"
rg -Fq 'SetPaperDollInspector(definition, item)' "$module"
rg -Fq 'frame.equipmentDetailTitle = CreateText(detailHeader, "heading", Text("装备明细"))' "$module"
rg -Fq 'frame.equipmentDetailRows = {}' "$module"
rg -Fq 'SetEquipmentDetailRow(row, item, row.slotIndex == selectedEquipmentSlot)' "$module"
if rg -q 'frame\.(tablePanel|equipmentInspector|equipmentRows)' "$module"; then
    echo "Equipment must remain one paper-doll surface without the legacy table or inspector card" >&2
    exit 1
fi
rg -Fq 'local function EnsureBackpackView()' "$module"
rg -Fq 'local function RenderBackpack(character)' "$module"
rg -Fq 'SetActiveView("backpack")' "$module"
rg -Fq 'local function CreateDetailTab(parent, text)' "$module"
rg -Fq 'SetDetailTabState(frame.todayTab, activeView == "today")' "$module"
rg -Fq 'tab.line:SetShown(tab.selected)' "$module"
if rg -Fq 'CreateTab(tabs, L["今日"]' "$module"; then
    echo "Character detail tabs must use text plus an underline, not the legacy filled tab" >&2
    exit 1
fi
rg -Fq 'local function EnsureTodayView()' "$module"
rg -Fq 'local TODAY_LEFT_COLUMN_RATIO = 0.252' "$module"
rg -Fq 'local TODAY_RAID_COLUMN_RATIO = 0.396' "$module"
rg -Fq 'local TODAY_COLUMN_GAP = 8' "$module"
rg -Fq 'local function CreateTodayColumn(parent, title)' "$module"
rg -Fq 'local actions = CreateTodayColumn(panel, Text("今日任务"))' "$module"
rg -Fq 'local raid = CreateTodayColumn(panel, Text("团队副本"))' "$module"
rg -Fq 'local operations = CreateTodayColumn(panel, Text("资源与快捷入口"))' "$module"
rg -Fq 'panel.operationsColumn.meta:SetText("")' "$module"
if rg -Fq 'panel.operationsColumn.meta:SetText(resourceUpdatedAt' "$module"; then
    echo "The mixed resource and shortcut lane must not show a misleading resource timestamp" >&2
    exit 1
fi
rg -Fq 'raid:SetPoint("TOPLEFT", actions, "TOPRIGHT", TODAY_COLUMN_GAP, 0)' "$module"
rg -Fq 'operations:SetPoint("TOPLEFT", raid, "TOPRIGHT", TODAY_COLUMN_GAP, 0)' "$module"
rg -Fq 'panel.dailySection = CreateTodaySection(actions, Text("专业日常"), "heading")' "$module"
rg -Fq 'summary.divider:SetPoint("BOTTOMLEFT", -12, 0)' "$module"
rg -Fq 'summary.divider:SetPoint("BOTTOMRIGHT", 12, 0)' "$module"
rg -Fq 'panel.weeklySection = CreateTodaySection(actions, Text("周常任务"), "heading")' "$module"
rg -Fq 'summary.weekly:Hide()' "$module"
rg -Fq 'panel.dailySection.meta:SetFormattedText("%d/%d", dailyCompletedCount, dailyEligibleCount)' "$module"
if rg -Fq 'panel.todaySummary.weekly:SetFormattedText' "$module"; then
    echo "The Today summary must not repeat only the weekly breakdown" >&2
    exit 1
fi
rg -Fq 'panel.resourceSection = CreateTodaySection(operations, Text("资源总览"))' "$module"
rg -Fq 'panel.professionSection = CreateTodaySection(operations, Text("专业技能"))' "$module"
rg -Fq 'panel.quickSection = CreateTodaySection(operations, Text("快速查看"))' "$module"
rg -Fq 'local section = CreateFrame("Frame", nil, parent)' "$module"
rg -Fq 'panel.weeklySection:SetPoint("TOPLEFT", panel.dailySection, "BOTTOMLEFT", 0, 0)' "$module"
rg -Fq 'panel.professionSection:SetPoint("TOPLEFT", panel.resourceSection, "BOTTOMLEFT", 0, 0)' "$module"
rg -Fq 'panel.quickSection:SetPoint("TOPLEFT", panel.professionSection, "BOTTOMLEFT", 0, 0)' "$module"
rg -Fq 'row:SetBackdropBorderColor(0, 0, 0, 0)' "$module"
rg -Fq 'row.divider:SetPoint("BOTTOMRIGHT", 0, 0)' "$module"
rg -Fq 'row.divider:SetShown(index < #DAILY_DEFINITIONS)' "$module"
rg -Fq 'panel.raidCompletedLabel = CreateText(raid, "heading", Text("已有进度"))' "$module"
rg -Fq 'panel.raidPendingLabel = CreateText(raid, "heading", Text("尚未开始"))' "$module"
rg -Fq 'column.header:SetHeight(TODAY_COLUMN_TITLE_HEIGHT)' "$module"
rg -Fq 'column.title:SetPoint("LEFT", 12, 0)' "$module"
rg -Fq 'column.title:SetJustifyV("MIDDLE")' "$module"
rg -Fq 'row.weeklyStatusIcon:SetSize(18, 18)' "$module"
rg -Fq 'SetTodayRow(row, WAITING_STATUS_TEXTURE, entry.name, Text("每周重置")' "$module"
rg -Fq 'local function SetTodayUnavailableRow(row, definition, detail, status)' "$module"
rg -Fq 'row.iconButton.icon:SetDesaturated(true)' "$module"
rg -Fq 'row.iconButton:SetAlpha(0.45)' "$module"
rg -Fq 'format(L["未学习%s"], definition.professionName or definition.name)' "$module"
rg -Fq 'L["暂不可做"]' "$module"
if rg -Fq 'L["每日事项已完成"]' "$module"; then
    echo "Today must keep the fixed three-row profession catalog instead of synthesizing a placeholder" >&2
    exit 1
fi
if rg -q 'WEEKLY_QUEST_TEXTURE|AvailableQuestIcon|dailyNote' "$module"; then
    echo "Today must hide inapplicable-daily footnotes and share weekly/raid status artwork" >&2
    exit 1
fi
rg -Fq 'row.name:SetPoint("TOPRIGHT", row.status, "TOPLEFT", -8, -1)' "$module"
rg -Fq 'UI.Style(group, "surface", { role = "raised" })' "$module"
rg -Fq 'group.hoverAccent:SetWidth(2)' "$module"
rg -Fq 'local function SetTodayPreviewHover(group, hovered)' "$module"
rg -Fq 'button:HookScript("OnEnter", function() SetTodayPreviewHover(group, true) end)' "$module"
rg -Fq 'local TODAY_RAID_PROGRESS_WIDTH = 170' "$module"
rg -Fq 'local TODAY_RESOURCE_DETAIL_GAP = 4' "$module"
rg -Fq 'local TODAY_RAID_ROW_HEIGHT = 40' "$module"
rg -Fq 'local function CreateTodayRaidRow(parent)' "$module"
rg -Fq 'local function SetTodayRaidRow(row, entry)' "$module"
rg -Fq 'local groupBoundary = completed and completedIndex == completedCount' "$module"
rg -Fq 'row.divider:SetPoint("BOTTOMLEFT", groupBoundary and 2 or 12, 0)' "$module"
rg -Fq 'local visibleProfessionCount = min(#tracks, #panel.professionRows)' "$module"
rg -Fq 'row.divider:SetShown(index < visibleProfessionCount)' "$module"
rg -Fq 'local segmentWidth = segmentCount > 0' "$module"
rg -Fq 'killed = boss.killed and true or false' "$module"
if rg -Fq 'local killed = boss and boss.killed or index <= representedKills' "$module"; then
    echo "False per-boss states must not fall through to aggregate progress" >&2
    exit 1
fi
rg -Fq 'panel:SetHeight(max(panel.requiredHeight or TODAY_PANEL_MIN_HEIGHT, height))' "$module"
rg -Fq 'row.kills:SetText(encounterCount > 0 and format("%d/%d", killedCount, encounterCount) or "—")' "$module"
if rg -q 'raidSubheading|本周尚无首领击杀' "$module"; then
    echo "Today raid progress must keep every raid row instead of collapsing completed raids into text" >&2
    exit 1
fi
rg -Fq '(tonumber(lockout.killedCount) or 0) > 0' "$module"
if rg -q 'todayPanel\.(progress|resources|professions|bag)' "$module"; then
    echo "Today view must render semantic modules instead of concatenated text blocks" >&2
    exit 1
fi
rg -Fq 'local function GetDailyApplicability(character, definition, learnedSkillLines)' "$module"
rg -Fq 'local tabLabels = { L["装备"], L["背包"] }' "$module"
if rg -q 'professionResources|EnsureProfessionResourcesView|RenderProfessionResources|professionResourcesPanel|professionDailyCards|professionTracks|resourceStrip' "$module"; then
    echo "The removed Professions & Resources page must not leave UI or navigation code behind" >&2
    exit 1
fi
if rg -q 'SetActiveView\("progress"\)|EnsureProgressView|RenderProgress|progressPanel|progressRaidRows|progressBossPanel|progressScroll|selectedProgressRaidID|progressSelectionCharacterName|PROGRESS_RAID_ROW_HEIGHT|PROGRESS_BOSS_ROW_HEIGHT|PROGRESS_HEADER_HEIGHT|PROGRESS_WEEKLY_HEIGHT|PROGRESS_MAX_SEGMENTS|PROGRESS_STATUS_TEXTURE' "$module"; then
    echo "The removed Progress page must not leave UI or navigation code behind" >&2
    exit 1
fi
rg -Fq 'dailyProfessionSkills = type(stored.dailyProfessionSkills) == "table"' "$overview"
rg -Fq 'stored.dailyProfessionSkills = dailyProfessionSkills' "$overview"
rg -Fq 'minLevel = 65, minRank = 350' "$module"
rg -Fq 'minLevel = 70, minRank = 1' "$module"
rg -Fq 'BG.GetRaidLockoutProgressModel(character, now)' "$module"
rg -Fq 'function BG.GetRaidLockoutProgressModel(character, now)' "$overview"
rg -Fq 'panel.raidSection.meta:SetFormattedText(L["副本 %d/%d"],' "$module"
rg -Fq 'bosses = GetRaidBossRoster(raid)' "$overview"
rg -Fq 'EJ_GetEncounterInfoByIndex' "$overview"
rg -Fq 'local function GetPrimaryProgressLockout(entry)' "$module"
rg -Fq 'local function GetProgressBosses(entry)' "$module"
rg -Fq 'local function SetProgressSegment(segment, completed)' "$module"
rg -Fq 'local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")' "$module"
rg -Fq 'entry.completed and "success" or "warning", nil)' "$module"
rg -Fq 'function BG.GetRaidLockoutProfessionTracks(character, now)' "$overview"
rg -Fq 'character.titanEmbersEarnedThisWeek' "$overview"
rg -Fq 'character.titanEmbersWeeklyMax' "$overview"
rg -Fq 'text:SetFont(BIAOGE_TEXT_FONT, RESOURCE_NUMBER_FONT_SIZE, "OUTLINE")' "$overview"
if rg -Fq 'RobotoCondensed-Medium.ttf' "$overview"; then
    echo "Character overview common resources must use the selected game font" >&2
    exit 1
fi
rg -Fq 'character.titanEmberIconFileID' "$module"
rg -Fq 'local function FormatWeeklyResourceDetail(earned, maximum)' "$module"
rg -Fq 'return format("（%s/%s）", FormatCompactNumber(earned), FormatCompactNumber(maximum))' "$module"
rg -Fq 'character.titanEmbersEarnedThisWeek' "$module"
rg -Fq 'character.titanEmbersWeeklyMax' "$module"
rg -Fq 'row.detail:SetPoint("RIGHT", row.value, "RIGHT",' "$module"
rg -Fq 'and (emberCapped and "danger" or "success") or "textMuted")' "$module"
rg -Fq 'row.detail = CreateText(row, "number")' "$module"
rg -Fq 'upgrades[1] and upgrades[1].iconFileID or UNKNOWN_SPEC_TEXTURE' "$module"
rg -Fq 'Interface\\MoneyFrame\\UI-GoldIcon' "$module"
rg -Fq 'local GOLD_ATLAS = "auctionhouse-icon-coin-gold"' "$module"
rg -Fq 'character.money and FormatCompactNumber(floor(character.money / 10000)) or "—"' "$module"
if rg -Fq 'FormatCompactNumber(floor(money / 10000)) .. L["金"]' "$module"; then
    echo "Gold resource value must not append a Chinese unit to the numeric font" >&2
    exit 1
fi
if rg -q 'generated_images|codex-clipboard|Media/.*profession|Media/.*resource' "$module"; then
    echo "Profession/resource view must use game-client icons, not mock artwork" >&2
    exit 1
fi
rg -Fq 'frame.backpackItemButtons' "$module"
rg -Fq 'local BACKPACK_ITEM_SIZE = 35' "$module"
rg -Fq 'CreateItemButton(frame.backpackContent, BACKPACK_ITEM_SIZE, 1)' "$module"
rg -Fq 'frame.backpackHeader = header' "$module"
rg -Fq 'local tab = CreateDetailTab(panel, Text(entry[2]))' "$module"
rg -Fq 'SetDetailTabState(tab, key == backpackFilter)' "$module"
rg -Fq 'frame.backpackInfoDivider:SetWidth(1)' "$module"
rg -Fq 'groupHeader = CreateFrame("Frame", nil, frame.backpackContent)' "$module"
if rg -Uq 'local function EnsureBackpackView\(\).*local tab = CreateTab\(panel' "$module"; then
    echo "Backpack filters must not return to bordered block tabs" >&2
    exit 1
fi
if [[ "$(rg -Fc 'button.level:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")' "$module")" -ne 2 ]]; then
    echo "Backpack icon badges must scale down with the 35-unit item tiles" >&2
    exit 1
fi
rg -Fq 'item.itemLevel and floor(item.itemLevel + 0.5)' "$module"
rg -Fq 'button.level:SetTextColor(color.r, color.g, color.b, 1)' "$module"
rg -Fq 'local function GetItemDisplayColor(link)' "$module"
rg -Fq 'link:match("|c%x%x(%x%x)(%x%x)(%x%x)")' "$module"
rg -Fq 'local CHARACTER_ROW_HEIGHT = 56' "$module"
rg -Fq 'local CHARACTER_ROW_STRIDE = CHARACTER_ROW_HEIGHT' "$module"
rg -Fq 'local MAX_CHARACTER_ROWS = 10' "$module"
rg -Fq 'row:SetBackdropBorderColor(0, 0, 0, 0)' "$module"
rg -Fq 'row.divider:SetPoint("BOTTOMRIGHT", 0, 0)' "$module"
rg -Fq 'UI.SetBackgroundAlphaColor(self, "hover")' "$module"
rg -Fq 'UI.SetBackgroundAlphaColor(self, "row")' "$module"
rg -Fq 'UI.BindBackgroundAlpha(surface, "SetBackdropColor", role)' "$module"
rg -Fq 'UI.BindBackgroundAlpha(frame, "SetBackdropColor", "canvas")' "$module"
if rg -Uq 'local function CreateCharacterRow.*UI\.Create\("button"' "$module"; then
    echo "Character rows must not inherit the bordered button hover treatment" >&2
    exit 1
fi
rg -Fq 'row.icon:SetSize(28, 28)' "$module"
rg -Fq 'row.textGroup = CreateFrame("Frame", nil, row)' "$module"
rg -Fq 'row.textGroup:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)' "$module"
rg -Fq 'row.textGroup:SetHeight(40)' "$module"
rg -Fq 'row.name = CreateText(row.textGroup, "body")' "$module"
rg -Fq 'row.updatedAt = CreateText(row.textGroup, "caption")' "$module"
rg -Fq 'local function GetCharacterUpdatedAt(character)' "$module"
rg -Fq 'renderedCharacters = characters' "$module"
rg -Fq 'RenderCharacterList(characters)' "$module"
if rg -Uq 'left:SetScript\("OnMouseWheel".*M\.Refresh\(\)' "$module"; then
    echo "Character-list scrolling must not rebuild the selected detail view" >&2
    exit 1
fi
rg -Fq 'row.itemLevel = CreateText(row, "numberCompact")' "$module"
rg -Fq 'SetTextColor(row.itemLevel, "forgeGold")' "$module"

for locale in Locales/zhCN.lua Locales/zhTW.lua Locales/enUS.lua; do
    rg -Fq 'L["提示：点击角色名称可查看装备和背包"]' "$locale"
    rg -Fq 'L["资源总览"]' "$locale"
    rg -Fq 'L["打开%s窗口刷新"]' "$locale"
    rg -Fq 'L["珠宝日常"]' "$locale"
    rg -Fq 'L["烹饪日常"]' "$locale"
    rg -Fq 'L["钓鱼日常"]' "$locale"
    rg -Fq 'L["未学习"]' "$locale"
    rg -Fq 'L["未学习%s"]' "$locale"
    rg -Fq 'L["暂不可做"]' "$locale"
    rg -Fq 'L["资格尚未记录"]' "$locale"
    rg -Fq 'L["技能需达到 %d"]' "$locale"
    rg -Fq 'L["传说级升级材料"]' "$locale"
    rg -Fq 'L["未开始"]' "$locale"
    rg -Fq 'L["副本 %d/%d"]' "$locale"
    rg -Fq 'L["待完成"]' "$locale"
    rg -Fq 'L["周常任务"]' "$locale"
    rg -Fq 'L["团队副本进度"]' "$locale"
    rg -Fq 'L["快速查看"]' "$locale"
    rg -Fq 'L["查看装备"]' "$locale"
    rg -Fq 'L["查看背包"]' "$locale"
    rg -Fq 'L["今日任务"]' "$locale"
    rg -Fq 'L["每日任务"]' "$locale"
    rg -Fq 'L["项待完成"]' "$locale"
    rg -Fq 'L["团队副本"]' "$locale"
    rg -Fq 'L["已有进度"]' "$locale"
    rg -Fq 'L["尚未开始"]' "$locale"
    rg -Fq 'L["资源与快捷入口"]' "$locale"
    if rg -q '本周进度|首领进度|暂无首领数据|副本 %d/%d · 周常 %d/%d|统一重置 %s|专业与资源、进度' "$locale"; then
        echo "Removed detail pages must not keep page-only locale strings" >&2
        exit 1
    fi
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

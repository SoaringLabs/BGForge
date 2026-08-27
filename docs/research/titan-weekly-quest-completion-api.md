# Titan Reforged Classic：当前角色周常完成状态 API

调研日期：2026-08-28  
核对客户端：Titan Reforged Classic 3.80.2（build 69496；UI source commit `ba472e5e1b5580b557e3dbf02c9e5ff23b223347`）

## 结论

**有条件可做。** 周常每周换 questID 并不要求在运行时预先知道“本周那一个 ID”：若插件知道该业务周常的**完整候选 ID 池**，登录时对池内每个 ID 查完成旗标即可；若任务已在日志中，也可从日志的 `frequency == Enum.QuestFrequency.Weekly` 自动发现当周 ID。

但 Titan 没有“枚举本周已交付的所有周常”接口。如果插件首次运行时任务已经交付，又既不知道 ID 池、也没有事前收到接取/交付事件，官方 AddOn API **无法从历史中反推该 questID**。此时正确状态是 `unknown`，不是“未完成”。

已知任一候选 questID 后，插件可以查询当前登录角色的服务器完成旗标：

```lua
local isDone = C_QuestLog.IsQuestFlaggedCompleted(questID)
```

Titan 客户端导出的 API 文档明确提供 `C_QuestLog.IsQuestFlaggedCompleted(questID) -> isCompleted`；函数没有角色参数，因此读取的是当前登录角色。[Titan `QuestLogDocumentation.lua` 98–110](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L98-L110)

对于完成旗标确实按周清除的可重复任务，这个布尔值可以用作“当前角色本周是否已经交付”。但接口只返回布尔值，不返回完成时间、完成周次或旗标的重置规则，所以不能把任意 questID 的 `true` 无条件解释为“本周完成”。必须先确认具体任务的 ID，以及它实际使用的是每周旗标、轮换任务池还是隐藏 tracking quest。

## 本地 BiaoGe 源码核对

### 结论：原版已经实现，采用静态候选池

本地原版 BiaoGe 确实有这项能力，而且核心做法就是“一个 UI 周常槽位对应一组可能轮换的 questID，池内任一任务已交付即认为该槽位本周完成”。Titan 3.8 客户端同时被归类为 `BG.IsWLK` 和 `BG.IsTitan`，所以会进入 WLK 共用的任务池逻辑：[BiaoGe `Init.lua`:164](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua:164)。

当前源码定义两个槽位：[BiaoGe `RoleOverview.lua`:1473](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1473)

- `week1`：`24579`–`24590`，以及标注为“时光服”的 `93975 / 94577 / 94579 / 95037 / 96312`。
- `week2`：标注为“祖格宝石周常”的 `98183`。

源码没有在运行时枚举任务日志、Gossip 或任务提供者，也不按任务名识别本周轮换。新增轮换任务需要发布代码补充 ID；更新日志中的“现在会识别新周常”和“更新 P5 周常任务”也印证了这是一份人工维护的内容表：[BiaoGe `更新日志.txt`:280](/Users/liushuxiang/Desktop/Personal/BiaoGe/更新日志.txt:280)、[BiaoGe `更新日志.txt`:17](/Users/liushuxiang/Desktop/Personal/BiaoGe/更新日志.txt:17)。

### 完整数据流

1. **初始化存档。** 数据存进账号级 SavedVariable `BiaoGe`；结构为 `BiaoGe.QuestCD[realmID][player][slotKey]`：[BiaoGe `BiaoGe.toc`:7](/Users/liushuxiang/Desktop/Personal/BiaoGe/BiaoGe.toc:7)、[BiaoGe `RoleOverview.lua`:1373](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1373)。完成记录包含 `name`、`player`、`colorplayer`、命中的 `questID`、剩余秒数 `resettime` 和绝对过期时间 `endtime`；它不保存完成历史或实际交付时间：[BiaoGe `RoleOverview.lua`:1487](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1487)。
2. **实时捕获。** `QUEST_TURNED_IN` 提供 `questID`。代码逐槽位、逐 ID 精确匹配；命中后立即保存该槽位，完全不需要预先知道“本周是哪一个”：[BiaoGe `RoleOverview.lua`:1502](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1502)、[BiaoGe `RoleOverview.lua`:1540](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1540)。
3. **登录补查。** 第一次 `PLAYER_ENTERING_WORLD` 后延迟 3 秒，遍历每个槽位的全部候选 ID，并调用 `C_QuestLog.IsQuestFlaggedCompleted`；任一返回 `true` 就补写记录。这能覆盖插件重载、晚安装或没有观察到交付事件的情况，前提仍是候选池完整：[BiaoGe `Init.lua`:71](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua:71)、[BiaoGe `RoleOverview.lua`:1587](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1587)。
4. **过期与重置。** 保存时用 `BG.GetNextWeekTime()` 计算下一次边界；中国区硬编码为周四 07:00，其他区为周二 07:00。每 60 秒更新 `resettime`，到期就删除该槽位；同一清理函数还会处理可选的 `BiaoGeAccounts.QuestCD`：[BiaoGe `function1.lua`:892](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/function1.lua:892)、[BiaoGe `RoleOverview.lua`:1549](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1549)、[BiaoGe `RoleOverview.lua`:1620](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:1620)。它没有使用 Titan 已提供的 `C_DateAndTime.GetSecondsUntilWeeklyReset()`。
5. **UI 消费。** Titan 角色总览把 `week1` 显示为“周常”、`week2` 显示为“祖格周常”，两项默认勾选；只要对应 `QuestCD` 记录存在就画绿色勾：[BiaoGe `RoleOverview.lua`:143](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:143)、[BiaoGe `RoleOverview.lua`:640](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua:640)、[BiaoGe `RoleOverview_core.lua`:1518](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview_core.lua:1518)。

### 原版实现的边界与失败模式

- 这是**完成记录器**，不是完整状态机。周常没有记录时 UI 留空，无法区分“未完成”“尚未发现”“候选池漏 ID”“API 暂未刷新”；只有专业日常才使用 `notFinish` 画红叉。
- 静态池漏掉新任务就会漏报；源码不会自动学习新 ID。反过来，池中若混入不会按周清除的 tracking quest，登录补查可能持续误报完成。
- 手工按地区、星期和本地 `date()` 固定 07:00，鲁棒性低于官方周重置倒计时。边界变更或地区规则不符时可能提前或延后清空。
- 启动流程先补查完成旗标、再清理旧记录。正常周重置旗标已清除时没有问题；若某候选旗标没有按周清除，补查会用新的 `endtime` 覆盖旧记录，继续显示完成。
- UI 还读取可选全账号聚合库 `BiaoGeAccounts`，并可按账号名、服务器和角色名筛选：[BiaoGe `RoleOverview_core.lua`:34](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview_core.lua:34)、[BiaoGe `RoleOverview_core.lua`:46](/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview_core.lua:46)。当前本地 BiaoGe checkout 不包含该伴生插件，因此只能确认 BiaoGe 会读取和清理其中的 `QuestCD`，不能从现有源码确认这份跨账号数据如何采集、同步或传输。

### 与 BGLite、BGForge 的差异及隐私结论

BGLite 没有保留这套实现：其 TOC 不加载任何 `RoleOverview*.lua`，`BG.RoleOverviewUI` 是空函数，源码还明确注释“角色总览已删除”：[BGLite `BGLite.toc`:21](/Users/liushuxiang/Desktop/Personal/BGLite/BGLite.toc:21)、[BGLite `function2.lua`:116](/Users/liushuxiang/Desktop/Personal/BGLite/Core/function2.lua:116)、[BGLite `BiaoGe.lua`:2032](/Users/liushuxiang/Desktop/Personal/BGLite/Core/BiaoGe.lua:2032)。BGLite 和 BGForge 的 `BG.DeletePlayerData` 中虽然仍残留 `QuestCD` 键名，但这只是删除旧存档的兼容清单，不是任务检测功能：[BGLite `function1.lua`:653](/Users/liushuxiang/Desktop/Personal/BGLite/Core/function1.lua:653)、[BGForge `function1.lua`:653](/Users/liushuxiang/Desktop/Personal/BGForge/Core/function1.lua:653)。当前 BGForge 也没有 `weekQuests`、任务完成 API 或面向周常的交付事件处理。

三者沿用同一个 `SavedVariables: BiaoGe` 名称，因此用户运行过原版后，旧 `BiaoGe.QuestCD` 可能仍惰性留在存档里；BGLite/BGForge 当前既不读取也不更新它，未来新增 schema 时应明确迁移或隔离，不能把旧记录直接当作本周证据。BGLite 的安全清理还明确删除了对其他玩家无消费方的 `guild / raceID / guid / factionGroup` 长期采集，说明恢复功能时必须逐字段重新证明必要性：[BGLite `DB.lua`:717](/Users/liushuxiang/Desktop/Personal/BGLite/Core/DB/DB.lua:717)、[BGLite `DB.lua`:1095](/Users/liushuxiang/Desktop/Personal/BGLite/Core/DB/DB.lua:1095)。

BGForge 新的全角色总览是独立的本机快照实现，并明确限制为本机实际登录过的角色、不发送插件消息、不读取战网账号、GUID、好友、公会或其他设备数据：[BGForge `RaidLockoutOverview.lua`:5](/Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua:5)。若以后恢复周常，**可以复用 BiaoGe 的“可信候选池 + 登录完成旗标补查 + 交付事件”算法，但不应整段移植存档和账号聚合层**。最小数据只需挂在当前本机角色快照下保存 `slotKey / status / questID? / resetAt`；无需冗余保存 `player`、`colorplayer`，也不要接入 `BiaoGeAccounts`。BGLite 对角色总览的删除只给出了“安全清理、移除非基础拍卖功能及风险代码”的整体说明，没有说明该周常子功能被删的具体政策或隐私原因：[BGLite `zhCN.lua`:25](/Users/liushuxiang/Desktop/Personal/BGLite/Locales/zhCN.lua:25)。因此，算法本身可以作为行为参考，但任何跨账号/跨设备恢复都需要另行确认，不能从原版存在就推定允许。

现有 `BGForgeRaidLockouts.nextResetAt` 来自已保存副本中最早的 `GetSavedInstanceInfo` 重置时间，过期逻辑也只清 `character.instances`：[BGForge `RaidLockoutOverview.lua`:981](/Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua:981)、[BGForge `RaidLockoutOverview.lua`:542](/Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua:542)。所以周常状态即使复用当前角色容器，也必须拥有独立的官方周重置 `resetAt/expiresAt`，不能搭团本清理逻辑的便车——那辆车并不到站。

## 未知当周 ID 时能发现什么

### 1. 枚举正在任务日志中的周常

Titan 自带 UI 仍使用全局 `GetNumQuestLogEntries()` 和 `GetQuestLogTitle(index)` 枚举日志。`GetQuestLogTitle` 的第 7、8 个返回值分别是 `frequency` 和 `questID`；当 `frequency == Enum.QuestFrequency.Weekly` 时，官方 UI 把它标记为周常。[Titan `QuestMapFrame.lua` 641–646](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_UIPanels_Game/Wrath/QuestMapFrame.lua#L641-L646)、[718–724](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_UIPanels_Game/Wrath/QuestMapFrame.lua#L718-L724) 生成文档定义 `Weekly = 2`。[Titan `QuestLogDocumentation.lua` 278–292](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L278-L292)

```lua
local function ScanActiveWeeklyQuests(onWeeklyQuest)
    local numEntries = GetNumQuestLogEntries()
    for index = 1, numEntries do
        local _, _, _, isHeader, _, isComplete, frequency, questID =
            GetQuestLogTitle(index)

        if not isHeader
            and questID
            and frequency == Enum.QuestFrequency.Weekly
        then
            onWeeklyQuest(questID, isComplete)
        end
    end
end
```

这只能发现尚未交付、仍在日志中的任务。`isComplete` 表示目标已达成/可交付，不等于已经交付。另外，“它是一个周常”不能证明“它属于 BGForge 要监控的那个周常槽位”；角色可能同时拥有多个无关周常，因此仍需要候选 ID 池或另一个稳定的业务识别条件。

### 2. 在接取和交付当下捕获 ID

`QUEST_ACCEPTED` 载荷是 `questIndex, questId`；`QUEST_TURNED_IN` 载荷是 `questID, xpReward, moneyReward`。两者都能在当下告诉插件轮换到的 questID。[Titan `QuestLogDocumentation.lua` 153–163](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L153-L163)、[226–237](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L226-L237)

但事件不替插件做业务归类：

- `QUEST_ACCEPTED` 本身不含 `frequency`。收到后应重扫任务日志，用 ID 和 `Weekly` 频率归类；不要长期依赖会随日志变化的 `questIndex`。
- `QUEST_TURNED_IN` 也不含 `frequency`。在交付前已经通过候选池、日志扫描或任务提供者对话把 ID 绑定到目标槽位，才能在交付事件中可靠地记为已完成。
- 如果插件当时未加载，这两个事件不会补发。

### 3. 从当前打开的任务提供者对话发现

`GOSSIP_SHOW` 时，`C_GossipInfo.GetAvailableQuests()` 和 `GetActiveQuests()` 返回当前对话 NPC 的任务；每条 `GossipQuestUIInfo` 含 `frequency` 和 `questID`。[Titan `GossipInfoDocumentation.lua` 23–40](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/GossipInfoDocumentation.lua#L23-L40)、[322–339](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/GossipInfoDocumentation.lua#L322-L339) 官方 Gossip UI 也只在对话打开后调用这两个列表。[Titan `GossipFrameShared.lua` 241–274](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_UIPanels_Game/Shared/GossipFrameShared.lua#L241-L274)

因此，若周常有稳定的任务提供者，可以在玩家主动打开该 NPC 时发现当周 ID。这不是全世界扫描；没有交互就没有这份列表，而已经交付的周常通常也不再出现在 `available` 列表。若该 NPC 同时提供多个周常，单看 `Weekly` 仍无法知道哪一个是目标。

### 4. 地图 API 不是通用的轮换周常目录

Titan 有 `C_QuestLog.GetQuestsOnMap(uiMapID)` 和 `C_TaskQuest.GetQuestsOnMap(uiMapID)`，但它们返回地图 POI，生成文档没有承诺“枚举所有可接任务”；共用的 `QuestPOIMapInfo` 仅提供 `questID`、`isQuestStart`、`isDaily` 等字段，没有 `frequency`/`isWeekly`。[Titan `QuestLogDocumentation.lua` 69–83](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L69-L83)、[`QuestTaskInfoDocumentation.lua` 119–133](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestTaskInfoDocumentation.lua#L119-L133)、[`QuestInfoSharedDocumentation.lua` 27–43](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestInfoSharedDocumentation.lua#L27-L43)

Titan 的 `C_QuestLine` 生成文档甚至没有任何可调用函数，不能移植 Retail 的可用任务线枚举逻辑。[Titan `QuestLineInfoDocumentation.lua` 1–16](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua#L1-L16) 所以地图最多只能作为额外观测来源，不能证明任务池已完整发现。

### 5. 交付后无法任意枚举已完成周常

Titan 的 `C_QuestLog` 函数表只有“给定单个 questID 查完成旗标”的 `IsQuestFlaggedCompleted`，没有 `GetAllCompletedQuestIDs`；当前 Titan UI source 也没有受支持的 `GetQuestsCompleted` 定义或用法。[Titan `QuestLogDocumentation.lua` 8–149](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L8-L149)

这导致两个明确的不可恢复场景：

1. 任务已交付后才首次安装/启用插件，且插件不知道完整候选 ID 池：无法找回本周 questID 和完成状态。
2. 插件观测到一个未分类的 `QUEST_TURNED_IN` ID，但交付前没见过它的日志/Gossip 频率，也不在已知任务池中：不能仅凭该事件把它判成目标周常。

## 推荐判断

若一个产品上的“周常”可能轮换多个任务 ID，应维护完整 ID 集合，而不是依赖本地化任务名：

```lua
local WEEKLY_QUEST_IDS = {
    -- 填入已经核实的 questID；轮换任务要全部列出
}

local function GetWeeklyCompletion()
    for _, questID in ipairs(WEEKLY_QUEST_IDS) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            return true, questID
        end
    end
    return false
end
```

`true` 表示该 questID 当前被服务器标记为已完成。`false` 也可能来自错误或无效 questID；Warcraft Wiki 对该接口的记录明确说明无效 ID 同样返回 `false`，所以 ID 必须先核实。[`C_QuestLog.IsQuestFlaggedCompleted`](https://warcraft.wiki.gg/wiki/API:C_QuestLog.IsQuestFlaggedCompleted)

只有在“候选 ID 池已确认完整，且每个旗标都已验证按周重置”时，所有 ID 都返回 `false` 才能得出 `incomplete`。池不完整时只能得出 `unknown`。

### BGForge 建议实现与数据模型

将“周常槽位”与“当周 questID”分开：

- 静态内容定义：`slotKey -> { verifiedQuestIDs, poolComplete }`。任务池是 Titan 内容数据，不存游戏版本/flavor 字段。不要按本地化任务名匹配。
- 当前角色当周快照：`{ slotKey, resetAt, status, questID?, observedAt, evidence }`，其中 `status` 至少区分 `unknown / available / active / readyToTurnIn / incomplete / completed`，`evidence` 可为 `flag / gossip / questLog / accepted / turnedIn`。
- 观测到一个新周常 ID 可以暂存并用于当周状态，但不应因为“它是 Weekly”就自动并入目标槽位的可信池。先核实任务来源与槽位归属，否则会把其他周常误认成目标。

推荐刷新顺序：

1. `PLAYER_ENTERING_WORLD`：计算 `resetAt`，过期上周快照；查询所有已核实 ID 的完成旗标，再扫活动任务日志。
2. `QUEST_LOG_UPDATE` 及 `QUEST_ACCEPTED`：重扫日志，绑定新观测 ID 的 `Weekly` 频率与进度。
3. `GOSSIP_SHOW`：仅当当前交互能稳定归属到目标槽位时，用 Gossip 条目发现 `available/active` 的当周 ID。
4. `QUEST_TURNED_IN`：若 ID 已属于该槽位，立即写入 `completed`，并用 `IsQuestFlaggedCompleted` 在后续刷新中复核。
5. 在线跨周：废弃旧快照并重跑上述流程。无新证据时为 `unknown`，不沿用上周 `completed`。

隐私上只保存当前用户角色的最小当周快照，按重置覆盖/过期；不保存任务历史、NPC/位置轨迹、组队成员或其他玩家数据，不同步、不上传。离线角色只能显示其上次登录时写入且尚未过期的快照。

### 状态不能只看任务日志

Titan 同时提供 `C_QuestLog.IsOnQuest(questID)`，它只回答任务是否正在当前角色的任务日志里。[Titan `QuestLogDocumentation.lua` 84–97](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L84-L97)

可将状态理解为：

| 完成旗标 | 在任务日志 | 含义 |
| --- | --- | --- |
| `true` | 通常为 `false` | 已经交付；若 ID 的旗标按周重置，表示本周已完成 |
| `false` | `true` | 已接取，可能进行中或已达成目标但尚未交付 |
| `false` | `false` | 未接/未完成，也可能是 ID 错误、轮换未覆盖或状态尚未刷新 |

“目标已完成但尚未交任务”不是“周常已经交付”。Titan 自带任务界面从活动任务日志读取 `isComplete`、`frequency` 和 `questID`，并把 `Enum.QuestFrequency.Weekly` 渲染为周常；这些字段只能描述仍在任务日志中的任务。[Titan `QuestMapFrame.lua` 643–646](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_UIPanels_Game/Wrath/QuestMapFrame.lua#L643-L646)、[718–724](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_UIPanels_Game/Wrath/QuestMapFrame.lua#L718-L724)。任务交付后会离开日志，因此最终完成判断仍应使用完成旗标。

## 监控与周重置

Titan 文档化了 `QUEST_TURNED_IN`，事件载荷直接包含 `questID`；插件可在交任务时立即刷新目标 ID。[Titan `QuestLogDocumentation.lua` 226–236](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L226-L236)

建议刷新时机：

- `PLAYER_ENTERING_WORLD` 后查询一次，覆盖本周中途安装插件、重载界面和换角色。
- `QUEST_TURNED_IN` 的 `questID` 命中目标集合时刷新。
- `QUEST_LOG_UPDATE` 后刷新活动/待交状态；Titan 也正式文档化了这个事件。[Titan `QuestLogDocumentation.lua` 204–209](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L204-L209)
- 在线跨周重置时重新查询。Titan 提供 `C_DateAndTime.GetSecondsUntilWeeklyReset()`，应使用它计算服务器周重置边界，不要把星期几和时区写死。[Titan `DateAndTimeDocumentation.lua` 87–95](https://github.com/Gethe/wow-ui-source/blob/ba472e5e1b5580b557e3dbf02c9e5ff23b223347/Interface/AddOns/Blizzard_APIDocumentationGenerated/DateAndTimeDocumentation.lua#L87-L95)

当前生成文档没有通用的“周重置完成”事件。保存离线角色快照时，应同时保存 `expiresAt = GetServerTime() + secondsUntilWeeklyReset`；过期后显示“待该角色登录刷新”或未完成的过期态，不要继续把上周的 `true` 当成本周数据。

## 相关接口的区别

| 接口 | Titan Reforged Classic | 语义与结论 |
| --- | --- | --- |
| `C_QuestLog.IsQuestFlaggedCompleted(questID)` | **有** | 当前登录角色、单个 ID 的完成旗标；推荐接口。 |
| `C_QuestLog.IsOnQuest(questID)` | **有** | 只表示任务是否在日志中，不等于已交付。 |
| `C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID)` | 当前 Titan 导出文档中**没有** | Retail 有，表示账号任意角色的完成状态，不符合“当前角色”语义；不要在 Titan 代码中依赖。[Retail 生成文档 898–910](https://github.com/Gethe/wow-ui-source/blob/027d26c3406d3de2cbd2b1f67d468fe033a1bcd4/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L898-L910)、[Warcraft Wiki](https://warcraft.wiki.gg/wiki/API:C_QuestLog.IsQuestFlaggedCompletedOnAccount) |
| `C_QuestLog.GetAllCompletedQuestIDs()` | 当前 Titan 导出文档中**没有** | Retail 批量返回完成任务 ID 数组；没有完成时间，即使存在也不比精确查询目标 ID 更能证明“本周”。[Retail 生成文档 115–123](https://github.com/Gethe/wow-ui-source/blob/027d26c3406d3de2cbd2b1f67d468fe033a1bcd4/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L115-L123)、[Warcraft Wiki](https://warcraft.wiki.gg/wiki/API:C_QuestLog.GetAllCompletedQuestIDs) |
| `GetQuestsCompleted([table])` | 当前 Titan 导出文档和 UI source 中**没有受支持定义** | 旧全局接口，9.0.1 被 `C_QuestLog.GetAllCompletedQuestIDs()` 取代；返回结构也不同。不要把旧宏或旧插件代码直接移植到 Titan。[Warcraft Wiki](https://warcraft.wiki.gg/wiki/API:GetQuestsCompleted) |

上述“没有”指当前 Titan 3.80.2 客户端导出的受支持 API 表面；它的 `QuestLogDocumentation.lua` 函数清单只有角色级 `IsQuestFlaggedCompleted`，而同一文件的 Retail 版本才包含账号级和批量接口。不要用 Retail 文档推断 Titan 能力。

## questID 与内容实现的必要核验

落地前还需要该周常的任务名或 questID，原因有四个：

1. 同名任务、阵营版本、阶段版本可能有不同 ID。
2. 一项 UI 上的周常槽位可能在多个 questID 中轮换，应按业务规则做 `any` 判断。
3. 有些玩法用不可见 tracking quest 记录领取/击杀/奖励，玩家看到的任务 ID 未必就是最终锁定旗标。
4. 完成 API 没有时间戳；只有确认目标旗标会在 Titan 的周重置中清除，才能把它命名为 `completedThisWeek`。最稳妥的验收是在同一角色上记录交付前、交付后、周重置后的三次返回值。

因此，目前可以确定“官方 AddOn API 能做”，但还不能在没有具体任务 ID 的情况下保证某个未指明周常的检测逻辑。接口不读其他角色，也没有 Titan 账号级查询；其他角色只能在其登录时读取并保存最小完成快照。

## 外部 Battle.net API 不是实时替代方案

暴雪的 WoW Profile API 有 `/profile/wow/character/{realm-slug}/{character-name}/quests` 和 `/quests/completed` 端点；但这是插件外部的 HTTP Profile API，不是游戏内 AddOn API。暴雪官方说明 Profile 端点在角色登出时更新，因此不能替代当前在线角色的即时查询；当年发布这些任务端点的公告还明确说它们不适用于 WoW Classic，所以也不能据此假定 Titan 可用。[Blizzard Profile API 更新规则](https://us.forums.blizzard.com/en/blizzard/t/wow-game-data-and-profile-api-patch-notes-2019-12-10/2392)、[Blizzard 任务端点发布公告](https://us.forums.blizzard.com/en/blizzard/t/world-of-warcraft-api-update-visions-of-nzoth/3461)

对 BGForge 而言，应使用游戏内 `C_QuestLog.IsQuestFlaggedCompleted`，不需要外部服务、OAuth 或上传角色数据；这也符合当前仅保存本机角色必要快照的隐私边界。

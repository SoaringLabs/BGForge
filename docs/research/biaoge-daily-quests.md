# 原版 BiaoGe“日常任务”检测与判定机制

调研日期：2026-08-28  
范围：只读核对本机 `BiaoGe` 原版源码，并对照 `BGLite 2.4.0` 与当前 `BGForge`。本文只说明已有行为，不主张直接移植其存档或跨账号数据层。

## 结论

**有，而且对“珠宝、烹饪、钓鱼”这类专业日常已经形成完整闭环。** 原版的核心不是动态判断“某任务属于某专业”，而是：

1. 为每一类专业日常维护固定的 questID 白名单；
2. 维护当前角色已学技能的 skillID 表；
3. 在交任务时按 questID 精确命中，登录时用完成旗标补查；
4. 若角色学了对应技能、但本日没有命中完成记录，就标记 `notFinish` 并在 UI 画红叉；
5. 完成后画绿勾，日重置到期后回到红叉；遗忘专业后，当前角色的红叉记录会被移除。

因此，用户所说“某些专业附带日常任务，例如珠宝、钓鱼”基本正确。更准确地说，BiaoGe 只识别源码内预先登记的专业日常任务池；它**不检查是否已接取、是否当前可接、等级/声望资格，也不会自动发现新增任务 ID**。

## Titan 界面里的“日常”具体指什么

Titan 的角色总览任务区有 7 个槽位：`week1` 周常、`week2` 祖格周常、`zhubao` 珠宝、`cooking` 烹饪、`fish` 钓鱼、`holiday` 节日本、`dayQuestCount` 日常总数。[BiaoGe `RoleOverview.lua` 640–678](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L640>)

这里有两个容易混淆的概念：

- `zhubao / cooking / fish` 是各自独立的专业日常完成状态；
- `dayQuestCount` 来自游戏 API 的“今天已完成日常数量”，不是专业日常总数。[BiaoGe `RoleOverview.lua` 1462–1470](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1462>)

设置页把上述槽位归入全局 `QUESTS_LABEL`（“任务”）分组；源码里的本地化键 `L["日常任务"]` 没有实际功能调用，只有语言文件残留。[BiaoGe `Options.lua` 3335–3351](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Options.lua#L3335>)、[BiaoGe `zhCN.lua` 1569](</Users/liushuxiang/Desktop/Personal/BiaoGe/Locales/zhCN.lua#L1569>)

珠宝、烹饪、钓鱼和日常总数都**不是 Titan 默认显示列**；它们需要用户在角色总览设置中勾选。默认项包含周常、祖格周常、节日本和专业 CD 等。[BiaoGe `RoleOverview.lua` 143–165](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L143>) 更新日志也明确说“已完成日常数量”默认不勾选，以及已学专业但未完成专业日常时显示红 X。[BiaoGe `更新日志.txt` 113–116](</Users/liushuxiang/Desktop/Personal/BiaoGe/更新日志.txt#L113>)、[BiaoGe `更新日志.txt` 390–394](</Users/liushuxiang/Desktop/Personal/BiaoGe/更新日志.txt#L390>)

## Titan 使用的专业日常数据表

Titan build 会同时设置 `BG.IsWLK = true` 和 `BG.IsTitan = true`，因此日常逻辑进入 WLK 共用分支；它不会进入只属于 `BG.IsWLK_80` 的旧时光服附加分支。[BiaoGe `Init.lua` 164–171](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua#L164>)

| 槽位 | skillID | 固定 questID 池 |
| --- | ---: | --- |
| 珠宝 `zhubao` | 755 | 12959, 12962, 12961, 12958, 12963, 12960 |
| 烹饪 `cooking` | 185 | 13114, 13116, 13113, 13115, 13112, 13102, 13100, 13107, 13101, 13103 |
| 钓鱼 `fish` | 356 | 13836, 13833, 13834, 13832, 13830 |

数据定义见 [BiaoGe `RoleOverview.lua` 1393–1411](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1393>)。当前 Titan 不会追加 `gamma / heroe` 的任务 ID；这两项只在 `BG.IsWLK_80` 下追加，Titan UI 中也已经移除。更新日志同样记录了该删除。[BiaoGe `更新日志.txt` 428–431](</Users/liushuxiang/Desktop/Personal/BiaoGe/更新日志.txt#L428>)

其他游戏版本也复用同一套框架，但候选池不同：CTM 有珠宝、烹饪、钓鱼；MOP 当前只列烹饪；SOD 留有灰谷任务池。[BiaoGe `RoleOverview.lua` 1412–1434](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1412>)

## 分类数量边界

**就原版 BiaoGe 在 Titan Reforged Classic 的实际检测模型而言，“专业日常”恰好只有 3 类：珠宝、烹饪、钓鱼。** 这里的判定标准不是注释或显示名称，而是 `BG.dayQuests` 项是否带有 `skillID`：Titan 会先因版本号命中 `BG.IsWLK`，因而获得这 3 个基础项；同时它命中的是 `BG.IsTitan` 而不是 `BG.IsWLK_80`，所以不追加后者专属的 `gamma` 和 `heroe`。[BiaoGe `Init.lua` 164–171](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua#L164>)、[BiaoGe `RoleOverview.lua` 1393–1411](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1393>)

源码穷举也与 UI 槽位一致：Titan 的 7 个“任务”槽位分别是 `week1`、`week2`、`zhubao`、`cooking`、`fish`、`holiday`、`dayQuestCount`；其中只有中间 3 项是专业日常。设置页也以 `BG.dayQuestCount = 7` 切分这一整个任务区，这个数字是“任务槽位总数”，不是专业日常分类数。[BiaoGe `RoleOverview.lua` 640–678](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L640>)、[BiaoGe `Options.lua` 3335–3351](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Options.lua#L3335>)

下列相邻概念不应计入这 3 类：

- `week1 / week2` 有独立的 `BG.weekQuests` 和周重置存储链，属于周常。[BiaoGe `RoleOverview.lua` 1473–1510](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1473>)
- `holiday` 监听 `LFG_COMPLETION_REWARD` 并匹配节日副本 ID，不走专业 questID 池。[BiaoGe `RoleOverview.lua` 1527–1538](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1527>)
- `dayQuestCount` 只是 `GetDailyQuestsCompleted()` 返回的当日已完成日常总数，不表示第四类专业日常。[BiaoGe `RoleOverview.lua` 1462–1470](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1462>)
- `professionCD` 使用制造法术的冷却时间，覆盖炼金、铭文、珠宝、采矿、裁缝等；它与任务完成检测分开。[BiaoGe `RoleOverview.lua` 1755–1842](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1755>)、[BiaoGe `RoleOverview.lua` 1920–1945](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1920>)
- Titan 掉落数据库中的“专业制造”是 `BG.Loot[FB].Profession` 装备物品目录，也不是日常任务类别。[BiaoGe `DB_Loot_Titan.lua` 1353–1365](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/DB_Loot_Titan.lua#L1353>)
- 资源区里注释为“珠宝日常”和“烹饪日常”的 ID `61 / 81` 是货币资源项，只记数量；它们不是任务完成状态，也不会把分类数从 3 变成 5。[BiaoGe `RoleOverview.lua` 720–738](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L720>)

因此，若 BGForge 将标题做成两层，“专业日常”下面按原版能力边界就是固定 3 个子列：“珠宝 / 烹饪 / 钓鱼”。这能证明原版实现的范围，但不能单独证明 Titan 游戏未来或所有服务器内容永远不会出现其他专业日常；若日后要扩展，仍需补充新的类别和 questID 池。

## 完成检测和判定链

### 1. 先记录角色学会了哪些专业

原版每 5 秒遍历 `GetNumSkillLines()` / `GetSkillLineInfo()`，把识别到的技能写到：

```text
BiaoGe.MONEY[realmID][player].skill[skillID]
    = { level, icon, isMain }
```

映射表包含珠宝 `755`、钓鱼 `356`、烹饪 `185`；完成扫描使用 skillID，而不是拿任务名或本地化专业名直接比较。[BiaoGe `RoleOverview.lua` 2045–2089](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L2045>) 日常模块的 `IsLearnSkill()` 就是读取这张持久化技能表。[BiaoGe `RoleOverview.lua` 1380–1386](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1380>)

### 2. 交任务时实时捕获

`QUEST_TURNED_IN` 提供 `questID`。处理器依次调用日常和周常更新函数，并在 1 秒后刷新日常完成总数。[BiaoGe `RoleOverview.lua` 1540–1547](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1540>)

日常更新函数遍历所有槽位的 questID 白名单；精确命中后调用 `SaveDayQuest()`。这里没有额外的专业判断，完成判据就是“交付的 questID 在候选池内”。[BiaoGe `RoleOverview.lua` 1451–1461](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1451>)

### 3. 登录时补查遗漏事件

`BG.Init2` 在首次 `PLAYER_ENTERING_WORLD` 时执行注册的初始化函数。[BiaoGe `Init.lua` 71–82](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua#L71>) 日常模块随后延迟 3 秒遍历全部候选 questID，并调用 `C_QuestLog.IsQuestFlaggedCompleted(questID)`；任一命中就保存该槽位。这覆盖了插件重载、晚安装或没有观察到交付事件的情况。[BiaoGe `RoleOverview.lua` 1587–1625](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1587>)

在扫描完成旗标前，如果某槽位关联了 skillID、角色已经学会该技能且当天还没有记录，代码会先写 `{ notFinish = true }`。所以专业日常能表达“未完成”；普通任务槽位没有这层专业前提，缺记录时只是空白。

这意味着红叉的真实语义是：

```text
已学对应技能 AND 本周期内未找到候选池中的已完成任务
```

它不是“服务器明确返回当前可做但没做”。候选池漏 ID、完成旗标异常或资格条件不满足，都可能被压成同一个红叉。

### 4. 特殊日常

- `dayQuestCount`：读取 `GetDailyQuestsCompleted()`；数量为 0 时删除记录。[BiaoGe `RoleOverview.lua` 1462–1470](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1462>)
- `holiday`：不走任务 ID，而是在 `LFG_COMPLETION_REWARD` 后检查副本 ID 是否命中节日本白名单。[BiaoGe `RoleOverview.lua` 1373–1375](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1373>)、[BiaoGe `RoleOverview.lua` 1527–1538](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1527>)
- MOP `shoucai`：通过 `UNIT_SPELLCAST_SUCCEEDED` 的耕作技能 ID 记录，不是任务完成检测。[BiaoGe `RoleOverview.lua` 1514–1525](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1514>)

## 存档、重置与 UI 判定

原版只声明一个账号级 SavedVariable：`BiaoGe`。[BiaoGe `BiaoGe.toc` 1–8](</Users/liushuxiang/Desktop/Personal/BiaoGe/BiaoGe.toc#L1>) 日常记录结构是：

```text
BiaoGe.QuestCD[realmID][player][questName] = {
    name, player, colorplayer, questID,
    resettime, endtime, count
}
```

具体写入见 [BiaoGe `RoleOverview.lua` 1373–1378](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1373>) 和 [1435–1450](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1435>)。角色键来自带服务器的玩家名和 `GetRealmID()`。[BiaoGe `Init.lua` 224–234](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua#L224>)

日重置不是查询官方重置倒计时，而是按 `GetServerTime()` 和 `date()` 计算下一个 07:00。[BiaoGe `function1.lua` 926–944](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/function1.lua#L926>) 每 60 秒扫描一次记录：[BiaoGe `RoleOverview.lua` 1549–1586](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1549>)

- 未到期：更新 `resettime`；
- 普通日常到期：删除槽位；
- 有 skillID 的专业日常到期：清除时间字段，改成 `notFinish = true`；
- 当前登录角色若已不再拥有该技能：删除该专业日常槽位；
- 同一清理函数还会遍历可选的 `BiaoGeAccounts.QuestCD`。

UI 读取记录后：`count` 显示数字，达到 `GetMaxDailyQuests()` 时数字变红；`notFinish` 显示半透明红叉；其余记录显示绿勾。[BiaoGe `RoleOverview_core.lua` 1518–1552](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview_core.lua#L1518>)

## 对照 BGLite 与当前 BGForge

### BGLite：机制被整体移除

BGLite 的 TOC 不加载 `RoleOverview*.lua`；`BG.RoleOverviewUI()` 是空函数，主初始化文件还直接注明“角色总览已删除”。[BGLite `BGLite.toc` 14–49](</Users/liushuxiang/Desktop/Personal/BGLite/BGLite.toc#L14>)、[BGLite `function2.lua` 110–123](</Users/liushuxiang/Desktop/Personal/BGLite/Core/function2.lua#L110>)、[BGLite `BiaoGe.lua` 2025–2034](</Users/liushuxiang/Desktop/Personal/BGLite/Core/BiaoGe.lua#L2025>)

BGLite 的 `BG.DeletePlayerData` 仍列出 `QuestCD`，但它只是删除旧角色存档时的兼容键名，不构成检测、写入或展示机制。[BGLite `function1.lua` 653–681](</Users/liushuxiang/Desktop/Personal/BGLite/Core/function1.lua#L653>) BGLite 只给出“移除与基础拍卖无关的功能及风险代码”的整体说明，没有解释专业日常子功能被删的单独隐私或政策理由。[BGLite `zhCN.lua` 25–31](</Users/liushuxiang/Desktop/Personal/BGLite/Locales/zhCN.lua#L25>)

### BGForge：恢复了独立周常记录器，但尚未恢复专业日常

当前 BGForge 的 TOC 加载新写的 `RaidLockoutOverview.lua`，而不是原版三份 `RoleOverview*.lua`。[BGForge `BGForge.toc` 16–24](</Users/liushuxiang/Desktop/Personal/BGForge/BGForge.toc#L16>) 新总览已经有一个独立的 Titan 周常槽位和候选 ID 池：[BGForge `RaidLockoutOverview.lua` 21–43](</Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua#L21>)

它也使用“交任务事件 + 登录完成旗标补查 + 独立 resetAt”的思路：[BGForge `RaidLockoutOverview.lua` 745–803](</Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua#L745>)、[BGForge `RaidLockoutOverview.lua` 2498–2553](</Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua#L2498>)。但当前代码没有原版的：

- `BG.dayQuests` 专业日常候选池；
- `dayQuestCount` / `GetDailyQuestsCompleted()`；
- `notFinish` 专业未完成状态；
- 每日 resetAt；
- 珠宝、烹饪、钓鱼日常 UI 列。

BGForge 虽然会采集两个**主专业**快照，但不包含烹饪、钓鱼等辅助技能，也没有把专业快照接到任务判定上。[BGForge `RaidLockoutOverview.lua` 68–80](</Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua#L68>)、[BGForge `RaidLockoutOverview.lua` 289–340](</Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua#L289>) `function1.lua` 中残留的 `QuestCD` 同样只是旧存档删除清单。[BGForge `function1.lua` 653–678](</Users/liushuxiang/Desktop/Personal/BGForge/Core/function1.lua#L653>)

所以当前状态可概括为：**原版 BiaoGe 有专业日常检测；BGLite 将其随角色总览整体删除；BGForge 目前只恢复了类似算法的周常记录器，专业日常仍未恢复。**

## 隐私与复用边界

原版日常记录只需要当前用户角色的数据，但存储内容比判定所需更宽：除了槽位、questID 和过期时间，还重复保存 `player`、职业着色后的 `colorplayer`；专业表还保存技能等级、图标和主/副专业标志。对专业日常判定而言，最小必要字段其实只是当前本机角色下的 `skillID`、槽位状态、可选命中 `questID` 和每日 `resetAt`。

原版 UI 会读取 `BiaoGeAccounts` 的账号名、服务器、角色名和 `QuestCD`，重置函数也会直接清理该外部全局中的任务记录。[BiaoGe `RoleOverview_core.lua` 34–68](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview_core.lua#L34>)、[BiaoGe `RoleOverview.lua` 1552–1585](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1552>) 本机 BiaoGe checkout 不含 `BiaoGeAccounts` 实现，因此只能确认 BiaoGe 会消费这份跨账号数据，**无法从现有源码确认它如何采集、同步或传输**。

在 BiaoGe 自身的日常调用链中没有发现 `SendAddonMessage`、AceComm 或上传逻辑；可确认的是它写本地 SavedVariables，并可读取外部 `BiaoGeAccounts` 数据。若 BGForge 后续恢复此功能，应继续使用现有“只保存本机实际登录角色、不发送插件消息、不读取其他设备数据”的边界。[BGForge `RaidLockoutOverview.lua` 5–6](</Users/liushuxiang/Desktop/Personal/BGForge/Core/Module/RaidLockoutOverview.lua#L5>) 不应因原版存在 `BiaoGeAccounts` 集成，就顺带恢复跨账号数据层。

## 实现层面的关键限制

- **静态 ID 表会过期。** Titan 若新增或替换专业日常 questID，旧版本会把已完成误判成红叉。
- **红叉是推断，不是完整资格状态。** 它不区分“没做”“没资格”“未发现新 ID”“API 暂未刷新”。
- **旧角色信息可能陈旧。** 插件无法在线查询未登录角色；其专业与任务状态都是该角色上次登录时留下的本地快照。
- **重置时间硬编码。** 原版日重置固定计算 07:00，规则变化时可能提前或延后切换状态。
- **辅助专业要单独纳入模型。** 当前 BGForge 只保存两个主专业；若要恢复钓鱼/烹饪日常，不能仅复用现有主专业数组。

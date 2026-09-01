# Titan 专业日常与制造 CD 核对

调研日期：2026-09-01  
范围：当前 BGForge、只读 BiaoGe 上游，以及公开的 WotLK Classic 游戏数据。Titan Reforged Classic 可能改写任务轮换或配方冷却；没有公开 Titan 数据可证实的部分统一标为“需实测”。

## 结论先行

1. **当前 BGForge 中，珠宝、烹饪、钓鱼三列都是“分类布尔值”。** 同一分类白名单中的任意一个任务完成，就给该分类画绿勾，直到每日重置；不会计数，也不会继续表达同类中的第二次完成。[BGForge `RaidLockoutOverview.lua` 48–83](../../Core/Module/RaidLockoutOverview.lua#L48)、[932–985](../../Core/Module/RaidLockoutOverview.lua#L932)
2. **按标准 WotLK 规则，每个角色每天分别只有一个珠宝日常、一个烹饪日常、一个钓鱼日常可做；三类互相独立，同一角色可以在一天内各完成一次，但不能在重置前重复交同一类。** 珠宝从 6 个任务中随机一个，烹饪和钓鱼各从 5 个任务中随机一个；烹饪源码出现 10 个 ID，是联盟/部落各有一套 ID，并不是一天能做 10 次。[Wowhead 珠宝日常指南](https://www.wowhead.com/wotlk/guide/professions/jewelcrafting/daily-quests)、[Wowhead 烹饪日常指南](https://www.wowhead.com/wotlk/guide/professions/cooking/daily-quests)、[Wowhead 钓鱼日常指南](https://www.wowhead.com/wotlk/guide/professions/fishing/daily-quests)
3. **BiaoGe 的 WLK/Titan 候选表共有 10 个制造法术，实际是 5 个专业、10 个独立显示项。** 其中 7 项制造固定物品，3 项是“研究”类随机产物；`66660` 固定制造王者琥珀，但 BiaoGe 把它当作共享炼金转化 CD 的代表法术。[BiaoGe `RoleOverview.lua` 1783–1842](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1783>)
4. **不要在 BGForge 中硬编码这些 CD 的小时数。** 原版 WotLK、3.3.3、WotLK Classic 阶段服和 Titan 的规则并不完全一致。BiaoGe 会对候选 spellID 调用客户端 `GetSpellCooldown()` 并保存观察到的结束时间；这能追踪“正在冷却”，但不能证明一个当前为 0 的配方究竟是“已就绪”还是“Titan 已取消 CD”。[BiaoGe `RoleOverview.lua` 1920–1945](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1920>)

## 1. 专业日常：游戏规则与插件规则

### 标准 WotLK 的实际规则

| 分类 | 每日候选 | 同一角色当天可交次数 | 与另外两类的关系 |
| --- | --- | --- | --- |
| 珠宝 | 6 个货单任务中当天开放 1 个 | 该分类 1 次；交完需等日重置 | 独立，可继续做烹饪和钓鱼 |
| 烹饪 | 5 个任务中当天开放 1 个 | 该分类 1 次；交完需等日重置 | 独立，可继续做珠宝和钓鱼 |
| 钓鱼 | 5 个任务中当天开放 1 个 | 该分类 1 次；交完需等日重置 | 独立，可继续做珠宝和烹饪 |

珠宝指南明确写明“每天可从 6 个随机选项中接取并完成 1 个”；钓鱼指南写明每天从 5 个随机任务中接取一个；烹饪指南写明每天随机获得 5 个之一，并在服务器日重置时更换。[Wowhead 珠宝日常指南](https://www.wowhead.com/wotlk/guide/professions/jewelcrafting/daily-quests)、[Wowhead 烹饪日常指南](https://www.wowhead.com/wotlk/guide/professions/cooking/daily-quests)、[Wowhead 钓鱼日常指南](https://www.wowhead.com/wotlk/guide/professions/fishing/daily-quests)

这里的“不能重复”是**每角色、每分类、每个日重置周期**。不同角色各自有自己的任务资格；同一角色一天内做完珠宝，并不会锁住烹饪或钓鱼。

Titan 是否沿用完全相同的服务器轮换和资格条件，没有公开的一手数据可以验证。BiaoGe 只是因为 Titan 客户端版本仍命中 `BG.IsWLK` 分支而复用了 WLK 白名单，并不能单独证明 Titan 服务端没有改规则。[BiaoGe `Init.lua` 164–171](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua#L164>)、[BiaoGe `RoleOverview.lua` 1393–1407](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1393>)

### 当前 BGForge 到底怎样判定

BGForge 为每个分类维护一个 questID 池：

- 珠宝：`12959, 12962, 12961, 12958, 12963, 12960`
- 烹饪：`13114, 13116, 13113, 13115, 13112, 13102, 13100, 13107, 13101, 13103`
- 钓鱼：`13836, 13833, 13834, 13832, 13830`

定义见 [BGForge `RaidLockoutOverview.lua` 48–70](../../Core/Module/RaidLockoutOverview.lua#L48)。交任务时，`QUEST_TURNED_IN` 的 questID 只要命中某一池，就直接写入该列的完成快照；登录、刷新或打开界面时，则逐个调用 `C_QuestLog.IsQuestFlaggedCompleted()`，找到该列第一个已完成 ID 后停止扫描。[BGForge `RaidLockoutOverview.lua` 932–985](../../Core/Module/RaidLockoutOverview.lua#L932)、[2900–2902](../../Core/Module/RaidLockoutOverview.lua#L2900)

因此，对问题“做任何一个都代表今日已完成吗”，应分两层回答：

- **对插件显示：是。** 同类任意一个白名单任务完成，整列就是完成。
- **对标准游戏规则：也是符合实际意图的。** 因为同一角色当天本来只会开放该类中的一个，所以一个绿勾足以表示“该分类今天做过了”。

当前 BGForge 还有两个边界：

- 它只保存“已完成”，未完成时留空，不像旧 BiaoGe 那样结合已学专业显示红叉。[BGForge `RaidLockoutOverview.lua` 1255–1275](../../Core/Module/RaidLockoutOverview.lua#L1255)
- 它不记录完成次数。如果 Titan 将来允许同一天完成同类多个任务，现有模型会把第二次及以后折叠掉；届时应把布尔快照升级为计数或任务集合。

## 2. BiaoGe 制造 CD 与产物映射

### 完整映射

| BiaoGe 项 | 专业 | spellID | 配方/技能 | 实际产物 | 产物性质与冷却关系 |
| --- | --- | ---: | --- | --- | --- |
| `alchemy_yanjiu` | 炼金 | `60893` | 诺森德炼金研究 | **没有固定物品**；服务器脚本随机生成药水、药剂或合剂类成品，并尝试发现一个炼金配方 | 独立研究 CD，不与普通炼金转化共用。WotLK 数据显示约 3 天。[Wowhead](https://www.wowhead.com/wotlk/spell=60893/northrend-alchemy-research) |
| `alchemy_zhuanhua` | 炼金 | `66660` | 转化：王者琥珀 | **王者琥珀** `36922`；材料为秋色水晶 + 永恒生命 | 该 spellID 自己产出王者琥珀，但属于会触发共享 CD 的诺森德炼金转化组；其他史诗宝石/永恒元素转化会占用同一组 CD。[Wowhead](https://www.wowhead.com/wotlk/spell=66660/transmute-kings-amber)、[Warcraft Wiki 转化说明](https://warcraft.wiki.gg/wiki/Transmute) |
| `inscription_dadiaowen` | 铭文 | `61177` | 诺森德铭文研究 | **没有固定物品**；随机生成铭文制品，并尝试发现大型雕文配方 | 与小型铭文研究是两个独立 CD。WotLK 数据显示 20 小时。[Wowhead](https://www.wowhead.com/wotlk/spell=61177/northrend-inscription-research)、[Warcraft Wiki 共享冷却说明](https://warcraft.wiki.gg/wiki/Shared_cooldown) |
| `inscription_xiaodiaowen` | 铭文 | `61288` | 小型铭文研究 | **没有固定物品**；随机生成卷轴/羊皮纸类制品，并尝试发现小型雕文配方 | 与诺森德铭文研究独立。WotLK 数据显示 20 小时。[Wowhead](https://www.wowhead.com/wotlk/spell=61288/minor-inscription-research)、[Warcraft Wiki 共享冷却说明](https://warcraft.wiki.gg/wiki/Shared_cooldown) |
| `jewelcrafting_bingdonglingzhu` | 珠宝 | `62242` | 冰冻棱柱 | **冰冻棱柱** `44943` | 先制造一个可开启的容器，开启后才得到随机诺森德宝石；按内容阶段，可出现稀有宝石，并有机会出现龙眼石/史诗宝石。它不是“直接制造某一颗固定宝石”。WotLK 数据显示 20 小时。[Wowhead 技能](https://www.wowhead.com/wotlk/spell=62242/icy-prism)、[Wowhead 物品](https://www.wowhead.com/wotlk/item=44943/icy-prism) |
| `forge_taitanjinggang` | 采矿 | `55208` | 熔炼泰坦精钢 | **泰坦精钢锭** `37663` | 固定产物；标准材料为 3 泰坦神铁锭 + 永恒火焰/大地/暗影各 1。原始 WotLK 有 20 小时 CD，3.3.3 后曾移除；Titan 当前是否启用必须读实时 API。[Wowhead](https://www.wowhead.com/wotlk/spell=55208/smelt-titansteel)、[WotLK Classic 3.4.3 变更](https://warcraft.wiki.gg/wiki/Patch_3.4.3) |
| `tailor_fawenbu` | 裁缝 | `56003` | 法纹布 | **法纹布** `41595` | 固定基础产物；与另外两种布是分开的 CD。原始 WotLK 有地点要求和约 3 天 20 小时 CD，3.3.3 后曾移除。[Wowhead](https://www.wowhead.com/wotlk/spell=56003/spellweave) |
| `tailor_wuwenbu` | 裁缝 | `56002` | 乌纹布 | **乌纹布** `41593` | 固定基础产物；独立于法纹布/月影布。[Wowhead](https://www.wowhead.com/wotlk/spell=56002/ebonweave) |
| `tailor_yueyingbu` | 裁缝 | `56001` | 月影布 | **月影布** `41594` | 固定基础产物；独立于法纹布/乌纹布。[Wowhead](https://www.wowhead.com/wotlk/spell=56001/moonshroud) |
| `tailor_bingchuanbeibao` | 裁缝 | `56005` | 冰川背包 | **冰川背包** `41600`，22 格普通背包 | 独立的约 7 天制造 CD；不与三种专精布共用。[Wowhead](https://www.wowhead.com/wotlk/spell=56005/glacial-bag) |

裁缝的四个固定产物 itemID 也能由仓库内配方库交叉确认：[BGForge `LibRecipes-3.0.lua` 10138–10142](../../Libs/LibRecipes-3.0.lua#L10138)。

### 炼金转化为何只列 `66660`

BiaoGe 把显示名写成泛化的“炼金转化”，但配置的法术并不是抽象的“转化总 CD”，而是具体配方 **转化：王者琥珀** `66660`。[BiaoGe `RoleOverview.lua` 1791–1795](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1791>)

这个做法的意图是用共享组中的一个法术代表整组。标准 WotLK 中，同组还包括其他史诗宝石转化，例如紫黄晶、赤玉石、恐惧石、巨锆石、祖尔之眼，以及带冷却的诺森德永恒元素互转；做其中一个后，其他同组配方也会进入冷却。[Warcraft Wiki 转化说明](https://warcraft.wiki.gg/wiki/Transmute)、[Wowhead 永恒元素转化](https://www.wowhead.com/wotlk/spell=53777/transmute-eternal-air-to-earth)

这里有一个实现风险：如果角色没有学会 `66660`，Titan 客户端是否仍会通过该未学法术返回共享组的冷却，需要实际角色测试。更稳妥的 BGForge 实现应从角色**已学会的共享转化配方**里选择一个代表 spellID，或遍历候选转化 spellID 取最长的有效冷却，而不是永久依赖王者琥珀这一条。

### 不能把历史时长当成 Titan 常量

公开资料存在看似矛盾的信息，是因为补丁阶段不同：

- 原始 WotLK 的泰坦精钢锭与三种诺森德专精布有长 CD；补丁 3.3.3 移除了这些 CD 和布料地点要求。[Warcraft Wiki 裁缝补丁记录](https://warcraft.wiki.gg/wiki/Tailoring)
- WotLK Classic Phase 4 也明确让三种布和泰坦精钢可随处制造且无 CD。[Wowhead Phase 4 专业 CD 变更](https://www.wowhead.com/wotlk/news/profession-cooldown-changes-with-phase-4-wotlk-classic-335366)
- BiaoGe 的 Titan 分支仍把它们放进候选表，但**是否显示取决于 `GetSpellCooldown()` 的实时结果**，候选表本身不等于“当前一定有 CD”。[BiaoGe `RoleOverview.lua` 1783–1842](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1783>)、[1920–1945](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1920>)

所以实现上应保存客户端观察到的 `startTime + duration`，UI 展示“可用/剩余时间”；不要根据资料表写死“20 小时、3 天或 7 天”。这样 Titan 调表时插件不会顺手穿越到另一个补丁。

## 3. 对总览 UI 的直接含义

- **专业日常保留 3 个布尔列即可：珠宝、烹饪、钓鱼。** 每列含义是“本重置周期是否完成过该类任意候选任务”。
- **制造 CD 不适合继续展开成 10 个固定宽列。** 更适合一个汇总格：显示“可用数 / 总数”或最紧急 CD，悬停/点击后按专业展开上述 10 个候选项。
- 详情层必须区分：`可制造`、`冷却中`、`未学会/未观察到`。尤其是泰坦精钢和三种布，`没有有效冷却` 不能粗暴解释成“冷却已完成”，也可能是 Titan 当前版本取消了该 CD。
- 每个角色只应保存本机实际观察到的 spellID、结束时间和可选配方名；无需恢复 BiaoGe 的跨账号数据读取。

## 4. Titan 实际冷却的数据源与 API 边界

### 官方公告只确认“有专业调整”，没有公开逐配方时长表

Titan 官方前瞻确认服务器基于 WotLK 80 级框架，并明确提到“放开了一些制造物品的限制”，但没有列出逐个 recipe/spell 的冷却数值。因此公告可以证明 Titan **会偏离标准 WotLK**，不能直接生成插件所需的 CD 表。[Titan 上线前瞻](https://wow.blizzard.cn/news/20250922/40565_1260660.html)、[专业改动前瞻](https://wow.blizzard.cn/news/20251107/40565_1269568.html)

当前机器安装的 Titan 客户端 `.build.info` 显示版本为 `3.80.2.69496`。该客户端的 `Logs/Hotfix.log` 明确记录了 `SpellCooldowns` 表的 `VALID`/`DELETE` 热修操作，说明冷却记录确实可以由 Titan 客户端数据或热修覆盖，而不是只能沿用公开 WotLK 数据。这也解释了为什么 Wowhead 的历史阶段数据不能直接当作 Titan 真值。[本机 `.build.info`](</Volumes/T7 Shield/blizzard/World of Warcraft/.build.info>)、[本机 Titan `Hotfix.log`](</Volumes/T7 Shield/blizzard/World of Warcraft/_classic_titan_/Logs/Hotfix.log>)

### 可以怎样查 DB2

静态数据层应以**同一个 Titan build、并合并该 build 的 hotfix**为前提，做如下联表：

```sql
SELECT
    sla.Spell,
    sla.SkillLine,
    sla.MinSkillLineRank,
    sc.RecoveryTime,
    sc.CategoryRecoveryTime,
    sc.StartRecoveryTime
FROM SkillLineAbility AS sla
LEFT JOIN SpellCooldowns AS sc
    ON sc.SpellID = sla.Spell
WHERE sla.Spell IN (
    60893, 66660, 61177, 61288, 62242,
    55208, 56003, 56002, 56001, 56005
);
```

- `SkillLineAbility` 负责把 recipe spell 归入专业技能线，并提供学习等级等信息；它**不保存冷却时长**。其公开结构定义包含 `SkillLine`、`Spell`、`MinSkillLineRank`、`TradeSkillCategoryID` 等字段。[WoWDBDefs `SkillLineAbility`](https://github.com/wowdev/WoWDBDefs/blob/master/definitions/SkillLineAbility.dbd)
- `SpellCooldowns` 才包含 `RecoveryTime`、`CategoryRecoveryTime` 和 `StartRecoveryTime`，并通过 `SpellID` 关联法术。[WoWDBDefs `SpellCooldowns`](https://github.com/wowdev/WoWDBDefs/blob/master/definitions/SpellCooldowns.dbd)
- 三种布在最终、已合并热修的数据里若没有有效 `SpellCooldowns` 记录，或 `RecoveryTime`/`CategoryRecoveryTime` 均为 0，才可把**客户端静态基础 CD**判为 0。不能只查基础 CASC 里的 DB2：Titan 热修可以修改或删除记录；本机日志已经出现 `SpellCooldowns ... VALID` 与 `... DELETE`。
- 这组 DB2 联表仍不是插件运行时的理想依赖：Lua 插件不能直接 SQL 查询 DB2，公开数据库也未必及时收录国服专属 build；服务端还可能实施状态或共享组逻辑。它更适合作为离线核表和候选列表生成源。

Wago Tools 可以直接导出当前 build 的表。将 [`SpellCooldowns` 3.80.2.69496 CSV](https://wago.tools/db2/SpellCooldowns/csv?build=3.80.2.69496) 与 [`SkillLineAbility` 3.80.2.69496 CSV](https://wago.tools/db2/SkillLineAbility/csv?build=3.80.2.69496) 按 `SpellID = Spell` 联接，并筛选炼金 `171`、采矿 `186`、裁缝 `197`、珠宝 `755`、铭文 `773` 后，当前 Titan 客户端数据为：

| 专业 CD | spellID | `CategoryRecoveryTime` | `RecoveryTime` | 换算 | BiaoGe |
| --- | ---: | ---: | ---: | ---: | --- |
| 诺森德炼金研究 | `60893` | 0 | `244800000` | 68 小时（2 天 20 小时） | 有 |
| 炼金转化共享组 | `66660` 等 | `72000000` | 0 | 20 小时 | 仅以 `66660` 代表 |
| 诺森德铭文研究 | `61177` | 0 | `72000000` | 20 小时 | 有 |
| 小型铭文研究 | `61288` | 0 | `72000000` | 20 小时 | 有 |
| 闪亮的玻璃 | `47280` | 0 | `72000000` | 20 小时 | **遗漏** |
| 冰冻棱柱 | `62242` | 0 | `72000000` | 20 小时 | 有 |
| 冰川背包 | `56005` | 0 | `590400000` | 164 小时（6 天 20 小时） | 有 |

以下法术在该 build 的 `SpellCooldowns` 中**没有以它们为 `SpellID` 的记录**：泰坦精钢 `55208`、法纹布 `56003`、乌纹布 `56002`、月影布 `56001`。这与三种布可连续制作的实测一致；静态数据也表明泰坦精钢在当前 build 无长 CD。注意 CSV 中可能存在 `ID` 恰好等于这些 spellID 的无关行，查询必须匹配最后一列 `SpellID`，不能匹配记录主键 `ID`。

这份结果还揭示了 BiaoGe 候选表的一处真正缺口：**Titan 仍有 20 小时 CD 的珠宝技能 `47280`“闪亮的玻璃”，BiaoGe 没有跟踪它。** 因此不能简单地把 BiaoGe 的 10 项删掉三种布就当作 Titan 完整表。

### 运行时 API 能知道什么

| API | 能回答 | 不能回答/限制 |
| --- | --- | --- |
| `GetSpellCooldown(spellID)` / `C_Spell.GetSpellCooldown(spellID)` | 当前角色该法术**正在进行的**开始时间与总时长 | 返回 0 时，无法区分“有 CD 但现在已就绪”和“该配方根本无 CD”；用未学会的 spellID 代表共享 CD 也不稳妥。Titan 生成文档将其定义为 active cooldown，inactive 时 `startTime`/`duration` 为 0。[Titan `C_Spell` 文档](https://github.com/Gethe/wow-ui-source/blob/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua)、[`SpellCooldownInfo` 结构](https://github.com/Gethe/wow-ui-source/blob/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua#L19-L31) |
| `GetSpellBaseCooldown(spellID)` | 客户端当前静态数据里的未修正基础 cooldown（毫秒） | 只说明静态 spell 基础值；不能替代角色的剩余时间，也不保证覆盖服务端日重置、共享转化组等规则。[API 语义](https://warcraft.wiki.gg/wiki/API%3AGetSpellBaseCooldown) |
| Titan 旧专业窗的 `GetTradeSkillCooldown(index)` | 在对应专业窗口已加载时，读取该已学配方的**剩余 CD 秒数** | 参数是当前专业列表索引，不是 spellID；窗口未加载时不能全局扫。返回 nil/0 同样不能证明这是“就绪”还是“永久无 CD”。Titan 自带专业窗口正是这样显示剩余 CD。[Titan Blizzard 专业窗口源码](https://github.com/Gethe/wow-ui-source/blob/classic_titan/Interface/AddOns/Blizzard_TradeSkillUI/Wrath/Blizzard_TradeSkillUI.lua#L316-L357) |
| `C_TradeSkillUI.GetRecipeCooldown(recipeID)` | 其他现代客户端的 recipe API | **Titan 不提供这条函数。** `classic_titan` 生成的 `TradeSkillUIDocumentation.lua` 中没有它，自带 UI 也走旧式 `GetTradeSkillCooldown(index)`；BGForge 不应把它设计成 Titan 主路径。[Titan `C_TradeSkillUI` 生成文档](https://github.com/Gethe/wow-ui-source/blob/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua) |

因此，**没有一个 API 能在配方处于 ready 状态时，单独、绝对地告诉插件“它未来施放后会不会进入长 CD”**。可靠方案是把三个信息层叠起来：Titan 候选表、静态 `GetSpellBaseCooldown` 诊断、角色实际观察到的 recipe/spell cooldown。

### BiaoGe 对 Titan 的真实处理

1. Titan 的接口版本 `3.80.x` 同时设置 `BG.IsWLK = true` 和 `BG.IsTitan = true`。[BiaoGe `Init.lua` 164–171](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/DB/Init.lua#L164>)
2. 专业 CD 候选表判断顺序是 `elseif BG.IsWLK then`，所以 Titan 直接复用 WLK 的 10 个 spellID；**没有 Titan 专属候选表，也没有 Titan 专属时长覆盖**。[BiaoGe `RoleOverview.lua` 1783–1842](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1783>)
3. Titan 总览 UI 只提供 7 个“忽略”选项：炼金研究、炼金转化、大/小雕文、冰冻棱柱、泰坦精钢、冰川背包；没有给法纹布、乌纹布、月影布提供忽略项。这与 Titan 三种布无 CD 的现状相符，但只是 UI 配置上的间接迹象，不是数据源。[BiaoGe `RoleOverview.lua` 640–675](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L640>)
4. 采集逻辑只在 `cooldown > 0` 时写记录。`GetSpellCooldown()` 返回 0 时，它既不会新增记录，也不会删除已有记录；旧记录到期后会被改成 `ready = true`。所以 BiaoGe 本身也无法区分 ready 与 no-CD，并可能保留历史“已就绪”记录。[BiaoGe `RoleOverview.lua` 1920–1945](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1920>)、[1965–2002](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1965>)
5. BiaoGe 监听 `TRADE_SKILL_UPDATE` 与 `SPELL_UPDATE_COOLDOWN` 后延迟 1 秒重查，这种延迟是合理的；API 文档也提示施法成功事件发生时 cooldown 值可能尚未立即更新。[BiaoGe `RoleOverview.lua` 1947–1963](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1947>)、[GetSpellCooldown 细节](https://warcraft.wiki.gg/wiki/API%3AGetSpellCooldown)

所以 BiaoGe 可作为“如何观察活动 CD”的参考，**不能作为 Titan 哪些配方有 CD 的权威清单**。

更具体地说，BiaoGe 当前对 Titan 是“两头都偏了一点”：候选表保留了已经无 CD 的泰坦精钢和三种布，却遗漏了仍有 20 小时 CD 的闪亮的玻璃 `47280`。

## 5. BGForge 的建议落地方案

1. 建立 Titan 专属候选定义，不复用历史 WotLK 表。当前 build 应纳入 7 个逻辑项：炼金研究、炼金转化共享组、大雕文研究、小雕文研究、闪亮的玻璃、冰冻棱柱、冰川背包。`55208/56001/56002/56003` 不进入总览 CD 列表。
2. 打开专业窗口时遍历非 header 配方，以 recipe index 调用 `GetTradeSkillCooldown(index)`；把所有 `remaining > 0` 的已学配方保存为 `endTime = GetServerTime() + remaining`。
3. 在 `UNIT_SPELLCAST_SUCCEEDED`、`TRADE_SKILL_UPDATE`、`SPELL_UPDATE_COOLDOWN` 后延迟短时间，再以候选 spellID 调用 `GetSpellCooldown` 补采。共享炼金转化应扫描角色已学会的一组转化 spellID，而不是只查未必学会的 `66660`。
4. 数据状态至少区分 `cooling`、`ready`、`unknown`；不要把 API 的 `(0, 0)` 直接翻译成“可用”，因为它也代表“无 CD”。只有候选表已确认该技能有 CD时，0 才能显示 ready。
5. 对当前角色，如果专业窗口扫描明确返回无 CD，且该配方不在 Titan 已确认候选表中，应删除旧的历史计时，避免照搬 BiaoGe 的永久 `ready` 残留。
6. 增加一个仅本机诊断命令，打印 build、spellID、是否已学、`GetSpellBaseCooldown`、`GetSpellCooldown`，并在专业窗打开时打印 `GetTradeSkillCooldown(index)`。这样每次 Titan 热修后可以由实际角色快速生成一份不含玩家身份信息的核对结果。

建议的游戏内诊断核心如下（仅用于实测，不是生产 UI）：

```lua
local ids = { 60893, 66660, 61177, 61288, 62242, 55208, 56003, 56002, 56001, 56005 }
for _, spellID in ipairs(ids) do
    local startTime, duration = GetSpellCooldown(spellID)
    local baseMS = GetSpellBaseCooldown and select(1, GetSpellBaseCooldown(spellID))
    print(spellID, GetSpellInfo(spellID), IsPlayerSpell(spellID), baseMS, startTime, duration)
end
```

这段输出能立刻验证三种布在**当前 Titan build 的静态基础值和当前角色状态**，但最终仍应结合专业窗口的 `GetTradeSkillCooldown(index)`；否则 `(0, 0)` 这个结果会一本正经地同时表示两件事。

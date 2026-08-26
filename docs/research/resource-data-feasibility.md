# BGForge 角色资源数据可行性（Titan Reforged Classic）

## 结论

| 数据 | 结论 | 可靠边界 |
| --- | --- | --- |
| 两个主专业、技能等级、图标 | **可实现** | 当前在线角色可直接读取；其他角色只能显示其上次登录时保存的快照。Titan 客户端自带界面已使用 `GetProfessions` 和 `GetProfessionInfo`。 |
| 橙装及实际装等 | **可实现，但必须定义“拥有”的范围** | 已装备和随身背包可以完整枚举；银行内物品只有在银行数据可见时才能完整枚举链接和实际装等。已知物品 ID 的总数可用 `GetItemCount(id, true)` 连银行一起统计。 |
| 橙色升级物品/碎片 | **可实现，但依赖维护物品 ID 清单** | API 没有“这是橙装升级材料”的语义分类。已知 ID 可可靠计数；新阶段增加材料时必须更新清单。 |

因此，这个资源表可以落地。推荐产品定义是：专业显示两个主专业；“橙装”显示已装备、背包和最近一次打开银行时记录到的橙色装备；“升级物品”按 BGForge 自己维护的 Titan 物品 ID 清单统计；饰品默认指两个**当前已装备饰品**。这套定义最稳定，也不会让一个 Hover 表承担仓库管理器的工作。

## 1. 主专业

### 可用 API

Titan 客户端自带的专业界面直接调用 `GetProfessions()`，其前两个返回值就是两个主专业索引；再调用 `GetProfessionInfo(index)` 可得到专业名、图标纹理、当前 `rank`、`maxRank` 和 skill line ID。[Titan 客户端 `SpellBookProfessions.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_UIPanels_Game/Cata/SpellBookProfessions.lua) 在 `SpellBook_UpdateProfTab` 和 `FormatProfession` 中展示了这条完整调用链。它正好对应“最多两个专业”和“等级 + 图标”的展示需求，不需要扫描次要技能。

若运行时发现某个 Titan 补丁未暴露这组全局函数，可以回退到 `GetNumSkillLines()` + `GetSkillLineInfo(index)`；Titan 自带 Classic 技能面板也使用这两个函数读取 `skillRank`/`skillMaxRank`。[Titan 客户端 `SkillFrame.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_UIPanels_Game/Classic/SkillFrame.lua)。只读上游使用的正是技能列表回退路径，并附有主专业 skill line ID 和图标映射：[BiaoGe `RoleOverview.lua` 2045–2091](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L2045>)。

### 建议快照

每个专业保存 `{ skillLineID, rank, maxRank, iconFileID }`，不要仅保存本地化名称。建议在登录初始化和 `SKILL_LINES_CHANGED` 后刷新；该事件由 Titan 的 `C_SkillInfo` API 文档和技能面板共同使用。[Titan `SkillInfoDocumentation.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/SkillInfoDocumentation.lua)。离线角色没有查询 API，只能读取 SavedVariables 中该角色最近一次登录保存的快照。

## 2. 橙装与实际装等

### 已装备物品：可靠

可以遍历角色装备槽：

- `GetInventoryItemLink("player", slot)` 返回带实例信息的装备链接；只读上游已经用它遍历角色 1–19 号装备槽：[BiaoGe `RoleOverview.lua` 2340–2387](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L2340>)。
- `GetInventoryItemQuality("player", slot)` 返回品质；Titan 的生成式 API 枚举明确规定 `Legendary == 5`：[Titan `ItemQualitiesDocumentation.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemQualitiesDocumentation.lua)。
- 对**完整 item link** 调用 `C_Item.GetDetailedItemLevelInfo(link)` 可取得 `actualItemLevel`；该函数和返回字段均存在于 Titan 的生成式 API 文档：[Titan `ItemDocumentation.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)。若某阶段物品运行时返回异常，则回退到 `select(4, GetItemInfo(link))`，必要时再用隐藏 Tooltip 解析。

这里必须优先保存完整链接，而非只有 item ID；同一基础物品若通过链接字段表达升级状态，单独用 ID 可能丢失实际装等。

### 背包：可靠；银行：有条件可靠

随身背包可以遍历 `0 .. NUM_BAG_SLOTS`，用 `C_Container.GetContainerNumSlots` 和 `C_Container.GetContainerItemInfo/GetContainerItemLink` 获取每格的 `quality`、`itemID`、数量和链接；Titan 的 `ContainerItemInfo` 结构明确包含这些字段。[Titan `ContainerDocumentation.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)。对 `quality == 5` 的装备链接读取实际装等即可。

银行分两种需求：

1. **已知 item ID 的数量**：`C_Item.GetItemCount(itemID, true)` 的 `includeBank` 参数明确支持把银行计入总数；[Titan `ItemDocumentation.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)。这适合升级材料和已知橙装家族的“有/无、数量”。
2. **完整枚举银行里的未知橙装及其实际装等**：需要在 `BANKFRAME_OPENED` 时扫描银行容器并保存链接；Titan 自带银行界面只在打开时注册银行槽位变化并读取对应格子。[Titan `BankFrame.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_UIPanels_Game/TBC/BankFrame.lua)。银行未打开时不应声称拥有一份实时、完整的格子清单。

因此 UI 最好把银行数据视为“最近一次打开银行时的快照”。离线角色同样只能显示其最后一次保存的快照，并记录 `updatedAt`，避免把旧值伪装成实时值。

### 异步物品资料

`C_Item.GetItemInfo(link/id)` 被 Titan API 标记为 `MayReturnNothing`，并同时提供 `GET_ITEM_INFO_RECEIVED`、`RequestLoadItemDataByID` 等加载机制。[Titan `ItemDocumentation.lua`](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)。实现时应：

- 先保存容器/装备给出的 link、itemID 和数量；
- 缺少名称、图标或装等时请求物品资料；
- 在 `GET_ITEM_INFO_RECEIVED` 或 `ITEM_DATA_LOAD_RESULT` 成功后补齐并重新刷新快照；
- 加失败/超时处理，不能无限等待回调。

### Titan 橙装目录

“扫描所有可见位置并筛品质 5”适合发现实际成品；但 Titan 的橙武任务存在阶段物品、组件和多个升级 item ID，若产品希望把“正在制作”也算进“有哪些橙装”，仍需要一个按武器家族分组的目录。

只读上游已经维护了橙颈、橙锤、风剑、橙杖、橙匕、橙弓等系列及阶段 ID：[BiaoGe `RoleOverview.lua` 389–431](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L389>)，并通过 `GetItemCount(itemID, true)` 查找每个家族当前拥有的阶段：[BiaoGe `RoleOverview.lua` 2104–2129](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L2104>)。这份表可以作为行为参考，但移植前应重新核对当前 Titan 阶段，且只保存 UI 必需的 `{ family, itemID, link, itemLevel, count, locationScope, updatedAt }`，不要顺手恢复上游其他角色活动数据。

## 3. 橙色升级物品/碎片

此类物品不能通过 `quality == 5` 或装备类型自动推导：API 能告诉插件 item ID、品质、类型和数量，却不会告诉插件“它用于升级哪件橙武”。所以可靠方案只有“策划目录 + `GetItemCount`”。

只读上游当前列出的 Titan 升级物品 ID 为：

```text
265340, 265524, 267339, 269664,
265335, 265523, 267338, 269667,
265526, 267335, 269669,
267340, 269665,
269670
```

来源：[BiaoGe `RoleOverview.lua` 432–439](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L432>)。BGForge 自己的 Titan 掉落白名单也把 P3、P4、P5 的升级物品按阶段列出，可作为第二处本地交叉检查：[BGForge `DB_Loot_BlackWhiteList.lua` 185–187](../../Core/DB/DB_Loot_BlackWhiteList.lua#L185)。

对每个 ID 调用 `GetItemCount(id, true)` 可以得到背包+银行总数；如果还要在 UI 中区分“身上/银行”，则分别获取不含银行数量与含银行数量后相减。它仍然只覆盖当前在线角色，其他角色必须读快照。新增阶段若出现新 ID，旧版本插件会漏计，因此这份目录需要显式版本化并随阶段更新。

## 4. 饰品与当前 BGForge 的数据边界

若“有哪些饰品”指正在使用的两个饰品，读取装备槽 13、14 最可靠，也与只读上游的角色总览设计一致；上游将饰品定义成 `equip` 组，并从装备快照取对应槽位：[BiaoGe `RoleOverview.lua` 1039–1057](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua#L1039>)、[BiaoGe `RoleOverview_core.lua` 307–326](</Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview_core.lua#L307>)。若定义成“角色所有饰品”，则会立即继承背包/银行的完整枚举限制，且 Hover 表很容易溢出；不建议首版这么定义。

当前 BGForge 已经遵守“仅本机登录角色快照、不发送插件消息”的隐私边界：[BGForge `RaidLockoutOverview.lua` 5–6](../../Core/Module/RaidLockoutOverview.lua#L5)。现有资源快照只保存金币、泰坦余烬和泰坦碎片：[BGForge `RaidLockoutOverview.lua` 327–352](../../Core/Module/RaidLockoutOverview.lua#L327)。新增数据应继续放在同一角色快照下，仅在该角色实际登录时更新；银行内容只在玩家主动打开银行时读取，不能引入跨账号通信或恢复 BiaoGe 里与本功能无关的数据收集。

## 建议的首版范围

1. 专业：两个主专业，显示 `rank + icon`，登录及技能变化时刷新。
2. 橙装：显示已装备、背包，以及最近一次银行扫描得到的**成品橙色装备**；显示图标和实际装等。
3. 升级物品：按上述已知 ID 目录显示数量，数量包含银行；目录带版本号。
4. 饰品：只显示当前装备的两个饰品及装等。
5. 所有装备/资源项保存 `updatedAt`；离线角色永远显示快照，不标成实时。

这套范围在 Titan API 能力内，数据密度也适合当前小界面。唯一必须在实现前做的运行时确认，是在 Titan 客户端里用一次最小诊断脚本验证 `GetDetailedItemLevelInfo` 对各阶段橙武链接的返回；若不一致，就沿用上游已经证明可工作的 `GetItemInfo(link)`/Tooltip 回退路径。

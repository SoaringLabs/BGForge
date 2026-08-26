# Titan Reforged: 泰坦余烬 API 调研

调研日期：2026-08-26

## 结论

泰坦余烬是角色货币，不是背包物品。Titan Reforged Classic 客户端可以通过货币 API 读取当前登录角色的数据：

```lua
local TITAN_EMBER_CURRENCY_ID = 3403
local info = C_CurrencyInfo.GetCurrencyInfo(TITAN_EMBER_CURRENCY_ID)

if info then
    local quantity = info.quantity
    local quantityEarnedThisWeek = info.quantityEarnedThisWeek
    local maxWeeklyQuantity = info.maxWeeklyQuantity
end
```

- `quantity`：当前角色仍持有、可以消费的泰坦余烬余额，适合资源总览正文。
- `quantityEarnedThisWeek`：本周累计获取量。
- `maxWeeklyQuantity`：本周获取上限。
- “本周剩余可获取量”需要用 `maxWeeklyQuantity - quantityEarnedThisWeek` 计算，并限制最小值为 0。

余额与周获取进度不是同一个概念。官方曾发放不计入每周上限的额外泰坦余烬，因此界面不应把余额简单显示成 `quantity / maxWeeklyQuantity`。

## 数据范围

`C_CurrencyInfo.GetCurrencyInfo` 没有角色参数，只能查询当前登录角色。全角色总览仍需在每个角色登录时读取并写入 SavedVariables，之后显示各角色最近一次缓存。

泰坦余烬不是包裹或银行物品，因此不应使用 `GetItemCount`。

登录初期接口可能暂时返回 `nil`；实现时不应以 0 覆盖旧缓存。建议初始化后延迟读取，并监听 `CURRENCY_DISPLAY_UPDATE` 重新读取。

## 项目内证据

- 原上游 BiaoGe 将 `3403` 标注为泰坦余烬，并用 `C_CurrencyInfo.GetCurrencyInfo` 保存其数量。
- BGForge 的 Titan 装备兑换数据已经把 `3403` 用作兑换货币 ID。
- 原上游按角色缓存货币，并监听 `CURRENCY_DISPLAY_UPDATE`、`PLAYER_MONEY` 和 `BAG_UPDATE_DELAYED`。

## 主要来源

- [Titan 客户端导出的 CurrencyInfo API 文档](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_titan/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua)
- [暴雪中国：泰坦重铸内容前瞻 III](https://wow.blizzard.cn/news/20251107/40565_1269568.html)
- [暴雪中国：额外泰坦余烬不计入每周上限的活动说明](https://wow.blizzard.cn/news/20251126/40565_1273210.html)
- `/Users/liushuxiang/Desktop/Personal/BiaoGe/Core/Module/RoleOverview.lua`
- `/Users/liushuxiang/Desktop/Personal/BGForge/Core/DB/DB_Loot_Titan.lua`


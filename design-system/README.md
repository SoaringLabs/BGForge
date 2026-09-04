# BGForge 设计系统

当前方向已经确定为配色方案 1：**Arcane Archive（奥术档案）**。

核心语言是：

- 冷墨蓝的数据工作台，降低不同地图环境色的干扰。
- Rune Blue（低饱和钢蓝）表达选择、焦点和主操作。
- Forge Gold 只表达 BGForge 品牌与高价值金额。
- 绿色、琥珀色和红色只表达业务状态。
- 紧凑但不拥挤，以稳定列宽、明确分组和 4/8 像素节奏提高扫描效率。

## 文件

- [`MASTER.md`](MASTER.md)：品牌、颜色、字体、间距、状态、组件和 Lua 使用规则的唯一事实来源。
- [`pages/character-overview.md`](pages/character-overview.md)：角色总览“小界面”（悬停小地图图标后出现的浮动面板）的页面级规范。
- [`pages/auction-workspace.md`](pages/auction-workspace.md)：主窗体与角色总览“大界面”（主窗体内“角色总览”标签页）的布局、导航规范。
- [`pages/wishlist.md`](pages/wishlist.md)：心愿清单工作台的页面级规范。
- `Core/UI/DesignSystem.lua`：可直接在 WoW 内使用的 tokens 与基础控件实现。

## 已实现的基础能力

```lua
local tab = BG.UI.Create("tab", parent, {
    text = "纳克萨玛斯",
    state = "selected",
    width = 120,
    height = 28,
})

BG.UI.SetState(tab, "default")
```

目前提供：

- `surface`：窗口、面板、标题、行、浮层等语义表面。
- `text`：标题、正文、标签、说明、数字和重要数字。
- `tab`：包含截图中确认的静态青蓝选中效果。
- `button`：primary、secondary、quiet、danger 四种层级。
- `input`：default、focus、error、disabled 状态。
- `divider`：统一的结构分隔线。

选中效果由底色、1px 边框、低透明度纯色层和 2px 底线组成，不使用渐变、持续动画或逐帧更新。

## 后续迁移原则

先迁移共享窗口框架与标签页，再迁移表格、输入框和状态展示，最后重组主体拍卖工作区。迁移期间保留现有内容、业务行为和本机数据边界，不引入玩家同步、额外身份采集或跨游戏版本状态。

# 更新日志

本文件记录 BGForge 各版本的重要变更。

版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)，日志格式参考
[Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## 未发布

## v0.1.0 - 2026-08-26

### 新增

- 新增“全角色总览”，集中查看本机登录过的角色：
  - 本周团本锁定状态；
  - 角色等级与专业；
  - 橙装、升级物品及已装备饰品；
  - 金币、泰坦余烬和泰坦碎片。
- 支持从主界面入口、小地图星标悬浮窗，以及 `/bgr`、`/bgraid` 命令打开总览。
- 总览数据仅保存在本机 SavedVariables 中，不通过插件频道发送角色数据。

### 界面预览

![BGForge 全角色总览](docs/images/v0.1.0-character-overview.png)

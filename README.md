# Comix · 魔兽世界「无限」版

爆击、治疗、连杀、死亡时弹出漫画图片、播放搞怪音效的娱乐插件，适配《魔兽世界》：“无限”（客户端目录 `_forever_`，`## Interface: 16001`）。

> 乌龟服（1.12 / TurtleWoW）版本在另一个仓库：[WatsonZ/Comix](https://github.com/WatsonZ/Comix)。
> 本仓库基于 Turaka、Nixxen 维护的 Comix 8.2.5 版本迁移而来。

## 安装

1. 点击 **Code → Download ZIP** 下载并解压。
2. 把解压出来的文件夹**改名为 `Comix`**（文件夹名必须和 `Comix.toc` 一致，否则游戏不认）。
3. 放到游戏目录 `World of Warcraft\_forever_\Interface\AddOns\` 下。
4. 完全退出游戏后重新进入。

## 使用

- 点击小地图边上的**炸弹图标**（左键打开设置，右键开关插件，可拖动），或输入 `/comix` 打开设置。
- 设置界面支持**中文 / English**，默认跟随客户端语言，可用界面上的按钮或 `/comix lang zh|en|auto` 切换。
- 所有设置改了立即生效，按角色保存。

### 常用命令

| 命令 | 作用 |
|---|---|
| `/comix` | 打开 / 关闭设置 |
| `/comix test` | 依次播放所有效果（再输一次停止） |
| `/comix debug` | 显示事件是否触发及原因（排查问题用） |
| `/comix minimap` | 显示 / 隐藏小地图按钮 |
| `/comix showjump` · `reportjump` · `clearjump` | 跳跃统计 |
| `/fail <目标> <文字 ~~>` · `/awesome ...` | 在消息里插入 [Supermassive Fail] / [Pure Awesome] 链接 |
| `/drama` · `/badjoke` | 狗血探测器 / 烂笑话探测器 |

## 在「无限」上的功能

“无限”启用了正式服“至暗之夜”的插件限制：插件读不到战斗日志，目标血量、伤害数值也都是保密值。本版本改用仍可读取的信号实现了大部分效果：

| 功能 | 状态 | 实现方式 |
|---|---|---|
| 爆击弹图 / 音效 / 闪屏、连续爆击 “Impressive” | ✅ | `UNIT_COMBAT` 的爆击标记和伤害类型（按法术学派选图） |
| 治疗爆击 | ✅ | `UNIT_COMBAT` |
| 被爆击反应、闪避 / 招架 / 格挡等 | ✅（新增） | `UNIT_COMBAT` |
| 连杀播报 | ✅ | 你打过的当前目标死亡时计数，死亡清零 |
| “Finish Him!” | ⚠️ 部分 | 读不到血量，改为怪物残血**恐惧逃跑**时触发 |
| 战斗怒吼 / 挫志怒吼、技能音效 | ✅ | 施法事件 |
| 死亡、复活、就位确认、切换区域、进副本、跳跃 | ✅ | 原有事件 |
| 超杀、爆击门槛、Finish Him 血线 | ❌ 已隐藏 | 需要伤害 / 血量数值 |
| 异议、拥抱统计 | ❌ 中文客户端已隐藏 | 只能识别英文表情文字 |

已知限制：`UNIT_COMBAT` 不告诉插件是谁打的，组队时队友对你目标打出的爆击也会触发；连杀只统计你当前选中的目标。

## 给其他插件调用

见 [Custom Function readme.txt](Custom%20Function%20readme.txt)：`Comix_CustomPic(path)`、`Comix_CustomSound(path)`、`Comix_ScreenFlash(r, g, b, size)`。

## 致谢

- 「无限」版作者：迪恩温彻斯特
- 原作者：Turaka @ Quel'Thalas、Nixxen 等 Comix 作者（[CurseForge](https://www.curseforge.com/wow/addons/comix)）
- 图片和音效素材来自原插件，版权归各自所有者。

---

## English

**Comix** for World of Warcraft “无限” (“Forever”, client folder `_forever_`, Interface 16001): comic images and silly sounds on crits, heals, kill streaks and deaths. Ported by 迪恩温彻斯特 from Comix 8.2.5 (Turaka, Nixxen). The Turtle WoW version lives in [WatsonZ/Comix](https://github.com/WatsonZ/Comix).

Install: download the ZIP, **rename the folder to `Comix`**, put it in `_forever_\Interface\AddOns\`, restart the game. Open the options with the minimap button or `/comix`; the options are bilingual (`/comix lang zh|en|auto`).

The client hides the combat log, health and damage amounts from addons, so crits, heal crits, crits taken, dodges and kill streaks are driven by `UNIT_COMBAT` and target-death checks; “Finish Him” fires when a mob flees in fear. Overkill, crit gap and the Finish Him health threshold are hidden on this client.

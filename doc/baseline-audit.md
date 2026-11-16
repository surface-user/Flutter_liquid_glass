# LIB-00：下一阶段开发基线核查

核查日期：2026-11-16。状态：REVIEW。本次只记录实际版本、复用边界和待决策项，不实现新组件。已依次读取当前 main 的 Agent 规范、任务和设计文档；两名子 Agent 分别只读核查 PR 链和接口准备度，由主 Agent 交叉复核。

## 固定版本与工作区

| 对象 | 核查结果 |
| --- | --- |
| 远端 main | `4842bea87992f4826b0113f8735d0e3dc558a620`，已合并 [#27](https://github.com/surface-user/Flutter_liquid_glass/pull/27)；相对 `a0bc51a` 仅增加新文档，没有带入旧实现 |
| 原工作区 | `codex/fix-five-contract-bugs` / `ac0028eacd0e1ee22747d454c04a456dcb307377`；未切换、重置或修改已有文件 |
| 原未跟踪内容 | `doc/component-lab-reference.md` 和两处 `test/failures/`，共1份文档、12张图片；记录 SHA256，交付前再次比较 |
| 本次分支 | `codex/lib-00-baseline-audit`，从上述 main 建立；工作树位于原仓库忽略的 `build/agent-worktrees/lib-00-baseline` |
| 工具 | 本机可找到 Flutter/Dart；没有 GitHub CLI。终端普通沙箱网络访问失败，允许的提升执行完成 `git fetch origin`，远端内容/PR 通过 GitHub connector 交叉核对 |

保留原工作区的含义包括保留未跟踪失败图片，而不是将其纳入新 PR。历史图片存在不能证明当前测试失败。此工作树可用于后续独立任务的基线参考，但仍是文档分支，不是已验收的代码集成基底。

## 原有 PR 链与检查

| PR | head | base | 查询时状态 |
| --- | --- | --- | --- |
| [#1](https://github.com/surface-user/Flutter_liquid_glass/pull/1) | `fdd5656` | main | 开放草稿 |
| [#2](https://github.com/surface-user/Flutter_liquid_glass/pull/2) | `17126f0` | #1 分支 | 开放草稿 |
| [#3](https://github.com/surface-user/Flutter_liquid_glass/pull/3) | `d0a1954` | #2 分支 | 开放草稿 |
| [#4](https://github.com/surface-user/Flutter_liquid_glass/pull/4) | `ac0028e` | #3 分支 | 开放草稿 |
| [#26](https://github.com/surface-user/Flutter_liquid_glass/pull/26) | `dece8ed` | #4 分支 | 开放草稿，仅新增任务计划 |
| [#27](https://github.com/surface-user/Flutter_liquid_glass/pull/27) | `8c136ee` | main | 已合并，merge 为 `4842bea` |

本次回读 #4 精确 head 的 [CI](https://github.com/surface-user/Flutter_liquid_glass/actions/runs/43008576778) 与 [依赖审查](https://github.com/surface-user/Flutter_liquid_glass/actions/runs/43008576765)，以及 #26 精确 head 的 [CI](https://github.com/surface-user/Flutter_liquid_glass/actions/runs/43818015702) 与 [依赖审查](https://github.com/surface-user/Flutter_liquid_glass/actions/runs/43818015704)，均为 success。这些是旧 head 的检查结果，不是本次本地复验或后续集成结果。#1/#2/#3/#4/#26 查询时均无已提交 review；非作者批准尚未取得。

开放 PR 共26个：#1–#4 是库实现链，#5–#19 是网站工作，#20–#24 是研究，#25 是网站计划，#26 是已由 #27 修订移植的库计划。未发现独立的 LIB-00 实施 PR；本轮不关闭、重定向、合并或评论这些旧 PR。

## 差异与保留规则

- main 与 #4 的共同祖先为 `a0bc51a`；#4 独有21提交，main 独有2提交。
- 两端实际差异 `git diff 4842bea ac0028e` 为111个路径、增加8094行/删除1303行：doc 20、lib 29、test 30、example 18、其他14。GitHub 三点比较从共同祖先计算，为109路径，不能用它替代两端差异。
- #27 的20份文档与 #4 均有两端差异。整树覆盖会删除 `doc/README.md`、回退 `doc/DEPLOYMENT.md` 并恢复旧依赖禁令；必须保留新方向、依赖准入及历史/当前事实分界。实际接入旧代码后再准确更新“main 尚无”的能力描述。
- #4 到 #26 仅 `doc/task.md` 有变化，lib/test/example/pubspec/CI 没有新增代码；#26 的计划已由 #27 校正进入主线，不再整提交移植 #26。
- #4 没有第三方 UI 运行依赖或核心 SDK 下限变动。pubspec 增加仓库元数据，example 增加 SDK integration_test 开发依赖，另有夹具发布排除；这些也应随代码复用逐项检查。

## 已有能力与真实缺口

| 范围 | main 当前事实 | 复用/后续边界 |
| --- | --- | --- |
| 模块与导出 | lib/src 6实现文件、20公开声明；theme/motion 仍循环导入 | #4 共26个 lib Dart 文件（含入口）、26公开声明；优先复用拆层与原公开消费/架构测试 |
| 主题/密度 | 局部整体替换，无 merge/GlassLayout/状态主题 | #4 已有对应实现及失败回归，不能重复实现或称已进入 main |
| 普通/玻璃材质 | 关闭模糊时使用不透明 fallback；enabled=false 保留内容/布局/裁剪并关闭装饰 | [main surface](https://github.com/surface-user/Flutter_liquid_glass/blob/4842bea87992f4826b0113f8735d0e3dc558a620/lib/src/surface.dart#L42)；关闭模糊不等于通用透明材质，LIB-04 仍需真实合同 |
| 输入/表单 | main 无文本控件；#4 只有基础 GlassTextField | [#4 输入](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/lib/src/components/inputs/glass_text_field.dart#L6) 不等于密码、多行或完整 FormField；先比较 SDK 配方，不预建包装 |
| 弹窗动效 | showGlassDialog 只把 duration 传给 SDK；页面路由消费正反时长 | [main 弹窗](https://github.com/surface-user/Flutter_liquid_glass/blob/4842bea87992f4826b0113f8735d0e3dc558a620/lib/src/components.dart#L226)；reverseDuration 缺口保留给 LIB-08，失败回归后处理 |
| 导航/菜单/消费者 | main 无 #4 五个桌面控件 | 复用 [#4 消费者](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/example/integration_test/fixtures/desktop_consumer.dart)，不将其算作完整首版流程 |
| SDK/包 | 0.1.0，Dart >=3.12、Flutter >=3.44，仅 Flutter 运行依赖 | 保留现状；第三方具体采用、最低版运行和资源许可仍需 LIB-01/02 决策/实测 |

## 下一实现基底与依赖调度

独立任务以 `4842bea` 为当前基底；开工前再次检查 main 是否前进。依赖旧实现的任务沿 #1→#2→#3→#4 复用原代码和回归，不重新开发一套，也不将整个旧链改指 main 后宣称小改动。

需要 #4 API 时，先在隔离工作树准备“既有代码＋main 新规范”的集成方案，逐项处理上述差异；代码/测试及必要 CI 一起验证，文档只按真实实现更新。可以继续独立准备，不强制先合并旧 PR；具体复用范围随首批流程冻结，审查/合并保持独立。此文档 PR 不执行该集成。

目前可以并行：只读 PR/版本核查、接口/消费者核查。两者已完成并交叉复核。LIB-01 的首版范围与 LIB-03 合同等待产品答复；LIB-02 须等依赖策略，LIB-04 须等合同；LIB-05/06/07/10 仅在前置验收、文件所有权明确后才可并行。共享主题、入口和 Flutter 命令仍串行。

## 待产品答复与验证边界

已在主对话询问目标应用/首验平台、第一条交付流程、第三方策略、通用命名与 Glass API 共存。所有选项仍待答复，建议不算已选定；后续问题随具体取舍继续在主对话提出。普通 UI 的视觉语言（Material 主题定制或项目中性视觉）也需在 LIB-01/03 明确。

本次仅做 Git/PR/源码与文档静态核查。4份变更文档的 UTF-8、138处链接（含4处固定源码及行号）、16个表格、围栏/冲突标记检查通过；102项文件库存一致，19项任务编号唯一且仅 LIB-00 为 REVIEW，原历史正文未变。原工作区仍在旧分支，13个原未跟踪文件 SHA256 均未变；子 Agent 只读复核未发现必要修订，这不等于 GitHub 非作者批准。

没有运行 Flutter 分析、测试、Golden、构建、发布预检或第三方消费者；不借旧 head 结果宣称通过。物理 IME、读屏、Android 真机/校准及其他平台仍按 [原任务账本](task.md) 和 [验证记录](testing.md) 待验。

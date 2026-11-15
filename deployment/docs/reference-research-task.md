# Flutter 项目独立调研任务

日期：2026-11-15。只写 deployment/docs 文档，不改代码、不构建/发布网站。每个项目独立报告，主Agent另作定位综合判断。

## 方法与隔离

四个研究任务均使用 fork_turns=none 新建子代理，不传主对话、已有结论或目标产品定位；禁止读取用户记忆、本地产品分析及其他代理报告。统一按项目自身目标研究界面组织、交互、效果展示、接口、局限与证据。代理完成后由主Agent核对源码证据，再作迁移建议。报告标明日期、固定提交、范围、源码事实/文档宣称/推断/运行未验；不以README当完整分析，不以技术栈推断平台一致性。

同时最多3名子代理，第四个任务待名额释放启动。各自只写自己报告；报告自带IN_PROGRESS/REVIEW字段，主Agent维护本账本避免共享文件冲突。

| 编号 | 项目 | 状态 | 依赖 | 文件 |
| --- | --- | --- | --- | --- |
| REF-A | AppFlowy | DONE | 无 | appflowy-independent-analysis.md |
| REF-F | fluent_ui | DONE | 无 | fluent-ui-independent-analysis.md |
| REF-S | shadcn_flutter | DONE | 无 | shadcn-flutter-independent-analysis.md |
| REF-P | Appainter | DONE | 名额已释放 | appainter-independent-analysis.md |
| REF-M | 主Agent综合 | DONE | 四份报告已REVIEW且关键证据复核完成 | flutter-reference-synthesis.md |

验收：每份有实际源码路径与固定提交链接、导航/弹窗完整调用链、可见交互与状态归属、动画配置/无障碍核查、界面展示如何关联代码、导出真实边界、许可证与未验范围；主Agent区别完整产品/组件库/主题工具，避免按统一产品目标打分。每项独立PR，CI/非作者审查与本地文档验收分别记录。

四份代理报告保留其原始REVIEW标记；主Agent已完成关键固定源码抽查与文档检查，上表DONE表示研究文档及独立PR交付完成，不表示第三方应用、测试、无障碍或性能通过。

| 项目 | 独立PR | 依赖 |
| --- | --- | --- |
| AppFlowy | [#20](https://github.com/surface-user/Flutter_liquid_glass/pull/20) | 原预览修复分支，未合并 |
| fluent_ui | [#21](https://github.com/surface-user/Flutter_liquid_glass/pull/21) | #20 |
| shadcn_flutter | [#22](https://github.com/surface-user/Flutter_liquid_glass/pull/22) | #21 |
| Appainter | [#23](https://github.com/surface-user/Flutter_liquid_glass/pull/23) | #22 |
| 主Agent综合 | [#24](https://github.com/surface-user/Flutter_liquid_glass/pull/24) | #23 |

PR采用叠加分支，每项差异独立；全部保持草稿，等待非作者审查，不合并，不更新站点。

## 主Agent验收

- 四个任务均fork_turns=none；Appainter另披露读过治理入口doc/AGENTS.md，没有读取定位/差距/记忆/其他报告。研究结论与针对本项目的建议分开。
- 主Agent重取AppFlowy 3段、fluent_ui 3段、shadcn 4段、Appainter 4段固定源码进行关键声明抽查；不是全仓重审。完整范围及限制见综合报告第12节。
- 七份新Markdown的UTF-8、围栏、相对链接、空白与固定版本引用检查通过；5张公开示例截图已实际查看。
- 本库/快照64个受保护文件散列不变；外层原有3项未跟踪内容保留；实验台源码仓库干净且HEAD仍aec7835d7ecca1a1198592f6a24d81e9d9f1c217。
- 没有改任何应用代码、源库、快照、依赖或构建配置；没有运行Flutter或第三方测试/构建，没有发布。
- CI与文档验收分开：研究PR仍可能在根库发布校验遇到被.gitignore忽略的已跟踪deployment文件，exit65。保留失败，不改根配置绕过；各最终头状态以PR和后续附录记录为准。

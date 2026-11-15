# Flutter 项目独立调研任务

日期：2026-11-15。只写 deployment/docs 文档，不改代码、不构建/发布网站。每个项目独立报告，主Agent另作定位综合判断。

## 方法与隔离

四个研究任务均使用 fork_turns=none 新建子代理，不传主对话、已有结论或目标产品定位；禁止读取用户记忆、本地产品分析及其他代理报告。统一按项目自身目标研究界面组织、交互、效果展示、接口、局限与证据。代理完成后由主Agent核对源码证据，再作迁移建议。报告标明日期、固定提交、范围、源码事实/文档宣称/推断/运行未验；不以README当完整分析，不以技术栈推断平台一致性。

同时最多3名子代理，第四个任务待名额释放启动。各自只写自己报告；报告自带IN_PROGRESS/REVIEW字段，主Agent维护本账本避免共享文件冲突。

| 编号 | 项目 | 状态 | 依赖 | 文件 |
| --- | --- | --- | --- | --- |
| REF-A | AppFlowy | REVIEW | 无 | appflowy-independent-analysis.md |
| REF-F | fluent_ui | REVIEW | 无 | fluent-ui-independent-analysis.md |
| REF-S | shadcn_flutter | REVIEW | 无 | shadcn-flutter-independent-analysis.md |
| REF-P | Appainter | REVIEW | 名额已释放 | appainter-independent-analysis.md |
| REF-M | 主Agent综合 | REVIEW | 四份报告已REVIEW且关键证据复核完成 | flutter-reference-synthesis.md |

验收：每份有实际源码路径与固定提交链接、导航/弹窗完整调用链、可见交互与状态归属、动画配置/无障碍核查、界面展示如何关联代码、导出真实边界、许可证与未验范围；主Agent区别完整产品/组件库/主题工具，避免按统一产品目标打分。每项独立PR，CI/非作者审查与本地文档验收分别记录。

前三份独立报告已由代理完成并置REVIEW；主Agent正在按固定源码抽查。AppFlowy已交付PR #20、fluent_ui已交付PR #21，PR与CI状态单独记录。

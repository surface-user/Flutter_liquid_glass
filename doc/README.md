# 开发文档入口

更新日期：2026-11-16。目标是通用 Flutter UI 组件库：优先建设可组合的组件与清晰接口，玻璃是可选材质；组件库可用后，再建设可视化设计台，生成供用户 Agent 还原界面的提示词。

## 版本与事实边界

| 层次 | 固定版本与状态 | 使用方式 |
| --- | --- | --- |
| 本次主线基底 | main `a0bc51acf22db1b867294f810157cfeba7e951fb` | 6 个实现文件、20 个公开声明；SDK-only 玻璃实现 |
| 未合并实现 | [#4](https://github.com/surface-user/Flutter_liquid_glass/pull/4)，`ac0028eacd0e1ee22747d454c04a456dcb307377` | 模块化、主题/密度及桌面控件；不在本 PR 中引入 |
| 计划来源 | [#26](https://github.com/surface-user/Flutter_liquid_glass/pull/26)，`dece8ed43040bde104a5608e576035a7c7c33b26`，base 为 #4 源分支 | 移植文档并校正主线边界；LIB/WEB 任务未实施 |

#26 相对上述 main 有 22 个提交、109 个文件差异。本 PR 从 main 独立提交，只修改 doc/，没有合入前序实现、测试、CI 或网站。后续实现须复核当时最新 main/PR；这里的固定版本不是持续更新的分支状态。

## 产品要求

- 首版覆盖操作、表单、选择、导航、浮层、布局、反馈与必要动效；精确变体和支持平台在任务中冻结。
- 选择顺序为已有实现、SDK 组合/主题、第三方直接使用、必要适配、最小自研。不机械包装所有控件，不以类型数量作为完成标准。
- 第三方 UI 依赖可以评估采用；准入须核查固定版本、许可证及传递依赖/资产、SDK、宿主/主题、平台、维护和体积。具体包尚未获准接入。
- 普通 UI 可以独立使用；关闭玻璃、动画或透明度仍保持可读与操作能力。业务状态、页面缓存、查询和持久化由应用负责。
- 设计台、提示词生成和真实还原验证在组件库验收后开展；本轮只改文档。

## 阅读顺序与文档索引

| 文档 | 用途与适用范围 |
| --- | --- |
| [AGENTS.md](AGENTS.md) | 当前开发规则和最小验证矩阵 |
| [task.md](task.md) | LIB/WEB 计划；后半为明确标记的未合并实现历史 |
| [architecture.md](architecture.md) | main 实际依赖与后续模块/适配边界 |
| [component-catalog.md](component-catalog.md) | 主线、#4 与计划能力对照 |
| [api.md](api.md) | main API 与 #4 增量的分界 |
| [design-system.md](design-system.md) | 主题、材质、密度与兼容要求 |
| [getting-started.md](getting-started.md) | main 可用的最小接入代码 |
| [ANIMATION_SPEC.md](ANIMATION_SPEC.md) | 通用动效及玻璃专属约束，建议参数不是实现证明 |
| [studyworkbench-integration.md](studyworkbench-integration.md) | 应用接入前提；没有修改或验收该应用 |
| [WORKFLOW.md](WORKFLOW.md) | 独立 PR、依赖链与实际 CI 边界 |
| [REVIEW_CHECKLIST.md](REVIEW_CHECKLIST.md) | 组件/适配、无障碍与验证审查 |
| [RELEASE.md](RELEASE.md) | 版本、依赖声明与维护者发布流程 |
| [ANDROID_PROFILE.md](ANDROID_PROFILE.md) | 真机性能验收；自动夹具仅在未合并分支 |
| [testing.md](testing.md) | 当前复现方法与 #4 历史验证账本 |
| [function-verification.md](function-verification.md) | #4 逐函数证据归档，源码链接固定至该提交 |
| [interaction-history.md](interaction-history.md) | 旧交互任务原始历史，不产生当前授权 |
| [VERIFICATION.md](VERIFICATION.md) | main 原有 2026-09-17 验证记录，非本轮通过证据 |
| [DEPLOYMENT.md](DEPLOYMENT.md) | 旧站点记录及后续设计台边界 |
| [FILES.txt](FILES.txt) | main 基底加本轮 doc/ 的文件库存，不列未合并源码 |

## doc/ 外的待同步项

main 没有根 AGENTS.md；#4 中的根入口只指向 doc/，未设置另一套产品定位。main 的 README、公开入口说明和 pubspec 描述仍聚焦轻量玻璃库，这是实际代码/包的旧定位，不能当成后续禁用第三方 UI 的规则。本轮按授权不修改 doc/ 外文件；实际通用 API 交付时同步它们、CHANGELOG 和必要示例。#4 的根入口、CI 和 PR 模板也没有随这次文档迁移进入 main。

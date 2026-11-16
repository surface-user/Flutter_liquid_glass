# Agent 开发规范

## 项目目标

维护通用 Flutter UI 组件库与清晰、可组合的公开接口，玻璃是可选特色材质。先交付库和独立消费者，再开展可视化设计台及供用户 Agent 还原界面的提示词。当前包名及公共入口 `lib/lightweight_liquid_glass.dart` 保持；新增命名、包拆分和 SDK 变化须有具体方案。

版本事实先读 [文档入口](README.md)：main 不含 #4 的模块化、merge/密度与五个桌面控件。历史已实现不等于 main 已有，计划不等于实现或新的开发授权。

## 开始任务前

1. 阅读本文件、[task.md](task.md) 和相关设计文档；若目标分支存在根 AGENTS.md，也先读取。main 当前没有该根入口。
2. 核对实际实现、调用方、导出、测试、示例、README、依赖和 SDK，不从未合并文档推断能力。
3. 执行 `git status --short` 并保留原有修改；需要切换基线时使用隔离分支/工作树。
4. 从明确基底建立 `codex/<task-id>-<slug>`；独立改动以 main 为 base，依赖链须说明，不能混入未授权提交。
5. 确认范围、依赖和验收；先选择已有能力或 SDK 组合，必要时才新增公开 API。

## 依赖与适配准入

允许经过评估的第三方 Flutter UI 依赖，不再一律禁止。采用前在对应任务记录：

- 固定发布版本/源码、许可证及具体复用文件、传递依赖和字体/图标/图片等资源的声明义务；不以根许可证替代逐项核查。
- 最低 Dart/Flutter、依赖解算、目标平台与渲染后端、宿主/主题/localization/Overlay、控制器所有权和减少动画的实际消费者验证。
- 维护活跃度、升级/退出路径、包体与运行成本，以及相对 SDK/现有组件的真实收益。
- 采用、延期或拒绝的依据。参考项目不是已批准依赖；本次不添加任何包或抬高 SDK。

默认核心保持 Flutter 原生、无业务耦合。第三方框架依赖优先隔离为可选适配；单包还是独立包在 LIB-01/02 决定，不能声称 Dart 的条件导出会使 pubspec 中的依赖成为可选。消费者可直接使用成熟组件；只为真实主题、值/事件、焦点、生命周期或兼容缺口做适配，不统一重导出整个第三方 API。

## 不可破坏的约束

- 玻璃核心用 Flutter/Dart 原生渲染；不将 Kotlin UI、Compose、PlatformView 或 TypeScript 运行时引入玻璃核心。候选插件的原生平台部分单独核查，不以此全面禁止 Flutter 第三方 UI。
- 不复制反编译代码；只参考公开行为/规范或许可证兼容且已核查的源码。
- 不持续动画 blur sigma；非必要循环默认关闭，空闲或隐藏时不留无意义 ticker。
- 动画遵循 disableAnimations、accessibleNavigation、主题 reduceMotion/enableAnimations；新适配验证其实际消费，保留焦点与最终状态。
- 重叠/嵌套过滤不错误共享 backdrop key；裁剪有界。高对比、减少透明和关闭模糊仍可读可操作。
- Android 真机是性能证据来源之一；Windows 兼容检查、widget 测试、Web 构建不代替设备测量。未验平台明确标注。
- 组件不包含业务身份/文案/状态、网络查询、页面缓存或持久化。外部 controller/FocusNode 由调用方释放。

## 实现与兼容

- 优先现有实现或 SDK；新 API 要有参数消费点、默认/null、受控值/回调、所有权、取消/卸载与不支持项。
- 新 API 同步 Dart 文档、可编译公开入口示例、必要测试、README 和 CHANGELOG。兼容旧 Glass API 与默认视觉，破坏性变更另定迁移/版本。
- 状态覆盖按实际组件选择 idle/hover/focus/pressed/disabled/selected/error/loading/readOnly 等，不凭空增加字段。
- 动画优先 repaint，避免每帧 layout/build；不预建未来抽象或空适配包。
- 目标边界是 components → theme → core 配置/渲染；main 当前尚未拆层，不把目标当成已有检查。第三方适配不能反向污染 core。
- 不更新 Golden 掩盖失败，不清除历史失败图片/日志；历史记录不产生新的授权或通过结论。

## 最小验证矩阵

| 修改范围 | 必须执行 |
| --- | --- |
| 文档 | UTF-8、相对链接/锚点、表格/围栏、实际分支/API/命令一致性、diff 范围 |
| Dart 实现 | 对实际存在目录运行 dart format；flutter analyze；相关消费者和回归 |
| 样式/状态 | style/widget 与相关契约测试；主线尚无的测试先随实现补齐 |
| 示例交互 | example 的 widget 测试 |
| 视觉 | 相关根/example Golden，并人工查看差异 |
| Web | example 的 Web release 构建及涉及的实际交互 |
| 第三方接入 | 解算、独立消费者、宿主/主题/平台/无障碍/包体与许可核对 |
| 发布相关 | flutter pub publish --dry-run |

具体命令和当前/历史测试分界见 [testing.md](testing.md)。

## PR 交付

更新任务状态及证据；提交小而完整的 Conventional Commit；推送 codex/** 并创建指定 base 的 PR。目标分支有 PR 模板时使用，没有时按 [WORKFLOW.md](WORKFLOW.md) 填写问题、改动、API/视觉、验证、风险和未验项。检查当前 head 的 CI，不继承历史绿灯。

PR 合并前至少一名非作者批准并满足适用检查；仓库配置和建议流程分开报告。本任务只创建 PR，不合并、不发布。后续合并/发布按当次用户授权及验收执行。

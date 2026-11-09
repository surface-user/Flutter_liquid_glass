# Agent 开发规范

## 项目目标

维护一个纯 Flutter、无业务耦合、无第三方 UI 运行时依赖的轻量玻璃组件库。所有公开接口从 `lib/lightweight_liquid_glass.dart` 导出。

## 开始任务前

1. 阅读根目录 `AGENTS.md`、本文件和 `doc/TASK.md`。
2. 阅读任务会触及的实现、调用方、测试、示例和 README。
3. 执行 `git status --short`，保留用户已有修改。
4. 从 `codex/<task-id>-<slug>` 分支开展工作；不要直接向 `main` 提交。
5. 在 `doc/TASK.md` 中确认任务范围和验收标准，不擅自扩大公开 API。

## 不可破坏的约束

- 玻璃渲染必须使用 Flutter / Dart 原生能力。
- 不引入 Kotlin UI、Compose、PlatformView、TypeScript 运行时或第三方 UI 依赖。
- 不复制反编译代码；只允许参考公开行为、公开规范或许可证兼容的源码。
- 不持续动画 `blurSigmaX` / `blurSigmaY`。交互动画优先使用透明度、位移、轻微缩放、边框和高光。
- 所有动画必须遵循 `MediaQuery.disableAnimations`、`accessibleNavigation`、主题 `reduceMotion` 和 `enableAnimations`。
- Android 是首要性能目标；空闲状态不得保留无意义的 ticker。
- `GlassGroup` 中重叠元素不得共享 backdrop key。
- 高对比度、减少透明度和关闭模糊时必须保持内容可读、可操作。
- 不加入具体业务类型、业务文案或业务状态。

## 代码规则

- 优先修改已有组件；只有现有 API 无法表达需求时才新增公开类型。
- 新公开 API 必须有 Dart 文档、README 示例、测试和 `CHANGELOG.md` 记录。
- 交互状态必须覆盖 idle、hover、focus、pressed、disabled 和 reduce-motion。
- 动画绘制优先通过 `Listenable` 直接触发 repaint，避免每帧 build/layout。
- 不为未来需求预留抽象、配置或依赖。
- Golden 只在确认视觉变化正确后更新，不用更新基准掩盖失败。

## 最小验证矩阵

| 修改范围 | 必须执行 |
| --- | --- |
| 文档 | 检查链接、代码块和与实际 API 的一致性 |
| Dart 实现 | `dart format --output=none --set-exit-if-changed lib test example/lib example/test`、`flutter analyze` |
| 样式/状态逻辑 | 根目录 `flutter test test/style_test.dart test/widget_test.dart` |
| 示例交互 | `cd example && flutter test test/widget_test.dart` |
| 视觉变化 | 根目录和 example 的 golden 测试，并人工查看差异 |
| Web 行为 | `cd example && flutter build web --release` |
| 发布相关 | `flutter pub publish --dry-run` |

## PR 交付

Agent 完成任务后应：

1. 更新 `doc/TASK.md` 的状态和验证记录。
2. 提交小而完整的 commit，使用 Conventional Commits。
3. 推送 `codex/**` 分支。
4. 使用 `.github/pull_request_template.md` 填写 PR。
5. 创建 PR 后等待 CI；自动合并仅在用户已授权、必需 CI 全通过且非作者审查者批准后执行，不得绕过失败检查。
6. 报告公开 API、视觉、性能、无障碍和兼容性影响。

PR 必须至少由一名非作者审查者批准。分支保护的具体设置见 `doc/WORKFLOW.md`。

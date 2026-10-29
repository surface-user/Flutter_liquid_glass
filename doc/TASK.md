# 当前开发任务：交互式玻璃动画

## 状态

`in_progress`

## 目标

让玻璃组件在按压、悬停和键盘焦点时产生明确但克制的响应感，同时保持纯 Flutter、低空闲开销、Android 优先和现有降级能力。

## 第一阶段范围

- `GlassButton`、`GlassIconButton` 和带 `onTap` 的 `GlassCard` 增加按压与释放反馈。
- Web / Desktop 增加 hover，键盘操作增加 focus 反馈。
- 使用缩放、1–2px 位移、着色、阴影和边缘高光表达状态。
- 动画控制器只在状态变化时运行；空闲后停止。
- disabled 状态不执行交互动画。
- reduce-motion 下立即切换或仅保留无位移的状态提示。
- 示例页展示 idle、hover、focus、pressed、disabled 和 reduce-motion。

## 实现顺序

- [x] 记录现有按钮、卡片和表面的调用关系及测试覆盖。
- [x] 先在现有交互组件内部实现共享的私有交互逻辑。
- [x] 验证私有逻辑能覆盖常用组件，再决定是否需要公开 `InteractiveGlassSurface`。
- [x] 添加按压、悬停、焦点和禁用状态测试。
- [x] 添加 reduce-motion 和 `enableAnimations: false` 测试。
- [ ] 更新示例和 golden，人工检查文字、边缘和裁剪。
- [ ] 在 Android profile 模式记录空闲与交互帧时间。
- [x] 更新 README、CHANGELOG 和验证记录。

## 验收标准

- 按下时目标缩放为 0.98 左右，垂直位移不超过 2px；释放后恢复。
- hover 最大缩放不超过 1.01，不能造成相邻布局抖动。
- 键盘焦点有不依赖颜色的清晰边缘提示。
- 不动画模糊半径，不改变组件布局尺寸。
- 空闲状态没有运行中的交互 ticker。
- 关闭动画和系统减少动画设置生效。
- 所有现有测试继续通过；新增交互测试和视觉基准通过。
- 不增加第三方运行时依赖。

## 后续阶段

### 指针高光

记录局部指针位置，通过 `CustomPainter` 调整径向高光和边缘亮度。优先直接 repaint，不触发布局。

### 通用交互表面

只有现有组件无法满足“任意 Widget 可交互”时，才增加公开接口。新增前必须比较扩展 `GlassSurface`、命名构造函数和独立组件的 API 成本。

### 可选折射 Shader

作为实验性高质量能力单独设计。仅在支持的 Impeller 场景启用，必须提供当前 `BackdropFilter` 降级路径，并完成 Android 真机 profile。第一阶段不包含 Shader。

## 非目标

- 不实现持续漂浮、永久流光或循环改变模糊半径。
- 不接入原生 Kotlin/Compose 动画层。
- 不移植 TypeScript 运行时。
- 不使用反编译实现。
- 不自动合并 PR。

## 完成记录

实现 Agent 在此填写：分支、PR、公开 API 变化、执行的检查、性能数据和仍存在的限制。

### 2026-10-29 本地实现

- 分支：`codex/phase1-glass-interaction`；尚未创建 PR。
- 调用关系：GlassIconButton → GlassButton → 私有 _GlassInteraction → GlassSurface；带 onTap 的 GlassCard 复用同一实现，无回调卡片保持静态。公开导出、依赖及 API 不变。
- 复用 InkWell 的指针、取消、焦点、键盘和语义行为；按压缩放 .98 / 下移 1.5px，悬停最多 1.01，焦点加粗边缘。TweenAnimationBuilder 仅重建变换，surface 作为 child 缓存；动画结束不再 tick，模糊参数固定。为可能重叠的交互表面隔离 backdrop 输入。
- 示例保留现有启用、禁用和 Reduce motion 控件，增加操作提示；新增四个独立交互 golden。原有 disabled 指针/键盘测试保留，新增取消恢复、空闲 ticker、卡片与焦点及四种减少动画来源测试。
- 静态分析、格式、根目录全部 33 项测试和示例 widget 测试通过。新增 4 项交互 golden 已人工逐一查看并独立复验通过。
- 示例 gallery golden 在 1280/390 light 存在 699/704 像素差异（0.03%/0.18%）；已用 HEAD 原始 components.dart 复测，差异数量完全相同。人工检查差异集中于标签边框，未更新旧基准；dark/dialog 后续断言被前面的 light 失败阻断。
- 无 Android 设备连接，仅 Windows/Edge，尚无 Android profile 空闲/交互帧时间数据，不能宣称完成性能验收。
- 待完成：修复或确认既有 gallery 基准差异、完整示例视觉验收、Android 真机 profile、提交与经授权后的 PR 流程。工作区原有文档和配置修改保留。

### 缺陷 GLASS-001：动态减少动画后按压状态残留

- 严重程度：P2，交互与无障碍状态恢复缺陷；修复及回归通过前阻止进入下一步。
- 发现方式：独立 Flutter widget 黑盒测试，22 项中 18 通过、4 失败；不能因多数通过将任务标记完成。整体状态保持 `in_progress`。
- 复现步骤：触摸按下 GlassButton → 推进 20ms → 开启一种减少动画设置 → 松开触摸 → 恢复动画设置 → 等待动画结束。
- 设置分别为 MediaQuery.disableAnimations、MediaQuery.accessibleNavigation、主题 accessibility.reduceMotion、performance.enableAnimations: false，四者分别复现。
- 期望：减少动画立即取消缩放和位移；松开后恢复动画也应保持 idle，布局不变，空闲无交互 ticker。
- 实际：恢复动画后停留在 .98 倍缩放、下移 1.5px；内容原 Rect(350,280,450,320) 变成 Rect(351,281.9,449,321.1)。
- 对应回归：`test/black_box_interaction_test.dart` 中 `reduced motion 1..4 switches during press and restores idle` 四个用例，保留原始事件和断言，不跳过、不改成预期失败。
- 状态：已修复并通过缺陷回归；第一阶段整体仍为 `in_progress`。
- 根因与修复：切换减少动画时替换子树，切断 InkWell 手势清理；保持动画与交互子树稳定，减少动画/禁用采用零时长恒等变换，并忽略禁用或重复的 highlight 回调。
- 原四个失败黑盒用例事件和断言未改；原内部测试改为检查变换恒等，继续验证无缩放、无位移。
- 验证：黑盒 22/22、全部根测试 55/55（含 golden）、格式、flutter analyze、Dart analyze 通过。示例交互与大字体通过；两项 light golden 仍有既有 699/704px 差异，未改基准，完整视觉验收仍未通过。Android 真机 profile 未完成。
- GitHub 查询当前分支无开放 PR，因此尚无 Request changes、复审或合并对象。自动审批拒绝远程推送：具体 GitHub 目的地未获明确授权；代码与测试保留本地，待用户授权。
- 本次交付流程：若已有 PR，在原 PR 具体代码处记录问题并由审查者 Request changes；修复推至同一分支，CI 重跑、复审通过并解决讨论。用户本次授权 Agent 在 required CI 全通过且非作者审查者批准后自动合并，不绕过保护规则；此授权覆盖此前文档的“不自动合并”限制。无 PR 时不伪造审查或批准。

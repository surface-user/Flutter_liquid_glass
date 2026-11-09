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
- [x] 更新示例和 golden，人工检查文字、边缘和裁剪。
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
- 不绕过 CI、未完成验收或非作者批准要求合并 PR；用户已授权满足条件后由 Agent 合并。

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

### 视觉验收与 CI 补齐

- 当前本地 SDK 为 Flutter 3.47.1 / Dart 3.13.1；旧验证文档及待提交 CI 固定 3.44.4，版本不一致。未安装旧 SDK 做双版本因果验证，不能断言差异完全由版本造成。
- 先把六张完整示例截图输出到 example/build/visual-review，再与旧图逐张并排检查；差异仅位于标签圆角边缘，未发现文字、布局或裁剪变化。移动端 dialog 完全相同；其余五张分别为 689、704、699、697、704 个差异像素。
- 在确认新视觉可接受后，将示例基准迁移到本地 3.47.1，并同步 CI 版本，未提高像素容差或跳过测试。复核图：build/gallery-review.png（本地忽略产物）。
- CI 显式加入黑盒回归和交互 golden，避免仅执行原文件而漏测本次缺陷。
- 重新检测仅 Windows/Edge，无 Android 设备或模拟器。Android profile 帧时间必须由真实运行采集，不以 widget 测试、Web 构建或 Windows 数据替代；整体仍为 in_progress。

- Android 实测步骤与采样字段已整理到 [ANDROID_PROFILE.md](ANDROID_PROFILE.md)，无设备时不填写或推断性能数据。

- 最终复验：根 55/55、示例 4/4（全部六张示例图比较通过）、格式检查、flutter analyze 通过；Web release 构建成功。pub publish --dry-run 校验约 111KB 包后因工作区未提交文件返回 1（1 个 dirty Git 警告），不是发布成功，也未上传。
- 第一阶段待办收敛为 Android 真机 profile 和远程交付/非作者审查。未继续后续指针高光或 Shader 阶段，未重试此前被拒绝的推送。CI 配置已本地补齐，但尚无远程运行证据。

### 2026-11-10 持续推进：自动性能采样

- 重新检测仍仅 Windows/Edge，没有 Android 设备或配置的模拟器；只安装了缺少 source.properties 的 NDK 目录。当前分支仍无 PR（GitHub 只读查询）。Android 性能项继续未勾选，整体仍 in_progress。
- 增加 example/integration_test/glass_performance_test.dart 与 test_driver/performance.dart：仅允许 Android profile，四种降级模式各采样 10 秒空闲及约 30 秒真实引擎交互帧。用稳定的三组件夹具，空闲不 pump；报告包含原始数据、刷新率、p50/p95/max 和超预算帧数。没有设备时不生成性能报告。
- 为统计计算增加 example/test/frame_metrics_test.dart，覆盖空帧 null、nearest-rank、流水线配对超预算计数、输入不变及无效数据拒绝。Flutter SDK integration_test 仅为示例开发依赖，没有新增库运行时依赖或公开 API。
- CI 加入统计单测及新目录格式检查。采样入口与报告说明见 ANDROID_PROFILE.md；真正 Android 数据、完整 APK 与设备校准仍待接入硬件。

- 2026-11-10 最终校验：根测试 55/55、示例测试 7/7、19 个文件格式检查、flutter analyze、Dart analyze、Web release 构建均通过。Android profile build bundle 资源打包通过，并额外用 `flutter assemble --output=build/profile_compile_check -dTargetPlatform=android-arm64 -dBuildMode=profile -dTargetFile=integration_test/glass_performance_test.dart kernel_snapshot_program` 验证测试入口 Dart kernel 编译通过；不是完整 APK/AOT 验收，也没有真机运行数据。CI 已加入该编译步骤。
- 等待外部输入：已请求接入可调试的 Android 真机，以及明确授权向 origin GitHub 仓库推送并创建 PR。用户未答复前不重试被拒绝的推送、不伪造设备记录或审查批准。当前可独立完成的采样准备已完成，任务不能标注全部完成。

### 2026-11-10 后续实现与交付授权

- 用户确认当前无可用真机，要求先集中完成实现、稍后统一设备验证；允许 Android Studio 模拟器做功能验证，但不将模拟器结果写为真机性能。Android profile 待办保留。
- 用户已明确授权向 https://github.com/surface-user/Flutter_liquid_glass.git 推送当前分支并创建 PR；此前远程授权阻塞已解除。
- [x] 指针高光：三类组件共享私有径向边缘 painter，ValueNotifier 直接 repaint，无指针位置 setState，无布局或模糊参数变化；退出清除，dispose 释放。禁用、减少动画、高对比度、减少透明度和 low 质量关闭该效果。
- [x] 通用表面评估：GlassCard 的任意 child + onTap 已覆盖当前场景。扩展 GlassSurface 会把交互混入静态渲染；命名构造与独立 InteractiveGlassSurface 均增加重复公开接口，当前没有必须新增的用例，故不新增。
- [ ] 可选 Shader：实验性后续能力，当前仍未满足支持的 Impeller 与 Android 真机 profile 前置条件，继续待办而非标记实现完成。现有 BackdropFilter 路径保留。

- 指针专项 6/6 通过：像素随位置变化、移动不重建 CustomPaint/不改变布局、退出后无 ticker，以及五类禁用/降级。新增 pointer golden 已人工查看。原示例 7/7 继续通过，原视觉基准不变。

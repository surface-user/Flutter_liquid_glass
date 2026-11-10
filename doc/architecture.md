# 架构与依赖边界

## M0 基线（8504ca7）

lib/src 原有 6 个文件，合计 1,476 行（不含公开入口）。实际相对导入：

| 文件 | 库内依赖 |
| --- | --- |
| style.dart | 无 |
| motion.dart | theme.dart |
| theme.dart | motion.dart、style.dart |
| surface.dart | style.dart、theme.dart |
| backdrop.dart | theme.dart |
| components.dart | motion.dart、style.dart、surface.dart、theme.dart |

theme ↔ motion 构成循环：纯动画配置与读取主题的页面路由放在同一文件。surface 同时处理主题/性能解析、分组与实际绘制；components 集中全部组件与共享交互。

## M1 边界

目标：components → theme → core 纯配置；components → core 渲染。core 不读取主题、不导入 components；theme 不导入组件或 core 渲染。Flutter SDK 可用于所有层。

GlassSurface/AnimatedGlassSurface/GlassBackdrop 的主题感知部分归 surfaces；唯一 GlassSurface 调用接收解析后配置的内部 renderer。分组限制、绘制算法、裁剪、fallback 及布局顺序保持。纯转场绘制和配置不读取 Theme。

共享交互保留为私有实现，通过 Dart part 在 buttons/card 之间共享同一库作用域；入口仅 show 原有公开类型，不将跨文件复用变成公开 API。这样可保留 _GlassInteraction 与 _PointerHighlight 的 Dart 私有作用域，无需新增公开交互 Widget。

## M1 实际文件依赖

以下路径相对 lib/src。Flutter SDK 导入省略；共 18 个实现文件，没有创建未实现的 inputs/feedback 目录。

| 文件 | 库内依赖/所属库 |
| --- | --- |
| core/style.dart | 无 |
| core/config.dart | 无 |
| core/motion_spec.dart | 无 |
| core/glass_group.dart | 无 |
| core/bloom_painter.dart | 无 |
| core/transitions.dart | core/motion_spec.dart |
| core/surface_renderer.dart | core/config.dart、core/glass_group.dart、core/style.dart |
| theme/theme.dart | core/config.dart、core/motion_spec.dart、core/style.dart |
| components/interaction.dart | core/config.dart、core/glass_group.dart、core/style.dart、theme/theme.dart、components/surfaces/glass_surface.dart；持有下面三个 part |
| components/buttons/glass_button.dart | part of components/interaction.dart，复用其导入和私有交互 |
| components/buttons/glass_icon_button.dart | part of components/interaction.dart |
| components/surfaces/glass_card.dart | part of components/interaction.dart |
| components/surfaces/glass_surface.dart | core/style.dart、core/surface_renderer.dart、theme/theme.dart |
| components/surfaces/animated_glass_surface.dart | core/style.dart、theme/theme.dart、components/surfaces/glass_surface.dart |
| components/surfaces/glass_backdrop.dart | core/bloom_painter.dart、theme/theme.dart |
| components/navigation/glass_app_bar.dart | core/style.dart、theme/theme.dart、components/surfaces/glass_surface.dart |
| components/navigation/glass_page_route.dart | core/motion_spec.dart、core/transitions.dart、theme/theme.dart |
| components/overlays/glass_dialog.dart | core/motion_spec.dart、core/style.dart、core/transitions.dart、theme/theme.dart、components/surfaces/glass_surface.dart |

GlassSurface 解析主题、系统高对比度、fallback 与性能配置，再调用内部 GlassSurfaceRenderer。renderer 自行依据解析配置执行过滤上限、opaque/disabled 限制及分组隔离；不导入 theme。用于分组比较的旧 defaultStyle 显式传入，保持不同过滤参数与嵌套表面的隔离条件。

页面路由与弹窗在组件层解析动态减少动画，调用不读取 context/theme 的纯 buildGlassTransition。GlassMotionSpec 独立后 theme 不再导入页面 Widget。AnimatedGlassSurface 仍直接采用目标 sigma。

## 可复核检查

`flutter test test/architecture_test.dart test/public_api_test.dart`：

- 解析相对、包路径、条件导入、export 与 part 依赖；检查文件存在、part 单一所属、循环及层级边界。
- theme 对 core 的依赖仅允许 config.dart、motion_spec.dart、style.dart，不能间接引入 renderer。
- 内部文件不得反向导入公开入口，消费者不得导入 src；入口必须逐项 show 原有 20 个声明。
- 检查器的循环/违规路径使用小型反例自测；公开入口夹具实际创建组件并操作按钮/弹窗。

检查针对当前 Dart 单行/多行指令形式，不承担完整 Dart 语法分析；API 基线另用 SDK 自带 analyzer 对旧/新源码进行一次性签名对照，不新增项目依赖。Golden 和原有事件级测试负责默认视觉与行为，不用源码检查替代运行验证。

## M2/M3 增量

theme/layout.dart 新增纯几何配置 GlassLayout，仅依赖 dart:ui 与 Flutter；theme/theme.dart 增加对它的依赖。层级方向保持，core 不读取主题。公开入口新增且仅新增 GlassLayout 类型，原公开声明继续导出。

主题层复用 SDK 的 ColorScheme/TextTheme/ButtonStyle/VisualDensity，提供 merge 的父主题复制契约；内部文字/padding 解析函数不导出。组件消费已解析的配置，core renderer 不增加主题依赖。Button/Card/AnimatedSurface 用私有 nullable 存储区分省略参数，同名公开 getter 保持旧非空默认值。

原有声明与默认行为的兼容测试继续运行，新增 theme_contract_test、component_contract_test、design_golden_test 覆盖配置与组件实际接入。依赖检查的显式导出清单更新为原 20 项加 GlassLayout，没有删除旧断言或测试。

## 状态与兼容

- core：样式值、纯配置、实际绘制、过滤分组和纯转场；接收主题已解析值。
- theme：不可变主题数据、最近局部整体替换解析、减少动画；M1 不实现新的合并语义。
- components：hover/pressed/focus、内部 controller 与 pointer 生命周期；子控件、业务数据和外部 FocusNode 由消费者持有。
- 外部唯一入口：lib/lightweight_liquid_glass.dart；src 路径不受兼容承诺保护。
- 兼容检查覆盖旧 20 个公开声明、构造函数参数/默认值、原消费者、分组与视觉 Golden。重构不更新任何基准图。

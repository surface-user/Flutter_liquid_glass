# 公开 API 基线与兼容契约

本清单对应 M0 的 `8504ca7`，M1 保留这些符号、参数含义和默认值。消费者仅导入 `package:lightweight_liquid_glass/lightweight_liquid_glass.dart`；`src/` 路径不属于兼容接口。版本仍为 0.1.0，运行时仅依赖 Flutter SDK。

下列 20 项为历史基线；现行 M2–M4 增量见文末。原构造调用继续可编译，默认视觉不变。

## 导出清单

20 个公开声明：`GlassStyle`、`GlassPresets`、`GlassQuality`、`GlassPerformanceConfig`、`GlassAccessibilityConfig`、`LiquidGlassThemeData`、`LiquidGlassTheme`、`GlassGroup`、`GlassSurface`、`AnimatedGlassSurface`、`GlassBackdrop`、`GlassCard`、`GlassButton`、`GlassIconButton`、`GlassAppBar`、`GlassDialog`、`showGlassDialog`、`GlassTransition`、`GlassMotionSpec`、`GlassPageRoute`。

入口使用 `show` 明确导出；内部交互、painter、renderer、转场函数与减少动画解析不导出。没有新增公开配置或组件。

## 组件构造参数

Widget 均保留 `key`，其默认值为 null；下表的“其余 null”仅指该行列出的可选参数。

| 接口 | 必填 | 可选参数与默认值 |
| --- | --- | --- |
| GlassSurface | child | width/height/constraints/padding/margin/alignment/style/fallbackColor=null；clipBehavior=Clip.antiAlias；enabled=true |
| AnimatedGlassSurface | child、style | duration=240ms；curve=Curves.easeOutCubic；width/height/constraints/padding/margin/alignment/fallbackColor=null；clipBehavior=Clip.antiAlias；enabled=true |
| GlassGroup | child | overlapping=false；重叠或嵌套表面不能共享过滤输入 |
| GlassBackdrop | 无 | child/gradient=null；intensity=1；animate=false；colors=[0xff7a9fff, 0xffcfa5ee, 0xff70d8cf] |
| GlassCard | child | style/margin/onTap=null；padding=EdgeInsets.all(20) |
| GlassButton | child、onPressed（可为 null） | style/focusNode=null；padding=EdgeInsets.symmetric(horizontal:20, vertical:12)；autofocus=false；最小约束 48×48 |
| GlassIconButton | icon、onPressed（可为 null）、tooltip | style=null；内部沿用按钮，padding=EdgeInsets.all(12) |
| GlassAppBar | 无 | title/leading/actions/style/bottom=null；toolbarHeight=kToolbarHeight；automaticallyImplyLeading=true |
| GlassDialog | content | title/style/semanticLabel=null；actions=[]；内部最大宽度 480、padding=24 |

`GlassSurface.enabled=false` 关闭装饰与过滤，保留内容、布局和裁剪，不等于禁用子控件。卡片 `onTap=null` 表示静态卡片；按钮 `onPressed=null` 禁止指针/键盘激活。

外部 `FocusNode` 由调用方持有并释放；组件不得释放它。指针 `ValueNotifier`、背景内部动画 controller 由组件创建与释放。child、标题、动作和业务状态均由调用方提供。

## 弹窗与页面转场

- `showGlassDialog<T>` 返回 `Future<T?>`；必填 `context`、`builder`；默认 `barrierDismissible=true`、`useRootNavigator=true`、`routeSettings=null`、`motion=null`。捕获局部主题，结果由 `Navigator.pop<T>` 返回。底层调用 Flutter `showGeneralDialog`，不能据此宣称已完成人工焦点恢复验收。
- `GlassPageRoute<T>` 必填 `builder`；`context/motion/settings=null`、`reduceMotion=false`、`fullscreenDialog=false`。提供源 context 时捕获主题与减少动画设置，`spec` 保持可读。
- `GlassTransition`：fade、fadeSlide、scaleFade、sharedAxis、none。
- `GlassMotionSpec`：transition=fadeSlide，duration=280ms，reverseDuration=220ms，curve=easeOutCubic，reverseCurve=easeInCubic。现有交互按压时长并不读取该路由配置。

## 样式与预设

`GlassStyle` 是不可变值；`copyWith`、静态 `lerp`、值相等与 hashCode 保留。默认字段：

| 字段 | 默认值 |
| --- | --- |
| blurSigmaX / blurSigmaY / blurEnabled | 12 / 12 / true |
| tintColor / tintOpacity / backgroundGradient | white / .16 / null |
| saturation / contrast | 1 / 1 |
| borderColor / borderOpacity / borderWidth / borderGradient | white / .38 / 1 / null |
| borderRadius / shape | circular(24) / rectangle |
| highlightColor / highlightOpacity / highlightAngle | white / .18 / -.8 radians |
| shadowColor / shadowOpacity / shadowBlurRadius / shadowOffset | black / .10 / 20 / (0,8) |
| noiseOpacity / noiseEnabled | .025 / false |

`copyWith` 未传字段保留原值；仅可空的 backgroundGradient、borderGradient 可通过显式 null 清空。数字/颜色/渐变插值；离散字段在 .5 切换。纯值 `GlassStyle.lerp` 可插值 sigma，但 `AnimatedGlassSurface` 的实际过滤采用目标 sigma，不能把纯插值直接用于连续过滤动画。主题 `lerp` 也存在这一边界，M2/M3 必须验证。

`GlassPresets` 七个常量：subtle、card、elevatedCard、button、appBar、dialog、selected。它们是固定样式；深色适配来自主题，不会自动改变预设常量。

## 主题与限制

- `LiquidGlassThemeData` 默认 brightness=light、accentColor=0xff4263eb；defaultStyle/cardStyle=card，buttonStyle=button，dialogStyle=dialog，appBarStyle=appBar；motion/performance/accessibility 分别为默认配置。`.dark(accentColor:0xff9babff)` 保留原工厂行为。
- `copyWith` 的 null 表示保留；样式字段为整体替换。`lerp` 插值强调色和样式，brightness/motion/performance/accessibility 在 .5 切换。
- `LiquidGlassTheme(data, child)` 当前为最近局部主题**整体替换**，其次 ThemeData.extensions，其次随 Material brightness 选择默认主题。M1 不实现字段继承；M2 要先定义兼容方案。
- `GlassPerformanceConfig` 默认 quality=adaptive、blurEnabled=true、maxBlurSigma=20、groupBackdropFilters=true、enableNoise=false、enableShadows=true、enableAnimations=true。low 有效 sigma=0；balanced/adaptive 上限 min(maxBlurSigma,16)；high 使用 maxBlurSigma。
- `GlassAccessibilityConfig` 默认 highContrast/reduceMotion/reduceTransparency 均 false。系统 highContrast 与主题高对比度合并；系统 disableAnimations/accessibleNavigation、主题 reduceMotion 或关闭 enableAnimations 任一满足即减少动画。

断言、copyWith 显式清空、离散插值、相异过滤隔离、动态减少动画的原测试保留。M1 不新增文字角色、状态样式、密度或部分覆盖配置。

## M2/M3 增量接口

该阶段增加 `GlassLayout`，合计 21 个公开声明。保留原声明，入口仍使用逐项 show。

- `LiquidGlassTheme.merge({Key? key, required LiquidGlassThemeData Function(LiquidGlassThemeData parent) data, required Widget child})` 是返回 Widget 的静态方法。最近父配置传给同步更新函数；使用 parent.copyWith 继承未修改字段。旧构造函数仍完整替换。
- `LiquidGlassThemeData` 新增 colorScheme=null、textTheme=空 TextTheme、layout=默认 GlassLayout、controlStyle=空 ButtonStyle、visualDensity=standard、tapTargetSize=padded。copyWith 中 colorScheme 未指定则保留、显式 null 清空。其他非空配置传空默认对象可重置。语义 getter：foregroundColor、surfaceColor、focusColor。
- `GlassLayout`：cardPadding=20、buttonPadding=20/12、iconButtonPadding=12、dialogPadding=24、dialogMaxWidth=480、titleSpacing=16、actionSpacing=24、actionRunSpacing=12、iconSize/appBarTitleSpacing=null。不可变，提供 copyWith/lerp；两个 nullable 尺寸未指定保留，显式 null 恢复 Flutter 默认。
- `GlassPerformanceConfig`、`GlassAccessibilityConfig`、`GlassMotionSpec` 增加 copyWith，未提供字段保留。
- `GlassMotionSpec` 新增 pressDuration=90ms、hoverDuration=160ms、releaseDuration=180ms、surfaceDuration=240ms、interactionCurve=easeOutCubic。系统/主题减少动画最终覆盖这些设置。
- `GlassButton` 新增 controlStyle；`GlassIconButton` 新增 controlStyle/focusNode/autofocus；`GlassCard` 新增 focusNode/autofocus；`GlassDialog` 新增 padding/constraints。
- Button/Card 的 padding 参数、AnimatedGlassSurface 的 duration/curve 参数接受 null 表示继承。原同名非空 getter 仍返回旧默认值；build 使用内部未指定信息解析主题。外部 FocusNode 仍由外部释放。

ButtonStyle 支持 foregroundColor、backgroundColor（着色颜色）、overlayColor（合成状态着色）、side、textStyle、iconSize、padding、minimumSize、visualDensity、tapTargetSize、animationDuration。组件状态解析返回 null 时继续继承对应主题状态。材质形状/阴影仍通过 GlassStyle 设置，不将 elevation/fixedSize 等未接入字段描述成有效能力。padding 和 minimumSize 若显式按状态改变，布局会随之改变；普通配色状态不改变尺寸。

主题 lerp 的数字/颜色仍插值，实际材质 sigma 采用目标值；过渡期间性能限制取交集、无障碍取并集，结束才解除旧限制。colorScheme 的 null 边界及离散 motion/tapTargetSize 在 .5 切换；layout 的 nullable 尺寸采用同样离散规则。

密度、继承、无障碍优先级及窗口契约见 [design-system.md](design-system.md)。库控件使用语义色；调用方 child 自己写死的 TextStyle 仍属于应用负责的内容样式。

## M4 桌面增量接口

新增以下五个 Widget，现共 26 个公开声明。均保留 `key=null`，不增加依赖，不改变旧组件默认值。

| 接口 | 必填 | 其余参数及默认值 |
| --- | --- | --- |
| GlassTextField | 无 | controller/focusNode/enabled/style/onChanged/onSubmitted/textInputAction=null；readOnly/autofocus=false；decoration=const InputDecoration() |
| GlassNavigationItem | label: String | leading/trailing/onPressed/focusNode/controlStyle=null；selected=false；indent=0（有限非负数，沿文字起始方向） |
| GlassTab | label: String | leading/onSelected/onClose/focusNode/controlStyle=null；selected=false |
| GlassToolbar | children: List<Widget> | spacing=null（layout.actionRunSpacing 加密度偏移，最低 0）；alignment=WrapAlignment.start |
| GlassMenu | trigger: Widget、items: List<Widget> | enabled=true；focusNode/onOpen/onClose/controlStyle=null |

GlassTextField 委托 SDK TextField 管理输入会话、选择、组合和粘贴；同一位置与 key 下，未传 controller 的隐式草稿随 SDK State 保留。外部 controller/FocusNode 由调用方释放，不能在 build 中重新创建。enabled 优先于 decoration.enabled；InputDecoration 表达标签、搜索前缀、清除后缀及错误。普通样式先应用 Material inputDecorationTheme，再补库默认；显式 decoration 优先。高对比度最终覆盖前景、提示、图标、边框及底色。此最小输入不包装表单校验、多行编辑或编辑器业务。

导航/Tab 的 selected 由调用方持有；回调为 null 时选择禁用。Tab 的关闭按钮仅在 onClose 非 null 时出现，关闭动作独立于选择；外部 focusNode 对应选择按钮。条目长标题单行省略并用 Tooltip 保留全文；工具栏自动换行。控件不自动创建页面缓存、树模型或 TabManager。

导航、Tab 和菜单的 controlStyle 复用 SDK ButtonStyle；除前节共有字段外，shape/alignment 及其他 SDK ButtonStyleButton 支持字段直接交由 SDK 处理。selected 加入样式解析状态；高对比度前景/底色和 2px 焦点边框优先，减少动画将 animationDuration 置零。条目默认起始对齐，无逐项 BackdropFilter。

GlassMenu 的 items 使用 SDK MenuItemButton；动作、禁用与语义由 SDK 项提供。SDK MenuAnchor 管理窗口内定位、键盘与 Esc；关闭恢复触发器焦点，onOpen/onClose 各按实际切换触发，外部 focusNode 不被释放。空 items 或 enabled=false 禁用触发；打开后禁用会关闭。外部点击用于关闭且被消费，不穿透激活底层控件。菜单使用普通表面；不承诺业务上下文菜单、多级菜单管理或实时跟随跨路由源状态。

加载、提示、空状态使用 SDK CircularProgressIndicator、Tooltip、Text 与现有容器组合，不新增平行反馈 API。真实接入步骤见 [studyworkbench-integration.md](studyworkbench-integration.md)，可编译消费者见 example/integration_test/fixtures/desktop_consumer.dart。

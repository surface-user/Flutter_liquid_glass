# 公开 API 基线与兼容契约

本节按 main 基底 `a0bc51a` 的6个实现文件逐项核对；不是 #4 增量清单。消费者仅导入 `package:lightweight_liquid_glass/lightweight_liquid_glass.dart`；`src/` 路径不属于兼容接口。版本仍为 0.1.0，当前运行时仅依赖 Flutter SDK；这是现状，第三方可按 [AGENTS.md](AGENTS.md) 评估采用。

下列20项是固定基线的公开声明，不等于20个控件。LIB-09A 新增一项 [NavigationItem](#独立导航条目)，原有声明和默认外观保持不变。

## 导出清单

20 个公开声明：`GlassStyle`、`GlassPresets`、`GlassQuality`、`GlassPerformanceConfig`、`GlassAccessibilityConfig`、`LiquidGlassThemeData`、`LiquidGlassTheme`、`GlassGroup`、`GlassSurface`、`AnimatedGlassSurface`、`GlassBackdrop`、`GlassCard`、`GlassButton`、`GlassIconButton`、`GlassAppBar`、`GlassDialog`、`showGlassDialog`、`GlassTransition`、`GlassMotionSpec`、`GlassPageRoute`。

原入口 export 六个文件，显式 hide glassReduceMotion/glassTransition；没有 #4 的逐项 show 清单，私有 painter 依 Dart 私有作用域隐藏。LIB-09A 在同一入口另行导出 `NavigationItem`。

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

`GlassSurface` 是玻璃表面容器，为 `child` 提供背景过滤、着色、边框和裁剪；它不管理子组件的值、焦点或激活。关闭模糊时使用降级填充；`GlassSurface.enabled=false` 则关闭装饰与过滤，保留内容、布局和裁剪。卡片 `onTap=null` 表示静态卡片；按钮 `onPressed=null` 禁止指针/键盘激活。

外部 `FocusNode` 由调用方持有并释放；组件不得释放它。main 没有 #4 指针高光的 ValueNotifier；背景内部动画 controller 由组件创建与释放。child、标题、动作和业务状态均由调用方提供。

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

`copyWith` 未传字段保留原值；仅可空的 backgroundGradient、borderGradient 可通过显式 null 清空。数字/颜色/渐变插值；离散字段在 .5 切换。纯值 `GlassStyle.lerp` 可插值 sigma，但 `AnimatedGlassSurface` 的实际过滤采用目标 sigma，不能把纯插值直接用于连续过滤动画。主题 `lerp` 也存在这一边界，后续实施须验证。

`GlassPresets` 七个常量：subtle、card、elevatedCard、button、appBar、dialog、selected。它们是固定样式；深色适配来自主题，不会自动改变预设常量。

## 主题与限制

- `LiquidGlassThemeData` 默认 brightness=light、accentColor=0xff4263eb；defaultStyle/cardStyle=card，buttonStyle=button，dialogStyle=dialog，appBarStyle=appBar；motion/performance/accessibility 分别为默认配置。`.dark(accentColor:0xff9babff)` 保留原工厂行为。
- `copyWith` 的 null 表示保留；样式字段为整体替换。`lerp` 插值强调色和样式，brightness/motion/performance/accessibility 在 .5 切换。
- `LiquidGlassTheme(data, child)` 当前为最近局部主题**整体替换**，其次 ThemeData.extensions，其次随 Material brightness 选择默认主题。main 不支持 merge/字段继承；#4 增量不能直接用于主线。
- `GlassPerformanceConfig` 默认 quality=adaptive、blurEnabled=true、maxBlurSigma=20、groupBackdropFilters=true、enableNoise=false、enableShadows=true、enableAnimations=true。low 有效 sigma=0；balanced/adaptive 上限 min(maxBlurSigma,16)；high 使用 maxBlurSigma。
- `GlassAccessibilityConfig` 默认 highContrast/reduceMotion/reduceTransparency 均 false。系统 highContrast 与主题高对比度合并；系统 disableAnimations/accessibleNavigation、主题 reduceMotion 或关闭 enableAnimations 任一满足即减少动画。

断言、copyWith 显式清空、离散插值、相异过滤隔离、动态减少动画的原测试保留。main 没有 #4 的文字角色、状态样式、密度或部分覆盖增量。

## 通用按钮

| 接口 | 必填 | 可选及默认 |
| --- | --- | --- |
| `ActionButton` | `Widget child`、`VoidCallback? onPressed` | `Widget? leading`（装饰，不播报）、`Key? key`（null）；另见共用选项 |
| `IconActionButton` | `Widget icon`、`String tooltip`（非空，本地化名称）、`VoidCallback? onPressed` | `Key? key`（null）；另见共用选项 |

共用选项：`ActionButtonVariant variant = secondary`（`primary`、`secondary`、`auxiliary`）；`ActionButtonSize size = medium`（`small`、`medium`、`large`）；`bool loading = false`；`FocusNode? focusNode` 与 `ActionButtonStyle? style` 默认为 null。外部焦点节点由应用释放。内容只用于显示，不应嵌套其他独立控件。

两种按钮共用 Flutter 激活和焦点机制；空回调禁用。非空回调且加载时，按钮保留焦点、名称及尺寸，不接受指针、Enter、Space 或语义激活；静态忙碌标记不启动循环动画。组件不执行异步任务、不自行重置加载状态。普通按钮可直接使用，玻璃可由外层 `GlassSurface` 提供；本切片没有按钮内建材质开关。原有 `GlassButton` 和 `GlassIconButton` 行为不变。

`ActionButtonStyle` 有两个可空字段：`BorderRadiusGeometry? borderRadius`（零圆角用 `BorderRadius.zero`）与 `Color? focusBorderColor`。高对比模式的焦点边框使用对应前景色。把 `ActionButtonThemeData` 加入 `ThemeData.extensions` 配置全局，或通过 `ActionButtonTheme(data: ..., child: ...)` 配置子树。主题的 `style`（通用）、`primary`、`secondary`、`auxiliary` 均默认为空样式。`ActionButtonTheme.of(context, variant)` 返回局部和全局继承后的样式覆盖，不补组件默认值。

各字段按实例 → 最近局部 → 更外层局部 → 全局 → 组件默认取值。同一层先查对应用途，再查通用；null 继承。主题的 `copyWith` 替换指定组，省略的组保留；主题过渡在中点切换这组配置。

## 独立导航条目

`NavigationItem` 从原包入口导出，需要 Material 宿主。必填 `label: String`；`selected` 默认为 false，由应用控制；可选的 `leading`、`trailing` 为非交互内容，`onPressed` 为空时禁用，`focusNode` 由调用方持有并释放。长标签省略显示，悬停可查看完整文本，读屏仍读取完整标签。

焦点移动不会选中条目。指针、Enter 和 Space 通过同一回调请求激活；应用可以拒绝切换。条目使用宿主的 Flutter `ColorScheme`，提供选中背景和独立焦点边框；状态反馈不带动画。调用方可用 `Material` 提供普通实色表面，或用玻璃表面容器 `GlassSurface` 包住布局；两者使用同一个 `NavigationItem`，选中、焦点和激活规则一致。首版不管理导航组、页面或路由，也不开放材质参数。

### 导航条目主题

从原包入口导出的 `NavigationItemThemeData` 可加入 `ThemeData.extensions`，作为全局配置。两个字段均为 `Color?`，默认为 null：`selectedBackgroundColor` 是选中条目的底色，其上仍会显示悬停和按压反馈；`focusBorderColor` 是聚焦时边框的颜色。

`NavigationItemTheme({Key? key, required NavigationItemThemeData data, required Widget child})` 仅影响其子树。字段依次取最近的局部配置、更外层局部配置、全局配置，最后才使用宿主默认值。未设置选中底色时取 `ColorScheme.secondaryContainer`；未设置边框颜色时沿用条目前景色。`NavigationItemTheme.of(context)` 可读取前三级合成后的覆盖值，未配置的字段仍为 null。

构造时的 null 表示继承；`copyWith` 的 null 表示保留当前字段。要恢复某字段的继承，传入省略该字段的新配置即可。宿主主题插值在中点切换导航主题的颜色覆盖，不插值 null。覆盖颜色不会改变前景色或自动重算高对比配色，应用应在所选背景上验证文字和焦点可辨认。此主题不改变原有 `LiquidGlassTheme` 的整体替换行为。

## #4 未合并增量与通用计划

#4 ac0028e 的 GlassLayout、LiquidGlassTheme.merge、主题语义/文字/状态/密度和五个桌面控件共增加6个公开声明，合计26个。其构造参数、ButtonStyle 消费字段、nullable 清空/覆盖、所有权和焦点规则完整保留在 [固定 API 文档](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/api.md)。本 PR 不复制它们为 main 已支持；实际选择该基底后复用原合同与失败回归。

已静态确认 main 的 showGlassDialog 仅向 showGeneralDialog 传 duration，独立 reverseDuration 没有消费；GlassPageRoute 则传入正反时长。LIB-08 保留失败回归/修复或明确兼容契约任务，本次不通过改文档假装修复。

新通用 API、命名/适配入口在 LIB-03 冻结，SDK/第三方直接组合不等于本库重导出或全量兼容承诺。每项明确默认/null、值/事件、状态、插槽、取消/返回值、controller/FocusNode 所有权与平台支持，参考 [task.md](task.md)。

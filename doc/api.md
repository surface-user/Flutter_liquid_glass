# 公开 API 基线与兼容契约

本清单对应 M0 的 `8504ca7`，M1 保留这些符号、参数含义和默认值。消费者仅导入 `package:lightweight_liquid_glass/lightweight_liquid_glass.dart`；`src/` 路径不属于兼容接口。版本仍为 0.1.0，运行时仅依赖 Flutter SDK。

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

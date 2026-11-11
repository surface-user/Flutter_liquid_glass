# Windows / Flutter 逐函数验证

基线 9e4daef；2026-11-11。三个子代理独立审查，主代理复核并合并测试。Windows 主机，Flutter 3.47.1 / Dart 3.13.1；新增组件测试显式使用 Windows Material 平台。此轮只增加测试和缺陷记录，lib/、原测试断言、原视觉基准均未修改。

## 范围和结果

- AST 清单：26 个 lib Dart 文件，103 个显式具名 callable（含构造器、getter、运算符、生命周期和具名局部 helper）。匿名回调归其宿主；字段隐式 getter、SDK 源码和测试工具函数不计入库函数。26 个公开声明及七个预设继续经公开入口消费。
- 分工：core/theme 34；渲染/交互 46；桌面/浮层 23。下表每项均有关联证据，不以行命中冒充完整功能验证。
- 基线根 114/114。新增 31 项（10+9+12）；全量根 139 通过、6 失败，共 145 项。6 项归为五类产品缺陷，详见 [task.md](task.md) BUG-TEST-01–05。不是“每个函数已证明无 bug”。
- 渲染组最终组合 72/72；core 新增 9 通过/1 失败；桌面新增 7 通过/5 失败。全量原用例保持通过。
- Windows 原生 C++ Debug 交叉验证与静态检查的最终结果见 [testing.md](testing.md)，不与 VM 组件测试混为一项。物理 IME、真实剪贴板与屏幕阅读器仍未验；Android 按用户决定保持待验。
- 私有恒值通知方法 _SurfaceScope.updateShouldNotify 的方法入口计数在 @override 所在的184行，185行恒false表达式无独立记录；R05验证外层重绘后稳定嵌套子控件不重建、过滤继续隔离。不能将恒值表达式未计数误读为整个方法未调用。const构造器可通过编译期构造/挂载验证，但不统一声称有运行期入口计数；参数组合、GPU/驱动延迟、Release无断言模式未穷尽。

## 证据索引

新增：[core 测试](../test/function_audit_core_test.dart) 的 C1–C10、[rendering 测试](../test/function_audit_rendering_test.dart) 的 R01–R09 均按声明顺序编号；[desktop 测试](../test/function_audit_desktop_test.dart) 使用完整用例名。[Windows 原生入口](../example/integration_test/function_audit_test.dart) 在现有宿主直接运行这三组，不新增演示应用。

原有测试简称：S=style_test，T=theme_contract_test，B/BB=black_box_interaction_test，WT=widget_test，PX=pointer_highlight_test，CG=component_contract_test，IG=interaction_golden_test；均位于 test/，此次实际复验而非仅沿用历史状态。CORE-HC-01 对应账本 BUG-TEST-04；其他缺陷见账本复现与对应测试名。

复现（根目录）：

```sh
flutter analyze
flutter test --coverage --coverage-path=build/function-audit/all-lcov.info --reporter expanded
cd example
flutter test integration_test/function_audit_test.dart -d windows --reporter expanded
flutter test --reporter expanded
```

已确认缺陷的正确预期断言保持启用，因此当前全量测试应返回失败。修复另开实现任务，禁止跳过/删除断言或更新旧图来获得绿灯。原始逐组报告、首次夹具失败和覆盖数据在本地忽略路径 build/function-audit/，CI 已包含三个新增根测试文件。

## 逐项清单

### 配置与主题（34）

| 函数 / 源码 | 契约与测试证据 | 结果或限制 |
| --- | --- | --- |
| [GlassPerformanceConfig.new](../lib/src/core/config.dart#L8) | 非负有限预算；quality 全枚举和0/5/30预算，C3 | PASS |
| [GlassPerformanceConfig.copyWith](../lib/src/core/config.dart#L25) | false/0 实际覆盖、源对象不变，C4；T继承保留 | PASS |
| [GlassPerformanceConfig.effectiveMaxBlurSigma](../lib/src/core/config.dart#L44) | low=0、high不额外截断、balanced/adaptive≤16，C3 | PASS |
| [GlassAccessibilityConfig.new](../lib/src/core/config.dart#L54) | 三个默认false与独立显式配置，C4/T | PASS |
| [GlassAccessibilityConfig.copyWith](../lib/src/core/config.dart#L60) | 三个true可改false且不串扰，C4 | PASS |
| [GlassMotionSpec.new](../lib/src/core/motion_spec.dart#L7) | 原duration/curve默认由S/B/T消费者使用；C4 | PASS |
| [GlassMotionSpec.copyWith](../lib/src/core/motion_spec.dart#L20) | transition与全部6个时长/3个curve可复制，C4 | PASS |
| [GlassStyle.new](../lib/src/core/style.dart#L10) | 全部受约束数字的负数/NaN/∞断言，C3；S默认 | PASS |
| [GlassStyle.copyWith](../lib/src/core/style.dart#L86) | 23个外观字段均可单独改变、不改源值，C1；S显式清梯度 | PASS |
| [GlassStyle.lerp](../lib/src/core/style.dart#L141) | 端点clamp、数值/颜色/梯度/形状/布尔中点，C2/S | PASS |
| [GlassStyle.==](../lib/src/core/style.dart#L185) | 全字段判别、Object异型拒绝、复制同值，C1 | PASS |
| [GlassStyle.hashCode](../lib/src/core/style.dart#L212) | 同值复制hash一致，Set使用23个不同外观，C1 | PASS |
| [GlassLayout.new](../lib/src/theme/layout.dart#L9) | 有限非负几何/非零宽度和图标，C5；T窄窗/2x | PASS |
| [GlassLayout.copyWith](../lib/src/theme/layout.dart#L43) | 未改字段保留、int→double、nullable显式重置与约束，C5/T | PASS |
| [GlassLayout.lerp](../lib/src/theme/layout.dart#L72) | 尺寸中点、方向Insets、nullable .5离散，C5/T | PASS |
| [LiquidGlassThemeData.new](../lib/src/theme/theme.dart#L11) | 默认角色及显式受限配置，C6/C7/T | PASS |
| [LiquidGlassThemeData.dark](../lib/src/theme/theme.dart#L30) | 自定义accent、暗色材质与dialog不同opacity，C6 | PASS |
| [LiquidGlassThemeData.darken](../lib/src/theme/theme.dart#L33) | 局部helper通过dark工厂5个材质槽验证，C6 | PASS |
| [LiquidGlassThemeData.foregroundColor](../lib/src/theme/theme.dart#L70) | 旧明/暗默认、ColorScheme.onSurface、显式clear回退，C6 | PASS |
| [LiquidGlassThemeData.surfaceColor](../lib/src/theme/theme.dart#L73) | 旧明/暗默认、ColorScheme.surface，C6 | PASS |
| [LiquidGlassThemeData.focusColor](../lib/src/theme/theme.dart#L78) | accent与scheme.primary优先级，C6 | PASS |
| [LiquidGlassThemeData.copyWith](../lib/src/theme/theme.dart#L80) | copy字段逐项源码核对、nullable清空/保留、局部不串扰，C6/T | PASS |
| [LiquidGlassThemeData.lerp](../lib/src/theme/theme.dart#L119) | null/端点、全部材质目标sigma、限制交集/无障碍并集、nullable色与density，C6/C7/T | PASS |
| [LiquidGlassTheme.new](../lib/src/theme/theme.dart#L177) | 局部整体替换、跨route捕获，C8/T | PASS |
| [LiquidGlassTheme.merge](../lib/src/theme/theme.dart#L180) | 显式parent.copyWith、嵌套/兄弟隔离，T（本组复跑） | PASS |
| [LiquidGlassTheme.of](../lib/src/theme/theme.dart#L190) | 无extension明暗回退、global extension、local优先，C8/T | PASS |
| [LiquidGlassTheme.updateShouldNotify](../lib/src/theme/theme.dart#L196) | 同实例不通知、data变化通知；T动态theme观察，C8 | PASS |
| [LiquidGlassTheme.wrap](../lib/src/theme/theme.dart#L198) | 捕获data包裹新child，仍覆盖目标global，C8 | PASS |
| [glassReduceMotion](../lib/src/theme/theme.dart#L203) | helper经B四来源运行中切换、无ticker与键鼠清理验证 | PASS |
| [_materialLerp](../lib/src/theme/theme.dart#L211) | helper经C7五槽和T实际filter检查，目标sigma离散 | PASS |
| [_mergeState](../lib/src/theme/theme.dart#L219) | helper经T的null状态继承→press显式→release恢复 | PASS |
| [glassControlStyle](../lib/src/theme/theme.dart#L230) | helper经T的全局/局部/状态配置与布局/图标真实解析 | PASS |
| [glassTextStyle](../lib/src/theme/theme.dart#L254) | helper经C10测试继承的Material角色在HC下可读；C6/T普通角色 | BUG-TEST-01/04 OPEN；Paint 与继承文字均存在高对比度缺陷 |
| [glassPadding](../lib/src/theme/theme.dart#L270) | helper经C9实际矩形检查RTL/LTR密度/0clamp；T显式padding优先 | 修正夹具后通过 |

### 渲染与交互（46）

| 函数 / 源码 | 契约与测试证据 | 结果或限制 |
| --- | --- | --- |
| [GlassButton.new](../lib/src/components/buttons/glass_button.dart#L6) | 参数/外部焦点原样保存；null回调禁用 | PASS |
| [GlassButton.padding](../lib/src/components/buttons/glass_button.dart#L21) | 省略返回旧20/12默认；build另行继承主题 | PASS |
| [GlassButton.build](../lib/src/components/buttons/glass_button.dart#L29) | 语义、状态样式、命中区域、键盘回调与主题降级 | PASS |
| [GlassIconButton.new](../lib/src/components/buttons/glass_icon_button.dart#L4) | icon/tooltip/外部FocusNode所有权不变 | PASS |
| [GlassIconButton.build](../lib/src/components/buttons/glass_icon_button.dart#L25) | Tooltip与GlassButton组合，不另造交互 | PASS |
| [_GlassInteraction.new](../lib/src/components/interaction.dart#L14) | 复用按钮/卡片共享交互的单一状态入口 | PASS |
| [_GlassInteraction.createState](../lib/src/components/interaction.dart#L33) | 稳定State承载指针notifier与按压状态 | PASS |
| [_GlassInteractionState.pointerEnabled](../lib/src/components/interaction.dart#L41) | 禁用/减少动画/高对比度/减少透明度/low不追踪高光 | PASS |
| [_GlassInteractionState.didChangeDependencies](../lib/src/components/interaction.dart#L51) | 动态限制立即清除旧指针位置 | PASS |
| [_GlassInteractionState.dispose](../lib/src/components/interaction.dart#L57) | 自有notifier释放；外部FocusNode不释放 | PASS |
| [_GlassInteractionState.didUpdateWidget](../lib/src/components/interaction.dart#L63) | 禁用时撤销pressed/hover/focus/pointer | PASS |
| [_GlassInteractionState.build](../lib/src/components/interaction.dart#L72) | 状态动画不改变布局/sigma；焦点保留边框；InkWell稳定 | PASS |
| [_PointerHighlight.new](../lib/src/components/interaction.dart#L179) | 用repaint监听notifier，不按移动重新build | PASS |
| [_PointerHighlight.paint](../lib/src/components/interaction.dart#L185) | 仅在非空且允许时绘制边缘；支持圆形/矩形 | PASS |
| [_PointerHighlight.shouldRepaint](../lib/src/components/interaction.dart#L220) | 仅样式/允许状态/notifier身份变化失效 | PASS |
| [AnimatedGlassSurface.new](../lib/src/components/surfaces/animated_glass_surface.dart#L9) | 保存布局、clip、enabled、fallback与可空覆盖 | PASS |
| [AnimatedGlassSurface.duration](../lib/src/components/surfaces/animated_glass_surface.dart#L30) | 旧默认240ms；显式duration可读 | PASS |
| [AnimatedGlassSurface.curve](../lib/src/components/surfaces/animated_glass_surface.dart#L31) | 旧默认easeOutCubic；显式curve可读 | PASS |
| [AnimatedGlassSurface.build](../lib/src/components/surfaces/animated_glass_surface.dart#L39) | 安全插值材质，但sigmaX/Y和blurEnabled立即取目标 | PASS |
| [_StyleTween.new](../lib/src/components/surfaces/animated_glass_surface.dart#L68) | 初始end用于首帧无begin的插值 | PASS |
| [_StyleTween.lerp](../lib/src/components/surfaces/animated_glass_surface.dart#L69) | 重定向GlassStyle.lerp；begin缺省取end | PASS |
| [GlassBackdrop.new](../lib/src/components/surfaces/glass_backdrop.dart#L9) | animate默认false；intensity限制0..1；参数可用 | PASS |
| [GlassBackdrop.createState](../lib/src/components/surfaces/glass_backdrop.dart#L26) | 控制器随稳定State持有 | PASS |
| [_GlassBackdropState._sync](../lib/src/components/surfaces/glass_backdrop.dart#L36) | 四类减少动画/TickerMode/animate关均停止并归零 | PASS |
| [_GlassBackdropState.didChangeDependencies](../lib/src/components/surfaces/glass_backdrop.dart#L47) | 媒体/主题/TickerMode变化重算ticker | PASS |
| [_GlassBackdropState.didUpdateWidget](../lib/src/components/surfaces/glass_backdrop.dart#L53) | animate参数变化重算ticker | PASS |
| [_GlassBackdropState.dispose](../lib/src/components/surfaces/glass_backdrop.dart#L59) | 销毁动画controller，不遗留瞬态回调 | PASS |
| [_GlassBackdropState.build](../lib/src/components/surfaces/glass_backdrop.dart#L65) | bounded背景绘制；colors复制避免mutable列表漏更新 | PASS |
| [GlassCard.new](../lib/src/components/surfaces/glass_card.dart#L4) | 卡片内容及外部所有权不变 | PASS |
| [GlassCard.padding](../lib/src/components/surfaces/glass_card.dart#L17) | 省略返回旧20；显式padding可用 | PASS |
| [GlassCard.build](../lib/src/components/surfaces/glass_card.dart#L24) | 静态卡不伪装按钮；onTap非空复用共享交互 | 渲染/交互 PASS；文字高对比度 BUG-TEST-04 OPEN |
| [GlassSurface.new](../lib/src/components/surfaces/glass_surface.dart#L8) | 原布局/clip/enabled参数继续可用 | PASS |
| [GlassSurface.build](../lib/src/components/surfaces/glass_surface.dart#L34) | 主题/媒体最终限制覆盖装饰，renderer只收解析值 | PASS |
| [GlassBloomPainter.new](../lib/src/core/bloom_painter.dart#L5) | 创建颜色与强度快照的绘制器 | PASS |
| [GlassBloomPainter.paint](../lib/src/core/bloom_painter.dart#L8) | 径向渐变有界；零尺寸不抛异常 | PASS |
| [GlassBloomPainter.shouldRepaint](../lib/src/core/bloom_painter.dart#L30) | 颜色逐项或intensity变化更新；相同值不更新 | PASS |
| [GlassGroup.new](../lib/src/core/glass_group.dart#L6) | 建立BackdropGroup，不以overlapping值错误共享 | PASS |
| [GlassGroup.updateShouldNotify](../lib/src/core/glass_group.dart#L9) | overlapping变化通知下游重算；不变无需通知 | PASS |
| [GlassSurfaceRenderer.new](../lib/src/core/surface_renderer.dart#L10) | 接收解析配置；不读取主题层 | PASS |
| [GlassSurfaceRenderer.build](../lib/src/core/surface_renderer.dart#L40) | 过滤上限、分组键、opaque/noise/shadow/clip边界 | PASS |
| [_SurfaceScope.new](../lib/src/core/surface_renderer.dart#L183) | 无论装饰是否开启都标识嵌套表面边界 | PASS |
| [_SurfaceScope.updateShouldNotify](../lib/src/core/surface_renderer.dart#L184) | scope身份无可变配置，恒不通知；嵌套仍隔离 | PASS；方法入口184行有命中，R05嵌套重绘保持隔离与稳定child |
| [_GlassPainter.new](../lib/src/core/surface_renderer.dart#L189) | 保存样式、高对比度与noise解析值 | PASS |
| [_GlassPainter.paint](../lib/src/core/surface_renderer.dart#L192) | 零尺寸返回；高对比度rim；圆/矩形、渐变、固定噪声 | PASS |
| [_GlassPainter.shouldRepaint](../lib/src/core/surface_renderer.dart#L256) | 样式、highContrast或noise变化触发paint | PASS |
| [buildGlassTransition](../lib/src/core/transitions.dart#L4) | 五种转场与reduceMotion短路，前后向曲线独立 | PASS |

### 桌面与浮层（23）

| 函数 / 源码 | 契约与测试证据 | 结果或限制 |
| --- | --- | --- |
| [desktopControlStyle](../lib/src/components/desktop_style.dart#L5) | SDK state styling without per-row blur; selected colors, shape, focus and reduced motion; new `selected navigation resolves declared state colors`, `selected navigation forwards selected state to shape resolver`; old desktop matrix | Selected foreground/background PASS; selected shape FAIL. Ordinary high contrast/motion modes pass old matrix. |
| [desktopControlStyle.states](../lib/src/components/desktop_style.dart#L22) | Adds selected to local/theme resolvers; new actual DefaultTextStyle=purple and Material background=yellow assertions | PASS for wrapped color properties; shape is not wrapped. |
| [GlassTextField.new](../lib/src/components/inputs/glass_text_field.dart#L7) | Public controller/focus/enabled/readOnly/InputDecoration/action callbacks; new owner replacement + search callback test; old implicit/read-only/disabled/IME injection | Valid construction PASS; no custom editor/parser implemented. |
| [GlassTextField.build](../lib/src/components/inputs/glass_text_field.dart#L29) | Material decoration defaults + glass geometry + enforced high contrast, SDK draft/selection ownership; new search/owner replacement and dark/light foreground Paint cases | Owner switch / enabled override / search callback PASS. Foreground Paint high contrast FAIL (2 cases). Physical OS IME and clipboard remain untested by agent. |
| [GlassAppBar.new](../lib/src/components/navigation/glass_app_bar.dart#L8) | Title/leading/actions/style/bottom/toolbar options forward to SDK; new custom toolbar+bottom test, old public consumer | PASS for supplied options; automatic back button relies on reviewed SDK and gallery existing flow. |
| [GlassAppBar.preferredSize](../lib/src/components/navigation/glass_app_bar.dart#L24) | toolbarHeight+bottom.preferredSize; custom 73+21=94 and actual Scaffold body top=94 | PASS. |
| [GlassAppBar.build](../lib/src/components/navigation/glass_app_bar.dart#L27) | GlassSurface wrapper and transparent SDK AppBar; custom toolbar dimensions and automaticallyImplyLeading=false | PASS; theme text/spacing examined against implementation. No new visual baseline. |
| [GlassNavigationItem.new](../lib/src/components/navigation/glass_navigation_item.dart#L7) | Controlled label/selection/indent/leading/trailing/focus; invalid negative/infinite/NaN assert | PASS for valid and invalid declared geometry. |
| [GlassNavigationItem.build](../lib/src/components/navigation/glass_navigation_item.dart#L26) | TextButton + selected semantics + directional indent + tooltip ellipsis; new selected colors/shape and old keyboard/LTR/RTL/narrow cases | Color, keyboard and indent PASS; selected shape FAIL. Widget child-owned hardcoded styles remain caller responsibility. |
| [GlassPageRoute.new](../lib/src/components/navigation/glass_page_route.dart#L8) | motion/context/reduceMotion/settings/fullscreenDialog; capture nearest local theme with Navigator | New reduceMotion=true, teal local theme, route arguments/result PASS; old route enum traversal assertions independently inspected. |
| [GlassPageRoute._](../lib/src/components/navigation/glass_page_route.dart#L38) | SDK duration/reverse duration, page builder and transition builder; public factory invokes it | PASS via new push/pop and zero duration test. All transition kinds and source disableAnimations covered by inspected widget_test cases, root full-suite replay PASS. |
| [GlassTab.new](../lib/src/components/navigation/glass_tab.dart#L7) | Public selected/onSelected/onClose/focus/style config; no page state | PASS via old keyboard selection/independent-close case and consumer matrix. |
| [GlassTab.build](../lib/src/components/navigation/glass_tab.dart#L24) | Adjacent select and close buttons, localized tooltip, close only when callback supplied | PASS old close count=1, selection remains1, 本轮根复验PASS；此前同源码native consumer 1/1，未算作本轮Tab物理键鼠验收. Shared selected-shape limitation applies to select child. |
| [GlassToolbar.new](../lib/src/components/navigation/glass_toolbar.dart#L6) | Children, nullable/finite nonnegative spacing, WrapAlignment | PASS invalid-geometry test and normal construction. |
| [GlassToolbar.build](../lib/src/components/navigation/glass_toolbar.dart#L15) | Derived gap=12+compact.horizontal*2=8, explicit gap=20 overrides and wraps at width110 | PASS actual child rects; no overflow. |
| [GlassDialog.new](../lib/src/components/overlays/glass_dialog.dart#L9) | Controlled content/title/actions/style/semantics/padding/constraints | PASS construction and callback/state flow; explicit maximum constraints do not work below 280 in wide parent. |
| [GlassDialog.build](../lib/src/components/overlays/glass_dialog.dart#L30) | Scrollable transparent SDK Dialog with GlassSurface; local theme/copy styles; explicit padding/constraints | FAIL: maxWidth230 produces width280 because outer Dialog keeps SDK minWidth280. Existing narrow2x, local dark and width300 cases PASS. |
| [showGlassDialog](../lib/src/components/overlays/glass_dialog.dart#L84) | Capture opening themes, root/local navigator, barrier/Esc, route settings, result, explicit no-transition | New local Navigator, captured maxWidth270, route name and string result are validated; width FAIL is in child layout. Existing Esc/non-dismissible/result cases PASS. |
| [GlassMenu.new](../lib/src/components/overlays/glass_menu.dart#L7) | Trigger/items/enabled/focus/onOpen/onClose/controlStyle | PASS normal/disabled options in old cases; external focus ownership checked; controller is internal SDK MenuController. |
| [GlassMenu.createState](../lib/src/components/overlays/glass_menu.dart#L25) | Creates state retaining controller and own fallback FocusNode | PASS repeated rebuild/open/close and parent replacement in old/new cases. |
| [_GlassMenuState.dispose](../lib/src/components/overlays/glass_menu.dart#L32) | Releases only self-owned fallback FocusNode; SDK child releases its own resources | Old caller focus survives unmount PASS; inspected explicit self-owned dispose only. Physical external focus reuse needs root native/manual distinction. |
| [_GlassMenuState.didUpdateWidget](../lib/src/components/overlays/glass_menu.dart#L38) | Disable while open schedules guarded close after frame | Existing disables-open test PASS, single close callback. Dynamic external focus replacement FAIL: open menu stays visible after Esc, no reliable restore. Callback mounted guard reviewed statically. |
| [_GlassMenuState.build](../lib/src/components/overlays/glass_menu.dart#L48) | MenuAnchor + MenuButtonTheme, window fit, Esc/focus, item callbacks, empty disabled trigger and outside-tap consumption | Normal close/focus/action/window modes PASS; new empty and disabled pointer/Enter rejection PASS; outside tap closes without activating underlying button PASS. External-owner replacement while open FAIL after explicitly verified keyboard focus. |

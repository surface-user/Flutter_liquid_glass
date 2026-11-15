# fluent_ui 独立源码研究

状态：REVIEW（研究稿已完成，待复核；不表示通过运行、视觉或无障碍验收）

研究日期：2026-11-15
研究对象：[bdlukaa/fluent_ui](https://github.com/bdlukaa/fluent_ui)
固定分支：`master`
固定提交：`e183ad9778df9f4e74a3664da6667e63b379f0f8`
提交说明：Release 4.18.0；提交时间：2026-11-12 13:59:35 UTC。版本以该提交的 `pubspec.yaml` 为准。[E01]

## 1. 方法、范围与证据口径

本报告先解释项目本身：它希望提供什么、Gallery 如何组织、公开 API 如何被消费、交互和主题如何落到代码。没有与任何委托方项目比较，也没有迁移或实施建议。未读取用户记忆、既有产品定位/差距文档或其他代理报告。

资料通过 GitHub 连接器读取。以下源码、示例和测试均固定到同一 SHA；没有克隆第三方仓库，也没有把第三方源码保存进工作区。研究只写本报告；未安装依赖、生成文件、运行测试、构建或控制浏览器。

本文明确区分四种判断：

| 标记 | 含义 | 能说明什么 |
| --- | --- | --- |
| 文档声称 | README、Dart 注释或样例文字表达的目标 | 维护者表达的意图，不能替代实测 |
| 源码证实 | 在固定提交的具体实现中可直接读到 | 该版本如何传值、分支、挂载和调用 |
| 推断 | 根据多处源码作出的有边界解释 | 明示前提，不提升为实机事实 |
| 运行未验 | 本次没有启动程序或执行检查 | 不声称实际帧率、视觉一致、读屏效果或平台通过 |

全文的 [E编号] 指向末尾证据索引中的固定 SHA、文件路径和行号。测试部分只表示“存在这些测试及断言”，不表示这些测试在本次环境通过。公开仓库统计会变化，因此没有以星标、下载量或 issue 数推导质量。

## 2. 项目目标、平台与维护身份

**文档声称：这是 Windows UI 的非官方 Flutter 实现。** README 明确使用“Unofficial implementation”，目标是在 Flutter 中按 Windows UI 指南构造应用，参照微软官方控件文档。它不是微软官方 Flutter Fluent UI，也不能因为仓库简介写着 WinUI3 就视为直接包装或嵌入原生 WinUI3 控件。[E02]

**源码证实：发布形态是 Dart/Flutter 控件库，另有独立 Gallery。** 版本为 4.18.0，约束为 Dart `>=3.8.0 <4.0.0`、Flutter `>=3.32.0`。公共入口导出 Flutter widgets、Fluent 控件、主题、本地化、图标，以及少量 `material_ui` 与 `scroll_pos` 类型；所以“控件使用 Flutter 构造”与“无第三方运行时依赖”是不同判断。根包实际依赖 `intl`、`scroll_pos`、`recase`、`math_expressions`、`material_ui` 等。[E01][E03]

**平台边界：设计重点是 Windows，源码有明确跨平台分支，不能据此宣布所有平台体验相同。** Gallery 把非 Web 的 Windows/Linux/macOS 视为 desktop，初始化 `flutter_acrylic` 和 `window_manager`；系统强调色加载条件、标题栏和窗口效果又有各自平台判断。Settings 的 Windows/Linux/macOS 效果列表不相同，Web 不提供该窗口效果列表。[E04][E05] 这证实作者区分平台能力，不等于本次验证了 Android、iOS、Linux、macOS、Windows 或 Web 的实际运行质量。

**文档声称：社区开源、维护资源集中。** README 欢迎外部贡献，并写明 bdlukaa 是当时唯一积极维护者，PR 审阅可能需要时间。[E02] 这是固定版本文档中的维护声明，不能推定未来维护承诺或服务级别。

## 3. Gallery 是什么，页面如何组织

Gallery 是独立的 `example` 应用，标题为 “Win UI for Flutter Gallery”。`main()` 先初始化绑定、按条件处理窗口，再预加载六个 deferred route library，最后运行 `MyApp`。虽然使用 deferred import，当前入口会在 `runApp` 前通过 `Future.wait` 预加载六组库，不能把它直接描述成“点击某页时才按需加载”。[E04]

外壳是 `FluentApp → MyHomePage → NavigationView`。应用主题由 example 自己的 `AppTheme extends ChangeNotifier` 和 Provider 管理；`_MyHomePageState._index` 管理外层导航选择。顶部包含自动建议搜索、主题切换和平台窗口按钮；底部含 Settings 与指向仓库的 Source code 链接。[E04][E06]

### 3.1 源码中的导航目录

以下是固定版本主入口实际注册的页面，而不是从包内所有类名反推的目录：[E07]

| Gallery 分组 | 主入口注册的页面 |
| --- | --- |
| Home | Home |
| Basic input | Button、Checkbox、Radio、Slider、ToggleSwitch、ComboBox、ColorPicker、Rating Control |
| Date & time | DatePicker、TimePicker、CalendarView、CalendarDatePicker |
| Dialogs & flyouts | ContentDialog、Flyout、TeachingTip、Tooltip、MenuBar |
| Navigation | Breadcrumb Bar、Navigation View、Tab View、Tree View、Command Bar |
| Surfaces & Layout | Acrylic、Tiles、Expander |
| Styles & Icons | Windows Icons、Fluent Icons、Typography、Colors |
| Status & info | InfoBar、InfoBadge、ProgressRing、ProgressBar |
| Text | AutoSuggestBox、NumberBox、PasswordBox、TextBox |
| Footer | Settings、Source code |

主入口中的 Mica 页面是注释代码，不能把它算成已开放 Gallery 页面；但公共库确实导出 `Mica`，两者并不矛盾。[E03][E07]

页面源码分在 `example/lib/screens/{inputs,forms,popups,navigation,surface,theming}` 等目录，`example/lib/routes/*.dart` 是相应 export 汇合处。样例一般组合 `ScaffoldPage.scrollable`、`PageHeader`、说明文字、`PageMixin` 的标题/描述辅助方法、`CodeSnippetCard`，再在 child 中真正实例化公开控件。[E08][E09]

### 3.2 展示代码与真实控件不是同一份对象

`CodeSnippetCard` 接收两个独立输入：`Widget child` 与 `String codeSnippet`。上方 Mica 容器显示 child，下方 Expander 显示经过语法高亮的字符串；打开后出现 Copy 按钮。源码没有将 child 自动反射为可复制代码，也没有将字符串作为可执行代码运行。[E09]

这形成直观的“效果 + 代码”阅读界面，也产生维护两份内容的一致性成本。实际发现：

- **ContentDialog：** 展示字符串里是局部 `final result = await ...`，随后仅 `setState(() {})`；实际方法是把返回值写回页面字段 `result`，供旁边 Text 显示。复制片段不包含同样的结果回显状态更新。[E10]
- **NavigationView：** 展示字符串引用 `topIndex`、`displayMode`、`indicators`、`items`、`WindowButtons` 和私有 `_NavigationBodyItem`；这些上下文没有随 Copy 一并打包。真正运行部分还包含 hasTopBar 条件、自定义 Teams layout 和 transitionBuilder 分支，展示字符串不完整涵盖这些行为。[E11]
- **TabView：** 当前可复制字符串写 `TabViewController(tabs: [...])`，实际 API 构造参数是 `initialTabs`；同一页面实际运行用的 controller 也使用 `initialTabs`。这是可直接定位的片段/API 不一致；本次没有执行编译，但仅按该固定 API 消费 `tabs:` 会与签名不符。[E12]

因此它适合解释使用方式，不能把每个 Copy 结果当成已经验证的独立可运行示例。

## 4. 公开库与 Gallery 私有 UI 的边界

| 层次 | 例子 | 消费边界 |
| --- | --- | --- |
| 公共应用基础 | FluentApp、FluentTheme、FluentThemeData、本地化 | 从 `package:fluent_ui/fluent_ui.dart` 导入 |
| 公共组件与配置 | NavigationView、NavigationPane、PaneItem、ContentDialog、FlyoutController、FlyoutTarget、Button、Checkbox、TabView | 包 API；实际签名以实现为准 |
| 库内实现 | _NavigationBody、_NavigationPageEntry、_DismissAction、_AcrylicGuts | 下划线私有符号，不是可直接消费的公共 API |
| Gallery 应用基础 | AppTheme、MyHomePage、WindowButtons、PageMixin、CodeSnippetCard | 在 example 目录；没有从根公共入口导出 |
| Gallery 示例和演示状态 | NavigationViewPage、ContentDialogPage、Flyout2Screen、_NavigationBodyItem、topIndex/result 等 | 教学应用实现，不能仅导入库就获得 |
| Gallery 原生窗口集成 | window_manager、flutter_acrylic、系统强调色、外链/字体/语法高亮等 | example 自身依赖；不应把其所有效果归给根库 |

公共入口虽通过 `view.dart` 暴露 pane/body 等 part 中的非私有声明，但不会导出 example 的壳和页面。example 的依赖表比根包大，包含 Provider、window_manager、flutter_acrylic、go_router、google_fonts、share_plus 等；“Gallery 使用某依赖”不代表根包也依赖它，反过来也不能从依赖声明单独认定某个导出功能已实现。[E03][E13]

## 5. 导航完整链：Gallery 入口 → 状态 → 公开组件 → 动画/焦点/返回

### 5.1 两层导航

Gallery 外层导航：主入口注册 `Navigation > Navigation View` 为 `NavigationViewPage`。点击项目后，外壳的 `NavigationPane.onChanged` 更新 `_index`，由外层 `NavigationView` 挂载对应 body。[E04][E07]

页面内部又嵌套一个 600 高的 `NavigationView`。页面 State 保存 `topIndex`、`displayMode`（初始 expanded）、`pageTransition`（Default）、`indicator`（Sticky）、`hasTopBar` 及动态 items。其 ComboBox 和 Checkbox 改这些字段；不是修改整个 Gallery 的 AppTheme。buildDisplayMode 虽被调用四次，但只对与当前 displayMode 相同的模式返回 UI，因此不能理解成屏幕同时摆放四个完整导航样例。[E11]

### 5.2 一次项目调用的执行链

| 步骤 | 直接实现 | 状态所有权与结果 |
| --- | --- | --- |
| 1. 鼠标或键盘调用 | PaneItem.build → HoverButton | HoverButton 汇总 pressed/hovered/focused/disabled；禁用或 pane 正在过渡时不执行项目回调 |
| 2. 触发项目行为 | PaneItem 的 onItemTapped | 先调用传入的 onPressed，再调用 PaneItem.onTap |
| 3. 请求导航 | NavigationPane._buildItem 把 onPressed 绑定为 changeTo(item) | 公共配置对象本身不把 selected 改成新值 |
| 4. 派发事件 | changeTo | enabled 检查；先 onItemInvoked，再按有效索引 onItemPressed，确实需要切换才 onChanged |
| 5. 应用接受选择 | 示例 onChanged → setState(topIndex = index) | 调用方回填 selected 后才产生新的选择 |
| 6. 选择 body | NavigationView.build → _NavigationBody | key 来自 item.key 或 selected；主题提供 duration/curve |
| 7. 页面过渡/保留 | _NavigationPageEntry | 当前页进入动画；失活页 Offstage 且 TickerMode(false)，只有请求 keepAlive 的页继续保留 |

证据：[E14][E15][E16][E17]。测试明确覆盖“调用先于选择”“重复调用已选项目只发 invoke”“Enter 调用 selectsOnInvoked=false 项目但不切换选择”。[E18]

**重要索引语义：** `selectedItem` 访问的是 `effectiveItems[selected]`。effectiveItems 从 allItems 过滤出带 body 的 PaneItem，排除 PaneItemAction；allItems 又含 footer 和递归 expander 子项。不能按原始 `items` 列表下标机械计算，也不能把 header/separator 当成可导航项。[E15] 相关注释还混用 allItems 的说法，消费时应以实际过滤代码为准。

### 5.3 受控与非受控部分

- **调用方控制：** selected、items、displayMode 配置，以及 onChanged 是否接受切换。没有 onChanged 时，普通项目请求不会自动改调用方选中值。
- **库内状态：** compact/minimal 面板开合、scrollController 的按需创建、局部选择历史、上一选项索引、过渡进行标记。
- **页面生命周期：** 默认仅挂载当前页；显式 AutomaticKeepAliveClientMixin 可选择保留。给出 paneBodyBuilder 时，body 的状态管理转由该 builder 承担。实现以缓存 map、keepAlive notification、Offstage、TickerMode 和 RepaintBoundary落实这些行为。[E14][E16]
- **不是统一模式：** TabView 在该版本要求 controller，controller 自己拥有 tabs 和 selectedIndex；不能从 NavigationPane 的受控 selected 推断整个库都采用同一状态模型。[E12][E29]

这组设计的好处是选择可以由业务/路由驱动，代价是调用方必须正确保存状态、索引与 key。页面默认不保留是清晰的资源取舍，也意味着页面切换后不能假设表单和局部计数自动持久化。测试用 init/dispose 计数和回访计数值验证两种生命周期；本次没有运行这些测试。[E19]

### 5.4 自适应布局、动画和焦点

auto 模式直接读取可用约束宽度；无穷宽时退回 MediaQuery.widthOf。默认边界是 <=640 minimal、641–1007 compact、>=1008 expanded，支持配置两个 threshold。[E20] 对应测试覆盖 640/641/1007/1008 和自定义 700/701/900 的边界。[E21]

body 的默认转场在 top 模式为 HorizontalSlidePageTransition，其他模式为 EntrancePageTransition；示例可切换 Entrance、Drill in、Horizontal。实际实现分别使用位移/淡入、缩放/淡入、横向位移；它们是 Flutter Widget 组合，不是原生窗口页面切换。[E16][E22]

焦点链为 PaneItem → HoverButton → FocusableActionDetector，项目聚焦时调用 Scrollable.ensureVisible；pane 内有 FocusTraversalOrder，body 有 FocusTraversalGroup。PaneItem 通过 semanticLabel 或标题文本提供语义名称，带 selected 语义和 FocusBorder；tooltip 是独立机制。不是仅凭“用了 Flutter”推定键盘和读屏支持。[E14][E17][E23]

### 5.5 三种“返回”必须分开

1. **关闭导航 overlay：** Esc 的 CallbackShortcuts 只在 compact/minimal overlay 已打开时 closePane；不负责退出 Gallery 的 Flutter route。[E24]
2. **局部选择历史：** 调用方回填 selected 后，didUpdateWidget 比较新旧有效项目，普通切换把旧项的 key/index 写入 history，返回切换则移除末条历史（[源码 L473-L504](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L473-L504)）。`NavigationView.of(context).pop()` 先关闭 compact/minimal overlay，再从局部历史请求 onChanged(previous)。PaneBackButton 默认基于 canPop 调用 view.pop；它与 Navigator.pop 不同。[E25]
3. **新屏幕 route：** 示例 “Open in a new screen” 显式 root Navigator.push(FluentPageRoute(...))；NavigationViewShellRoute 的 TitleBar.onBackRequested 则 root Navigator.pop。FluentPageRoute 包含 route Semantics、DrillInPageTransition 和固定 200ms transitionDuration。[E11][E26]

这说明 NavigationView 提供 UI、选择和局部历史，不取代 Flutter Navigator/Router。源码本身也明确该边界。[E14]

## 6. 弹窗完整链：ContentDialog

### 6.1 Gallery 到返回值

| 阶段 | 代码消费路径 | 直接结果 |
| --- | --- | --- |
| Gallery 入口 | Dialogs & flyouts → ContentDialogPage | 页面独立保存 String? result |
| 点击 Show dialog | Button.onPressed → showContentDialog(context) | 进入异步方法 |
| 建立模态 route | await showDialog<String>(context, builder) | 默认 root Navigator 推入 FluentDialogRoute<String> |
| 渲染内容 | builder → ContentDialog(title, content, actions) | ContentDialog 只负责内容/动作区布局和主题 |
| 用户选择 | Delete/Cancel Button → Navigator.pop(context, String) | route 返回字符串；示例没有实际文件删除代码 |
| 结果回显 | result = await ...；setState | 返回值进入旁边 Text；Esc 等无结果退出可返回 null |

证据：[E07][E10][E27]。Delete 按钮的“删除”仅是演示文案和注释，不能把该样例描述成真实文件操作。

### 6.2 ContentDialog 与 showDialog 分工

`ContentDialog` 是 StatelessWidget：对 title/content/actions 应用 ContentDialogTheme，默认 maxWidth 为 368，动作区通过 ButtonTheme.merge 应用动作按钮样式；一个 action 靠末端，多 action 用 Row/Expanded 布局。它自己没有 open 字段或内部“确定/取消”业务结果，也不负责 push route。[E27]

公开 `showDialog<T extends Object?>` 承担捕获主题、选择 Navigator、barrier 与转场配置。当前默认：

- useRootNavigator = true；
- barrierColor = 0x8A000000；
- barrierDismissible = false；
- dismissWithEsc = true；
- transitionDuration 优先显式参数，再 FluentTheme.fastAnimationDuration，再 300ms。[E28]

`FluentDialogRoute` 使用 RawDialogRoute；pageBuilder 把捕获主题包回 builder 内容，再包 SafeArea、Actions 和 autofocus 的 FocusScope。dismissWithEsc 为 true 时注册 DismissIntent → _DismissAction → Navigator.pop。默认转场是 FadeTransition + ScaleTransition；按代码，scale 的 Tween 是 begin:1、end:0.85，不将其改写为想象中的“0.85 放大到 1”。[E28]

源码能证明存在局部焦点 scope、DismissIntent 路径和 barrier 参数，不能证明所有读屏器都正确报出 title、焦点回到原按钮、Tab 被完整约束、系统返回键行为跨平台一致。这些属于运行未验。

### 6.3 接口与注释不一致

存在两处具体的可审阅问题：

- showDialog 签名接收 `barrierLabel`，但内部构造 route 时无条件传 `FluentLocalizations.of(context).modalBarrierDismissLabel`，没有使用该实参。直接构造 FluentDialogRoute 的构造器则有 barrierLabel 回退逻辑。[E28]
- FluentDialogRoute 的注释写 barrierDismissible 默认 true，并谈到 useSafeArea 参数；实际 showDialog 默认 false，route 实现总包 SafeArea，公开签名没有 useSafeArea 参数。[E28]

这些属于固定提交源码/注释层面的一致性问题；本次未以运行用例确认全部外部影响。

## 7. 锚点浮层链：Flyout 的补充核查

Flyout 与居中 ContentDialog 的消费模型不同：示例在 State 中持有 controller，将按钮包在 FlyoutTarget，点击时 controller.showFlyout(builder: ...)。FlyoutTarget 的 build 将自身附着到 controller；控制器利用 target 与 Navigator 的 RenderBox 计算相对位置，建立非 opaque PageRouteBuilder，并 await Navigator.push 的结果。[E30][E31]

| 链环 | 源码行为 |
| --- | --- |
| 示例状态 | 四个 FlyoutController；barrierDismissible=true、dismissWithEsc=true、dismissOnPointerMoveAway=false；首个 placementMode=topCenter |
| 打开 | Clear cart 按钮调用 showFlyout，builder 返回 FlyoutContent |
| 自动位置 | 把用户选的模式作为 FlyoutAutoConfiguration.preferredMode 传入；实际空间/尺寸仍参与位置计算 |
| 动画 | 默认打开时长来自 fastAnimationDuration；reverseTransitionDuration 的实际默认参数为 Duration.zero；外层始终有 FadeTransition |
| 焦点/关闭 | dismissWithEsc=true 时包 Actions 与 autofocus FocusScope；样例确认按钮调用 Flyout.of(context).close |
| 生命周期 | controller.dispose 移除 WidgetsBinding observer；窗口 metrics 改变时已打开浮层会 close |

证据：[E30][E31][E32]。其中“默认关闭时长”尤其应看签名：虽然注释说默认跟随 transitionDuration，签名给的是 Duration.zero；只在调用方显式传 null 时 `??=` 才会采用打开时长。[E31]

**示例生命周期不足：** 页面创建了 controller、menuController、itemsController、contextController 四个对象，而 dispose 只释放其中三个，漏掉 itemsController。由于构造器注册 WidgetsBinding observer、dispose 才移除，这存在残留 observer 的源码依据；未实测泄漏规模或用户可见后果。[E30][E31]

## 8. 组件职责、交互状态与组合方式

这个库的结构不只是“许多外观相似的控件”：它把手势/焦点基础、状态样式、具体视觉组件、应用主题和上层导航分别组合。

### 8.1 Button 的状态消费链

`Button extends BaseButton`；Button 提供默认 padding、边框和颜色解析，BaseButton 依次取 widget.style、局部/应用主题 style、默认 style 的属性，然后把状态交给 HoverButton。[E33][E34]

HoverButton 中的状态来源可以直接定位：

| 状态 | 来源与处理 | 视觉消费 |
| --- | --- | --- |
| idle | 没有交互标记时的空 state set | 默认 token |
| hover | FocusableActionDetector.onShowHoverHighlight 或 MouseRegion | controlFillColorSecondary 等 |
| pressed | GestureDetector down/up/cancel，或 ActivateIntent/ButtonActivateIntent | tertiary 背景、secondary 前景 |
| focused | onShowFocusHighlight | FocusBorder；与 hover 不混作同一种状态 |
| disabled | enabled getter 为 false 时仅返回 disabled | disabled 填充/文字 token，语义 enabled=false |
| selected/checked | 不是所有按钮的基础瞬态 | 由 PaneItem.selected、Checkbox.checked、ToggleButton 等各自拥有 |

按键 activation 会立刻调用 onPressed，再等待 theme.fastAnimationDuration 清除 pressed；鼠标 tap up 的清除等待是硬编码 100ms。基础按钮视觉通过 AnimatedContainer(fasterAnimationDuration) 和 AnimatedDefaultTextStyle(fastAnimationDuration) 变化。[E17][E34] 这证明动效不是单一“点击缩放”，而是状态、颜色、字色与焦点轮廓等分层处理。

普通 Button 的 onPressed=null 常被文档简称为禁用，但 BaseButton 还有 onLongPress/onTapDown/onTapUp 等可使 enabled 为真的入口；消费复杂手势时应按 actual enabled 规则理解，不把单一文档简写当作所有参数组合的真值表。[E17][E34]

### 8.2 状态所有权并非一刀切

| 控件 | 公开状态模型 | 使用方需要完成的工作 |
| --- | --- | --- |
| Button | 不保存业务切换值；回调触发动作 | 提供 onPressed；视觉状态由底层管理 |
| Checkbox | required bool? checked、required ValueChanged<bool?>? onChanged | 保存 checked 并在回调回填；onChanged=null 禁用 |
| NavigationPane | int? selected + onChanged | 保存有效选中索引；配置 items/body/key |
| PaneItemExpander | initiallyExpanded 及库内 expander State | 初始值写入 _open；不是持续受控展开值（[源码 L950-L998](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane_items.dart#L950-L998)） |
| TabView | required TabViewController | 创建并 dispose controller；新增/关闭请求中调用 add/removeAt |
| ContentDialog | 内容 widget，不保存显示状态 | 通过 showDialog/route 管理显示；自己决定返回值 |
| Flyout | controller + attached target + route | 管理 controller 生命周期，提供 builder 与关闭行为 |

Checkbox 在 onPressed 中发出 checked==null ? null : !checked；没有把字段自行改变。不要假设 nullable checked 一定会自动循环三态，它依照当前值和调用方回填工作。[E35]

TabViewController 的 tabs 是 UnmodifiableListView，select/add/removeAt/move 等方法修改内部数据并 notifyListeners；TabView 的 onChanged 是 controller 已更新后的通知。onNewPressed 只是请求，调用方必须 add，Tab.onClosed 也需要调用方移除。它与 NavigationPane 的“回调请求然后调用方回填”存在实质差别。[E12][E29]

## 9. 真实 API 与消费路径

以下保留已经核对的签名关键部分；为易读省略的参数明确写“节选”，不是完整 API 文档。所有名称和默认值均来自固定源码。

| API（真实签名或节选） | 从哪里进入、怎样消费 | 约束/容易误读处 |
| --- | --- | --- |
| `const FluentApp({home, theme, darkTheme, themeMode, builder, ...})`；另有 `FluentApp.router({...})` | Gallery 用普通构造器，以 home=MyHomePage 启动；下发主题/本地化/路由基础 | 不是必须依赖 Gallery；router 构造器与普通 Navigator 配置分开 [E36] |
| `const NavigationView({titleBar, pane, content, transitionBuilder, paneBodyBuilder, ...})` | pane 配 NavigationPane；或直接给 content | 构造 assert 要求 pane/content 两者恰好一种 [E14] |
| `NavigationPane({int? selected, ValueChanged<int>? onChanged, ..., displayMode=PaneDisplayMode.auto, ...})` | onChanged→保存选择→重新传 selected | effectiveItems 决定索引；changeTo 发请求 [E15] |
| `PaneItem({icon, body, title, ..., enabled=true, selectsOnInvoked=true, semanticLabel, contentBuilder})` | 描述目标页；库构建语义、焦点、tooltip、indicator | 它不是 Widget 子类；继承 NavigationPaneItem，build 由 pane 调用 [E14][E15] |
| `const Button({required child, required onPressed, ..., style, focusable=true})` | 业务回调 + BaseButton/HoverButton | style 按 WidgetStateProperty 解析，状态不是任意字符串 [E33][E34] |
| `const Checkbox({required this.checked, required this.onChanged, ...})` | 回调产生候选 bool?，调用方回填 checked | 可空值行为需自己理解；不会在内部直接持久化 [E35] |
| `const ContentDialog({title, content, actions, style, constraints=kDefaultContentDialogConstraints})` | 作为 showDialog.builder 的内容 | ContentDialog 不负责 push/pop [E27] |
| `Future<T?> showDialog<T extends Object?>({required BuildContext context, required WidgetBuilder builder, ...})` | await 结果；actions 调 Navigator.pop(context,result) | 默认 root=true、点击遮罩不关、Esc 允许；barrierLabel 实参未转发 [E28] |
| `const FlyoutTarget({required FlyoutController controller, required Widget child})` | 将锚点与控制器连接 | showFlyout 前需 attached [E31] |
| `Future<T?> FlyoutController.showFlyout<T>({required WidgetBuilder builder, ..., Duration? reverseTransitionDuration=Duration.zero, ...})` | 以附着目标定位，push 浮层 route | 默认动画/关闭与 ContentDialog 不同 [E31][E32] |
| `TabViewController({List<Tab> initialTabs=const [], int initialIndex=0})` + `const TabView({required controller, ...})` | State 中持有 controller；add/removeAt/select/move | 当前片段的 tabs: 名称过时；controller 自己拥有选择 [E12][E29] |
| `factory FluentThemeData({..., ResourceDictionary? resources, Duration? fasterAnimationDuration, ...})` | App 或局部 FluentTheme 传 theme data；组件读取 token | 有四档时长与 curve，没有在此工厂暴露统一 reduceMotion 字段 [E37] |
| `const DisableAcrylic({required child})` | 在 subtree 显式包一层 | 是关闭材质效果的上下文，不等于自动侦测系统高对比 [E38] |

## 10. 主题 token、材质、动画配置与减少动画边界

### 10.1 主题的实际层次

ResourceDictionary 定义 textFill、controlFill、controlStroke、card、system、focus 等语义颜色，文件注明从微软 Common_themeresources_any.xaml 生成。FluentThemeData 根据 brightness 选 light/dark 字典，派生 typography、强调色、Acrylic/Mica 背景和各组件主题；局部 ButtonTheme、NavigationPaneTheme、ContentDialogTheme 等再做覆盖。[E37][E39]

这使“hover/pressed/disabled 的颜色”可以通过语义 token 持续传播，而不用每个示例硬编码一套色值。标准焦点框也从 resources.focusStrokeColorOuter/Inner 取得内外两层边框。[E23] 但并非每个细节都已 token 化：PaneItem 的 horizontal margin=6 旁仍有 TODO“Put this into the theme”。[E14]

主题覆盖也不是所有字段都能平滑插值。当前 ButtonThemeData.lerp 直接返回空的 ButtonThemeData；它没有逐项插值样式，因此不能仅看到 AnimatedFluentTheme 就断言全部局部按钮样式都连续过渡。[E40]

### 10.2 材质不是原生窗口效果的同义词

公开 Acrylic 在 Flutter 中组合 backdrop filter、tint/luminosity 和噪声层；DisableAcrylic 存在时只画 alpha 强制为 1 的 fallback，不建立 BackdropFilter。这条降级行为有精确实现与 widget 测试。[E38]

Gallery 通过 flutter_acrylic.Window.setEffect 改宿主窗口是另一层平台集成，由 example/AppTheme 和 Settings 管理。两者应分别理解：网页中公开 Acrylic 的背景采样，与桌面窗口对系统桌面内容的透明/材质效果不是相同调用路径。[E05][E06][E38]

AnimatedAcrylic 明确提供 blurAmount tween，实际将动画评估后的 blurAmount 传入 Acrylic；这只是该库提供的能力，不说明每次普通按钮交互都在动画化 blur。[E41] 性能成本必须按使用方式及实际设备验证，本次没有测量。

### 10.3 动画设置的覆盖范围

| 位置 | 本版本可直接确认的设置 |
| --- | --- |
| FluentThemeData | faster 83ms、fast 167ms、medium 250ms、slow 358ms；默认 curve=easeInOut |
| BaseButton | 容器用 faster，文字用 fast |
| NavigationPane/body | pane theme duration/curve；默认由 theme.fastAnimationDuration 派生 |
| Sticky indicator | 使用自身 duration 或 slow/fast theme 值 |
| End indicator | 实现中存在固定 150ms AnimatedContainer |
| showDialog | 显式 duration → theme.fast → 300ms |
| FluentPageRoute | 固定 200ms |
| CodeSnippetCard 的 Copy 提示 | 200ms AnimatedSwitcher，1500ms 复原反馈 |
| HoverButton tap up | 固定 100ms pressed 状态延迟 |

证据：[E09][E16][E17][E22][E26][E28][E34][E37][E42]。所以“统一设置 theme 四个时长就覆盖 Gallery 所有动画”没有源码依据。

**减少动画的严格结论：** 在本次逐行核查的 FluentApp、FluentThemeData、NavigationView/body/indicators、ContentDialog route、Flyout、BaseButton、HoverButton、Acrylic 以及 Gallery 状态链中，没有看到库显式读取 `MediaQuery.disableAnimations` 或 `accessibleNavigation` 并统一切换时长/转场的代码；上述若干位置直接采用固定或主题时长。[E16][E17][E26][E28][E32][E34][E37][E41][E42]

这既不能表述成“已证明完整遵守系统减少动画”，也不能升级成“Flutter 底层完全不处理减少动画”。底层 AnimationController/路由可能还有 SDK 自身策略，本次没有把指定 Flutter SDK 实现纳入审计，也没有设置系统选项实测。公开 SuppressPageTransition 可以直接返回 child，属于显式替代转场能力；不等于系统偏好会自动选用它。[E22]

## 11. 复制、分享和导出的实际能力

**源码证实的 Gallery 能力：**

1. CodeSnippetCard 的 Copy 将原始 widget.codeSnippet 放到 Clipboard；代码显示使用 trim 后的字符串和可选择富文本。既能点按钮复制，也有文字选择及 Windows 风格 contextMenuBuilder。[E09]
2. 图标页点击复制的是 `prefix.iconName` 标识符；控制光标使用 copy，完成后显示 copied 提示。不是导出 SVG、PNG、字体子集或完整应用。[E43]
3. Source code 项打开仓库外链。[E04]
4. README 还声称有 Fluent UI DevTools 图标浏览扩展，可复制标识符和 usage snippet；本次只核对了文档声明及 extension/devtools 目录存在，没有运行扩展或审计其预构建 bundle。[E02]

在上述主入口、CodeSnippetCard 与已研究页面中，没有发现“把当前参数配置序列化为工程”“导出 Flutter 项目”“下载完整示例”这类实现。example 声明了 share_plus 并不足以证明每个组件页有分享或导出按钮；本报告不据依赖名补出功能。[E13]

## 12. 测试、键鼠、无障碍与高对比：证据和局限

| 范围 | 已核查的直接证据 | 此次不能证明 |
| --- | --- | --- |
| 导航自适应 | threshold 边界测试、resize/窄面板/overflow 测试 | 真实窗口所有尺寸无视觉错位 |
| 导航事件与键盘 | invoke/selection 次序；对 FocusNode 请求焦点后发送 Enter | 所有快捷键、所有平台键盘布局与输入法一致 |
| Esc/局部返回 | compact overlay Esc 测试；动态/嵌套/footer 局部历史测试 | 系统返回、浏览器历史与路由整合全部正确 |
| 语义/tooltip | ensureSemantics + bySemanticsLabel；selected 语义；tooltip 可独立开关 | Narrator/NVDA/VoiceOver 实际朗读与焦点反馈 |
| 页面生命周期 | keepAlive 与普通页面的 init/dispose/状态断言 | 所有业务页都正确选择保留策略 |
| 弹窗 | 标题/内容/actions 出现；按钮关闭；单 action 对齐；自定义 style；空内容不崩溃 | Tab 焦点约束、读屏标题宣告、焦点恢复、Esc 跨环境表现 |
| Flyout | controller attached/open/close；点击外部关闭；禁用项不关闭；鼠标 hover 子菜单；LTR/RTL 子菜单 | 触摸、键盘子菜单完整操作与真实屏幕边缘全部定位 |
| Acrylic | 透明 tint/luminosity 计算、repaint boundary 采样、显式禁用 opaque fallback | 各 GPU/渲染器下的实际材质与性能 |
| Button | 约束与主题前景色/文字色覆盖、IconButton 小尺寸样式测试 | 每个状态的截图基准或全控件无障碍认证 |

证据：[E18][E19][E21][E23][E44][E45][E46][E47]。已核查的是代表性测试文件和断言，不是库的完整质量认证。

**性能证据应按断言强度理解。** navigation_view_test 中名为“renders without freezing”“works smoothly”的用例主要 pump/drag 后断言 NavigationView 存在；另有 item_99 不在树中以检查懒构建。它们能提供结构性回归保护，不能替代帧时间、内存、CPU/GPU 的性能基准。[E48] body 的 RepaintBoundary 与失活 TickerMode 是明确优化机制，但不能据此直接给出帧率结论。[E16]

**高对比边界：** 本次核查的 FluentApp 普通/router 构造器提供 theme/darkTheme/themeMode，theme 选择实现按 platformBrightness 决定；FluentThemeData 工厂默认选择 light/dark ResourceDictionary。没有在这些入口看到 highContrastTheme/highContrastDarkTheme 或 MediaQuery.highContrast 的自动分派。[E36][E37] 因而可以说有可定制颜色和焦点 token、可显式 DisableAcrylic，不能说已经自动跟随系统高对比、已经通过对比度标准或在任意用户自定义主题下都可读。

**语言与文字缩放：** Gallery Settings 提供方向、locale 和文字缩放配置，main 的 builder 用 MediaQuery.copyWith(textScaler: ...) 应用缩放；README 列有多语言支持并警告不支持的 locale 可能出错。[E04][E05][E02] 这些是可配置能力，不是所有翻译质量、双向排版、200% 字体放大无截断的实测证明。

## 13. 优点、取舍与不足

### 13.1 可以从代码支撑的优点

- **设计系统覆盖范围广且有消费示例。** 从基础输入、日期、文本到导航、弹窗、图标、材质，不仅有类型导出，还在 Gallery 分组提供实际控件实例与状态操控。[E03][E07]
- **公共控件与示例应用有明确目录/导出边界。** 可以独立使用库，而不携带 Gallery 的 Provider、窗口管理和说明卡；示例则能承担更多宿主集成。[E03][E13]
- **导航行为不仅关注视觉。** 有有效索引、事件顺序、非选择型调用、局部历史、显式页面保留、键盘与语义配置，相关测试能定位具体回归。[E15][E18][E19][E25]
- **主题有语义资源基础。** 状态色、焦点双边框、组件主题与全局 token 的消费路径可追踪，而不是仅在页面写大量最终色值。[E23][E33][E37][E39]
- **提供真实降级路径。** DisableAcrylic 不只是降低透明度，而是去掉过滤与噪声并使用不透明 fallback，有对应断言。[E38][E47]

### 13.2 合理取舍及其代价

- **重视 Windows 设计语言。** 统一 Fluent 外观方便构造 Windows 风格应用，但不能把同一套 Flutter 控件等同于各平台原生 UI/平台无障碍行为。[E02][E04]
- **导航选择留给调用方。** 与外部路由同步容易表达；调用方同时承担索引、key、回调回填、生命周期选择。[E14][E15]
- **默认不长期挂载所有页面。** 有利于限制资源占用；要保留表单/编辑状态的页面需要主动 keepAlive 或由 paneBodyBuilder 管理。[E16][E19]
- **示例代码和效果分开维护。** 阅读和复制简单，但不自动保证同源，需要持续人工保持一致，当前已出现可定位偏差。[E09][E10][E12]
- **主题时长覆盖多数常见控件。** 仍存在固定时长与独立动作延迟；不能把局部设置理解为全局动效策略。[E37][E42]

### 13.3 具体不足与未证实范围

| 项目 | 性质 | 证据边界 |
| --- | --- | --- |
| TabView Copy 使用 tabs:，实际参数为 initialTabs: | 明确 API/片段不一致 | 静态签名已确认；未实际编译复制片段 [E12] |
| showDialog barrierLabel 实参未消费 | 明确传值路径问题 | showDialog 路径证实；直接构造 route 的行为另计 [E28] |
| 弹窗 barrierDismissible/useSafeArea 注释与签名不一致 | 文档/API 一致性不足 | 不推导所有关闭场景失败 [E28] |
| Flyout 示例漏 dispose itemsController | 生命周期遗漏 | 构造注册 observer 与释放路径已证实；未测泄漏规模 [E30][E31] |
| ButtonThemeData.lerp 返回空主题 | 插值实现限制 | 不泛化为所有主题插值失效 [E40] |
| 所研究核心链未显式统一映射系统减少动画 | 能力证据不足 | 未审计 Flutter SDK 底层，也未实测系统开关 |
| 所研究主题入口没有高对比自动选派 | 能力证据不足 | 可自定义颜色，不等于系统高对比已接通 |
| 单维护者声明和文档部分滞后 | 维护取舍 | 固定 README 所述；不是对维护者未来表现的判断 [E02] |

## 14. 许可证

固定提交的 LICENSE 为 BSD 3-Clause 文本，版权署名为 Copyright 2020 Bruno D'Luka。其条款允许有条件的源码/二进制再分发与修改，要求保留版权/条件/免责声明，并限制未经许可用作者或贡献者姓名背书；软件按原样提供。[E49]

这里只报告仓库 LICENSE 本身；没有完成所有字体、图片、示例依赖和传递依赖的逐项许可审计，也没有推导微软商标或视觉资产的授权范围。

## 15. 证据索引

以下链接全部锁定为同一提交：`e183ad9778df9f4e74a3664da6667e63b379f0f8`。范围较长的证据覆盖完整链，不表示其中每行都被正文逐字引用。核心已核查超过 8 个相关源码/测试文件，重点覆盖导航、ContentDialog、Flyout 及其依赖。

| 编号 | 固定源码位置 | 用途 |
| --- | --- | --- |
| E01 | [pubspec.yaml L1-L35](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/pubspec.yaml#L1-L35) | 版本、目标、SDK、依赖 |
| E02 | [README.md L18-L72](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/README.md#L18-L72)；[L119-L168](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/README.md#L119-L168) | 非官方身份、维护声明、安装/DevTools、语言 |
| E03 | [lib/fluent_ui.dart L1-L88](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/fluent_ui.dart#L1-L88) | 公开入口与边界 |
| E04 | [example/lib/main.dart L20-L139](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/main.dart#L20-L139)；[L171-L245](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/main.dart#L171-L245)；[L465-L479](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/main.dart#L465-L479) | 启动、外壳、搜索、主题、外链 |
| E05 | [example/lib/screens/settings.dart L23-L74](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/settings.dart#L23-L74)；[L94-L237](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/settings.dart#L94-L237)；[L260-L390](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/settings.dart#L260-L390) | 平台效果列表、设置能力 |
| E06 | [example/lib/theme.dart L8-L96](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/theme.dart#L8-L96) | Gallery 应用主题状态、窗口效果 |
| E07 | [example/lib/main.dart L271-L477](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/main.dart#L271-L477) | Gallery 页面注册与分组 |
| E08 | [example/lib/routes/navigation.dart L1-L4](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/routes/navigation.dart#L1-L4)；[routes/popups.dart L1-L5](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/routes/popups.dart#L1-L5)；[widgets/page.dart L1-L31](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/widgets/page.dart#L1-L31) | 示例 export 与页面辅助层 |
| E09 | [example/lib/widgets/code_snippet_card.dart L6-L172](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/widgets/code_snippet_card.dart#L6-L172)；[L208-L217](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/widgets/code_snippet_card.dart#L208-L217) | 效果/字符串分离、复制/选择、动效 |
| E10 | [example/lib/screens/popups/content_dialog.dart L12-L99](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/popups/content_dialog.dart#L12-L99) | 弹窗示例完整状态链、片段偏差 |
| E11 | [example/lib/screens/navigation/navigation_view.dart L16-L153](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/navigation/navigation_view.dart#L16-L153)；[L154-L325](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/navigation/navigation_view.dart#L154-L325)；[L351-L518](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/navigation/navigation_view.dart#L351-L518) | 导航示例、真实消费、独立 route |
| E12 | [example/lib/screens/navigation/tab_view.dart L14-L30](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/navigation/tab_view.dart#L14-L30)；[L160-L202](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/navigation/tab_view.dart#L160-L202)；[tab_view_controller.dart L11-L20](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/tab_view/tab_view_controller.dart#L11-L20) | tabs / initialTabs 不一致 |
| E13 | [example/pubspec.yaml L1-L42](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/pubspec.yaml#L1-L42) | Gallery 独立依赖 |
| E14 | [navigation_view/view.dart L84-L159](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L84-L159)；[pane_items.dart L127-L220](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane_items.dart#L127-L220)；[L265-L327](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane_items.dart#L265-L327)；[L469-L534](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane_items.dart#L469-L534) | 导航职责、交互、语义、定制 |
| E15 | [navigation_view/pane.dart L101-L140](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane.dart#L101-L140)；[L242-L268](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane.dart#L242-L268)；[L363-L427](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane.dart#L363-L427)；[L457-L483](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane.dart#L457-L483) | 回调、有效索引、item 调用链 |
| E16 | [navigation_view/view.dart L740-L754](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L740-L754)；[body.dart L74-L262](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/body.dart#L74-L262) | body 选择、动画、keepAlive、TickerMode |
| E17 | [utils/hover_button.dart L261-L438](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/utils/hover_button.dart#L261-L438) | 手势、状态、键盘 Action、焦点语义 |
| E18 | [test/navigation_view_test.dart L1265-L1330](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1265-L1330) | invoke/selection/Enter 测试 |
| E19 | [test/navigation_view_test.dart L1540-L1592](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1540-L1592) | 页面保留生命周期测试 |
| E20 | [navigation_view/view.dart L675-L710](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L675-L710) | 自适应宽度判断 |
| E21 | [test/navigation_view_test.dart L1205-L1263](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1205-L1263) | 默认/自定义阈值边界测试 |
| E22 | [styles/page_transitions.dart L9-L177](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/styles/page_transitions.dart#L9-L177) | 三种转场和 Suppress |
| E23 | [utils/focus.dart L89-L114](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/utils/focus.dart#L89-L114)；[L185-L227](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/utils/focus.dart#L185-L227)；[test/navigation_view_test.dart L1594-L1663](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1594-L1663) | 焦点资源、语义/tooltip 独立测试 |
| E24 | [navigation_view/view.dart L880-L905](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L880-L905) | Esc 关闭导航 overlay |
| E25 | [navigation_view/view.dart L357-L438](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L357-L438)；[title_bar.dart L748-L817](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/title_bar.dart#L748-L817) | 本地历史与 PaneBackButton |
| E26 | [lib/src/fluent_page_route.dart L58-L106](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/fluent_page_route.dart#L58-L106) | 独立 route、语义、200ms |
| E27 | [flyouts/content_dialog.dart L62-L177](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/content_dialog.dart#L62-L177) | ContentDialog 职责与布局 |
| E28 | [flyouts/content_dialog.dart L242-L377](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/content_dialog.dart#L242-L377) | showDialog、route、转场、焦点/返回及注释差异 |
| E29 | [tab_view_controller.dart L7-L118](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/tab_view/tab_view_controller.dart#L7-L118)；[tab_view.dart L99-L140](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/tab_view/tab_view.dart#L99-L140) | controller 状态所有权 |
| E30 | [example/lib/screens/popups/flyout.dart L8-L47](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/popups/flyout.dart#L8-L47)；[L153-L188](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/popups/flyout.dart#L153-L188) | Flyout 示例状态/调用及 dispose |
| E31 | [flyouts/flyout.dart L649-L709](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/flyout.dart#L649-L709)；[L762-L842](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/flyout.dart#L762-L842)；[L902-L965](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/flyout.dart#L902-L965)；[L1234-L1262](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/flyout.dart#L1234-L1262) | 控制器 attachment/route/关闭/释放 |
| E32 | [flyouts/flyout.dart L1163-L1227](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/flyout.dart#L1163-L1227) | 指针离开、Esc、焦点、默认 fade |
| E33 | [buttons/button.dart L78-L119](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/button.dart#L78-L119)；[buttons/theme.dart L332-L365](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/theme.dart#L332-L365) | Button 签名与状态 token |
| E34 | [buttons/base.dart L100-L133](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/base.dart#L100-L133)；[L150-L255](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/base.dart#L150-L255) | enabled、样式优先级、视觉动画 |
| E35 | [inputs/checkbox.dart L83-L120](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/inputs/checkbox.dart#L83-L120)；[L149-L164](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/inputs/checkbox.dart#L149-L164) | Checkbox 受控值与回调 |
| E36 | [lib/src/fluent_app.dart L51-L112](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/fluent_app.dart#L51-L112)；[L448-L503](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/fluent_app.dart#L448-L503) | FluentApp 真实入口与主题选择 |
| E37 | [styles/theme.dart L206-L215](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/styles/theme.dart#L206-L215)；[L425-L522](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/styles/theme.dart#L425-L522) | 主题 token、时长、颜色选择 |
| E38 | [surfaces/acrylic.dart L527-L570](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/surfaces/acrylic.dart#L527-L570)；[L742-L762](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/surfaces/acrylic.dart#L742-L762) | 材质渲染与显式降级 |
| E39 | [styles/color_resources.dart L1-L100](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/styles/color_resources.dart#L1-L100) | 资源字典与来源声明 |
| E40 | [buttons/theme.dart L270-L290](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/theme.dart#L270-L290) | ButtonThemeData.lerp/merge |
| E41 | [surfaces/acrylic.dart L287-L302](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/surfaces/acrylic.dart#L287-L302)；[L380-L438](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/surfaces/acrylic.dart#L380-L438) | AnimatedAcrylic 参数和 tween 消费 |
| E42 | [navigation_view/indicators.dart L138-L165](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/indicators.dart#L138-L165)；[L260-L306](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/indicators.dart#L260-L306) | indicator 的固定/主题时长 |
| E43 | [example/lib/screens/theming/icons.dart L221-L255](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/theming/icons.dart#L221-L255) | 图标标识符复制 |
| E44 | [test/navigation_view_test.dart L1333-L1417](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1333-L1417)；[L1503-L1538](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1503-L1538) | 局部历史与 Esc 测试 |
| E45 | [test/content_dialog_test.dart L7-L81](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/content_dialog_test.dart#L7-L81)；[L83-L207](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/content_dialog_test.dart#L83-L207) | ContentDialog 测试 |
| E46 | [test/flyout_test.dart L10-L208](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/flyout_test.dart#L10-L208)；[L234-L441](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/flyout_test.dart#L234-L441) | Flyout 鼠标/菜单/LTR/RTL 测试 |
| E47 | [test/acrylic_test.dart L7-L82](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/acrylic_test.dart#L7-L82)；[L95-L151](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/acrylic_test.dart#L95-L151)；[L249-L277](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/acrylic_test.dart#L249-L277) | 材质数值/结构/降级测试 |
| E48 | [test/navigation_view_test.dart L395-L540](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L395-L540)；[test/button_test.dart L13-L164](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/button_test.dart#L13-L164) | 性能命名用例的断言边界、按钮测试 |
| E49 | [LICENSE L1-L11](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/LICENSE#L1-L11) | BSD 3-Clause 文本 |

## 16. 交付边界与复核重点

研究稿已覆盖项目身份与目标、Gallery 目录、公开/示例边界、导航与弹窗完整调用链、锚点浮层、真实签名与状态所有权、主题/动画、复制能力、测试与无障碍证据及许可证。可优先复核 E12、E28、E30/E31 所列的三类确定性一致性/生命周期问题。

本次未做：程序启动、截图对照、复制片段编译、测试/构建执行、系统减少动画/高对比实测、读屏器/键盘全流程、真实平台兼容及性能测量、依赖完整许可审计。所有效果描述均来自固定源码与文档；在线 Gallery 的当前部署是否等于该 SHA 未验。

[E01]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/pubspec.yaml#L1-L35
[E02]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/README.md#L18-L72
[E03]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/fluent_ui.dart#L1-L88
[E04]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/main.dart#L20-L139
[E05]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/settings.dart#L23-L74
[E06]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/theme.dart#L8-L96
[E07]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/main.dart#L271-L477
[E08]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/routes/navigation.dart#L1-L4
[E09]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/widgets/code_snippet_card.dart#L6-L172
[E10]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/popups/content_dialog.dart#L12-L99
[E11]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/navigation/navigation_view.dart#L16-L153
[E12]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/navigation/tab_view.dart#L14-L30
[E13]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/pubspec.yaml#L1-L42
[E14]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L84-L159
[E15]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane.dart#L101-L140
[E16]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L740-L754
[E17]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/utils/hover_button.dart#L261-L438
[E18]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1265-L1330
[E19]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1540-L1592
[E20]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L675-L710
[E21]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1205-L1263
[E22]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/styles/page_transitions.dart#L9-L177
[E23]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/utils/focus.dart#L89-L114
[E24]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L880-L905
[E25]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/view.dart#L357-L438
[E26]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/fluent_page_route.dart#L58-L106
[E27]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/content_dialog.dart#L62-L177
[E28]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/content_dialog.dart#L242-L377
[E29]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/tab_view/tab_view_controller.dart#L7-L118
[E30]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/popups/flyout.dart#L8-L47
[E31]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/flyout.dart#L649-L709
[E32]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/flyout.dart#L1163-L1227
[E33]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/button.dart#L78-L119
[E34]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/base.dart#L100-L133
[E35]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/inputs/checkbox.dart#L83-L120
[E36]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/fluent_app.dart#L51-L112
[E37]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/styles/theme.dart#L206-L215
[E38]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/surfaces/acrylic.dart#L527-L570
[E39]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/styles/color_resources.dart#L1-L100
[E40]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/buttons/theme.dart#L270-L290
[E41]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/surfaces/acrylic.dart#L287-L302
[E42]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/indicators.dart#L138-L165
[E43]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/example/lib/screens/theming/icons.dart#L221-L255
[E44]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L1333-L1417
[E45]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/content_dialog_test.dart#L7-L81
[E46]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/flyout_test.dart#L10-L208
[E47]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/acrylic_test.dart#L7-L82
[E48]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/test/navigation_view_test.dart#L395-L540
[E49]: https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/LICENSE#L1-L11

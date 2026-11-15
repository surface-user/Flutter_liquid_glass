# shadcn_flutter 独立源码研究

- 状态：**REVIEW**。静态证据与引用已复核；等待主研究汇合。本报告不代表运行验收。
- 研究日期：2026-11-15（Asia/Shanghai）。
- 对象：[sunarya-thito/shadcn_flutter](https://github.com/sunarya-thito/shadcn_flutter)。
- 固定分支：`master`；完整 SHA：`611caafcdfa0da659924c7a7679083714b917d17`。
- 提交时间：2026-10-01 09:08:40 UTC；提交信息：`Add model response catalog contract test`。
- 获取方式：GitHub 连接器只读读取仓库元数据、递归树及固定 SHA 文件。未克隆仓库，未安装依赖，未执行生成器、分析、测试、构建或浏览器操作。
- 独立性：只根据该公开项目材料理解项目，不与其他项目比较，不提供迁移建议。未使用用户记忆、产品定位、差距文档或其他研究报告。

## 1. 判断方法与结论边界

本文以“能否追到真实实现与消费点”为依据，不按组件数量、截图或 README 宣传评定完整性。证据等级：

| 标记 | 含义 |
| --- | --- |
| 文档声称 | 官方 README、说明文字或示例注释表达的意图，不自动视为实现事实 |
| 源码证实 | 固定 SHA 的声明、调用、状态读写或测试断言可直接支持的行为 |
| 推断 | 从明确代码路径推得的影响，尚未运行复现 |
| 运行未验 | 浏览器视觉、真机输入、屏幕阅读器、性能、测试成功状态均不在本次证据内 |

“仓库存在测试”只说明作者编写了相应断言，不等于这些断言已在本次环境通过。搜索没有结果也不等于平台完全不支持某功能。

五个核心事实：

1. 这是以 Flutter Widgets 为底座的组件库及配套生态；公共包、文档应用、互操作包、开发工具和 GenUI Catalog 是不同职责。[E01–E04、E60–E62]
2. Gallery 卡片和组件详情页必须区别：卡片内示意被 `IgnorePointer`/`ExcludeFocus` 包住，点击进入示例页；详情页才直接挂载可交互 Widget。[E10–E13]
3. NavigationBar 的选择由调用者通过 `selectedKey/onSelected` 持有，点击链穿过 NavigationItem→SelectedButton→Button→Clickable；它不自动绑定应用路由。[E18–E20、E35]
4. 弹窗有真实打开、过渡、关闭和结果返回链；统一 `showOverlay` 并不意味着每种机制的外部 Completer 关闭能力相同。Popover 默认在移动平台转为 Drawer。[E22–E32]
5. 当前 GenUI 是受 Catalog/schema 限制的 A2UI 渲染和交互适配；文档页保留了与当前源码不一致的旧 DSL。它不能作为“已支持任意场景可视化编辑器”的证据。[E46–E51]

## 2. Monorepo 的包职责

根 workspace 列出了九个成员（含两个 example）；根包 `publish_to: none`。这不是九套独立组件系统。[E02]

| 目录 | 可证职责 | 不能直接等同的能力 |
| --- | --- | --- |
| `packages/shadcn_flutter` | 发布的 Dart/Flutter 公共库；当前 pubspec 版本 0.0.55；SDK ≥3.13.0、Flutter ≥3.47.0；依赖 Flutter、data_widget、animation_kit、gap；公共入口导出组件、主题、工具、图标、预览辅助及部分 Flutter Widgets。[E03、E04] | 不是 docs 应用，也不是 AI 会话运行时 |
| `packages/docs` | Flutter 文档/Gallery 应用；使用 GoRouter、shared_preferences、http、语法高亮和各互操作包；组织路由、示例、主题工作台和代码面板。[E05–E16、E43] | 不能把 docs 内的界面控件当作公共库必然导出的工具 |
| `packages/shadcn_flutter/example` | 根 README 定义的最小消费应用。[E01] | 本次未展开验证其全部平台目录 |
| `packages/shadcn_flutter_material` | MaterialShadcnApp、MaterialLayer、上下文菜单及少量不冲突符号重导出，提供 Material 祖先和本地化接入。[E60] | 核心库本身不因此强制依赖 Material |
| `packages/shadcn_flutter_cupertino` | CupertinoShadcnApp、CupertinoLayer、上下文菜单和选择控件等接入。[E61] | 与核心导航条并非同一个组件 |
| `packages/shadcn_flutter_skeletonizer` | SkeletonizerLayer 及骨架屏依赖接入，相关扩展与主题脉冲属于伴随包。[E62] | 核心库未自动安装所有骨架屏能力 |
| `packages/gen` | 根 README 明确为图标、样式、颜色、docs、LLM 参考材料生成工具；目录树存在相应 bin 脚本。[E01] | 开发期生成器不等于用户的场景导出器 |
| `packages/shadcn_flutter_genui` | 独立 A2UI Catalog 和 shadcn Widget renderers；公开入口只导出 gen_catalog；运行时、会话、DataModel 和传输由 genui 提供。[E46–E48] | 不等于完整 AI IDE 或任意 Flutter 代码执行器 |
| `packages/shadcn_flutter_genui/example` | README 指向的 OpenRouter 会话接入示例。[E46] | 本次未请求实际模型或验证联网会话 |

**文档声称**：Introduction 称“cohesive ecosystem”，并称支持六平台、可混用 Material/Cupertino。[E63]
**源码证实**：核心 pubspec 依赖与互操作包分离，docs 在 surfaceBuilder 中安装 MaterialLayer、CupertinoLayer、SkeletonizerLayer，根应用单独注册本地化。[E03、E43、E60–E62]
**运行未验**：不能据此断言六个平台行为、视觉和性能已全部验收。

公开入口会重新导出 Flutter Widgets，同时隐藏并替换部分同名布局与表单符号；消费端同名类的来源需要看实际 import。公共 `AlertDialog` 的来源是该库，不能只因名称熟悉就当成 Material 实现。[E04、E59]

## 3. 文档/Gallery 的信息结构与真实预览

### 3.1 页面和组件组织

DocsPage 定义 Getting Started、组件分类和各页面条目，GenUI 标有 experimental。Gallery 主页面按 Animation、Disclosure、Feedback、Forms、Layout、Navigation、Surfaces、Data Display、Utilities 等分区摆放卡片，还显示 Work in Progress；部分 Data Table/Chart 是 WIP 卡片，而其他位置存在实际 Table。因此不能把标签、占位卡和可用组件混计。[E05、E09]

组件详情统一经过 ComponentPage：标题、描述、返回 Components 的导航，以及根据 WidgetUsageExample.title 构造的页内目录。Button 页把 Primary、Secondary、Outline、Ghost、尺寸、密度、形状、组合等示例依次列出；本次读到的公共详情包装器是“多个有标题的示例区块”，不是统一的示例下拉选择器。[E12、E16]

DocsPage 还有文档搜索入口和快捷键绑定；这是文档导航能力，不是组件场景编辑器。其具体浏览器布局、窄屏表现和搜索可用性本次未实测。

### 3.2 两种“预览”不可混同

| 位置 | 实现 | 交互性质 |
| --- | --- | --- |
| Gallery 列表卡片 | ComponentCard 外层 Clickable 跳 `context.pushNamed(widget.name)`；内层 `ExcludeFocus`、`IgnorePointer`，200px 高区域内缩放/裁剪内容 | 主要作为导航缩略示意，内层不会直接操作 |
| 导航条卡片 | NavigationBarTile 实际手写 Card/Row/Column/Icon/Text，未实例化 NavigationBar | 图形示意不是组件本身运行证据 |
| Dialog 卡片 | 直接内嵌 AlertDialog 内容，Save 回调为空 | 不代表真正打开了独立模态路由 |
| 组件详情示例 | WidgetUsageExample 的 `Center(child: widget.child)` 直接构造真实 Widget | 可执行实例，其结果由每个示例自己的状态和回调决定 |
| 开发者预览 | 公共 `ShadcnPreview/MultiPreview` 封装 Flutter `widget_previews` 并安装 ShadcnLayer | 开发工具预览注解，不是网站自由编辑画布 |

证据：[E10–E13、E45、E59]。这一区分使“页面有组件外观”和“用户能在页面中验证完整交互”成为不同命题。

### 3.3 参数、代码和预览之间的关系

导航示例内确实提供参数控件：alignment、labelType、customButtonStyle、expanded；它们由示例 State 管理，并直接改变导航条。参数名称和值使用 Select、Checkbox 组合，属于该示例特制控制面板。[E18]

WidgetUsageExample 本身只接收 title、child、path、summarize，没有从 Dart 构造函数自动生成属性面板的逻辑。**源码证实**的是特定示例有参数控件，不能扩张成“所有组件都有统一参数编辑器”。[E13]

代码面板 `CodeBlockFutureBuilder` 对 `raw.githubusercontent.com/.../master/packages/docs/${path}` 发 HTTP 请求，再用正则摘要或展示全文；外链也指向 master。[E14] 这会带来两个明确限制：

- **推断**：已经部署的二进制预览可能来自旧提交，而代码文字来自当时最新 master；两者不是固定版本绑定。
- HTTP 响应直接取 `response.body`，没有按状态码验证成功；请求/摘要失败路径存在，但不能保证展示内容一定是可编译示例。代码面板也不是用户正在交互的 Widget 的即时源码序列化。

本报告所有分析链接固定 SHA，避免跟着该动态 master 链漂移。

## 4. 导航完整链：从文档入口到选择结果

| 步骤 | 实际路径/消费点 | 可见或状态结果 | 证据 |
| --- | --- | --- | --- |
| 文档入口 | DocsPage 的 Navigation→Navigation Bar；GoRoute 的 `navigation_bar` builder 返回 NavigationBarExample | 进入指定详情页 | E05、E08 |
| Gallery 入口 | NavigationBarTile→ComponentCard，点击 pushNamed | 从静态示意进入详情 | E10、E11 |
| 示例选择 | ComponentPage→WidgetUsageExample(path, child: NavigationBarExample1()) | 示例与对应代码文件在同一区块 | E17 |
| 初始状态 | State 内 `Key? selected = const ValueKey(0)` | 初始 Home 被选中 | E18 |
| API 输入 | NavigationBar 接收 `selectedKey: selected` 与 `onSelected` | 状态来自父调用者 | E18、E19 |
| 子项消费 | NavigationControlData 下发 selectedKey；NavigationItem 用 `widget.selected ?? (key != null && key == data?.selectedKey)` | 显式 selected 可覆盖父选择结果 | E19、E20 |
| 点击链 | SelectedButton 切换 bool；NavigationItem 先调用自身 onChanged，key 非空且 value 为 true 才调用父 onSelected(key) | 回调把 key 交回示例 | E20 |
| 父更新 | onSelected 内 setState 更新 selected | 选中样式、背景颜色按 key 更新 | E18 |
| 参数更新/过渡 | Select/Checkbox 各自 setState；Bar 在设置 expandedSize/collapsedSize 时使用 AnimatedValueBuilder(kDefaultDuration) | 参数立即作用于真实组件；尺寸动画有条件触发 | E18、E19 |

**源码证实**：该链选择的是 key，并没有调用 Navigator 或 GoRouter；示例可见结果是选中样式和颜色变化。NavigationBar 不是内建路由管理器。StatefulWidget 也不代表它替调用者保存 selectedKey——`_onSelected` 只是把 key 回调出去。[E18、E19]

**组合取舍**：父 NavigationBar、NavigationItem 的 key、可选 label、普通/选中 ButtonStyle、布局 Scaffold 相互组合；同一底层选择项可由 NavigationRail/Sidebar 等容器共享概念，但本次完整追踪仅对 Bar 作行为结论。Key 必须有稳定身份；没有 key 的 item 不会走父 onSelected 分支。[E20]

## 5. 弹窗完整链：模态 Dialog 和锚定 Popover

### 5.1 Dialog：编辑表单→关闭→结果

| 步骤 | 源码事实 | 证据 |
| --- | --- | --- |
| 页面入口 | Gallery/Dialog 或 DocsPage/Surfaces/Dialog；路由 builder→DialogExample | E05、E07、E09 |
| 真正示例 | WidgetUsageExample→DialogExample1，PrimaryButton 显示 Edit Profile | E21、E22 |
| 打开 | onPressed 调 `showOverlay(context, DialogConfiguration(), builder: ...)` | E22、E23 |
| 展示机制 | DialogConfiguration 找 Navigator，capture themes/data，构造 DialogRoute，push route | E24 |
| 焦点和安全区域 | DialogConfiguration 默认 useRootNavigator/useSafeArea=true，traversalEdgeBehavior 默认 closedLoop；route 给 barrier 默认 'Dismiss' 标签 | E24、E25 |
| 内容组合 | AlertDialog(title/content/actions)；FormController、Form、FormField、TextField，首输入 autofocus=true | E22 |
| 过渡 | DialogRoute 固定 150ms；ScaleTransition 从 0.7 到 1.0 叠 FadeTransition，FocusScope 包裹 | E25 |
| 关闭与返回 | Save changes→`Navigator.of(context).pop(controller.values)` | E22 |
| 结果消费 | 此 docs 示例忽略 showOverlay 返回对象，未把返回值更新到外层 UI；测试另行 .future.then 保存 confirmed 并断言 | E22、E52 |

示例注释称“Present a Material dialog”，但 import 来自 shadcn_flutter，执行点是自定义 DialogConfiguration/DialogRoute。以调用实现判断，这是库自身的模态路由机制，不应把注释作为 Material API 事实。[E22–E25]

**AlertDialog 的边界**：它构造 ModalBackdrop 与 ModalContainer 及标题/内容/动作布局；开窗行为由 showOverlay/DialogConfiguration 完成。把 AlertDialog 直接放在普通树里可以显示内容，但并没有因此创建独立路由。[E24、E59]

### 5.2 Popover：锚点→显示→关闭和自适应

示例用 `OverlayAnchor(anchor: #popoverButton)` 包裹 PrimaryButton；打开 `PopoverConfiguration(anchor: LinkedAnchor(#popoverButton), alignment: Alignment.topCenter, offset: Offset(0, 8))`，内容是 ModalContainer+Form。Submit 只调用 `closeOverlay(context)`；`.future.then` 仅在 debug 打印关闭信息，没有保存尺寸值或导出场景。[E28]

桌面 Popover 路径：

1. 解析锚点，检查可见性，capture theme/data，生成 OverlayEntry，必要时增加 barrier。
2. 内部 FocusScope，AnimatedValueBuilder 由 isClosed 驱动；PopoverLayout 动态布局，缩放 0.9→1.0 并淡入。
3. 点击外部或 closeOverlay 让 isClosed 变为 true，并完成结果 completer。
4. 动画到 0 后移除、dispose entry，完成 animationCompleter。

证据：[E26、E29–E31]。这也说明 `.future` 和动画移除时点不能笼统当成同一事件；popover 的普通结果 future 在退场动画完成前就可能已完成。

默认 `showOverlay(adaptive: true)` 会调用 adaptiveConversion；Popover 在 `isMobile(Theme.of(context).platform)` 时变成底部 Drawer。当前 toDrawer 只传 anchor、position、barrierDismissible，桌面的 alignment/offset/尺寸限制等并非逐项保留。这个取舍让移动端获得不同展示机制，也让“相同配置”不等于“跨平台相同几何外观”。`adaptive: false` 或 `.nonAdaptive` 可保留真正 Popover。[E23、E30、E52]

### 5.3 统一入口不等于完全统一生命周期能力

**源码证实的限制**：

- DialogConfiguration 返回的是包住 Navigator.push Future 的 `_FutureOverlayCompleter`。它的 remove/dispose 是空实现；继承的 close 最终调用 remove，因而外部拿到这个对象调用 close 不能据源码认定能关闭 Dialog。[E24、E26、E32]
- Dialog 内容内部则有 `_DialogOverlayContentCompleter`，closeWithResult 会 pop/remove route，因此内容里的 `closeOverlay(context, value)` 有实际关闭路径。[E27]
- OverlayController 对同 runtimeType 的已打开对象只设置 `completer.config` 并返回旧 future；base config setter 是空实现，Dialog 的 Future adapter 没有覆盖它。**推断**：Controller 对 Dialog 的更新/关闭能力不等同于可原位更新的 Popover，声明的通用接口不能替代逐机制核查。[E26、E32]

以上是静态控制流结论，未运行复现；不把它泛化为“所有弹层关闭都失败”。

## 6. 公共 API：真实签名、消费位置与调用例

下表列必要签名；“节选”明确表示省略无关可选参数，不是完整构造声明。默认值和参数名按固定源码；尤其 `barrierDismissable`（Popover）和 `barrierDismissible`（Dialog）拼写不同。

| API | 真实声明或明确节选 | 消费点/实际例 |
| --- | --- | --- |
| Button | 构造节选：`const Button({super.key, required this.child, required this.style, this.onPressed, this.enabled, this.focusNode, this.statesController, this.disableTransition = false, this.disableHoverEffect = false, this.disableFocusOutline = false, ...})`；onPressed 为 VoidCallback?，style 为 AbstractButtonStyle | ButtonState→Clickable，enabled 默认取 onPressed!=null，传递焦点、状态、回调和样式解析器。[E33、E35] |
| PrimaryButton | 构造节选：`const PrimaryButton({super.key, required this.child, this.onPressed, this.enabled, this.leading, this.trailing, this.alignment, this.size = ButtonSize.normal, this.density = ButtonDensity.normal, this.shape = ButtonShape.rectangle, this.focusNode, this.disableTransition = false, this.onHover, this.onFocus, this.enableFeedback, ..., this.theme})` | build 转成 Button(style: ButtonStyle.primary(...))；Dialog示例用它打开和保存。[E22、E34] |
| NavigationBar | 完整参数集合：`const NavigationBar({super.key, required this.children, this.alignment = NavigationBarAlignment.start, this.direction, this.labelType = NavigationLabelType.all, this.labelPosition = NavigationLabelPosition.bottom, this.labelSize = NavigationLabelSize.small, this.backgroundColor, this.padding, this.surfaceOpacity, this.surfaceBlur, this.selectedKey, this.onSelected, this.expanded = false, this.keepCrossAxisSize, this.keepMainAxisSize, this.expandedSize, this.collapsedSize, this.spacing, this.theme})` | selectedKey 类型 Key?；onSelected 类型 ValueChanged<Key?>?；经 NavigationControlData 消费。[E19] |
| NavigationItem | `const NavigationItem({super.key, this.selectedStyle, this.selected, this.onChanged, super.label, super.spacing, super.style, super.alignment, super.enabled, super.overflow, super.marginAlignment, required super.child})` | selected 为 bool?；onChanged 为 ValueChanged<bool>?；比较 key 与父 selectedKey，再交给 SelectedButton。[E20] |
| showOverlay | `OverlayCompleter<T?> showOverlay<T>(BuildContext context, OverlayConfiguration configuration, {required WidgetBuilder builder, bool adaptive = true})` | 调 configuration.adaptiveConversion(context)，随后 resolved.show<T>。[E23] |
| DialogConfiguration | `const DialogConfiguration({this.useRootNavigator = true, this.barrierDismissible = true, this.barrierColor, this.barrierLabel, this.useSafeArea = true, this.routeSettings, this.anchorPoint, this.traversalEdgeBehavior, this.alignment, this.fullScreen = false})` | Navigator.push(DialogRoute)，结果由 .future 获取。[E24] |
| PopoverConfiguration | 完整参数集合见 E29；关键必需项只有 `required this.alignment`；anchor 可选，rootOverlay/modal/barrierDismissable/follow/consumeOutsideTaps 默认 true | showDuration/dismissDuration 是可选 Duration?；锚点跟随及外点关闭在 E30/E31 消费，移动平台可先转 Drawer |
| closeOverlay | `Future<void> closeOverlay<T>(BuildContext context, [T? value])` | 找当前内容继承的 OverlayCompleter，调用 closeWithResult(value)；找不到时返回已完成 Future。[E26] |
| AlertDialog | `const AlertDialog({super.key, this.leading, this.title, this.content, this.actions, this.trailing, this.surfaceBlur, this.surfaceOpacity, this.barrierColor, this.padding})` | 负责布局与表面，未负责 push 路由。[E59] |

从项目示例抽出的最小消费形式如下，意在表达现有 API，不是本次新增并验证的程序：

```dart
NavigationBar(
  selectedKey: selected,
  onSelected: (key) => setState(() => selected = key),
  children: [
    NavigationItem(
      key: const ValueKey(0),
      label: const Text('Home'),
      child: const Icon(BootstrapIcons.house),
    ),
  ],
);

showOverlay<String>(
  context,
  const DialogConfiguration(),
  builder: (dialogContext) => PrimaryButton(
    onPressed: () => Navigator.of(dialogContext).pop('confirmed'),
    child: const Text('Confirm'),
  ),
).future.then((value) {
  // 调用者消费 value。
});
```

依据 E18、E20、E52。导航状态和 UI 回调仍由调用方决定；Dialog 的返回值也只有被调用方接收后才构成外层业务结果。

## 7. 状态管理与组合模型

### 7.1 受控值与内部状态须按组件区分

NavigationBar 的 selectedKey、Checkbox 的 state 和 SelectedButton 的 value 都是外部值驱动思路；StatefulWidget 内部也会管理交互状态，但不会自动成为业务值的唯一来源。Checkbox 构造要求 state/onChanged，用户交互调用回调，调用方负责重新提供 state。[E19、E20、E39]

命名为 ControlledCheckbox 的包装器反而通过 ControlledComponentAdapter 同时支持：

- 提供 controller：初始值取 controller.value，监听变更；
- 无 controller：initialValue 初始化内部 `_value`；
- 用户变化：先调用 onChanged，再写 controller 或 setState 修改内部值。

因此不能只按类名把所有 Controlled* 解释成“必须由父组件每次传值”。[E37、E38]

**实现边界**：Adapter 的 didUpdateWidget 只在 controller 身份变化时换 listener，未看到同步新 controller.value、重新消费 initialValue 或 dispose 移除 listener 的实现；外部 controller 变化触发的 listener 也只 setState，不调用 onChanged。**推断**：动态替换控制器、卸载后控制器继续存活等场景需要专门验证，不能把注释里“所有程序变化都会回调”无条件当成事实。[E37]

### 7.2 组合方式与代价

组件主要通过 Widget 子树、builder、样式对象、ComponentTheme/Data 继承组合。导航容器提供控制数据，item 把选择表达为 SelectedButton；弹窗 configuration 提供机制，builder 提供内容，AlertDialog/ModalContainer 提供表面，Form 提供值与校验。职责可复用，但使用者需要理解主题祖先、key 身份、上下文所在弹层以及关闭结果的不同阶段。[E19、E20、E23–E27、E59]

## 8. 主题、动画、减少动画、高对比与输入可访问性

### 8.1 已有主题与样式能力

ThemeData 有 colorScheme、typography、radius、scaling、iconTheme、surfaceOpacity、surfaceBlur、enableFeedback、density 和平台覆盖；提供明暗构造。组件再通过普通/选中 ButtonStyle、ComponentTheme 或 widget 属性控制外观。[E19、E20、E34、E40]

Docs 的 Theme 页提供明暗、base/accent、radius、density、scaling、opacity、blur 等选择；实时 kitchen preview 与 `buildCode()` 生成的 ShadcnApp 配置片段一起展示。MyAppState 把相关偏好写入 SharedPreferences。[E41–E43]

这是“主题配置工作台”可证实的能力；生成的代码是主题参数片段，默认状态甚至返回带 `...` 占位的 ShadcnApp。不能把它称为完整可构建应用导出。[E42]

### 8.2 动画的具体事实与限制

| 范围 | 源码事实 | 限制 |
| --- | --- | --- |
| 通用时长 | kDefaultDuration=150ms | 默认常量，不是自动运动偏好策略。[E64] |
| Button/Clickable | Button 传 disableTransition，Clickable 仍有按压 transform 的 50ms AnimatedValueBuilder；Button 自定义 alignment 另有 AnimatedAlign(kDefaultDuration) | 单个 disableTransition 不能据此认定关闭所有相关动画。[E35、E36] |
| NavigationBar | expandedSize/collapsedSize 非空才构造尺寸 AnimatedValueBuilder | docs 切换 expanded 不等于必然触发该尺寸支路。[E19] |
| Dialog | 固定150ms，0.7→1缩放+淡入 | DialogConfiguration 无公开 duration 参数。[E24、E25] |
| Popover | 可传 showDuration/dismissDuration；scale0.9→1+fade | 当前 isClosed 为 true 的支路取 showDuration，false 支路取 dismissDuration，与名称所暗示的方向相反；静态事实，未运行测时。[E30、E31] |
| 主题 | ShadcnApp/Layer 有 enableThemeAnimation 字段；ShadcnAnimatedTheme 支持 duration==zero 直接 Theme | 已读 Layer.build 仍固定 duration:kDefaultDuration，未消费该 flag 来选时长；不能只看到字段就宣布开关有效。[E44] |

针对公共库和 docs 核查了 `MediaQuery.disableAnimations`、`accessibleNavigation`、`highContrast` 等显式接入。本次 GitHub 默认分支代码搜索 disableAnimations/highContrast 返回零结果；在本报告追踪的主题、按钮、导航、Dialog/Popover 文件也没有相应显式判断。

这支持的结论仅是：**未找到该库自身统一的减少动画/高对比策略证据**。Flutter 框架或 animation_kit 依赖可能自行处理部分平台行为，本次未对依赖实现、浏览器 prefers-reduced-motion、系统高对比或屏幕阅读器进行实测，不能宣布它们完全失效，也不能宣布全组件支持。

### 8.3 已有键鼠、焦点与未完成的证明

- Clickable 使用 FocusableActionDetector；Enter/Space→ActivateIntent，四方向键→DirectionalFocusIntent；onShowFocusHighlight 更新 focused state；支持外传 focusNode、shortcuts、actions，外层 FocusOutline。[E36]
- Button 将 focusNode/onFocus/onHover 传入 Clickable；FocusOutline 使用 colorScheme.ring、可主题化边框，并有150ms动画。[E35、E65]
- Dialog 默认 closedLoop 焦点遍历、FocusScope、safe area、barrier label；示例首输入 autofocus=true。[E22、E24、E25]
- 本次测试读取中 button_test 的焦点/hover 用例只核查回调参数存在，代码注释明确实际触发需要 integration testing，不能据此声称完整键鼠验收。[E54]
- 已读 Clickable 有 TapSemanticEvent，但这不等同于证明所有按钮都有完整 button/selected/disabled 语义、所有图标有可读标签、所有模态恢复焦点正确。未做全组件 Semantics 树审计和屏幕阅读器验收。

优势是键鼠与焦点有具体共享实现；限制是缺少在本次可证范围内的系统级偏好与全链无障碍测试结果。

## 9. GenUI 的真实能力与文档偏差

### 9.1 当前可证范围

当前包 README 明确自己不替代 GenUI runtime。Catalog 提供 shadcn renderers；Conversation、SurfaceController、Surface、transport、validation、DataModel 由 genui 提供。[E46]

源码实际 `GenCatalog.all` 列出 Text/Button/Card/CheckBox/ChoicePicker/Column/DateTimeInput/Divider/Icon/List/Modal/Row/Slider/Tabs/TextField，以及 Switch/Progress 扩展。其 `asCatalog` 精确扩展口是：

```dart
static Catalog asCatalog({
  List<CatalogItem> items = const [],
  List<ClientFunction> functions = const [],
  List<String> systemPromptFragments = const [],
})
```

实现合并 `[...all, ...items]`、BasicFunctions 和传入函数，设置 catalogId/aliases 与提示规则。规则要求 A2UI v0.9、root id、createSurface/updateComponents 分离，并给输入使用路径双向绑定。[E47、E48]

这意味着接口可扩展，但额外组件需要开发者编写 CatalogItem/ClientFunction，不能据此称任意 Flutter Widget、任意属性和任意业务行为无需接入就可以编辑。具体范围由 schema、Catalog 和宿主注册项决定。

### 9.2 文档页与源码确有不一致

| 材料 | 展示内容 | 当前源码核查 |
| --- | --- | --- |
| docs GenUI 页 | 声称内置 TextArea、Select、RadioGroup、Alert、Badge、Avatar、Accordion、Form、FormFieldError 等 | 当前 GenCatalog.all 没有这些同名条目；不能拿 docs 名单作现有 Catalog 支持范围。[E49、E47] |
| docs GenUI 页 | 示例继承 GenSystemFunction，使用 GenDataField/GenDataFieldDescriptor，并调 `asCatalog(systemFunctions: ...)` | 当前 asCatalog 参数是 items/functions/systemPromptFragments，公共入口仅导出 gen_catalog；该调用形状与当前实现不符。[E49、E47] |
| 包 README | 使用标准 A2UI CatalogItem/ClientFunction，并说明没有第二套 schema/action DSL | 与当前 Catalog 实现一致，应优先以固定源码定义支持范围。[E46–E48] |

**推断**：只照 docs 页面复制这些旧例，可能遇到找不到类或参数的问题；本次没执行编译，不能将其描述成已运行复现的编译错误。

### 9.3 测试能证明到哪一层

model_response_contract_test 把带 prose/JSON fence 的固定模型文本 fixture 放进 A2uiTransportAdapter，等 surface事件，挂载 Surface，断言布局顺序与视口，编辑 TextField、点击 Checkbox，再点击 Save，检查 DataModel 和提交消息。catalog_test 另核查 Catalog 名称集合、双向绑定、外部数据更新、事件回传、无 Material host 的渲染。[E50、E51]

这是比“只截图显示文本”更深入的测试设计；但输入是固定夹具，不能替代真实模型在任意需求下产生合法 schema、持续修订、恢复会话或保存场景的可靠性证明。本次也未运行这些测试。

## 10. 复制、导出、截图、持久化：分别有什么

| 能力 | 证据及范围 | 结论 |
| --- | --- | --- |
| 示例代码复制 | CodeBlock→CodeSnippet，复制 action 调 Clipboard.setData，随后显示复制提示。[E15] | 有，复制面板所展示的字符串 |
| 原始源码跳转 | 外链打开 GitHub master 对应文件。[E14] | 有；不是下载独立项目 |
| 主题代码生成/复制 | ThemePage.buildCode 生成 ShadcnApp/theme参数片段，交给 CodeBlock。[E42] | 有，范围是主题片段 |
| Gallery 图片捕获 | ComponentCard 在 ComponentsMode.capture 分支用 RenderRepaintBoundary.toImage→PNG→base64 URL→launchUrlString。[E10] | 存在捕获实现；正常模式点击进入组件，不能据此说普通页面有完善的截图下载流程 |
| 开发预览 | ShadcnPreview/ShadcnMultiPreview 提供 Flutter widget_previews 主题包装。[E45] | 有，开发辅助 |
| 偏好保存 | SharedPreferences 保存主题、density/scaling、surface参数；桌面路径持久化还有条件分支。[E43] | 有，偏好/路径持久化 |
| 完整场景保存、版本化、分享URL、项目打包导出、编辑后代码回写 | 本次追踪的详情包装器、主题工作台、代码面板和 Catalog 公共 API 中未找到相应完整链 | 未建立存在证据；不能由代码复制、偏好保存或AI Surface推导出来 |

最后一行是范围内的否定证据，不是对仓库所有未读文件的绝对不存在断言。

## 11. 测试、CI 与许可证证据

### 11.1 测试证据矩阵

| 已读测试文件 | 实际断言覆盖 | 本次限制 |
| --- | --- | --- |
| button_test.dart | 展示、onPressed、禁用、enabled，焦点/hover参数存在 | 焦点用例不是按键交互验收。[E54] |
| overlay_configuration_test.dart | desktop Popover、Android默认Drawer、adaptive:false保留Popover，Dialog pop的结果future | 已有针对机制的断言，但本次未执行。[E52] |
| popover_key_test.dart | Symbol锚点、卸载注销、可见性门控、锚点定位、滚动跟随、实时invert/margin、scope隔离 | 不等于真实浏览器/真机定位通过。[E53] |
| docs/new_examples_smoke_test.dart | PinnedSheet backdrop阻挡、Table RTL、Select创建项、固定宽度等部分示例 | 并非全部 docs 示例覆盖。[E55] |
| genui/catalog_test.dart | Catalog集合、双向绑定、外部更新、事件、无Material宿主 | 静态读取。[E51] |
| genui/model_response_contract_test.dart | 固定模型文本→Surface→布局→交互→事件 | 未请求真实模型。[E50] |

读取文件超过要求的八个，关键链优先；证据索引列出 50 个不同文件。未以测试文件数量代替覆盖率计算，也未声称所有组件都有测试或所有测试通过。

### 11.2 CI 配置并非结果

PR 工作流 job 名为 Analyze and Test，但实际步骤是依赖解析、flutter analyze 和 docs Web build，没有 flutter test 步骤。主分支部署工作流另有核心包 flutter test，deploy 依赖该 job，再构建 docs WASM 并发布 GitHub Pages。[E56、E57]

因此“PR job 名包含 Test”不能当作 PR 已执行测试的依据；主部署 test 只指向 packages/shadcn_flutter，不能扩张成 docs、GenUI 与所有伴随包测试都在同一流水线执行。本次未查询具体运行日志/状态，未把 CI 配置视为成功运行证据。

### 11.3 许可证

根 LICENSE 及已读核心包/GenUI LICENSE 为 BSD 3-Clause 文字：允许源代码/二进制再分发和修改，条件包括保留版权与条款、二进制材料附带声明、未经许可不以作者/贡献者名义背书，并有按现状免责。[E58]

仓库还存在图标、字体和 vendor 目录的独立 LICENSE（Bootstrap、字体、email_validator、phonecodes 等）。本次未逐项核读这些第三方资源条款，故不能把根 BSD 标签当作整仓全部资产的统一许可结论。这是许可文本识别，不是法律意见。

## 12. 客观优点、缺点与设计取舍

| 观察 | 优点/价值 | 代价或边界 |
| --- | --- | --- |
| 公共库与伴随包分离 | Widgets核心依赖较集中，Material/Cupertino/骨架屏按需接入 | docs使用更完整宿主，不能照搬其运行条件而忽略祖先/本地化。[E03、E43、E60–E62] |
| 真实Widget示例和公开组合API | 能沿回调与状态追踪实际行为，导航与弹层非纯静态图片 | Gallery缩略示意有手写替身且内层不可操作；须进入详情辨别。[E10–E22] |
| 状态/样式/容器可组合 | 业务状态归调用者、样式可针对选中态定制 | key、controller、context和回调契约需要理解；Adapter动态生命周期存在待验证边界。[E18–E20、E37] |
| 统一OverlayConfiguration入口 | 不同机制共用show/builder/result模型，移动默认自适应 | 配置转换不是逐参数保留；Dialog外部Completer能力与Popover不同。[E23–E32] |
| 主题工作台与代码片段 | 调参有实时视觉语境，可复制主题配置 | 无完整场景导出证据，示例代码仍从master动态取。[E14、E41、E42] |
| 键鼠焦点共享基础 | Enter/Space/方向键、FocusOutline有真实实现 | 未建立统一减少动画/高对比和全组件Semantics验收证据。[E35、E36、E44、E65] |
| GenUI标准协议与交互夹具 | 有数据绑定与动作回传测试，不止文字生成 | docs旧DSL与当前源码不一致；支持范围仍由Catalog与宿主决定。[E46–E51] |
| 测试与CI分层 | 核心有明确交互/回归断言，部署前有核心test依赖 | PR工作流未跑test；附属包测试运行状态未核实。[E52–E57] |

综合判断（静态证据范围）：项目的长处是组件组合、主题工作台和真实交互示例可以追到公开 API；局限集中在文档与当前版本同步、统一接口各机制能力差异、系统偏好/无障碍的证据不足，以及把演示、代码片段、AI Catalog 误读为通用编辑器的风险。该判断不依赖组件数，也不是运行质量或跨平台性能评级。

## 13. 限制与后续核验边界

1. 本报告没有浏览器截图和现场操作；所有“点击结果”描述均来自代码控制流或测试断言。部署站点可能与 master 不同，不作当前线上外观承诺。
2. 固定 SHA 的包版本和 SDK声明是源码事实，未检查 pub.dev 发布包是否与该 SHA逐字一致。
3. 未执行安装、生成器、测试、构建；未验证六平台、性能、真实输入法、屏幕阅读器、焦点返回、系统高对比和减少动画。
4. 没有全文逐文件审计；否定结论按已读范围表述。默认分支搜索结果可能受GitHub索引影响，且不是固定SHA文本快照搜索。
5. 已明确指出的文档/API偏差、动画参数方向、controller生命周期、Dialog外部关闭边界是静态核查结果或推断，未扩张为运行复现事故。
6. 本次仅输出本报告，未改项目代码/配置/账本，未Git提交，未把第三方源码落入仓库。

## 14. 固定版本证据索引

下列全部链接均固定到同一完整 SHA；E 编号用于正文交叉核查。

| 编号 | 固定SHA源码/文本 | 核查位置 |
| --- | --- | --- |
| E01 | [仓库职责说明](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/README.md#L1-L21) | `README.md:1-21` |
| E02 | [workspace 成员](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/pubspec.yaml#L1-L17) | `pubspec.yaml:1-17` |
| E03 | [公开包版本、SDK与依赖](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/pubspec.yaml#L1-L29) | `packages/shadcn_flutter/pubspec.yaml:1-29` |
| E04 | [公共导出入口](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/shadcn_flutter.dart#L1-L176) | `packages/shadcn_flutter/lib/shadcn_flutter.dart:1-176` |
| E05 | [文档分类与导航条目](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs_page.dart#L145-L290) | `packages/docs/lib/pages/docs_page.dart:145-290` |
| E06 | [GenUI和Components路由入口](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/main.dart#L290-L315) | `packages/docs/lib/main.dart:290-315` |
| E07 | [Dialog文档路由](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/main.dart#L397-L406) | `packages/docs/lib/main.dart:397-406` |
| E08 | [NavigationBar文档路由](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/main.dart#L717-L723) | `packages/docs/lib/main.dart:717-723` |
| E09 | [Gallery分组与WIP条目](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components_page.dart#L127-L275) | `packages/docs/lib/pages/docs/components_page.dart:127-275` |
| E10 | [卡片跳转、截图模式与禁用内层交互](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components_page.dart#L359-L435) | `packages/docs/lib/pages/docs/components_page.dart:359-435` |
| E11 | [导航缩略图为手工示意](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components/navigation_bar/navigation_bar_tile.dart#L12-L70) | `packages/docs/lib/pages/docs/components/navigation_bar/navigation_bar_tile.dart:12-70` |
| E12 | [组件页目录与页面结构](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/component_page.dart#L27-L112) | `packages/docs/lib/pages/docs/component_page.dart:27-112` |
| E13 | [真实Widget预览与代码面板](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/widget_usage_example.dart#L8-L53) | `packages/docs/lib/pages/widget_usage_example.dart:8-53` |
| E14 | [代码从master远程加载](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/widget_usage_example.dart#L75-L172) | `packages/docs/lib/pages/widget_usage_example.dart:75-172` |
| E15 | [复制代码到剪贴板](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/code_highlighter.dart#L114-L159) | `packages/docs/lib/code_highlighter.dart:114-159` |
| E16 | [按钮多个示例按页排列](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components/button_example.dart#L28-L118) | `packages/docs/lib/pages/docs/components/button_example.dart:28-118` |
| E17 | [导航页到示例绑定](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components/navigation_bar_example.dart#L7-L25) | `packages/docs/lib/pages/docs/components/navigation_bar_example.dart:7-25` |
| E18 | [导航状态、参数控件、可见反馈](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components/navigation_bar/navigation_bar_example_1.dart#L10-L170) | `packages/docs/lib/pages/docs/components/navigation_bar/navigation_bar_example_1.dart:10-170` |
| E19 | [NavigationBar构造与状态下发](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/navigation/navigation_bar/bar.dart#L87-L215) | `packages/shadcn_flutter/lib/src/components/navigation/navigation_bar/bar.dart:87-215` |
| E20 | [NavigationItem选择消费链](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/navigation/navigation_bar/item.dart#L21-L139) | `packages/shadcn_flutter/lib/src/components/navigation/navigation_bar/item.dart:21-139` |
| E21 | [弹窗页到示例绑定](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components/dialog_example.dart#L7-L25) | `packages/docs/lib/pages/docs/components/dialog_example.dart:7-25` |
| E22 | [弹窗打开、表单与pop结果](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components/dialog/dialog_example_1.dart#L9-L73) | `packages/docs/lib/pages/docs/components/dialog/dialog_example_1.dart:9-73` |
| E23 | [统一showOverlay精确签名](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart#L94-L104) | `packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart:94-104` |
| E24 | [DialogConfiguration完整构造与路由](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart#L825-L924) | `packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart:825-924` |
| E25 | [弹窗路由与150ms缩放淡入](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/dialog.dart#L571-L671) | `packages/shadcn_flutter/lib/src/components/overlay/dialog.dart:571-671` |
| E26 | [closeOverlay与Completer契约](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/overlay.dart#L21-L80) | `packages/shadcn_flutter/lib/src/components/overlay/overlay.dart:21-80` |
| E27 | [弹窗内部关闭adapter](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/dialog.dart#L700-L772) | `packages/shadcn_flutter/lib/src/components/overlay/dialog.dart:700-772` |
| E28 | [Popover锚点、关闭与完成回调](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/components/popover/popover_example_1.dart#L13-L85) | `packages/docs/lib/pages/docs/components/popover/popover_example_1.dart:13-85` |
| E29 | [PopoverConfiguration完整构造](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart#L206-L231) | `packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart:206-231` |
| E30 | [Popover展示、关闭、转Drawer](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart#L330-L531) | `packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart:330-531` |
| E31 | [Popover布局缩放和淡入](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/popover.dart#L419-L480) | `packages/shadcn_flutter/lib/src/components/overlay/popover.dart:419-480` |
| E32 | [外部Future completer及OverlayController边界](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart#L1273-L1435) | `packages/shadcn_flutter/lib/src/components/overlay/overlay_configuration.dart:1273-1435` |
| E33 | [Button构造](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/control/button.dart#L874-L909) | `packages/shadcn_flutter/lib/src/components/control/button.dart:874-909` |
| E34 | [PrimaryButton构造与消费](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/control/button.dart#L4143-L4207) | `packages/shadcn_flutter/lib/src/components/control/button.dart:4143-4207` |
| E35 | [Button转Clickable与动画](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/control/button.dart#L1478-L1559) | `packages/shadcn_flutter/lib/src/components/control/button.dart:1478-1559` |
| E36 | [焦点、键盘与按压动画](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/control/clickable.dart#L846-L988) | `packages/shadcn_flutter/lib/src/components/control/clickable.dart:846-988` |
| E37 | [ControlledComponentAdapter状态实现](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/form/control.dart#L201-L269) | `packages/shadcn_flutter/lib/src/components/form/control.dart:201-269` |
| E38 | [ControlledCheckbox包裹适配器](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/form/checkbox.dart#L348-L383) | `packages/shadcn_flutter/lib/src/components/form/checkbox.dart:348-383` |
| E39 | [Checkbox构造与回调](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/form/checkbox.dart#L584-L618) | `packages/shadcn_flutter/lib/src/components/form/checkbox.dart:584-618` |
| E40 | [ThemeData字段和默认值](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/theme/theme.dart#L139-L218) | `packages/shadcn_flutter/lib/src/theme/theme.dart:139-218` |
| E41 | [主题参数选择面板](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/theme_page.dart#L1341-L1635) | `packages/docs/lib/pages/docs/theme_page.dart:1341-1635` |
| E42 | [主题代码生成范围](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/theme_page.dart#L1796-L1849) | `packages/docs/lib/pages/docs/theme_page.dart:1796-1849` |
| E43 | [主题偏好持久化与App组装](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/main.dart#L860-L1007) | `packages/docs/lib/main.dart:860-1007` |
| E44 | [Layer主题与动画消费](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/shadcn_app.dart#L595-L715) | `packages/shadcn_flutter/lib/src/shadcn_app.dart:595-715` |
| E45 | [Flutter开发预览注解](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/previewer/previewer.dart#L1-L128) | `packages/shadcn_flutter/lib/src/previewer/previewer.dart:1-128` |
| E46 | [GenUI当前职责与标准协议](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_genui/README.md#L3-L118) | `packages/shadcn_flutter_genui/README.md:3-118` |
| E47 | [Catalog精确成员和扩展参数](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_genui/lib/src/gen_catalog.dart#L616-L674) | `packages/shadcn_flutter_genui/lib/src/gen_catalog.dart:616-674` |
| E48 | [A2UI规则与双向绑定路径](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_genui/lib/src/gen_catalog.dart#L13-L31) | `packages/shadcn_flutter_genui/lib/src/gen_catalog.dart:13-31` |
| E49 | [文档旧组件及旧DSL](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/genui_page.dart#L170-L236) | `packages/docs/lib/pages/docs/genui_page.dart:170-236` |
| E50 | [模型文本夹具到交互回传测试](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_genui/test/model_response_contract_test.dart#L10-L101) | `packages/shadcn_flutter_genui/test/model_response_contract_test.dart:10-101` |
| E51 | [Catalog与数据绑定测试](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_genui/test/catalog_test.dart#L8-L173) | `packages/shadcn_flutter_genui/test/catalog_test.dart:8-173` |
| E52 | [Popover自适应与Dialog结果测试](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/test/components/overlay_configuration_test.dart#L11-L136) | `packages/shadcn_flutter/test/components/overlay_configuration_test.dart:11-136` |
| E53 | [锚点跟随、滚动及边界测试](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/test/components/popover_key_test.dart#L225-L490) | `packages/shadcn_flutter/test/components/popover_key_test.dart:225-490` |
| E54 | [按钮交互、禁用及焦点测试边界](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/test/components/button_test.dart#L144-L207) | `packages/shadcn_flutter/test/components/button_test.dart:144-207` |
| E55 | [Docs部分示例交互测试](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/test/new_examples_smoke_test.dart#L14-L125) | `packages/docs/test/new_examples_smoke_test.dart:14-125` |
| E56 | [PR实际分析与Web构建](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/.github/workflows/pr.yml#L14-L42) | `.github/workflows/pr.yml:14-42` |
| E57 | [主分支核心测试及WASM部署](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/.github/workflows/main.yml#L9-L44) | `.github/workflows/main.yml:9-44` |
| E58 | [根BSD-3-Clause许可证](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/LICENSE#L1-L11) | `LICENSE:1-11` |
| E59 | [AlertDialog是内容而非开窗函数](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/layout/dialog/alert_dialog.dart#L120-L160) | `packages/shadcn_flutter/lib/src/components/layout/dialog/alert_dialog.dart:120-160` |
| E60 | [Material互操作入口](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_material/lib/shadcn_flutter_material.dart#L1-L53) | `packages/shadcn_flutter_material/lib/shadcn_flutter_material.dart:1-53` |
| E61 | [Cupertino互操作入口](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_cupertino/lib/shadcn_flutter_cupertino.dart#L1-L58) | `packages/shadcn_flutter_cupertino/lib/shadcn_flutter_cupertino.dart:1-58` |
| E62 | [Skeletonizer互操作入口](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter_skeletonizer/lib/shadcn_flutter_skeletonizer.dart#L1-L58) | `packages/shadcn_flutter_skeletonizer/lib/shadcn_flutter_skeletonizer.dart:1-58` |
| E63 | [官方定位与平台声称](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/docs/lib/pages/docs/introduction_page.dart#L30-L72) | `packages/docs/lib/pages/docs/introduction_page.dart:30-72` |
| E64 | [通用150ms默认时长](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/util.dart#L269-L272) | `packages/shadcn_flutter/lib/src/util.dart:269-272` |
| E65 | [焦点环主题与动画](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/layout/focus_outline.dart#L151-L185) | `packages/shadcn_flutter/lib/src/components/layout/focus_outline.dart:151-185` |

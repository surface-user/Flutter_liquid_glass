# 通用 Flutter UI 组件库整合任务

更新日期：2026-11-18。当前方向：**先整合底层组件库与公开接口，再建设可视化设计台**。玻璃是可选特色材质，不是所有控件的前提。#27 从 main a0bc51a 移植并校正了 #26 的计划。已确认 8 类组件和首批范围；各项实现状态见下方任务记录。

## 1. 当前决定、范围与基线

- 本文件是根组件库的主任务账本；`deployment/docs/task.md` 只管理网站自身工作。[PR #25](https://github.com/surface-user/Flutter_liquid_glass/pull/25) 的网站优先计划需调整，不能作为接下来的根库开发顺序；保留其历史，不合并或关闭它。
- 产品目标：为 Flutter 应用及用户的 Agent 提供可组合、接口真实、样式一致的通用 UI 能力，逐步覆盖基础控件、导航、表单、浮层、布局、反馈和动效。优先复用 SDK、现有库和经过核查的第三方能力，缺口才自研，不预设四个参考项目都要采用。
- #27 只调整文档。本次在 #29 交付独立导航条目及相关规范；组件分类是后续任务的归类依据，各项仍按明确批准的范围实施。不发布、不合并。
- #26 原读取基线（保留来源，不作为本 PR 基底）：根库 `ac0028eacd0e1ee22747d454c04a456dcb307377`（`codex/fix-five-contract-bugs`）；#25 头 `8d501b2ba5ee5a7eb1f84cad82a44e7fa49b3307` 与其根 `lib/`、`doc/task.md` 一致，后续差异在 deployment。main 尚未包含该根库基线；原 #26 以该源库分支为 base；本 PR 则从 main 独立提交，只移植 doc/，不带入 #26 相对 main 的22个提交/109文件或网站链。
- 原 M0–M5、BUG-TEST、测试失败及设备/人工/非作者审查记录原文保留在后面的历史区；已有实现不重新标成未开发，也不把历史 REVIEW 自动改为 DONE。后续开工重读最新分支和未提交改动。
- 本次已同步 [Agent 规范](AGENTS.md)、[架构](architecture.md)、[设计规范](design-system.md)：通用库优先、玻璃可选、允许经评估的第三方 UI。LIB-01 仍需冻结首版/命名/包边界，LIB-02 才做候选实测与具体采用决定；没有安装或批准某个依赖。玻璃原生渲染、无业务耦合、API 兼容、分组隔离、减少动画、降级和性能约束继续适用。

### 阅读下表前先区分 main 与 #4

| 基线 | 实际能力 |
| --- | --- |
| main a0bc51a（本 PR 代码基底） | 6个实现文件、20个公开声明；玻璃表面/按钮/顶栏/弹窗/路由及基础主题，无 merge/密度/五个桌面控件 |
| #4 ac0028e（下方已有能力/缺口盘点的范围） | 26个源文件、26个声明；模块化、GlassLayout/merge/状态主题、文本/导航条目/Tab/工具栏/菜单；未合并 |
| LIB/WEB | 计划；本次文档没有实现任何新组件、第三方适配或设计台 |

第1节以下“已有/当前/根库”的技术盘点以及第2–6节以已有能力为前提的任务，均参考 #4 固定实现，不声称这些能力进入 main。若从 main 开发，先在 LIB-00 决定前序改动的合入/移植顺序或另行实施缺失能力；不能直接运行 #4 专属测试或粘贴增量 API。准确主线能力见 [组件目录](component-catalog.md) 与 [API](api.md)。候选版本/许可信息继承 #26 的固定研究，本次没有重新审计第三方、安装或运行它们，采用前由 LIB-02 再核查。

### #4 已有能力：复用与补齐，不重复开发

以下沿用 #26 对 #4 固定版本的核对结果：唯一公开入口 `lib/lightweight_liquid_glass.dart`、全部26个 Dart 源文件及 [真实组件目录](component-catalog.md)、[API](api.md)、[架构](architecture.md)。入口有26个公开声明，包含配置/主题/函数，不等于26个控件。以下为该固定版本的盘点；本次复核主线源码与分支差异，不重做原26文件逐函数验证。历史测试结果不是本轮运行结果。

| 能力 | 实际接口/实现 | 本轮判断 |
| --- | --- | --- |
| 主题与密度 | LiquidGlassThemeData/merge、GlassLayout、SDK ColorScheme/TextTheme/ButtonStyle | 已有；补通用主题映射，不重造 token 系统 |
| 材质 | GlassSurface、GlassStyle/Presets、GlassBackdrop、GlassGroup | 已有；保留模糊上限、重叠隔离、高对比/无模糊可读；Backdrop 默认静态 |
| 布局与内容容器 | GlassCard | 已有玻璃卡片；通用卡片、面板和顶栏布局按 LIB-10 推进 |
| 操作 | GlassButton、GlassIconButton，内部 interaction、SDK InkWell | 已有 hover/focus/pressed/disabled、按压/释放、指针高光；通用按钮变体和 loading 契约待定 |
| 文本输入 | GlassTextField(controller/focusNode、onChanged/onSubmitted、InputDecoration) → SDK TextField | 已有基本输入/搜索、只读/禁用/错误外观；没有据此认定已提供 FormField 校验、数字输入或自动补全 |
| 导航与布局 | GlassNavigationItem(selected/onPressed)、GlassTab(onSelected/onClose)、GlassToolbar(Wrap)、GlassAppBar | 已有受控条目、独立关闭和工具栏；未提供完整树数据、TabManager 或通用页面业务状态 |
| 浮层 | GlassDialog、showGlassDialog<T> → Future<T?>；GlassMenu → SDK MenuAnchor/MenuItemButton | 已有滚动弹窗、主题捕获、单层菜单、关闭/焦点机制；复杂弹出层、级联菜单仍需评估 |
| 动效 | GlassMotionSpec、GlassPageRoute、内部 buildGlassTransition、AnimatedGlassSurface | 已有 fade/fadeSlide/scaleFade/sharedAxis/none；不是通用时间线。页面路由消费 reverseDuration；showGlassDialog 仅把 duration 传给 showGeneralDialog，独立退出时长尚未兑现 |
| 反馈 | SDK Tooltip、CircularProgressIndicator、Text 与容器组合 | 历史 M4-04 已证明基础组合可用；新增库 API 需有主题、交互或复用价值，不能把所有反馈列成缺失 |

## 2. 整合方式与候选来源

每个组件先选方式：**已有实现 → SDK 直接组合/主题接入 → 第三方直接依赖 → 包装适配 → 最小自研**。直接使用不等于统一重导出整套第三方 API；包装必须解决明确的主题、值/回调、焦点、动效或兼容问题。SDK 已完整满足时，交付可编译用法和主题接入即可，不为组件数量机械造同名壳。

下列版本及结论继承 #26 的既有研究；其当轮抽查了源码、pubspec 和许可文本，本次未重新尽调，不声称为最新发布包。未安装、构建或验证第三方运行；依赖约束相交不等于已兼容。

| 候选/已核对接口 | 初步选择与理由 | 许可与兼容性门槛 |
| --- | --- | --- |
| Flutter SDK：ThemeData、ButtonStyle、Form/FormField、TextField、MenuAnchor、布局/语义/焦点与动画基础 | 默认基础来源；主题配置和必要薄适配统一体验，保留 SDK 原生编辑与键盘能力 | 本库当前 Dart >=3.12、Flutter >=3.44；按实际最低版和开发版验证，新增 API 不凭在线最新版推定最低版可用；保留 SDK/资源声明 |
| fluent_ui 4.18.0：NavigationPane(selected/onChanged)、ContentDialog + showDialog<T>、Checkbox(checked/onChanged) | 优先评估桌面导航、树/Tab、NumberBox、选择和浮层；SDK 足够的基础控件不重复引入。复杂控件可直接消费或在可选适配包桥接主题与状态，先验证再选 | 根 BSD-3-Clause；需保留声明，并逐项检查字体/图标/噪声和传递依赖。Dart >=3.8、Flutter >=3.32 只表明下限相容；实际引入 intl、scroll_pos、recase、math_expressions、material_ui，需解算与包体/主题/平台核验，不带 Gallery 的原生窗口依赖 |
| shadcn_flutter 0.0.55：Checkbox(state/onChanged)，另有 ControlledCheckbox、ControlledComponentAdapter/controller；独立主题与组件入口 | 优先评估表单、Select、Popover、布局等增量价值；采用命名空间/显式桥接，保留受控值语义，不把其状态枚举强转成 bool。不为了它替换全部宿主 | 根 BSD-3-Clause，资源/vendor 许可分别查；该固定版 Dart >=3.13、Flutter >=3.47，**高于本库最低版，暂不接入**。LIB-02 比较兼容发布版或可选包抬高自身下限的成本，不默默抬高核心 SDK。animation_kit/data_widget/gap、字体、主题和减少动画需实测 |
| AppFlowy / appflowy_ui 1.0.0：AFBaseButton(onTap/builder/disabled)、AFModal/Header/Body/Footer | 先学习桌面交互、语义 token 与模态组合职责；不引入文档/数据库/BLoC/FFI 业务框架。只有具体能力优于 SDK/现有库且许可明确时再评估代码或依赖 | 根 AGPLv3；UI 子包 LICENSE 是“TODO: Add your license here.”，没有独立宽松许可依据。本轮不复制、不采用其源码；具体代码/资产与分发范围核查后才可决定。子包 Dart ^3.6.2、含 flutter_animate/cached_network_image；发布状态、独立构建和资源待验 |
| Appainter 2.7.7：BasicThemeState.theme → ThemeData.from/localize；WidgetService.showColorPicker → 选色依赖 | 它是主题编辑应用，publish_to:none；参考主题预览/输出一致性与状态用例，不作为根库组件依赖。颜色选择优先 SDK 或独立包的单独尽调，不能因 Appainter 使用就自动采用 | 根 AGPLv3；不复制应用实现或资产。该应用固定 Flutter 3.38.0，含 Firebase/BLoC 等大量应用依赖，不带入组件库。独立选色包的版本/许可/无障碍另核 |

固定证据（保留 #26 所列来源；原报告有更广覆盖，本次未重新抽查候选接口）：

- fluent_ui：[`pubspec`](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/pubspec.yaml)、[`NavigationPane`](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/navigation/navigation_view/pane.dart)、[`ContentDialog/showDialog`](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/flyouts/content_dialog.dart)、[`Checkbox`](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/lib/src/controls/inputs/checkbox.dart)、[许可](https://github.com/bdlukaa/fluent_ui/blob/e183ad9778df9f4e74a3664da6667e63b379f0f8/LICENSE)。
- shadcn_flutter：[`pubspec`](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/pubspec.yaml)、[`control`](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/form/control.dart)、[`Checkbox`](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/packages/shadcn_flutter/lib/src/components/form/checkbox.dart)、[许可](https://github.com/sunarya-thito/shadcn_flutter/blob/611caafcdfa0da659924c7a7679083714b917d17/LICENSE)。
- AppFlowy：[`appflowy_ui/pubspec`](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/pubspec.yaml)、[`AFBaseButton`](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart)、[`AFModal`](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/modal/modal.dart)、[根许可](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/LICENSE)、[子包许可占位](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/LICENSE)。
- Appainter：[`pubspec`](https://github.com/zeshuaro/appainter/blob/c7e834b90dc47b68612d0a1db3a7b641438f3843/pubspec.yaml)、[`BasicThemeState`](https://github.com/zeshuaro/appainter/blob/c7e834b90dc47b68612d0a1db3a7b641438f3843/lib/basic_theme/cubit/basic_theme_state.dart)、[`WidgetService`](https://github.com/zeshuaro/appainter/blob/c7e834b90dc47b68612d0a1db3a7b641438f3843/lib/services/widget_service.dart)、[许可](https://github.com/zeshuaro/appainter/blob/c7e834b90dc47b68612d0a1db3a7b641438f3843/LICENSE)。
- 研究背景固定在 [#24 综合及四份报告](https://github.com/surface-user/Flutter_liquid_glass/tree/1f3c0dbd0e1a9310f903f7ff8d103dc364d69daa/deployment/docs)。其中“网站场景优先、源库可选”的建议按本轮决定调整，不能照搬为当前目标。

## 3. 组件整合清单

### 已确认分类与首批范围

以[组件与能力目录](component-catalog.md#八类组件)为准。首批覆盖 5 类，其余按实际场景排期；下方技术清单和任务编号保留后续候选，不扩大首批交付。

| 类别 | 职责边界 | 首批范围 |
| --- | --- | --- |
| 操作 | 触发命令 | 通用按钮和图标按钮（LIB-05） |
| 输入与表单 | 编辑草稿、校验和提交 | 单行与多行文本输入，可组合 Flutter 表单（LIB-06） |
| 选择与开关 | 在选项间选择，或改变开关、范围等持续值 | 后续（LIB-07、LIB-15A） |
| 专用选择器 | 编辑日期、时间、颜色等有专属交互的值 | 后续（LIB-15A） |
| 导航 | 请求切换页面或视图；选中与路由由应用持有 | 独立导航条目与标签（LIB-09A、LIB-09） |
| 布局与内容容器 | 排列和组织内容；材质独立配置 | 卡片、面板和顶栏布局组合（LIB-10） |
| 弹窗与浮层 | 临时呈现交互，负责关闭、焦点和结果 | 确认弹窗（LIB-08） |
| 状态与反馈 | 提示进度、结果或当前状态 | 验收示例使用 Flutter 组合，统一接口后续评估（LIB-11） |

[主题、材质和动效](component-catalog.md#基础能力)单列：主题决定视觉默认与覆盖（LIB-03/04），材质决定表面绘制与降级（LIB-04，`GlassSurface` 归此类），动效决定过渡与减少动画策略（LIB-12）。通用组件按用途命名，组件实现按职责归目录；`NavigationItem` 放在 `lib/src/components/navigation/`，普通实色或玻璃材质由调用方在外层组合。

### 技术清单与后续候选

“SDK 有”表示候选基础，不表示本库已有对应公开封装；“待扩展”表示未在当前入口实现的能力。下表是范围与优先选择，最终接口名、依赖和支持平台在对应任务验收时冻结。

| 类别/作用 | 当前状态 | 拟整合内容与方式/理由 | 批次任务 |
| --- | --- | --- | --- |
| 通用按钮、图标按钮、链接按钮、命令工具栏 | 玻璃按钮已实现 | 扩展变体、尺寸、loading/disabled、leading/trailing；SDK Filled/Outlined/Text/IconButton 主题接入，已有玻璃接口保留。分段选择归选择与开关 | P0 LIB-05 |
| 文本、密码、搜索、多行、表单项 | GlassTextField 部分覆盖 | SDK TextField/TextFormField/Form 组合；补 label/helper/error、校验/提交/重置、obscure/输入类型/formatter 等必要透传，先核对差异；不自造编辑器 | P0 LIB-06 |
| Checkbox、Radio、Switch、分段选择 | 无对应本库公开类型 | SDK 优先，统一主题与受控值/回调；三态、互斥、键盘与 disabled 必验。fluent/shadcn 作差异候选，SDK 不足才适配 | P0 LIB-07 |
| Select/Dropdown、Combobox/Autocomplete | SDK 可组合，根库未封装 | 先单选/搜索建议，使用 SDK DropdownMenu/Autocomplete；异步查询由外部负责。复杂可搜索/多选比较 fluent ComboBox/AutoSuggestBox、shadcn Select 的真实签名 | P0 LIB-07；P1 LIB-15A |
| Slider/Range、数字输入 | SDK 有，根库未封装 | SDK Slider/RangeSlider 与格式化/校验；高级 NumberBox 比较 fluent，避免把数值解析和文本草稿混同 | P1 LIB-15A |
| 日期/时间/日历、颜色选择 | 根库未提供 | SDK picker 优先；评估独立选择包或 fluent 日历。日期范围、时区/locale、取消返回、颜色格式分别定约，颜色包不沿用 Appainter 的许可结论 | P1 LIB-15A |
| 侧栏条目、底部/轨道导航、Tab、Breadcrumb | #29 草稿新增独立条目；#4 有未合并的条目和 Tab | 受控条目 + SDK NavigationRail/Bar/Drawer、TabBar 组合；补分组、溢出/滚动及可访问导航，不引入业务页面管理器。复杂桌面导航再评估 fluent_ui | P0 LIB-09A、LIB-09；P1 LIB-14 |
| 树与层级、可重排/可关闭 Tab | 条目 indent 只是表现 | 先明确选中/展开/虚拟化/拖拽职责；比较 SDK TreeSliver/ReorderableListView 与 fluent TreeView/TabView，数据和页面缓存外置，不把现有 indent 称完整树 | P1 LIB-15B |
| 普通卡片、面板、列表项、分隔与折叠 | 玻璃卡片/表面已有 | SDK Card/ListTile/Divider/ExpansionTile；统一实色层与间距/密度；必要时提供可复用组合，保留玻璃可选 | P0 LIB-10 |
| 顶栏布局、Row/Column/Wrap、Stack、滚动、Grid/响应式 | SDK 已有；#4 有未合并的工具栏 Wrap | 直接 SDK + 布局配方；真实重复需求才做响应式容器/分栏适配，不重复包装所有布局原语。可拖分栏评估后置 | P0 LIB-10；P1 LIB-15B |
| 说明/确认/输入弹窗 | GlassDialog/showGlassDialog 已有基础 | 以现有泛型结果机制组合用途预设；统一 confirm/cancel/null、滚动/窄窗、焦点恢复和 theme 捕获；修正或明确 reverseDuration 契约 | P0 LIB-08 |
| 菜单、右键菜单、Popover/Tooltip/锚定浮层 | 单层 GlassMenu、SDK Tooltip 可用 | 先补锚点/窗口翻转/外点关闭/Esc 与焦点；SDK MenuAnchor/OverlayPortal 优先，复杂 Popover 比较 fluent Flyout/shadcn，级联菜单后置 | P0 LIB-08；P1 LIB-14 |
| Drawer/Sheet、可展开区域 | SDK 有；根库未提供专用 API | SDK Drawer/showModalBottomSheet/ExpansionTile，核对局部 Navigator、遮罩/返回值、拖动关闭、焦点与减少动画；必要桥接主题 | P1 LIB-15A |
| Toast/SnackBar、Banner/Alert、状态徽标 | SDK 可用；根库未提供专用 API | SDK ScaffoldMessenger/SnackBar/MaterialBanner/Badge；补队列/替换/关闭、动作与可访问播报的组合契约，业务消息外部提供 | P0 LIB-11 |
| 进度、加载、Skeleton、空/错/成功状态 | SDK 基础加载/提示已有用例 | 先可确定/不确定进度与停止；SDK 组合空/错/成功。Skeleton 仅有真实等待需求再评估，不默认闪烁 shimmer 或新增依赖 | P0 LIB-11；P1 LIB-15B |
| 表格、排序分页、列表选择 | SDK DataTable/PaginatedDataTable 可用 | 先外部数据/排序/选择回调，再评估大数据虚拟化；不把 SDK 小表格承诺成海量数据网格 | P1 LIB-15B |
| Avatar、Chip/Tag、图标、图片与文字排版 | SDK 可用，根库未做统一方案 | SDK CircleAvatar/Chip/Icon/Text/Image + 主题配方；字体 fallback、长中文、错误占位和资产许可；不打包来源不明的图标集 | P0 LIB-04/10；P1 LIB-15B |
| 高级编辑器、图表、拖拽树、命令面板 | 根库未提供，尚无首版必要性证明 | 长期候选 P2；先确认场景、独立包、许可与数据契约，单独立项；不带 AppFlowy 业务/后端，也不凭四个项目的名字宣称支持 | P2，首版不承诺 |

## 4. 动效清单：触发、属性、现状与边界

所有新效果先明确触发、可动画属性、时长/曲线来源、打断/反向/卸载行为和减少动画替代。减少动画仍保留最终状态、焦点与错误反馈；不得通过隐藏状态来“关闭动画”。

| 效果/作用 | 当前事实及拟整合选择 | 触发与验收 |
| --- | --- | --- |
| 按压、hover、释放、焦点环 | 现有 interaction 已有轻微缩放/位移与时长；SDK 状态样式已用 | 真键鼠状态触发，取消按压/失焦/动态禁用不触发回调；尺寸/语义不随缩放丢失；LIB-05/12 |
| 指针高光、边框/颜色反馈 | 已有 repaint 高光，低质量/高对比/减少透明/减少动画会禁用指针特效 | 不新增闲置 ticker；语义状态不能只靠颜色；不变 blur；LIB-04/05 |
| 表面外观过渡 | AnimatedGlassSurface 已插值样式，sigma 始终取目标 | 验证颜色/边框/阴影与显式 duration；不声称所有字段可平滑插值；LIB-04/12 |
| 路由进入/退出 | GlassPageRoute 已有五种 transition 及正反时长/曲线 | push/pop、嵌套 Navigator、运行中偏好改变与主题捕获；不是页内 Tab 切换；LIB-08/12 |
| 弹窗/Popover 进退 | 玻璃弹窗可转场，reverseDuration 消费缺口已静态确认；Popover 不由其自动覆盖 | 打开/关闭/取消/外点/Esc、退出时长、结果 future 与移除时点，按机制分别采样；LIB-08 |
| 导航选中/指示器、Tab 内容 | 当前 selected 外观由 SDK/样式承担；没有通用内容转场组件证据 | 比较 SDK AnimatedSwitcher/FadeTransition 等组合；保持页面状态规则由消费者决定，动画中隐藏页停 ticker；LIB-09/12 |
| 折叠/展开、尺寸与分栏 | 根库未提供专用公开动效 | SDK ExpansionTile/AnimatedSize/AnimatedContainer 优先；长内容/打断/反向无溢出；P0 折叠，P1 拖分栏；LIB-10/15B |
| Toast/Banner、进度反馈 | SDK 已有动画机制，未统一本库契约 | 显示/替换/关闭、非确定进度停止、播报且不抢焦点；减少动画/后台/卸载不留帧；LIB-11 |
| 列表增删/重排、共享元素 | 根库未提供通用封装 | P1 评估 AnimatedList/ReorderableListView/Hero；稳定 key、取消与返回一致；不首版自建动画引擎；LIB-15B |
| 主题切换 | 现有 ThemeExtension.lerp 与主题配置，不等于已有统一 AnimatedTheme 宿主 | SDK AnimatedTheme/必要桥接；高对比/低性能限制立即优先，玻璃 sigma 不逐帧动画；LIB-04/12 |
| 背景、循环、Skeleton shimmer | GlassBackdrop 默认静态、animate 显式开启；新骨架未承诺 | 装饰循环默认关，系统偏好/不可见/卸载停止；不以循环证明“丰富”；LIB-11/12 |
| 弹簧/强调、交错、手势跟随 | 尚未确立首版需求 | P2 再评估 SDK SpringSimulation 或独立动效包；先原生最小实现，不为效果数量引 flutter_animate/animation_kit；LIB-02 仅评估成本 |

现有内部 `glassReduceMotion` 合并 MediaQuery.disableAnimations、accessibleNavigation、主题 reduceMotion、enableAnimations，并非公开导出。新通用层不让消费者 import src；在 LIB-03/12 决定内部复用或必要公开策略。不同 SDK/平台对 reduced motion 的信号可能不同，需核查锁定 SDK 的引擎/框架映射及 iOS 等平台的额外信号；手工覆盖 MediaQuery 只证明显式读取分支，不替代系统实测。参考 [Flutter disableAnimations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html)。

## 5. 分阶段任务、依赖与退出条件

每项独立 PR，按 [工作流](WORKFLOW.md) 和 PR 模板交付；共享主题/入口/动效文件按所有权串行集成，不擅自开代理。状态：PLANNED → 获实施授权且依赖验收后 READY → IN_PROGRESS → REVIEW → DONE；失败退回，真实阻塞另记。LIB-09A 在 [#29 草稿](https://github.com/surface-user/Flutter_liquid_glass/pull/29) 审查，其余新实现按下表追踪。

### G0：固定整合边界与接口契约

| 编号 | 优先级/状态 | 依赖 | 交付及验收 |
| --- | --- | --- | --- |
| LIB-00 | P0 / PLANNED | 无 | 复核当前源库分支、main 差距及原 M1–M5/#4 的 REVIEW/CI/人工待验，确定下一实现基底。保留已有失败/未跟踪文件，输出可追溯版本与已有能力映射；不以重开任务清空历史，也不强制先合并旧 PR 才可继续独立工作。 |
| LIB-01 | P0 / PLANNED | LIB-00 | 同步 AGENTS/architecture/design-system 的通用库定位、核心/可选适配边界和依赖准入；定义 SDK 组合何时足够、何时提供稳定库 API。比较单包直接依赖与独立适配包维护成本，选最小可行方案；冻结首版 P0 清单、命名/旧 Glass API 共存策略。包名/SDK/破坏性迁移有具体依据再决定，不自动改名。验收：本清单每行有责任模块、采用方式、明确排除项，无“无依赖”与实际接入矛盾。 |
| LIB-02 | P0 / PLANNED | LIB-01 | 对拟采用的 fluent/shadcn 版本做最小独立消费者试验：至少覆盖值/回调、主题/宿主、一个浮层与动效关闭；核对发布包与固定源码、最低 SDK、传递依赖、资源许可、Web/Windows/Android 支持和包体成本。输出采用/延期/拒绝及证据；AppFlowy/Appainter 保持参考，除非另有具体许可依据。验收：明确锁定版本/升级策略和 NOTICE 来源；能拒绝全部第三方而用 SDK 完成本批，不为证明研究有效强行引包。 |
| LIB-03 | P0 / PLANNED | LIB-01 | 按首版组件冻结最小公开契约：必填/默认/null、值/回调类型、受控与初值、controller/focusNode 所有权、selected/indeterminate/error/loading/readOnly/disabled、插槽、异步结果/取消、优先级与生命周期、稳定入口。用可编译消费者证明旧 API 可用、新 API 无业务类型；SDK/第三方同名类命名空间明确，不新增万能 Component/JSON 运行时。验收：参数有消费点/有效条件及不支持项，配置字段存在不算能力完成。 |

### G1：首版可用的通用组件基础

#### LIB-09A：独立导航条目

状态：REVIEW（本地验证完成，待非作者审查）。经确认从 #27 合入后的 main `4842bea` 建立独立分支；只交付无材质前缀的 [NavigationItem](api.md#独立导航条目)。本任务使用 Flutter 控件和主线已有的 `GlassSurface`，不依赖尚未合入的通用主题、按钮或弹窗，也不改变完整 LIB-09 的依赖与状态。以 #4 的受控条目和回归思路为参考，保留旧 PR 链。

验收：同一公开接口在普通实色表面（`Material`）、玻璃表面（`GlassSurface`）和关闭模糊的玻璃表面上，选中语义、焦点、点击和 Enter/Space 激活一致。禁用不激活，焦点和激活不自动变更选中；外部焦点节点仍由应用持有。材质配置只放在父表面；不引入侧栏容器、路由、组选择或页面状态。

本地验证（Windows，Flutter 3.47.1）：格式、静态分析和根测试 27/27 通过（含 4 项新增用例及根视觉回归）。示例 2 通过、2 失败：浅色 1280/390 截图分别有 699/704 像素不同；从未修改的 `4842bea` 隔离复跑得到相同失败，8 张参考、实际与差异图片的 SHA256 对应一致。保留失败产物和原基准，不调整容差。未做设备、实窗或读屏验收；本任务不合并、不发布。

分类复核：`NavigationItem` 源码归导航目录，仍从原公开入口导出，仅依赖 Flutter Material 主持交互和状态样式。测试继续从公共入口导入，并把 `GlassSurface` 作为外层夹具。归档后复跑格式、静态分析与根测试 27/27 均通过；示例及基准图无改动，本次未复跑示例。

| 编号 | 优先级/状态 | 依赖 | 交付及验收 |
| --- | --- | --- | --- |
| LIB-04 | P0 / PLANNED | LIB-03 | 补通用主题与材质接入：语义色/文字/间距/圆角/尺寸/密度、浅深/局部继承、实色/透明/玻璃、主题切换和 SDK 控件主题配方；复用现有配置并明确哪些控件支持何种材质。验收：同一消费者混用普通与玻璃组件，显式值/继承/高对比/无模糊优先级一致，旧默认和 48px 触摸目标不回退，不把所有组件包一层 BackdropFilter。 |
| LIB-05 | P0 / PLANNED | LIB-04 | 按组件清单补按钮与操作类变体/尺寸/loading、键鼠/触摸与状态；先 SDK 主题或现有控件扩展，明确新公开类型的必要性。验收：Enter/Space、按压取消、hover/focus/disabled、重复点击和加载中策略、焦点环/label、tooltip 与长中文；旧按钮和 controlStyle 消费回归通过。 |
| LIB-06 | P0 / PLANNED | LIB-04 | 以现有 GlassTextField/SDK 扩展文本、密码、搜索、多行与 FormField 组合；补本批需要的输入透传、错误/校验/提交/重置和异步校验的外部责任。验收：受控文本/初值冲突、组合输入跨重建、选择/粘贴、只读/禁用、外部 controller/focus 不被释放、错误语义/2x文字；物理中文 IME 另验不虚报。 |
| LIB-07 | P0 / PLANNED | LIB-04 | 实现 Checkbox/Radio/Switch/分段选择及首个单选/搜索建议的 SDK 主题接入或必要包装；不等待复杂多选才交付。验收：受控回填、null/三态、互斥、清空、disabled、方向键/Tab/Space、选中语义；筛选/空结果/长标签与菜单边界可观察。第三方方案若被选中则额外依赖 LIB-02，不能先占位 API。 |
| LIB-08 | P0 / PLANNED | LIB-04、LIB-05、LIB-06 | 补确认/输入/说明弹窗组合与菜单/锚定浮层共同边界；先保留现有泛型结果与单层菜单。为 showGlassDialog reverseDuration 写失败回归，再选择真实路由消费实现或明确不支持的兼容契约；不只改说明假装已生效。验收：confirm/cancel/null/校验、嵌套 Navigator/局部主题、外点/Esc/返回键、焦点圈定/恢复、重复开关/窗口裁切及正反计时；复杂第三方浮层额外依赖 LIB-02。 |
| LIB-09 | P0 / PLANNED | LIB-04、LIB-05、LIB-08 | 先补标签和侧栏受控组合，导航轨道与面包屑后续评估；明确窄屏响应、滚动/溢出、选中与关闭和局部内容切换；复用独立条目，不做业务 TabManager。验收：键盘顺序、长中文/RTL、禁用目标、关闭与选中回调分离、隐藏页 ticker/焦点停用；示例状态由消费者持有。 |
| LIB-10 | P0 / PLANNED | LIB-04 | 补卡片/面板/列表项/分隔/折叠与常见布局配方，定义布局约束、padding、滚动和 responsive 边界；SDK 可完整表达者直接组合。验收：窄窗/长内容/2x文字/RTL、嵌套滚动和无界约束的支持规则、折叠时焦点/语义不落隐藏内容，不引业务布局引擎。 |
| LIB-11 | P0 / PLANNED | LIB-04、LIB-05、LIB-08 | 简化工作台先用 Flutter 组合反馈；再评估统一进度、Toast/SnackBar/Banner、空/错/成功的接口。验收：可确定进度、重复通知队列/替换规则、空/错状态可操作、loading 结束/后台/卸载无闲置帧，播报不抢焦点；SDK 组合已足够者不新增公开控件。 |
| LIB-12 | P0 / PLANNED | LIB-04、LIB-08、LIB-09、LIB-10、LIB-11 | 按动效清单统一实际消费与触发：交互、表面、路由/弹窗、内容切换、展开和反馈；复用 GlassMotionSpec/SDK 的可表达部分，说明局部覆盖与中断/反向。验收：状态/transform/时间采样证明有效，动态四项已有偏好及锁定平台额外信号可关闭非必要动画；无 blur 连续动画、无隐藏/空闲 ticker。不是时间线编辑器。 |
| LIB-13 | P0 / PLANNED | LIB-05、LIB-06、LIB-07、LIB-08、LIB-09、LIB-10、LIB-11、LIB-12 | 做跨组件可访问性与兼容集成：键盘/快捷键、焦点顺序与恢复、角色/名称/值/错误/选中/加载语义、触摸目标、中文/RTL/2x文字、高对比/减少透明/关闭模糊、嵌套主题。验收：自动化语义/交互断言 + Windows 实窗/物理 IME/读屏的实际记录；未有设备的平台继续标待验，不能用 Gallery 截图代替。 |

### G2：按真实收益扩展，再交付组件库基线

| 编号 | 优先级/状态 | 依赖 | 交付及验收 |
| --- | --- | --- | --- |
| LIB-14 | P1 / PLANNED | LIB-02、LIB-03、LIB-04 | 若 LIB-02 选中第三方，首批仅接入有明确增量价值的桌面导航/树或复杂选择/Popover；每个来源分别独立 PR，可直接消费或必要适配。不选中时记录“不采用”及 SDK 替代，不造空包。验收：只装核心不被迫装可选 UI；主题映射、值/事件、dispose、减少动画、资产声明和最低 SDK/平台消费通过；非所有第三方参数都自动承诺支持。 |
| LIB-15A | P1 / PLANNED | LIB-06、LIB-07、LIB-08、LIB-13 | 按使用价值分别开子任务实现数字/范围、日期时间、颜色、复杂多选与 Drawer/Sheet；先冻结选择器范围/locale/取消/边界。每类独立 PR、最小消费者和对应交互/无障碍验证；若选第三方额外依赖 LIB-02/14，未选中的类别可延期，不以合并大 PR 掩盖未完成项。 |
| LIB-15B | P1 / PLANNED | LIB-09、LIB-10、LIB-11、LIB-13 | 分别评估树/大列表/数据表、拖分栏/重排、Avatar/Chip/资源和可选 Skeleton；为复杂控件给出数据量与性能支持上限。每类独立子任务/PR，排序/分页/选择/稳定 key/焦点/语义与卸载证据可复核，不自研完整数据平台。 |
| LIB-16 | P0 / PLANNED | LIB-13；仅所选 P1 进入本次基线时再依赖对应 LIB-14/15A/15B | 用独立的简化工作台验收首批组件：侧栏、顶部栏与标签、主内容与卡片、底部输入区、确认弹窗及结果反馈。使用模拟数据、只用公共入口，验证布局、视觉和基本交互，不实现真实 Agent 流程。同步 Dart 文档、API/目录、README/迁移与 CHANGELOG；运行适用格式/分析、行为、视觉、Web 和发布预检，保留旧 Golden/失败证据。按真实环境测性能，人工/设备/非作者审查与 CI 单列；不要求所有 P1 才能交付 P0。 |
| WEB-LATER | 后续 / PLANNED | LIB-16；另定网站范围 | 再在 deployment 计划可视化设计台：组件配置/层级/状态与事件关系 → 生成带真实 API/版本/主题/动效/无障碍/未支持项的提示词 → 用户 Agent 还原。用至少两个不同组合做实际还原并核对行为；保留设计与运行状态分离、JSON往返/旧数据保护。不将网页、完整场景工程导出或在线模型接入塞进根库首版。 |

主要顺序：LIB-00 → 01 → 03 → 04 → 基础组件 → 12/13 → 16 → WEB-LATER。首批工作台只取上表已确认的组件和适用检查；LIB-12/13 的完整任务仍保留其后续依赖，不因工作台通过而标记完成。LIB-02 在01后进行；仅选中第三方的任务依赖其结果。各组件按明确范围独立实施，08先等输入/操作契约。P1逐类立项，P2先收集需求。

## 6. 每个组件的完成标准与未决事项

每个实施 PR 只补对实际风险有用的验证，不能为凑覆盖率复制实现断言：

1. 说明用途、已有/新增范围、采用来源/版本、SDK/第三方/自研责任及许可；不支持项明确。
2. 接口可从稳定公共入口或明确的可选适配入口消费；默认、主题/局部覆盖优先级、值/回调/返回值、所有权与取消契约有最小可编译例子。
3. 覆盖适用的 idle/hover/focus/pressed/disabled/selected/error/loading/readOnly/indeterminate；无该状态的组件标不适用，不强加虚假字段。
4. 键盘、焦点、语义、中文大字、降级与动态减少动画通过适用自动化；系统读屏/IME/设备性能有实际证据才说通过。新视觉人工查看差异，保留旧基准，构建通过不代替行为。
5. 不耦合页面身份、业务数据、后台服务或持久化；内部资源释放，外部资源不释放；没有持续模糊动画或无意义空闲 ticker。
6. 更新同一能力清单、文档与状态；本地检查、远程 CI、人工/设备、非作者审查分别报告。禁止自动合并、发布或以旧 head 的绿灯代替当前提交。

开工前仍需决定/核实：

- 后续组件的具体名称和签名、单包还是可选适配包、实际采用的依赖和 SDK 影响仍随任务决定。通用组件的命名原则和 8 类目录已确认；不因此引入某个框架。
- 首版精确变体/尺寸/平台支持：LIB-03 冻结，Windows 优先兼容验收，同时保留 Android 原性能目标；其他平台逐项验证。
- 第三方控件的宿主、主题/localization、路由/Overlay、状态枚举和动效开关并不互换；若无法可靠桥接，保留直接依赖用法或拒绝该项，不嵌套整个 App 来隐藏问题。
- 资源/传递依赖和具体复用文件的许可未完成全量核查；本库现有 LICENSE 不因候选根许可标签而自动覆盖外部资产。
- 原 REVIEW、物理 IME、Android 真机/校准、读屏、非作者审查和待合并链保持未验。#25 曾记录 deployment 已跟踪文件受 .gitignore 忽略导致发布预检失败；根库分支是否遇到同问题以当前 CI 为准，不改发布规则绕过。
- 研究文档的“优点”不是生产可用保证；本次只有主线源码/分支与文档核查，没有运行 Flutter/第三方测试、浏览器/设备验收或性能测量。

---

> 历史快照：本页原文对应未合并实现 [#4 / ac0028e](https://github.com/surface-user/Flutter_liquid_glass/tree/ac0028eacd0e1ee22747d454c04a456dcb307377)，移植自 #26 文档快照。以下“当前”“本轮”、PASS/DONE/REVIEW、命令与授权均属于原记录，不表示 main 已具备这些文件/能力，不是本次执行结果，也不产生当前操作授权。代码/测试链接固定到该提交；build/ 日志是原作者本地忽略产物，本次未取得或复验。现行规则见 [AGENTS.md](AGENTS.md)，主线事实见 [README.md](README.md)。


## 历史任务原文（范围与状态保留）

以下为此前模块化重构/专项修复账本。仅将标题下移一级以纳入历史区，正文保留；其中“当前”“本轮”“不扩建”等表述限定于历史批次，不改变本文件上方的新计划和本轮只写文档的边界。

## 组件库模块化重构任务

### 当前目标与范围

状态：IN_PROGRESS。M0 完成；五类专项缺陷已由五个子Agent修复并经主Agent验收为DONE。根167/167、Windows原生53/53、example8/8及旧视觉通过；M1–M5恢复REVIEW，统一PR/CI与人工实窗、非作者审查及设备项分开记录。
目标：职责与依赖正确 → API/参数契约清晰 → 交互可靠 → 文档和测试可验证 → 视觉细节。
本轮保持旧接口可调用、旧默认布局/视觉、包名、SDK 与依赖；以增量公开配置接入主题和密度，不扩建 example，不修改 StudyWorkbench。
规则唯一来源：[AGENTS.md](AGENTS.md)。本轮优先 Windows 桌面验证；Android 性能与其他平台待验项继续保留。

### 阶段总览

| 阶段 | 状态 | 退出条件 |
| --- | --- | --- |
| M0 现状审计与基线 | DONE | 真实 API/依赖清单、单一账本、基线与限制可复核 |
| M1 结构与依赖 | REVIEW | 无循环/反向依赖；公开 API 与原视觉兼容；适用测试通过 |
| M2 主题、Tokens、Density | REVIEW | BUG-TEST-01/04已修并验收；等待非作者审查/必要人工验收 |
| M3 现有组件接入规范 | REVIEW | BUG-TEST-03/04已验收；必要人工/审查保留 |
| M4 最小桌面能力 | REVIEW | 五类缺陷已验收；非作者审查与实窗人工保留 |
| M5 回归与交付 | REVIEW | 新旧回归全部通过；统一PR/CI、人工与审查单列 |

### 活跃任务及后续验收条件

#### 五个缺陷并行修复调度（2026-11-11）

用户指定当前对话为主 Agent，共五个子 Agent 分别负责 BUG-TEST-01–05，完成后统一提交一个 PR。实际账本路径为小写 doc/task.md（不另建 doc/TASK.md）。基线 51054e9，修复分支 codex/fix-five-contract-bugs；保留原失败回归和历史证据。

就绪条件：对应公开契约、失败回归和实现均已具备；阶段审查/设备待验不阻塞本地缺陷修复。平台最多三个子 Agent 同时运行，分两批启动共五个；共享 theme/theme.dart 的 01→04 按文件所有权串行。Flutter 命令也按项目规范串行执行，其他互不重叠的代码可并行。

| 任务 | 依赖 | 调度状态 | 验收条件 |
| --- | --- | --- | --- |
| BUG-TEST-01 | 专项失败回归（已具备） | DONE | 实现已提交主Agent；Paint回读精度按ARGB32严格比较后复验通过，未改目标色 |
| BUG-TEST-02 | 专项失败回归（已具备） | DONE | 子Agent新增3项+原selected两项5/5，主Agent根167/167、原生53/53验收通过 |
| BUG-TEST-03 | 专项失败回归（已具备） | DONE | 子Agent新4项+原component5项9/9，原230宽度回归1/1；主Agent根167/167、原生53/53验收通过 |
| BUG-TEST-04 | BUG-TEST-01 REVIEW 后释放主题文件（已满足） | DONE | 新增10项+01两项+原core/desktop22项34/34；主Agent根167/167、原生53/53验收通过 |
| BUG-TEST-05 | 专项失败回归（已具备） | DONE | 新增3项、原菜单3项及原owner切换回归均通过；主Agent根167/167、原生53/53验收通过 |

子 Agent 实现完成置 REVIEW；主 Agent 检查代码、原断言及 Windows 回归，通过才置 DONE，失败退回 IN_PROGRESS。五项已验收，统一[草稿PR #4](https://github.com/surface-user/Flutter_liquid_glass/pull/4)已创建；最终head的CI待核对。物理IME、Android真机和非作者审查不虚报DONE，也不自动合并。

#### Windows / Flutter 函数专项验证（2026-11-11）

用户要求新增测试任务，并由额外子代理独立验证每个函数。本轮基于 `9e4daef`，分支 `codex/test-function-verification`。验证范围为 lib/ 的构造器、方法、getter、顶层函数及其公开使用链；私有函数通过可观察行为验证。测试通过不等于穷尽所有输入；物理 IME、无 Android 真机和非作者审查的原待验项保留。

| 编号 | 状态 | 任务与退出条件 |
| --- | --- | --- |
| TEST-01 | DONE | AST 清单 103/103 具名函数均已关联独立审查/测试证据及限制 |
| TEST-02 | DONE | 原继承文字失败已修复，根与Windows原生复验全部通过 |
| TEST-03 | DONE | 子代理独立核查 46 函数，新增 9 项 + 原 63 项组合 72/72；主代理补核恒值通知入口与嵌套重绘行为 |
| TEST-04 | DONE | 原桌面五项失败已修复，新增边界和原键鼠回归通过 |
| TEST-05 | DONE | 修复后根167/167、Windows原生53/53、原示例8/8；原139/6和25/6失败记录保留 |

发现的问题逐条追加到本节，包含复现、预期/实际、影响、证据与状态。此前审计先登记失败，本轮实现修复且不更新旧视觉基准或弱化断言。逐函数证据汇总到 [function-verification.md](function-verification.md)。

##### BUG-TEST-01：高对比度输入不能覆盖 Paint 前景

状态：DONE；优先级：P1。
修复验收：2026-11-11 主Agent验收通过。Paint 深浅、shader/stroke、外部对象与普通模式恢复通过；主Agent根167/167、Windows原生53/53。ARGB32严格比较解决nativePaint回读精度差异，目标色不变。
复现：高对比度主题下，GlassTextField.style 传入 TextStyle(foreground: Paint()..color=…)；深色用黑色 Paint，浅色用白色 Paint。
预期/实际：无障碍最终限制应覆盖普通组件样式；实际 EditableText.style.foreground 仍保留传入 Paint，产生暗底黑字或浅底白字。两种 brightness 回归均失败。
影响/位置：glassTextStyle 的 copyWith(color:…) 无法覆盖 TextStyle.foreground；GlassTextField.build 使用该返回值。不是 child 自行绘制不受控内容。
证据：test/function_audit_desktop_test.dart 的 high contrast input overrides foreground Paint 两项；build/function-audit/desktop-test.log。修复后必须保留两项断言与高对比度优先级。

##### BUG-TEST-02：选中状态未传给导航 shape 解析器

状态：DONE；优先级：P2。
修复验收：2026-11-11 主Agent验收通过。8个原透传SDK属性补齐selected；主Agent原shape/颜色和新增3项均通过，根167/167、原生53/53。
复现：GlassNavigationItem(selected:true)，controlStyle.shape 按 WidgetState.selected 返回 StadiumBorder，否则返回 RoundedRectangleBorder。
预期/实际：主题约定的 selected 状态应生效；实际仍得到 RoundedRectangleBorder。独立前景/底色 selected 用例通过，问题在未包装的 SDK 状态属性。
影响/位置：components/desktop_style.dart 的 shape 直接透传，selected 仅注入部分字段。需核对同类状态属性，不能破坏已工作的颜色路径。
证据：test/function_audit_desktop_test.dart 的 selected navigation forwards selected state to shape resolver；desktop-test.log。

##### BUG-TEST-03：弹窗显式最大宽度被外层最小宽度覆盖

状态：DONE；优先级：P2。
修复验收：2026-11-11 主Agent验收通过。外层与表面约束统一；显式230/tight、主题220、旧280/480、Material约束和窄窗2x通过；原视觉未改。
复现：showGlassDialog 内创建 GlassDialog(constraints:BoxConstraints(maxWidth:230))，使用可容纳该宽度的正常窗口。
预期/实际：显式约束应覆盖主题几何；实际 GlassSurface 宽度为 280，超过指定 maxWidth。外层 SDK Dialog 默认最小宽度未与内层约束统一。
影响/位置：GlassDialog.build 只向 GlassSurface 传 constraints，影响桌面紧凑弹窗的明确布局契约。
证据：test/function_audit_desktop_test.dart 的 nested navigator dialog returns local result and keeps parent route；desktop-retest.log，Expected 230 / Actual 280。完整关闭、返回值和父路由先验证通过，最后宽度断言失败。

##### BUG-TEST-04：浅色高对比度卡片继承不可读的全局白字

状态：DONE；优先级：P1。
修复验收：2026-11-11 主Agent验收通过。按实际正文/标题角色补强不可读继承色，保留可读默认；颜色空间统一；新增10项及原对比度回归通过。
复现：Material ThemeData.textTheme.bodyMedium 设置白字，LiquidGlassThemeData 开启浅色 highContrast；GlassCard.child 仅为无 style 的 Text。
预期/实际：库侧高对比度表面应为普通继承文字提供可读前景；实际在 #edf1f8 不透明底上仍保留白字，对比度 1.1328，低于测试中的 4.5。此处不是调用方在 child 上写死 style。
影响/位置：glassTextStyle 在 style 为空且主题 brightness 匹配时不解析强制高对比度前景，影响 GlassCard.build 的内容文字。这与 BUG-TEST-01 的 Paint 覆盖路径不同。
证据：test/function_audit_core_test.dart 的 audit theme: high contrast card keeps inherited text readable；core-retest.log。保持可读性断言，不以要求完全相同的色值制造失败。

##### BUG-TEST-05：菜单打开期间替换 FocusNode 后 Esc 失效

状态：DONE；优先级：P2。
修复验收：2026-11-11 主Agent验收通过。换节点焦点移交、已聚焦菜单项保留、当前trigger恢复、空项/禁用/卸载通过，onClose一次且外部节点不释放。
复现：聚焦并断言 firstFocus.hasFocus，Enter 打开 GlassMenu；保持打开状态，把外部 focusNode 从 firstFocus 换为 secondFocus，随后发送 Esc。
预期/实际：动态重建后的菜单仍可用 Esc 关闭并恢复当前触发器焦点；实际菜单项仍在，未关闭。已先独立验证正常外点关闭、点击消费和再次点击动作均通过，排除“从未聚焦”的夹具问题。
影响/位置：_GlassMenuState.build 的 MenuAnchor/childFocusNode 动态绑定链；不应通过释放外部节点或重建全部业务状态规避。
证据：test/function_audit_desktop_test.dart 的 menu owner replacement restores new focus and consumes outside tap；desktop-retest.log，findsNothing / 实际仍有 Menu action。

DONE 仅表示该任务定义的验收条件满足；实现、自动化、审查、必要人工验收分别记录。阶段远程交付/审查未完成时保留 REVIEW；待验与测试失败分别列出。

#### M0-01：公开 API 与职责盘点

状态：DONE
依赖：无
目标：盘点真实能力与缺口。
范围：导出、参数默认值、依赖、调用方和测试。
不包含：修改其他应用或推断其缺陷。
验收：公开清单完整；循环、硬编码和缺口有代码依据。
验证：api.md、component-catalog.md、architecture.md 与源码核对。
结果：盘点与本地基线完成；根测试 62/62、example 8/8、格式/分析通过。无产品行为变更；阶段代码审查在 M1 交付时进行。
证据：[api.md](api.md)、[component-catalog.md](component-catalog.md)、[architecture.md](architecture.md)。
遗留：设备/跨平台边界见阻塞与待验项。

#### M0-02：文档和任务整理

状态：DONE
依赖：M0-01
目标：建立单一任务账本。
范围：task.md 大小写迁移、规则链接、阶段清单和历史归档。
不包含：复制多份规则或删除旧待验项。
验收：仅有 doc/task.md；引用更新；历史证据和待验项保留。
验证：Git 路径、全文引用及文档链接检查。
结果：盘点与本地基线完成；根测试 62/62、example 8/8、格式/分析通过。无产品行为变更；阶段代码审查在 M1 交付时进行。
证据：Git 大小写重命名、[interaction-history.md](interaction-history.md) 和当前 24 项任务；所有活跃引用迁至小写。
遗留：设备/跨平台边界见阻塞与待验项。

#### M0-03：验证基线

状态：DONE
依赖：M0-01
目标：确认重构前可复核基线。
范围：格式、分析、根测试和 example 全部测试。
不包含：把历史报告算成本次通过或虚构设备数据。
验收：记录 SDK、命令、结果、既有失败和环境限制。
验证：testing.md 与 build/m0-m1/baseline 日志。
结果：盘点与本地基线完成；根测试 62/62、example 8/8、格式/分析通过。无产品行为变更；阶段代码审查在 M1 交付时进行。
证据：[testing.md](testing.md) 的 M0 基线与 build/m0-m1/baseline 日志。
遗留：设备/跨平台边界见阻塞与待验项。

#### M1-01：底层能力拆分

状态：REVIEW
依赖：M0-01、M0-03
目标：让 core 接收解析后配置。
范围：渲染、分组、纯配置、主题感知包装与转场分离。
不包含：更换渲染算法、Shader 或视觉重绘。
验收：core 不依赖 theme/components；主题不依赖页面组件；无重复公开表面。
验证：依赖边界检查、分组/降级/动画及 Golden 回归。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

#### M1-02：主题层定位

状态：REVIEW
依赖：M1-01
目标：集中主题入口并消除反向依赖。
范围：theme/ 与 core 纯配置依赖。
不包含：Tokens、字段合并或密度新功能。
验收：theme 只依赖 core 纯配置；旧解析、copyWith 和 lerp 行为保留。
验证：依赖检查、现有样式及主题测试。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

#### M1-03：现有组件拆分

状态：REVIEW
依赖：M1-01、M1-02
目标：按职责拆分现有组件。
范围：buttons、surfaces、navigation、overlays 与私有共享交互。
不包含：新增桌面组件、空目录或 Example 功能。
验收：每类组件归属明确；交互和 painter 不复制；资源释放保留。
验证：现有指针、键盘、动态减少动画、生命周期和 Golden 测试。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

#### M1-04：导出与兼容

状态：REVIEW
依赖：M1-03
目标：维护唯一公开入口与旧调用。
范围：显式导出、消费者、文档路径、测试和 CI。
不包含：新增公开 API、变更默认值或包版本。
验收：旧公开符号和构造调用可用；内部实现不导出；Golden 不变。
验证：公开入口消费测试、API 源码对照、全部测试及 CI。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

#### M2-01：参数体系

状态：REVIEW
依赖：M1-04
目标：建立基础值、语义角色与必要组件配置。
范围：颜色、字体、几何、材质与实际硬编码。
不包含：大而全配置或参数设置页面。
验收：已有控件需要的参数可通过主题配置并有默认值说明。
验证：配置单测与组件样式断言。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M2-02：继承和覆盖

状态：REVIEW
依赖：M2-01
目标：实现可预测的字段继承。
范围：全局/局部/显式参数、清空语义、不可变复制与插值。
不包含：静态全局变量或静默改变旧替换语义。
验收：优先级明确；局部不串扰；显式清空与动态切换有测试。
验证：配置单测、局部并存和动态切换组件测试。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M2-03：密度机制

状态：REVIEW
依赖：M2-01、M2-02
目标：提供显式紧凑模式。
范围：视觉尺寸、布局约束、命中区域和文字缩放。
不包含：直接缩小旧默认按钮。
验收：旧默认保留；桌面紧凑与触摸目标分开；中英文放大不裁切。
验证：尺寸断言、键鼠测试和长文本 Golden。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M2-04：降级优先级

状态：REVIEW（BUG-TEST-01/04已修复验收）
依赖：M2-02
目标：统一最终生效限制。
范围：性能、减少透明度、高对比度和减少动画。
不包含：以配置代替硬件性能测量。
验收：装饰不能绕过限制；关闭玻璃后功能保持。
验证：降级组合、动态减少动画与无 ticker 回归。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M3-01：表面和卡片

状态：REVIEW（BUG-TEST-04已修复验收）
依赖：M2-01 至 M2-04
目标：接入统一样式与布局。
范围：表面、卡片、交互边界和过滤分组。
不包含：重新实现模糊算法。
验收：配置真实生效；静态与交互语义明确；分组安全。
验证：表面/卡片组件测试及 Golden。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M3-02：按钮与图标按钮

状态：REVIEW
依赖：M2-01 至 M2-04
目标：接入主题、尺寸、密度与适用变体。
范围：hover/focus/pressed/disabled 和布局稳定性。
不包含：业务按钮或重复交互实现。
验收：键鼠可用；状态不抖动、不重复触发；配置覆盖正确。
验证：状态、尺寸、禁用和减少动画测试。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M3-03：顶栏、弹窗与转场

状态：REVIEW（BUG-TEST-03已修复验收）
依赖：M2-01 至 M2-04
目标：统一间距和主题传播。
范围：局部主题、Esc、焦点恢复和窄窗口。
不包含：应用全局业务路由。
验收：局部配置跨浮层有效；关闭恢复焦点；窄窗口无溢出。
验证：路由/弹窗组件测试和窗口人工验收。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M3-04：状态与资源清理

状态：REVIEW
依赖：M3-01 至 M3-03
目标：保证动态状态与所有权正确。
范围：controller、FocusNode、监听器和动画。
不包含：缓存所有 rebuild 或修改业务状态。
验收：外部对象不被释放；内部对象清理；禁用/减少动画无残留。
验证：动态切换、重建、卸载和黑盒事件回归。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

#### M4-01：输入组件

状态：REVIEW（BUG-TEST-01已修复验收）
依赖：M3-04
目标：补齐通用输入/搜索外观接口。
范围：文本、焦点、禁用、只读、错误和前后缀。
不包含：搜索引擎、数据查询或自造文本编辑器。
验收：草稿稳定；受控文本与所有权明确；中文组合、选择和粘贴可用。
验证：组件测试及 Windows 输入法人工验收。
结果：GlassTextField 已实现；组合范围跨 rebuild 保留、选择/粘贴、只读/禁用、外部所有权由组件测试覆盖；Windows 原生输入流程通过。
证据：[api.md](api.md) 与 [testing.md](testing.md)；desktop_components_test、windows-native-final.log。
遗留：物理中文 IME 与人工剪贴板验收待做：测试窗口已启动，computer-use 应用授权超时。非作者审查待进行。

#### M4-02：导航条目

状态：REVIEW（BUG-TEST-02已修复验收）
依赖：M3-04
目标：提供最小导航表现组合。
范围：Tab、侧栏/树条目表现和工具栏。
不包含：TabManager、文件系统或页面缓存。
验收：标题/图标/状态/回调由调用方传入；公开 API 可组合。
验证：键鼠、状态、长标题和最小组合夹具。
结果：GlassNavigationItem、GlassTab、GlassToolbar 已实现；选中/关闭独立、RTL/LTR 缩进、长标题、窄窗口换行、键盘和原生导航均通过。
证据：[api.md](api.md)、[testing.md](testing.md)；公开消费者、desktop_components_test、Windows 原生测试。
遗留：实窗人工键鼠与非作者审查待进行。

#### M4-03：菜单和浮层

状态：REVIEW（BUG-TEST-05已修复验收）
依赖：M3-03、M3-04
目标：补齐明确需要的菜单交互。
范围：必要菜单、焦点、Esc、关闭回调和窗口边界。
不包含：未经确认扩大多级菜单与业务路由。
验收：先冻结最小清单；不遮挡关键内容；关闭和焦点行为明确。
验证：浮层组件测试和 Windows 边界人工验收。
结果：单层 GlassMenu 已实现；SDK Esc、关闭/禁用、焦点恢复和 320×240 窗口边界回归通过；Windows 原生菜单→弹窗→Esc 通过。
证据：[testing.md](testing.md)；desktop_components_test、四张新视觉图与原生功能日志。
遗留：实窗人工边界与非作者审查待进行。

#### M4-04：必要反馈组件

状态：REVIEW
依赖：M4-01 至 M4-03
目标：仅补流程真实缺口。
范围：必要加载、提示和空状态。
不包含：占位 API、网络重试或业务状态机。
验收：先证明组合不足；只交付真实需要并可用的反馈。
验证：需求清单、语义和状态组件测试。
结果：Tooltip、CircularProgressIndicator、Text 组合覆盖提示、加载和空状态；语义与加载结束后无残留帧验证通过，无需新增公开类型。
证据：[design-system.md](design-system.md)；desktop_components_test 的 SDK 反馈用例。
遗留：非作者审查待进行。

#### M5-01：测试矩阵

状态：REVIEW（原六项失败保持启用并已通过；根167/167、原生53/53）
依赖：M3、M4
目标：覆盖设计与交互组合。
范围：深浅、旧默认/紧凑、局部覆盖、降级与文字缩放。
不包含：无意义全排列或降低断言。
验收：风险组合和全部新增分支有验证；失败保留。
验证：完整自动化与必要 Golden 人工检查。
结果：根 114/114，example 8/8；16 个桌面组合、窄窗 2x 中英文、RTL、原视觉与四张新增深浅/菜单视觉通过。新增图已逐张目检，保留首次失败和修复证据。
证据：[testing.md](testing.md)；build/m4-m5/root-test.log、example-test.log。
遗留：远程 CI 与非作者审查按本分支提交单列。

#### M5-02：公共接口消费验证

状态：REVIEW
依赖：M4、M5-01
目标：验证独立公开调用。
范围：只导入唯一入口的最小消费者和原 example。
不包含：新增 Showcase 或演示功能。
验收：示例参数真实；仅公开入口即可完成组合。
验证：消费者编译/组件测试及 example 兼容回归。
结果：独立消费者仅导入公开入口和 SDK；显式 26 个导出、架构和公开消费通过。example/lib 未改，原示例 8/8、Web release 与 Windows 消费通过。
证据：[testing.md](testing.md)；example/integration_test/fixtures/desktop_consumer.dart。
遗留：完整跨平台运行/人工验收与非作者审查待进行。

#### M5-03：性能边界检查

状态：REVIEW
依赖：M3、M4
目标：验证开销与资源边界。
范围：ticker、模糊参数、重复过滤和监听器。
不包含：伪造帧时间或以模拟器代替真机。
验收：静态/自动化边界通过；测量仅记录真实目标环境。
验证：静态检查、空闲测试、Windows/Android 实测（具备环境时）。
结果：静态/自动化的过滤、动画与生命周期边界通过。Windows 四模式引擎 profile 已落盘；每模式空闲 10s 无新帧，交互 raster p95 2.296–3.146ms；保留超预算长尾。
证据：[testing.md](testing.md)；windows-profile-final/integration_response_data.json、Android profile kernel 编译。
遗留：用户确认本轮无 Android 真机；真机 profile、设备校准与完整 APK 保留待验。无产品稳定 FPS 结论。

#### M5-04：文档与迁移说明

状态：REVIEW
依赖：M5-01、M5-02
目标：统一真实 API 与正式文档。
范围：设计规范、API、组件目录、测试和 CHANGELOG。
不包含：虚构可用接口或逐测试报告。
验收：接口与示例一致；旧新参数映射和限制明确。
验证：链接、代码示例编译与源码核对。
结果：公开 API、README 示例、设计/架构/组件目录、测试与 CHANGELOG 已更新；旧默认、包名、版本、SDK 和依赖保留。
证据：[api.md](api.md)、[testing.md](testing.md)；相对链接、公开消费者与 Git 差异。
遗留：非作者审查待进行。

#### M5-05：StudyWorkbench 接入清单

状态：REVIEW
依赖：M5-04
目标：划清组件库与应用责任。
范围：紧凑主题、统一控件、TabManager/资源树/页面布局边界。
不包含：修改 StudyWorkbench 或宣称其体验已验收。
验收：接入步骤可执行；库侧能力、应用责任和未验证项分开。
验证：公开 API 最小夹具与接入文档核对。
结果：库侧接入顺序、参数映射、应用责任和验收步骤已交付；使用公开消费者核对。
证据：[studyworkbench-integration.md](studyworkbench-integration.md)。
遗留：未修改或验收 StudyWorkbench，实际接入与业务测试另行执行。

### 阻塞与待验项

- 用户确认本轮无 Android 真机；真机 profile、完整 APK/设备校准与模拟器实际运行仍待完成。Dart kernel 编译与 Windows 数据不能代替。
- 重构前已有 `example/test/failures/` 未跟踪图片，已备份至 `build/m0-m1/baseline/pre-existing-failures/`；本轮亦保留原 `test/failures/`。不以历史图片存在判断当前仍失败。
- 尚未只读核对 StudyWorkbench 真实调用；库侧缺口不等于应用问题根因。
- M2/M3 的旧替换与显式 merge 均保留。M4 最小输入/导航/菜单已完成；Windows 实窗已启动，应用控制授权超时，人工键鼠/物理 IME 仍待验。功能自动化与 profile 分别记为已通过。
- 非作者审查与合并单列；本轮不自动合并、不发布包。

### 交付与审查

- 当前修复分支：`codex/fix-five-contract-bugs`，基于专项提交51054e9，修复提交2776a50。用户已明确授权统一PR；已推送并创建[草稿PR #4](https://github.com/surface-user/Flutter_liquid_glass/pull/4)，以M2/M3分支为基底，包含此前本地的M4/M5、审计和五项修复。最终head的CI以PR Checks为准；未合并或发布。
- 此前专项分支：`codex/test-function-verification`；51054e9记录首次六项失败，本轮已修复，原始失败证据保留。
- M4/M5 分支：`codex/m4-m5-desktop-components`，基于 M2/M3 的 `d0a1954`。此前单独交付授权待确认；现已按用户最新指令纳入统一修复PR，不另开重复PR，最新验证见 [testing.md](testing.md)。
- M2/M3 分支：`codex/m2-theme-density`，基于 M1 的 `17126f0`；实现提交 `e234943`。[草稿 PR #3](https://github.com/surface-user/Flutter_liquid_glass/pull/3) 以 `codex/m0-m1-modularization` 为基底，保留原 PR 与审查状态。
- 此前自动审批拒绝推送；用户在 2026-11-11 明确批准将该分支推送至 `https://github.com/surface-user/Flutter_liquid_glass.git` 并创建草稿 PR，授权阻塞已解除。未合并、未发布。
- M2/M3 本地根 86/86、example 8/8、格式/分析、旧/新 Golden、Web release 和发布预检 0 warnings 通过；远程精确结果以 PR #3 当前提交的 Checks 为准。非作者审查与必要实窗验收仍未完成，保持 REVIEW。

- 分支：`codex/m0-m1-modularization`；实现提交 `c8817c0`。
- [草稿 PR #2](https://github.com/surface-user/Flutter_liquid_glass/pull/2) 以 `codex/phase1-glass-interaction` 为基底，依赖未合并的 [PR #1](https://github.com/surface-user/Flutter_liquid_glass/pull/1)，本 PR 仅展示 M0/M1 差异。
- 本地格式/分析、根 66/66、example 8/8、公开签名 20/20、Web release、发布预检 0 warnings、文档链接与原失败图片保全均通过。
- GitHub Actions 在 PR 上执行静态/行为、Windows 视觉、标题与依赖审查；精确结果以 PR 当前提交的 Checks 为准，不能用旧提交通过覆盖新提交。
- 非作者批准、Windows 实窗、Android 设备与性能仍未完成；M1 保持 REVIEW。没有合并或发布。

### 精简完成索引

- 旧交互/指针高光、GLASS-001、历史视觉失败、远程授权及验证记录一次归档到 [interaction-history.md](interaction-history.md)，原始版本仍可从 Git `8504ca7:doc/TASK.md` 追溯。归档保留记录，不作为当前通过证明。
- 当前盘点：[api.md](api.md)、[component-catalog.md](component-catalog.md)、[architecture.md](architecture.md)。
- 当前验证：[testing.md](testing.md)；旧记录：[VERIFICATION.md](VERIFICATION.md)；Android：[ANDROID_PROFILE.md](ANDROID_PROFILE.md)。

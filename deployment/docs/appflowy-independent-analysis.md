# AppFlowy Flutter 桌面客户端独立研究

状态：REVIEW
研究日期：2026-11-15
固定分支：`main`
完整提交：`8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93`
提交时间：2026-10-28T06:07:24Z；提交信息为 README 图片更新。
研究对象：[AppFlowy-IO/AppFlowy 固定快照](https://github.com/AppFlowy-IO/AppFlowy/tree/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93)。

## 1. 研究范围、方法与证据等级

本报告先研究 AppFlowy 本身，不与任何其他项目比较，也不给出移植或改造方案。重点是 `frontend/appflowy_flutter` 的 Flutter 桌面应用；必要时追到 `frontend/rust-lib` 的本机后端。独立 Web 客户端、网站前端、移动端页面没有被混入桌面实现结论。根路由按 `UniversalPlatform.isDesktop/isMobile` 注册不同入口，确有桌面和移动页面分流，而非仅凭屏幕宽度切换同一页面。[E04](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L46-L64)

本轮通过 GitHub 连接器读取固定 SHA 的目录树、源码和测试，没有下载第三方源码，没有安装依赖、运行生成器、构建、测试或操作浏览器。阅读超过 40 个源码/测试/元信息文件，下面的证据索引按实际论点细分；同一文件可支持多个独立论点，不把证据编号数量当文件数量。所有源代码链接均锚定同一完整 SHA。

证据标注规则：

| 标记 | 含义 | 可以支持什么 |
| --- | --- | --- |
| 文档声称 | README、包说明表达的定位或目标 | 项目想解决的问题，不能直接证明实际体验、安全性或完整性 |
| 源码证实 | 固定快照存在具体实现与调用点 | 静态结构、分支、默认参数、结果传递方式 |
| 合理推断 | 从已核查实现推导的收益、限制或风险 | 有依据的解释，不等于实测结果 |
| 运行未验 | 本轮未启动应用或执行相应验证 | 帧率、屏幕阅读器表现、窗口溢出、磁盘可靠性等仍未知 |

应用 `pubspec.yaml` 标为版本 0.11.4、`publish_to: none`，声明 Flutter >=3.27.4、Dart >=3.3.0 <4.0.0；这只是所选源码元信息，不代表已经核对商店/发布包版本或重现其工具链。[E03](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/pubspec.yaml#L1-L87)

## 2. 产品要解决什么问题

### 2.1 用户与工作对象

**文档声称**：AppFlowy 将自己描述为带 AI 的工作空间，面向项目、知识和团队协作，同时强调用户对数据的控制。README 将个人用户与企业/开发者分别描述：前者需要知识和项目工具、跨平台原生体验，后者希望在构件和协作基础设施上进行定制。这里的“控制数据”“原生体验”是产品目标，不能仅凭说明推导安全审计结论。[E01](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/README.md#L1-L18) [E02](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/README.md#L137-L160) [E03](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/pubspec.yaml#L1-L87)

**源码证实**：工作对象不是单纯的文本文件列表。目录中的 `ViewPB.layout` 会映射为文档、表格、看板、日历或聊天插件；表格/看板/日历共用 `DatabaseTabBarViewPlugin`，文档走 `DocumentPlugin`，聊天走 `AIChatPagePlugin`。因此文档与数据库视图都属于工作空间中的页面入口，具体内容由不同插件承担。[E20](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_ext.dart#L92-L131)

### 2.2 产品组织

桌面外壳加载当前工作空间和用户，然后提供 TabsBloc、HomeBloc、HomeSettingBloc、FavoriteBloc 等状态；进入失败和加载中有明确页面分支。侧栏并非固定一种树：没有空间、空间列表为空或工作空间未启用协作时显示旧目录分区，否则显示空间内容。目录分区又区分收藏、协作工作空间/私有区、个人区。[E05](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L48-L169) [E12](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/sidebar.dart#L424-L475) [E13](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/shared/sidebar_folder.dart#L35-L74)

| 产品层级/区域 | 用户看到的组织 | 源码中的责任 |
| --- | --- | --- |
| 用户与工作空间 | 当前用户、工作空间上下文 | DesktopHomeScreen 读取用户与工作空间设置，工作空间状态独立 |
| 收藏、目录、空间 | 在工作空间内定位页面 | HomeSideBar + SidebarSectionsBloc / SpaceBloc / FolderBloc |
| Tab | 多个打开位置；可在已有 Tab 中替换页面 | TabsBloc 管理 PageManager 列表与当前索引 |
| 页面/插件 | 文档、数据库、聊天等内容 | ViewPB 转 Plugin，PluginWidgetBuilder 构造实际页面 |
| 副页面和编辑面板 | 在当前工作区域旁显示额外上下文 | PageManager 次级插件与 HomeSettingBloc 编辑面板是两条不同机制 |

该表是责任划分，不意味着每个用户/套餐/工作空间都会同时显示所有区域。[E05](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L48-L169) [E12](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/sidebar.dart#L424-L475) [E19](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L410-L439) [E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) [E65](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L61-L117)

**合理推断**：这套组织适合在多个相关页面、结构化数据和正文之间来回工作。代价是“页面布局类型”“打开位置”“工作空间/空间”和“内容数据”分别由不同对象维护；它降低单个控件的职责，却提高跨层理解成本。

## 3. 真实桌面布局与响应式边界

### 3.1 外壳结构

DesktopHomeScreen 通过 Stack 叠放主内容、帮助气泡、右侧编辑面板、通知面板、侧栏和拖动边界。主内容不是网页 CSS 布局：其左右位置由 HomeLayout 计算，Flutter Widget 约束和位移动画完成布局。主内容设置 `minWidth: 500`；侧栏是否占据左侧空间取决于它处于常驻还是抽屉模式。[E06](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L253-L318) [E07](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_layout.dart#L13-L43)

主区域内部又是 Column：Windows 额外显示 WindowTitleBar，其下为 TabsManager；正文部分使用 IndexedStack 保留各 Tab 对应位置，当前 PageManager 构造顶栏、PageStack 和 SecondaryView。副页面适配宽度输入为内容可用宽度的 3/7。[E65](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L61-L117)

### 3.2 实际尺寸与分支

| 条件/尺寸 | 核查到的行为 | 边界解释 |
| --- | --- | --- |
| 侧栏最小宽度 268 | HomeLayout 取 268 + resizeOffset 的下限 | 拖动 offset 在 HomeSettingBloc 内夹到 0–200，即该路径约 268–468 |
| 屏幕宽度 <1024 | checkScreenSize 在状态跨越“小屏”边界时，可隐藏展开侧栏或在变宽时恢复 | 不是所有构建都无条件重设；已有状态和分支参与 |
| 展开侧栏且宽度 <=768 | HomeLayout 将侧栏视为 drawer，主内容左偏移变为 0 | 侧栏覆盖内容，而非继续压缩主区域 |
| 编辑面板宽度 400 | 主内容右侧偏移为 400 | 没有在该几何代码中看到窄窗自适应上限 |
| 副页面初始显示 | 宽度取 max(450, 3/7 可用宽度) | 独立于右侧编辑面板，不能把二者当成同一个控件 |
| 主内容 minWidth=500 | 在外层位置约束中存在内容最小宽度 | 极窄窗口的最终效果须实际运行验证 |

证据：[E07](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_layout.dart#L13-L43) [E08](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_sizes.dart#L1-L25) [E09](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/flowy_infra/lib/size.dart#L3-L11) [E10](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart#L53-L113) [E62](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L232-L315) [E65](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L61-L117)。

**源码证实**：这里有两个不同断点——1024 用于自动折叠状态，768 用于展开侧栏是否覆盖正文。它们不是一个统一“移动端断点”，桌面窄窗也不会因此切换为 MobileHomeScreen。[E04](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L46-L64) [E07](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_layout.dart#L13-L43) [E10](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart#L53-L113)

**合理推断/运行未验**：侧栏可收折、宽度可调和副页面比例能适应常见桌面多任务；500/400/450 的并存限制也意味着极窄窗口或大字体不是仅凭“响应式”一词就能保证。没有实窗缩放或视觉回归结果支持“所有尺寸无溢出”。

## 4. 组件组合与状态归属

| 层 | 已核查的对象 | 持有/接受什么 | 不应混淆的责任 |
| --- | --- | --- | --- |
| 设计系统 | AppFlowyTheme、AppFlowyThemeData | 色彩角色、文字、间距、圆角、阴影；InheritedTheme 提供数据 | 它不持有文档或导航状态 |
| 通用交互 | AFBaseButton | 自己的 FocusNode、hover/focus；外部 onTap、disabled 和样式 builder | 聚焦状态是组件本地状态，业务是否允许操作由外部传入 |
| 模态布局 | AFModal、Header/Body/Footer | child、leading/trailing 插槽与约束 | AFModal 本身不 push 路由、不提交业务 |
| 应用弹窗 | AFTextFieldDialog | 本地 TextEditingController，初始文本、回调、长度限制 | 在 showDialog 之上组合模态布局与输入/按钮 |
| 导航 | TabsBloc / PageManager / PageNotifier | Tab 列表、插件、次级插件、显示通知 | 导航位置与文档编辑内容分开 |
| 页面内容 | DocumentPlugin / DocumentPage / DocumentBloc | 元信息/访问权限、编辑器状态、事务流 | 文档插件生命周期不等于整应用路由生命周期 |
| 后端协议 | ViewBackendService / DocumentService / Dispatch | PB payload、事件、FlowyResult、FFI | 这是应用数据协议，不是视觉组件参数 |

依据：[E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) [E23](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document.dart#L52-L103) [E25](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document_page.dart#L53-L153) [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) [E30](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_service.dart#L177-L198) [E34](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/appflowy_theme.dart#L5-L142) [E35](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/definition/theme_data.dart#L9-L105) [E38](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart#L17-L158) [E39](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/modal/modal.dart#L6-L130) [E45](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart#L101-L148) [E46](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_backend/lib/dispatch/dispatch.dart#L117-L147)。

AFBaseButton 的本地 FocusNode 在 dispose 释放，hover、focus、disabled 进入样式 builder；AFModal 用主题阴影、圆角、表面颜色与间距组合 Center / Padding / ConstrainedBox / DecoratedBox / Material。弹窗业务没有塞进这些基础表面。[E38](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart#L17-L158) [E39](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/modal/modal.dart#L6-L130)

**取舍**：应用同时使用 Material Theme 和 AppFlowyTheme，也同时引用较早的 flowy_infra_ui 与新的 appflowy_ui。例如侧栏条目使用 FlowyHover / FlowyIconButton，新重命名弹窗使用 AFModal / AFTextField / AFFilledTextButton。不能把仓库描述成“所有界面已统一由同一组件体系生成”。[E16](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L574-L620) [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) [E33](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/app_widget.dart#L239-L275)

## 5. 完整导航链：从目录点击到文档内容与过渡

本节限定一条实际可到达的路径：桌面侧栏采用目录分区时，点击一个 Document 类型的 ViewItem。空间分支另有入口，本报告不把目录分区路径硬套为所有工作空间的唯一导航。

| 步骤 | 真实调用/状态变化 | 可复核证据 |
| --- | --- | --- |
| 0. 选择侧栏结构 | _renderFolderOrSpace → SidebarFolder → Personal/Public/PrivateSectionFolder → SectionFolder | [E12](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/sidebar.dart#L424-L475) [E13](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/shared/sidebar_folder.dart#L35-L74) |
| 1. 构造选择回调 | SectionFolder._buildViews 构造 ViewItem；onSelected 调 TabsBloc.openPlugin(view)，Ctrl 情形先 openTab；中键走 openTab | [E14](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/folder/_section_folder.dart#L93-L125) |
| 2. 点击触发 | SingleInnerViewItem 的 GestureDetector.onTap → _handleViewTap；200ms 本地点击节流后调用 widget.onSelected(context, view) | [E15](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L494-L543) [E16](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L574-L620) |
| 3. 事件与插件选择 | TabsBloc.openPlugin 将 view.plugin(arguments) 和 view 放入 TabsEvent.openPlugin；Document 布局映射为 DocumentPlugin | [E18](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L288-L303) [E20](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_ext.dart#L92-L131) |
| 4. 导航状态 | openPlugin 处理器先做短时间重复打开去重，清除次级插件，再 emit(state.openPlugin(...))；若已有相同插件 ID 的 Tab 则选已有位置，否则替换当前 PageManager 的插件 | [E17](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L73-L109) [E19](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L410-L439) |
| 5. 生命周期 | PageManager.setPlugin 先 newPlugin.init，再 PageNotifier.setPlugin；换 ID 时 dispose 原插件，保存最近打开 ID，notifyListeners | [E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) |
| 6. 内容构建 | PageManager.stackWidget 消费 PageNotifier；按插件类型选择实际 builder；DocumentPluginWidgetBuilder.buildWidget 返回 keyed DocumentPage | [E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) [E24](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document.dart#L150-L170) |
| 7. 数据与编辑内容 | DocumentPage 建 DocumentBloc(documentId) 并 initial；根据 loading/error/forceClose/EditorState 分支显示加载、错误或编辑区域；权限状态更新 editable | [E25](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document_page.dart#L53-L153) |
| 7a. 文档加载 | DocumentBloc.initial 调 _fetchDocumentState → DocumentService.openDocument → DocumentEventOpenDocument；DocumentDataPB.toDocument 后构造 EditorState；桌面分支通过 EditorDropHandler 包 AppFlowyEditorPage | [E71](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_bloc.dart#L240-L262) [E72](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart#L25-L30) [E73](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document_page.dart#L157-L207) |
| 8. 视觉过渡 | stackWidget 里的 FadingIndexedStack 在“插件类型 index 改变”时先设 opacity=0，下一帧设回 1，以默认 250ms TweenAnimationBuilder 淡入 | [E21](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L561-L604) [E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) |

**关键限定**：FadingIndexedStack 的触发条件是 `oldWidget.index != widget.index`，index 取自 PluginSandbox 中的插件类型。因此从文档 A 到文档 B 并不能仅凭这段代码断言一定淡入；文档到数据库等类型变化才符合这个局部触发条件。外层 Tab 使用 IndexedStack，也不能把所有 Tab 切换说成“带 250ms 路由动画”。[E21](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L561-L604) [E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) [E65](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L61-L117)

**与应用路由的区别**：进入 DesktopHomeScreen 本身通过 GoRouter 的 CustomTransitionPage 和 FadeTransition；这与内部文档选择的 TabsBloc → PageManager 链是两种机制。前者使用 _slowDuration，而非该内容栈的 250ms 常量。[E04](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L46-L64) [E66](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L514-L524) [E67](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L765-L775)。

**合理推断**：Tab 复用和按插件分发让“打开某个页面”有统一入口；相应地，打开位置、Plugin 生命周期和编辑器加载是连续几个阶段，不能以点击回调完成等同内容已经加载或持久化完成。

## 6. 完整弹窗链：重命名页面

此链从条目的“更多”菜单开始，选择 Rename，追到文本结果、ViewBloc 状态和后端通知，不用 README 或截图推导。

| 阶段 | 实现与结果 | 证据 |
| --- | --- | --- |
| 触发 | 悬停/编辑状态显示更多按钮，onPressed 调 PopoverController.show；右键也能 showAt | [E16](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L574-L620) |
| 菜单动作 | ViewMoreActionPopover 组合 PopoverActionList，构造包含 rename 的 action；动作回调调用 onAction，随后关闭 popover | [E26](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_more_action_button.dart#L40-L109) |
| 应用调用 | ViewMoreActionType.rename 调 showAFTextFieldDialog；initialValue 为 view.nameOrDefault，maxLength=256；onConfirm 发 ViewEvent.rename(newValue) | [E27](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L777-L797) |
| 构建路由与 UI | showAFTextFieldDialog 返回 showDialog<String?>；builder 建 AFTextFieldDialog，内部用 AFModal/Header/Body/Footer 和 AFTextField | [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) |
| 本地输入状态 | TextEditingController 初始化为原值并默认全选，组件卸载时 dispose；输入 autofocus；确认按钮监听 controller，trim 后为空则禁用 | [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) |
| 确认与结果 | 提交输入或点确认都会 handleConfirm：trim，空则返回，否则先 onConfirm(text)，再 Navigator.pop(text)；取消/关闭不带文本返回 | [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) |
| 业务状态 | ViewBloc 收 rename，await ViewBackendService.updateView(viewId,name)；成功 rebuild ViewPB.name 并 emit，失败保存 FlowyResult.failure | [E29](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_bloc.dart#L137-L163) |
| 协议与通知 | updateView 建 UpdateViewPayloadPB → FolderEventUpdateView.send；ViewListener 监听 RustStreamReceiver，DidUpdateView 解码 ViewPB，ViewBloc 初始订阅该通知以刷新视图 | [E30](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_service.dart#L177-L198) [E31](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_listener.dart#L36-L85) [E68](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_bloc.dart#L68-L79) |

返回值和回调是两种可用结果通道；此调用点用回调且 unawaited，并未等待 Future 中的 String。**源码证实**：确认即关闭弹窗，后台更新异步继续。**合理推断**：交互更快，但弹窗关闭不代表重命名已保存成功；失败进入 ViewBloc.successOrFailure，是否每个入口都会向用户完整显示错误本轮未追尽。[E27](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L777-L797) [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) [E29](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_bloc.dart#L137-L163)

**验证边界**：仓库有 F2 重命名集成测试，但它寻找的是 RenameViewPopover；不能当成对新 AFTextFieldDialog 链的精确测试。ConfirmPopup 的 Enter/Escape 测试也属于另一种弹窗，不能直接代替此重命名弹窗的键盘、焦点恢复和窄窗验证。[E57](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/test/widget_test/confirm_dialog_test.dart#L54-L94) [E59](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/integration_test/desktop/sidebar/rename_current_item_test.dart#L15-L47)

## 7. 动效：触发、参数、主题和减少动画

| 动效 | 触发与参数来源 | 已知限制 |
| --- | --- | --- |
| 侧栏/编辑/通知面板移动 | HomeSettingState → HomeLayout；拖动 duration=30ms，slide=350ms；外层使用 easeOutQuad，Tween 按 Offset 做 Transform.translate | 关闭完成可返回 SizedBox.shrink；并不是持续改变 blur |
| 内容淡入 | 插件类型 index 改变，默认 250ms；opacity 先 0 再 1 | 同类型文档切换不满足其 index 变化条件 |
| 副页面 | 自持 AnimationController，300ms、easeOut，宽度及水平 offset tween；浮动入口另有 150ms AnimatedSwitcher | 这是另一组动画参数和生命周期 |
| 主题过渡 | AnimatedAppFlowyTheme 继承 ImplicitlyAnimatedWidget，默认 kThemeAnimationDuration；AppFlowyThemeDataTween 调 lerp | 颜色插值；文字样式、圆角、spacing、shadow 直接取 end，并非全部平滑插值 |
| 进入桌面主页 | GoRouter CustomTransitionPage + FadeTransition，_slowDuration | 不等于页面内容插件的淡入 |

证据：[E06](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L253-L318) [E11](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart#L132-L146) [E21](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L561-L604) [E32](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/edit_panel/panel_animation.dart#L25-L47) [E34](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/appflowy_theme.dart#L5-L142) [E35](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/definition/theme_data.dart#L9-L105) [E62](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L232-L315)，以及 E66/E67 固定链接。

**源码证实**：所核查的面板时长函数、FadingIndexedStack、AnimatedPanel、自定义主题动画和副页面控制器，没有在这些本地分支中显式读取 `MediaQuery.disableAnimations` 或 `accessibleNavigation`，AppFlowyThemeData 的已见字段也没有 reduceMotion 开关。**不能据此宣布整个应用不支持减少动画**：Flutter 框架对隐式/显式动画的系统行为、SDK 版本差异，以及其他文件可能的处理并未运行或穷尽验证。准确结论是“这几条已追链路未见统一应用级减少动画策略；系统实际效果待验”。[E11](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart#L132-L146) [E21](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L561-L604) [E32](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/edit_panel/panel_animation.dart#L25-L47) [E34](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/appflowy_theme.dart#L5-L142) [E35](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/definition/theme_data.dart#L9-L105) [E62](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L232-L315)

主题通过 InheritedTheme 传播到组件；App 根同时配置 Material 的 lightTheme/darkTheme/themeMode，并根据当前亮度包 AnimatedAppFlowyTheme。它是一套色彩和组件样式基础设施，但未在这些已见接口中把所有动画参数收敛为统一 motion token。[E33](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/app_widget.dart#L239-L275) [E34](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/appflowy_theme.dart#L5-L142) [E35](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/definition/theme_data.dart#L9-L105)

**静态风险观察**：SecondaryView 的 initState 创建 AnimationController，但其 dispose 只解除监听和释放 widthNotifier，未见 animationController.dispose。控制器清理缺口可直接从这段函数核查；它是否触发 ticker 报错或长期资源占用需要实际开关副页面及卸载验证，不能作为已复现泄漏报告。[E62](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L232-L315)

## 8. 效果通过什么展示：主产品与组件示例分开

AppFlowy 主应用是工作空间产品：用户实际编辑文档、操作数据库、切换页面，其界面效果服务于这些任务；没有证据说明主产品是一款让用户组合 UI、调参并导出 Flutter 控件代码的设计工具。判断依据是上述真实页面/插件链和内容导出链，而不是 README 宣传截图。[E20](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_ext.dart#L92-L131) [E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) [E25](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document_page.dart#L53-L153) [E50](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/export_tab.dart#L18-L181) [E55](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/settings/widgets/files/settings_file_exporter_widget.dart#L228-L273)

仓库另有 `packages/appflowy_ui/example`。它的标题是 AppFlowy UI Example，使用 TabBarView 展示 Button、TextField、Modal、Avatar、Menu、Dropdown Menu 六类页面，并提供明暗主题切换。这才是直接可识别的组件效果展示应用，不能与主应用混为一谈。源码只证实页面分类和主题切换入口，本轮未启动示例、未核查每个示例页是否具备完整的交互状态矩阵或参数编辑。[E42](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/example/lib/main.dart#L24-L125)

包 README 的 Supported components 清单仍将 Modal/Menu/Avatar 等列为未完成，但组件导出和示例已经包含相关类别，说明清单存在滞后，不能用 README 勾选框当真实 API 清单。[E37](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/component.dart#L1-L8) [E40](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/README.md#L1-L39) [E42](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/example/lib/main.dart#L24-L125)

## 9. 接口：Flutter 库 API、应用内部接口和后端协议

这里的“公开”必须分层理解。Dart 符号没有下划线、应用源码可见、README 写了安装示例，都不能单独证明是跨项目稳定承诺。

| 类别 | 实例、参数或结果 | 实际消费点 | 应如何理解 |
| --- | --- | --- | --- |
| Flutter 包导出 API | appflowy_ui.dart 导出组件与主题；AFModal(child,constraints,backgroundColor)，AFBaseButton(onTap,builder,padding,borderRadius,disabled,autofocus,showFocusRing) | dialog_v2 用 AFModal 与 AF 按钮；app 根用 AnimatedAppFlowyTheme | 可从该包入口消费的 Dart API；不等于已核对 pub.dev 发布、稳定性政策或独立宽松许可 |
| 应用服务函数 | showAFTextFieldDialog(context,title,initialValue,onConfirm,maxLength…) → Future<String?> | ViewItem 更多菜单 Rename | 位于 appflowy/lib，不是 appflowy_ui 包导出 API |
| 应用导航协议 | TabsBloc.openPlugin(ViewPB,arguments)，TabsEvent.openTab，ViewPB.plugin | SectionFolder 与 ViewItem | 绑定 ViewPB、Plugin、GetIt 和应用状态，不能当独立导航控件 API |
| 应用插件协议 | Plugin.init/dispose、PluginWidgetBuilder.buildWidget(PluginContext,shrinkWrap,data) | PageManager → DocumentPluginWidgetBuilder | 此应用内部内容扩展机制；未核查外部动态插件 ABI/加载或第三方插件稳定支持 |
| 本机后端事件 | DocumentEventApplyAction(ApplyActionPayloadPB).send、FolderEventUpdateView(UpdateViewPayloadPB).send | DocumentService、ViewBackendService | Protobuf + Dart FFI 的应用协议，不是 HTTP UI 组件接口 |
| 导出服务 | DocumentExporter.export(type,path?) → FlowyResult<String,FlowyError> | ShareBloc 与设置导出 | 序列化用户内容；不是导出视觉样式或控件源码 |

证据：[E18](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L288-L303) [E20](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_ext.dart#L92-L131) [E22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) [E23](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document.dart#L52-L103) [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) [E30](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_service.dart#L177-L198) [E36](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/appflowy_ui.dart#L1-L3) [E37](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/component.dart#L1-L8) [E38](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart#L17-L158) [E39](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/modal/modal.dart#L6-L130) [E41](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/pubspec.yaml#L1-L19) [E45](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart#L101-L148) [E46](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_backend/lib/dispatch/dispatch.dart#L117-L147) [E51](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/export/document_exporter.dart#L13-L65)。

可直接复核的调用实例：

```dart
// 应用自身的实际模式：弹窗回调发业务事件。
showAFTextFieldDialog(
  context: context,
  title: LocaleKeys.disclosureAction_rename.tr(),
  initialValue: widget.view.nameOrDefault,
  onConfirm: (newValue) {
    context.read<ViewBloc>().add(ViewEvent.rename(newValue));
  },
  maxLength: 256,
);
```

该片段摘取自真实调用点并省去外层 unawaited；不是宣称可仅导入 appflowy_ui 就独立运行。[E27](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L777-L797)

```dart
// 实际后端载荷：页面 ID 和新名称进入 PB 事件。
final payload = UpdateViewPayloadPB.create()..viewId = viewId;
if (name != null) payload.name = name;
return FolderEventUpdateView(payload).send();
```

源码还支持 isFavorite 和 extra，这里仅展示重命名所经过的字段。[E30](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_service.dart#L177-L198)

## 10. 保存与导出：输出究竟是什么

### 10.1 编辑保存

DocumentBloc 订阅编辑器 transactionStream，在 TransactionTime.before 且不是 inMemoryUpdate 时，将事务交给 TransactionAdapter。后者将树形编辑器操作适配成后端动作，先处理外部文本 delta，再 applyAction。DocumentService 将其放进 PB 事件，Dispatch 序列化请求并调用 `ffi.async_event`。Rust handler 获取 editable_document 并应用 block action/text delta。[E43](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_bloc.dart#L264-L304) [E44](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/editor_transaction_adapter.dart#L16-L99) [E45](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart#L101-L148) [E46](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_backend/lib/dispatch/dispatch.dart#L117-L147) [E47](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/rust-lib/flowy-document/src/event_handler.rs#L119-L162)

Rust DocumentManager 为新文档调用 save_collab_to_disk，并启动后台创建云端 collab 的任务；打开文档先从持久化 data source 读取，本地不存在时尝试云端数据，随后用 CollabBuilder 创建带 sync_enable 配置的文档。**源码证实的保存对象是文档/协作数据结构，而非 UI 层截图或界面参数**。[E48](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/rust-lib/flowy-document/src/manager.rs#L151-L216) [E49](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/rust-lib/flowy-document/src/manager.rs#L234-L285)

**边界**：本轮没有深入审核所有 Collab 持久化插件、磁盘刷写时机、异常断电恢复、离线同步冲突或网络重试；“事务送往后端”不等于每一步均已耐久写盘或云端同步成功。还有一处值得继续验证：TransactionAdapter await 了 DocumentService 返回值，但本段没有检查其 FlowyResult。失败的最终提示/重试是否由其他层补齐，本轮未追尽。[E44](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/editor_transaction_adapter.dart#L16-L99) [E45](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart#L101-L148)

### 10.2 单页与批量导出

| 操作 | 真实输出 | 不能扩大成的结论 |
| --- | --- | --- |
| 文档 Export HTML | documentToHTML(document) 的 HTML 字符串，经 ShareBloc 写到 .html | 未证实附带全部本地附件，不能保证离线完整重现 |
| 文档 Export Markdown | 文件选择默认 .zip；customDocumentToMarkdown 构建 md 文件和资源 archive，压缩写入指定路径 | 不是单个裸 .md，也不是 Flutter UI 源码 |
| 文档 Copy to clipboard | 无 path 的 Markdown 字符串，写 plainText | 不传输 zip 附件资源包 |
| 文档 JSON | jsonEncode(document)，单页 .json 入口限 kDebugMode | debug 工具入口不是正式可见格式清单 |
| 数据库 CSV | DatabaseEventExportCSV 的 DatabaseExportDataPB.data，经文件写入 | 不能仅凭 CSV 推断保留所有数据库布局、关系、附件和权限 |
| Raw Database Data | DatabaseEventExportRawDatabaseData，JSON 文件入口限 debug | 与 CSV 不同；未检验可往返重建全部工作空间 |
| 设置 → 选择页面批量导出 | Document 输出 JSON 内容、扩展名 .afdocument；其他 layout 进入 CSV 分支；逐文件写到选定目录，同名加计数 | 不是复制整个用户配置目录，也不是完整账号/工作空间备份 |

证据：[E50](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/export_tab.dart#L18-L181) [E51](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/export/document_exporter.dart#L13-L65) [E52](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/shared/markdown_to_document.dart#L26-L96) [E53](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_bloc.dart#L305-L349) [E54](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/settings/share/export_service.dart#L7-L22) [E55](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/settings/widgets/files/settings_file_exporter_widget.dart#L228-L273)。

Markdown 自定义 parser 涵盖图片、多图、表格/看板/日历、子页、链接预览和文件块等；本轮只追到 archive 汇聚和 zip 写入，没有逐个核对 parser 对所有网络、本地资源和子页面的覆盖。因此“具备资源打包路径”可确认，“所有内容无损导出”不能确认。该函数在转换异常时记录日志后继续，最终可能形成内容为空的 Markdown 文件；这是静态错误处理风险观察，未制作坏数据复现。[E52](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/shared/markdown_to_document.dart#L26-L96)

DocumentExportType.text 虽有枚举成员，但实现直接 throw UnimplementedError；不能列为已实现文本导出。分享/发布与导出也不是同一动作：ShareMenu 分为不同 tab，ShareBloc 的 publish 会更新发布状态和 URL，ExportTab 走的是本地序列化路径。[E51](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/export/document_exporter.dart#L13-L65) [E53](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_bloc.dart#L305-L349) [E69](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_menu.dart#L132-L168)。

### 10.3 导出反馈的边界

ShareButton 提供 ShareBloc，并监听 isLoading=false 且 exportResult 非空后显示成功或错误 toast，HTML/Markdown/CSV 有成功提示。ShareBloc 的 _export 中 HTML/CSV/JSON 采用同步字符串文件写入，此局部没有包裹异常；磁盘满、无写权限等抛出的文件异常是否被上层统一处理，本轮未追尽。不能只因为类型有 FlowyResult 就宣称所有 IO 错误都能变成用户可见失败结果。[E53](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_bloc.dart#L305-L349) [E56](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_button.dart#L33-L108)

## 11. 测试与无障碍证据

### 11.1 看到了什么测试

| 已阅读测试 | 实际断言范围 | 本轮状态 |
| --- | --- | --- |
| confirm_dialog_test.dart | ConfirmPopup 的 Escape 不执行确认且关闭；Enter 执行确认且关闭 | 源码存在，未执行；不是 AFTextFieldDialog 的专门测试 |
| sidebar_view_item_test.dart | 匿名登录后右键条目，打开图标选择并验证页面图标 | 源码存在，未执行 |
| rename_current_item_test.dart | F2 打开 RenameViewPopover，输入并失焦后侧栏显示新名字 | 源码存在，未执行；与本报告重命名对话框不是同一 UI |
| transaction_adapter_test.dart | 插入节点/子节点、外部文本 ID、旧 delta 回退、false 属性格式处理等 | 单元测试源可见，未执行；不证明磁盘持久化或云端同步 |
| appflowy_ui/example/test/widget_test.dart | 仍为 Counter increments smoke test，找 0/1 和 + | 与当前示例 TabBarView 代码明显不对应；未运行，不报告实际失败结果 |

证据：[E57](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/test/widget_test/confirm_dialog_test.dart#L54-L94) [E58](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/integration_test/desktop/sidebar/sidebar_view_item_test.dart#L25-L55) [E59](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/integration_test/desktop/sidebar/rename_current_item_test.dart#L15-L47) [E60](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/test/unit_test/editor/transaction_adapter_test.dart#L10-L155) [E61](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/example/test/widget_test.dart#L13-L30)；事务测试后续案例位于同一固定文件 226、294 行起；当前示例见 [E42](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/example/lib/main.dart#L24-L125)。

这里可以确认有行为测试和数据适配测试投入，也能确认部分示例测试仍残留模板。不能从几个文件外推整个仓库测试质量，更不能把“有测试文件”写成“当前 CI 全通过”。本轮未查询/执行该快照 CI、未比较黄金图像、未检查所有集成测试入口。

### 11.2 无障碍：已有机制与缺口

**源码证实**：AFBaseButton 使用 Focus、ActivateIntent 回调、可见焦点环和 disabled 分支；AFTextFieldDialog 自动聚焦、默认全选、空白确认防护；主页侧栏和编辑面板使用 FocusTraversalGroup。这些是键盘和可操作性的具体机制。[E38](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart#L17-L158) [E28](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) [E70](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L212-L250)。

**源码证实但不等于完整合规**：

- AFBaseButton 在所读文件中没有显式 `Semantics(button: true)`；GestureDetector 可贡献动作语义，但不能据此假定屏幕阅读器拿到了完整按钮角色、名称和禁用状态。[E38](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart#L17-L158)
- App 根用应用设置的 textScaleFactor 替换 MediaQuery.textScaler，并非直接沿用系统文字缩放。这有利于应用自身尺度一致，但用户系统放大设置的实际继承关系必须单独核查。[E33](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/app_widget.dart#L239-L275)
- 侧栏条目 30 高，更多按钮 24 宽；这是桌面密度选择，不等于触摸目标或放大模式已验收。[E08](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_sizes.dart#L1-L25) [E16](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L574-L620)
- 减少动画没有在已追本地链路中统一显式接入；不能通过默认框架行为的猜测填补验收。[E21](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L561-L604) [E32](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/edit_panel/panel_animation.dart#L25-L47) [E34](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/appflowy_theme.dart#L5-L142)

**运行未验**：Windows Narrator、macOS VoiceOver、屏幕阅读器焦点/朗读、整应用 Tab 顺序、模态关闭后的焦点恢复、高对比度、200% 缩放、真实 IME、触摸和减少动画系统设置。README 对 accessible 的描述应视为设计目标，不是这轮取得的合规结果。[E40](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/README.md#L1-L39)

## 12. 优点、取舍与不足

| 观察 | 有证据的优点 | 同时付出的代价/不足 | 置信度 |
| --- | --- | --- | --- |
| 页面与内容插件分工 | 同一个导航入口能打开文档/数据库/聊天；PageManager 负责生命周期和位置 | 私有业务协议较多，不能把它当无需上下文的控件库 API | 高：真实调用链 |
| 侧栏与副页面 | 目录/空间按工作空间状态切换，宽度和收折可配置，副页面支持并排上下文 | 多套尺寸下限/两种侧栏断点，极窄窗口仍待实测 | 高：几何与分支；体验为中 |
| 主题与组合组件 | 语义色、文字/间距/表面插槽和本地交互状态可复用 | Material/旧 Flowy/新 AF 并存；动画参数未见统一 motion 配置 | 高：源码 |
| 用户内容导出 | HTML、带资源路径的 Markdown zip、CSV、afdocument 具有实际调用和写入路径 | 非全工作空间无损备份；debug 格式与未实现 text 必须区分；部分 IO/转换错误路径待验证 | 高：实现；保真性未知 |
| 质量证据 | 存在鼠标/键盘、重命名、事务转换测试 | 部分测试对应旧 UI，组件示例残留计数器模板；无障碍与减动画未取得运行证据 | 高：测试文本；运行未知 |
| 资源生命周期 | DocumentPlugin、DocumentPage、AFBaseButton 可见释放逻辑 | SecondaryView 未见 AnimationController.dispose；是否产生运行问题待复现 | 高：局部事实；风险中 |
| 文档与源码同步 | README 明确目标并有 UI 包说明和示例 | UI 支持列表落后于导出，子包许可证占位 | 高：固定文本 |

各项依据分别见第 3–11 节，不依据截图或宣传语评判“流畅”“高级”“成熟”或性能领先。不存在本轮硬件帧时间、内存、启动速度、安装包、真实辅助技术或生产恢复验证数据。

## 13. 许可证与可复用性的事实边界

根 LICENSE 是 GNU Affero General Public License Version 3，README 也声称 AGPLv3。**因此不能把整个主应用当成 MIT/BSD 代码使用。** 此处仅记录许可证事实，不代替对具体使用/分发方式的法律审查。[E63](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/LICENSE#L1-L18) [E02](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/README.md#L137-L160)

新的 appflowy_ui 子包虽然有独立 pubspec、入口和示例，但其 LICENSE 内容仍为 `TODO: Add your license here.`。这不是一个独立宽松授权证明，也不能仅因存在独立目录就断言它脱离根许可。所有依赖、资源字体和第三方包的许可证未逐项审查；本报告不复制第三方实现，不执行分发或整合动作。[E41](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/pubspec.yaml#L1-L19) [E64](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/LICENSE#L1-L1)

## 14. 结论置信度与剩余核查边界

| 结论 | 等级 | 理由 |
| --- | --- | --- |
| 研究对象的桌面外壳以 Flutter 实现，内容/导航与本机 Rust 事件相连 | 高 | 固定 Dart 路由、Widget、PB/FFI 与 Rust handler 实证 |
| 文档/数据库/聊天以插件形成统一页面入口 | 高 | ViewPB.plugin 到 PageManager/DocumentPlugin 完整链 |
| 页面类型变化存在 250ms 淡入，侧栏/面板使用单独的位移时长 | 高 | 具体触发条件与参数已核查 |
| 新重命名弹窗确认后立即关闭，异步保存结果再进入 ViewBloc | 高 | 从触发、输入状态、回调到后端事件完整追踪 |
| AppFlowy 主产品是工作空间；appflowy_ui/example 是单独组件展示 | 高 | 产品内容与示例 TabBarView 的代码职责不同 |
| 各种窗口、减少动画和辅助技术下的体验质量 | 未知 | 本轮未运行 |
| 内容导出完整性、断电恢复、全部后台协议健壮性 | 未知 | 已核查到序列化/IO/持久化入口，未做往返与故障试验 |
| 公共 UI 包的发布状态、对外兼容承诺和独立许可 | 未确认 | 没有验证 registry/版本政策，子包 LICENSE 为占位 |

本轮交付的是可复核的静态研究，状态 REVIEW 代表材料已写完、等待独立复核；不代表代码改动验收、应用测试通过或实际桌面体验已验证。

## 15. 固定版本证据索引

以下链接的路径、完整 SHA 和行号固定；编号指向一个证据范围，不代表独立文件。导航/弹窗流程中的每个关键步骤均可沿索引追到原始源码。

| 编号 | 文件与核查点 | 固定源码 |
| --- | --- | --- |
| E01 | README：定位、用户与平台：`README.md` | [L1–L18](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/README.md#L1-L18) |
| E02 | README：目标用户与许可：`README.md` | [L137–L160](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/README.md#L137-L160) |
| E03 | 应用元信息与主要依赖：`frontend/appflowy_flutter/pubspec.yaml` | [L1–L87](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/pubspec.yaml#L1-L87) |
| E04 | 平台路由分流：`frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart` | [L46–L64](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L46-L64) |
| E05 | 桌面入口与状态提供：`frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart` | [L48–L169](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L48-L169) |
| E06 | 桌面布局与面板过渡：`frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart` | [L253–L318](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L253-L318) |
| E07 | HomeLayout 几何计算：`frontend/appflowy_flutter/lib/workspace/presentation/home/home_layout.dart` | [L13–L43](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_layout.dart#L13-L43) |
| E08 | 尺寸常量：`frontend/appflowy_flutter/lib/workspace/presentation/home/home_sizes.dart` | [L1–L25](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_sizes.dart#L1-L25) |
| E09 | 宽度断点：`frontend/appflowy_flutter/packages/flowy_infra/lib/size.dart` | [L3–L11](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/flowy_infra/lib/size.dart#L3-L11) |
| E10 | 布局状态、收折与拖动：`frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart` | [L53–L113](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart#L53-L113) |
| E11 | 布局动画时长：`frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart` | [L132–L146](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/home/home_setting_bloc.dart#L132-L146) |
| E12 | 侧栏目录/空间分流：`frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/sidebar.dart` | [L424–L475](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/sidebar.dart#L424-L475) |
| E13 | 个人与协作目录：`frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/shared/sidebar_folder.dart` | [L35–L74](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/shared/sidebar_folder.dart#L35-L74) |
| E14 | 目录条目选择回调：`frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/folder/_section_folder.dart` | [L93–L125](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/folder/_section_folder.dart#L93-L125) |
| E15 | 条目点击节流与悬停：`frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart` | [L494–L543](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L494-L543) |
| E16 | 条目操作入口：`frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart` | [L574–L620](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L574-L620) |
| E17 | Tabs 事件处理：`frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart` | [L73–L109](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L73-L109) |
| E18 | Tabs 接口与页面选择：`frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart` | [L288–L303](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L288-L303) |
| E19 | Tab 复用策略：`frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart` | [L410–L439](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/tabs/tabs_bloc.dart#L410-L439) |
| E20 | 布局到插件映射：`frontend/appflowy_flutter/lib/workspace/application/view/view_ext.dart` | [L92–L131](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_ext.dart#L92-L131) |
| E21 | 插件类型淡入：`frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart` | [L561–L604](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L561-L604) |
| E22 | PageNotifier 与 PageManager：`frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart` | [L616–L746](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L616-L746) |
| E23 | DocumentPlugin 生命周期：`frontend/appflowy_flutter/lib/plugins/document/document.dart` | [L52–L103](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document.dart#L52-L103) |
| E24 | DocumentPage 构建点：`frontend/appflowy_flutter/lib/plugins/document/document.dart` | [L150–L170](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document.dart#L150-L170) |
| E25 | 文档状态与加载/权限：`frontend/appflowy_flutter/lib/plugins/document/document_page.dart` | [L53–L153](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document_page.dart#L53-L153) |
| E26 | 菜单构造与动作返回：`frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_more_action_button.dart` | [L40–L109](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_more_action_button.dart#L40-L109) |
| E27 | 重命名弹窗实际调用点：`frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart` | [L777–L797](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/menu/view/view_item.dart#L777-L797) |
| E28 | 重命名弹窗公开函数与本地状态：`frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart` | [L103–L255](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/dialog_v2.dart#L103-L255) |
| E29 | 重命名异步状态结果：`frontend/appflowy_flutter/lib/workspace/application/view/view_bloc.dart` | [L137–L163](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_bloc.dart#L137-L163) |
| E30 | 重命名后端事件：`frontend/appflowy_flutter/lib/workspace/application/view/view_service.dart` | [L177–L198](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_service.dart#L177-L198) |
| E31 | 后端变更通知：`frontend/appflowy_flutter/lib/workspace/application/view/view_listener.dart` | [L36–L85](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_listener.dart#L36-L85) |
| E32 | 面板 Tween 实现：`frontend/appflowy_flutter/lib/workspace/presentation/widgets/edit_panel/panel_animation.dart` | [L25–L47](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/widgets/edit_panel/panel_animation.dart#L25-L47) |
| E33 | App 根主题与文字缩放：`frontend/appflowy_flutter/lib/startup/tasks/app_widget.dart` | [L239–L275](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/app_widget.dart#L239-L275) |
| E34 | 主题继承与隐式动画：`frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/appflowy_theme.dart` | [L5–L142](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/appflowy_theme.dart#L5-L142) |
| E35 | 主题字段与插值范围：`frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/definition/theme_data.dart` | [L9–L105](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/theme/definition/theme_data.dart#L9-L105) |
| E36 | UI 包导出：`frontend/appflowy_flutter/packages/appflowy_ui/lib/appflowy_ui.dart` | [L1–L3](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/appflowy_ui.dart#L1-L3) |
| E37 | 组件集合导出：`frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/component.dart` | [L1–L8](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/component.dart#L1-L8) |
| E38 | 基础按钮状态和焦点：`frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart` | [L17–L158](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart#L17-L158) |
| E39 | 模态表面与插槽：`frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/modal/modal.dart` | [L6–L130](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/lib/src/component/modal/modal.dart#L6-L130) |
| E40 | UI 包说明：`frontend/appflowy_flutter/packages/appflowy_ui/README.md` | [L1–L39](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/README.md#L1-L39) |
| E41 | UI 包版本与依赖：`frontend/appflowy_flutter/packages/appflowy_ui/pubspec.yaml` | [L1–L19](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/pubspec.yaml#L1-L19) |
| E42 | UI 示例与组件分类：`frontend/appflowy_flutter/packages/appflowy_ui/example/lib/main.dart` | [L24–L125](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/example/lib/main.dart#L24-L125) |
| E43 | 文档事务订阅：`frontend/appflowy_flutter/lib/plugins/document/application/document_bloc.dart` | [L264–L304](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_bloc.dart#L264-L304) |
| E44 | 事务到后端适配：`frontend/appflowy_flutter/lib/plugins/document/application/editor_transaction_adapter.dart` | [L16–L99](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/editor_transaction_adapter.dart#L16-L99) |
| E45 | 文档后端事件接口：`frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart` | [L101–L148](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart#L101-L148) |
| E46 | Dart 到 Rust 分发：`frontend/appflowy_flutter/packages/appflowy_backend/lib/dispatch/dispatch.dart` | [L117–L147](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_backend/lib/dispatch/dispatch.dart#L117-L147) |
| E47 | Rust 文档变更处理：`frontend/rust-lib/flowy-document/src/event_handler.rs` | [L119–L162](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/rust-lib/flowy-document/src/event_handler.rs#L119-L162) |
| E48 | 文档持久化与同步构建：`frontend/rust-lib/flowy-document/src/manager.rs` | [L151–L216](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/rust-lib/flowy-document/src/manager.rs#L151-L216) |
| E49 | 文档本地读取与云端回退：`frontend/rust-lib/flowy-document/src/manager.rs` | [L234–L285](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/rust-lib/flowy-document/src/manager.rs#L234-L285) |
| E50 | 导出界面与格式：`frontend/appflowy_flutter/lib/plugins/shared/share/export_tab.dart` | [L18–L181](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/export_tab.dart#L18-L181) |
| E51 | 文档序列化导出：`frontend/appflowy_flutter/lib/workspace/application/export/document_exporter.dart` | [L13–L65](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/export/document_exporter.dart#L13-L65) |
| E52 | Markdown 压缩包内容：`frontend/appflowy_flutter/lib/shared/markdown_to_document.dart` | [L26–L96](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/shared/markdown_to_document.dart#L26-L96) |
| E53 | 导出状态与文件写入：`frontend/appflowy_flutter/lib/plugins/shared/share/share_bloc.dart` | [L305–L349](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_bloc.dart#L305-L349) |
| E54 | 数据库导出事件：`frontend/appflowy_flutter/lib/workspace/application/settings/share/export_service.dart` | [L7–L22](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/settings/share/export_service.dart#L7-L22) |
| E55 | 设置中批量导出：`frontend/appflowy_flutter/lib/workspace/presentation/settings/widgets/files/settings_file_exporter_widget.dart` | [L228–L273](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/settings/widgets/files/settings_file_exporter_widget.dart#L228-L273) |
| E56 | 导出结果反馈：`frontend/appflowy_flutter/lib/plugins/shared/share/share_button.dart` | [L33–L108](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_button.dart#L33-L108) |
| E57 | 确认弹窗测试：`frontend/appflowy_flutter/test/widget_test/confirm_dialog_test.dart` | [L54–L94](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/test/widget_test/confirm_dialog_test.dart#L54-L94) |
| E58 | 侧栏鼠标菜单测试：`frontend/appflowy_flutter/integration_test/desktop/sidebar/sidebar_view_item_test.dart` | [L25–L55](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/integration_test/desktop/sidebar/sidebar_view_item_test.dart#L25-L55) |
| E59 | F2 重命名测试：`frontend/appflowy_flutter/integration_test/desktop/sidebar/rename_current_item_test.dart` | [L15–L47](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/integration_test/desktop/sidebar/rename_current_item_test.dart#L15-L47) |
| E60 | 事务适配单元测试：`frontend/appflowy_flutter/test/unit_test/editor/transaction_adapter_test.dart` | [L10–L155](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/test/unit_test/editor/transaction_adapter_test.dart#L10-L155) |
| E61 | UI 示例模板测试：`frontend/appflowy_flutter/packages/appflowy_ui/example/test/widget_test.dart` | [L13–L30](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/example/test/widget_test.dart#L13-L30) |
| E62 | 副页面控制器生命周期：`frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart` | [L232–L315](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L232-L315) |
| E63 | 根许可证：`LICENSE` | [L1–L18](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/LICENSE#L1-L18) |
| E64 | UI 子包许可证占位：`frontend/appflowy_flutter/packages/appflowy_ui/LICENSE` | [L1–L1](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/packages/appflowy_ui/LICENSE#L1-L1) |
| E65 | Tab 外层布局和副页面比例：`frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart` | [L61–L117](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/home_stack.dart#L61-L117) |
| E66 | 桌面主页路由转场：`frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart` | [L514–L524](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L514-L524) |
| E67 | 路由淡入与时长来源：`frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart` | [L765–L775](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/startup/tasks/generate_router.dart#L765-L775) |
| E68 | ViewBloc 变更通知订阅：`frontend/appflowy_flutter/lib/workspace/application/view/view_bloc.dart` | [L68–L79](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/application/view/view_bloc.dart#L68-L79) |
| E69 | 分享/发布/导出 Tab 分流：`frontend/appflowy_flutter/lib/plugins/shared/share/share_menu.dart` | [L132–L168](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/shared/share/share_menu.dart#L132-L168) |
| E70 | 桌面焦点组：`frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart` | [L212–L250](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart#L212-L250) |
| E71 | 文档读取与 EditorState 初始化：`frontend/appflowy_flutter/lib/plugins/document/application/document_bloc.dart` | [L240–L262](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_bloc.dart#L240-L262) |
| E72 | 文档打开事件：`frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart` | [L25–L30](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/application/document_service.dart#L25-L30) |
| E73 | 桌面编辑器内容构建：`frontend/appflowy_flutter/lib/plugins/document/document_page.dart` | [L157–L207](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/document/document_page.dart#L157-L207) |

未检查：真实应用运行、测试/构建、当前发布包、全仓库语义/动画策略、性能和完整许可证依赖清单。
需保留的风险：报告中静态发现的控制器清理、导出异常处理和测试陈旧问题尚未运行复现；请勿将其升级为已证实的用户故障或将本报告当成产品验收。

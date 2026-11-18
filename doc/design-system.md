# 主题、材质与接口设计规范

## 当前 main 契约

`a0bc51a` 的 LiquidGlassThemeData 只含 brightness/accentColor、五种玻璃样式、motion/performance/accessibility。局部 LiquidGlassTheme(data: …) 完整替换，其次读取 ThemeData.extensions，再按 Material brightness 取默认值。copyWith 的 null 保留原值；嵌套配置整对象替换。main 尚无 merge、GlassLayout、colorScheme/textTheme/controlStyle、VisualDensity 主题字段或配置 copyWith 增量。

main 按钮最小 48×48、padding 20/12；卡片 20、图标按钮 12、弹窗 padding 24/最大宽度 480。实际 API 见 [api.md](api.md)。这些固定默认不能写成已支持主题密度。

玻璃模糊受性能配置限制，高对比/减少透明采用不透明降级；AnimatedGlassSurface 的实际 sigma 取目标。main 的主题 lerp 对 performance/accessibility 在 .5 离散切换，尚无 #4 的过渡期限制交并集增强；后续测试须覆盖。关闭模糊不是“所有组件透明”：当前表面使用不透明 fallback。

## 首批接口约定

已确认的 [8 类组件及首批范围](component-catalog.md#八类组件)按用途划分。主题、材质、动效独立于组件分类；本节规定实现边界，具体签名和字段由 LIB-03 确认。

- 颜色、文字、状态优先使用 SDK ColorScheme/TextTheme/ButtonStyle；间距/尺寸只抽取真实共用值，不复制平行 token 系统。
- 普通实色、透明与玻璃按组件实际支持逐项列明。普通控件独立可用；无逐行过滤器。材质配置不改变受控值、回调、布局语义或键盘行为。
- 新通用组件按用途命名，不带 `Glass` 或 `Liquid` 前缀，例如独立导航条目 `NavigationItem`。`GlassSurface` 的 `Glass` 明确指它提供的材质：它是玻璃表面容器，可包住整个侧栏；普通实色表面可直接用 Flutter 的 `Material`。既有 `Glass*` 公开名称保留以兼容旧调用。
- 样式逐字段按单组件 → 局部主题 → 全局主题 → 默认值回退；同层特定用途覆盖同层通用值，所以局部通用值仍优先于全局特定值。未设置的字段继续继承，性能及系统无障碍最终约束。旧 `LiquidGlassTheme(data: …)` 保留整体替换语义；部分继承须显式表达。
- 每个可空字段说明省略、显式 null、清空/恢复的含义；嵌套 copy/merge 规则明确，主题不串扰。
- 密度是明确选择。保留旧默认与触摸目标；桌面紧凑、长中文/RTL/2x 文字与窄窗分别验收，最小约束允许内容撑开。
- 公共接口复用 Flutter 的 Widget、controller、FocusNode 和回调类型；外部对象由调用方释放。路由/浮层的主题捕获与持续订阅区别明确；返回结果、Esc/返回/外点、焦点圈定/恢复及卸载可验证。
- 第三方主题/宿主和状态枚举必须实测桥接；必要字段无消费点就不公开，未映射字段写明不支持，不自动继承整个 ButtonStyle 契约。

## 首批组件交付

- **操作（LIB-05）**：复用 Flutter 按钮的激活、键盘和焦点机制，补统一外观与状态契约。通用按钮有主要、次要、辅助三种用途和小、中、大三档尺寸，玻璃是独立且可继承的表面配置。空回调禁用；调用方控制加载，组件阻止重复激活并保留布局和已持有的焦点。外观定制不接管激活语义；链接按钮和工具栏不在首批范围。
- **输入与表单（LIB-06）**：由 Flutter 输入和表单控件承载单行、多行和校验。外部 `TextEditingController` 与非空 `initialValue` 不能同时提供；内部状态只用 `initialValue` 初始化。沿用 Flutter 重置行为；同一字段改初值或替换 controller 后，不依赖重置更新基准。本批不加 `resetValue`、专用选择器或自有编辑器；应用持有加载、保存和外部错误。
- **导航（LIB-09A/09）**：复用 [#29 的独立导航条目](https://github.com/surface-user/Flutter_liquid_glass/pull/29)，在其基础上补标签和侧栏组合。应用持有选中项并决定切换；聚焦不等于选中。组件不管理路由、导航树数据或页面缓存。
- **布局与内容容器（LIB-10）**：用 Flutter 布局原语组合卡片、面板和顶部栏；同一内容可由普通 `Material` 或外层 `GlassSurface` 承载。不包装 `Row`、`Column` 等原语，也不做可拖分栏。
- **弹窗与浮层（LIB-08）**：以 Flutter 弹窗和结果机制为基础，形成确认弹窗的焦点与返回值契约；玻璃仅是可选表面。复杂菜单、Popover 和 Sheet 后续按场景评估。

首批用模拟数据的简化工作台验收组合；反馈先用 Flutter 控件，选择与开关、专用选择器及统一反馈接口后续安排。

## #4 增量合同的处置

[固定 M2–M5 设计全文](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/design-system.md) 保留 merge、nullable 清空、40/48px、Paint 可读性、selected 透传、Dialog 约束和 Menu 动态焦点合同。它们属于未合并实现，不是本次 main 的现行功能；后续选用该基底时优先复用并保留原失败/回归，不重复开发或降低标准。

通用库实施前仍需验证最低 SDK 和第三方影响。动效见 [ANIMATION_SPEC.md](ANIMATION_SPEC.md)，完成标准见 [task.md](task.md)；文档目标不能替代组件消费或设备/读屏证据。

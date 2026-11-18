# 架构与依赖边界

## main 现状

以下为 #27 合入后的主线 `4842bea`（Dart 源码与 `a0bc51a` 相同）。6 个实现文件的实际导入关系：

| 文件（相对 lib/src） | 库内依赖 |
| --- | --- |
| style.dart | 无 |
| theme.dart | motion.dart、style.dart |
| motion.dart | theme.dart |
| surface.dart | style.dart、theme.dart |
| backdrop.dart | theme.dart |
| components.dart | motion.dart、style.dart、surface.dart、theme.dart |

theme ↔ motion 仍有循环。此主线没有 core/theme/components 子目录、架构测试或显式 show 清单；公共入口导出上述文件并隐藏 glassReduceMotion/glassTransition。20 项基线声明及调用限制见 [api.md](api.md)。[#29 草稿](https://github.com/surface-user/Flutter_liquid_glass/pull/29)增加无玻璃渲染依赖的 `NavigationItem`，归导航目录并从同一入口导出。

## 通用库目标边界（待实现）

- core：Flutter/Dart 原生纯配置、玻璃绘制/过滤分组与纯转场；不读取业务、主题宿主或第三方 UI 框架。
- theme：语义颜色/文字/几何、密度、动效与无障碍配置；依赖 core 纯配置，复用 SDK ThemeData/ColorScheme/TextTheme/ButtonStyle，不再平建整套状态体系。
- components：按[八类用途](component-catalog.md#八类组件)组织，管理受控值/回调、焦点、语义和自有资源生命周期；不持有业务数据或页面缓存。主题、材质与动效是独立能力。普通 `Material` 和玻璃 `GlassSurface` 可作为外层容器，负责表面绘制、裁剪和适用的降级；子组件的受控值、事件契约和语义保持一致。
- 可选第三方接入：直接消费已有接口，或仅为共同契约做适配。框架主题/localization、Navigator/Overlay 与减少动画不能假定互通；不通过嵌套整个 App 隐藏冲突。
- 后续设计台：消费已验收的稳定 API/版本，不让序列化、在线模型或网站运行时反向进入库核心。

比较已有实现、Flutter SDK 与成熟第三方时，以真实体验、维护成本、最低 SDK、许可和运行开销为依据。第三方无需等 SDK 方案失败才评估；实现选择交付最小可用接口。只在统一主题、交互或兼容确有收益时做适配；布局和基础反馈可直接交付组合用法。[首批交付方式](design-system.md#首批组件交付)不预设所有候选都需采用。

## 依赖隔离与公开入口

本次 main pubspec 只有 Flutter 运行依赖，这是事实而非永久禁止条款。准入执行 [AGENTS.md](AGENTS.md) 的许可、版本/SDK、传递资源、维护、体积和实际平台验证。

首批使用现有单一核心包，复用 Flutter SDK 和已核对的库实现；本批无必须随核心安装的第三方 UI 依赖，不增空适配包。后续有明确收益时，经 LIB-02 核查后选择直接使用或独立可选适配。独立适配有额外维护成本，但不会让核心承担其依赖；条件导出不能让 core pubspec 中声明的依赖变为可选。第三方直接使用时保留命名空间，不把所有 API 纳入本库兼容承诺。

保留 `lightweight_liquid_glass` 包名、`lib/lightweight_liquid_glass.dart` 及既有 Glass API。新增通用组件按用途命名，不加 `Glass` 或 `Liquid` 前缀；具体签名、受控状态、null/默认/清空、返回值和 controller/focus 所有权由 LIB-03 确认。本批不提高核心 SDK 下限。

## 未合并实现与保留证据

[#4 固定实现 ac0028e](https://github.com/surface-user/Flutter_liquid_glass/tree/ac0028eacd0e1ee22747d454c04a456dcb307377/lib) 已将上述职责拆为 26 个源文件，引入 GlassLayout、merge 和五个桌面控件，共 26 个公开声明。这些实现及其测试没有进入本 PR，选择它们作为下一开发基底须先处理 PR 依赖链与审查。

[原 M0–M5 架构全文](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/architecture.md) 保留文件依赖表、part 私有共享交互、20→21→26 导出及架构测试的历史契约。[逐函数归档](function-verification.md) 和 [验证账本](testing.md) 保留失败及复验；不能作为当前 main 或本次提交通过的证据。

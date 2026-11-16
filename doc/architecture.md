# 架构与依赖边界

## main 现状

本轮基底为 `a0bc51a`，没有改 Dart 文件。6 个实现文件的实际导入关系：

| 文件（相对 lib/src） | 库内依赖 |
| --- | --- |
| style.dart | 无 |
| theme.dart | motion.dart、style.dart |
| motion.dart | theme.dart |
| surface.dart | style.dart、theme.dart |
| backdrop.dart | theme.dart |
| components.dart | motion.dart、style.dart、surface.dart、theme.dart |

theme ↔ motion 仍有循环。main 没有 core/theme/components 子目录、架构测试或显式 show 清单；公共入口导出上述文件并隐藏 glassReduceMotion/glassTransition。20 项声明及调用限制见 [api.md](api.md)。

## 通用库目标边界（待实现）

- core：Flutter/Dart 原生纯配置、玻璃绘制/过滤分组与纯转场；不读取业务、主题宿主或第三方 UI 框架。
- theme：语义颜色/文字/几何、密度、动效与无障碍配置；依赖 core 纯配置，复用 SDK ThemeData/ColorScheme/TextTheme/ButtonStyle，不再平建整套状态体系。
- components：普通 UI 与可选玻璃外观，受控值/回调、焦点和自有资源生命周期；使用已解析配置，不持有业务数据或页面缓存。
- 可选第三方接入：直接消费已有接口，或仅为共同契约做适配。框架主题/localization、Navigator/Overlay 与减少动画不能假定互通；不通过嵌套整个 App 隐藏冲突。
- 后续设计台：消费已验收的稳定 API/版本，不让序列化、在线模型或网站运行时反向进入库核心。

采用顺序：已有实现 → SDK 组合/主题 → 第三方直接消费 → 必要适配 → 最小自研。SDK 足够的布局、提示、加载等可交付配方，不重复包装。不同材质不能影响值/事件或语义。

## 依赖隔离与公开入口

本次 main pubspec 只有 Flutter 运行依赖，这是事实而非永久禁止条款。准入执行 [AGENTS.md](AGENTS.md) 的许可、版本/SDK、传递资源、维护、体积和实际平台验证。

LIB-01/02 决定单包或独立适配包。若宣称“只装核心无需第三方框架”，就不能在核心 pubspec 中直接声明该框架；独立适配的维护/版本成本需与实际需求权衡，不预建空包。第三方直接使用时保留命名空间，不把所有 API 自动纳入本库兼容承诺。

当前稳定入口和包名保留。新增通用命名、适配入口、受控状态、null/默认/清空、返回值、controller/focus 所有权在 LIB-03 冻结；不自动重命名 Glass API 或提高核心 SDK。

## 未合并实现与保留证据

[#4 固定实现 ac0028e](https://github.com/surface-user/Flutter_liquid_glass/tree/ac0028eacd0e1ee22747d454c04a456dcb307377/lib) 已将上述职责拆为 26 个源文件，引入 GlassLayout、merge 和五个桌面控件，共 26 个公开声明。这些实现及其测试没有进入本 PR，选择它们作为下一开发基底须先处理 PR 依赖链与审查。

[原 M0–M5 架构全文](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/architecture.md) 保留文件依赖表、part 私有共享交互、20→21→26 导出及架构测试的历史契约。[逐函数归档](function-verification.md) 和 [验证账本](testing.md) 保留失败及复验；不能作为当前 main 或本次提交通过的证据。

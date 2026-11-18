# 组件与能力目录

组件按使用目的分为 8 类，分类参考 [Flutter fluent_ui Gallery](https://pub.dev/packages/fluent_ui/example) 和其[源码目录](https://github.com/bdlukaa/fluent_ui/tree/master/lib/src/controls)。新通用组件按用途命名，从 `package:lightweight_liquid_glass/lightweight_liquid_glass.dart` 导入。开发顺序见 [任务账本](task.md#3-组件整合清单)。

## 八类组件

盘点基于 [`main` 的 `4842bea`](https://github.com/surface-user/Flutter_liquid_glass/tree/4842bea87992f4826b0113f8735d0e3dc558a620) 和 [草稿整合提交 `407900b`](https://github.com/surface-user/Flutter_liquid_glass/tree/407900b40115b52c86fe1a41527478427db2879d)。下表的草稿功能仍待合入。示例中的 Flutter 控件从 SDK 导入。

| 类别 | 职责 | 根库公开入口 | `example/` 中的组合 |
| --- | --- | --- | --- |
| 操作 | 触发命令 | main 有 `GlassButton`、`GlassIconButton`。草稿新增 [`ActionButton`、`IconActionButton`](api.md#通用按钮)，共用用途、尺寸、样式与加载契约 [#35](https://github.com/surface-user/Flutter_liquid_glass/pull/35) | 工作台调用公开通用按钮 [#39](https://github.com/surface-user/Flutter_liquid_glass/pull/39) |
| 输入与表单 | 编辑草稿、校验与提交 | 暂无输入组件 | `Form` 与单行、多行 `TextFormField`，使用 Flutter 的校验和重置 [#34](https://github.com/surface-user/Flutter_liquid_glass/pull/34) |
| 选择与开关 | 改变选项、布尔值或连续范围 | 暂无选择组件 | 三态复选、互斥单选、开关 [#43](https://github.com/surface-user/Flutter_liquid_glass/pull/43)，分段、受控下拉及本地搜索建议 [#45](https://github.com/surface-user/Flutter_liquid_glass/pull/45) |
| 专用选择器 | 编辑日期、时间、颜色等有专属规则的值 | 暂无专用选择器 | 当前草稿尚无相关例程 |
| 导航 | 请求切换页面或视图，由应用持有选中状态与路由 | 草稿新增 [`NavigationItem`](api.md#独立导航条目) [#29](https://github.com/surface-user/Flutter_liquid_glass/pull/29)、[`NavigationTab`](api.md#独立导航标签) [#38](https://github.com/surface-user/Flutter_liquid_glass/pull/38) | 工作台组合条目和可关闭标签，共用应用选中状态 [#39](https://github.com/surface-user/Flutter_liquid_glass/pull/39) |
| 布局与内容容器 | 排列、分隔、展示或展开内容 | main 有 `GlassCard`、`GlassAppBar)。暂无独立于材质的通用容器 | Flutter 卡片、面板、顶栏布局与可选 `GlassSurface` [#33](https://github.com/surface-user/Flutter_liquid_glass/pull/33) |
| 弹窗与浮层 | 临时呈现内容或动作，管理关闭、焦点与结果 | main 有 `GlassDialog`、`showGlassDialog`。[#41](https://github.com/surface-user/Flutter_liquid_glass/pull/41) 修复旧函数退出时长 | 普通/玻璃确认 [#37](https://github.com/surface-user/Flutter_liquid_glass/pull/37)、说明与输入弹窗 [#44](https://github.com/surface-user/Flutter_liquid_glass/pull/44)、`MenuAnchor` 锚定菜单 [#42](https://github.com/surface-user/Flutter_liquid_glass/pull/42) |
| 状态与反馈 | 呈现进度、结果或当前状态 | 暂无反馈组件 | 行内状态、进度与 `ScaffoldMessenger` 提示 [#48](https://github.com/surface-user/Flutter_liquid_glass/pull/48) |

按主要用途归类：按钮触发命令，标签切视图，分段选择修改值；用浮层展示日历的日期选择器仍归专用选择器。应用管理业务数据、页面生命周期和持久化。

## 基础能力

| 能力 | 职责与现有入口 | 对应任务 |
| --- | --- | --- |
| 主题 | 提供视觉默认与覆盖规则。保留 `LiquidGlassThemeData` / `LiquidGlassTheme`，草稿增加按钮主题和导航条目/标签共享主题 [#32](https://github.com/surface-user/Flutter_liquid_glass/pull/32)、[#35](https://github.com/surface-user/Flutter_liquid_glass/pull/35) | LIB-04、LIB-17 |
| 材质 | 控制表面绘制与降级；`GlassSurface` 是可选玻璃表面容器，`GlassStyle` / `GlassPresets` 配置外观，`GlassGroup` / `GlassBackdrop` 协助玻璃表面与背景组合。普通实色表面可用 Flutter `Material` | LIB-04 |
| 动效 | 管理过渡、时序与减少动画。已有 `GlassMotionSpec`、`GlassPageRoute` 与 `AnimatedGlassSurface`，草稿修复减少动画及路由中途返回 [#46](https://github.com/surface-user/Flutter_liquid_glass/pull/46)、[#49](https://github.com/surface-user/Flutter_liquid_glass/pull/49)、[#50](https://github.com/surface-user/Flutter_liquid_glass/pull/50) | LIB-12 |

同一组导航条目可以放在普通实色表面或一个包住侧栏的 `GlassSurface` 里。材质负责模糊、着色、边框和裁剪；选中、焦点和激活由导航条目处理。新通用组件按用途命名；既有 `GlassButton`、`GlassCard`、`GlassDialog` 仍按操作、布局与内容容器、弹窗与浮层归类，公开名称继续兼容。

简化工作台用于验收这些组件的组合及交互。旧 [#4 固定目录](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/component-catalog.md)中的 `GlassTextField`、`GlassNavigationItem`、`GlassTab` 等仍属于旧分支。

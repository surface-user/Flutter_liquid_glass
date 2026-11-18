# 组件与能力目录

组件按使用目的分为 8 类，参考 [Flutter fluent_ui Gallery](https://pub.dev/packages/fluent_ui/example) 和其[源码目录](https://github.com/bdlukaa/fluent_ui/tree/master/lib/src/controls)。分类用来找组件和定范围；每项可由库接口、Flutter 组合或经评估的第三方实现交付，不要求逐项封装。

## 八类组件

| 类别 | 归类边界 | 代表项 | 首批范围 / 对应任务 |
| --- | --- | --- | --- |
| 操作 | 触发命令；持续值的切换归选择与开关 | 按钮、图标按钮、链接按钮、命令工具栏 | [通用按钮和图标按钮](api.md#通用按钮)（主要、次要、辅助）；LIB-05 |
| 输入与表单 | 编辑文本或数字草稿，以及字段校验和提交 | 单行、多行、密码、搜索、数字输入、表单项 | 单行和多行文本输入，见[原生表单示例](getting-started.md#原生表单示例)；沿用 Flutter 重置行为，不加 `resetValue`；LIB-06 |
| 选择与开关 | 改变选项、布尔值或连续范围 | 复选、单选、开关、分段选择、下拉选择、滑块 | 后续；LIB-07、LIB-15A |
| 专用选择器 | 编辑具有专门格式和交互规则的值 | 日期、时间、日历、颜色选择器 | 后续；LIB-15A |
| 导航 | 切换页面或视图；应用持有选中与路由 | 独立导航条目、标签、面包屑、导航轨、导航树 | [`NavigationItem`](api.md#独立导航条目)（LIB-09A）与 [`NavigationTab`](api.md#独立导航标签)（LIB-09） |
| 布局与内容容器 | 排列、分隔、展示或展开内容；不定义渲染材质 | 卡片、面板、列表项、分隔线、折叠区、顶栏布局 | 卡片、面板和顶栏布局组合；LIB-10 |
| 弹窗与浮层 | 临时显示附加内容或交互；按需管理关闭、焦点和结果 | 确认弹窗、菜单、Popover、Tooltip、Sheet | 确认弹窗；LIB-08 |
| 状态与反馈 | 告知进度、结果和当前状态 | 进度、通知、徽标、空态、错误态 | 工作台直接用 Flutter 组合；统一接口后续评估，LIB-11 |

按主要用途归类：按钮触发命令，标签切视图，分段选择修改值；用浮层展示日历的日期选择器仍归专用选择器。应用管理业务数据、页面生命周期和持久化。

## 基础能力

| 能力 | 职责与现有入口 | 对应任务 |
| --- | --- | --- |
| 主题 | 提供颜色、文字、间距、尺寸及覆盖规则；现有 `LiquidGlassThemeData` / `LiquidGlassTheme` 保持兼容 | LIB-03、LIB-04 |
| 材质 | 控制表面绘制与降级；`GlassSurface` 是可选玻璃表面容器，`GlassStyle` / `GlassPresets` 配置外观，`GlassGroup` / `GlassBackdrop` 协助玻璃表面与背景组合。普通实色表面可用 Flutter `Material` | LIB-04 |
| 动效 | 定义状态或画面的过渡、时序与减少动画规则；例如 `GlassMotionSpec`、`GlassPageRoute` 和用于材质外观过渡的 `AnimatedGlassSurface` | LIB-12 |

同一组导航条目可以放在普通实色表面或一个包住侧栏的 `GlassSurface` 里。材质负责模糊、着色、边框和裁剪；选中、焦点和激活由导航条目处理。新通用组件按用途命名；既有 `GlassButton`、`GlassCard`、`GlassDialog` 仍按操作、布局与内容容器、弹窗与浮层归类，公开名称继续兼容。

## 实现状态

[#27 合入后的主线](https://github.com/surface-user/Flutter_liquid_glass/tree/4842bea87992f4826b0113f8735d0e3dc558a620)已有玻璃按钮、卡片、顶栏、弹窗、材质和动效入口；[#29 草稿](https://github.com/surface-user/Flutter_liquid_glass/pull/29)新增独立导航条目；[#4 固定目录](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/component-catalog.md)中的 `GlassNavigationItem`、`GlassTextField`、标签和菜单等是未合并实现。首批范围与各任务状态见 [task.md](task.md)；公开调用见 [api.md](api.md)。

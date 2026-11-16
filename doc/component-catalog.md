# 组件与能力目录

基线与状态见 [README.md](README.md)，公开调用见 [api.md](api.md)。公开声明包含配置、主题和函数，不能当成控件数量。

| 能力 | main a0bc51a | #4 ac0028e（未合并） | 后续通用库 |
| --- | --- | --- | --- |
| 主题/密度 | LiquidGlassThemeData、整体局部替换；无 merge/GlassLayout/controlStyle | merge、SDK 语义色/文字/状态、GlassLayout/密度 | LIB-03/04 冻结普通/透明/玻璃与 SDK 主题桥接 |
| 表面/背景 | GlassSurface、AnimatedGlassSurface、GlassCard、GlassBackdrop、GlassGroup | 模块化与配置消费改进 | 保留裁剪/分组/降级；不为每个控件套过滤器 |
| 操作 | GlassButton、GlassIconButton，SDK InkWell | 按压/hover/指针高光和主题状态增强 | LIB-05，SDK 变体优先；loading 等契约待定 |
| 输入/表单/选择 | 没有本库文本/选择公开类型；可直接用 SDK | GlassTextField 基础输入，不等同 FormField/完整编辑器 | LIB-06/07；SDK 文本/Form/选择优先 |
| 导航/布局 | GlassAppBar、GlassPageRoute；可组合 SDK 布局 | GlassNavigationItem、GlassTab、GlassToolbar | LIB-09/10；树数据/页面缓存/路由业务外置 |
| 浮层 | GlassDialog、showGlassDialog<T> | 再加单层 GlassMenu 与焦点修复 | LIB-08；Popover/多层/Drawer/Sheet 按需求补齐 |
| 反馈/数据展示 | SDK Tooltip/进度/Text 可组合，无本库统一封装 | 有组合消费者验证 | LIB-11/15B；表格/树性能上限需实际测试 |
| 动效 | GlassMotionSpec、五种页面转场、表面过渡、可选背景动画 | 交互时长、动态偏好等增强 | LIB-12；内容切换、展开/反馈按实际机制验收 |
| 可选第三方 | 未采用 | 未采用 | LIB-02/14 评估，未批准具体包 |
| 可视化设计台/提示词 | 无根库能力 | 无根库能力 | WEB-LATER，在 LIB-16 后另定范围 |

#4 的 Windows 自动化不等于物理 IME/读屏、Android 真机或其他平台已验收；本 PR 不重新运行它的测试。旧详表与限制保留在 [固定组件目录](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/component-catalog.md)。

全部 LIB/WEB 新能力仍为 PLANNED，详见 [task.md](task.md)。业务身份、持久化、查询、TabManager 和缓存不进入组件库；SDK 直接组合可作为交付，无需虚设新公开控件。

# 主题、材质与接口设计规范

## 当前 main 契约

`a0bc51a` 的 LiquidGlassThemeData 只含 brightness/accentColor、五种玻璃样式、motion/performance/accessibility。局部 LiquidGlassTheme(data: …) 完整替换，其次读取 ThemeData.extensions，再按 Material brightness 取默认值。copyWith 的 null 保留原值；嵌套配置整对象替换。main 尚无 merge、GlassLayout、colorScheme/textTheme/controlStyle、VisualDensity 主题字段或配置 copyWith 增量。

main 按钮最小 48×48、padding 20/12；卡片 20、图标按钮 12、弹窗 padding 24/最大宽度 480。实际 API 见 [api.md](api.md)。这些固定默认不能写成已支持主题密度。

玻璃模糊受性能配置限制，高对比/减少透明采用不透明降级；AnimatedGlassSurface 的实际 sigma 取目标。main 的主题 lerp 对 performance/accessibility 在 .5 离散切换，尚无 #4 的过渡期限制交并集增强；后续测试须覆盖。关闭模糊不是“所有组件透明”：当前表面使用不透明 fallback。

## 通用库目标（LIB-03/04 待冻结/实现）

- 颜色、文字、状态优先使用 SDK ColorScheme/TextTheme/ButtonStyle；间距/尺寸只抽取真实共用值，不复制平行 token 系统。
- 普通实色、透明与玻璃按组件实际支持逐项列明。普通控件独立可用；无逐行过滤器。材质配置不改变受控值、回调、布局语义或键盘行为。
- 优先级为显式字段 → 局部配置 → 全局配置 → 兼容默认；性能及系统无障碍最终约束。现有“整体替换”继续保留；部分继承采用明确方法，不能偷偷改变旧构造含义。
- 每个可空字段说明省略、显式 null、清空/恢复的含义；嵌套 copy/merge 规则明确，主题不串扰。
- 密度是明确选择。保留旧默认与触摸目标；桌面紧凑、长中文/RTL/2x 文字与窄窗分别验收，最小约束允许内容撑开。
- 外部 controller/FocusNode 保留所有权；路由/浮层的主题捕获与持续订阅区别明确；返回结果、Esc/返回/外点、焦点圈定/恢复及卸载可验证。
- 第三方主题/宿主和状态枚举必须实测桥接；必要字段无消费点就不公开，未映射字段写明不支持，不自动继承整个 ButtonStyle 契约。

## #4 增量合同的处置

[固定 M2–M5 设计全文](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/design-system.md) 保留 merge、nullable 清空、40/48px、Paint 可读性、selected 透传、Dialog 约束和 Menu 动态焦点合同。它们属于未合并实现，不是本次 main 的现行功能；后续选用该基底时优先复用并保留原失败/回归，不重复开发或降低标准。

通用库实施前仍需验证最低 SDK 和第三方影响。动效见 [ANIMATION_SPEC.md](ANIMATION_SPEC.md)，完成标准见 [task.md](task.md)；文档目标不能替代组件消费或设备/读屏证据。

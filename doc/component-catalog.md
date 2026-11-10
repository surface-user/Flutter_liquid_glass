# 真实组件与能力目录

范围：M0/M1。所属模块为重构目标/落点；当前是否通过见 [testing.md](testing.md)。公开调用契约见 [api.md](api.md)，依赖见 [architecture.md](architecture.md)。

| 模块 | 已实现 API | 已有测试与限制 |
| --- | --- | --- |
| core | GlassStyle、GlassPresets、GlassGroup、纯动画/性能/无障碍配置 | style_test、widget_test；配置是显式策略，不是硬件检测 |
| theme | LiquidGlassThemeData、LiquidGlassTheme | 复制/插值、深浅主题、弹窗主题捕获；局部整体替换，无字段合并 |
| components/surfaces | GlassSurface、AnimatedGlassSurface、GlassCard、GlassBackdrop | 限界裁剪、分组隔离、无模糊/高对比度、目标 sigma、背景 ticker、深浅 Golden |
| components/buttons | GlassButton、GlassIconButton | 指针/键盘、禁用、按压取消、动态减少动画、指针 repaint、状态 Golden；48px 旧默认 |
| components/navigation | GlassAppBar、GlassPageRoute | 页面往返、五类转场、源主题捕获；不是 TabManager |
| components/overlays | GlassDialog、showGlassDialog | 可滚动内容、局部主题捕获、返回值、示例窄窗口；完整桌面焦点行为仍需 M3 |

共享 UI 交互与指针 painter 属于 components 内部，不是公开组件。背景默认静态，`animate=true` 才持续移动；减少动画后停止。业务身份、选中资源、页面缓存及数据持久化不属于组件库。

## 已确认缺口（未实现）

- M2：语义文字/颜色、统一间距、密度、字段继承和组件状态配置。当前 padding、尺寸、颜色、字重、交互时长存在硬编码。
- M3：现有组件消费新配置；Windows Esc、焦点恢复、动态局部主题与窄窗口完整契约。
- M4：通用输入/搜索外观、Tab/侧栏/树条目、工具栏、必要菜单及反馈。先用现有 API 组合证明缺口，不建占位类型。
- 实验 Shader 保留原待办；不属于本轮。

本轮只核对仓库内消费者：example/lib/main.dart、test/、example/test/、example/integration_test/；它们均通过公开入口使用库。没有核对 StudyWorkbench 的实际调用，不将其问题归因于本库。

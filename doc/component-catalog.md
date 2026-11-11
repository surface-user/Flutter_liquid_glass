# 真实组件与能力目录

范围：M0–M5。所属模块为实际落点；当前是否通过见 [testing.md](testing.md)。公开调用契约见 [api.md](api.md)，依赖见 [architecture.md](architecture.md)。

| 模块 | 已实现 API | 已有测试与限制 |
| --- | --- | --- |
| core | GlassStyle、GlassPresets、GlassGroup、纯动画/性能/无障碍配置 | style_test、widget_test；配置是显式策略，不是硬件检测 |
| theme | LiquidGlassThemeData、LiquidGlassTheme、GlassLayout | 保留旧整体替换，新增 merge 继承、语义/文字/状态配置及显式密度；严格插值和清空测试 |
| components/surfaces | GlassSurface、AnimatedGlassSurface、GlassCard、GlassBackdrop | 限界裁剪、分组隔离、无模糊/高对比度、目标 sigma、背景 ticker、深浅 Golden |
| components/buttons | GlassButton、GlassIconButton | 指针/键盘、禁用、按压取消、动态减少动画、指针 repaint、状态 Golden；48px 旧默认 |
| components/inputs | GlassTextField | SDK 输入/搜索、只读、禁用、错误和前后缀；组合/选择/粘贴、重建/所有权测试；物理 IME 另验 |
| components/navigation | GlassAppBar、GlassPageRoute、GlassNavigationItem、GlassTab、GlassToolbar | 页面转场；受控条目/Tab、独立关闭、双向缩进、工具栏换行；不是 TabManager |
| components/overlays | GlassDialog、showGlassDialog、GlassMenu | 可滚动弹窗、局部主题捕获；SDK 单层菜单、Esc/焦点/禁用/边界测试 |

共享 UI 交互与指针 painter 属于 components 内部，不是公开组件。背景默认静态，`animate=true` 才持续移动；减少动画后停止。业务身份、选中资源、页面缓存及数据持久化不属于组件库。

## 能力进展与待验缺口

- M2/M3：配置与现有组件接入已实现；合并/显式覆盖、密度、状态、Esc/焦点恢复、外部 FocusNode、2x 文字与窄窗口已有自动化。Windows 实窗及非作者审查待验，不能标记全部完成。
- M4：五个最小桌面组件已实现。提示、加载和空状态通过 SDK Tooltip/CircularProgressIndicator/Text 与容器组合覆盖，不新增重复 API。公开入口夹具验证深浅、密度、降级与文字缩放；原生和审查结果见验证账本。
- 实验 Shader 保留原待办；不属于本轮。

本轮只核对仓库内消费者：example/lib/main.dart、test/、example/test/、example/integration_test/；它们均通过公开入口使用库。没有核对 StudyWorkbench 的实际调用，不将其问题归因于本库。

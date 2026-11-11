# StudyWorkbench 接入清单

此清单只描述本库提供的能力与应用侧步骤。没有修改或审计 StudyWorkbench；公开消费者夹具通过不表示该应用已接入、体验已验收或问题根因已确认。

## 接入顺序

1. 在应用依赖中锁定经审查的提交；本轮分支为 codex/m4-m5-desktop-components，基于尚未合并的 M2/M3，不能从 main 推断增量已可用。
2. 仅导入 `package:lightweight_liquid_glass/lightweight_liquid_glass.dart`，不要依赖 src 路径。运行应用原有测试，记录替换前布局、焦点与编辑草稿基线。
3. 在 ThemeData.extensions 设置 LiquidGlassThemeData；ColorScheme 的 brightness 与 Material 主题保持一致，TextTheme 使用应用现有字体。桌面显式选择 compact + shrinkWrap；触屏保留 padded。局部覆盖使用 LiquidGlassTheme.merge 的 parent.copyWith，旧构造函数仍整体替换。
4. 用 GlassTextField 替换需要统一外观的普通输入/搜索；保留应用持有的 controller、FocusNode、onChanged/onSubmitted。搜索查询、异步取消、防抖、错误来源由应用处理。不要在 build 创建 controller，中文组合期间不要用回写 text 的方式同步状态。
5. 将 TabManager 的标题/选中/关闭映射至 GlassTab；选择与关闭分别接回应用的原动作，页面缓存、脏状态确认和关闭后的选中策略由应用负责。
6. 将资源树的一行映射至 GlassNavigationItem 的 label/leading/trailing/indent/selected；展开、排序、虚拟化、拖放和文件身份仍由应用负责。为长列表复用一个外层表面，避免每一行套模糊。
7. 用 GlassToolbar 组合动作，使用 GlassMenu + SDK MenuItemButton 表现已存在的单层菜单。若业务需要多层、右键位置或异步权限，先明确契约，不假定当前封装已提供。加载/提示/空状态沿用 SDK 与已有容器。
8. 分批替换并运行下面的验收；保留应用原回归失败，独立记录库侧和应用侧结果。

## 参数映射

| 应用需要统一的项目 | 库侧入口 | 应用继续负责 |
| --- | --- | --- |
| 颜色、字体、间距 | colorScheme、textTheme、GlassLayout | 业务信息层级、字体资源和内容样式 |
| 控件状态和密度 | controlStyle、visualDensity、tapTargetSize | 窗口布局、断点及触屏策略 |
| 搜索与草稿 | GlassTextField + InputDecoration | 查询、草稿持久化、冲突和保存 |
| Tab 与资源行 | GlassTab、GlassNavigationItem | TabManager、树模型、路由及页面生命周期 |
| 动作、菜单和弹窗 | GlassToolbar、GlassMenu、showGlassDialog | 权限、业务动作和确认流程 |
| 可访问与性能降级 | GlassAccessibilityConfig、GlassPerformanceConfig | 实机测量与应用自定义内容可读性 |

## 应用侧验收

- 深浅主题、紧凑/触摸、局部覆盖、禁用/只读/错误、中英文 2x 文字与窄窗口。
- 实际中文 IME 候选/组合跨父级 rebuild 不丢失，选择/剪贴板、Tab 顺序、Enter/Esc、菜单窗口边界与焦点恢复。
- 关闭模糊、高对比度、减少透明度/动画后，业务内容仍可读可操作，关闭页面后无监听器或 ticker 残留。
- 对真实资源数量和目标 Windows/Android 设备采样，区分冷启动、空闲和交互；库测试夹具的数据不能作为应用性能结论。

库侧可执行对照：`test/desktop_components_test.dart`、`example/integration_test/fixtures/desktop_consumer.dart`。本次原生/自动化证据与尚缺项目统一见 [testing.md](testing.md)，阶段状态见 [task.md](task.md)。

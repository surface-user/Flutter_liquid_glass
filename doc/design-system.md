# 设计参数与解析契约

## M2/M3 实施约定（2026-11-11）

当前在 codex/m2-theme-density 开发，依赖 M1 已通过的实现与自动化；PR #2 的非作者审查仍待完成，不据此合并。下述契约已接入现有组件，完成/待验状态以 task.md 为准。

## 配置分层与兼容

- 材质继续使用 GlassStyle：圆角、边框、着色、模糊、高光、阴影及显式清空渐变。
- 语义颜色、文字与控件状态复用 Flutter ColorScheme、TextTheme、ButtonStyle；不新增平行颜色体系或自造状态枚举。
- GlassLayout 提供现有组件的 padding、间隔、图标尺寸和弹窗宽度；密度复用 VisualDensity，触摸最小目标由 MaterialTapTargetSize 约束。
- 旧 LiquidGlassTheme(data: …) 仍整体替换。新增 LiquidGlassTheme.merge(data: (parent) => parent.copyWith(…), child: …) 显式继承父配置；未修改字段沿父配置保留。内部通过 Builder 读取最近父主题，不修改静态全局变量。
- 显式组件参数 → 对应局部主题字段 → 外层/全局配置 → 旧默认值；组件覆盖与主题控制样式按字段合并，材质 GlassStyle 继续是完整值。
- 组件 controlStyle 的状态解析返回 null 时继承主题中同一状态。显式材质 style 的底色/边框优先于继承的控件装饰；同时显式给出的 controlStyle 可进一步覆盖对应字段。overlayColor 在底色上做 alpha 合成，透明覆盖层不会擦掉底色。
- 组件旧 padding/duration 等公开 getter 保持旧默认值；内部保留“未提供”的信息，避免构造默认值屏蔽主题。显式 null 表示未提供。
- copyWith 中非空字段 null 表示保留；可空 colorScheme 使用未指定哨兵，显式 null 恢复按 brightness 的旧语义默认。GlassStyle.copyWith 的渐变显式 null 清空；布局/文字/控件配置用空默认配置重置，不创造含糊的 null 含义。
- 嵌套配置不是猜测合并：使用 parent.layout.copyWith、parent.performance.copyWith、parent.accessibility.copyWith、parent.motion.copyWith 或 ButtonStyle.merge 修改对应字段；构造一个全新配置表示显式替换该配置。

## 密度与文字

旧默认：按钮最小 48×48，padding 20/12；卡片 20；图标按钮 12；弹窗 24、最大宽度 480。
显式 VisualDensity.compact（horizontal/vertical=-2）将每侧 padding 减少 4px、默认最小控件尺寸从 48 降至 40px；默认 padded 仍保证至少 48px 的实际布局/命中区域。桌面可以显式 shrinkWrap 采用紧凑最小值。不存在画在一行却把点击扩展到相邻行的隐藏命中区域。
尺寸使用最小约束而非固定高度，长文本和中英文文字缩放由内容撑开。组件显式 padding 优先，默认 getter 与实际主题解析分开。

## 最终限制

性能限制与系统无障碍在装饰解析后执行。系统高对比度强制可读前景/边框；减少透明度和关闭模糊使用不透明 fallback；任一减少动画来源禁止位移和缩放。

高对比度下，显式前景 Paint 用新建纯色 Paint 覆盖，保留排版字段且不修改调用方对象。普通继承文字以组件实际 Material 角色判断不透明降级底上的可读性；低于本库 4.5 对比度测试阈值或继承任意 Paint 时才补强，已有可读默认色保持。颜色空间先统一再计算，阈值测试不代表全部无障碍验收。
主题插值只对可安全绘制的颜色/几何字段渐变，实际 blur sigma 直接采用目标值；性能上限和无障碍限制在过渡期间取更严格值，不能在过渡中暂时解除。
Theme 中各离散字段的切换时机与 nullable 清空、局部并存和动态切换均需测试。控制器与 FocusNode 的原所有权契约保留。

ColorScheme 为 null 时保留旧色；显式配置时 onSurface/surface/primary 提供前景、降级表面和焦点色。TextTheme 的 bodyMedium、labelLarge、headlineSmall、titleLarge 分别供内容、控件、弹窗标题与顶栏使用。更具体的控件前景色优先于文字角色颜色；系统高对比度覆盖普通装饰颜色。默认禁用按钮保留原 .4 前景透明度。

ButtonStyle 的有效字段清单见 api.md；未接入字段不属于当前契约。焦点至少保留 2px 的非纯颜色边缘指示。仅状态变化触发交互动画，指针位置仍直接 repaint。

## 既有契约边界

GlassAppBar 的 preferredSize 无 BuildContext，toolbarHeight 继续由显式参数控制，避免主题改变内部高度却不改变 Scaffold 预留空间。主题可调整其文字、前景和标题间隔。
路由/弹窗沿用 Flutter InheritedTheme 捕获打开时的局部主题；浮层内部可继续合并主题。不能把打开时捕获称为持续订阅源局部主题。

GlassDialog 显式 constraints 同时作用于外层 Dialog 和表面；省略时保留 SDK/Material 最小约束并受 GlassLayout.dialogMaxWidth 限制。GlassMenu 打开期间换节点时移交原触发器焦点，已聚焦菜单项不被抢占；关闭恢复当前有效触发器节点，空 items 与禁用均安全关闭，外部节点仍由调用方释放。

## M4/M5 最小范围

- GlassTextField 复用 SDK TextField；输入/搜索共用一个 API，前后缀、错误和标签通过 InputDecoration，controller/FocusNode 外部所有权与 SDK 内部状态规则保持。
- GlassNavigationItem 表现侧栏/树的一行；接收 label、leading/trailing、indent、selected 和回调，不保存页面/文件身份或展开树状态。
- GlassTab 表现受控选中和独立关闭动作；不持有页面缓存，关闭按钮与选择按钮为相邻控件。
- GlassToolbar 使用可换行组合；GlassMenu 使用 MenuAnchor 与 SDK MenuItemButton，包含焦点、Esc、禁用切换、关闭回调和窗口边界。本轮不增加多级菜单管理器。
- 新桌面条目与菜单默认普通表面，不为每行创建 BackdropFilter。颜色、文字、间距、密度、交互状态复用现有主题。
- 提示、加载、空状态优先用 Tooltip/CircularProgressIndicator/Text 组合验证，不新增占位反馈 API。
- M5 采用公开入口夹具覆盖深浅/密度/降级/文字缩放组合。Windows 原生自动化和 profile 结果见 [testing.md](testing.md)；实窗人工与 Android 真机独立验收。审查不由作者自批。

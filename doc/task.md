# 组件库模块化重构任务

## 当前目标与范围

状态：IN_PROGRESS。M0 完成；五类专项缺陷已由五个子Agent修复并经主Agent验收为DONE。根167/167、Windows原生53/53、example8/8及旧视觉通过；M1–M5恢复REVIEW，统一PR/CI与人工实窗、非作者审查及设备项分开记录。
目标：职责与依赖正确 → API/参数契约清晰 → 交互可靠 → 文档和测试可验证 → 视觉细节。
本轮保持旧接口可调用、旧默认布局/视觉、包名、SDK 与依赖；以增量公开配置接入主题和密度，不扩建 example，不修改 StudyWorkbench。
规则唯一来源：[AGENTS.md](AGENTS.md)。本轮优先 Windows 桌面验证；Android 性能与其他平台待验项继续保留。

## 阶段总览

| 阶段 | 状态 | 退出条件 |
| --- | --- | --- |
| M0 现状审计与基线 | DONE | 真实 API/依赖清单、单一账本、基线与限制可复核 |
| M1 结构与依赖 | REVIEW | 无循环/反向依赖；公开 API 与原视觉兼容；适用测试通过 |
| M2 主题、Tokens、Density | REVIEW | BUG-TEST-01/04已修并验收；等待非作者审查/必要人工验收 |
| M3 现有组件接入规范 | REVIEW | BUG-TEST-03/04已验收；必要人工/审查保留 |
| M4 最小桌面能力 | REVIEW | 五类缺陷已验收；非作者审查与实窗人工保留 |
| M5 回归与交付 | REVIEW | 新旧回归全部通过；统一PR/CI、人工与审查单列 |

## 活跃任务及后续验收条件

### 五个缺陷并行修复调度（2026-11-11）

用户指定当前对话为主 Agent，共五个子 Agent 分别负责 BUG-TEST-01–05，完成后统一提交一个 PR。实际账本路径为小写 doc/task.md（不另建 doc/TASK.md）。基线 51054e9，修复分支 codex/fix-five-contract-bugs；保留原失败回归和历史证据。

就绪条件：对应公开契约、失败回归和实现均已具备；阶段审查/设备待验不阻塞本地缺陷修复。平台最多三个子 Agent 同时运行，分两批启动共五个；共享 theme/theme.dart 的 01→04 按文件所有权串行。Flutter 命令也按项目规范串行执行，其他互不重叠的代码可并行。

| 任务 | 依赖 | 调度状态 | 验收条件 |
| --- | --- | --- | --- |
| BUG-TEST-01 | 专项失败回归（已具备） | DONE | 实现已提交主Agent；Paint回读精度按ARGB32严格比较后复验通过，未改目标色 |
| BUG-TEST-02 | 专项失败回归（已具备） | DONE | 子Agent新增3项+原selected两项5/5，主Agent根167/167、原生53/53验收通过 |
| BUG-TEST-03 | 专项失败回归（已具备） | DONE | 子Agent新4项+原component5项9/9，原230宽度回归1/1；主Agent根167/167、原生53/53验收通过 |
| BUG-TEST-04 | BUG-TEST-01 REVIEW 后释放主题文件（已满足） | DONE | 新增10项+01两项+原core/desktop22项34/34；主Agent根167/167、原生53/53验收通过 |
| BUG-TEST-05 | 专项失败回归（已具备） | DONE | 新增3项、原菜单3项及原owner切换回归均通过；主Agent根167/167、原生53/53验收通过 |

子 Agent 实现完成置 REVIEW；主 Agent 检查代码、原断言及 Windows 回归，通过才置 DONE，失败退回 IN_PROGRESS。五项已验收，统一[草稿PR #4](https://github.com/surface-user/Flutter_liquid_glass/pull/4)已创建；最终head的CI待核对。物理IME、Android真机和非作者审查不虚报DONE，也不自动合并。

### Windows / Flutter 函数专项验证（2026-11-11）

用户要求新增测试任务，并由额外子代理独立验证每个函数。本轮基于 `9e4daef`，分支 `codex/test-function-verification`。验证范围为 lib/ 的构造器、方法、getter、顶层函数及其公开使用链；私有函数通过可观察行为验证。测试通过不等于穷尽所有输入；物理 IME、无 Android 真机和非作者审查的原待验项保留。

| 编号 | 状态 | 任务与退出条件 |
| --- | --- | --- |
| TEST-01 | DONE | AST 清单 103/103 具名函数均已关联独立审查/测试证据及限制 |
| TEST-02 | DONE | 原继承文字失败已修复，根与Windows原生复验全部通过 |
| TEST-03 | DONE | 子代理独立核查 46 函数，新增 9 项 + 原 63 项组合 72/72；主代理补核恒值通知入口与嵌套重绘行为 |
| TEST-04 | DONE | 原桌面五项失败已修复，新增边界和原键鼠回归通过 |
| TEST-05 | DONE | 修复后根167/167、Windows原生53/53、原示例8/8；原139/6和25/6失败记录保留 |

发现的问题逐条追加到本节，包含复现、预期/实际、影响、证据与状态。此前审计先登记失败，本轮实现修复且不更新旧视觉基准或弱化断言。逐函数证据汇总到 [function-verification.md](function-verification.md)。

#### BUG-TEST-01：高对比度输入不能覆盖 Paint 前景

状态：DONE；优先级：P1。
修复验收：2026-11-11 主Agent验收通过。Paint 深浅、shader/stroke、外部对象与普通模式恢复通过；主Agent根167/167、Windows原生53/53。ARGB32严格比较解决nativePaint回读精度差异，目标色不变。
复现：高对比度主题下，GlassTextField.style 传入 TextStyle(foreground: Paint()..color=…)；深色用黑色 Paint，浅色用白色 Paint。
预期/实际：无障碍最终限制应覆盖普通组件样式；实际 EditableText.style.foreground 仍保留传入 Paint，产生暗底黑字或浅底白字。两种 brightness 回归均失败。
影响/位置：glassTextStyle 的 copyWith(color:…) 无法覆盖 TextStyle.foreground；GlassTextField.build 使用该返回值。不是 child 自行绘制不受控内容。
证据：test/function_audit_desktop_test.dart 的 high contrast input overrides foreground Paint 两项；build/function-audit/desktop-test.log。修复后必须保留两项断言与高对比度优先级。

#### BUG-TEST-02：选中状态未传给导航 shape 解析器

状态：DONE；优先级：P2。
修复验收：2026-11-11 主Agent验收通过。8个原透传SDK属性补齐selected；主Agent原shape/颜色和新增3项均通过，根167/167、原生53/53。
复现：GlassNavigationItem(selected:true)，controlStyle.shape 按 WidgetState.selected 返回 StadiumBorder，否则返回 RoundedRectangleBorder。
预期/实际：主题约定的 selected 状态应生效；实际仍得到 RoundedRectangleBorder。独立前景/底色 selected 用例通过，问题在未包装的 SDK 状态属性。
影响/位置：components/desktop_style.dart 的 shape 直接透传，selected 仅注入部分字段。需核对同类状态属性，不能破坏已工作的颜色路径。
证据：test/function_audit_desktop_test.dart 的 selected navigation forwards selected state to shape resolver；desktop-test.log。

#### BUG-TEST-03：弹窗显式最大宽度被外层最小宽度覆盖

状态：DONE；优先级：P2。
修复验收：2026-11-11 主Agent验收通过。外层与表面约束统一；显式230/tight、主题220、旧280/480、Material约束和窄窗2x通过；原视觉未改。
复现：showGlassDialog 内创建 GlassDialog(constraints:BoxConstraints(maxWidth:230))，使用可容纳该宽度的正常窗口。
预期/实际：显式约束应覆盖主题几何；实际 GlassSurface 宽度为 280，超过指定 maxWidth。外层 SDK Dialog 默认最小宽度未与内层约束统一。
影响/位置：GlassDialog.build 只向 GlassSurface 传 constraints，影响桌面紧凑弹窗的明确布局契约。
证据：test/function_audit_desktop_test.dart 的 nested navigator dialog returns local result and keeps parent route；desktop-retest.log，Expected 230 / Actual 280。完整关闭、返回值和父路由先验证通过，最后宽度断言失败。

#### BUG-TEST-04：浅色高对比度卡片继承不可读的全局白字

状态：DONE；优先级：P1。
修复验收：2026-11-11 主Agent验收通过。按实际正文/标题角色补强不可读继承色，保留可读默认；颜色空间统一；新增10项及原对比度回归通过。
复现：Material ThemeData.textTheme.bodyMedium 设置白字，LiquidGlassThemeData 开启浅色 highContrast；GlassCard.child 仅为无 style 的 Text。
预期/实际：库侧高对比度表面应为普通继承文字提供可读前景；实际在 #edf1f8 不透明底上仍保留白字，对比度 1.1328，低于测试中的 4.5。此处不是调用方在 child 上写死 style。
影响/位置：glassTextStyle 在 style 为空且主题 brightness 匹配时不解析强制高对比度前景，影响 GlassCard.build 的内容文字。这与 BUG-TEST-01 的 Paint 覆盖路径不同。
证据：test/function_audit_core_test.dart 的 audit theme: high contrast card keeps inherited text readable；core-retest.log。保持可读性断言，不以要求完全相同的色值制造失败。

#### BUG-TEST-05：菜单打开期间替换 FocusNode 后 Esc 失效

状态：DONE；优先级：P2。
修复验收：2026-11-11 主Agent验收通过。换节点焦点移交、已聚焦菜单项保留、当前trigger恢复、空项/禁用/卸载通过，onClose一次且外部节点不释放。
复现：聚焦并断言 firstFocus.hasFocus，Enter 打开 GlassMenu；保持打开状态，把外部 focusNode 从 firstFocus 换为 secondFocus，随后发送 Esc。
预期/实际：动态重建后的菜单仍可用 Esc 关闭并恢复当前触发器焦点；实际菜单项仍在，未关闭。已先独立验证正常外点关闭、点击消费和再次点击动作均通过，排除“从未聚焦”的夹具问题。
影响/位置：_GlassMenuState.build 的 MenuAnchor/childFocusNode 动态绑定链；不应通过释放外部节点或重建全部业务状态规避。
证据：test/function_audit_desktop_test.dart 的 menu owner replacement restores new focus and consumes outside tap；desktop-retest.log，findsNothing / 实际仍有 Menu action。

DONE 仅表示该任务定义的验收条件满足；实现、自动化、审查、必要人工验收分别记录。阶段远程交付/审查未完成时保留 REVIEW；待验与测试失败分别列出。

### M0-01：公开 API 与职责盘点

状态：DONE
依赖：无
目标：盘点真实能力与缺口。
范围：导出、参数默认值、依赖、调用方和测试。
不包含：修改其他应用或推断其缺陷。
验收：公开清单完整；循环、硬编码和缺口有代码依据。
验证：api.md、component-catalog.md、architecture.md 与源码核对。
结果：盘点与本地基线完成；根测试 62/62、example 8/8、格式/分析通过。无产品行为变更；阶段代码审查在 M1 交付时进行。
证据：[api.md](api.md)、[component-catalog.md](component-catalog.md)、[architecture.md](architecture.md)。
遗留：设备/跨平台边界见阻塞与待验项。

### M0-02：文档和任务整理

状态：DONE
依赖：M0-01
目标：建立单一任务账本。
范围：task.md 大小写迁移、规则链接、阶段清单和历史归档。
不包含：复制多份规则或删除旧待验项。
验收：仅有 doc/task.md；引用更新；历史证据和待验项保留。
验证：Git 路径、全文引用及文档链接检查。
结果：盘点与本地基线完成；根测试 62/62、example 8/8、格式/分析通过。无产品行为变更；阶段代码审查在 M1 交付时进行。
证据：Git 大小写重命名、[interaction-history.md](interaction-history.md) 和当前 24 项任务；所有活跃引用迁至小写。
遗留：设备/跨平台边界见阻塞与待验项。

### M0-03：验证基线

状态：DONE
依赖：M0-01
目标：确认重构前可复核基线。
范围：格式、分析、根测试和 example 全部测试。
不包含：把历史报告算成本次通过或虚构设备数据。
验收：记录 SDK、命令、结果、既有失败和环境限制。
验证：testing.md 与 build/m0-m1/baseline 日志。
结果：盘点与本地基线完成；根测试 62/62、example 8/8、格式/分析通过。无产品行为变更；阶段代码审查在 M1 交付时进行。
证据：[testing.md](testing.md) 的 M0 基线与 build/m0-m1/baseline 日志。
遗留：设备/跨平台边界见阻塞与待验项。

### M1-01：底层能力拆分

状态：REVIEW
依赖：M0-01、M0-03
目标：让 core 接收解析后配置。
范围：渲染、分组、纯配置、主题感知包装与转场分离。
不包含：更换渲染算法、Shader 或视觉重绘。
验收：core 不依赖 theme/components；主题不依赖页面组件；无重复公开表面。
验证：依赖边界检查、分组/降级/动画及 Golden 回归。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

### M1-02：主题层定位

状态：REVIEW
依赖：M1-01
目标：集中主题入口并消除反向依赖。
范围：theme/ 与 core 纯配置依赖。
不包含：Tokens、字段合并或密度新功能。
验收：theme 只依赖 core 纯配置；旧解析、copyWith 和 lerp 行为保留。
验证：依赖检查、现有样式及主题测试。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

### M1-03：现有组件拆分

状态：REVIEW
依赖：M1-01、M1-02
目标：按职责拆分现有组件。
范围：buttons、surfaces、navigation、overlays 与私有共享交互。
不包含：新增桌面组件、空目录或 Example 功能。
验收：每类组件归属明确；交互和 painter 不复制；资源释放保留。
验证：现有指针、键盘、动态减少动画、生命周期和 Golden 测试。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

### M1-04：导出与兼容

状态：REVIEW
依赖：M1-03
目标：维护唯一公开入口与旧调用。
范围：显式导出、消费者、文档路径、测试和 CI。
不包含：新增公开 API、变更默认值或包版本。
验收：旧公开符号和构造调用可用；内部实现不导出；Golden 不变。
验证：公开入口消费测试、API 源码对照、全部测试及 CI。
结果：实现完成；格式/分析通过，根 66/66、example 8/8、API 签名 20/20、Web release 通过；非作者审查待进行；实窗/设备未执行。
证据：[architecture.md](architecture.md)、[testing.md](testing.md) 的 M1 复验与 build/m0-m1/final 日志。
遗留：旧 Android 待验项不阻塞本任务；远程 CI/非作者审查见下方。

### M2-01：参数体系

状态：REVIEW
依赖：M1-04
目标：建立基础值、语义角色与必要组件配置。
范围：颜色、字体、几何、材质与实际硬编码。
不包含：大而全配置或参数设置页面。
验收：已有控件需要的参数可通过主题配置并有默认值说明。
验证：配置单测与组件样式断言。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M2-02：继承和覆盖

状态：REVIEW
依赖：M2-01
目标：实现可预测的字段继承。
范围：全局/局部/显式参数、清空语义、不可变复制与插值。
不包含：静态全局变量或静默改变旧替换语义。
验收：优先级明确；局部不串扰；显式清空与动态切换有测试。
验证：配置单测、局部并存和动态切换组件测试。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M2-03：密度机制

状态：REVIEW
依赖：M2-01、M2-02
目标：提供显式紧凑模式。
范围：视觉尺寸、布局约束、命中区域和文字缩放。
不包含：直接缩小旧默认按钮。
验收：旧默认保留；桌面紧凑与触摸目标分开；中英文放大不裁切。
验证：尺寸断言、键鼠测试和长文本 Golden。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M2-04：降级优先级

状态：REVIEW（BUG-TEST-01/04已修复验收）
依赖：M2-02
目标：统一最终生效限制。
范围：性能、减少透明度、高对比度和减少动画。
不包含：以配置代替硬件性能测量。
验收：装饰不能绕过限制；关闭玻璃后功能保持。
验证：降级组合、动态减少动画与无 ticker 回归。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M3-01：表面和卡片

状态：REVIEW（BUG-TEST-04已修复验收）
依赖：M2-01 至 M2-04
目标：接入统一样式与布局。
范围：表面、卡片、交互边界和过滤分组。
不包含：重新实现模糊算法。
验收：配置真实生效；静态与交互语义明确；分组安全。
验证：表面/卡片组件测试及 Golden。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M3-02：按钮与图标按钮

状态：REVIEW
依赖：M2-01 至 M2-04
目标：接入主题、尺寸、密度与适用变体。
范围：hover/focus/pressed/disabled 和布局稳定性。
不包含：业务按钮或重复交互实现。
验收：键鼠可用；状态不抖动、不重复触发；配置覆盖正确。
验证：状态、尺寸、禁用和减少动画测试。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M3-03：顶栏、弹窗与转场

状态：REVIEW（BUG-TEST-03已修复验收）
依赖：M2-01 至 M2-04
目标：统一间距和主题传播。
范围：局部主题、Esc、焦点恢复和窄窗口。
不包含：应用全局业务路由。
验收：局部配置跨浮层有效；关闭恢复焦点；窄窗口无溢出。
验证：路由/弹窗组件测试和窗口人工验收。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M3-04：状态与资源清理

状态：REVIEW
依赖：M3-01 至 M3-03
目标：保证动态状态与所有权正确。
范围：controller、FocusNode、监听器和动画。
不包含：缓存所有 rebuild 或修改业务状态。
验收：外部对象不被释放；内部对象清理；禁用/减少动画无残留。
验证：动态切换、重建、卸载和黑盒事件回归。
结果：实现完成；格式/分析、根 86/86、example 8/8 通过；旧视觉保留，新增深浅紧凑图已目检；审查/必要实窗待验。
证据：[design-system.md](design-system.md)、[api.md](api.md)、[testing.md](testing.md) 的 M2/M3 记录；原始日志 build/m2。
遗留：非作者审查、Windows 实窗和设备性能未验；不自动合并。

### M4-01：输入组件

状态：REVIEW（BUG-TEST-01已修复验收）
依赖：M3-04
目标：补齐通用输入/搜索外观接口。
范围：文本、焦点、禁用、只读、错误和前后缀。
不包含：搜索引擎、数据查询或自造文本编辑器。
验收：草稿稳定；受控文本与所有权明确；中文组合、选择和粘贴可用。
验证：组件测试及 Windows 输入法人工验收。
结果：GlassTextField 已实现；组合范围跨 rebuild 保留、选择/粘贴、只读/禁用、外部所有权由组件测试覆盖；Windows 原生输入流程通过。
证据：[api.md](api.md) 与 [testing.md](testing.md)；desktop_components_test、windows-native-final.log。
遗留：物理中文 IME 与人工剪贴板验收待做：测试窗口已启动，computer-use 应用授权超时。非作者审查待进行。

### M4-02：导航条目

状态：REVIEW（BUG-TEST-02已修复验收）
依赖：M3-04
目标：提供最小导航表现组合。
范围：Tab、侧栏/树条目表现和工具栏。
不包含：TabManager、文件系统或页面缓存。
验收：标题/图标/状态/回调由调用方传入；公开 API 可组合。
验证：键鼠、状态、长标题和最小组合夹具。
结果：GlassNavigationItem、GlassTab、GlassToolbar 已实现；选中/关闭独立、RTL/LTR 缩进、长标题、窄窗口换行、键盘和原生导航均通过。
证据：[api.md](api.md)、[testing.md](testing.md)；公开消费者、desktop_components_test、Windows 原生测试。
遗留：实窗人工键鼠与非作者审查待进行。

### M4-03：菜单和浮层

状态：REVIEW（BUG-TEST-05已修复验收）
依赖：M3-03、M3-04
目标：补齐明确需要的菜单交互。
范围：必要菜单、焦点、Esc、关闭回调和窗口边界。
不包含：未经确认扩大多级菜单与业务路由。
验收：先冻结最小清单；不遮挡关键内容；关闭和焦点行为明确。
验证：浮层组件测试和 Windows 边界人工验收。
结果：单层 GlassMenu 已实现；SDK Esc、关闭/禁用、焦点恢复和 320×240 窗口边界回归通过；Windows 原生菜单→弹窗→Esc 通过。
证据：[testing.md](testing.md)；desktop_components_test、四张新视觉图与原生功能日志。
遗留：实窗人工边界与非作者审查待进行。

### M4-04：必要反馈组件

状态：REVIEW
依赖：M4-01 至 M4-03
目标：仅补流程真实缺口。
范围：必要加载、提示和空状态。
不包含：占位 API、网络重试或业务状态机。
验收：先证明组合不足；只交付真实需要并可用的反馈。
验证：需求清单、语义和状态组件测试。
结果：Tooltip、CircularProgressIndicator、Text 组合覆盖提示、加载和空状态；语义与加载结束后无残留帧验证通过，无需新增公开类型。
证据：[design-system.md](design-system.md)；desktop_components_test 的 SDK 反馈用例。
遗留：非作者审查待进行。

### M5-01：测试矩阵

状态：REVIEW（原六项失败保持启用并已通过；根167/167、原生53/53）
依赖：M3、M4
目标：覆盖设计与交互组合。
范围：深浅、旧默认/紧凑、局部覆盖、降级与文字缩放。
不包含：无意义全排列或降低断言。
验收：风险组合和全部新增分支有验证；失败保留。
验证：完整自动化与必要 Golden 人工检查。
结果：根 114/114，example 8/8；16 个桌面组合、窄窗 2x 中英文、RTL、原视觉与四张新增深浅/菜单视觉通过。新增图已逐张目检，保留首次失败和修复证据。
证据：[testing.md](testing.md)；build/m4-m5/root-test.log、example-test.log。
遗留：远程 CI 与非作者审查按本分支提交单列。

### M5-02：公共接口消费验证

状态：REVIEW
依赖：M4、M5-01
目标：验证独立公开调用。
范围：只导入唯一入口的最小消费者和原 example。
不包含：新增 Showcase 或演示功能。
验收：示例参数真实；仅公开入口即可完成组合。
验证：消费者编译/组件测试及 example 兼容回归。
结果：独立消费者仅导入公开入口和 SDK；显式 26 个导出、架构和公开消费通过。example/lib 未改，原示例 8/8、Web release 与 Windows 消费通过。
证据：[testing.md](testing.md)；example/integration_test/fixtures/desktop_consumer.dart。
遗留：完整跨平台运行/人工验收与非作者审查待进行。

### M5-03：性能边界检查

状态：REVIEW
依赖：M3、M4
目标：验证开销与资源边界。
范围：ticker、模糊参数、重复过滤和监听器。
不包含：伪造帧时间或以模拟器代替真机。
验收：静态/自动化边界通过；测量仅记录真实目标环境。
验证：静态检查、空闲测试、Windows/Android 实测（具备环境时）。
结果：静态/自动化的过滤、动画与生命周期边界通过。Windows 四模式引擎 profile 已落盘；每模式空闲 10s 无新帧，交互 raster p95 2.296–3.146ms；保留超预算长尾。
证据：[testing.md](testing.md)；windows-profile-final/integration_response_data.json、Android profile kernel 编译。
遗留：用户确认本轮无 Android 真机；真机 profile、设备校准与完整 APK 保留待验。无产品稳定 FPS 结论。

### M5-04：文档与迁移说明

状态：REVIEW
依赖：M5-01、M5-02
目标：统一真实 API 与正式文档。
范围：设计规范、API、组件目录、测试和 CHANGELOG。
不包含：虚构可用接口或逐测试报告。
验收：接口与示例一致；旧新参数映射和限制明确。
验证：链接、代码示例编译与源码核对。
结果：公开 API、README 示例、设计/架构/组件目录、测试与 CHANGELOG 已更新；旧默认、包名、版本、SDK 和依赖保留。
证据：[api.md](api.md)、[testing.md](testing.md)；相对链接、公开消费者与 Git 差异。
遗留：非作者审查待进行。

### M5-05：StudyWorkbench 接入清单

状态：REVIEW
依赖：M5-04
目标：划清组件库与应用责任。
范围：紧凑主题、统一控件、TabManager/资源树/页面布局边界。
不包含：修改 StudyWorkbench 或宣称其体验已验收。
验收：接入步骤可执行；库侧能力、应用责任和未验证项分开。
验证：公开 API 最小夹具与接入文档核对。
结果：库侧接入顺序、参数映射、应用责任和验收步骤已交付；使用公开消费者核对。
证据：[studyworkbench-integration.md](studyworkbench-integration.md)。
遗留：未修改或验收 StudyWorkbench，实际接入与业务测试另行执行。

## 阻塞与待验项

- 用户确认本轮无 Android 真机；真机 profile、完整 APK/设备校准与模拟器实际运行仍待完成。Dart kernel 编译与 Windows 数据不能代替。
- 重构前已有 `example/test/failures/` 未跟踪图片，已备份至 `build/m0-m1/baseline/pre-existing-failures/`；本轮亦保留原 `test/failures/`。不以历史图片存在判断当前仍失败。
- 尚未只读核对 StudyWorkbench 真实调用；库侧缺口不等于应用问题根因。
- M2/M3 的旧替换与显式 merge 均保留。M4 最小输入/导航/菜单已完成；Windows 实窗已启动，应用控制授权超时，人工键鼠/物理 IME 仍待验。功能自动化与 profile 分别记为已通过。
- 非作者审查与合并单列；本轮不自动合并、不发布包。

## 交付与审查

- 当前修复分支：`codex/fix-five-contract-bugs`，基于专项提交51054e9，修复提交2776a50。用户已明确授权统一PR；已推送并创建[草稿PR #4](https://github.com/surface-user/Flutter_liquid_glass/pull/4)，以M2/M3分支为基底，包含此前本地的M4/M5、审计和五项修复。最终head的CI以PR Checks为准；未合并或发布。
- 此前专项分支：`codex/test-function-verification`；51054e9记录首次六项失败，本轮已修复，原始失败证据保留。
- M4/M5 分支：`codex/m4-m5-desktop-components`，基于 M2/M3 的 `d0a1954`。此前单独交付授权待确认；现已按用户最新指令纳入统一修复PR，不另开重复PR，最新验证见 [testing.md](testing.md)。
- M2/M3 分支：`codex/m2-theme-density`，基于 M1 的 `17126f0`；实现提交 `e234943`。[草稿 PR #3](https://github.com/surface-user/Flutter_liquid_glass/pull/3) 以 `codex/m0-m1-modularization` 为基底，保留原 PR 与审查状态。
- 此前自动审批拒绝推送；用户在 2026-11-11 明确批准将该分支推送至 `https://github.com/surface-user/Flutter_liquid_glass.git` 并创建草稿 PR，授权阻塞已解除。未合并、未发布。
- M2/M3 本地根 86/86、example 8/8、格式/分析、旧/新 Golden、Web release 和发布预检 0 warnings 通过；远程精确结果以 PR #3 当前提交的 Checks 为准。非作者审查与必要实窗验收仍未完成，保持 REVIEW。

- 分支：`codex/m0-m1-modularization`；实现提交 `c8817c0`。
- [草稿 PR #2](https://github.com/surface-user/Flutter_liquid_glass/pull/2) 以 `codex/phase1-glass-interaction` 为基底，依赖未合并的 [PR #1](https://github.com/surface-user/Flutter_liquid_glass/pull/1)，本 PR 仅展示 M0/M1 差异。
- 本地格式/分析、根 66/66、example 8/8、公开签名 20/20、Web release、发布预检 0 warnings、文档链接与原失败图片保全均通过。
- GitHub Actions 在 PR 上执行静态/行为、Windows 视觉、标题与依赖审查；精确结果以 PR 当前提交的 Checks 为准，不能用旧提交通过覆盖新提交。
- 非作者批准、Windows 实窗、Android 设备与性能仍未完成；M1 保持 REVIEW。没有合并或发布。

## 精简完成索引

- 旧交互/指针高光、GLASS-001、历史视觉失败、远程授权及验证记录一次归档到 [interaction-history.md](interaction-history.md)，原始版本仍可从 Git `8504ca7:doc/TASK.md` 追溯。归档保留记录，不作为当前通过证明。
- 当前盘点：[api.md](api.md)、[component-catalog.md](component-catalog.md)、[architecture.md](architecture.md)。
- 当前验证：[testing.md](testing.md)；旧记录：[VERIFICATION.md](VERIFICATION.md)；Android：[ANDROID_PROFILE.md](ANDROID_PROFILE.md)。

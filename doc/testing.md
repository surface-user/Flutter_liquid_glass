# 当前验证与边界

## M0：2026-11-10 基线

Windows；Flutter 3.47.1 / Dart 3.13.1，与现有 CI 一致。基线提交 8504ca7，重构分支 codex/m0-m1-modularization。

| 检查 | 本次结果 | 原始日志（本地忽略产物） |
| --- | --- | --- |
| dart format --output=none --set-exit-if-changed lib test example/lib example/test example/integration_test example/test_driver | 21 文件，0 改动，通过 | build/m0-m1/baseline/format.log |
| flutter analyze | 通过，无问题 | build/m0-m1/baseline/analyze.log |
| flutter test --reporter expanded（根目录） | 62/62，通过，含全部根 Golden | build/m0-m1/baseline/root-test.log |
| cd example；flutter test --reporter expanded | 8/8，通过，含六张 gallery/dialog 比较与放大文字 | build/m0-m1/baseline/example-test.log |

重构前已存在的 example/test/failures 图片未删除；备份与 SHA256 清单保存在 build/m0-m1/baseline。它们是历史产物，不代表当前测试失败。第一次沙箱运行 Flutter 因 SDK cache/lockfile 无写权限退出；获得命令权限后复验，不能把权限失败记成产品缺陷。

## 复现命令

```sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test example/integration_test example/test_driver
flutter analyze
flutter test --reporter expanded
cd example
flutter test --reporter expanded
```

本机工具需要写项目之外的 Flutter SDK 缓存；必要时使用已批准的 SDK 命令权限。命令串行执行，避免 SDK 启动锁争用。CI 必须显式包含新增架构/公开入口测试，不能仅依赖本地全量运行。

## 验证边界

- M0 格式、分析、自动化与现有 Golden 基线已通过；不代表 M1 已通过。
- 结构重构不改变 Golden、不放宽容差；M1 对同一组图片做精确比较。
- 未运行新的 Windows 实窗验收、浏览器交互、Android 真机/模拟器，也未构建完整 Android APK。
- Android 旧任务保留，采样入口及条件见 [ANDROID_PROFILE.md](ANDROID_PROFILE.md)。Web 构建、组件测试或模拟器不能替代硬件性能。
- 非作者审查、远程 CI、合并和发布分别记录；不从历史 PR 通过推断本分支通过。
- 旧验证时间线见 [VERIFICATION.md](VERIFICATION.md)、[interaction-history.md](interaction-history.md)。

## M1：结构重组复验

| 检查 | 本次结果 | 原始日志 |
| --- | --- | --- |
| 格式与 flutter analyze | 通过，无问题；新增测试一处 const 提示已修正 | build/m0-m1/final/format.log、analyze.log |
| 原 API 源码签名对照 | 20/20 声明的构造参数、默认值、字段、方法签名与枚举值保持 | build/m0-m1/final/api-check.log、api-signatures.json |
| 架构与公开入口专项 | 4/4 通过 | build/m0-m1/final/contracts.log |
| 根目录全量测试 | 66/66 通过，原 62 项与新增 4 项，含全部 Golden | build/m0-m1/final/root-test.log |
| const 修正后公开消费复验 | 1/1 通过 | build/m0-m1/final/public-api.log |
| example 全量测试 | 8/8 通过，六张原有 Golden 精确比较 | build/m0-m1/final/example-test.log |
| Web release 构建 | 通过；Wasm dry run 成功；仍有 CupertinoIcons 字体族提示，无新增图标或依赖 | build/m0-m1/final/web-build.log |
| flutter pub publish --dry-run | 133 KB，0 warnings，未上传/发布 | build/m0-m1/final/publish-dry-run.log |
| 文档与原产物 | 相对链接解析、Git diff 检查通过；原 8 张失败图片 SHA256 不变 | build/m0-m1/baseline/pre-existing-failures.sha256.json |

API 对照使用 SDK 已安装的 analyzer 解析重构前备份与当前源码，校验公开签名，不修改项目依赖；首次临时比对脚本的 token 遍历报错，改用 AST 声明属性后完成对照。该工具错误与产品测试失败分开记录。

本轮没有修改 test/goldens 或 example/test/goldens，没有放宽比较容差；原有黑盒事件与断言保留。只增加架构与公开消费测试，不新增 Example 功能。最终远程 CI/审查状态见 [task.md](task.md)。

## M2/M3：2026-11-11 主题与现有组件

环境仍为 Windows、Flutter 3.47.1 / Dart 3.13.1；基线提交 17126f0，分支 codex/m2-theme-density。

| 检查 | 当前结果 | 原始日志（本地忽略产物） |
| --- | --- | --- |
| 开始前根测试 | 66/66 通过 | build/m2/baseline/root-test.log |
| 格式 | 39 文件、0 改动，通过 | build/m2/format.log |
| flutter analyze | 无问题，通过 | build/m2/analyze.log |
| 完整根测试 | 86/86 通过：原 66 项、新增主题 13 项、组件契约 5 项、设计 Golden 2 项 | build/m2/root-test.log |
| 原视觉基准 | 根原 9 张和 example 原 6 张均未修改；精确比较通过 | 同上及 example-test.log |
| 新增视觉基准 | design-light/design-dark 已逐张目检（Agent），暗色局部文字对比度调整后重新生成，并普通测试比较通过 | build/m2/design-render-retest.log、test/goldens/design-*.png |
| example 测试 | 8/8 通过；最终配置代码再次复核 | build/m2/example-test.log |
| Web release | 构建通过；最终配置代码再次复核，以最终日志/CI 为准；已有 CupertinoIcons 提示保留 | build/m2/web-build.log |
| 发布预检 | 144 KB，0 warnings，未发布 | build/m2/publish-dry-run.log |

保留的失败记录：

- 首次主题测试揭示 nullable 数字参数的 int/double cast、SDK ButtonStyle.merge 覆盖顺序和高对比度禁用文字的旧视觉差异。均已修正；未修改原 Golden。密度切换用例同时修正为等待 MaterialApp 主题动画结束，断言尺寸不变。
- 新 Golden 夹具最初未在测试函数结束前恢复绘制调试变量，现按旧夹具模式清理；不是产品渲染失败。
- 透明覆盖层回归首次对比 Color 与 MaterialColor 的浮点相等失败；改为比较实际 ARGB32 渲染色值，透明度断言保留。首次日志 root-before-overlay-fix.log 保留。
- 早期格式/分析错误修复后复验；没有删除、跳过或降低原失败测试。

M2/M3 自动化验证了字段/状态继承、显式覆盖/清空、密度与目标尺寸、实际过滤 sigma、动态主题/减少动画、Esc/焦点恢复、外部 FocusNode 复用和 2x 中英文文字。Windows 实窗、Android 真机/模拟器与硬件性能未执行；它们与非作者审查分别列为待验，不以 86 项通过替代。

远程边界：此前 M2/M3 分支推送被自动审批拒绝，未绕过拦截；用户在 2026-11-11 明确授权将该分支推送至 surface-user/Flutter_liquid_glass 并创建草稿 PR 后，已完成推送并创建 [PR #3](https://github.com/surface-user/Flutter_liquid_glass/pull/3)。远程 CI 精确结果以 PR 当前提交的 Checks 为准；非作者审查和设备验收仍未完成。

## M4/M5：2026-11-11 桌面能力与交付

分支 codex/m4-m5-desktop-components，基于 d0a1954；Flutter 3.47.1 / Dart 3.13.1。仅新增公开桌面组件和测试消费者，example/lib 不变。

| 检查 | 本次结果 | 原始日志（本地忽略产物） |
| --- | --- | --- |
| 格式 / 分析 | 51 文件、0 改动；无分析问题 | build/m4-m5/format.log、analyze.log |
| 完整根测试 | 114/114：原 86 项 + 桌面行为 26 项 + 视觉 2 项 | build/m4-m5/root-test.log |
| example 全量 | 8/8，原六张视觉比较通过 | build/m4-m5/example-test.log |
| 新视觉 | 四张 desktop / desktop-menu 深浅图逐张目检（Agent），普通全量测试再次精确比较通过 | test/goldens/desktop-*.png、desktop-menu-*.png |
| 原生 Windows 自动化 | 最终 C++ Debug 宿主构建，公开消费者输入/导航/菜单弹窗/Esc/Tab 关闭 1/1 | build/m4-m5/windows-native-final.log |
| Windows profile | C++ Profile 宿主构建，四模式完整采样通过；详见下表 | build/m4-m5/windows-profile-final.log 及 windows-profile-final/integration_response_data.json |
| Android profile Dart 编译 | kernel_snapshot_program 通过，未构建 APK；PowerShell 参数须完整加引号 | build/m4-m5/android-kernel.log（未加引号的首次失败）及 android-kernel-result.txt |
| Web release | 原示例构建与 Wasm dry run 通过；保留已有 CupertinoIcons 提示 | build/m4-m5/web-build.log |
| 发布预检 | 同 SDK、同参数直接调用 Dart pub（FLUTTER_ROOT 指向本机 SDK）通过，153 KB、0 warnings；未发布。Windows Flutter 转发层运行时分析器异常退出，远程 CI 标准命令待验证 | build/m4-m5/pub-forward-args-trace.log、publish-dry-run-wrapper.log |
| 文档 / 兼容 | 19 个 Markdown、102 个相对链接目标；README 桌面示例静态分析、库存清单与 Git diff 检查通过；旧图片与 example/lib 未改 | build/m4-m5/docs-check.log、readme-smoke.log |

组件矩阵覆盖深浅 × 标准/紧凑 × 普通/无模糊/减少动画/高对比度的 16 个风险组合；另验 320px 窄窗口、2x 中英文、RTL/LTR 树缩进、输入组合/选择/模拟剪贴板、隐式草稿、只读/禁用、外部所有权、菜单关闭次数/边界/焦点、SDK 加载结束后无 ticker。旧视觉图及原断言未修改。

失败保留：首次剪贴板测试等待真实平台通道，改为受控测试剪贴板后完成；平台/绘制调试变量改为测试函数结束前复原。新视觉初次暴露 SDK 按钮缺少完整字体角色继承，修正共享样式并增加回归；树行改用起始对齐并验证双向缩进。首次 Windows profile 在 SDK 测试键盘逻辑转物理键映射处失败，显式提供 physicalKey 后全程复验；windows-profile.log 保留该失败。均未通过删除/跳过测试或更新旧图规避。

标准 `flutter pub publish --dry-run` 在本机两种启动入口都返回 65，子进程只报告 `Please report this at dartbug.com.`，未给出源码诊断。以相同 `FLUTTER_ROOT`、`PUB_ENVIRONMENT=flutter_cli:forward` 执行 `dart pub --suppress-analytics --verbose publish --dry-run`，`dart analyze .\lib .\pubspec.yaml` 子进程退出 0，包清单确认测试夹具、旧失败图片与采样日志均排除。未修改 CI 命令或弱化发布检查。

### Windows 实际引擎采样

运行命令（example 目录，测试专用夹具）：

```sh
flutter drive --profile -d windows --driver=test_driver/performance.dart --target=integration_test/desktop_performance_test.dart
```

系统报告 Windows 10 Home China 10.0 Build 26200（Flutter doctor 识别为 Windows 11）；SDK display.refreshRate=200Hz，帧预算 5ms。GPU/渲染后端未独立确认。每模式预热 2s、空闲 10s、交互约 30–32s，最近秩百分位；交互重复导航、弹窗与菜单的打开/Esc 关闭。样本由真实 FrameTiming 回调采集，包含引擎批量报告；无重复运行统计或重构前同负载对照，不能推断因果提速、稳定 FPS 或应用最大负载表现。

| 模式 | 空闲新帧 | 交互帧数 | build p95 ms | raster p95 / max ms | 超 5ms 帧数 |
| --- | --- | --- | --- | --- | --- |
| default | 0 | 6315 | 1.983 | 3.048 / 19.710 | 32 |
| no_blur | 0 | 6277 | 2.155 | 2.895 / 16.403 | 19 |
| high_contrast | 0 | 6247 | 2.187 | 2.296 / 4.033 | 0 |
| reduce_motion | 0 | 6053 | 1.951 | 3.146 / 13.587 | 44 |

空闲百分位为 null（没有帧），不是 0ms。超预算按 max(build,raster) 计；减少动画不会取消 SDK 焦点/菜单绘制或测试动作本身请求的帧。没有设定产品帧阈值，因此只记录数据和空闲边界通过，仍有长尾帧。SDK 提示 integration_test 原生插件未检测到；Windows 此次通过 VM driver 返回完整 result=true、failureDetails=[] 与四模式原始数组，JSON 已落盘，未把提示当作 Android 原生插件已校准。

原始 JSON SHA256：`92C41D1F2CC7F68625319A2319B2DF2D8097A7AFB346E1EF8ABC7A993BB3BED2`。原始数据保留在上述 build 路径，不放入发布包。

### 尚待验收

Windows 实窗：`flutter run --profile -d windows -t integration_test/fixtures/desktop_consumer.dart`（example 目录）启动成功，渲染日志报告 Impeller / OpenGLES；computer-use 应用授权超时，未执行人工键鼠、物理中文 IME 或剪贴板。复验时聚焦 Search / draft，输入拼音并检查 Composition 范围、候选与提交、选区粘贴；再用 Tab/Enter 打开 Actions、Esc 关闭检查焦点，缩窄窗口检查浮层边界。组件注入的 composing 与 native enterText 不能替代物理 IME。

用户确认本轮无 Android 真机，完整 APK、Android/其他平台运行与性能、非作者审查仍待完成。StudyWorkbench 接入清单是库侧交付，不表示对该应用的修改或验收。

## 2026-11-11：独立逐函数验证

按用户要求新增三个子代理，基于 9e4daef，分支 codex/test-function-verification。AST 盘点 lib/ 的 103 个具名 callable，分成 core/theme 34、渲染/交互 46、桌面/浮层 23；三个代理均独立审查对应调用方与既有断言，并编写和实际运行测试。全清单、语义证据及未验边界见 [function-verification.md](function-verification.md)。

| 检查 | 最终结果 | 日志（本地忽略产物 build/function-audit/） |
| --- | --- | --- |
| 原根基线 | 114/114，通过，含原视觉 | baseline-root.log、baseline-lcov.info |
| 新增 core | 10 项：9 通过/1 失败 | core-retest.log、core-final-lcov.info |
| 新增渲染/交互 | 9 项通过；与原63项组合72/72 | rendering-test.log、rendering-lcov.info |
| 新增桌面/浮层 | 12 项：7 通过/5 失败；同轮原32项全部通过 | desktop-retest.log、desktop-final-lcov.info |
| 最终全量根 | 145 项：139 通过/6 失败；原114项仍通过，失败全部来自新增正确预期回归 | final-root.log、final-lcov.info |
| Windows 原生专项 | C++ Debug 宿主构建；直接运行同31项新增用例，25通过/6失败，复现同五类缺陷 | windows-native-final.log |
| 原 example | 8/8，通过，六张原图精确比较 | example-test.log |
| 格式 / 分析 | 55 文件0改动；flutter analyze 无问题 | format-final.log、analyze-final.log |

六项失败对应 [task.md](task.md) 的五类 OPEN 缺陷：高对比度 Paint 深/浅两项、继承全局白字、selected shape、Dialog 最大宽度和菜单动态 FocusNode。没有修改生产代码、放宽产品预期、跳过失败或更新原 Golden；CI 已显式包含三个新增根文件，因此缺陷修复前不能把本分支检查标成全通过。

Windows 原生入口为 example/integration_test/function_audit_test.dart；在 example 运行 `flutter test integration_test/function_audit_test.dart -d windows --reporter expanded`。它直接调用三个根专项测试的 main，复用已有宿主，example/lib 不变。结果与前一轮较小的 native consumer 1/1 分开：此前通过不覆盖这次新发现的边界。

夹具与产品失败分开保留：core 首轮取错 padding 层、外层 DefaultTextStyle 被 Material 重置，改测真实几何和全局 Material bodyMedium 实际对比度；渲染首轮错误地包含 SDK painter，之后 PictureRecorder 被重复创建 Canvas，均已修正。Windows 原生首轮转场值约0.4987，与VM精确假时钟0.5不同；改用实际中段进度验证相同曲线，曲线误差断言仍为0.001，复跑后仅保留六项真实失败。首次日志分别保存在 core-first.log、rendering-test-initial.log、rendering-test-canvas-fixture.log、windows-native-audit.log。首次分析的一处 const 提示已修正并完整复验。

覆盖复核：_SurfaceScope.updateShouldNotify 的入口计数在 @override 所在的184行，185行恒false表达式没有独立记录，不能据此判为函数未执行。R05另验外层表面只变着色时，稳定嵌套child不重建且过滤保持隔离；初次夹具未等待前一主题的性能限制过渡结束，修正后通过，保留 notify-test-initial.log / notify-test.log。const构造器可能在编译期构造，不能要求其运行期入口计数。逐项检查仍不等于穷尽所有输入。

物理 Windows IME、剪贴板、屏幕阅读器、Release 无断言、Android/其他平台和真实 GPU 延迟仍不在此轮通过范围。本轮未重新跑 Web/发布预检，未推送、创建新 PR、合并或发布。

## 2026-11-11：五个子Agent修复与主Agent验收

修复基线51054e9、分支codex/fix-five-contract-bugs。按用户调度规范共创建五个修复子Agent，每个负责一类bug；平台上限为三个并发子Agent，分两批。BUG01和BUG04共享主题文件，前者REVIEW释放文件后才解除后者BLOCKED；其余文件独立并行。主Agent最终检查代码与验收结果，再将五项置DONE；原审计失败保留，不将历史记录抹成全通过。

| 验证 | 本次结果 | 原始日志（本地忽略路径 build/five-bug-fixes/） |
| --- | --- | --- |
| 格式/分析 | 60文件0改动，flutter analyze无问题 | format.log、analyze.log |
| 根全量 | 167/167：原145项及新增22项修复边界；原六项失败已通过 | root-test.log、lcov.info |
| Windows原生 | C++ Debug宿主构建，原专项31项+新修复22项共53/53 | windows-native.log |
| example | 8/8，原六张视觉比较通过 | example-test.log |
| 所有旧视觉 | 根/示例基准未修改、未更新容差，精确比较通过 | root-test.log、example-test.log |
| Web release | 原示例与Wasm dry run通过；保留已有CupertinoIcons字体提示 | web-build.log |
| Android采样Dart入口 | kernel_snapshot_program退出0；未构建APK或测设备 | android-kernel.txt |

修复边界：新建纯色Paint保留排版且不变异外部对象；颜色回读按精确ARGB32比较以区分float32/64表示。继承文字按实际正文/标题角色与不透明HC底判断可读性，保留可读旧默认，统一色空间，深浅/系统/主题/透明/Shader均有用例。选中状态补齐SDK shape/icon/size/elevation/cursor等原透传属性；Dialog外层/内层约束协调；菜单保持打开并迁移触发器焦点，已有菜单项焦点保留，关闭恢复当前节点，空项/禁用/卸载与回调次数验证通过。

子Agent最初日志与主Agent统一结果分开：bug01日志保留浅色Paint精度假失败，目标色未改；bug05-initial保留首次夹具single定位和补充关闭恢复缺口。所有最终修复都经过原失败用例与新增用例，不跳过原断言。当前具名callable104（新增一个局部selectedProperty），公开声明26不变；清单/源码行号已更新。

剩余边界：物理IME/剪贴板/屏幕阅读器、Android真机及完整APK、其他平台设备、非作者审查仍未完成；不得用上述自动化替代。统一PR及当前head的CI结果另记，未自动合并、未发布包。

# P0 实验台任务与调度账本

日期：2026-11-14。主 Agent：当前对话；子 Agent：A（组件与普通模式）、B（弹窗）、C（运行与动效）。

依据：[差距分析](D:/computer_work/project/Flutter_liquid_glass/deployment/docs/liquid-glass-vs-m3e-canvas-gap-analysis.md)、[deployment 规范](D:/computer_work/project/Flutter_liquid_glass/deployment/agent.md)、[组件参考手册](D:/computer_work/project/Flutter_liquid_glass/doc/component-lab-reference.md)。用户已批准 P0 实现、3子 Agent 并行、每项任务独立 PR。

## 范围与状态规则

- 本轮只实施 P0-A/B/C 和最终 P0-V 验证；P1/P2留在下方未授权批次，不因本轮要求“全部DONE”擅自实现。
- 所有代码、分支工作目录、文档、截图与构建产物仅位于 `deployment/`。不改根 lib/test/example、组件库快照、依赖或原有失败证据。
- 普通模式不展示 Flutter 类型、builder/controller/FocusNode、递归原始参数和 JSON 编辑；高级模式保留原有22种类型、参数和旧复杂结构。
- 不清空旧布局，不以简化表单覆盖未识别的高级内容。运行草稿与设计初值分离，动态减少动画、高对比度、过滤隔离与无闲置ticker契约保留。
- READY → IN_PROGRESS → REVIEW → DONE。子 Agent 更新自己行的状态与证据；主 Agent 独立检查后才置 DONE，失败退回 IN_PROGRESS。依赖未满足为 BLOCKED，并明确原因。
- 实现/本地验收/PR交付/CI/部署分别记录。DONE要求本项实现、主Agent验收及独立PR交付；PR/远程连接失败保留 REVIEW并记录交付阻塞，不虚报。
- 每次开始执行先读本文件并检查未完成依赖。Flutter 命令由主 Agent 串行运行；子 Agent 不同时启动 Flutter。共享 main.dart 的集成由主 Agent负责。

## 当前批次与依赖

| 编号 | 所有者 | 状态 | 依赖 | 任务与退出条件 | 验证/PR |
| --- | --- | --- | --- | --- | --- |
| P0-A | 子A + 主集成 | DONE | 无；共同接口约定见下 | 用途分类、普通/高级模式、卡片默认静态；普通属性直接改常用内容/外观/动作；高级项明确提示且可访问，不丢旧结构；基础与窄屏入口均能真实操作 | 14项专项及拆分分支分析通过；普通矩阵首轮通过；[PR #6](https://github.com/surface-user/Flutter_liquid_glass/pull/6)已交付，CI/非作者审查另列 |
| P0-B | 子B + 主集成 | DONE | 无；共同接口约定见下 | 说明/确认弹窗直编：入口形式与文案、标题正文、按钮条目、返回结果、大小/外观、真实试用；支持文字/按钮/图标入口；自定义内容明确进高级模式且不丢失；不开放未做好的多行/密码表单 | 19项专项与拆分分支分析通过；[PR #7](https://github.com/surface-user/Flutter_liquid_glass/pull/7)已交付，CI/非作者审查另列 |
| P0-C | 子C + 主集成 | DONE | 无；共同接口约定见下 | 独立运行/重置、不污染设计初值；按压/材质/弹窗或页面动效清楚试用、预设与重播；正常/减少动画均可观察，退出后无持续ticker | 8项专项及全量125项通过；[PR #8](https://github.com/surface-user/Flutter_liquid_glass/pull/8)已交付，CI/非作者审查另列 |
| P0-V | 主Agent（子Agent交叉复核） | DONE | P0-A/B/C均已进入REVIEW；最终DONE要求各项通过 | 接线完整、逐项功能/旧布局/中文排版回归、正式Web构建、截图目检与浏览器操作；记录限制并提交独立验证PR | 125/125、格式/分析、Web构建、540视图、Edge与ZIP一致性通过；[PR #9](https://github.com/surface-user/Flutter_liquid_glass/pull/9)已交付；原站点第3版发布成功，CI/人工审查另列 |

## 并行文件所有权与接线契约

工作应用：`deployment/component-lab-site/app`，已有本地基线 `82e241b5ac2133aa7db99a0b19a30a83fca04957`。三个子 Agent 共用文件系统，禁止重置/回退其他人的修改，禁止擅自提交别人的文件。

- A：新增 `lib/editor_catalog.dart`、`lib/basic_inspector.dart`、`test/p0_catalog_test.dart`。不改 main.dart/registry.dart/schema.dart。提供用途分类与普通表单 Widget；仅通过回调提交布局，需保留未编辑字段。入口弹窗统一映射 showGlassDialog，底层表面/主题/分组/路由不出现在普通目录或类型下拉。普通组件名采用用户用途名称。
- B：新增 `lib/dialog_editor.dart`、`test/p0_dialog_test.dart`；负责必要的 `registry.dart`/`schema.dart` 小改动，仅用于真实入口样式/结果，不改库快照。提供 `DialogEditor`，入参当前完整模块 `Json module`、`String? Function(Json) onApply`、可选 `ValueChanged<String> onEvent`；模块替换仍由主Agent校验/历史/保存。支持识别 showGlassDialog、GlassDialog及按钮 dialog 动作；不能表达的自定义内容只读说明并提供高级入口回调。公开构造参数尽快与主Agent同步。
- C：新增 `lib/motion_tryout.dart`、`lib/workbench_preview.dart`、`test/p0_motion_test.dart`。不改 main/registry/schema。提供 `MotionTryout`（当前 theme Json、通过回调提交 motion），`WorkbenchPreview`（传入克隆 scene，自有 Runtime、重置/退出/返回）。效果遵循现有库限制，销毁运行时资源，禁止以复制标签/假动画冒充真实控件。
- 主：main.dart 的模式、普通目录/属性面板、弹窗与动效接线；build.ps1/README/验收记录；必要跨任务修复。若需改别人所有文件，先消息协商，不同时写同一文件。
- 子 Agent提交前报告具体文件/回调签名/测试入口；测试由主Agent排队执行，主Agent负责独立PR。子 Agent可以阅读整个相关实现，但不得修改分配之外文件。

## 验收矩阵

| 分组 | 必验内容 |
| --- | --- |
| A 分类/模式 | 普通目录无底层项/原始类型；高级22项仍可用；旧复杂节点切换模式不丢失；普通常用参数、添加、复制删除、撤销重做；中文与窄屏模式切换 |
| B 弹窗 | 说明/确认、标题可空、长正文、按钮/图标/文字入口；真实点击、遮罩/Esc/按钮关闭、返回值区分、重复打开、编辑后重开、焦点恢复；自定义内容安全保留 |
| C 动效/运行 | 真按压反馈、材质前后切换、真浮层/路由；预设/重播；减少动画动态改变；重置临时文本/变量；退出不改设计JSON、不泄漏控制器/ticker |
| V 排版/兼容 | 320/390/820/1180/1500宽 × 100/130/200%字体；短窗口与浮层；原有宽高/类型/资源生命周期测试保持；截图实际查看；正式浏览器尺寸/输入/弹窗/返回核对 |
| V 构建/边界 | 格式、flutter analyze、完整app测试、build.ps1；下载源码一致性；根库和快照内容不变；既有失败产物保留；物理IME/真机与未验浏览器单列 |

## PR与工作目录

现有 Sites 源码是 deployment 内的独立Git仓库，没有 GitHub PR remote；外层 GitHub 仓库忽略 deployment。主Agent将先核对远程与权限，准备 deployment 内的隔离审查目录，把本轮必要源码显式纳入 GitHub 评审路径。不得上传 `.git`、缓存、旧artifacts、凭据、压缩发布包或无关外层文件；每项任务单独分支/PR，按实际依赖选择base。

PR是交付评审，不自动合并。CI、非作者审查与线上发布另列；出现真实外部阻塞则记录具体操作/错误并继续可推进任务。旧 Sites 发布认证问题需本轮重新核对，不能依据历史失败直接虚报本轮无法发布。

## 后续批次（未授权实施）

| 批次 | 状态 | 内容 |
| --- | --- | --- |
| P1-A | 未排期 | 真实表单需求决定输入/选择的库接口及网站接入；本轮不得修改源库 |
| P1-B | 未排期 | 显式页面/图层/目标、工程与当前设计代码交付 |
| P2 | 未排期 | 经需求确认的方向/协同动效、Popover、底部面板等 |

## 调度与验证记录

- 初始化：只读核对根/独立站点仓库；根已有未跟踪 `doc/component-lab-reference.md`、`example/test/failures/`、`test/failures/`，保留。站点基线工作区干净。3个无实现依赖的P0任务可并行，最终验证等待集成。
- 审查基础：`deployment/p0-review/repository` 为隔离Git目录，现有实验台基线和账本已提交 [草稿PR #5](https://github.com/surface-user/Flutter_liquid_glass/pull/5)，base为原库修复PR #4的当前分支；后续P0各任务独立PR，不自动合并。当前源库工作分支未切换，PR新增路径均在deployment。
- Sites连接重核：原项目ID保持不变，本轮返回可用的短期认证并已成功打开原源码基线；当前服务返回站点公开受众，保持现状，不擅自变更分享权限。历史认证失败不能作为本轮结论。
- PR基础检查首次失败：根CI扫描独立app但未为app解析依赖，出现168项包引用错误，非组件库回归。仅在deployment增加分析边界，app自带原有检查规则；隔离目录实测根分析0问题，app分析0问题，临时undefined探针确实报错后已移除，未禁用app检查。修正已推送PR #5，等待新CI。
- 第一轮完整回归120通过/1失败（新增入口button漏中文映射），已补映射。首轮截图另发现大字体下拉文字裁切，A/B/C分别退回修正、加入实际文字边界断言；不以“无溢出异常”代替可读性验收。旧失败日志均保留。

- PR发布检查边界：PR #5新检查的根分析、库与示例测试、Android profile Dart编译、示例Web构建、视觉回归均通过；最后pub dry-run因根gitignore仍忽略已纳入PR的deployment文件退出65。deployment内pubignore实测无效并已移除；不改根配置，不绕过失败CI、不合并。网页本地验收与Sites发布和库包发布分别记录。

- 最终串行回归125/125通过，格式/静态分析通过；普通210与高级330视图矩阵完成，64个保护文件哈希保持一致。第一次集成点试用按钮时输入光标滚动尚未稳定导致未命中，保留日志；修正测试等待实际布局并断言hitTestable，完整重跑通过，未改产品逻辑或降低断言。

- P0-V主验收通过：正式构建、Edge中文正文/弹窗Esc/运行输入重置/菜单/动效路由返回/390宽属性均通过；下载ZIP54文件一致。2026-11-14原站点第3版已发布成功，权限保持，详见[p0-verification.md](p0-verification.md)。等待本项独立PR交付，不把CI库包发布门槛冒充通过。

- P0-V独立[PR #9](https://github.com/surface-user/Flutter_liquid_glass/pull/9)已交付，P0-A/B/C/V均DONE（按上方本地验收+PR定义），P1/P2未授权不推进。所有PR仍为草稿、未合并；#6/#7/#8精确head已核实仅库包发布检查失败，其余根CI步骤通过，#9最终head检查单独观察。

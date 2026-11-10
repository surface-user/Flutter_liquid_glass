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

API 对照使用 SDK 已安装的 analyzer 解析重构前备份与当前源码，校验公开签名，不修改项目依赖；首次临时比对脚本的 token 遍历报错，改用 AST 声明属性后完成对照。该工具错误与产品测试失败分开记录。

本轮没有修改 test/goldens 或 example/test/goldens，没有放宽比较容差；原有黑盒事件与断言保留。只增加架构与公开消费测试，不新增 Example 功能。最终远程 CI/审查状态见 [task.md](task.md)。

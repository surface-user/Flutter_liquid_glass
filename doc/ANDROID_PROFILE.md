# Android profile 验收

状态：待目标设备；截至 2026-10-29 尚无实测数据，不得以 widget 测试或桌面帧时间替代。

## 运行

在 example 目录执行（device-id 用 flutter devices 列出的 Android ID）：

```sh
flutter devices
flutter run --profile -d <device-id>
```

连接真机、开启 USB 调试并授权后运行。若构建仍出现历史 NDK source.properties 缺失错误，先记录并修复 Android 构建环境；不要删除全局 SDK 或自动安装模拟器来冒充真机。

## 采样

1. 记录设备型号、Android 版本、刷新率、Flutter/引擎版本、渲染后端和启用的玻璃质量配置。
2. 打开此次运行的 DevTools Performance，预热示例。固定页面位置，停止滚动和所有输入，等待按钮墨水与提示消失后，记录 10 秒空闲轨迹。
3. 另录 30 秒交互轨迹，重复按钮按压/释放、移出取消、图标按钮及可点击卡片。触屏不模拟 hover；有物理键盘时另测 Tab/Enter/Space。
4. 分别记录默认、关闭模糊、高对比度、Reduce motion。减少动画时检查无缩放/位移，键盘焦点边缘仍可见；复现 GLASS-001 的四种开关切换由保留的黑盒测试覆盖，真机另验示例 Reduce motion。
5. 导出每段轨迹，记录 UI/build 与 raster 帧时间的 p50/p95/最大值、采样帧数和超出设备帧预算的帧数。帧预算为 1000 / 刷新率 ms。空闲不强制生成帧；没有帧时写无新帧，不填写虚构的 0ms 百分位。
6. 按压释放后不得持续请求交互帧；检查文字、裁剪和降级可读性。将实际结果、轨迹路径及限制附到 task.md，再决定是否满足性能验收；没有预设或实测阈值时不宣称稳定 FPS。

## 待填写结果

| 项目 | 当前证据 |
| --- | --- |
| 设备/刷新率/后端 | 未采集 |
| 空闲轨迹 | 未采集 |
| 默认交互帧时间与超预算帧 | 未采集 |
| 降级及减少动画 | widget 回归通过，Android 待验证 |
| 性能验收 | 未完成 |

## 自动采样入口（2026-11-10）

示例增加了 Flutter SDK 自带的 integration_test 开发依赖，库运行时依赖不变。在 example 目录执行：

```sh
flutter pub get
flutter drive --profile -d <device-id> --driver=test_driver/performance.dart --target=integration_test/glass_performance_test.dart
```

入口只接受 Android profile 模式，使用 fullyLive 引擎帧策略；默认、关闭模糊、高对比度、减少动画分别采集 10 秒空闲和约 30 秒交互，约需 3 分钟。交互使用固定三组件夹具（GlassButton、GlassIconButton、可点击 GlassCard），不等同于整个 Gallery 的最大负载测试。每轮先预热并等待引擎批量帧报告排空；空闲观察不 pump，不人为生成帧。

默认报告为 `example/build/integration_response_data.json`（设置 FLUTTER_TEST_OUTPUTS_DIR 时位于该目录），包含系统信息、屏幕刷新率、采样时长、原始 UI/build 与 raster 毫秒数组、nearest-rank p50/p95/最大值及超预算计数。`frames_over_budget` 按同一帧 build 或 raster 任一超预算计一次，`>` 而非 `>=`；不把流水线两阶段耗时相加冒充逐帧延迟。空闲没有新帧时 count=0、百分位=null。交互无样本或交互 ticker 未停止时测试失败；失败报告会尽可能保存，失败数据不作为验收通过依据。

报告不会猜测设备型号、引擎版本或后端，请在同一终端保存 `flutter --version`、`flutter devices`，并记录目标设备型号和启动日志中的渲染后端。若设置了 FLUTTER_TEST_OUTPUTS_DIR，应为每个设备/运行单独指定目录，避免覆盖证据。自动夹具不能替代上述真实页面、文字裁剪、触摸及减少动画验收。

本地可运行 `flutter test test/frame_metrics_test.dart` 校验统计逻辑；此命令的合成数据只是单测输入，不是真机性能。Android bundle 编译成功也不代表 APK 构建成功或已运行真机。

### 当前编译与本地验证

2026-11-10：统计单测及示例共 7 项、根 55 项、格式和分析通过。profile 资源打包与单独 kernel_snapshot_program 编译通过。CI 同样编译 Android profile Dart 入口，但不会运行真机采样；这些结果不能完成上方性能验收表。

## Android Studio 模拟器功能验证

用户安排实现完成后统一设备验证。届时在 Android Studio Device Manager 创建并启动 AVD，用 flutter devices 确认 ID，在 example 目录执行：

```sh
flutter test integration_test/gallery_test.dart -d <emulator-id>
```

入口复用本地 Gallery 测试，覆盖主题切换、减少动画、对话框和页面往返。它可在 debug 模拟器运行，不测硬件帧率。尚未安装或启动 AVD；如受 NDK 缺失阻塞，需先修复 Android 构建环境。

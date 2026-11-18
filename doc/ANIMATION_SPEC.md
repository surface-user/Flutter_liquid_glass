# 通用 UI 与玻璃动效规格

本页是后续实现/验收规范。main 的表面/路由/可选背景动画已存在，按压缩放、指针高光、主题交互时长等在 #4；不因本页建议参数认定主线已实现。版本边界见 [README.md](README.md)。

## 状态优先级

`disabled > pressed > focused > hovered > idle`

同一时刻只解析一个主状态，focus 边框可以与 hover / pressed 视觉叠加。触摸设备不模拟 hover。

## 玻璃交互建议参数

| 状态 | 缩放 | Y 位移 | 着色变化 | 阴影 | 时长 |
| --- | ---: | ---: | ---: | --- | ---: |
| idle | 1.0 | 0 | 0 | 主题默认 | — |
| hovered | 1.01 | 0 | +0.03 | 略增强 | 160ms |
| focused | 1.0 | 0 | +0.02 | 不变 | 120ms |
| pressed | 0.98 | 1–2px | +0.05 | 降低高度 | 90ms |
| release | 1.0 | 0 | 归零 | 恢复 | 180ms |
| disabled | 1.0 | 0 | 0 | 主题默认 | — |

数值是第一轮调试起点，不应全部公开为参数。只有真实使用场景证明需要配置时，才加入主题规范。

## 通用动画原则

- SDK 与成熟组件已有动画优先复用；第三方须遵循 [依赖准入](AGENTS.md)，验证系统偏好、隐藏/后台、打断/反向与卸载。设计台动效时间线后置。
- 交互动画优先使用 `AnimationController`、`Tween`、`Transform`、`MouseRegion`、`Focus`、`Listener`、`Material` 和 `InkWell`。
- 不修改布局约束，缩放发生在绘制阶段。
- 不动画背景模糊 sigma。
- 高频指针位置通过 `ValueNotifier` / painter repaint 传递，避免 `setState` 重建整棵子树。
- 每个控制器在动画结束后停止；dispose 必须释放控制器和监听器。
- pressed 结束后，即使指针在组件外释放，也必须恢复 idle / hovered。
- disabled 不响应指针、键盘或语义点击。

## 减少动画

减少动画时：

- 缩放和位移为 0。
- 可立即切换边框、着色和 focus 提示。
- 不启动背景位移、流光或回弹控制器。
- 无障碍 focus 指示仍然存在。

玻璃动效同时读取 Flutter 的系统减少动画与无障碍导航、平台独立的 `AccessibilityFeatures.reduceMotion`、局部或全局主题的减少动画与性能设置。任一条件要求减少动画即生效。表面过渡立即结束在目标样式。启用动画且可见的 `GlassBackdrop` 会停止位移，限制解除后可恢复。

新建玻璃路由在有源 `context` 时读取这些设置。应用运行中切换系统设置的验收需要对应平台，Widget 测试只验证 Flutter 发出信号后的行为。

## 玻璃 Shader 边界

可选折射 Shader 是后续实验，main 和 #4 均未交付；通用库首版不以此为前提。未来实现必须满足：

- 只作为 `GlassQuality.high` 的可选路径。
- 编译失败、后端不支持或运行异常时退回 `BackdropFilter`。
- shader uniform 只传尺寸、时间、指针位置和强度等必要数据。
- 不在所有卡片上启动全局时间动画。
- Android profile 数据和 Web / 非 Impeller 降级测试齐全后才公开。

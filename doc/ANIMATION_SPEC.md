# 玻璃交互动画规格

## 状态优先级

`disabled > pressed > focused > hovered > idle`

同一时刻只解析一个主状态，focus 边框可以与 hover / pressed 视觉叠加。触摸设备不模拟 hover。

## 建议参数

| 状态 | 缩放 | Y 位移 | 着色变化 | 阴影 | 时长 |
| --- | ---: | ---: | ---: | --- | ---: |
| idle | 1.0 | 0 | 0 | 主题默认 | — |
| hovered | 1.01 | 0 | +0.03 | 略增强 | 160ms |
| focused | 1.0 | 0 | +0.02 | 不变 | 120ms |
| pressed | 0.98 | 1–2px | +0.05 | 降低高度 | 90ms |
| release | 1.0 | 0 | 归零 | 恢复 | 180ms |
| disabled | 1.0 | 0 | 0 | 主题默认 | — |

数值是第一轮调试起点，不应全部公开为参数。只有真实使用场景证明需要配置时，才加入主题规范。

## 动画原则

- 交互动画使用 `AnimationController`、`Tween`、`Transform`、`MouseRegion`、`Focus`、`Listener`、`Material` 和 `InkWell`。
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

## Shader 边界

可选折射 Shader 不属于第一阶段。未来实现必须满足：

- 只作为 `GlassQuality.high` 的可选路径。
- 编译失败、后端不支持或运行异常时退回 `BackdropFilter`。
- shader uniform 只传尺寸、时间、指针位置和强度等必要数据。
- 不在所有卡片上启动全局时间动画。
- Android profile 数据和 Web / 非 Impeller 降级测试齐全后才公开。

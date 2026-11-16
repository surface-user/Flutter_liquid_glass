# 从 main 接入

本页仅使用 main `a0bc51a` 已有接口；安装与完整示例见 [根 README](../README.md)。版本/分支应固定为经审查的实际提交，不从包版本 0.1.0 推断已含 #4 增量。

## 最小应用

```dart
import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() => runApp(
  MaterialApp(
    theme: ThemeData(
      extensions: const [LiquidGlassThemeData()],
    ),
    home: Scaffold(
      body: Center(
        child: GlassButton(
          onPressed: () {},
          child: const Text('打开'),
        ),
      ),
    ),
  ),
);
```

局部配置使用现有整体替换构造；要保留父值，在 Builder/context 中先读取父配置：

```dart
Builder(
  builder: (context) {
    final parent = LiquidGlassTheme.of(context);
    return LiquidGlassTheme(
      data: parent.copyWith(accentColor: Colors.indigo),
      child: const GlassCard(child: Text('局部配置')),
    );
  },
)
```

main 的嵌套 performance/accessibility/motion 没有 copyWith；构造新对象表示完整替换，须显式保留所需字段。按钮默认至少 48px，不支持主题密度/controlStyle。玻璃是当前实现特色；普通输入、选择、布局、反馈可直接使用 SDK，不必每项包装玻璃。

## 未合并接口

LiquidGlassTheme.merge、GlassLayout、colorScheme/textTheme/controlStyle、紧凑密度和 GlassTextField/NavigationItem/Tab/Toolbar/Menu 都只存在于 #4。不要将其示例粘到当前 main；如需试验，明确锁定 [#4 ac0028e](https://github.com/surface-user/Flutter_liquid_glass/tree/ac0028eacd0e1ee22747d454c04a456dcb307377)，并记录它未合并/未完成人工设备验收的风险。

[原增量接入示例](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/getting-started.md) 保留作为该版本用法，不能当成本次代码已新增。通用 API、第三方适配和设计台仍按 [task.md](task.md) 开展；本次不安装依赖。

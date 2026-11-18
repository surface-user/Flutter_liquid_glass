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

## 独立导航条目

[#29 草稿](https://github.com/surface-user/Flutter_liquid_glass/pull/29)新增 [`NavigationItem`](api.md#独立导航条目)，可搭配普通实色表面或玻璃表面容器。合入前，从 #29 分支试用；这与 #4 中的 `GlassNavigationItem` 是两个接口。

## 原生表单示例

[表单示例源码](../example/lib/recipes/form_recipe.dart)通过 Flutter 的 `Form` 和 `TextFormField` 组合单行标题和多行备注。在 `example` 目录运行 `flutter pub get`，再用 `flutter run -d edge -t lib/recipes/form_recipe.dart` 启动；测试用 `flutter test test/form_recipe_test.dart`。该示例独立于 gallery，库未新增输入包装类型。

- 应用用 `ThemeData.inputDecorationTheme` 定义全局外观。局部用 `InputDecorationTheme.of(context).copyWith(...)` 继承未覆盖的字段；实例的 `InputDecoration` 优先。普通和玻璃表面可复用同一表单；示例用 `MaterialApp.highContrastTheme` 响应系统高对比度。
- 标题只用 `initialValue`，备注由外部 controller 持有。示例先 `validate()`，成功后用 `save()` 读取值到页面；不提交数据。错误用同步 validator 或调用方提供的 `forceErrorText`；外部错误由调用方显式清除。
- `reset()` 恢复原生字段的初始文本；不传 `resetValue`，也不依赖同一字段动态更新初值来改重置基准。外部 controller 和焦点节点仍由调用方释放。组合输入的 widget 测试不等于实机输入法验收。

## 确认弹窗示例

[确认弹窗示例源码](../example/lib/recipes/confirmation_recipe.dart)在同一个 Flutter `showDialog<bool>` 路由上，用 `AlertDialog` 提供普通外观，或用 `GlassDialog` 提供玻璃外观。在 `example` 目录执行 `flutter run -d edge -t lib/recipes/confirmation_recipe.dart`；测试执行 `flutter test test/confirmation_recipe_test.dart`。示例独立于 gallery，不新增库 API。

- 确认返回 `true`，取消按钮返回 `false`，允许的外点或 Esc 等无值关闭返回 `null`。应用只在收到 `true` 时执行确认操作。
- 默认打开在根 Navigator；嵌套场景可用 `useRootNavigator: false`。按钮用弹窗的 context 弹出对应路由。弹窗内 Tab 闭环，关闭后在原触发器仍可聚焦时恢复焦点。
- `barrierDismissible: false` 禁止外点和 Esc，动作按钮仍可关闭弹窗。减少动画时跳过弹窗路由动画。使用 `showGlassDialog` 时，可以用 `GlassMotionSpec` 分别设置进入与退出时长。

## #4 未合并接口

LiquidGlassTheme.merge、GlassLayout、colorScheme/textTheme/controlStyle、紧凑密度和 GlassTextField、GlassNavigationItem、GlassTab、GlassToolbar、GlassMenu 都只存在于 #4。不要将其示例粘到当前 main；如需试验，明确锁定 [#4 ac0028e](https://github.com/surface-user/Flutter_liquid_glass/tree/ac0028eacd0e1ee22747d454c04a456dcb307377)，并记录它未合并/未完成人工设备验收的风险。

[原增量接入示例](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/getting-started.md) 保留作为该版本用法，不能当成本次代码已新增。通用 API、第三方适配和设计台仍按 [task.md](task.md) 开展；本次不安装依赖。

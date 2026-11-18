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

## 锚定菜单示例

[菜单示例源码](../example/lib/recipes/anchored_menu_recipe.dart)使用 Flutter 的 `MenuAnchor` 和 `MenuItemButton`。应用持有命令与执行结果；菜单只负责呈现和交互。示例将触发按钮放在页面右下角，由 Flutter 在可用空间内定位菜单。在 `example` 目录运行 `flutter run -d edge -t lib/recipes/anchored_menu_recipe.dart`；测试执行 `flutter test test/anchored_menu_recipe_test.dart`。

- 示例打开时聚焦首个命令，方向键切换可用项目，Enter 执行，Esc 仅关闭；结束后回到仍存在的触发按钮。禁用项的 `onPressed` 为 `null`。
- `consumeOutsideTap: true` 消费关闭菜单的外点，不让该次点击触发后方按钮。只有菜单项的 `onPressed` 才执行命令。
- 示例始终使用 `animated: false`，包括系统减少动画时；这只关闭菜单展开和收起动画，不改变宿主其他控件的动效。窄窗与键盘行为由 widget 测试覆盖，实窗和屏幕阅读器需另验。

## 选择与开关示例

[选择示例源码](../example/lib/recipes/selection_recipe.dart)用 Flutter 原生 `CheckboxListTile`、`RadioGroup` / `RadioListTile` 和 `SwitchListTile`，由应用持有值并在回调时更新。外观跟随宿主的 `ThemeData` 颜色，包括高对比度主题。此配方独立于 gallery，不增加库接口或依赖。

- 三态复选按未勾选 → 勾选 → 混合（`null`）循环。
- 单选值由 `RadioGroup` 统一管理；用 Tab 进入组，方向键切换并跳过禁用项。禁用单选用 `enabled: false`。
- 复选和开关以 `onChanged: null` 禁用，已保存的值保持不变。

在 `example` 目录执行 `flutter run -d edge -t lib/recipes/selection_recipe.dart`，或用 `flutter test test/selection_recipe_test.dart` 验证。

## #4 未合并接口

LiquidGlassTheme.merge、GlassLayout、colorScheme/textTheme/controlStyle、紧凑密度和 GlassTextField、GlassNavigationItem、GlassTab、GlassToolbar、GlassMenu 都只存在于 #4。不要将其示例粘到当前 main；如需试验，明确锁定 [#4 ac0028e](https://github.com/surface-user/Flutter_liquid_glass/tree/ac0028eacd0e1ee22747d454c04a456dcb307377)，并记录它未合并/未完成人工设备验收的风险。

[原增量接入示例](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/doc/getting-started.md) 保留作为该版本用法，不能当成本次代码已新增。通用 API、第三方适配和设计台仍按 [task.md](task.md) 开展；本次不安装依赖。

## 说明与输入弹窗示例

[独立示例](../example/lib/recipes/dialog_recipes.dart)使用 Flutter 的 `showDialog`、`AlertDialog` 和 `Form`。在 `example` 目录运行 `flutter run -d edge -t lib/recipes/dialog_recipes.dart`，测试运行 `flutter test test/dialog_recipes_test.dart`。

- 说明弹窗使用可访问标题和滚动正文，关闭按钮保持可达。开启减少动画后，打开和关闭均跳过路由动画。
- 输入弹窗从页面当前标题初始化。原生表单拒绝空白标题，通过后返回去掉首尾空白的文字，页面才更新显示值。取消按钮显式返回取消，外点或 Esc 返回空结果，两者都丢弃草稿。
- 可用 Enter 打开输入弹窗、Tab 移动焦点、Esc 关闭。在触发器仍可聚焦时，关闭后焦点回到触发器。应用负责表单提交和持久化。

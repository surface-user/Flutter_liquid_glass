# 接入与局部配置

从 `package:lightweight_liquid_glass/lightweight_liquid_glass.dart` 导入。依赖安装方式与最小应用见 [README](../README.md)。内部 src 路径不属于公开契约。

## 注册全局主题

将 LiquidGlassThemeData 放进 ThemeData.extensions；保持两个 brightness 一致：

```dart
final glass = LiquidGlassThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ),
);
final material = ThemeData(
  brightness: Brightness.dark,
  extensions: [glass],
);
```

## 保留父配置的局部覆盖

```dart
LiquidGlassTheme.merge(
  data: (parent) => parent.copyWith(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    layout: parent.layout.copyWith(iconSize: 18),
    performance: parent.performance.copyWith(blurEnabled: false),
  ),
  child: GlassButton(onPressed: () {}, child: const Text('打开资料')),
)
```

旧 LiquidGlassTheme(data: …) 仍替换完整配置。不要用一个全新默认配置冒充“只改一个字段”；先用 parent.copyWith，再用嵌套对象的 copyWith 保留其余字段。

标准模式按钮保持 48px；紧凑 + shrinkWrap 为最小 40px，内容可以继续撑高。触摸场景保留 padded，紧凑 padding 仍可生效，但实际布局/命中区域至少 48px。

## 状态、清空与所有权

- ButtonStyle 控制状态颜色、文字、padding、最小尺寸等已接入字段；清单见 [api.md](api.md)。不要假定所有 SDK ButtonStyle 字段均已实现。
- colorScheme 的显式 null 恢复旧色；GlassStyle.copyWith(backgroundGradient:null) 清空渐变；GlassLayout.copyWith(iconSize:null) 恢复继承图标尺寸。
- 显式组件 padding 不再做密度调整；省略参数才按主题与密度解析。同名 getter 保留旧默认值，不代表已构建控件的有效主题值。
- 外部 FocusNode 由调用方释放；组件不持有页面、文件或业务状态。
- 弹窗/页面捕获打开时的局部主题。需要浮层内部再次覆盖时，在其内容内继续使用 merge。

示例 API 和配置组合由 theme_contract_test、component_contract_test、public_api_test 及设计 Golden 验证；原 example 保留兼容用途。Windows 实窗与 Android 性能的验证边界见 [testing.md](testing.md)。

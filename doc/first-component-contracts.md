# 首批组件最小接口契约

本页细化 [首批组件交付](design-system.md#首批组件交付)，供 LIB-04/05/06/08/09/10 按切片实施。保留 `lightweight_liquid_glass`、现有包入口和旧 Glass API。以下标为 **拟新增** 的签名是实现约定，尚未导出；Flutter 原生组合从 SDK 导入，不由本库整体重导出。[现有 API 基线](api.md)记录主线玻璃能力；本分支继承 [#29 草稿](https://github.com/surface-user/Flutter_liquid_glass/pull/29)的独立 `NavigationItem`，未继承 #4 的 `GlassTextField`、`GlassTab` 或主题增量。

示例片段中的 `material` 指 `import 'package:flutter/material.dart' as material;`，`ui` 指 `import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart' as ui;`。使用前缀可避免同名类型影响调用；新组件仍按用途命名。回调、选中状态和业务文案由应用提供。本文不以示例中的拟新增名称承诺已发布接口；最终视觉、数值和扩展随实现验收。

## 操作（LIB-05）

本工作树已按 LIB-05 实现以下按钮；实际公开参数、样式及用法见 [通用按钮 API](api.md#通用按钮)。

| 组件 | 必填 | 可选及默认 |
| --- | --- | --- |
| `ActionButton` | `Widget child`、`VoidCallback? onPressed` | `Widget? leading`、`FocusNode? focusNode`、`ActionButtonStyle? style` 默认为 null；`ActionButtonVariant variant = secondary`（`primary / secondary / auxiliary`）；`ActionButtonSize size = medium`（`small / medium / large`）；`bool loading = false` |
| `IconActionButton` | `Widget icon`、`String tooltip`、`VoidCallback? onPressed` | 同上 `focusNode`、`variant`、`size`、`loading`、`style`，无 `leading` |

- `onPressed: null` 表示外部禁用；`loading: true` 表示请求处理中，不接收指针、Enter、Space 或辅助技术的再次激活，不为加载把非空回调改成 null 或替换焦点节点。已获焦点、可访问名称、触摸目标和布局保持稳定，读屏能得知忙碌且不能重复触发。若调用方同时把回调置为 null，按禁用行为处理。组件不执行 Future、不自动结束加载；调用方设置状态。
- `leading` 和 `icon` 只提供内容，装饰图标不重复播报；图标按钮使用非空 `tooltip` 提供名称。用途与尺寸分别选择样式，不改变激活方式。玻璃仍是独立、可继承的表面配置；首个切片只验普通按钮与外层玻璃的组合，按钮独立表面接口随实现确认，不提前增加模糊参数。三个尺寸默认触摸目标保留 48×48 逻辑像素，跟随文字放大；不保证固定高度。
- 验收：按压取消不调用，指针、Enter/Space 和语义动作每次只调用一次；加载时原焦点和外框不跳，解除加载后可再次激活；外部 `FocusNode` 不释放；焦点可与 hover/pressed 并存且可辨认。旧 `GlassButton` / `GlassIconButton` 及默认视觉不回退。

```dart
// save()、saving 由应用提供。
ui.ActionButton(
  onPressed: save,
  loading: saving,
  child: const material.Text('保存'),
)
```

## 输入与表单（LIB-06）

首批以原生 `TextFormField` 和 `Form` 组成可独立使用的接入配方；先用主题统一外观，避免包装整个 SDK 签名。纯文本且无初值和校验时也可直接用 `TextField`，它不参加 `FormState.reset()`。

| 参数（只列首批使用项） | 类型、默认与消费 |
| --- | --- |
| 初值、资源 | `TextEditingController? controller`、`String? initialValue`、`FocusNode? focusNode` 均默认 null。外部 controller 与非空初值互斥；没有 controller 时，初值 null 表示从空串开始。controller/focusNode 由调用方释放 |
| 行数和编辑状态 | `int? maxLines = 1`，正整数为上限，null 表示不限定行数、仍受父约束；`bool readOnly = false`；原生 `bool? enabled` 缺省由装饰配置解析，无设置时为 true，传 false 禁止编辑与激活 |
| 字段装饰与外部错误 | `InputDecoration? decoration` 默认空装饰并应用宿主主题；标签、提示、辅助文本用其对应字段。`String? forceErrorText = null` 用于表单外部错误，由调用方清除；非空时字段无效且跳过 validator |
| 校验与回调 | `FormFieldValidator<String>? validator`、`ValueChanged<String>? onChanged`、`ValueChanged<String>? onFieldSubmitted`、`FormFieldSetter<String>? onSaved` 默认 null。validator 同步返回 null 或错误文本；默认不自动校验，可用原生 `autovalidateMode`。提交回调与 `FormState.save()` 均不隐式执行异步保存 |

不在 build 中写 controller；父级普通重建不覆盖草稿，切记录由应用建立新的会话身份。沿用 [Flutter 原生重置与回调](https://api.flutter.dev/flutter/material/TextFormField/onChanged.html)：重置可写回 controller 并触发字段 `onChanged`；程序直接写 controller 不应据此当作用户输入。不要假定动态改变初值或替换 controller 能更新同一字段的重置基准。不加 `resetValue`、自动清草稿、保存时重设基准，或动态基准专项测试。

```dart
material.Form(
  key: formKey,
  child: material.TextFormField(
    controller: editor,
    maxLines: 4,
    decoration: const material.InputDecoration(labelText: '备注'),
    validator: (value) =>
        (value ?? '').trim().isEmpty ? '请输入备注' : null,
  ),
)
```

验收：原生 `validate()`、`save()`、`reset()` 不因主题接入改变语义；单行、多行、只读、禁用、外部错误和长文换行可用；重建保留草稿、选区和中文输入法组合；外部资源在移除后可继续使用。真机输入法、读屏单列验证。

## 导航（LIB-09A/09）

- **#29 已实现**：`NavigationItem({required String label, bool selected = false, Widget? leading, Widget? trailing, VoidCallback? onPressed, FocusNode? focusNode, Key? key})`。可空值默认 null。仅请求激活；父级更新 `selected` 后才改变选中语义。空回调禁用；两侧插槽不接管激活。条目只依赖 Flutter，玻璃由消费端组合。
- **拟新增**：先用相同的受控语义组合侧栏；如果需要可关闭的单个标签，建议 `NavigationTab({required String label, bool selected = false, VoidCallback? onPressed, VoidCallback? onClose, String? closeTooltip, FocusNode? focusNode, Key? key})`。可空值默认 null；空激活回调只禁用主标签；空 `onClose` 表示无关闭按钮，有 `onClose` 时调用方提供非空本地化 `closeTooltip`。关闭按钮是同级焦点目标，不能冒泡成激活；应用决定是否关闭以及下一个选中项。标签列表、路由、重排和页面缓存由使用端持有，不造 TabManager。

```dart
ui.NavigationItem(
  label: '项目',
  selected: activeSection == Section.projects,
  onPressed: () => selectSection(Section.projects),
)
```

验收：聚焦与选中分离，指针/Enter/Space 只请求一次，应用可拒绝更新；标签的关闭与激活分别可由键盘操作；条目在普通与玻璃外层的焦点、语义一致，RTL、大文字及窄栏不截断可访问名称。

## 布局与内容容器（LIB-10）

首批交付组合，不加同名 `Card`、`Row`、`Column`、`AppBar` 或通用容器接口。普通内容可用原生 `Card(child: Widget?, margin: EdgeInsetsGeometry?)` 等合适的组件，省略样式时跟随宿主主题。统一面板内容布局时显式用 `Widget child`、`EdgeInsetsGeometry padding`（该用法默认 `EdgeInsets.zero`）和父约束；填色、圆角和裁剪由普通 `Material` 或玻璃 `GlassSurface` 提供。顶栏组合头部、标题和操作区；父容器负责宽度与滚动，窄屏操作区可折行，不增加全局布局管理器。

```dart
material.Widget panel(material.Widget child, {bool glass = false}) {
  final body = material.Padding(
    padding: const material.EdgeInsets.all(12),
    child: child,
  );
  return glass
      ? ui.GlassSurface(child: body)
      : material.Material(child: body);
}
```

验收：同一内容在普通实色与玻璃面板均可组合；窄宽度、RTL、大文字和长内容不溢出，滚动区由父级提供明确约束。关闭模糊时内容仍清楚且可操作，不给每个子控件创建过滤器。

## 确认弹窗（LIB-08）

首批用 [Flutter `showDialog<bool>`](https://api.flutter.dev/flutter/material/showDialog.html) 及 `AlertDialog` 组合，不加同名路由函数。必填 `BuildContext context`、`WidgetBuilder builder`。此配方沿用 `bool useRootNavigator = true` 与 `bool barrierDismissible = true`；有嵌套导航时可以显式选 `useRootNavigator: false`。外层闭合焦点遍历沿弹窗路由，标题、内容、动作由调用方传入；窄窗和长文可滚动。玻璃变体可另用现有 `showGlassDialog<bool>` 与 `GlassDialog` 组合，按相同结果规则验收，不默认提供该路由当前未兑现的独立退出时长。

| 结果 | 来源 |
| --- | --- |
| `true` | 显式确认，将值返回给打开弹窗的调用方 |
| `false` | 显式取消按钮 |
| `null` | 未给结果的关闭，例如允许的外点、Esc/系统返回或程序关闭 |

```dart
final result = await material.showDialog<bool>(
  context: context,
  builder: (dialogContext) => material.AlertDialog(
    title: const material.Text('确认删除？'),
    scrollable: true,
    actions: [
      material.TextButton(
        onPressed: () => material.Navigator.of(dialogContext).pop(false),
        child: const material.Text('取消'),
      ),
      material.TextButton(
        onPressed: () => material.Navigator.of(dialogContext).pop(true),
        child: const material.Text('删除'),
      ),
    ],
  ),
);
if (result == true) deleteSelection();
```

验收：用弹窗自己的 context 只弹出对应路由，确认/取消/关闭结果可区分且只返回一次；焦点停留在弹窗，关闭后在原触发器仍存在且可聚焦时恢复；长文和动作可访问，减少动画不丢最终状态。不把外点开关当作所有退出方式的总开关，业务提交由调用方决定。

## 主题与材质交界（LIB-04）

- 新通用样式按**字段**解析：实例 → 最近局部主题 → 更外层局部主题 → 全局 → SDK/组件默认。同一层先取用途特定字段，再取本层通用字段；null 表示继续找下一候选，而非清空或跳过本层。例：全局主要按钮设蓝底和圆角、局部通用样式设绿底，则局部绿底胜出，同时沿用全局圆角；实例只设圆角时，背景仍为绿底。视觉或系统约束（如对比度、最小触摸目标、减少动画）在最后落实。只有真实消费点才新增样式字段，不自动外露整个 `ButtonStyle`。
- 旧 `LiquidGlassTheme(data: …)` 的整体替换、查找优先级和默认不变；新的局部字段继承另有明确入口。先用一个真实现有消费者（如 `NavigationItem` 的选中背景与焦点边框）验证字段解析，保留原签名和默认外观；待首个通用按钮消化用途覆盖，再用已用字段建立公共契约。
- 普通实色用 Flutter `Material`，玻璃用现有 `GlassSurface`，无需统一材质枚举或把选择硬编码进所有控件。玻璃层负责模糊、着色、边框、裁剪和无模糊降级；切换材质不改变组件的状态与事件规则。不要把普通实色等同于玻璃的降级配置，或把 `GlassSurface(enabled: false)` 当成禁用子组件。
- 最小验收：同一组件用局部配置覆盖一项字段、另一项从全局继承；有实例可覆盖字段时验证实例优先。有真实用途变体的组件再验证“局部通用压过全局特定”，不为此增加占位变体。让消费者从公共入口混用普通与玻璃父层，验证选中、键盘、焦点、暗色/高对比和关模糊可用、没有额外逐行过滤；减少动画时不增加非必要动效或闲置 ticker。旧主题整体替换、旧 API 和默认视觉必须回归。

实现 PR 对拟新增接口补从原包入口导入的可编译例、Dart 文档、README、CHANGELOG 和适用测试；本页不改变公开导出，不代表未实现接口已通过编译或验收。高级导航、复杂选择、异步表单、第三方依赖及最终视觉调校后续独立处理。

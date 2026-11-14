# GlassLab · 组件实验台

独立 Flutter Web 应用。源码、组件库快照、测试、产物和 Sites 配置全部在本目录；不修改外层组件库。`packages/lightweight_liquid_glass` 是随实验台保存的快照，不会自动跟随外层库更新。

## 本地运行

需要 Flutter 3.44+、Dart 3.12+。

```powershell
cd app
flutter pub get
flutter run -d chrome
```

不能直接双击 `app/web/index.html`：它是需要 Flutter 构建替换占位符的源模板。正式网页必须由 HTTP 服务托管构建后的 `dist/`。

## 验证和构建

在本目录运行：

```powershell
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
cd ..
./build.ps1
```

构建脚本将网页放入 `dist/`，CanvasKit 随站点托管，另生成网页下载按钮使用的 `playground-source.zip`。旧网页产物保存在 `artifacts/dist-*`，不覆盖源码。下载源码解压后可按“本地运行”步骤启动；重建部署脚本仅在完整 Sites 工作目录提供。

布局保存在当前浏览器的 localStorage，重要布局请导出 JSON；切换浏览器或站点地址不会自动迁移布局。

## Sites 发布

复用 `.openai/hosting.json` 的现有项目 ID 和 `dist` 静态目录。按照 Sites 源码同步、打包、保存版本、发布流程更新，保持原访问权限。站点使用独立的源码仓库，不向外层 Flutter 库提交或创建 PR。

## 参数与类型适配（2026-11-13）

数字和文字参数支持回车或失焦应用，错误不覆盖有效布局；模块外框与内部表面尺寸分别控制。组件类型按插槽筛选并重建对应参数，不支持项只读说明；可继承的值可以恢复默认。旧布局校验失败时保留原始数据并提供导出，保存前自动保留首份旧布局备份。完整契约、逐组件证据及验证边界见 [VERIFICATION.md](VERIFICATION.md)。

## 2026-11-12 修复验证

- 修复组件拖拽被画布滚动手势抢占，以及缩放坐标被重复换算的问题；调整大小使用相同坐标契约。
- 紧凑工具栏和底栏支持窄屏，功能保留在图标按钮中。
- 7 项测试通过；包括触摸拖拽、65%/125% 鼠标移动和调整大小、撤销重做、320/390/820/1440px 布局。
- Flutter analyze 无问题。日志与桌面截图在 `artifacts/`；旧失败日志保留。
- 自动化结果不代表真实移动设备或所有浏览器均已验收。

## 中文界面与菜单弹窗修复

- 组件名、属性名、下拉选项、事件提示、加载页和系统返回/关闭提示使用中文；配置编辑器保留原始代码字段，兼容已有保存布局。旧版本的内置英文示例文案在显示时转换为中文，不重写用户保存的数据。
- 菜单“打开弹窗”原先传入了缺少组件类型的默认配置，渲染器将其当成文字。现在默认动作明确创建玻璃弹窗，显示标题、正文和“知道了”关闭按钮；同类默认页面动作也保留其卡片类型。
- 11 项测试通过，包含中文标签覆盖、菜单弹窗打开和关闭、320/390px 下 130% 字体弹窗，以及 320/390/820/1180/1500px 下主题设置展开。静态分析无问题，原拖拽与缩放回归仍通过。
- 已查看 `artifacts/menu-dialog-zh.png`、`artifacts/menu-dialog-zh-320.png` 和窄屏设置截图，未见文字遮挡或布局溢出。测试截图中的图标方框来自测试环境未载入图标字体；正式网页使用随构建提供的图标字体。
- 原失败证据在 `artifacts/menu-before.log`；本次验证日志为 `artifacts/zh-final-test.log` 和 `artifacts/zh-final-analyze.log`。

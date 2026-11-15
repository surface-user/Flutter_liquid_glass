# 主Agent公开示例抽查记录

日期：2026-11-15。此记录由主Agent独立补充，未传给四个独立研究代理，避免影响其判断。浏览器：Edge，视口1661×941，未安装桌面客户端、登录账号或运行仓库代码。公开网站当前部署提交未提供可核验标识，不能当成与固定源码SHA一致的运行证明。全部是短流程抽查，未计时测帧或完成可访问性审计。

## B01 fluent_ui Gallery

入口：https://bdlukaa.github.io/fluent_ui/ （由官方仓库README链接进入）。
实际路径：首页→Dialogs & flyouts→ContentDialog→Show dialog→Cancel→展开Source code。
事实：左侧用途分组、中央用途说明与真实试用；出现“Delete file permanently?”模态框，取消后页面显示“User canceled dialog”；源代码折叠区可展开并有Copy入口。未点击Delete，未核验复制到剪贴板的内容与执行体逐字一致。
证据：[真实弹窗](evidence/reference-research/fluent-dialog.jpg)、[取消结果与代码同屏](evidence/reference-research/fluent-code-result.jpg)。默认深色，文字可见；这不证明所有主题、高对比和减少动画已通过。

## B02 shadcn_flutter Docs

入口：https://sunarya-thito.github.io/shadcn_flutter/ （由官方仓库提供）。
实际路径：Introduction→左侧Dialog→Edit Profile→查看表单→Esc关闭。
事实：文档导航包含用途分类、Application/Animation/Overlay等；Dialog页是单一真实Edit Profile示例，输入框与Save changes按钮在模态中；Esc返回原示例，示例下方有源码区。首页部分项标WIP/Experimental。没有编辑或提交表单，未验证后端保存、结果回传、复制代码与编译源码相同。
证据：[弹窗表单](evidence/reference-research/shadcn-dialog.jpg)。界面提供的“84 components”是站点宣传数字，未在本记录当成有效功能数。

## B03 Appainter

入口：https://appainter.dev/ （官方仓库homepage）。
实际路径：Basic→Brightness由浅切深→观察Theme Preview→点击Export→Brightness恢复浅色。
事实：左侧颜色/主题配置，中间设备预览，右侧Device Preview设备与系统/无障碍模拟选项；手机预览含按钮启用/禁用对照、Buttons/Inputs/Selections/Text标签和底部导航。Brightness改变时色值与整个预览同时改变，宿主工具外观与被预览主题分开。
Export点击后没有出现可识别导出面板；本次未捕获或校验下载文件，不据此宣称导出成功或失败。导出的真实类型以固定源码研究为准。恢复Brightness值为0后关闭调研标签。
证据：[调整前](evidence/reference-research/appainter-before.jpg)、[深色主题联动](evidence/reference-research/appainter-dark-preview.jpg)。没有把右侧模拟控件的存在当成对应设备/无障碍实际通过。

## 未运行项与结论边界

AppFlowy仅做固定源码研究，没有登录或启动客户端。三个公开示例的加载完成、短流程、截图已实际查看；没有进行四项目全量交互回归、中文本地化/窄屏/真机性能或物理输入法验证。浏览器短流程只支持上述观察，不支持性能、完备性或稳定性的总体结论。

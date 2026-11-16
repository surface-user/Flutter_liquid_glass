# Demo 与后续设计台

## 当前边界

根组件库优先，设计台在 LIB-16 后按 WEB-LATER 另行定义。目标是消费真实版本/API，配置组件/状态/事件并生成提示词，交由用户 Agent 实现界面；不把网站工程导出或在线模型服务塞进首版库。

下方保留 main 的原始发布记录，仅为 2026-09-17 快照；本次没有验证站点在线性、发布状态/受众或本地 deployment checkout。main 没有跟踪 deployment/；路径属于当时另行维护的工作区，不能在当前仓库直接执行。后续若授权更新，先读取实际站点身份与部署规则，不能猜测 ID 或重建同名站点。本任务只创建文档 PR，不发布。

## 原始发布记录

### Public demo

URL: https://lightweight-liquid-glass-lab.marseille-cjh.chatgpt.site

Published successfully through Sites on 2026-09-17. Audience: public.
The demonstration runs in the visitor's browser; it does not need the author's
computer or local preview server to stay online.

The hosting checkout is deployment/site/ and its persisted Site identity is in
deployment/site/.openai/hosting.json. Reuse it for future deployments.
This local deployment checkout and its archives are excluded from the library
repository and pub package. The library's GitHub remote remains unchanged.

The deployed static files come from example/build/web. The deployment bootstrap
loads CanvasKit from its own canvaskit/ directory and disables the deprecated
service-worker bootstrap. Keep this configuration when refreshing the demo.

For later updates: rebuild the Flutter example, update this same static checkout,
then follow the Sites hosting workflow to publish a new version to this URL.

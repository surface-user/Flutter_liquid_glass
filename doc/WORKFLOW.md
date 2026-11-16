# 开发与 GitHub 工作流

## 基线与范围

任务先列目标、实际分支、依赖和验收。main 的普通独立变更使用 main 基底与 codex/** 分支；依赖未合并 PR 的工作须说明 base/head、固定 SHA 及最终合入路径。不能把堆叠分支改指 main 后声称只有顶层差异。

本次文档以 main a0bc51a 为唯一父提交，参考 #26/#4 的文档内容，保持代码/测试/CI/网站在 PR 之外。保留原工作区与未提交改动，不关闭、合并或重定向旧 PR。#26 仍需后续同步这些新规则，合并前解决重复文档与计划差异；不能用旧版本覆盖新规范。

## 提交与审查

1. doc/task.md 或 Issue 定义具体工作与验收；已有授权覆盖的工作直接推进。
2. 建立隔离分支/工作树，实现最小完整改动，按风险更新调用方、测试、示例和文档。
3. Conventional Commits，例如 `docs(direction): align library-first development docs`；PR 标题同样遵循。
4. 本地跑适用检查，检查相对 main 的完整 diff，推送并创建明确 base 的 PR。
5. 目标分支有 .github/pull_request_template.md 时使用；否则正文列问题/结果、实现取舍、API/视觉、验证、性能/无障碍、未验与依赖。可用 GitHub connector 或已认证 CLI，不把凭据写入仓库。
6. 检查当前 head 的 CI 和非作者审查；至少一名非作者批准且满足适用检查后，按当次用户授权决定合并。创建 PR 不等于授权合并或发布。

## CI 的真实状态

main a0bc51a 没有 .github/ 工作流、模板、CODEOWNERS 或 Dependabot；本次仅 doc/，不把 #4 的配置一起带入。因此不能承诺本 PR 自动运行 Flutter/Dependency Review。创建后查询当前 head 的实际工作流/检查；无运行即报告无 CI，不借用 #26 绿灯。

#4 的 [固定 CI](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/.github/workflows/ci.yml) 使用 Flutter 3.47.1，含格式/分析、根/example行为、Android profile Dart 入口编译、Web、Windows Golden、发布 dry-run、标题检查；[Dependency Review](https://github.com/surface-user/Flutter_liquid_glass/blob/ac0028eacd0e1ee22747d454c04a456dcb307377/.github/workflows/dependency-review.yml) 单独执行。引入后按真实配置使用；编译不是设备性能，CI 不代替 IME/读屏。

本轮查询 main 的 GitHub branch API 返回 protected=false。这是查询时状态；不通过改文档、跳过检查或自动修改设置解决。

## 建议保护与依赖更新

建议 main 要求 PR、至少一名非作者批准、提交更新后重新审查、讨论解决、适用 status checks、禁止强推与删除；CODEOWNERS/check 名以实际合入配置为准。设置需要维护者另行启用，不是文档提交即可生效。

采用第三方后，将实际 pub 依赖纳入升级和漏洞/许可审查，核对资产与传递项；SDK-only 的旧状态不再成为永远不配置 pub 更新的理由。Dependabot 与功能 PR 都遵循同一审查，不能自动绕过失败。

发布流程见 [RELEASE.md](RELEASE.md)，文档验证及历史账本见 [testing.md](testing.md)。

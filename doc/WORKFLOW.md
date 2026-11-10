# 开发与 GitHub 工作流

## 工作流总览

1. Issue 或 `doc/task.md` 定义目标和验收标准。
2. Agent 创建 `codex/<task-id>-<slug>` 分支。
3. 实现最小完整改动，补测试、示例和文档。
4. 本地执行与改动匹配的检查。
5. Agent commit、push，并使用 `gh pr create` 提交 PR。
6. GitHub CI 执行格式、分析、测试、视觉回归、Web 构建和发布预检。
7. CODEOWNERS 与人工审查检查 API、性能、无障碍和兼容性。
8. 所有 required checks 通过且至少一人批准后，按用户授权由 Agent 或维护者合并。

## 分支和 commit

- 功能：`codex/<issue>-<slug>`
- 修复：`codex/fix-<issue>-<slug>`
- 文档：`codex/docs-<slug>`

Commit 与 PR 标题使用：

```text
feat(surface): add press feedback
fix(group): isolate overlapping filters
docs(workflow): document animation task
test(motion): cover reduced motion
ci: add Flutter validation
```

允许中文说明，但标题必须保留 `type(scope): description` 结构。

## Agent 提交 PR

Agent 在用户授权创建 PR 后执行：

```sh
git push -u origin <branch>
gh pr create --base main --head <branch> --title "feat(surface): ..." --body-file <prepared-body-file>
```

PR 正文使用 `.github/pull_request_template.md`。如果没有 GitHub CLI 登录状态，Agent停止在已推送分支并报告，不保存凭据到仓库。

## 自动化

### CI

`.github/workflows/ci.yml` 在 main、`codex/**` 分支和 PR 上运行：

- Dart 格式检查。
- Flutter 静态分析。
- 根组件测试和示例交互测试。
- Windows 视觉回归。
- Web release 构建。
- pub.dev 发布预检。
- PR 标题规范检查。

### 依赖审查

`.github/workflows/dependency-review.yml` 在 PR 中阻止已知 high/critical 漏洞依赖。仓库需启用 Dependency graph；私有仓库可能还需要 GitHub Code Security。

### 自动创建依赖 PR

`.github/dependabot.yml` 每周检查 GitHub Actions 版本并自动创建 PR。当前运行时没有第三方 Dart 包，因此不配置无实际更新目标的 pub 任务。

Dependabot PR 仍必须通过 CI 和人工审查，不自动合并。

## 推荐分支保护

在 GitHub `Settings → Rules → Rulesets` 为 `main` 配置：

- Require a pull request before merging。
- Require at least 1 approval。
- Dismiss stale approvals when new commits are pushed。
- Require review from Code Owners。
- Require status checks：`static-analysis-and-tests`、`visual-regression`、`dependency-review`。
- Require conversation resolution。
- Block force pushes and branch deletion。
- 不允许管理员默认绕过；紧急修复应留下审计说明。

这些仓库设置不能仅靠提交文件生效，需要仓库管理员在 GitHub 界面启用。

## 合并策略

推荐 squash merge，使每个 PR 在 main 上形成一个清晰提交。禁止 CI 自动合并功能代码或 Dependabot PR。

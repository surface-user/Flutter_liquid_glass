# 发布流程

## 版本规则

- patch：兼容的修复、性能或文档改进。
- minor：兼容的新公开接口或组件。
- major：公开 API 破坏性变更。

## 发布前

1. `doc/TASK.md` 已完成，PR 已合并。
2. 更新 `pubspec.yaml` 版本和 `CHANGELOG.md`。
3. 执行 `flutter analyze`、完整测试、Web 构建和 `flutter pub publish --dry-run`。
4. 检查 README、GitHub 地址、License 和 `.pubignore`。
5. 确认 golden 是审查后的最终结果。
6. 在 Android 真机验证涉及渲染或性能的改动。

## 发布

```sh
git tag v<version>
git push origin v<version>
flutter pub publish
```

`flutter pub publish` 是不可逆的外部发布动作，只能由维护者在最终检查后手动执行。GitHub Release 应使用 CHANGELOG 中相同版本的内容。

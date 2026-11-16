# 发布流程

## 版本规则

- patch：兼容的修复、性能或文档改进。
- minor：兼容的新公开接口或组件。
- major：公开 API 破坏性变更。

## 发布前

1. 本次发布所选任务已验收并按授权合入；task.md 中长期 PLANNED、历史 REVIEW 或待验项单独列明，不要求整份未来路线完成，也不抹去未完成记录。
2. 更新 `pubspec.yaml` 版本和 `CHANGELOG.md`。
3. 执行 `flutter analyze`、完整测试、Web 构建和 `flutter pub publish --dry-run`。
4. 检查 README、GitHub 地址、License 和 `.pubignore`。
5. 确认 golden 是审查后的最终结果。
6. 在 Android 真机验证涉及渲染或性能的改动；其他声明支持的平台按实际记录。
7. 若新增第三方，核对固定版本、传递/资源许可与必要声明、最低 SDK 和包体/依赖变化；独立适配包记录各自版本和核心兼容范围，不默默抬高核心 SDK。
8. 同步 README/pubspec/公共入口说明与实际能力。当前这些文件仍聚焦旧玻璃实现，本轮未修改。

## 发布

以下只供维护者在明确授权后的发布阶段使用。本次文档 PR 不打 tag、不发布、不合并。

```sh
git tag v<version>
git push origin v<version>
flutter pub publish
```

`flutter pub publish` 是不可逆的外部发布动作，只能由维护者在最终检查后手动执行。GitHub Release 应使用 CHANGELOG 中相同版本的内容。

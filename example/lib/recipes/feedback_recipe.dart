import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() => runApp(const MaterialApp(home: FeedbackRecipe()));

enum _Status { empty, waiting, progress, failed, complete }

class FeedbackRecipe extends StatelessWidget {
  const FeedbackRecipe({super.key});

  @override
  Widget build(BuildContext context) =>
      const ScaffoldMessenger(child: _FeedbackPage());
}

class _FeedbackPage extends StatefulWidget {
  const _FeedbackPage();

  @override
  State<_FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<_FeedbackPage> {
  _Status _status = _Status.empty;
  var _progress = 0.0;
  String? _acknowledgedMessage;

  void _setStatus(_Status status) => setState(() => _status = status);

  void _startProgress() => setState(() {
    _progress = .25;
    _status = _Status.progress;
  });

  void _advance() => setState(() {
    _progress += .25;
    if (_progress == 1) _status = _Status.complete;
  });

  void _showMessage(String message) {
    final media = MediaQuery.of(context);
    final theme = LiquidGlassTheme.of(context);
    final reduceMotion =
        media.disableAnimations ||
        media.accessibleNavigation ||
        theme.accessibility.reduceMotion ||
        !theme.performance.enableAnimations;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        showCloseIcon: true,
        persist: true,
        action: SnackBarAction(
          label: '确认收到',
          onPressed: () => setState(() => _acknowledgedMessage = message),
        ),
      ),
      snackBarAnimationStyle: reduceMotion
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: kThemeAnimationDuration,
              reverseDuration: kThemeAnimationDuration,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (label, action, onPressed) = switch (_status) {
      _Status.empty => ('暂无结果', '开始', () => _setStatus(_Status.waiting)),
      _Status.waiting => ('等待进度', '开始计量', _startProgress),
      _Status.progress => ('正在处理', '推进进度', _advance),
      _Status.failed => ('处理失败', '重试', () => _setStatus(_Status.waiting)),
      _Status.complete => ('处理完成', '返回空态', () => _setStatus(_Status.empty)),
    };
    final busy = _status == _Status.waiting || _status == _Status.progress;

    return Scaffold(
      appBar: AppBar(title: const Text('状态与反馈示例')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_status == _Status.progress) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  semanticsLabel: '处理进度',
                ),
                ExcludeSemantics(child: Text('${(_progress * 100).round()}%')),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton(onPressed: onPressed, child: Text(action)),
                  if (busy) ...[
                    TextButton(
                      onPressed: () => _setStatus(_Status.failed),
                      child: const Text('模拟失败'),
                    ),
                    TextButton(
                      onPressed: () => _setStatus(_Status.empty),
                      child: const Text('取消处理'),
                    ),
                  ],
                ],
              ),
              const Divider(),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => _showMessage('已更新状态'),
                    child: const Text('显示更新提示'),
                  ),
                  TextButton(
                    onPressed: () => _showMessage('可查看处理结果'),
                    child: const Text('显示结果提示'),
                  ),
                ],
              ),
              if (_acknowledgedMessage case final message?)
                Text('已确认：$message'),
            ],
          ),
        ),
      ),
    );
  }
}

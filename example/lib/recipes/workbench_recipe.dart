import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

import 'confirmation_recipe.dart' show showConfirmation;

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Roboto', colorSchemeSeed: Colors.indigo),
    home: const WorkbenchRecipe(),
  ),
);

enum _View {
  overview('Overview', 'Workspace summary', Icons.dashboard_outlined),
  project('Project', 'Project summary', Icons.folder_outlined),
  activity('Activity', 'Recent activity', Icons.history);

  const _View(this.label, this.heading, this.icon);

  final String label;
  final String heading;
  final IconData icon;
}

enum _Surface {
  solid('Solid'),
  glass('Glass'),
  withoutBlur('No blur');

  const _Surface(this.label);

  final String label;
}

/// A standalone example that composes library widgets with Flutter.
class WorkbenchRecipe extends StatefulWidget {
  const WorkbenchRecipe({super.key});

  @override
  State<WorkbenchRecipe> createState() => _WorkbenchRecipeState();
}

class _WorkbenchRecipeState extends State<WorkbenchRecipe> {
  final _openViews = <_View>{_View.overview, _View.project, _View.activity};
  final _draft = TextEditingController();
  final _applyFocus = FocusNode();
  _View _selected = _View.overview;
  _Surface _surface = _Surface.solid;
  bool _confirming = false;
  String? _result;
  String? _appliedDraft;

  @override
  void dispose() {
    _draft.dispose();
    _applyFocus.dispose();
    super.dispose();
  }

  void _select(_View view) => setState(() {
    _openViews.add(view);
    _selected = view;
  });

  void _close(_View view) => setState(() {
    _openViews.remove(view);
    if (_selected == view) _selected = _View.overview;
  });

  Future<void> _confirm(BuildContext context) async {
    if (_confirming) return;
    final draft = _draft.text;
    setState(() => _confirming = true);
    final result = await showConfirmation(
      context,
      title: 'Apply this draft?',
      content: const Text('This only updates the preview in this example.'),
      glass: _surface != _Surface.solid,
    );
    if (!mounted) return;
    setState(() {
      _confirming = false;
      _result = switch (result) {
        true => 'Draft applied',
        false => 'Apply cancelled',
        null => 'Dialog dismissed',
      };
      if (result == true) _appliedDraft = draft;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassTheme.of(context);
    final performance = glassTheme.performance;
    return LiquidGlassTheme(
      data: _surface == _Surface.withoutBlur
          ? glassTheme.copyWith(
              performance: GlassPerformanceConfig(
                quality: performance.quality,
                blurEnabled: false,
                maxBlurSigma: performance.maxBlurSigma,
                groupBackdropFilters: performance.groupBackdropFilters,
                enableNoise: performance.enableNoise,
                enableShadows: performance.enableShadows,
                enableAnimations: performance.enableAnimations,
              ),
            )
          : glassTheme,
      child: RepaintBoundary(
        key: const ValueKey('workbench-preview'),
        child: Scaffold(
          body: GlassBackdrop(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 660;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: wide ? 200 : constraints.maxWidth,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Wrap(
                                    children: [
                                      for (final view in _View.values)
                                        SizedBox(
                                          width: wide ? 184 : null,
                                          child: NavigationItem(
                                            key: ValueKey('nav-${view.name}'),
                                            label: view.label,
                                            leading: Icon(view.icon),
                                            selected: _selected == view,
                                            onPressed: () => _select(view),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth - (wide ? 216 : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Sample workspace',
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      for (final surface in _Surface.values)
                                        ChoiceChip(
                                          label: Text(surface.label),
                                          selected: _surface == surface,
                                          onSelected: (_) => setState(
                                            () => _surface = surface,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      for (final view in _openViews)
                                        NavigationTab(
                                          key: ValueKey('tab-${view.name}'),
                                          label: view.label,
                                          selected: _selected == view,
                                          onPressed: () => _select(view),
                                          onClose: view == _View.overview
                                              ? null
                                              : () => _close(view),
                                          closeTooltip: 'Close ${view.label}',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _previewPanel(theme),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _draft,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      labelText: 'Draft note',
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: ActionButton(
                                      onPressed: () async =>
                                          await _confirm(context),
                                      focusNode: _applyFocus,
                                      loading: _confirming,
                                      variant: ActionButtonVariant.primary,
                                      child: const Text('Apply draft'),
                                    ),
                                  ),
                                  if (_result case final result?) ...[
                                    const SizedBox(height: 8),
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(result),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewPanel(ThemeData theme) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  _selected.heading,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(switch (_selected) {
                _View.overview => 'Choose a section or write a draft below.',
                _View.project => 'A sample project with notes to review.',
                _View.activity =>
                  'A short record of changes in this workspace.',
              }),
              if (_appliedDraft case final draft?) ...[
                const SizedBox(height: 8),
                Text(draft),
              ],
            ],
          ),
        ),
      ),
    );
    return _surface == _Surface.solid
        ? Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: content,
          )
        : GlassSurface(child: content);
  }
}

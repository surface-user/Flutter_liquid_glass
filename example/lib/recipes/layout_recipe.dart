import 'package:flutter/material.dart';
import 'package:lightweight_liquid_glass/lightweight_liquid_glass.dart';

void main() => runApp(const MaterialApp(home: LayoutRecipe()));

class LayoutRecipe extends StatefulWidget {
  const LayoutRecipe({super.key});

  @override
  State<LayoutRecipe> createState() => _LayoutRecipeState();
}

class _LayoutRecipeState extends State<LayoutRecipe> {
  bool _useGlass = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const panelContent = Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecipeCard(
            title: 'Projects',
            description:
                'Browse the active projects and the notes connected with each one.',
          ),
          SizedBox(height: 8),
          _RecipeCard(
            title: 'Recent notes',
            description:
                'Review the latest notes, their progress, and any details that still need attention.',
          ),
        ],
      ),
    );

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'A workspace layout for projects and recent notes',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _useGlass = !_useGlass),
                          child: Text(_useGlass ? 'Use solid' : 'Use glass'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_useGlass)
                      const GlassSurface(child: panelContent)
                    else
                      Material(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: panelContent,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    ),
  );
}

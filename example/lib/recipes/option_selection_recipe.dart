import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: OptionSelectionRecipe()));

enum _Mode {
  compact('Compact'),
  detailed('Detailed'),
  unavailable('Unavailable');

  const _Mode(this.label);
  final String label;
}

enum _Destination {
  local('Local folder'),
  archive('Archive folder with a deliberately long description'),
  offline('Offline folder');

  const _Destination(this.label);
  final String label;
}

class OptionSelectionRecipe extends StatefulWidget {
  const OptionSelectionRecipe({super.key});

  @override
  State<OptionSelectionRecipe> createState() => _OptionSelectionRecipeState();
}

class _OptionSelectionRecipeState extends State<OptionSelectionRecipe> {
  static const _suggestions = ['Blue folder', 'Green folder', 'Yellow folder'];

  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  _Mode? _mode = _Mode.compact;
  _Destination? _destination = _Destination.archive;
  bool _hasArchive = true;
  String? _suggestion;

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Iterable<String> _matches(String text) {
    final query = text.trim().toLowerCase();
    return query.isEmpty
        ? const <String>[]
        : _suggestions.where((option) => option.toLowerCase().contains(query));
  }

  Iterable<_Destination> get _destinations => _Destination.values.where(
    (destination) => destination != _Destination.archive || _hasArchive,
  );

  void _toggleArchive() => setState(() {
    _hasArchive = !_hasArchive;
    if (!_hasArchive && _destination == _Destination.archive) {
      _destination = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('Option selection')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Display mode', style: heading),
                    const SizedBox(height: 8),
                    SegmentedButton<_Mode>(
                      direction:
                          constraints.maxWidth < 460 ||
                              MediaQuery.textScalerOf(context).scale(16) > 24
                          ? Axis.vertical
                          : Axis.horizontal,
                      emptySelectionAllowed: true,
                      segments: [
                        for (final mode in _Mode.values)
                          ButtonSegment(
                            value: mode,
                            enabled: mode != _Mode.unavailable,
                            label: Text(mode.label),
                          ),
                      ],
                      selected: {if (_mode case final mode?) mode},
                      onSelectionChanged: (values) => setState(() {
                        _mode = values.isEmpty ? null : values.single;
                      }),
                    ),
                    Text('Mode: ${_mode?.label ?? 'None'}'),
                    const SizedBox(height: 16),
                    Text('Destination', style: heading),
                    DropdownButton<_Destination>(
                      value: _destination,
                      hint: const Text('Choose a folder'),
                      isExpanded: true,
                      itemHeight: null,
                      items: [
                        for (final destination in _destinations)
                          DropdownMenuItem(
                            value: destination,
                            enabled: destination != _Destination.offline,
                            child: Text(
                              destination.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null &&
                            value != _Destination.offline &&
                            _destinations.contains(value)) {
                          setState(() => _destination = value);
                        }
                      },
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _destination == null
                              ? null
                              : () => setState(() => _destination = null),
                          child: const Text('Clear destination'),
                        ),
                        TextButton(
                          onPressed: _toggleArchive,
                          child: Text(
                            _hasArchive ? 'Remove archive' : 'Restore archive',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Local suggestions', style: heading),
                    const SizedBox(height: 8),
                    Autocomplete<String>(
                      textEditingController: _query,
                      focusNode: _searchFocus,
                      optionsBuilder: (value) => _matches(value.text),
                      optionsViewOpenDirection: OptionsViewOpenDirection.up,
                      onSelected: (value) =>
                          setState(() => _suggestion = value),
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) =>
                              TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Search folders',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) {
                                  if (_suggestion != null) {
                                    setState(() => _suggestion = null);
                                  }
                                },
                                onSubmitted: (_) => onFieldSubmitted(),
                              ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _query,
                      builder: (context, value, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: value.text.isEmpty
                                ? null
                                : () {
                                    _query.clear();
                                    setState(() => _suggestion = null);
                                  },
                            child: const Text('Clear search'),
                          ),
                          if (value.text.trim().isNotEmpty &&
                              _matches(value.text).isEmpty)
                            Semantics(
                              liveRegion: true,
                              child: const Text('No matching folders'),
                            ),
                          Text('Suggestion: ${_suggestion ?? 'None'}'),
                        ],
                      ),
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

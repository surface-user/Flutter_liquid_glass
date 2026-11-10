import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const _configFiles = {
  'lib/src/core/config.dart',
  'lib/src/core/motion_spec.dart',
  'lib/src/core/style.dart',
};

// Read every URI in a directive, including conditional imports and Dart parts.
Iterable<String> _uris(String source) sync* {
  final directives = RegExp(
    r'^\s*(?:import|export|part(?!\s+of))\s+[^;]+;',
    multiLine: true,
  );
  for (final directive in directives.allMatches(source)) {
    for (final uri in RegExp(
      "['\"]([^'\"]+)['\"]",
    ).allMatches(directive.group(0)!)) {
      yield uri.group(1)!;
    }
  }
}

List<String> _boundaryErrors(Map<String, Set<String>> graph) {
  final errors = <String>[];
  for (final entry in graph.entries) {
    for (final target in entry.value) {
      if ((entry.key.startsWith('lib/src/core/') &&
              !target.startsWith('lib/src/core/')) ||
          (entry.key.startsWith('lib/src/theme/') &&
              !target.startsWith('lib/src/theme/') &&
              !_configFiles.contains(target))) {
        errors.add('${entry.key} -> $target');
      }
      if (entry.key.startsWith('lib/src/') &&
          target == 'lib/lightweight_liquid_glass.dart') {
        errors.add('${entry.key} imports the public barrel');
      }
    }
  }
  return errors;
}

List<String> _cycle(Map<String, Set<String>> graph) {
  final done = <String>{};
  final stack = <String>[];
  List<String> visit(String node) {
    final index = stack.indexOf(node);
    if (index != -1) return [...stack.sublist(index), node];
    if (!done.add(node)) return [];
    stack.add(node);
    for (final target in graph[node] ?? <String>{}) {
      final cycle = visit(target);
      if (cycle.isNotEmpty) return cycle;
    }
    stack.removeLast();
    return [];
  }

  for (final node in graph.keys) {
    final cycle = visit(node);
    if (cycle.isNotEmpty) return cycle;
  }
  return [];
}

void main() {
  test(
    'guard reads conditional/package URIs and detects cycles and boundaries',
    () {
      expect(
        _uris(
          [
            "import 'a.dart' if (dart.library.io) 'b.dart';",
            "export 'package:lightweight_liquid_glass/src/core/style.dart' show GlassStyle;",
            "part 'button.dart';",
            "part of 'interaction.dart';",
          ].join('\n'),
        ),
        [
          'a.dart',
          'b.dart',
          'package:lightweight_liquid_glass/src/core/style.dart',
          'button.dart',
        ],
      );
      expect(
        _cycle({
          'a': {'b'},
          'b': {'a'},
        }),
        ['a', 'b', 'a'],
      );
      expect(
        _cycle({
          'a': {'b'},
          'b': <String>{},
        }),
        isEmpty,
      );
      expect(
        _boundaryErrors({
          'lib/src/core/a.dart': {'lib/src/components/b.dart'},
          'lib/src/theme/a.dart': {'lib/src/core/surface_renderer.dart'},
        }),
        hasLength(2),
      );
      expect(
        _boundaryErrors({
          'lib/src/theme/a.dart': {'lib/src/core/config.dart'},
        }),
        isEmpty,
      );
    },
  );

  test('library dependencies respect layers and contain no cycles', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    final names = {
      for (final file in files)
        file.absolute.uri: file.path.replaceAll('\\', '/'),
    };
    final graph = <String, Set<String>>{};
    final partOwners = <Uri, Uri>{};
    for (final file in files) {
      final source = file.readAsStringSync();
      final name = names[file.absolute.uri]!;
      graph[name] = {};
      for (final uri in _uris(source)) {
        if (uri.startsWith('dart:') ||
            (uri.startsWith('package:') &&
                !uri.startsWith('package:lightweight_liquid_glass/'))) {
          continue;
        }
        final target = uri.startsWith('package:lightweight_liquid_glass/')
            ? Directory('lib').absolute.uri.resolve(
                uri.substring('package:lightweight_liquid_glass/'.length),
              )
            : file.absolute.uri.resolve(uri);
        expect(
          names.containsKey(target),
          isTrue,
          reason: '$name -> $uri must resolve',
        );
        graph[name]!.add(names[target]!);
      }
      for (final part in RegExp(
        r"^part '([^']+)';",
        multiLine: true,
      ).allMatches(source)) {
        final target = file.absolute.uri.resolve(part.group(1)!);
        expect(
          partOwners.containsKey(target),
          isFalse,
          reason: 'one owner per part',
        );
        partOwners[target] = file.absolute.uri;
      }
      if (name.startsWith('lib/src/core/')) {
        expect(
          source.contains('LiquidGlassTheme'),
          isFalse,
          reason: '$name must not resolve themes',
        );
      }
    }
    for (final file in files) {
      final source = file.readAsStringSync();
      final owner = RegExp(
        r"^part of '([^']+)';",
        multiLine: true,
      ).firstMatch(source);
      if (owner != null) {
        expect(
          partOwners[file.absolute.uri],
          file.absolute.uri.resolve(owner.group(1)!),
        );
        expect(
          _uris(source),
          isEmpty,
          reason: 'parts share their owner imports',
        );
      }
    }
    expect(_boundaryErrors(graph), isEmpty);
    expect(_cycle(graph), isEmpty);
  });

  test(
    'public barrel explicitly exports exactly the original twenty declarations',
    () {
      final source = File(
        'lib/lightweight_liquid_glass.dart',
      ).readAsStringSync();
      final exports = RegExp(r'export\s+[^;]+;').allMatches(source).toList();
      final names = <String>[];
      for (final export in exports) {
        final shown = RegExp(r'\bshow\s+([^;]+);').firstMatch(export.group(0)!);
        expect(
          shown,
          isNotNull,
          reason: 'every export needs an explicit allowlist',
        );
        names.addAll(shown!.group(1)!.split(',').map((name) => name.trim()));
      }
      expect(
        names,
        unorderedEquals([
          'GlassStyle',
          'GlassPresets',
          'GlassQuality',
          'GlassPerformanceConfig',
          'GlassAccessibilityConfig',
          'LiquidGlassThemeData',
          'LiquidGlassTheme',
          'GlassGroup',
          'GlassSurface',
          'AnimatedGlassSurface',
          'GlassBackdrop',
          'GlassCard',
          'GlassButton',
          'GlassIconButton',
          'GlassAppBar',
          'GlassDialog',
          'showGlassDialog',
          'GlassTransition',
          'GlassMotionSpec',
          'GlassPageRoute',
        ]),
      );
      for (final directory in [
        'test',
        'example/lib',
        'example/test',
        'example/integration_test',
      ]) {
        for (final file
            in Directory(directory)
                .listSync(recursive: true)
                .whereType<File>()
                .where((file) => file.path.endsWith('.dart'))) {
          // This checker names internal paths as data; only actual directives count.
          expect(
            _uris(
              file.readAsStringSync(),
            ).where((uri) => uri.contains('/src/')),
            isEmpty,
            reason: file.path,
          );
        }
      }
    },
  );
}

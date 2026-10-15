import 'dart:io';

const _defaultLcovPath = 'coverage/lcov.info';
const _defaultOutputPath = 'coverage/pr_coverage.md';
const _defaultThreshold = 80.0;
const _defaultMinLines = 20;

Future<void> main(List<String> args) async {
  final options = _Options.fromArgs(args);
  final coverageByFile = _parseLcov(File(options.lcovPath));
  final addedLinesByFile = await _changedDartLines(options.baseRef);

  final fileResults = <_FileCoverage>[];

  for (final entry in addedLinesByFile.entries) {
    if (!_isCoverageEligiblePath(entry.key)) continue;

    final coverage = coverageByFile[entry.key];
    if (coverage == null) continue;

    var found = 0;
    var hit = 0;

    for (final line in entry.value) {
      final count = coverage[line];
      if (count == null) continue;
      found++;
      if (count > 0) hit++;
    }

    if (found > 0) {
      fileResults.add(_FileCoverage(entry.key, found, hit));
    }
  }

  fileResults.sort((a, b) => b.found.compareTo(a.found));

  final totalFound = fileResults.fold<int>(0, (sum, item) => sum + item.found);
  final totalHit = fileResults.fold<int>(0, (sum, item) => sum + item.hit);
  final percent = totalFound == 0 ? 100.0 : totalHit / totalFound * 100;
  final gateApplies = totalFound >= options.minLines;
  final passed = !gateApplies || percent >= options.threshold;

  final markdown = _buildMarkdown(
    threshold: options.threshold,
    minLines: options.minLines,
    totalFound: totalFound,
    totalHit: totalHit,
    percent: percent,
    gateApplies: gateApplies,
    passed: passed,
    fileResults: fileResults,
  );

  final output = File(options.outputPath)..parent.createSync(recursive: true);
  output.writeAsStringSync(markdown);
  stdout.writeln(markdown);

  if (!passed) {
    stderr.writeln(
      'PR coverage failed: ${percent.toStringAsFixed(2)}% '
      '< ${options.threshold.toStringAsFixed(2)}%',
    );
    exit(1);
  }
}

Map<String, Map<int, int>> _parseLcov(File file) {
  if (!file.existsSync()) {
    stderr.writeln('LCOV file not found: ${file.path}');
    exit(1);
  }

  final coverageByFile = <String, Map<int, int>>{};
  String? currentSource;

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentSource = _normalizePath(line.substring(3));
      coverageByFile.putIfAbsent(currentSource, () => <int, int>{});
      continue;
    }

    if (currentSource == null || !line.startsWith('DA:')) continue;

    final parts = line.substring(3).split(',');
    if (parts.length < 2) continue;

    final lineNumber = int.tryParse(parts[0]);
    final hitCount = int.tryParse(parts[1]);
    if (lineNumber == null || hitCount == null) continue;

    coverageByFile[currentSource]![lineNumber] = hitCount;
  }

  return coverageByFile;
}

Future<Map<String, Set<int>>> _changedDartLines(String baseRef) async {
  final result = await Process.run('git', [
    'diff',
    '--unified=0',
    '--no-ext-diff',
    '--diff-filter=AM',
    '$baseRef...HEAD',
    '--',
    '*.dart',
  ]);

  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }

  final changed = <String, Set<int>>{};
  String? currentFile;
  int? newLine;

  for (final rawLine in (result.stdout as String).split('\n')) {
    if (rawLine.startsWith('diff --git ')) {
      currentFile = null;
      newLine = null;
      continue;
    }

    if (rawLine.startsWith('+++ b/')) {
      currentFile = _normalizePath(rawLine.substring(6));
      if (!_isCoverageEligiblePath(currentFile)) {
        currentFile = null;
        continue;
      }
      changed.putIfAbsent(currentFile, () => <int>{});
      continue;
    }

    if (rawLine.startsWith('@@ ')) {
      newLine = _newLineStart(rawLine);
      continue;
    }

    if (currentFile == null || newLine == null) continue;

    if (rawLine.startsWith('+')) {
      changed[currentFile]!.add(newLine);
      newLine++;
    } else if (rawLine.startsWith('-')) {
      continue;
    } else {
      newLine++;
    }
  }

  changed.removeWhere((_, lines) => lines.isEmpty);
  return changed;
}

int _newLineStart(String hunkHeader) {
  final match = RegExp(r'\+(\d+)(?:,\d+)?').firstMatch(hunkHeader);
  if (match == null) return 0;
  return int.parse(match.group(1)!);
}

String _normalizePath(String path) {
  var normalized = path.replaceAll('\\', '/');
  final cwd = Directory.current.path.replaceAll('\\', '/');
  if (normalized.startsWith('$cwd/')) {
    normalized = normalized.substring(cwd.length + 1);
  }
  if (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  return normalized;
}

bool _isCoverageEligiblePath(String path) {
  final normalized = _normalizePath(path);
  if (!normalized.startsWith('lib/')) return false;
  if (normalized == 'lib/main.dart') return false;
  if (normalized.contains('/views/')) return false;
  if (normalized.endsWith('.g.dart')) return false;
  if (normalized.endsWith('.freezed.dart')) return false;
  if (normalized.endsWith('.mocks.dart')) return false;
  return true;
}

String _buildMarkdown({
  required double threshold,
  required int minLines,
  required int totalFound,
  required int totalHit,
  required double percent,
  required bool gateApplies,
  required bool passed,
  required List<_FileCoverage> fileResults,
}) {
  final buffer = StringBuffer()
    ..writeln('## PR Coverage')
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | ---: |')
    ..writeln('| Current coverage | ${percent.toStringAsFixed(2)}% |')
    ..writeln('| Required minimum | ${threshold.toStringAsFixed(2)}% |')
    ..writeln();

  if (!gateApplies) {
    buffer.writeln(
      'Info: the coverage rule does not block this PR because the volume of '
      'new testable lines is too low.',
    );
  } else if (passed) {
    buffer.writeln(
      'Success: coverage for new lines meets the required minimum.',
    );
  } else {
    buffer.writeln(
      'Failure: coverage for new lines is below the required minimum. '
      'Add tests or reduce uncovered lines.',
    );
  }

  if (fileResults.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('| File | Lines | Covered | Coverage |')
      ..writeln('| --- | ---: | ---: | ---: |');

    for (final result in fileResults.take(20)) {
      buffer.writeln(
        '| `${result.path}` | ${result.found} | ${result.hit} | '
        '${result.percent.toStringAsFixed(2)}% |',
      );
    }
  }

  return buffer.toString();
}

class _FileCoverage {
  final String path;
  final int found;
  final int hit;

  _FileCoverage(this.path, this.found, this.hit);

  double get percent => found == 0 ? 100.0 : hit / found * 100;
}

class _Options {
  final String lcovPath;
  final String baseRef;
  final double threshold;
  final int minLines;
  final String outputPath;

  _Options({
    required this.lcovPath,
    required this.baseRef,
    required this.threshold,
    required this.minLines,
    required this.outputPath,
  });

  factory _Options.fromArgs(List<String> args) {
    String value(String name, String fallback) {
      final index = args.indexOf(name);
      if (index == -1 || index + 1 >= args.length) return fallback;
      return args[index + 1];
    }

    return _Options(
      lcovPath: value('--lcov', _defaultLcovPath),
      baseRef: value('--base', 'origin/main'),
      threshold: double.parse(value('--threshold', '$_defaultThreshold')),
      minLines: int.parse(value('--min-lines', '$_defaultMinLines')),
      outputPath: value('--output', _defaultOutputPath),
    );
  }
}

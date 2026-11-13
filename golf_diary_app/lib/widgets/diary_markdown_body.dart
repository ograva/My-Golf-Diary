import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lightweight, zero-dependency Markdown renderer tailored for Swing Diary
/// coaching responses: headings, inline bold/italic/code, lists, horizontal
/// rules, scrollable Markdown tables, and monospace `──►` sequence diagrams.
class DiaryMarkdownBody extends StatelessWidget {
  const DiaryMarkdownBody({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();
    if (!_looksStructured(trimmed)) {
      return Text(trimmed);
    }

    final lines = trimmed.replaceAll('\r\n', '\n').split('\n');
    final blocks = <Widget>[];
    var i = 0;

    while (i < lines.length) {
      final raw = lines[i];
      final line = raw.trimRight();

      if (line.trim().isEmpty) {
        i += 1;
        continue;
      }

      if (line.trimLeft().startsWith('```')) {
        final codeLines = <String>[];
        i += 1;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          codeLines.add(lines[i]);
          i += 1;
        }
        if (i < lines.length) i += 1;
        blocks.add(_CodeDiagramBox(text: codeLines.join('\n')));
        continue;
      }

      if (_isHorizontalRule(line)) {
        blocks.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(),
        ));
        i += 1;
        continue;
      }

      if (_isTableRow(line) &&
          i + 1 < lines.length &&
          _isTableSeparator(lines[i + 1])) {
        final header = _parseTableCells(line);
        i += 2;
        final rows = <List<String>>[];
        while (i < lines.length && _isTableRow(lines[i])) {
          rows.add(_parseTableCells(lines[i]));
          i += 1;
        }
        blocks.add(_MarkdownTable(header: header, rows: rows));
        continue;
      }

      final headingMatch = RegExp(r'^(#{1,4})\s+(.+)$').firstMatch(line.trim());
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final headingText = headingMatch.group(2)!.trim();
        final textTheme = Theme.of(context).textTheme;
        final style = level <= 2 ? textTheme.titleMedium : textTheme.titleSmall;
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: _InlineMarkdownText(text: headingText, baseStyle: style),
        ));
        i += 1;
        continue;
      }

      if (_isDiagramLine(line)) {
        final diagramLines = <String>[line];
        i += 1;
        while (i < lines.length &&
            lines[i].trim().isNotEmpty &&
            _isDiagramLine(lines[i])) {
          diagramLines.add(lines[i].trimRight());
          i += 1;
        }
        blocks.add(_CodeDiagramBox(text: diagramLines.join('\n')));
        continue;
      }

      final bulletMatch =
          RegExp(r'^(\s*)([-*•]|\d+\.)\s+(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        final indent = (bulletMatch.group(1)!.length ~/ 2) * 12.0;
        final marker = bulletMatch.group(2)!;
        final itemText = bulletMatch.group(3)!.trim();
        final displayMarker =
            marker == '-' || marker == '*' ? '•' : marker;
        blocks.add(Padding(
          padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$displayMarker '),
              Expanded(child: _InlineMarkdownText(text: itemText)),
            ],
          ),
        ));
        i += 1;
        continue;
      }

      blocks.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: _InlineMarkdownText(text: line.trim()),
      ));
      i += 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }

  static bool _looksStructured(String text) {
    return text.contains('\n') ||
        text.contains('**') ||
        text.contains('`') ||
        text.contains('──►') ||
        text.startsWith('#');
  }

  static bool _isHorizontalRule(String line) {
    final t = line.trim();
    return RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(t);
  }

  static bool _isTableRow(String line) {
    final t = line.trim();
    return t.startsWith('|') && t.endsWith('|') && t.length > 2;
  }

  static bool _isTableSeparator(String line) {
    final t = line.trim();
    if (!_isTableRow(t)) return false;
    final cells = _parseTableCells(t);
    return cells.isNotEmpty &&
        cells.every((cell) => RegExp(r'^:?-{2,}:?$').hasMatch(cell));
  }

  static List<String> _parseTableCells(String line) {
    var inner = line.trim();
    if (inner.startsWith('|')) inner = inner.substring(1);
    if (inner.endsWith('|')) inner = inner.substring(0, inner.length - 1);
    return [for (final cell in inner.split('|')) cell.trim()];
  }

  static bool _isDiagramLine(String line) {
    return line.contains('──►') ||
        line.contains('──>') ||
        line.contains('-->') ||
        line.contains('┌') ||
        line.contains('└') ||
        line.contains('│');
  }
}

class _CodeDiagramBox extends StatelessWidget {
  const _CodeDiagramBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mono = GolfTextStyles.tabularNum(
      context,
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
    ).copyWith(height: 1.4);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(text, style: mono),
      ),
    );
  }
}

class _MarkdownTable extends StatelessWidget {
  const _MarkdownTable({required this.header, required this.rows});

  final List<String> header;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final colCount = [
      header.length,
      for (final row in rows) row.length,
    ].reduce((a, b) => a > b ? a : b);
    if (colCount == 0) return const SizedBox.shrink();

    List<String> pad(List<String> cells) => [
          for (var c = 0; c < colCount; c++)
            c < cells.length ? cells[c] : '',
        ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: cs.outlineVariant, width: 0.75),
          children: [
            TableRow(
              decoration: BoxDecoration(color: cs.surfaceContainerHigh),
              children: [
                for (final cell in pad(header))
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: _InlineMarkdownText(
                      text: cell,
                      baseStyle: tt.titleSmall,
                    ),
                  ),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  for (final cell in pad(row))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: _InlineMarkdownText(
                        text: cell,
                        baseStyle: tt.bodyMedium,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineMarkdownText extends StatelessWidget {
  const _InlineMarkdownText({required this.text, this.baseStyle});

  final String text;
  final TextStyle? baseStyle;

  static final RegExp _tokenPattern =
      RegExp(r'(\*\*(.+?)\*\*|`([^`]+)`|\*([^*]+)\*)');

  @override
  Widget build(BuildContext context) {
    final effectiveBase = baseStyle ?? Theme.of(context).textTheme.bodyMedium;
    if (!_tokenPattern.hasMatch(text)) {
      return Text(text, style: baseStyle);
    }

    final cs = Theme.of(context).colorScheme;
    final codeStyle = GolfTextStyles.tabularNum(
      context,
      fontSize: (effectiveBase?.fontSize ?? 14) - 1,
      fontWeight: FontWeight.w500,
    ).copyWith(backgroundColor: cs.surfaceContainerHigh);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3), style: codeStyle));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: effectiveBase, children: spans));
  }
}

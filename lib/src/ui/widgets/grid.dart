import 'package:flutter/material.dart';

class Grid extends StatelessWidget {
  const Grid.fromColumns({
    super.key,
    required this.columns,
    required this.totalWidth,
    required this.spacing,
    required this.runSpacing,
    required this.children,
  }) : baseWidth = (totalWidth - ((columns - 1) * spacing)) / columns;

  final double baseWidth;
  final double totalWidth;
  final int columns;

  final double spacing;
  final double runSpacing;

  /// (flex, widget)
  final List<(int, Widget)> children;

  @override
  Widget build(BuildContext context) {
    assert(!children.map((e) => e.$1).any((e) => e > columns));
    List<List<Widget>> rows = [[]];

    int size = 0;
    for (var e in children) {
      size += e.$1;

      Widget flex = SizedBox(width: e.$1 * baseWidth, child: e.$2);

      if (size > columns) {
        size = e.$1;
        rows.add([flex]);
      } else {
        rows.last.add(flex);
      }
    }

    return Column(
      spacing: runSpacing,
      children: rows.map((r) => Row(spacing: spacing, children: r)).toList(),
    );
  }
}

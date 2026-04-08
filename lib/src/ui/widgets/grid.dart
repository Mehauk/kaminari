import 'dart:math';

import 'package:flutter/material.dart';

class Grid extends StatefulWidget {
  const Grid({
    super.key,
    required this.spacing,
    required this.runSpacing,
    required this.children,
  });

  final double spacing;
  final double runSpacing;
  final List<Widget> children;

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  late List<GlobalKey> _childKeys;
  late List<double?> _childWidths;

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(Grid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _syncKeys();
    }
  }

  void _syncKeys() {
    _childKeys = List<GlobalKey>.generate(
      widget.children.length,
      (_) => GlobalKey(),
    );
    _childWidths = List<double?>.filled(widget.children.length, null);
  }

  void _scheduleMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureChildWidths();
    });
  }

  void _measureChildWidths() {
    final widths = <double>[];

    for (final key in _childKeys) {
      final context = key.currentContext;
      if (context == null) {
        return;
      }
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) {
        return;
      }
      widths.add(renderObject.size.width);
    }

    if (widths.isEmpty) {
      return;
    }

    final updatedWidths = widths.map((w) => w).toList();
    if (!_listEquals(_childWidths, updatedWidths)) {
      setState(() {
        _childWidths = List<double?>.from(updatedWidths);
      });
    }
  }

  bool _listEquals(List<double?> a, List<double?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool get _hasMeasuredWidths {
    return _childWidths.isNotEmpty &&
        _childWidths.every((width) => width != null);
  }

  int _columnsFor(double availableWidth) {
    if (availableWidth <= 0 || widget.children.isEmpty) {
      return 1;
    }

    final maxWidth = _childWidths.whereType<double>().fold<double>(0, max);
    if (maxWidth <= 0) {
      return 1;
    }

    final candidate =
        ((availableWidth + widget.spacing) / (maxWidth + widget.spacing))
            .floor();
    return max(1, candidate);
  }

  List<List<int>> _buildRows(double availableWidth) {
    if (widget.children.isEmpty || availableWidth <= 0) {
      return const [];
    }

    if (_hasMeasuredWidths) {
      final rows = <List<int>>[];
      var currentRow = <int>[];
      var currentRowWidth = 0.0;

      for (var index = 0; index < widget.children.length; index++) {
        final width = _childWidths[index] ?? 0;

        if (width >= availableWidth && availableWidth > 0) {
          if (currentRow.isNotEmpty) {
            rows.add(currentRow);
            currentRow = <int>[];
            currentRowWidth = 0.0;
          }
          rows.add([index]);
          continue;
        }

        if (currentRow.isEmpty) {
          currentRow = [index];
          currentRowWidth = width;
          continue;
        }

        final nextWidth = currentRowWidth + widget.spacing + width;
        if (nextWidth <= availableWidth) {
          currentRow.add(index);
          currentRowWidth = nextWidth;
        } else {
          rows.add(currentRow);
          currentRow = [index];
          currentRowWidth = width;
        }
      }

      if (currentRow.isNotEmpty) {
        rows.add(currentRow);
      }

      return rows;
    }

    final columns = _columnsFor(availableWidth);
    final rowCount = (widget.children.length / columns).ceil();
    final rows = <List<int>>[];

    for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      final start = rowIndex * columns;
      final end = min(start + columns, widget.children.length);
      rows.add(List<int>.generate(end - start, (i) => start + i));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final rows = _buildRows(availableWidth);

        if (!_hasMeasuredWidths && widget.children.isNotEmpty) {
          _scheduleMeasurement();
        }

        return Column(
          spacing: widget.runSpacing,
          crossAxisAlignment: .center,
          children: List<Widget>.generate(rows.length, (rowIndex) {
            final rowItems = rows[rowIndex];
            return SizedBox(
              width: availableWidth,
              child: Row(
                mainAxisSize: .max,
                spacing: widget.spacing,
                crossAxisAlignment: .start,
                children: rowItems.asMap().entries.map((entry) {
                  final index = entry.value;
                  final child = widget.children[index];
                  return Flexible(
                    fit: FlexFit.loose,
                    child: KeyedSubtree(key: _childKeys[index], child: child),
                  );
                }).toList(),
              ),
            );
          }),
        );
      },
    );
  }
}

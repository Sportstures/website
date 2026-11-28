import 'package:flutter/material.dart';

import '../../api/competitions_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/ui_kit.dart';

/// Points for each result, and the order in which teams level on points are separated.
class TableRulesEditor extends StatelessWidget {
  const TableRulesEditor({super.key, required this.rules, required this.onChanged});

  final TableRules rules;
  final ValueChanged<TableRules> onChanged;

  void _set({int? win, int? draw, int? loss, List<String>? order}) => onChanged(TableRules(
        win: win ?? rules.win,
        draw: draw ?? rules.draw,
        loss: loss ?? rules.loss,
        tiebreakers: order ?? rules.tiebreakers,
        custom: rules.custom,
      ));

  void _move(int from, int to) {
    final order = [...rules.tiebreakers];
    order.insert(to, order.removeAt(from));
    _set(order: order);
  }

  Widget _points(String label, int value, ValueChanged<int> onPick) => SizedBox(
        width: 110,
        child: DropdownButtonFormField<int>(
          key: ValueKey('$label-$value'),
          initialValue: value,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
          // The server accepts 0 to 10.
          items: [for (var p = 0; p <= 10; p++) DropdownMenuItem(value: p, child: Text('$p'))],
          onChanged: (v) {
            if (v != null) onPick(v);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final order = rules.tiebreakers;
    final unused = [for (final t in tiebreakerLabels.keys) if (!order.contains(t)) t];
    const heading = TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Points', style: heading),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            _points('Win', rules.win, (v) => _set(win: v)),
            _points('Draw', rules.draw, (v) => _set(draw: v)),
            _points('Loss', rules.loss, (v) => _set(loss: v)),
          ],
        ),
        const SizedBox(height: 14),
        const Text('When teams are level on points, compare', style: heading),
        const SizedBox(height: 4),
        for (final (i, t) in order.indexed)
          Row(
            key: ValueKey('tiebreaker-$t'),
            children: [
              SizedBox(width: 22, child: Text('${i + 1}.', style: tableStrongStyle)),
              Expanded(child: Text(tiebreakerLabels[t] ?? t, style: tableCellStyle)),
              IconButton(tooltip: 'Move up', icon: const Icon(Icons.arrow_upward, size: 16), onPressed: i == 0 ? null : () => _move(i, i - 1)),
              IconButton(
                  tooltip: 'Move down',
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: i == order.length - 1 ? null : () => _move(i, i + 1)),
              // At least one is needed.
              IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: order.length == 1 ? null : () => _set(order: [for (final o in order) if (o != t) o])),
            ],
          ),
        if (unused.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in unused)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 14),
                  label: Text(tiebreakerLabels[t]!),
                  onPressed: () => _set(order: [...order, t]),
                ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        const Text('Teams still level after these share a position.', style: TextStyle(fontSize: 11, color: AppColors.muted)),
        if (!rules.isStandard)
          TextButton(onPressed: () => onChanged(const TableRules()), child: const Text('Use the standard rules')),
      ],
    );
  }
}

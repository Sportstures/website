import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'ui_kit.dart';

const filterInputText = TextStyle(fontSize: 12, color: AppColors.ink);

class FilterField {
  const FilterField({required this.label, required this.child, this.flex = 2, this.wide = false});

  final String label;
  final Widget child;
  final int flex;

  /// Takes a whole row on narrow screens (e.g. search boxes).
  final bool wide;
}

/// Card of labelled filter controls with FILTER and RESET FILTERS buttons.
class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.fields,
    required this.onApply,
    required this.onReset,
  });

  final List<FilterField> fields;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final filterButton = SizedBox(
      height: 40,
      child: SiteButton(label: 'FILTER', icon: Icons.filter_list, small: true, onPressed: onApply),
    );

    final resetButton = TextButton.icon(
      onPressed: onReset,
      icon: const Icon(Icons.refresh, size: 14),
      label: const Text('RESET FILTERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(foregroundColor: AppColors.ink),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final field in fields) ...[
                      Expanded(flex: field.flex, child: _LabeledField(field)),
                      const SizedBox(width: 12),
                    ],
                    filterButton,
                  ],
                ),
                const SizedBox(height: 4),
                resetButton,
              ],
            );
          }

          const gap = 12.0;
          final half = (constraints.maxWidth - gap) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: field.wide ? constraints.maxWidth : half,
                      child: _LabeledField(field),
                    ),
                ],
              ),
              const SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: filterButton),
                  const SizedBox(width: 8),
                  resetButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField(this.field);

  final FilterField field;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        field.child,
      ],
    );
  }
}

/// 40px bordered box that filter controls sit in.
class FilterBox extends StatelessWidget {
  const FilterBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.allLabel,
  });

  final T? value;
  final List<T> options;
  final String Function(T option) labelOf;
  final ValueChanged<T?> onChanged;

  /// When set, adds a first option meaning "no filter" (null).
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    return FilterBox(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: filterInputText,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.muted),
          borderRadius: BorderRadius.circular(8),
          dropdownColor: Colors.white,
          items: [
            if (allLabel != null)
              DropdownMenuItem<T?>(value: null, child: Text(allLabel!, overflow: TextOverflow.ellipsis)),
            for (final option in options)
              DropdownMenuItem<T?>(
                value: option,
                child: Text(labelOf(option), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class FilterSearchField extends StatelessWidget {
  const FilterSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        style: filterInputText,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
          suffixIcon: const Icon(Icons.search, size: 18, color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.green),
        ),
      ),
    );
  }
}

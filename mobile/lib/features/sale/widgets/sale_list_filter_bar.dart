import 'package:flutter/material.dart';

import '../models/sale_flags.dart';

class SaleListFilterBar extends StatelessWidget {
  const SaleListFilterBar({
    super.key,
    required this.dateFromLabel,
    required this.dateToLabel,
    required this.onPickDateFrom,
    required this.onPickDateTo,
    this.selectedFlag,
    this.onlyFlagged = false,
    this.onSelectFlag,
    this.onSelectFlagged,
  });

  final String dateFromLabel;
  final String dateToLabel;
  final VoidCallback onPickDateFrom;
  final VoidCallback onPickDateTo;
  final SaleFlagKind? selectedFlag;
  final bool onlyFlagged;
  final ValueChanged<SaleFlagKind?>? onSelectFlag;
  final VoidCallback? onSelectFlagged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tarih aralığı',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateFilterButton(
                    label: dateFromLabel,
                    onPressed: onPickDateFrom,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: _DateFilterButton(
                    label: dateToLabel,
                    onPressed: onPickDateTo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Bayrak',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _FlagFilterChip(
                  label: 'Tümü',
                  selected: selectedFlag == null && !onlyFlagged,
                  onSelected: () => onSelectFlag?.call(null),
                ),
                _FlagFilterChip(
                  label: 'İşaretli',
                  selected: onlyFlagged && selectedFlag == null,
                  onSelected: () => onSelectFlagged?.call(),
                ),
                for (final style in SaleFlagStyle.values)
                  _FlagFilterChip(
                    color: style.color,
                    selected: selectedFlag == style.kind,
                    onSelected: () => onSelectFlag?.call(style.kind),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagFilterChip extends StatelessWidget {
  const _FlagFilterChip({
    required this.selected,
    required this.onSelected,
    this.label,
    this.color,
  });

  final String? label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return FilterChip(
      label: label == null
          ? Icon(Icons.flag_rounded, size: 18, color: accent)
          : Text(label!),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: accent.withValues(alpha: 0.16),
      side: BorderSide(color: selected ? accent : theme.colorScheme.outlineVariant),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? accent : null,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/sale_flags.dart';

class SaleFlagPicker extends StatelessWidget {
  const SaleFlagPicker({
    super.key,
    required this.flags,
    required this.onChanged,
    this.enabled = true,
  });

  final SaleFlags flags;
  final ValueChanged<SaleFlags> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final style in SaleFlagStyle.values)
          _FlagButton(
            style: style,
            selected: flags.contains(style.kind),
            enabled: enabled,
            onTap: () => onChanged(flags.toggle(style.kind)),
          ),
      ],
    );
  }
}

class SaleFlagMarks extends StatelessWidget {
  const SaleFlagMarks({super.key, required this.flags});

  final SaleFlags flags;

  @override
  Widget build(BuildContext context) {
    final selected = [
      for (final style in SaleFlagStyle.values)
        if (flags.contains(style.kind)) style,
    ];
    if (selected.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final style in selected)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, size: 16, color: style.color),
              const SizedBox(width: 4),
              Text(
                style.label,
                style: TextStyle(
                  color: style.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({
    required this.style,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SaleFlagStyle style;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? style.color.withValues(alpha: 0.16) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? style.color : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: style.color, size: 20),
              const SizedBox(width: 6),
              Text(
                style.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: style.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

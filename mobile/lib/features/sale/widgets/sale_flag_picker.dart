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
    return Row(
      children: [
        for (final style in SaleFlagStyle.values) ...[
          _FlagButton(
            style: style,
            selected: flags.kind == style.kind,
            enabled: enabled,
            onTap: () => onChanged(flags.select(style.kind)),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class SaleFlagMarks extends StatelessWidget {
  const SaleFlagMarks({super.key, required this.flags});

  final SaleFlags flags;

  @override
  Widget build(BuildContext context) {
    final kind = flags.kind;
    if (kind == null) return const SizedBox.shrink();

    return Icon(
      Icons.flag_rounded,
      size: 18,
      color: SaleFlagStyle.of(kind).color,
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
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.flag_rounded, color: style.color, size: 26),
        ),
      ),
    );
  }
}

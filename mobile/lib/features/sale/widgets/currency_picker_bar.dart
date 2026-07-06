import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/json_field.dart';
import '../currency_display.dart';
import '../currency_provider.dart';
import '../currency_selection.dart';

class CurrencyPickerBar extends ConsumerWidget {
  const CurrencyPickerBar({super.key, required this.onChanged});

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currenciesProvider);
    final selectedId = ref.watch(selectedCurrencyIdProvider);

    return currencies.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final options = items
            .map((c) {
              final id = c.intField('CurrencyId');
              if (id == null) return null;
              final code = c.stringField('Code') ?? '';
              return _CurrencyOption(
                id: id,
                symbol: currencySymbol(code, currencyId: id),
              );
            })
            .whereType<_CurrencyOption>()
            .toList();

        if (options.isEmpty) return const SizedBox.shrink();

        final validIds = options.map((o) => o.id).toSet();
        final effectiveId = validIds.contains(selectedId)
            ? selectedId
            : options.first.id;

        if (!validIds.contains(selectedId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedCurrencyIdProvider.notifier).state = effectiveId;
          });
        }

        final selected = options.firstWhere((o) => o.id == effectiveId);

        if (options.length <= 1) {
          return _CurrencySymbolBadge(symbol: selected.symbol);
        }

        return _CurrencySymbolButton(
          symbol: selected.symbol,
          onTap: () => _pickCurrency(context, options, effectiveId),
        );
      },
      loading: () => const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _pickCurrency(
    BuildContext context,
    List<_CurrencyOption> options,
    int selectedId,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Para birimi',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _CurrencyPickChip(
                        symbol: options[i].symbol,
                        selected: options[i].id == selectedId,
                        onTap: () => Navigator.pop(ctx, options[i].id),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) onChanged(picked);
  }
}

class _CurrencyOption {
  const _CurrencyOption({required this.id, required this.symbol});

  final int id;
  final String symbol;
}

class _CurrencySymbolBadge extends StatelessWidget {
  const _CurrencySymbolBadge({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
      child: Text(
        symbol,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _CurrencySymbolButton extends StatelessWidget {
  const _CurrencySymbolButton({required this.symbol, required this.onTap});

  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            border: Border.all(color: colorScheme.primary, width: 1.5),
          ),
          child: Center(
            child: Text(
              symbol,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyPickChip extends StatelessWidget {
  const _CurrencyPickChip({
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.85)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            symbol,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SaleDetailActionBar extends StatelessWidget {
  const SaleDetailActionBar({
    super.key,
    required this.cancelling,
    required this.onEdit,
    required this.onCancel,
  });

  final bool cancelling;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(_height)),
      maximumSize: const WidgetStatePropertyAll(Size(double.infinity, _height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      visualDensity: VisualDensity.standard,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: cancelling ? null : onCancel,
              style: buttonStyle.copyWith(
                foregroundColor: WidgetStatePropertyAll(colorScheme.error),
                side: WidgetStatePropertyAll(
                  BorderSide(color: colorScheme.error),
                ),
              ),
              icon: cancelling
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('İptal Et'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: cancelling ? null : onEdit,
              style: buttonStyle,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Düzenle'),
            ),
          ),
        ],
      ),
    );
  }
}

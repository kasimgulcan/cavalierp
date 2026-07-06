import 'package:flutter/material.dart';

class StockWarningBanner extends StatelessWidget {
  const StockWarningBanner({super.key, required this.message});

  final String message;

  static String messageFor({
    required double stockQty,
    required int quantity,
    required bool isStaff,
  }) {
    if (stockQty <= 0) {
      if (isStaff) {
        return 'Stok yok. Satış tamamlanabilir; stok eksiye düşebilir.';
      }
      return 'Stokta yok. Talep olarak ilerleyebilirsiniz.';
    }
    if (quantity > stockQty) {
      if (isStaff) {
        return 'Talep edilen adet stoktan fazla. Satış tamamlanabilir; yönetici stoku düzenler.';
      }
      return 'Talep edilen adet stoktan fazla. Talep olarak ilerleyebilirsiniz.';
    }
    return '';
  }

  static String cartSnackBarMessage({
    required double stockQty,
    required int quantity,
    required bool isStaff,
  }) {
    if (isStaff) {
      final warning = messageFor(
        stockQty: stockQty,
        quantity: quantity,
        isStaff: true,
      );
      if (warning.isNotEmpty) return '$warning Sepete eklendi.';
      return 'Sepete eklendi';
    }

    if (stockQty <= 0) {
      return 'Stokta yok; talep sepetinize eklendi.';
    }
    if (quantity > stockQty) {
      return 'Stok yetersiz; talep sepetinize eklendi.';
    }
    return 'Talep sepetinize eklendi.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_provider.dart';
import 'checkout_draft.dart';

/// Drops the in-memory edit of an existing sale. Does not call the server,
/// so the saved sale stays as it is.
void startNewSale(WidgetRef ref) {
  ref.read(editingSaleIdProvider.notifier).state = null;
  ref.read(checkoutDraftProvider.notifier).clear();
  ref.read(cartProvider.notifier).clear();
}

Future<void> confirmAndStartNewSale(
  BuildContext context,
  WidgetRef ref,
  int saleId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Yeni satış'),
      content: Text(
        'Satış #$saleId kayıtta kalır ve değiştirilmez. '
        'Bu düzenleme bırakılıp boş bir satışa geçilsin mi?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Yeni satış'),
        ),
      ],
    ),
  );
  if (confirmed == true) startNewSale(ref);
}

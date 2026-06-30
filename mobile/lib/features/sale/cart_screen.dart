import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/user_profile_provider.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total;
    final isStaff = ref.watch(isStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
      body: lines.isEmpty
          ? const Center(child: Text('Sepet boş'))
          : ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                return ListTile(
                  title: Text(line.product.displayName),
                  subtitle: Text(
                    'ID: ${line.product.sizeId} · ${line.quantity} x ${line.unitPrice.toStringAsFixed(2)}',
                  ),
                  trailing: Text(line.lineTotal.toStringAsFixed(2)),
                  onLongPress: () =>
                      ref.read(cartProvider.notifier).removeLine(line.product.sizeId),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Toplam: ${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: lines.isEmpty
                  ? null
                  : () => context.push(isStaff ? '/checkout' : '/order-checkout'),
              child: Text(isStaff ? 'Satışı Tamamla' : 'Talep Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../auth/user_profile_provider.dart';
import 'cart_provider.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'pending_order_checkout_provider.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/cart_summary_bar.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final currencyId = effectiveCurrencyId(ref.watch(selectedCurrencyIdProvider));
    final total = ref.read(cartProvider.notifier).totalFor(currencyId);
    final isStaff = ref.watch(isStaffProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbolFrom(currency);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
      body: lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sepetiniz boş',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ürünler sekmesinden sepete ürün ekleyebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: lines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => CartLineTile(line: lines[index]),
            ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : CartSummaryBar(
              itemCount: lines.length,
              totalLabel: formatCartTotal(total, symbol),
              actionLabel: isStaff ? 'İleri' : 'Talep Gönder',
              onAction: () {
                final loggedIn =
                    ref.read(authStateProvider).valueOrNull ?? false;
                final target = isStaff ? '/checkout' : '/order-checkout';
                if (!loggedIn) {
                  final encoded = Uri.encodeComponent(target);
                  context.push('/login?redirect=$encoded');
                  return;
                }
                if (isStaff) {
                  ref.read(pendingOrderCheckoutProvider.notifier).state = null;
                }
                context.push(target);
              },
            ),
    );
  }
}

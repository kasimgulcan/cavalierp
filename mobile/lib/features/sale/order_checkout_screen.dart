import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'cart_provider.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';

class OrderCheckoutScreen extends ConsumerStatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  ConsumerState<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends ConsumerState<OrderCheckoutScreen> {
  final _customer = TextEditingController();
  final _note = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _customer.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currencyId = effectiveCurrencyId(ref.read(selectedCurrencyIdProvider));

    setState(() => _loading = true);
    final result = await ref.read(cartProvider.notifier).submitOrderRequest(
          currencyId: currencyId,
          customer: _customer.text.trim().isEmpty ? null : _customer.text.trim(),
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    setState(() => _loading = false);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talep gönderilemedi')),
      );
      return;
    }

    ref.read(cartProvider.notifier).clear();
    context.go('/order-confirmed', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(selectedCurrencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Talebi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currency != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Para birimi'),
                subtitle: Text('${currency['Code']} — ${currency['Name']}'),
              ),
            TextField(
              controller: _customer,
              decoration: const InputDecoration(
                labelText: 'İsim / müşteri (opsiyonel)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Talep Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

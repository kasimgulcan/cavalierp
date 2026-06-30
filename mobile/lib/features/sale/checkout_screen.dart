import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'cart_provider.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';

final _paymentTypesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('Lookup.PaymentTypes', {});
  if (!response.success) return [];
  return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _customer = TextEditingController();
  int? _paymentTypeId;
  final _note = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _customer.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final currencyId = effectiveCurrencyId(ref.read(selectedCurrencyIdProvider));

    setState(() => _loading = true);
    final result = await ref.read(cartProvider.notifier).completeSale(
          currencyId: currencyId,
          customer: _customer.text.trim().isEmpty ? null : _customer.text.trim(),
          paymentTypeId: _paymentTypeId,
          note: _note.text,
        );
    setState(() => _loading = false);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış kaydedilemedi')),
      );
      return;
    }
    ref.read(cartProvider.notifier).clear();
    context.go('/sale-summary', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final paymentTypes = ref.watch(_paymentTypesProvider);
    final currency = ref.watch(selectedCurrencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                labelText: 'Müşteri (opsiyonel)',
                hintText: 'Yeni müşteri adı yazabilirsiniz',
              ),
            ),
            paymentTypes.when(
              data: (items) => DropdownButtonFormField<int?>(
                decoration: const InputDecoration(labelText: 'Ödeme tipi (opsiyonel)'),
                initialValue: _paymentTypeId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                  ...items.map(
                    (p) => DropdownMenuItem(
                      value: (p['PaymentTypeId'] as num).toInt(),
                      child: Text(p['Name'] as String),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _paymentTypeId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const Text('Ödeme tipleri yüklenemedi'),
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Not'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _complete,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Satışı Tamamla'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'cart_provider.dart';
import 'checkout_note.dart';
import 'checkout_discount.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'pending_order_checkout_provider.dart';
import 'order_request_provider.dart';
import 'widgets/cart_summary_bar.dart';
import 'widgets/checkout_discount_section.dart';
import 'widgets/checkout_form_section.dart';
import 'widgets/checkout_line_tile.dart';

final _paymentTypesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('Lookup.PaymentTypes', {});
  if (!response.success) return [];
  return (response.data as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _customer = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  int? _paymentTypeId;
  final _note = TextEditingController();
  bool _loading = false;
  bool _prefilled = false;
  CheckoutDiscountInput _discount = const CheckoutDiscountInput();

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  void _applyPendingCheckout(PendingOrderCheckout pending) {
    if (_prefilled) return;
    _prefilled = true;
    _customer.text = pending.customer ?? '';
    _phone.text = pending.phone ?? '';
    _email.text = pending.email ?? '';
    _note.text = pending.note ?? '';
  }

  Future<void> _complete() async {
    final currencyId = effectiveCurrencyId(ref.read(selectedCurrencyIdProvider));
    final pending = ref.read(pendingOrderCheckoutProvider);
    final subtotal = ref.read(cartProvider.notifier).totalFor(currencyId);

    setState(() => _loading = true);
    final result = await ref.read(cartProvider.notifier).completeSale(
          currencyId: currencyId,
          customer: _customer.text.trim().isEmpty ? null : _customer.text.trim(),
          paymentTypeId: _paymentTypeId,
          note: buildCheckoutNote(
            note: _note.text,
            phone: _phone.text,
            email: _email.text,
          ),
          orderRequestId: pending?.orderRequestId,
          discountPercent: _discount.percent,
          discountFixedAmount: _discount.fixedAmount,
        );
    setState(() => _loading = false);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış kaydedilemedi')),
      );
      return;
    }
    ref.read(pendingOrderCheckoutProvider.notifier).state = null;
    ref.read(cartProvider.notifier).clear();
    if (pending != null) {
      ref.invalidate(orderDetailProvider(pending.orderRequestId));
    }
    context.go('/sale-summary', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final paymentTypes = ref.watch(_paymentTypesProvider);
    final lines = ref.watch(cartProvider);
    final pending = ref.watch(pendingOrderCheckoutProvider);
    if (pending != null) {
      _applyPendingCheckout(pending);
    }
    final currencyId = effectiveCurrencyId(ref.watch(selectedCurrencyIdProvider));
    final subtotal = ref.read(cartProvider.notifier).totalFor(currencyId);
    final discountTotal = _discount.totalDiscountAmount(subtotal);
    final total = _discount.grandTotal(subtotal);
    final currency = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbolFrom(currency);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_loading) {
          ref.read(pendingOrderCheckoutProvider.notifier).state = null;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            pending == null ? 'Satış' : 'Talep #${pending.orderRequestId} → Satış',
          ),
        ),
        body: lines.isEmpty
            ? const Center(child: Text('Sepet boş'))
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        CheckoutFormSection(
                          title: 'Müşteri',
                          children: [
                            TextField(
                              controller: _customer,
                              decoration: const InputDecoration(
                                labelText: 'Müşteri adı (opsiyonel)',
                                hintText: 'Yeni müşteri adı yazabilirsiniz',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefon (opsiyonel)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'E-posta (opsiyonel)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CheckoutFormSection(
                          title: 'Ödeme',
                          children: [
                            paymentTypes.when(
                              data: (items) => DropdownButtonFormField<int?>(
                                decoration: const InputDecoration(
                                  labelText: 'Ödeme tipi (opsiyonel)',
                                  border: OutlineInputBorder(),
                                ),
                                initialValue: _paymentTypeId,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Seçilmedi'),
                                  ),
                                  ...items.map(
                                    (p) => DropdownMenuItem(
                                      value: (p['PaymentTypeId'] as num).toInt(),
                                      child: Text(p['Name'] as String),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _paymentTypeId = v),
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) =>
                                  const Text('Ödeme tipleri yüklenemedi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kalemler',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...lines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CheckoutLineTile(line: line),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckoutFormSection(
                          title: 'Not',
                          children: [
                            TextField(
                              controller: _note,
                              minLines: 4,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: 'Not (opsiyonel)',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CheckoutDiscountSection(
                          subtotal: subtotal,
                          onDiscountChanged: (value) =>
                              setState(() => _discount = value),
                        ),
                      ],
                    ),
                  ),
                  CartSummaryBar(
                    itemCount: lines.length,
                    subtotalLabel: formatCartTotal(subtotal, symbol),
                    discountAmount:
                        discountTotal > 0 ? discountTotal : null,
                    discountSymbol: symbol,
                    totalLabel: formatCartTotal(total, symbol),
                    actionLabel: _loading ? 'Kaydediliyor…' : 'Satışı Tamamla',
                    enabled: !_loading,
                    onAction: _loading ? null : _complete,
                  ),
                ],
              ),
      ),
    );
  }
}

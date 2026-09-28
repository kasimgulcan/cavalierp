import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'cart_provider.dart';
import 'checkout_note.dart';
import 'checkout_discount.dart';
import 'checkout_draft.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'home_shell_tab_provider.dart';
import 'pending_order_checkout_provider.dart';
import 'order_request_provider.dart';
import 'sale_provider.dart';
import 'models/sale_flags.dart';
import 'sale_session.dart';
import 'widgets/cart_summary_bar.dart';
import 'widgets/sale_flag_picker.dart';
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
  SaleFlags _flags = const SaleFlags();
  final _note = TextEditingController();
  bool _loading = false;
  bool _prefilled = false;
  CheckoutDiscountInput _discount = const CheckoutDiscountInput();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(checkoutDraftProvider);
    _customer.text = draft.customer;
    _phone.text = draft.phone;
    _email.text = draft.email;
    _note.text = draft.note;
    _paymentTypeId = draft.paymentTypeId;
    _flags = draft.flags;
    _discount = draft.discount;
  }

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  void _saveDraft() {
    ref.read(checkoutDraftProvider.notifier).replace(
          CheckoutDraft(
            customer: _customer.text,
            phone: _phone.text,
            email: _email.text,
            note: _note.text,
            paymentTypeId: _paymentTypeId,
            discount: _discount,
            flags: _flags,
          ),
        );
  }

  void _applyPendingCheckout(PendingOrderCheckout pending) {
    if (_prefilled) return;
    _prefilled = true;
    _customer.text = pending.customer ?? '';
    _phone.text = pending.phone ?? '';
    _email.text = pending.email ?? '';
    _note.text = pending.note ?? '';
    _saveDraft();
  }

  void _goAddProducts() {
    _saveDraft();
    ref.read(homeShellTabProvider.notifier).state = kHomeShellProductsTabIndex;
    context.go('/home');
  }

  void _resetLocalForm() {
    if (!mounted) return;
    _customer.clear();
    _phone.clear();
    _email.clear();
    _note.clear();
    setState(() {
      _paymentTypeId = null;
      _flags = const SaleFlags();
      _discount = const CheckoutDiscountInput();
      _prefilled = true;
    });
  }

  Future<void> _complete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final lines = ref.read(cartProvider);
        final currencyId =
            effectiveCurrencyId(ref.read(selectedCurrencyIdProvider));
        final subtotal = ref.read(cartProvider.notifier).totalFor(currencyId);
        final total = _discount.grandTotal(subtotal);
        final currency = ref.read(selectedCurrencyProvider);
        final symbol = currencySymbolFrom(currency);
        final customer = _customer.text.trim();
        final editingId = ref.read(editingSaleIdProvider);
        return AlertDialog(
          title: Text(
            editingId == null ? 'Satışı tamamla?' : 'Satışı güncelle?',
          ),
          content: Text(
            [
              if (customer.isNotEmpty) customer,
              '${lines.length} kalem',
              formatCartTotal(total, symbol),
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(editingId == null ? 'Tamamla' : 'Kaydet'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final currencyId = effectiveCurrencyId(ref.read(selectedCurrencyIdProvider));
    final pending = ref.read(pendingOrderCheckoutProvider);
    final editingId = ref.read(editingSaleIdProvider);

    setState(() => _loading = true);
    final result = editingId == null
        ? await ref.read(cartProvider.notifier).completeSale(
              currencyId: currencyId,
              customer:
                  _customer.text.trim().isEmpty ? null : _customer.text.trim(),
              paymentTypeId: _paymentTypeId,
              note: buildCheckoutNote(
                note: _note.text,
                phone: _phone.text,
                email: _email.text,
              ),
              orderRequestId: pending?.orderRequestId,
              discountPercent: _discount.percent,
              discountFixedAmount: _discount.fixedAmount,
              flags: _flags,
            )
        : await ref.read(cartProvider.notifier).updateSale(
              saleId: editingId,
              currencyId: currencyId,
              customer:
                  _customer.text.trim().isEmpty ? null : _customer.text.trim(),
              paymentTypeId: _paymentTypeId,
              note: buildCheckoutNote(
                note: _note.text,
                phone: _phone.text,
                email: _email.text,
              ),
              discountPercent: _discount.percent,
              discountFixedAmount: _discount.fixedAmount,
              flags: _flags,
            );
    setState(() => _loading = false);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editingId == null
                ? 'Satış kaydedilemedi'
                : 'Satış güncellenemedi',
          ),
        ),
      );
      return;
    }
    ref.read(pendingOrderCheckoutProvider.notifier).state = null;
    ref.read(editingSaleIdProvider.notifier).state = null;
    ref.read(checkoutDraftProvider.notifier).clear();
    ref.read(cartProvider.notifier).clear();
    if (pending != null) {
      ref.invalidate(orderDetailProvider(pending.orderRequestId));
    }
    if (editingId != null) {
      ref.invalidate(saleDetailProvider(editingId));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/sales/$editingId');
      }
      return;
    }
    for (final entry in _flags.toParams().entries) {
      result.putIfAbsent(entry.key, () => entry.value);
    }
    context.go('/sale-summary', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(editingSaleIdProvider, (previous, next) {
      if (previous != null && next == null) {
        _resetLocalForm();
      }
    });

    final paymentTypes = ref.watch(_paymentTypesProvider);
    final lines = ref.watch(cartProvider);
    final pending = ref.watch(pendingOrderCheckoutProvider);
    final editingId = ref.watch(editingSaleIdProvider);
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
          _saveDraft();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editingId != null
                ? 'Satış #$editingId düzenle'
                : pending == null
                    ? 'Satış'
                    : 'Talep #${pending.orderRequestId} → Satış',
          ),
          actions: [
            TextButton(
              onPressed: _goAddProducts,
              child: const Text('Ürün ekle'),
            ),
          ],
        ),
        body: lines.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sepet boş'),
                    if (editingId != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => confirmAndStartNewSale(
                                  context,
                                  ref,
                                  editingId,
                                ),
                        child: const Text('Yeni satış'),
                      ),
                    ],
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        if (editingId != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Satış #$editingId güncellenecek.',
                                ),
                              ),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => confirmAndStartNewSale(
                                          context,
                                          ref,
                                          editingId,
                                        ),
                                child: const Text('Yeni satış'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        CheckoutFormSection(
                          title: 'Müşteri',
                          children: [
                            TextField(
                              controller: _customer,
                              onChanged: (_) => _saveDraft(),
                              decoration: const InputDecoration(
                                labelText: 'Müşteri adı (opsiyonel)',
                                hintText: 'Yeni müşteri adı yazabilirsiniz',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phone,
                              onChanged: (_) => _saveDraft(),
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefon (opsiyonel)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _email,
                              onChanged: (_) => _saveDraft(),
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
                                onChanged: (v) {
                                  setState(() => _paymentTypeId = v);
                                  _saveDraft();
                                },
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) =>
                                  const Text('Ödeme tipleri yüklenemedi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CheckoutFormSection(
                          title: 'Bayrak',
                          children: [
                            SaleFlagPicker(
                              flags: _flags,
                              onChanged: (flags) {
                                setState(() => _flags = flags);
                                _saveDraft();
                              },
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
                              onChanged: (_) => _saveDraft(),
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
                          initialDiscount: _discount,
                          onDiscountChanged: (value) {
                            setState(() => _discount = value);
                            _saveDraft();
                          },
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
                    actionLabel: _loading
                        ? 'Kaydediliyor…'
                        : editingId == null
                            ? 'Satışı Tamamla'
                            : 'Satışı Kaydet',
                    enabled: !_loading,
                    onAction: _loading ? null : _complete,
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'checkout_note.dart';
import 'cart_provider.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/cart_summary_bar.dart';
import 'widgets/checkout_form_section.dart';

class OrderCheckoutScreen extends ConsumerStatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  ConsumerState<OrderCheckoutScreen> createState() =>
      _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends ConsumerState<OrderCheckoutScreen> {
  final _customer = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _note = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currencyId = effectiveCurrencyId(ref.read(selectedCurrencyIdProvider));

    setState(() => _loading = true);
    final result = await ref.read(cartProvider.notifier).submitOrderRequest(
          currencyId: currencyId,
          customer: _customer.text.trim().isEmpty ? null : _customer.text.trim(),
          note: buildCheckoutNote(
            note: _note.text,
            phone: _phone.text,
            email: _email.text,
          ),
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
    final lines = ref.watch(cartProvider);
    final currencyId = effectiveCurrencyId(ref.watch(selectedCurrencyIdProvider));
    final total = ref.read(cartProvider.notifier).totalFor(currencyId);
    final currency = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbolFrom(currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Talep')),
      body: lines.isEmpty
          ? const Center(child: Text('Sepet boş'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      CheckoutFormSection(
                        title: 'İletişim bilgileri',
                        children: [
                          TextField(
                            controller: _customer,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'İsim / firma (opsiyonel)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Telefon (opsiyonel)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'E-posta (opsiyonel)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sepetiniz',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CartLineTile(line: line),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CheckoutFormSection(
                        title: 'Not',
                        children: [
                          TextField(
                            controller: _note,
                            minLines: 5,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Talep notu (opsiyonel)',
                              hintText: 'Beden, teslimat veya özel istekleriniz…',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CartSummaryBar(
                  itemCount: lines.length,
                  totalLabel: formatCartTotal(total, symbol),
                  actionLabel: _loading ? 'Gönderiliyor…' : 'Talep Gönder',
                  enabled: !_loading,
                  onAction: _loading ? null : _submit,
                ),
              ],
            ),
    );
  }
}

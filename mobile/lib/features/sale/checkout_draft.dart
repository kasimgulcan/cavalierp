import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'checkout_discount.dart';
import 'models/sale_flags.dart';

class CheckoutDraft {
  const CheckoutDraft({
    this.customer = '',
    this.phone = '',
    this.email = '',
    this.note = '',
    this.paymentTypeId,
    this.discount = const CheckoutDiscountInput(),
    this.flags = const SaleFlags(),
  });

  final String customer;
  final String phone;
  final String email;
  final String note;
  final int? paymentTypeId;
  final CheckoutDiscountInput discount;
  final SaleFlags flags;

  bool get hasUserInput =>
      customer.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      note.trim().isNotEmpty ||
      paymentTypeId != null ||
      discount.percent > 0 ||
      discount.fixedAmount != 0 ||
      flags.any;
}

class CheckoutDraftNotifier extends StateNotifier<CheckoutDraft> {
  CheckoutDraftNotifier() : super(const CheckoutDraft());

  void replace(CheckoutDraft draft) => state = draft;

  void clear() => state = const CheckoutDraft();
}

final checkoutDraftProvider =
    StateNotifierProvider<CheckoutDraftNotifier, CheckoutDraft>((ref) {
  final notifier = CheckoutDraftNotifier();
  ref.listen(authStateProvider, (previous, next) {
    if (next.valueOrNull != true) notifier.clear();
  });
  return notifier;
});

final editingSaleIdProvider = StateProvider<int?>((ref) => null);

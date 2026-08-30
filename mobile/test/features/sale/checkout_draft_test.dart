import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/checkout_discount.dart';
import 'package:cavalierp/features/sale/checkout_draft.dart';

void main() {
  test('empty checkout draft is unused', () {
    expect(const CheckoutDraft().hasUserInput, isFalse);
  });

  test('draft with customer or discount is kept across navigation', () {
    const draft = CheckoutDraft(
      customer: 'Ayşe',
      phone: '0555',
      discount: CheckoutDiscountInput(percent: 10),
    );
    expect(draft.hasUserInput, isTrue);
    expect(draft.customer, 'Ayşe');
    expect(draft.discount.percent, 10);
  });
}

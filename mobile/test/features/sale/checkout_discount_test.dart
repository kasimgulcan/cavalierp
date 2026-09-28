import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/core/format/price_format.dart';
import 'package:cavalierp/features/sale/checkout_discount.dart';
import 'package:cavalierp/features/sale/models/cart_line.dart';
import 'package:cavalierp/features/sale/models/product.dart';
import 'package:cavalierp/features/sale/currency_selection.dart';

Product _product({required int sizeId, required double price}) => Product(
      sizeId: sizeId,
      productName: 'Ürün $sizeId',
      priceTL: price,
      priceEUR: price,
      priceUSD: price,
      stockQty: 10,
    );

void main() {
  test('roundSaleMoney rounds to kuruş', () {
    expect(roundSaleMoney(21.044), 21.04);
    expect(roundSaleMoney(21.045), 21.05);
  });

  test('formatDiscountField leaves zero empty', () {
    expect(formatDiscountField(0), '');
    expect(formatDiscountField(10), '10');
    expect(formatDiscountField(21.04), isNotEmpty);
  });

  test('percent discount only', () {
    const input = CheckoutDiscountInput(percent: 10);
    expect(input.percentDiscountAmount(1000), 100);
    expect(input.fixedDiscountAmount(1000), 0);
    expect(input.totalDiscountAmount(1000), 100);
    expect(input.grandTotal(1000), 900);
  });

  test('fixed amount discount only', () {
    const input = CheckoutDiscountInput(fixedAmount: 50);
    expect(input.totalDiscountAmount(1000), 50);
    expect(input.grandTotal(1000), 950);
  });

  test('negative fixed amount rounds the discounted total up', () {
    const input = CheckoutDiscountInput(percent: 20, fixedAmount: -8);
    expect(input.percentDiscountAmount(12090), 2418);
    expect(input.fixedDiscountAmount(12090), -8);
    expect(input.grandTotal(12090), 9680);
  });

  test('negative adjustment cannot raise the total above the list price', () {
    const input = CheckoutDiscountInput(percent: 20, fixedAmount: -99999);
    expect(input.grandTotal(12090), 12090);
  });

  test('percent then fixed amount on remaining subtotal', () {
    const input = CheckoutDiscountInput(percent: 10, fixedAmount: 5000);
    expect(input.percentDiscountAmount(100000), 10000);
    expect(input.subtotalAfterPercent(100000), 90000);
    expect(input.fixedDiscountAmount(100000), 5000);
    expect(input.totalDiscountAmount(100000), 15000);
    expect(input.grandTotal(100000), 85000);
  });

  test('buildRoundedUnitPrices matches target total after discount', () {
    final lines = [
      CartLine(product: _product(sizeId: 1, price: 25000), quantity: 1),
      CartLine(product: _product(sizeId: 2, price: 24000), quantity: 1),
      CartLine(product: _product(sizeId: 3, price: 25000), quantity: 1),
    ];
    const discount = 6000.0;
    const subtotal = 74000.0;
    final target = roundSaleMoney(subtotal - discount);

    final unitPrices = buildRoundedUnitPrices(
      lines: lines,
      currencyId: kDefaultCurrencyId,
      discountAmount: discount,
    );

    var total = 0.0;
    for (var i = 0; i < lines.length; i++) {
      total = roundSaleMoney(
        total + lineTotalFromUnitPrice(unitPrices[i], lines[i].quantity),
      );
    }

    expect(target, 68000);
    expect(total, target);
  });

  test('buildRoundedSaleLinesPayload without discount uses rounded unit prices', () {
    final lines = [
      CartLine(
        product: _product(sizeId: 1, price: 33333.34),
        quantity: 3,
        unitPriceOverride: 33333.34,
      ),
    ];

    final payload = buildRoundedSaleLinesPayload(
      lines: lines,
      currencyId: kDefaultCurrencyId,
      discountAmount: 0,
    );

    expect(payload.first['UnitPrice'], 33333.34);
    expect(
      lineTotalFromUnitPrice(payload.first['UnitPrice'] as double, 3),
      100000.02,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/models/cart_line.dart';
import 'package:cavalierp/features/sale/models/product.dart';
import 'package:cavalierp/features/sale/currency_selection.dart';

void main() {
  test('CartLine lineTotal uses selected currency price', () {
    final line = CartLine(
      product: Product(
        sizeId: 1,
        productName: 'Gömlek - M',
        priceTL: 100,
        priceEUR: 10,
        priceUSD: 12,
        stockQty: 5,
      ),
      quantity: 3,
    );
    expect(line.lineTotalFor(kEurCurrencyId), 30);
  });

  test('CartLine respects unit price override', () {
    final line = CartLine(
      product: Product(
        sizeId: 1,
        productName: 'Gömlek - M',
        priceTL: 100,
        priceEUR: 10,
        priceUSD: 12,
        stockQty: 5,
      ),
      quantity: 2,
      unitPriceOverride: 8,
    );
    expect(line.lineTotalFor(kEurCurrencyId), 16);
  });
}

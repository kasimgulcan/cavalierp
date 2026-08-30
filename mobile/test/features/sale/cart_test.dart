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

  test('gift line uses zero unit price and keeps list price', () {
    final line = CartLine(
      product: Product(
        sizeId: 1,
        productName: 'Hediye pantolon',
        priceTL: 100,
        priceEUR: 10,
        priceUSD: 12,
        stockQty: 5,
      ),
      quantity: 1,
      isGift: true,
    );
    expect(line.unitPriceFor(kDefaultCurrencyId), 0);
    expect(line.listPriceFor(kDefaultCurrencyId), 100);
    expect(line.lineTotalFor(kDefaultCurrencyId), 0);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/models/product.dart';
import 'package:cavalierp/features/sale/currency_selection.dart';

void main() {
  test('Product.fromJson reads all currency prices', () {
    final product = Product.fromJson({
      'SizeId': 1,
      'ProductName': 'Rug',
      'PriceTL': 100,
      'PriceEUR': 10,
      'PriceUSD': 12,
      'StockQty': 5,
    });

    expect(product.priceFor(kDefaultCurrencyId), 100);
    expect(product.priceFor(kEurCurrencyId), 10);
    expect(product.priceFor(kUsdCurrencyId), 12);
  });

  test('Product.fromJson supports legacy single-currency rows', () {
    final product = Product.fromJson({
      'SizeId': 2,
      'ProductName': 'Rug',
      'UnitPrice': 50,
      'CurrencyId': kEurCurrencyId,
      'StockQty': 1,
    });

    expect(product.priceFor(kEurCurrencyId), 50);
    expect(product.priceFor(kDefaultCurrencyId), 0);
  });
}

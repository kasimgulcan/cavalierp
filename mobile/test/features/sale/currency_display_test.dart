import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/currency_display.dart';
import 'package:cavalierp/features/sale/currency_selection.dart';

void main() {
  test('currencySymbol maps common codes to symbols', () {
    expect(currencySymbol('TRY'), '₺');
    expect(currencySymbol('TL'), '₺');
    expect(currencySymbol('EUR'), '€');
    expect(currencySymbol('USD'), r'$');
    expect(currencySymbol('GBP'), '£');
  });

  test('currencySymbol falls back safely for missing code', () {
    expect(currencySymbol(null), '₺');
    expect(currencySymbol(''), '₺');
    expect(currencySymbol('  '), '₺');
    expect(currencySymbol('XYZ'), 'XYZ');
  });

  test('currencySymbolFrom uses currency map', () {
    expect(
      currencySymbolFrom({
        'CurrencyId': kDefaultCurrencyId,
        'Code': 'TRY',
      }),
      '₺',
    );
    expect(
      currencySymbolFrom({
        'CurrencyId': 2,
        'Code': 'EUR',
      }),
      '€',
    );
    expect(currencySymbolFrom(null), '₺');
  });
}

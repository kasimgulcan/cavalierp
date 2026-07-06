import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/core/format/price_format.dart';

void main() {
  test('formatPrice uses Turkish thousand separator', () {
    expect(formatPrice(1234.56), '1.234,56');
    expect(formatPrice(1000000), '1.000.000,00');
    expect(formatPriceWithSymbol(99.5, '€'), '99,50 €');
    expect(formatPrice(roundSaleMoney(73999.98), decimals: 0), '74.000');
  });

  test('roundSaleMoney rounds to whole lira', () {
    expect(roundSaleMoney(73999.98), 74000);
  });

  test('parseDecimalInput accepts comma decimals', () {
    expect(parseDecimalInput('99,50'), 99.5);
    expect(parseDecimalInput('1.234,56'), 1234.56);
    expect(parseDecimalInput('100'), 100);
  });

  test('parseDecimalInput returns null for empty input', () {
    expect(parseDecimalInput(''), isNull);
    expect(parseDecimalInput('   '), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/core/format/price_format.dart';

void main() {
  test('formatPrice uses Turkish thousand separator', () {
    expect(formatPrice(1234.56), '1.234,56');
    expect(formatPrice(1000000), '1.000.000,00');
    expect(formatPriceWithSymbol(99.5, '€'), '99,50 €');
    expect(formatPrice(roundSaleMoney(21.044), decimals: 2), '21,04');
  });

  test('roundSaleMoney rounds to kuruş', () {
    expect(roundSaleMoney(21.044), 21.04);
    expect(roundSaleMoney(21.045), 21.05);
    expect(roundSaleMoney(73999.984), 73999.98);
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

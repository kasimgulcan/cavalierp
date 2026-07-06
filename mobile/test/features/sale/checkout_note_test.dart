import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/checkout_note.dart';

void main() {
  test('buildCheckoutNote combines contact fields and note', () {
    expect(
      buildCheckoutNote(
        phone: '555 123 4567',
        email: 'a@b.com',
        note: 'Acil teslim',
      ),
      'Telefon: 555 123 4567\n'
      'E-posta: a@b.com\n'
      '\n'
      'Acil teslim',
    );
  });

  test('buildCheckoutNote returns empty for blank input', () {
    expect(buildCheckoutNote(), '');
  });

  test('parseCheckoutNote extracts contact fields and note', () {
    final parsed = parseCheckoutNote(
      'Telefon: 05054821065\n'
      'E-posta: kasimgulcan@\n'
      '\n'
      'test',
    );

    expect(parsed.phone, '05054821065');
    expect(parsed.email, 'kasimgulcan@');
    expect(parsed.note, 'test');
  });

  test('parseCheckoutNote returns empty for blank input', () {
    expect(parseCheckoutNote(null), const ParsedCheckoutNote());
    expect(parseCheckoutNote('   '), const ParsedCheckoutNote());
  });
}

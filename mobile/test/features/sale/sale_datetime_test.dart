import 'package:cavalierp/features/sale/sale_datetime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatSaleDateTime keeps the local clock', () {
    final value = DateTime(2026, 10, 5, 0, 30);

    expect(formatSaleDateTime(value), '2026-10-05 00:30:00');
  });

  test('future moments are rejected and now is allowed', () {
    final now = DateTime(2026, 10, 5, 14, 15);

    expect(isFutureSaleDateTime(now, now), isFalse);
    expect(isFutureSaleDateTime(now.subtract(const Duration(minutes: 1)), now), isFalse);
    expect(isFutureSaleDateTime(now.add(const Duration(minutes: 1)), now), isTrue);
  });

  test('an untouched sale sends the save moment', () {
    final now = DateTime(2026, 10, 5, 0, 30, 12);
    final stored = DateTime(2026, 10, 4, 18, 5, 9);

    expect(saleDateTimeToSend(now: now), now);
    expect(saleDateTimeToSend(chosen: stored, now: now), stored);
    expect(formatSaleDateTime(saleDateTimeToSend(chosen: stored, now: now)), '2026-10-04 18:05:09');
  });

  test('picking a day or time keeps the other part and clears seconds', () {
    final shown = DateTime(2026, 10, 5, 0, 30, 45);

    expect(
      saleDateTimeWithPickedDate(shown, DateTime(2026, 10, 4)),
      DateTime(2026, 10, 4, 0, 30),
    );
    expect(
      saleDateTimeWithPickedTime(shown, 16, 45),
      DateTime(2026, 10, 5, 16, 45),
    );
  });
}

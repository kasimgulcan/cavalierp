import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/widgets/stock_warning_banner.dart';

void main() {
  group('StockWarningBanner.messageFor', () {
    test('staff sees sale allowance when stock is zero', () {
      expect(
        StockWarningBanner.messageFor(
          stockQty: 0,
          quantity: 1,
          isStaff: true,
        ),
        contains('Satış tamamlanabilir'),
      );
    });

    test('member sees request wording when stock is zero', () {
      expect(
        StockWarningBanner.messageFor(
          stockQty: 0,
          quantity: 1,
          isStaff: false,
        ),
        'Stokta yok. Talep olarak ilerleyebilirsiniz.',
      );
      expect(
        StockWarningBanner.messageFor(
          stockQty: 0,
          quantity: 1,
          isStaff: false,
        ),
        isNot(contains('Satışa izin')),
      );
    });

    test('member sees request wording when quantity exceeds stock', () {
      expect(
        StockWarningBanner.messageFor(
          stockQty: 2,
          quantity: 5,
          isStaff: false,
        ),
        'Talep edilen adet stoktan fazla. Talep olarak ilerleyebilirsiniz.',
      );
    });
  });

  group('StockWarningBanner.cartSnackBarMessage', () {
    test('member out of stock uses talep sepet wording', () {
      expect(
        StockWarningBanner.cartSnackBarMessage(
          stockQty: 0,
          quantity: 1,
          isStaff: false,
        ),
        'Stokta yok; talep sepetinize eklendi.',
      );
    });

    test('staff keeps sale cart wording', () {
      expect(
        StockWarningBanner.cartSnackBarMessage(
          stockQty: 5,
          quantity: 1,
          isStaff: true,
        ),
        'Sepete eklendi',
      );
    });
  });
}

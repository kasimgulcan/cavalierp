import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/models/sales_report.dart';

void main() {
  test('SalesReport groups rows by product code and sums totals', () {
    final report = SalesReport.fromRows([
      {
        'Product': 'Gömlek - M',
        'StyleName': 'Classic',
        'ProductCode': 'CODE-1',
        'Color': 'Mavi',
        'SizeId': 1,
        'SizeLabel': 'M',
        'Quantity': 2,
        'Amount': 200,
      },
      {
        'Product': 'Gömlek - L',
        'StyleName': 'Classic',
        'ProductCode': 'CODE-1',
        'Color': 'Mavi',
        'SizeId': 2,
        'SizeLabel': 'L',
        'Quantity': 1,
        'Amount': 110,
      },
      {
        'Product': 'Pantolon - 32',
        'StyleName': 'Denim',
        'ProductCode': 'CODE-2',
        'SizeId': 3,
        'SizeLabel': '32',
        'Quantity': 3,
        'Amount': 450,
      },
    ]);

    expect(report.products, hasLength(2));
    expect(report.totalQuantity, 6);
    expect(report.totalAmount, 760);

    final shirt = report.products.firstWhere((g) => g.productCode == 'CODE-1');
    expect(shirt.totalQuantity, 3);
    expect(shirt.totalAmount, 310);
    expect(shirt.sizes, hasLength(2));
  });
}

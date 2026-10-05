import 'package:cavalierp/features/sale/models/sale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sale line shows catalog name and size instead of the stored code', () {
    final line = SaleLine.fromJson({
      'SaleLineId': 768,
      'SizeId': 43,
      'Product': 'H.RUGFL_FLC0002_FLC0001BRWRGL_L',
      'Quantity': 1,
      'UnitPrice': 100,
      'ListPrice': 100,
      'ProductName': 'FLEECE BLANKET WITH COLLAR',
      'StyleName': 'WINDSOR',
      'Size': 'L',
      'ProductCode': 'H.RUGFL_FLC0002_FLC0001BRWRGL',
      'Color': 'BROWN/ROSE GOLD',
    });

    expect(line.displayName, 'FLEECE BLANKET WITH COLLAR');
    expect(line.product, 'H.RUGFL_FLC0002_FLC0001BRWRGL_L');
    expect(line.sizeLabel, 'L');
    expect(line.styleName, 'WINDSOR');
    expect(line.color, 'BROWN/ROSE GOLD');
    expect(line.productCode, 'H.RUGFL_FLC0002_FLC0001BRWRGL');
  });

  test('sale line keeps the stored product when the catalog name is missing', () {
    final line = SaleLine.fromJson({
      'SaleLineId': 1,
      'SizeId': 1,
      'Product': 'HEADBAND',
      'Quantity': 2,
      'UnitPrice': 50,
      'ListPrice': 50,
    });

    expect(line.displayName, 'HEADBAND');
    expect(line.sizeLabel, isNull);
    expect(line.productCode, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/models/product.dart';
import 'package:cavalierp/features/sale/models/product_group.dart';

Product _product({
  required int sizeId,
  required String productName,
  double price = 100,
  double stockQty = 5,
  String? styleName,
  String? color,
  String? sizeLabel,
  String? productCode,
}) =>
    Product(
      sizeId: sizeId,
      productName: productName,
      priceTL: price,
      priceEUR: price,
      priceUSD: price,
      stockQty: stockQty,
      styleName: styleName,
      color: color,
      sizeLabel: sizeLabel,
      productCode: productCode,
    );

void main() {
  test('ProductGroup groups sizes by ProductCode', () {
    final products = [
      _product(
        sizeId: 1,
        productName: 'Gömlek',
        styleName: 'Classic',
        color: 'Mavi',
        sizeLabel: 'M',
        productCode: 'CODE-1',
      ),
      _product(
        sizeId: 2,
        productName: 'Gömlek',
        stockQty: 3,
        styleName: 'Classic',
        color: 'Mavi',
        sizeLabel: 'L',
        productCode: 'CODE-1',
      ),
      _product(
        sizeId: 3,
        productName: 'Pantolon',
        price: 200,
        stockQty: 1,
        productCode: 'CODE-2',
      ),
    ];

    final groups = ProductGroup.fromProducts(products);

    expect(groups, hasLength(2));

    final shirtGroup = groups.firstWhere((g) => g.productCode == 'CODE-1');
    expect(shirtGroup.sizeCount, 2);
    expect(shirtGroup.sizes.map((p) => p.sizeLabel), ['L', 'M']);
    expect(shirtGroup.totalStock, 8);
    expect(shirtGroup.allSizesOutOfStock, isFalse);
  });

  test('ProductGroup allSizesOutOfStock is true when every size is empty', () {
    final group = ProductGroup(
      key: 'CODE-1',
      sizes: [
        _product(
          sizeId: 1,
          productName: 'Gömlek',
          stockQty: 0,
          sizeLabel: 'M',
          productCode: 'CODE-1',
        ),
        _product(
          sizeId: 2,
          productName: 'Gömlek',
          stockQty: 0,
          sizeLabel: 'L',
          productCode: 'CODE-1',
        ),
      ],
    );

    expect(group.allSizesOutOfStock, isTrue);
  });
}

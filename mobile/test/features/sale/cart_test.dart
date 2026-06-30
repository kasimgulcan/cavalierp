import 'package:flutter_test/flutter_test.dart';
import 'package:csm_stok_mobile/features/sale/models/cart_line.dart';
import 'package:csm_stok_mobile/features/sale/models/product.dart';

void main() {
  test('CartLine lineTotal multiplies quantity and unit price', () {
    final line = CartLine(
      product: Product(
        sizeId: 1,
        displayName: 'Gömlek - M',
        listPrice: 12,
        unitPrice: 10,
        stockQty: 5,
      ),
      quantity: 3,
      unitPrice: 10,
    );
    expect(line.lineTotal, 30);
  });
}

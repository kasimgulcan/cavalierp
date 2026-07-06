import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/sale/models/sale.dart';
import 'package:cavalierp/features/sale/sale_totals.dart';

SaleDetail _detail({
  required List<SaleLine> lines,
  double? subtotalAmount,
  double? totalAmount,
  double discountPercent = 0,
  double discountFixedAmount = 0,
}) {
  return SaleDetail(
    saleId: 1,
    staffEmail: 'staff',
    lines: lines,
    subtotalAmount: subtotalAmount,
    totalAmount: totalAmount,
    discountPercent: discountPercent,
    discountFixedAmount: discountFixedAmount,
  );
}

void main() {
  test('discountAmount uses stored percent and fixed values', () {
    final detail = _detail(
      subtotalAmount: 100000,
      totalAmount: 85000,
      discountPercent: 10,
      discountFixedAmount: 5000,
      lines: [
        SaleLine(
          saleLineId: 1,
          sizeId: 1,
          product: 'Ürün 1',
          quantity: 1,
          unitPrice: 100000,
          listPrice: 100000,
        ),
      ],
    );

    expect(detail.listSubtotal, 100000);
    expect(detail.percentDiscountAmount, 10000);
    expect(detail.fixedDiscountAmount, 5000);
    expect(detail.discountAmount, 15000);
    expect(detail.netTotal, 85000);
    expect(detail.hasDiscount, isTrue);
  });

  test('no discount when stored values are zero', () {
    final detail = _detail(
      lines: [
        SaleLine(
          saleLineId: 1,
          sizeId: 1,
          product: 'Ürün 1',
          quantity: 2,
          unitPrice: 1000,
          listPrice: 1000,
        ),
      ],
    );

    expect(detail.discountAmount, 0);
    expect(detail.hasDiscount, isFalse);
  });
}

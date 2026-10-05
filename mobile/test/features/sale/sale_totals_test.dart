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

  test('negative amount adjustment is included in the net total', () {
    final detail = _detail(
      subtotalAmount: 1910,
      totalAmount: 1337,
      discountPercent: 30,
      discountFixedAmount: -63,
      lines: [
        SaleLine(
          saleLineId: 1,
          sizeId: 1,
          product: 'Çorap',
          quantity: 1,
          unitPrice: 1910,
          listPrice: 1910,
        ),
      ],
    );

    expect(detail.percentDiscountAmount, 573);
    expect(detail.fixedDiscountAmount, -63);
    expect(detail.discountAmount, 510);
    expect(detail.netTotal, 1400);
    expect(detail.listSubtotal - detail.discountAmount, 1400);
  });

  test('sale list net total uses the adjustment instead of stored total', () {
    const summary = SaleSummary(
      saleId: 270,
      staffEmail: 'staff',
      createdAt: null,
      subtotalAmount: 1910,
      totalAmount: 1337,
      discountPercent: 30,
      discountFixedAmount: -63,
    );

    expect(summary.netTotal, 1400);
  });

  test('sale summary json recomputes net when an adjustment is stored', () {
    expect(
      saleNetTotalFromJson({
        'SubtotalAmount': 1910,
        'DiscountPercent': 30,
        'DiscountFixedAmount': -63,
        'TotalAmount': 1337,
      }),
      1400,
    );
  });
}

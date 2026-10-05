import '../../core/format/price_format.dart';
import 'checkout_discount.dart';
import 'models/order_request.dart';
import 'models/sale.dart';

extension SaleDetailTotals on SaleDetail {
  CheckoutDiscountInput get discountInput => CheckoutDiscountInput(
        percent: discountPercent ?? 0,
        fixedAmount: discountFixedAmount ?? 0,
      );

  double get listSubtotal {
    if (subtotalAmount != null) {
      return roundSaleMoney(subtotalAmount!);
    }
    return roundSaleMoney(
      lines.fold(
        0.0,
        (sum, line) =>
            sum + lineTotalFromUnitPrice(line.unitPrice, line.quantity),
      ),
    );
  }

  double get netTotal =>
      resolvedSaleNetTotal(
        subtotal: listSubtotal,
        storedTotal: totalAmount,
        percent: discountPercent ?? 0,
        fixedAmount: discountFixedAmount ?? 0,
      ) ??
      0;

  double get percentDiscountAmount =>
      discountInput.percentDiscountAmount(listSubtotal);

  double get fixedDiscountAmount =>
      discountInput.fixedDiscountAmount(listSubtotal);

  double get discountAmount => discountInput.totalDiscountAmount(listSubtotal);

  bool get hasDiscount =>
      (discountPercent ?? 0) > 0 || (discountFixedAmount ?? 0) != 0;
}

extension SaleSummaryTotals on SaleSummary {
  double get netTotal =>
      resolvedSaleNetTotal(
        subtotal: subtotalAmount,
        storedTotal: totalAmount,
        percent: discountPercent ?? 0,
        fixedAmount: discountFixedAmount ?? 0,
      ) ??
      0;
}

extension OrderRequestSaleDiscount on OrderRequestDetail {
  CheckoutDiscountInput? get convertedSaleDiscountInput {
    if (convertedSaleId == null) return null;
    final percent = convertedSaleDiscountPercent ?? 0;
    final fixed = convertedSaleDiscountFixedAmount ?? 0;
    if (percent <= 0 && fixed == 0) return null;
    return CheckoutDiscountInput(percent: percent, fixedAmount: fixed);
  }

  double? get convertedSaleSubtotal =>
      convertedSaleSubtotalAmount != null
          ? roundSaleMoney(convertedSaleSubtotalAmount!)
          : null;

  double? get convertedSaleNetTotal => resolvedSaleNetTotal(
        subtotal: convertedSaleSubtotalAmount,
        storedTotal: convertedSaleNetTotalAmount,
        percent: convertedSaleDiscountPercent ?? 0,
        fixedAmount: convertedSaleDiscountFixedAmount ?? 0,
      );
}

/// İndirim alanları varsa net, üst karttaki formülle hesaplanır.
/// Sunucunun TotalAmount değeri eksi tutar düzeltmesini yok sayabilir.
double? resolvedSaleNetTotal({
  double? subtotal,
  double? storedTotal,
  double percent = 0,
  double fixedAmount = 0,
}) {
  if (subtotal != null && (percent > 0 || fixedAmount != 0)) {
    return CheckoutDiscountInput(
      percent: percent,
      fixedAmount: fixedAmount,
    ).grandTotal(roundSaleMoney(subtotal));
  }
  if (storedTotal != null) return roundSaleMoney(storedTotal);
  if (subtotal != null) return roundSaleMoney(subtotal);
  return null;
}

double? readSaleAmount(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double? saleNetTotalFromJson(Map<String, dynamic> json) {
  return resolvedSaleNetTotal(
    subtotal: readSaleAmount(json['SubtotalAmount']),
    storedTotal: readSaleAmount(json['TotalAmount']),
    percent: readSaleAmount(json['DiscountPercent']) ?? 0,
    fixedAmount: readSaleAmount(json['DiscountFixedAmount']) ?? 0,
  );
}

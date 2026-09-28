import '../../core/format/price_format.dart';
import 'models/cart_line.dart';

String formatDiscountField(double value) {
  if (value == 0) return '';
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return formatDecimalInput(value);
}

/// % indirim ve tutar indirimi birlikte uygulanır:
/// önce yüzde, ardından kalan tutar üzerinden sabit tutar.
class CheckoutDiscountInput {
  const CheckoutDiscountInput({
    this.percent = 0,
    this.fixedAmount = 0,
  });

  final double percent;
  final double fixedAmount;

  @override
  bool operator ==(Object other) =>
      other is CheckoutDiscountInput &&
      other.percent == percent &&
      other.fixedAmount == fixedAmount;

  @override
  int get hashCode => Object.hash(percent, fixedAmount);

  double percentDiscountAmount(double subtotal) {
    if (subtotal <= 0 || percent <= 0) return 0;
    return roundSaleMoney(
      (subtotal * percent.clamp(0, 100) / 100).clamp(0, subtotal),
    );
  }

  double subtotalAfterPercent(double subtotal) {
    return roundSaleMoney(
      (subtotal - percentDiscountAmount(subtotal)).clamp(0, double.infinity),
    );
  }

  /// Pozitif tutar indirimdir. Negatif tutar, yüzde sonrası nete eklenen
  /// yuvarlama düzeltmesidir ve liste fiyatının üstüne çıkamaz.
  double fixedDiscountAmount(double subtotal) {
    if (fixedAmount == 0 || subtotal <= 0) return 0;
    final afterPercent = subtotalAfterPercent(subtotal);
    if (fixedAmount > 0) {
      return roundSaleMoney(fixedAmount.clamp(0, afterPercent));
    }
    final maxAddBack = roundSaleMoney(subtotal - afterPercent);
    return roundSaleMoney(fixedAmount.clamp(-maxAddBack, 0));
  }

  double totalDiscountAmount(double subtotal) {
    return roundSaleMoney(
      percentDiscountAmount(subtotal) + fixedDiscountAmount(subtotal),
    );
  }

  double grandTotal(double subtotal) {
    return roundSaleMoney(
      (subtotal - totalDiscountAmount(subtotal)).clamp(0, double.infinity),
    );
  }
}

double lineTotalFromUnitPrice(double unitPrice, int quantity) {
  return roundSaleMoney(roundMoney(unitPrice) * quantity);
}

/// İndirimli satış kalemlerinde birim fiyatları yuvarlayarak
/// satır toplamlarının hedef tutara eşit olmasını sağlar.
List<double> buildRoundedUnitPrices({
  required List<CartLine> lines,
  required int currencyId,
  required double discountAmount,
}) {
  if (lines.isEmpty) return [];

  final subtotal = roundSaleMoney(
    lines.fold(0.0, (sum, line) => sum + line.lineTotalFor(currencyId)),
  );
  final targetTotal = roundSaleMoney(subtotal - discountAmount);

  if (discountAmount <= 0 || subtotal <= 0) {
    return lines
        .map((line) => roundMoney(line.unitPriceFor(currencyId)))
        .toList();
  }

  final unitPrices = List<double>.filled(lines.length, 0);
  var runningTotal = 0.0;

  for (var i = 0; i < lines.length - 1; i++) {
    final line = lines[i];
    final share = line.lineTotalFor(currencyId) / subtotal;
    final lineTarget = roundSaleMoney(targetTotal * share);
    final unit = line.quantity > 0
        ? roundMoney(lineTarget / line.quantity)
        : 0.0;
    unitPrices[i] = unit;
    runningTotal = roundSaleMoney(
      runningTotal + lineTotalFromUnitPrice(unit, line.quantity),
    );
  }

  final last = lines.last;
  final remaining = roundSaleMoney(targetTotal - runningTotal);
  var lastUnit = last.quantity > 0
      ? roundMoney(remaining / last.quantity)
      : 0.0;

  for (var attempt = 0; attempt < 20; attempt++) {
    final total = roundSaleMoney(
      runningTotal + lineTotalFromUnitPrice(lastUnit, last.quantity),
    );
    final diff = roundSaleMoney(targetTotal - total);
    if (diff == 0) break;
    lastUnit = roundMoney(lastUnit + diff / last.quantity);
  }

  unitPrices[lines.length - 1] = lastUnit;
  return unitPrices;
}

List<Map<String, dynamic>> buildSaleLinesPayload({
  required List<CartLine> lines,
  required int currencyId,
}) {
  return lines
      .map(
        (line) => {
          'SizeId': line.product.sizeId,
          'Product': line.product.productName,
          'Quantity': line.quantity,
          'UnitPrice': roundMoney(line.unitPriceFor(currencyId)),
          'ListPrice': roundMoney(line.listPriceFor(currencyId)),
        },
      )
      .toList();
}

/// @deprecated İndirim artık satış düzeyinde saklanır; birim fiyatları değiştirmez.
List<Map<String, dynamic>> buildRoundedSaleLinesPayload({
  required List<CartLine> lines,
  required int currencyId,
  required double discountAmount,
}) {
  final unitPrices = buildRoundedUnitPrices(
    lines: lines,
    currencyId: currencyId,
    discountAmount: roundSaleMoney(discountAmount),
  );

  return List.generate(lines.length, (index) {
    final line = lines[index];
    return {
      'SizeId': line.product.sizeId,
      'Product': line.product.productName,
      'Quantity': line.quantity,
      'UnitPrice': unitPrices[index],
      'ListPrice': roundMoney(line.listPriceFor(currencyId)),
    };
  });
}

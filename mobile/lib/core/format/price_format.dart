import 'dart:math' as math;

/// Para tutarını belirtilen ondalık basamağa yuvarlar.
double roundMoney(double value, {int fractionDigits = 2}) {
  if (!value.isFinite) return 0;
  final factor = math.pow(10, fractionDigits).toDouble();
  return (value * factor).roundToDouble() / factor;
}

/// Satış toplamları tam liraya yuvarlanır (örn. 73.999,98 → 74.000).
double roundSaleMoney(double value) => roundMoney(value, fractionDigits: 0);

/// Türkiye formatı: binlik ayraç `.`, ondalık `,` — örn. 1.234,56
String formatPrice(double value, {int decimals = 2}) {
  final rounded = roundMoney(value, fractionDigits: decimals);
  final negative = rounded < 0;
  final abs = rounded.abs();
  final fixed = abs.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts.first;
  final decPart = parts.length > 1 ? parts[1] : '';

  final grouped = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) {
      grouped.write('.');
    }
    grouped.write(intPart[i]);
  }

  final result = StringBuffer();
  if (negative) result.write('-');
  result.write(grouped);
  if (decimals > 0) {
    result.write(',');
    result.write(decPart.padRight(decimals, '0'));
  }
  return result.toString();
}

String formatPriceWithSymbol(double value, String symbol, {int decimals = 2}) {
  return '${formatPrice(value, decimals: decimals)} $symbol';
}

String formatStock(double value) => formatPrice(value, decimals: 0);

/// Kullanıcı girişi: `99,50`, `1.234,56` veya `99.50`
double? parseDecimalInput(String text) {
  var value = text.trim();
  if (value.isEmpty) return null;
  if (value.contains(',')) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(value);
}

String formatDecimalInput(double value, {int decimals = 2}) {
  return formatPrice(value, decimals: decimals);
}

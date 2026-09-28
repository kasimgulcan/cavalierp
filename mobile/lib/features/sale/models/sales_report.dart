import '../../../core/models/json_field.dart';
import 'size_order.dart';

class SalesReportSizeLine {
  const SalesReportSizeLine({
    required this.sizeId,
    required this.productName,
    this.styleName,
    this.productCode,
    this.color,
    this.sizeLabel,
    this.sizePos,
    required this.quantity,
    required this.amount,
  });

  final int sizeId;
  final String productName;
  final String? styleName;
  final String? productCode;
  final String? color;
  final String? sizeLabel;
  final int? sizePos;
  final int quantity;
  final double amount;

  factory SalesReportSizeLine.fromJson(Map<String, dynamic> json) {
    return SalesReportSizeLine(
      sizeId: json.intField('SizeId') ?? 0,
      productName: json.stringField('Product') ?? '',
      styleName: json.stringField('StyleName'),
      productCode: json.stringField('ProductCode'),
      color: json.stringField('Color'),
      sizeLabel: json.stringField('SizeLabel'),
      sizePos: json.intField('Pos'),
      quantity: json.intField('Quantity') ?? 0,
      amount: json.doubleField('Amount') ?? 0,
    );
  }

  static String groupKey(SalesReportSizeLine line) {
    final code = line.productCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    return '${line.styleName ?? ''}|${line.productName}';
  }
}

class SalesReportProductGroup {
  const SalesReportProductGroup({
    required this.key,
    required this.productName,
    this.styleName,
    this.productCode,
    this.color,
    required this.sizes,
  });

  final String key;
  final String productName;
  final String? styleName;
  final String? productCode;
  final String? color;
  final List<SalesReportSizeLine> sizes;

  int get totalQuantity =>
      sizes.fold(0, (sum, line) => sum + line.quantity);

  double get totalAmount =>
      sizes.fold(0, (sum, line) => sum + line.amount);
}

class SalesReport {
  const SalesReport({required this.products});

  final List<SalesReportProductGroup> products;

  int get totalQuantity =>
      products.fold(0, (sum, group) => sum + group.totalQuantity);

  double get totalAmount =>
      products.fold(0, (sum, group) => sum + group.totalAmount);

  static SalesReport fromRows(List<Map<String, dynamic>> rows) {
    final lines = rows.map(SalesReportSizeLine.fromJson).toList();
    final grouped = <String, List<SalesReportSizeLine>>{};

    for (final line in lines) {
      grouped
          .putIfAbsent(SalesReportSizeLine.groupKey(line), () => [])
          .add(line);
    }

    final products = grouped.entries.map((entry) {
      final sizes = [...entry.value]
        ..sort(
          (a, b) => compareBySizePosition(
            positionA: a.sizePos,
            positionB: b.sizePos,
            labelA: a.sizeLabel ?? '',
            labelB: b.sizeLabel ?? '',
          ),
        );
      final primary = sizes.first;
      return SalesReportProductGroup(
        key: entry.key,
        productName: primary.productName,
        styleName: primary.styleName,
        productCode: primary.productCode,
        color: primary.color,
        sizes: sizes,
      );
    }).toList();

    products.sort((a, b) {
      final byStyle = (a.styleName ?? '').compareTo(b.styleName ?? '');
      if (byStyle != 0) return byStyle;
      return a.productName.compareTo(b.productName);
    });

    return SalesReport(products: products);
  }
}

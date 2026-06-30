import '../../../core/models/json_field.dart';

class Product {
  Product({
    required this.sizeId,
    required this.displayName,
    required this.listPrice,
    required this.unitPrice,
    required this.stockQty,
    this.variantCode,
    this.imageUrl,
  });

  final int sizeId;
  final String displayName;
  final double listPrice;
  final double unitPrice;
  final double stockQty;
  final String? variantCode;
  final String? imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    sizeId: (json['SizeId'] as num? ?? json['sizeId'] as num).toInt(),
    displayName: (json['Product'] ?? json['product']) as String,
    listPrice: (json['ListPrice'] as num? ?? json['listPrice'] as num)
        .toDouble(),
    unitPrice: (json['UnitPrice'] as num? ?? json['unitPrice'] as num)
        .toDouble(),
    stockQty: (json['StockQty'] as num? ?? json['stockQty'] as num).toDouble(),
    variantCode: json.stringField('VariantCode'),
    imageUrl: json.stringField('ImageUrl'),
  );
}

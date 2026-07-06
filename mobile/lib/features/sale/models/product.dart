import '../../../core/models/json_field.dart';
import '../currency_selection.dart';

class Product {
  Product({
    required this.sizeId,
    required this.productName,
    required this.priceTL,
    required this.priceEUR,
    required this.priceUSD,
    required this.stockQty,
    this.styleName,
    this.color,
    this.sizeLabel,
    this.productCode,
    this.imageUrl,
  });

  final int sizeId;
  final String productName;
  final double priceTL;
  final double priceEUR;
  final double priceUSD;
  final double stockQty;
  final String? styleName;
  final String? color;
  final String? sizeLabel;
  final String? productCode;
  final String? imageUrl;

  double priceFor(int currencyId) {
    switch (currencyId) {
      case kEurCurrencyId:
        return priceEUR;
      case kUsdCurrencyId:
        return priceUSD;
      default:
        return priceTL;
    }
  }

  String get variantLabel {
    final parts = [
      if (color != null && color!.isNotEmpty) color,
      if (sizeLabel != null && sizeLabel!.isNotEmpty) sizeLabel,
    ];
    return parts.join(' · ');
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    if (json.field('PriceTL') != null ||
        json.field('PriceEUR') != null ||
        json.field('PriceUSD') != null) {
      return Product(
        sizeId: (json['SizeId'] as num? ?? json['sizeId'] as num).toInt(),
        productName: json.stringField('ProductName') ?? '',
        priceTL: json.doubleField('PriceTL') ?? 0,
        priceEUR: json.doubleField('PriceEUR') ?? 0,
        priceUSD: json.doubleField('PriceUSD') ?? 0,
        stockQty:
            (json['StockQty'] as num? ?? json['stockQty'] as num).toDouble(),
        styleName: json.stringField('StyleName'),
        color: json.stringField('Color'),
        sizeLabel: json.stringField('Size'),
        productCode: json.stringField('ProductCode'),
        imageUrl: json.stringField('ImageUrl'),
      );
    }

    final unitPrice = json.doubleField('UnitPrice') ?? 0;
    final currencyId = json.intField('CurrencyId') ?? kDefaultCurrencyId;

    return Product(
      sizeId: (json['SizeId'] as num? ?? json['sizeId'] as num).toInt(),
      productName: json.stringField('ProductName') ?? '',
      priceTL: currencyId == kDefaultCurrencyId ? unitPrice : 0,
      priceEUR: currencyId == kEurCurrencyId ? unitPrice : 0,
      priceUSD: currencyId == kUsdCurrencyId ? unitPrice : 0,
      stockQty:
          (json['StockQty'] as num? ?? json['stockQty'] as num).toDouble(),
      styleName: json.stringField('StyleName'),
      color: json.stringField('Color'),
      sizeLabel: json.stringField('Size'),
      productCode: json.stringField('ProductCode'),
      imageUrl: json.stringField('ImageUrl'),
    );
  }

  Product copyWith({String? imageUrl}) => Product(
        sizeId: sizeId,
        productName: productName,
        priceTL: priceTL,
        priceEUR: priceEUR,
        priceUSD: priceUSD,
        stockQty: stockQty,
        styleName: styleName,
        color: color,
        sizeLabel: sizeLabel,
        productCode: productCode,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

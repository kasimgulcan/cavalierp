import '../../../core/format/price_format.dart';
import 'product.dart';

class ProductGroup {
  ProductGroup({required this.key, required this.sizes})
    : assert(sizes.isNotEmpty);

  final String key;
  final List<Product> sizes;

  Product get primary => sizes.first;

  String? get productCode => primary.productCode;
  String? get styleName => primary.styleName;
  String get productName => primary.productName;
  String? get color => primary.color;
  String? get imageUrl => primary.imageUrl;

  int get sizeCount => sizes.length;

  String get sizesLabel {
    final labels = sizes
        .map((p) => p.sizeLabel?.trim())
        .whereType<String>()
        .where((label) => label.isNotEmpty)
        .toList();
    if (labels.isEmpty) return '—';
    return labels.join(' - ');
  }

  double get totalStock =>
      sizes.fold(0, (sum, product) => sum + product.stockQty);

  bool get allSizesOutOfStock =>
      sizes.every((product) => product.stockQty <= 0);

  double minPriceFor(int currencyId) => sizes
      .map((p) => p.priceFor(currencyId))
      .reduce((a, b) => a < b ? a : b);

  double maxPriceFor(int currencyId) => sizes
      .map((p) => p.priceFor(currencyId))
      .reduce((a, b) => a > b ? a : b);

  bool hasVariablePriceFor(int currencyId) =>
      minPriceFor(currencyId) != maxPriceFor(currencyId);

  String priceLabel(String currencySymbol, int currencyId) {
    final minPrice = minPriceFor(currencyId);
    final maxPrice = maxPriceFor(currencyId);
    if (hasVariablePriceFor(currencyId)) {
      return '${formatPrice(minPrice)} – ${formatPrice(maxPrice)} $currencySymbol';
    }
    return formatPriceWithSymbol(minPrice, currencySymbol);
  }

  static String groupKey(Product product) {
    final code = product.productCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    return 'size:${product.sizeId}';
  }

  static List<ProductGroup> fromProducts(List<Product> products) {
    final grouped = <String, List<Product>>{};
    for (final product in products) {
      grouped.putIfAbsent(groupKey(product), () => []).add(product);
    }

    final groups = grouped.entries.map((entry) {
      final sizes = [...entry.value]
        ..sort(
          (a, b) => (a.sizeLabel ?? '').compareTo(b.sizeLabel ?? ''),
        );
      return ProductGroup(key: entry.key, sizes: sizes);
    }).toList();

    groups.sort((a, b) {
      final byStyle = (a.styleName ?? '').compareTo(b.styleName ?? '');
      if (byStyle != 0) return byStyle;
      return a.productName.compareTo(b.productName);
    });

    return groups;
  }
}

import '../../../core/format/price_format.dart';
import 'product.dart';

class CartLine {
  CartLine({
    required this.product,
    required this.quantity,
    this.unitPriceOverride,
    this.listPriceOverride,
  });

  final Product product;
  int quantity;
  final double? unitPriceOverride;
  final double? listPriceOverride;

  double listPriceFor(int currencyId) =>
      listPriceOverride ?? product.priceFor(currencyId);

  double unitPriceFor(int currencyId) =>
      unitPriceOverride ?? listPriceFor(currencyId);

  double lineTotalFor(int currencyId) =>
      roundSaleMoney(quantity * unitPriceFor(currencyId));
}

import 'product.dart';

class CartLine {
  CartLine({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  final Product product;
  int quantity;
  double unitPrice;

  double get lineTotal => quantity * unitPrice;
}

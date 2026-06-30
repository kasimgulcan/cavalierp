import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_thumbnail.dart';

/// Sepete ekleme dialogunda ürün görseli.
class ProductDialogImage extends StatelessWidget {
  const ProductDialogImage({
    super.key,
    required this.product,
    this.size = 120,
  });

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ProductThumbnail(imageUrl: product.imageUrl, size: size),
    );
  }
}

import 'package:flutter/material.dart';

import 'product_image_viewer.dart';
import 'product_thumbnail.dart';

/// Sepete ekleme dialogunda ürün görseli — dokununca tam ekran açılır.
class ProductDialogImage extends StatelessWidget {
  const ProductDialogImage({
    super.key,
    required this.imageUrl,
    this.size = 120,
  });

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.trim().isNotEmpty == true;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasImage
              ? () => showProductImageViewer(context, imageUrl)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ProductThumbnail(imageUrl: imageUrl, size: size),
              if (hasImage)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.zoom_out_map_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

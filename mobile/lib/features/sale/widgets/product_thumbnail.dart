import 'package:flutter/material.dart';

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 56,
  });

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: size * 0.45,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return placeholder;
    }

    final cacheWidth =
        (MediaQuery.devicePixelRatioOf(context) * size).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              size: size * 0.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

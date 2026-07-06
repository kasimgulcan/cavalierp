import 'package:flutter/material.dart';

void showProductImageViewer(BuildContext context, String? imageUrl) {
  final url = imageUrl?.trim();
  if (url == null || url.isEmpty) return;

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _ProductImageViewerPage(imageUrl: url),
    ),
  );
}

class _ProductImageViewerPage extends StatelessWidget {
  const _ProductImageViewerPage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: Colors.white70),
              );
            },
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

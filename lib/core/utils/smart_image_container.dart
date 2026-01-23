import 'package:flutter/material.dart';

class SmartImageContainer extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SmartImageContainer({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Si la URL es nula o vacía, mostramos placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // 2. MIENTRAS CARGA (Loading)
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        // 3. SI FALLA (Error / Sin Internet)
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(isError: true);
        },
      ),
    );
  }

  Widget _buildPlaceholder({bool isError = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          isError ? Icons.image_not_supported_outlined : Icons.image_outlined,
          color: Colors.grey[400],
          size: 30,
        ),
      ),
    );
  }
}
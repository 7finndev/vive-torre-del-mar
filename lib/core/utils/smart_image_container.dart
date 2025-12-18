import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SmartImageContainer extends StatelessWidget {
  final String? imageUrl; // Puede ser nulo
  final double? height;
  final double? width;
  final double borderRadius;
  final bool isCircle; 

  const SmartImageContainer({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.borderRadius = 12.0,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. URL Segura: Si es nulo o vacío, ponemos una imagen gris o placeholder
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final validUrl = hasImage 
        ? imageUrl! 
        : 'https://via.placeholder.com/400x300.png?text=Sin+Imagen';

    Widget content;

    if (!hasImage) {
      // Si no hay imagen real, mostramos un contenedor gris simple
      content = Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey));
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          // A. FONDO BORROSO (Rellena todo el hueco)
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: CachedNetworkImage(
              imageUrl: validUrl,
              fit: BoxFit.cover, 
              color: Colors.white.withOpacity(0.8),
              colorBlendMode: BlendMode.modulate, // Suaviza el fondo
              placeholder: (context, url) => Container(color: Colors.grey[100]),
              errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
            ),
          ),

          // B. IMAGEN NÍTIDA (Se ajusta al centro sin recortarse)
          Center(
            child: CachedNetworkImage(
              imageUrl: validUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    // 2. Aplicar forma (Círculo o Rectángulo redondeado)
    if (isCircle) {
      return ClipOval(
        child: SizedBox(
          height: height,
          width: width ?? height, // Si es círculo, forzamos cuadrado
          child: content,
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: width,
          child: content,
        ),
      );
    }
  }
}
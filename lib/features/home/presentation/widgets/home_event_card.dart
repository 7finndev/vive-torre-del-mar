import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HomeEventCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String? logoUrl;
  final VoidCallback onTap;

  const HomeEventCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.logoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200, // Un poco más alto para que luzca mejor
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // 1. FONDO NEGRO: Si la imagen tarda o es transparente, se verá negro, no gris "sucio".
          color: Colors.black, 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 2. LA IMAGEN
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover, //-->Recorta la imagen
                //fit: BoxFit.contain, //-->Muestra la imagen completa.
                // Placeholder: Un spinner blanco sobre fondo negro (muy elegante)
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                // Error: Un icono rojo MUY visible (para saber si falla)
                errorWidget: (context, url, error) {
                  return Container(
                    color: Colors.red.shade900,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text("Error Imagen", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                },
              ),

              // 3. LOGO (Si existe)
              if (hasLogo)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: CachedNetworkImage(
                    imageUrl: logoUrl!,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),

              // 4. TÍTULO "EXPLORAR RUTA" (Sin caja, solo texto con sombra)
              if (!hasLogo)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20, // Para evitar que se salga si es muy largo
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28, // Grande e impactante
                      height: 1.0,
                      shadows: [
                        // Sombra dura para legibilidad perfecta
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.9),
                        ),
                        // Resplandor suave detrás
                        Shadow(
                          offset: const Offset(0, 0),
                          blurRadius: 15.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
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
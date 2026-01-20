import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// IMPORTANTE: Importa el helper que creamos antes
import 'package:torre_del_mar_app/core/utils/event_type_helper.dart'; 

class HomeEventCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String? logoUrl;
  final String eventType; // <--- 1. NUEVO PARÁMETRO
  final VoidCallback onTap;

  const HomeEventCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.logoUrl,
    required this.eventType, // <--- 2. LO REQUERIMOS EN EL CONSTRUCTOR
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    
    // 3. OBTENEMOS LA APARIENCIA (Color, Texto, Icono)
    final appearance = EventTypeHelper.getAppearance(eventType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200, 
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
              // --- IMAGEN DE FONDO ---
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover, 
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) {
                  return Container(
                    color: Colors.red.shade900,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white, size: 40),
                      ],
                    ),
                  );
                },
              ),

              // --- 4. LA ETIQUETA RECUPERADA ---
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: appearance.color, // Color dinámico (Naranja, Morado, Verde...)
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(appearance.icon, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        appearance.label.toUpperCase(), // "GASTRONÓMICO", "AVENTURA"...
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- LOGO (Si existe) ---
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

              // --- TÍTULO ---
              if (!hasLogo)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20, 
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.9),
                        ),
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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';

class EstablishmentCard extends StatelessWidget {
  final EstablishmentModel establishment;

  const EstablishmentCard({super.key, required this.establishment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail', extra: establishment),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias, // Recorta la imagen para que respete el borde redondo
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los hijos a la altura disponible (130px)
          children: [
            
            // 1. IMAGEN (IZQUIERDA) - Ancho fijo
            SizedBox(
              width: 130, // Cuadrado perfecto (130x130) o rectangular vertical
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SmartImageContainer(
                    imageUrl: establishment.coverImage,
                    borderRadius: 0, // El borde lo da el Container padre
                  ),
                  // Sombra interior sutil para separar imagen de contenido blanco
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Colors.black.withOpacity(0.1), Colors.transparent],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // 2. INFORMACIÓN (DERECHA) - Ocupa el resto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Centrado verticalmente
                  children: [
                    // A. TÍTULO
                    Text(
                      establishment.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6), // Separación

                    // B. UBICACIÓN
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            establishment.address ?? "Ver mapa",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(), // Empuja lo siguiente abajo del todo

                    // C. HORARIO / ESTADO
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            establishment.schedule ?? "Consultar horario",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. BADGE TAPAS (Etiqueta opcional a la derecha)
            if (establishment.products?.isNotEmpty ?? false)
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8)),
                    ),
                    child: Text(
                      "${establishment.products!.length}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800
                      ),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart'; 

class EstablishmentCard extends StatelessWidget {
  final EstablishmentModel establishment;

  const EstablishmentCard({super.key, required this.establishment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Esto recorta la imagen en las esquinas de la tarjeta
      child: InkWell(
        onTap: () => context.push('/detail', extra: establishment),
        child: SizedBox(
          height: 110, 
          child: Row(
            children: [
              // 1. SMART IMAGE CONTAINER
              SizedBox(
                width: 110, // Cuadrado perfecto
                height: 110,
                child: SmartImageContainer(
                  imageUrl: establishment.coverImage,
                  // Ponemos radio 0 porque el Card padre ya se encarga de recortar las esquinas
                  borderRadius: 0, 
                ),
              ),
              
              // 2. INFORMACIÓN A LA DERECHA (Tu código original)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nombre
                      Text(
                        establishment.name,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Dirección
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              establishment.address ?? "Ubicación desconocida", 
                              style: const TextStyle(color: Colors.grey, fontSize: 12), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            )
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Horario
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              establishment.schedule ?? "Consultar horario", 
                              style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w500), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            )
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              // 3. FLECHITA
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/features/map/presentation/providers/navigation_provider.dart';
// Importa el archivo nuevo que creamos arriba (ajusta la ruta si lo pusiste en otro lado)
import 'package:torre_del_mar_app/features/home/presentation/providers/nearest_bar_provider.dart'; 

class NextStopCard extends ConsumerWidget {
  final int eventId;
  const NextStopCard({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ESCUCHAMOS EL PROVIDER (La magia reactiva)
    final nearestAsync = ref.watch(nearestBarProvider(eventId));

    return nearestAsync.when(
      // 1. CARGANDO (Silencioso o Skeleton)
      loading: () => const SizedBox.shrink(), 
      
      // 2. ERROR (Si explota el GPS o la Red, no mostramos nada y evitamos crash)
      error: (err, stack) => const SizedBox.shrink(), 
      
      // 3. DATOS LISTOS
      data: (result) {
        // Caso A: No hay GPS o no hay bares pendientes
        if (result == null || result.bar == null) {
          // Opcional: Mostrar tarjeta de "Ruta Completada" o nada
          // Si no hay GPS, mejor no mostramos nada para no molestar
           return const SizedBox.shrink(); 
        }

        final bar = result.bar!;
        final distance = result.distance;

        // Caso B: Tenemos bar cercano
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Configurar navegación
              ref.read(navigationProvider.notifier).setTarget(bar);
              context.go('/event/$eventId/map'); 
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // FOTO
                  SizedBox(
                    width: 70, height: 70,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SmartImageContainer(imageUrl: bar.coverImage),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // TEXTOS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "TU PRÓXIMA PARADA",
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bar.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "A solo ${(distance / 1000).toStringAsFixed(1)} km de aquí",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // ICONO FLECHA
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.near_me, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
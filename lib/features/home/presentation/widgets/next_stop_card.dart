import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/features/map/presentation/providers/navigation_provider.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/nearest_bar_provider.dart'; 

class NextStopCard extends ConsumerWidget {
  final int eventId;
  const NextStopCard({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearestAsync = ref.watch(nearestBarProvider(eventId));

    return nearestAsync.when(
      loading: () => const SizedBox.shrink(), 
      error: (err, stack) => const SizedBox.shrink(), 
      data: (result) {
        if (result == null || result.bar == null) {
           return const SizedBox.shrink(); 
        }

        final bar = result.bar!;
        final distance = result.distance;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // 🔥 CORRECCIÓN AQUÍ:
              // Usamos 'selectOnly' para marcar el bar en el mapa.
              // Al navegar a /map, el mapa verá que hay un 'target' y mostrará la tarjeta automáticamente.
              ref.read(navigationProvider.notifier).selectOnly(bar);
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
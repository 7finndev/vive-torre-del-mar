import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';

import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';

class TapasListScreen extends ConsumerWidget {
  const TapasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Necesitamos tanto las tapas como los bares para saber de quién es cada tapa
    final productsAsync = ref.watch(productsListProvider);
    final establishmentsAsync = ref.watch(establishmentsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Galería de Productos")), // Texto más genérico
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tapas) {
          if (tapas.isEmpty) return const Center(child: Text("No hay productos cargados."));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Columnas
              childAspectRatio: 0.8, // Más altas que anchas
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: tapas.length,
            itemBuilder: (context, index) {
              final tapa = tapas[index];
              
              // Buscamos el bar dueño de esta tapa
              final establishments = establishmentsAsync.value ?? [];
              final bar = establishments.firstWhere(
                (e) => e.id == tapa.establishmentId,
                orElse: () => EstablishmentModel(id: -1, name: "Local Desconocido", qrUuid: "", isActive: false),
              );

              return GestureDetector(
                onTap: () {
                  if (bar.id != -1) {
                    context.push('/detail', extra: bar);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0,4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FOTO PRODUCTO CON SMART IMAGE ---
                      Expanded(
                        child: ClipRRect(
                          // Mantenemos esto para redondear SOLO arriba
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: SmartImageContainer(
                            imageUrl: tapa.imageUrl,
                            // Ponemos 0 porque el ClipRRect padre ya recorta la forma
                            borderRadius: 0, 
                            // Opcional: Si quieres que el círculo interior (si fuera logo)
                            // no se use, dejamos isCircle: false por defecto.
                          ),
                        ),
                      ),
                      
                      // TEXTOS
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tapa.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bar.name, 
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis, // Evita errores si es muy largo
                            ),
                            if (tapa.price != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "${tapa.price}€",
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
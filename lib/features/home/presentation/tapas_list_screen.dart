import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/core/widgets/error_view.dart'; // <--- IMPORTAR

class TapasListScreen extends ConsumerWidget {
  const TapasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsListProvider);
    final establishmentsAsync = ref.watch(establishmentsListProvider);

    //Funcion auxiliar:
    void reloadAll(){
      ref.invalidate(currentEventProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(establishmentsListProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Galería de Productos")),
      body: RefreshIndicator(
        color: Colors.orange,
        onRefresh: () async {
          //Utilizamos la funcion auxiliar reloadAll() aqui:
          reloadAll();
          //Sustituyendo estas lineas:
          // --> ref.invalidate(productsListProvider);
          // --> ref.invalidate(establishmentsListProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          
          // ✅ CAMBIO AQUÍ: ErrorView en lugar de Text
          error: (err, stack) => ErrorView(
            error: err,
            onRetry: () {
              //Aqui tambien se utiliza la funcion auxiliar reloadAll():
              reloadAll();
              //Sustituyendo estas lineas:
              //--> ref.invalidate(productsListProvider);
              //--> ref.invalidate(establishmentsListProvider);
            },
          ),

          data: (tapas) {
            if (tapas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                   SizedBox(height: 100),
                   Center(child: Text("No hay productos cargados.")),
                ],
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.8, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: tapas.length,
              itemBuilder: (context, index) {
                final tapa = tapas[index];
                
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
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: SmartImageContainer(
                              imageUrl: tapa.imageUrl,
                              borderRadius: 0, 
                            ),
                          ),
                        ),
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
                                overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
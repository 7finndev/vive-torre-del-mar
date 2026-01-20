import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

// Si tu productsListProvider está en home_providers, importa esto:
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';

class AdminProductDetailScreen extends ConsumerWidget {
  final ProductModel product;

  const AdminProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. TRUCO DE MAGIA: 🎩
    // En lugar de usar 'this.product' directamente, buscamos la versión más nueva
    // en la lista global de productos.
    final productsAsync = ref.watch(productsListProvider);

    // Intentamos encontrar este producto en la lista actualizada.
    // Si la lista está cargando o falla, usamos el 'product' viejo temporalmente.
    final currentProduct = productsAsync.valueOrNull?.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product, // Si no lo encuentra, usa el viejo
    ) ?? product;

    // Truco anti-caché para la imagen
    final String? imageUrl = currentProduct.imageUrl != null 
        ? "${currentProduct.imageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}"
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentProduct.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // 2. NAVEGACIÓN CON ESPERA
              // Usamos 'push' para esperar a que el formulario se cierre
              // Nota: pushNamed necesita que definas el nombre en el router, si no usas nombres, usa push
              final bool? result = await context.pushNamed<bool>(
                'product_form',
                extra: {
                  'eventId': currentProduct.eventId,
                  'productToEdit': currentProduct, // Pasamos el actual
                },
              );

              // 3. SI SE GUARDÓ CORRECTAMENTE...
              if (result == true) {
                // FORZAMOS LA RECARGA DE LA LISTA
                // Al invalidar la lista, el 'ref.watch' de arriba se disparará de nuevo
                // y 'currentProduct' se actualizará solo.
                ref.invalidate(productsListProvider);
                
                // Opcional: Mostrar mensaje
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vista actualizada")),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGEN
            SizedBox(
              height: 300,
              width: double.infinity,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.fastfood, size: 80, color: Colors.grey)),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. CABECERA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentProduct.name,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "${currentProduct.price}€",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Estado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: currentProduct.isAvailable ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: Text(
                          currentProduct.isAvailable ? "Disponible" : "Agotado / Inactivo",
                          style: TextStyle(color: currentProduct.isAvailable ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (currentProduct.isWinner)
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(5)
                          ),
                          child: const Text(
                            "🏆 GANADOR",
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // 3. DESCRIPCIÓN
                  const Text("Descripción", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text(
                    currentProduct.description != null && currentProduct.description!.isNotEmpty 
                        ? currentProduct.description! 
                        : "Sin descripción detallada.",
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),

                  // Ingredientes si los hay
                  if (currentProduct.ingredients != null && currentProduct.ingredients!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text("Ingredientes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 5),
                    Text(currentProduct.ingredients!),
                  ],

                  const SizedBox(height: 30),
                  
                  // 4. DATOS TÉCNICOS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Datos Internos", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text("Producto ID: ${currentProduct.id}"),
                        Text("Establishment ID: ${currentProduct.establishmentId}"),
                        Text("Event ID: ${currentProduct.eventId}"),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
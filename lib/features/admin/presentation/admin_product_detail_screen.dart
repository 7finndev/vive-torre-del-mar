import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/admin/presentation/providers/admin_products_providers.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
// 🔥 1. IMPORTAMOS EL MODELO DE ESTABLECIMIENTO
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';

import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
// 🔥 2. IMPORTA DONDE TENGAS EL PROVIDER DE 'TODOS LOS ESTABLECIMIENTOS'
// Si lo dejaste en admin_products_screen.dart, importa ese archivo.
// Si lo moviste a admin_products_providers.dart, importa ese.

class AdminProductDetailScreen extends ConsumerWidget {
  final ProductModel product;

  const AdminProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lista de productos (para refrescar datos del producto actual)
    final productsAsync = ref.watch(productsListProvider);
    
    // 🔥 3. TRAEMOS LA LISTA DE BARES (Para buscar el dueño del producto)
    final establishmentsAsync = ref.watch(adminAllEstablishmentsProvider);

    final currentProduct = productsAsync.valueOrNull?.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product,
    ) ?? product;

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
              final bool? result = await context.pushNamed<bool>(
                'product_form',
                extra: {
                  'eventId': currentProduct.eventId,
                  'productToEdit': currentProduct,
                },
              );

              if (result == true) {
                ref.invalidate(productsListProvider);
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
            // IMAGEN
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
                  // CABECERA
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
                  
                  // ESTADO
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

                  // 🔥 4. NUEVA SECCIÓN: ESTABLECIMIENTO ASOCIADO 🔥
                  const Text("Ofrecido por:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
                  const SizedBox(height: 10),

                  establishmentsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text("No se pudo cargar el local: $e"),
                    data: (establishments) {
                      // Buscamos el local en la lista usando el ID que tiene el producto
                      final establishment = establishments.firstWhere(
                        (e) => e.id == currentProduct.establishmentId,
                        // Fallback por si no lo encontramos
                        orElse: () => EstablishmentModel(id: 0, name: "Local Desconocido", isActive: false, qrUuid: ''),
                      );

                      if (establishment.id == 0) return const Text("Local no encontrado.");

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: establishment.coverImage != null 
                              ? NetworkImage(establishment.coverImage!) 
                              : null,
                            child: establishment.coverImage == null 
                              ? const Icon(Icons.store, color: Colors.blue) 
                              : null,
                          ),
                          title: Text(
                            establishment.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text("Ir a la ficha del socio >", style: TextStyle(color: Colors.blue[700])),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // 🔥 NAVEGAMOS AL DETALLE DEL ESTABLECIMIENTO
                            // Usamos la ruta que ya tienes configurada para socios
                            context.push('/admin/socios/detail', extra: establishment);
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // DESCRIPCIÓN
                  const Text("Descripción", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text(
                    currentProduct.description != null && currentProduct.description!.isNotEmpty 
                        ? currentProduct.description! 
                        : "Sin descripción detallada.",
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),

                  // INGREDIENTES
                  if (currentProduct.ingredients != null && currentProduct.ingredients!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text("Ingredientes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 5),
                    Text(currentProduct.ingredients!),
                  ],

                  const SizedBox(height: 30),
                  
                  // DATOS TÉCNICOS
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
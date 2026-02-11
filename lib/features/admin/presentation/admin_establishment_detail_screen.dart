import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart'; // <--- NUEVA LIBRERÍA
import 'package:torre_del_mar_app/core/utils/qr_download_widget.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/product_repository.dart';

// Provider auxiliar
final productsByEstablishmentProvider = FutureProvider.family
    .autoDispose<List<ProductModel>, int>((ref, establishmentId) async {
      final allProducts = await ref
          .read(productRepositoryProvider)
          .getAllProducts();
      return allProducts
          .where((p) => p.establishmentId == establishmentId)
          .toList();
    });

class AdminEstablishmentDetailScreen extends ConsumerWidget {
  final EstablishmentModel establishment;

  const AdminEstablishmentDetailScreen({
    super.key,
    required this.establishment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(
      productsByEstablishmentProvider(establishment.id),
    );

    // TRUCO ANTI-CACHÉ:
    // Añadimos un timestamp al final de la URL. Esto fuerza a Flutter a
    // volver a descargar la imagen si acabamos de subirla.
    final String? imageUrl = establishment.coverImage != null
        ? "${establishment.coverImage!}?t=${DateTime.now().millisecondsSinceEpoch}"
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(establishment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Editar Datos",
            onPressed: () {
              context.push('/admin/socios/edit', extra: establishment);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGEN DE PORTADA (Con Efecto "Cine" Difuminado)
            SizedBox(
              height: 300,
              width: double.infinity,
              child: imageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // A. FONDO BORROSO (La misma imagen estirada y desenfocada)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                          child: Container(
                            color: Colors.black.withOpacity(0.5), // Oscurece para destacar la principal
                          ),
                        ),
                        // B. IMAGEN PRINCIPAL (Nítida y contenida)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.contain, 
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.white54),
                                  SizedBox(height: 10),
                                  Text("No se pudo cargar la imagen", style: TextStyle(color: Colors.white54)),
                                ],
                              )
                            );
                          },
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.orange.shade50,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store, size: 80, color: Colors.orange),
                            SizedBox(height: 10),
                            Text("Sin foto de portada", style: TextStyle(color: Colors.orange)),
                          ],
                        )
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATOS PROPIETARIO
                  Text(
                    "Datos del Propietario",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                            title: Text(
                              establishment.ownerName ?? "Nombre no registrado",
                            ),
                            subtitle: const Text("Propietario / Gerente"),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_android,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(establishment.ownerPhone ?? "-"),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.email,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        establishment.ownerEmail ?? "-",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ZONA DE TAPAS
                  Text(
                    "Historial de Productos",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),

                  productsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text("Error cargando tapas: $e"),
                    data: (products) {
                      if (products.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Sin productos registrados.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final prod = products[index]; 
                          
                          return ListTile(
                            // 🔥 AQUÍ LE DAMOS ACCIÓN 🔥
                            onTap: () {
                              // Navegamos usando la ruta que ya tienes en app_router.dart
                              context.push('/admin/products/detail', extra: prod);
                            },
                            // ---------------------------
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: prod.imageUrl != null
                                    ? Image.network(
                                        prod.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                                      )
                                    : const Icon(Icons.fastfood, color: Colors.orange),
                              ),
                            ),
                            title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${prod.price}€"),
                            // Flechita a la derecha para indicar que se puede entrar
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  const Divider(),

                  // =======================================================
                  // 🚀 ZONA QR MEJORADA (REAL + GRANDE)
                  // =======================================================
                  const SizedBox(height: 10),
                  const Text(
                    "Código QR Oficial",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  /*
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Column(
                      children: [
                        // PINTAMOS EL QR REAL
                        QrImageView(
                          data: establishment.qrUuid, // <--- El dato real
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                        
                        const SizedBox(height: 10),
                        SelectableText(
                          establishment.qrUuid, 
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.bold)
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // BOTÓN "VER EN GRANDE" (Para descargar/imprimir)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showBigQrDialog(context, establishment.name, establishment.qrUuid);
                            },
                            icon: const Icon(Icons.zoom_in),
                            label: const Text("Ampliar para Imprimir"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[900],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15)
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Pulsa 'Ampliar' y haz una captura o clic derecho para guardar.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                  */
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // AQUÍ USAMOS TU NUEVO WIDGET
                        QrDownloadSection(
                          dataContent: establishment.qrUuid,
                          establishmentName: establishment.name,
                        ),

                        const SizedBox(height: 20),

                        // Información de texto (Opcional, pero útil tenerla visible)
                        const Text(
                          "Identificador UUID:",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        SelectableText(
                          establishment.qrUuid,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DIÁLOGO PARA VER EL QR GIGANTE
  void _showBigQrDialog(BuildContext context, String name, String data) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(30),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 5, color: Colors.black),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 300.0, // TAMAÑO GIGANTE
                ),
              ),
              const SizedBox(height: 20),
              Text(
                data,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                "Haz una captura de pantalla o clic derecho -> Guardar imagen",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

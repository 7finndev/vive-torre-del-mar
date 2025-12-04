import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'; // Opcional si usas clusters, si no, markers normales
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';

// IMPORTANTE: Asegúrate de tener 'flutter_map_cancellable_tile_provider' 
// o la configuración de caché que hicimos antes.
import 'package:flutter_map_cache/flutter_map_cache.dart'; 
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart'; 

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ESCUCHAR LA LISTA FILTRADA (Ya viene filtrada por el evento activo)
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    
    // 2. CENTRO POR DEFECTO (Torre del Mar)
    final initialCenter = const LatLng(36.742, -4.095);

    return Scaffold(
      body: establishmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error mapa: $err")),
        data: (establishments) {
          
          // 3. CREAR MARCADORES DINÁMICOS
          final markers = establishments.map((bar) {
            if (bar.latitude == null || bar.longitude == null) return null;
            
            return Marker(
              point: LatLng(bar.latitude!, bar.longitude!),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                   // Al tocar el pin, mostramos el modal o vamos al detalle
                   _showPreviewModal(context, bar);
                },
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            );
          }).whereType<Marker>().toList(); // Filtrar nulos

          return FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                 // Configuración de caché que hicimos antes
                 tileProvider: CachedTileProvider(
                    maxStale: const Duration(days: 30),
                    store: MemCacheStore(maxSize: 10 * 1024 * 1024, maxEntrySize: 512 * 1024),
                 ),
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }

  void _showPreviewModal(BuildContext context, dynamic bar) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 150,
        width: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            Text(bar.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/detail', extra: bar);
              }, 
              child: const Text("Ver Ficha")
            )
          ],
        ),
      )
    );
  }
}
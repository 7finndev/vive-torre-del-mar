import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart'; // Asegúrate de tener este import si usas flutter_map
import 'package:latlong2/latlong.dart'; // Y este para las coordenadas

// TUS IMPORTS EXACTOS
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
// Si usas marcadores propios
import 'package:torre_del_mar_app/core/widgets/error_view.dart'; // <--- EL WIDGET SALVAVIDAS

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchamos la lista de establecimientos
    final establishmentsAsync = ref.watch(establishmentsListProvider);

    return Scaffold(
      body: establishmentsAsync.when(
        // A. CARGANDO
        loading: () => const Center(child: CircularProgressIndicator()),

        // B. ERROR (AQUÍ EVITAMOS LA PANTALLA ROJA)
        error: (err, stack) => ErrorView(
          error: err,
          onRetry: () {
            ref.invalidate(currentEventProvider);       //|--> Reinicia el Padre
            ref.invalidate(establishmentsListProvider); //|--> Reinicia el Hijo
          }
        ),

        // C. DATOS LISTOS
        data: (establishments) {
          if (establishments.isEmpty) {
            return const Center(child: Text("No hay locales para mostrar en este evento."));
          }

          // Centramos el mapa en el primer local o en Torre del Mar por defecto
          final center = establishments.first.latitude != null 
              ? LatLng(establishments.first.latitude!, establishments.first.longitude!)
              : const LatLng(36.74, -4.09); // Torre del Mar centro aprox

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.torre_del_mar_app',
                // IMPORTANTE: Manejo de errores de tiles si no hay red
                errorTileCallback: (tile, error, stackTrace) {
                   // Esto evita que el mapa se ponga gris/rojo feo, simplemente no carga el fondo
                },
              ),
              MarkerLayer(
                markers: establishments.map((e) {
                  if (e.latitude == null || e.longitude == null) return null;
                  return Marker(
                    point: LatLng(e.latitude!, e.longitude!),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40), 
                    // O usa tu CustomMapMarker si lo tienes implementado en widgets
                  );
                }).whereType<Marker>().toList(), // Filtramos nulos
              ),
            ],
          );
        },
      ),
    );
  }
}
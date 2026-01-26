import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:geolocator/geolocator.dart'; 

import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/core/widgets/error_view.dart';
import 'package:torre_del_mar_app/features/home/presentation/widgets/establishment_card.dart'; 
import 'providers/navigation_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  Future<LatLng?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      return await Geolocator.getCurrentPosition().then((p) => LatLng(p.latitude, p.longitude));
    } catch (e) { return null; }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    final navState = ref.watch(navigationProvider); // Escuchamos cambios

    return Scaffold(
      body: establishmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorView(
          error: err,
          onRetry: () {
            ref.invalidate(establishmentsListProvider);
          }
        ),
        data: (establishments) {
          if (establishments.isEmpty) return const Center(child: Text("No hay locales."));

          final center = establishments.first.latitude != null 
              ? LatLng(establishments.first.latitude!, establishments.first.longitude!)
              : const LatLng(36.74, -4.09);

          return Stack(
            children: [
              // 1. MAPA
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.0,
                  onTap: (_, __) => ref.read(navigationProvider.notifier).clearSelection(),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.torre_del_mar_app',
                  ),
                  
                  // RUTA (Debajo de los pines)
                  if (navState.routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: navState.routePoints,
                          strokeWidth: 5.0,
                          color: Colors.orange,
                        ),
                      ],
                    ),

                  // MARCADORES
                  MarkerLayer(
                    markers: establishments.map((e) {
                      if (e.latitude == null || e.longitude == null) return null;
                      
                      final isSelected = navState.targetEstablishment?.id == e.id;

                      return Marker(
                        point: LatLng(e.latitude!, e.longitude!),
                        width: isSelected ? 60 : 40, // Un poco más grande si seleccionado
                        height: isSelected ? 60 : 40,
                        child: GestureDetector(
                          onTap: () async {
                            // 1. Feedback táctil inmediato (opcional)
                            // HapticFeedback.selectionClick(); 

                            final userLoc = await _getCurrentLocation();
                            if (userLoc != null) {
                              // 2. Activamos la lógica
                              ref.read(navigationProvider.notifier).selectEstablishment(e, userLoc);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Activa el GPS para trazar la ruta."))
                              );
                            }
                          },
                          child: Icon(
                            Icons.location_on, 
                            color: isSelected ? Colors.orange : Colors.red, 
                            size: isSelected ? 60 : 40,
                            // Añadimos una sombra para que se vea mejor
                            shadows: const [Shadow(blurRadius: 5, color: Colors.black45)],
                          ),
                        ),
                      );
                    }).whereType<Marker>().toList(),
                  ),
                  
                  // USUARIO
                  if (navState.userLocation != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: navState.userLocation!,
                        width: 20, height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]
                          ),
                        ),
                      )
                    ]),
                ],
              ),

              // 2. INDICADOR DE CARGA (CHIP FLOTANTE) - ¡AQUÍ ESTÁ LA MEJORA!
              if (navState.isLoadingRoute)
                Positioned(
                  top: 60, // Debajo de la barra de estado
                  left: 0, 
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Calculando ruta...", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. TARJETA DEL ESTABLECIMIENTO (Bottom Sheet)
              if (navState.targetEstablishment != null)
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (navState.isOfflineMode)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                          child: const Text("Sin conexión: Ruta no disponible", style: TextStyle(color: Colors.white)),
                        ),
                      EstablishmentCard(establishment: navState.targetEstablishment!),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
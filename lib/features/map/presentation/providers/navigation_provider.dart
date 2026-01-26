import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/map/data/datasources/osm_service.dart';

// ESTADO
class NavigationState {
  final EstablishmentModel? targetEstablishment;
  final LatLng? userLocation;
  final List<LatLng> routePoints; 
  final bool isLoadingRoute;      // <--- LA CLAVE
  final bool isOfflineMode;       
  final bool shouldRecalculate; 

  NavigationState({
    this.targetEstablishment,
    this.userLocation,
    this.routePoints = const [],
    this.isLoadingRoute = false,
    this.isOfflineMode = false,
    this.shouldRecalculate = false,
  });

  NavigationState copyWith({
    EstablishmentModel? targetEstablishment,
    LatLng? userLocation,
    List<LatLng>? routePoints,
    bool? isLoadingRoute,
    bool? isOfflineMode,
    bool? shouldRecalculate,
  }) {
    return NavigationState(
      targetEstablishment: targetEstablishment ?? this.targetEstablishment,
      userLocation: userLocation ?? this.userLocation,
      routePoints: routePoints ?? this.routePoints,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      shouldRecalculate: shouldRecalculate ?? this.shouldRecalculate,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  final OsrmService _osrmService = OsrmService();

  NavigationNotifier() : super(NavigationState());

  void setTarget(EstablishmentModel establishment) {
    state = state.copyWith(
      targetEstablishment: establishment,
      routePoints: [], 
      isOfflineMode: false,
      shouldRecalculate: true,
    );
  }

  // --- MÉTODO OPTIMIZADO ---
  Future<void> selectEstablishment(EstablishmentModel establishment, LatLng userLocation) async {
    // 1. INMEDIATO: Mostrar local, limpiar ruta vieja y ACTIVAR CARGA
    state = state.copyWith(
      targetEstablishment: establishment,
      userLocation: userLocation,
      routePoints: [], 
      isLoadingRoute: true, // <--- ¡AQUÍ ENCENDEMOS EL SPINNER!
      isOfflineMode: false,
      shouldRecalculate: false, 
    );

    try {
      final targetLoc = LatLng(establishment.latitude!, establishment.longitude!);
      
      // 2. ASÍNCRONO: Esperar a la API (mientras el usuario ve el spinner)
      final points = await _osrmService.getWalkingRoute(userLocation, targetLoc);
      
      if (mounted) {
        // 3. RESULTADO: Pintar ruta y APAGAR spinner
        state = state.copyWith(
          routePoints: points,
          isLoadingRoute: false, // <--- APAGAMOS
          isOfflineMode: points.isEmpty, // Si viene vacío, asumimos fallo de red
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingRoute: false,
          isOfflineMode: true,
        );
      }
    }
  }

  void clearSelection() {
    state = NavigationState(userLocation: state.userLocation); 
  }
  
  void updateUserLocation(LatLng loc) {
    state = state.copyWith(userLocation: loc);
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
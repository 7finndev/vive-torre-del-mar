import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';

// ESTADO: ¿Hacia dónde vamos y dónde estamos?
class NavigationState {
  final EstablishmentModel? targetEstablishment;
  final LatLng? userLocation;
  // Si es true, el mapa debe recalcular la ruta nada más abrirse
  final bool shouldRecalculate; 

  NavigationState({
    this.targetEstablishment, 
    this.userLocation, 
    this.shouldRecalculate = false
  });

  NavigationState copyWith({
    EstablishmentModel? targetEstablishment,
    LatLng? userLocation,
    bool? shouldRecalculate,
  }) {
    return NavigationState(
      targetEstablishment: targetEstablishment ?? this.targetEstablishment,
      userLocation: userLocation ?? this.userLocation,
      shouldRecalculate: shouldRecalculate ?? this.shouldRecalculate,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(NavigationState());

  // Llamado desde la Home (Card "Tu próxima parada")
  void setTarget(EstablishmentModel establishment) {
    state = state.copyWith(
      targetEstablishment: establishment, 
      shouldRecalculate: true
    );
  }

  // Llamado desde el Mapa (GPS)
  void updateUserLocation(LatLng location) {
    state = state.copyWith(userLocation: location);
  }
  
  // Llamado cuando la ruta ya se ha pintado
  void routeCalculated() {
    state = state.copyWith(shouldRecalculate: false);
  }
  
  void clearRoute() {
    state = NavigationState(userLocation: state.userLocation); 
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
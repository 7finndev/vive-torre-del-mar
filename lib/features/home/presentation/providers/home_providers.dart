import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/establishment_repository.dart';
import 'package:torre_del_mar_app/features/scan/data/repositories/passport_repository.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';

// Parte necesaria para la generación de código de Riverpod
part 'home_providers.g.dart';

// Este provider guarda el ID del evento que estamos viendo ahora mismo (USUARIO FINAL).
final currentEventIdProvider = StateProvider<int>((ref) => 1); // Por defecto 1
// ----------------------------------------

// Estado para guardar el filtro del Hub (activo, proximos, historico)
// Al ser StateProvider, no necesita 'buil_runner'
final hubFilterProvider = StateProvider<String>((ref) => 'active');


// 1. Proveedor de la BD Local
@riverpod
LocalDbService localDb(LocalDbRef ref) {
  return LocalDbService(); 
  // Nota: Ya llamamos a .init() en main.dart
}

// 2. Proveedor del Repositorio de Establecimientos
@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider);
  return EstablishmentRepository(supabase, localDb);
}

// 3. Proveedor de la LISTA DE BARES (Filtrada por evento actual - PARA USUARIO)
@riverpod
Future<List<EstablishmentModel>> establishmentsList(EstablishmentsListRef ref) async {
  final repository = ref.watch(establishmentRepositoryProvider);
  // 1. Esperamos a saber en qué evento estamos
  final event = await ref.watch(currentEventProvider.future);
  // 2. Pedimos solo los locales de ese evento
  return repository.getEstablishments(eventId: event.id);
}

// 4. Stream de Conectividad
@riverpod
Stream<List<ConnectivityResult>> connectivityStream(ConnectivityStreamRef ref) {
  return Connectivity().onConnectivityChanged;
}

// 5. Proveedor de la LISTA DE PRODUCTOS (Filtrada por evento actual - PARA USUARIO)
@riverpod
Future<List<ProductModel>> productsList(ProductsListRef ref) async {
  final repository = ref.watch(establishmentRepositoryProvider);
  final event = await ref.watch(currentEventProvider.future);
  return repository.getProducts(eventId: event.id);
}

// 6. Proveedor del Repositorio de Pasaporte
@riverpod
PassportRepository passportRepository(PassportRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider);
  return PassportRepository(supabase, localDb);
}

// 7. Evento Actual (Objeto completo basado en ID seleccionado)
@riverpod
Future<EventModel> currentEvent(CurrentEventRef ref) async {
  final id = ref.watch(currentEventIdProvider);
  final supabase = Supabase.instance.client;
  
  final response = await supabase.from('events').select().eq('id', id).single();
  return EventModel.fromJson(response);
}

// =================================================================
// 🆕 PROVIDERS PARA EL PANEL DE ADMINISTRACIÓN (ZONA ADMIN)
// =================================================================

// 8. Lista de Eventos ACTIVOS o PRÓXIMOS (Para el Dropdown del Admin)
@riverpod
Future<List<EventModel>> activeEventsList(ActiveEventsListRef ref) async {
  final supabase = Supabase.instance.client;
  
  // Traemos eventos 'active' o 'upcoming' para poder añadirles tapas antes de que empiecen
  final response = await supabase
      .from('events')
      .select()
      .or('status.eq.active,status.eq.upcoming')
      .order('start_date', ascending: false);
  
  return response.map((e) => EventModel.fromJson(e)).toList();
}

// 9. Lista MAESTRA de Establecimientos (Para vincular al Admin)
// Nota: Traemos TODOS los bares ordenados alfabéticamente.
// El admin debe seleccionar cuál de todos los bares de la BD va a participar.
@riverpod
Future<List<EstablishmentModel>> allEstablishmentsList(AllEstablishmentsListRef ref) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('establishments')
      .select()
      .order('name', ascending: true); // A-Z

  return response.map((e) => EstablishmentModel.fromJson(e)).toList();
}
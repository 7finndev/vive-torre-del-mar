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

// Este provider guarda el ID del evento que estamos viendo ahora mismo.
final currentEventIdProvider = StateProvider<int>((ref) => 1); // Por defecto 1
// ----------------------------------------

// 1. Proveedor de la BD Local
@riverpod
LocalDbService localDb(LocalDbRef ref) {
  return LocalDbService(); 
  // Nota: Ya llamamos a .init() en main.dart, así que aquí solo instanciamos
}

// 2. Proveedor del Repositorio
@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider);
  return EstablishmentRepository(supabase, localDb);
}

// 3. Proveedor de la LISTA DE BARES (Lo que usará la UI)
@riverpod
Future<List<EstablishmentModel>> establishmentsList(EstablishmentsListRef ref) async {
  // Este provider se encarga de llamar al método inteligente getEstablishments
  final repository = ref.watch(establishmentRepositoryProvider);

  // 1.-Esperamos a saber en qué evento estamos:
  final event = await ref.watch(currentEventProvider.future);

  // 2.-Pedimos solo los locales de ese evento:
  return repository.getEstablishments(eventId: event.id);
}

// NUEVO: Un Stream que emite eventos cada vez que cambia la red (WiFi <-> 4G <-> Nada)
@riverpod
Stream<List<ConnectivityResult>> connectivityStream(ConnectivityStreamRef ref) {
  return Connectivity().onConnectivityChanged;
}
// NUEVO PROVIDER: Lista de Productos (Tapas)
@riverpod
Future<List<ProductModel>> productsList(ProductsListRef ref) async {
  final repository = ref.watch(establishmentRepositoryProvider);

  //1.-Obtenemos primero la configuración del evento activo
  // future asegura que esperamos a que cargue el evento.
  final event = await ref.watch(currentEventProvider.future);

  //2.-Le pasamos ese ID dinámico al repositorio
  return repository.getProducts(eventId: event.id);
}

// Proveedor del Repositorio de Pasaporte
@riverpod
PassportRepository passportRepository(PassportRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider);
  return PassportRepository(supabase, localDb);
}


// Actualizamos el provider que descarga el evento para que lea ese ID
@riverpod
Future<EventModel> currentEvent(CurrentEventRef ref) async {
  final id = ref.watch(currentEventIdProvider); // <--- AHORA ES DINÁMICO
  final supabase = Supabase.instance.client;
  
  final response = await supabase.from('events').select().eq('id', id).single();
  return EventModel.fromJson(response);
}
/*
// Provider para obtener datos del Evento Activo (ID 1 por ahora)
@riverpod
Future<EventModel> currentEvent(CurrentEventRef ref) async {
  final supabase = Supabase.instance.client;
  
  // Leemos el evento 1 de Supabase
  final response = await supabase
      .from('events')
      .select()
      .eq('id', 1)
      .single();
      
  return EventModel.fromJson(response);
}
*/

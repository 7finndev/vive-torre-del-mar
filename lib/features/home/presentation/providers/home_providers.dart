import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/establishment_repository.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/product_repository.dart';
import 'package:torre_del_mar_app/features/scan/data/repositories/passport_repository.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/sponsor_model.dart';

part 'home_providers.g.dart';

// --- ESTADOS GLOBALES ---
final currentEventIdProvider = StateProvider<int>((ref) => 1);
final hubFilterProvider = StateProvider<String>((ref) => 'active');

// 1. Proveedor de la BD Local
@riverpod
LocalDbService localDb(LocalDbRef ref) {
  return LocalDbService(); 
}

// 2. Repositorios
@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider);
  return EstablishmentRepository(supabase, localDb);
}

@riverpod
PassportRepository passportRepository(PassportRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider);
  return PassportRepository(supabase, localDb);
}

// 3. Establecimientos (Usuario)
@riverpod
Future<List<EstablishmentModel>> establishmentsList(EstablishmentsListRef ref) async {
  final repository = ref.watch(establishmentRepositoryProvider);
  final event = await ref.watch(currentEventProvider.future);
  return repository.getEstablishments(eventId: event.id);
}

// 4. Conectividad
@riverpod
Stream<List<ConnectivityResult>> connectivityStream(ConnectivityStreamRef ref) {
  return Connectivity().onConnectivityChanged;
}

// 5. Productos (Usuario)
@riverpod
Future<List<ProductModel>> productsList(ProductsListRef ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final event = await ref.watch(currentEventProvider.future);
  return repository.getProductsByEvent(event.id);
}

// 7. Evento Actual (Objeto completo basado en ID seleccionado) - BLINDADO 🛡️
@riverpod
Future<EventModel> currentEvent(CurrentEventRef ref) async {
  final id = ref.watch(currentEventIdProvider);
  final supabase = Supabase.instance.client;
  
  // Necesitamos acceso a la BD local para buscar en la caché si falla internet
  final localDb = ref.watch(localDbProvider); 

  try {
    // A. INTENTO ONLINE
    final response = await supabase
        .from('events')
        .select()
        .eq('id', id)
        .single();
    
    return EventModel.fromJson(response);

  } catch (e) {
    // B. SI FALLA -> BUSCAMOS EN LA CACHÉ DE EVENTOS
    // (Como adminEventsList ya descarga TODOS los eventos y los guarda, 
    // podemos buscar este evento específico ID=15 dentro de esa lista guardada)
    
    final cachedEvents = localDb.getCachedEvents(); // Leemos la caja 'cache_events_raw'
    
    if (cachedEvents.isNotEmpty) {
      try {
        // Buscamos el evento que coincida con el ID
        final found = cachedEvents.firstWhere(
          (element) => element['id'] == id,
        );
        // Si lo encontramos, lo devolvemos y la app NO explota
        return EventModel.fromJson(found);
      } catch (_) {
        // Si no está en caché, no podemos hacer nada
      }
    }

    // C. SI NO HAY RED Y NO ESTÁ EN CACHÉ -> LANZAMOS EL ERROR
    // (Esto activará el ErrorView en la pantalla)
    throw e;
  }
}

// =================================================================
// 🛡️ PROVIDERS INTELIGENTES (OFFLINE-FIRST)
// =================================================================

// 8. LISTA DE EVENTOS PARA EL HUB (Todos los estados + Caché)
// NOTA: He renombrado 'activeEventsList' a 'adminEventsList' porque en tu HubScreen 
// usabas 'adminEventsListProvider' y filtrabas localmente. Este trae TODO.
@riverpod
Future<List<EventModel>> adminEventsList(AdminEventsListRef ref) async {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider); // Acceso a Hive

  try {
    // A. INTENTO ONLINE
    // print("🌐 Descargando eventos...");
    final response = await supabase
        .from('events')
        .select()
        .or('status.eq.active,status.eq.upcoming,status.eq.archived,status.eq.finished') // Traemos todo el historial
        .order('start_date', ascending: false);
    
    // B. SI HAY ÉXITO -> GUARDAR EN CACHÉ (JSON PURO)
    final dataList = List<Map<String, dynamic>>.from(response);
    await localDb.cacheEvents(dataList);

    return dataList.map((e) => EventModel.fromJson(e)).toList();

  } catch (e) {
    // C. SI FALLA (SIN INTERNET) -> LEER CACHÉ
    // print("⚠️ Error de red. Buscando en caché...");
    final cachedData = localDb.getCachedEvents();
    
    if (cachedData.isNotEmpty) {
      // print("✅ Usando eventos cacheados");
      return cachedData.map((e) => EventModel.fromJson(e)).toList();
    }

    // D. SI NO HAY RED Y NO HAY CACHÉ -> LANZAR ERROR (Saldrá el ErrorView)
    rethrow;
  }
}

// 9. Lista MAESTRA de Establecimientos (Admin)
@riverpod
Future<List<EstablishmentModel>> allEstablishmentsList(AllEstablishmentsListRef ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('establishments').select().order('name', ascending: true);
  return response.map((e) => EstablishmentModel.fromJson(e)).toList();
}

// 10. Detalle Admin
@riverpod
Future<EventModel> eventDetails(EventDetailsRef ref, int eventId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('events').select().eq('id', eventId).single();
  return EventModel.fromJson(response);
}

// =================================================================
// 🆕 PROVIDER DE PATROCINADORES (CON CACHÉ)
// =================================================================
final sponsorsListProvider = FutureProvider<List<SponsorModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbProvider);

  try {
    // A. ONLINE
    final response = await supabase
        .from('sponsors')
        .select()
        .eq('is_active', true)
        .order('priority', ascending: false);

    // B. GUARDAR CACHÉ
    final dataList = List<Map<String, dynamic>>.from(response);
    await localDb.cacheSponsors(dataList);

    return dataList.map((e) => SponsorModel.fromJson(e)).toList();

  } catch (e) {
    // C. LEER CACHÉ SI FALLA
    final cachedData = localDb.getCachedSponsors();
    if (cachedData.isNotEmpty) {
      return cachedData.map((e) => SponsorModel.fromJson(e)).toList();
    }
    rethrow;
  }
});
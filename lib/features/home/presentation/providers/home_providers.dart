import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Imports de tus repos y modelos
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/establishment_repository.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/product_repository.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/sponsor_repository.dart';
import 'package:torre_del_mar_app/features/scan/data/repositories/passport_repository.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/sponsor_model.dart';

part 'home_providers.g.dart';

// --- ESTADOS GLOBALES ---
final currentEventIdProvider = StateProvider<int>((ref) => 1);
final hubFilterProvider = StateProvider<String>((ref) => 'active');

// 2. Repositorios
@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  // 🔥 CORREGIDO: localDbServiceProvider
  final localDb = ref.watch(localDbServiceProvider); 
  return EstablishmentRepository(supabase, localDb);
}

@riverpod
PassportRepository passportRepository(PassportRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  // 🔥 CORREGIDO: localDbServiceProvider
  final localDb = ref.watch(localDbServiceProvider);
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

// 7. Evento Actual
@riverpod
Future<EventModel> currentEvent(CurrentEventRef ref) async {
  final id = ref.watch(currentEventIdProvider);
  final supabase = Supabase.instance.client;
  
  // 🔥 CORREGIDO: localDbServiceProvider
  final localDb = ref.watch(localDbServiceProvider); 

  try {
    final response = await supabase.from('events').select().eq('id', id).single();
    return EventModel.fromJson(response);
  } catch (e) {
    final cachedEvents = localDb.getCachedEvents();
    if (cachedEvents.isNotEmpty) {
      try {
        final found = cachedEvents.firstWhere((element) => element['id'] == id);
        return EventModel.fromJson(found);
      } catch (_) {}
    }
    rethrow;
  }
}

// 8. LISTA DE EVENTOS (Admin/Hub)
@riverpod
Future<List<EventModel>> adminEventsList(AdminEventsListRef ref) async {
  final supabase = Supabase.instance.client;
  // 🔥 CORREGIDO: localDbServiceProvider
  final localDb = ref.watch(localDbServiceProvider);

  try {
    final response = await supabase
        .from('events')
        .select()
        .or('status.eq.active,status.eq.upcoming,status.eq.archived,status.eq.finished')
        .order('start_date', ascending: false);
    
    final dataList = List<Map<String, dynamic>>.from(response);
    await localDb.cacheEvents(dataList);

    return dataList.map((e) => EventModel.fromJson(e)).toList();

  } catch (e) {
    final cachedData = localDb.getCachedEvents();
    if (cachedData.isNotEmpty) {
      return cachedData.map((e) => EventModel.fromJson(e)).toList();
    }
    rethrow;
  }
}

// 9. Lista MAESTRA
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

// 11. PATROCINADORES
@riverpod
Future<List<SponsorModel>> sponsorsList(SponsorsListRef ref) async {
  final repo = ref.watch(sponsorRepositoryProvider);
  // 🔥 CORREGIDO: localDbServiceProvider
  final localDb = ref.watch(localDbServiceProvider);

  try {
    final sponsors = await repo.getActiveSponsors();
    final jsonList = sponsors.map((e) => e.toJson()).toList();
    await localDb.cacheSponsors(jsonList);
    return sponsors;
  } catch (e) {
    final cached = localDb.getCachedSponsors();
    if (cached.isNotEmpty) {
      return cached.map((e) => SponsorModel.fromJson(e)).toList();
    }
    rethrow;
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 

// Importa tu modelo de Evento
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';

part 'dashboard_repository.g.dart';

class DashboardStats {
  final int totalScans;
  final int totalUsers;
  final int activeProducts;
  final int activeEstablishments;
  final Map<String, int> languages; 

  // --- CAMPOS PARA EL GRÁFICO ---
  final int countProducts; // Tapas/Gastro
  final int countDrinks;   // Cócteles
  final int countShopping; // Tiendas

  // --- CAMPOS TECNOLOGÍAS ---
  final int deviceAndroid;
  final int deviceIOS;
  final int deviceDesktop; // <--- ¡NUEVO CAMPO!
  final int deviceWeb;

  DashboardStats({
    required this.totalScans,
    required this.totalUsers,
    required this.activeProducts,
    required this.activeEstablishments,
    required this.countProducts,
    required this.countDrinks,
    required this.countShopping,
    required this.deviceAndroid,
    required this.deviceIOS,
    required this.deviceDesktop, // <--- AÑADIDO
    required this.deviceWeb,
    required this.languages,
  });
}

class DashboardRepository {
  final SupabaseClient _client;
  DashboardRepository(this._client);

  Future<DashboardStats> getStats({int? eventId}) async {
    // 1. USUARIOS (Global)
    final usersCount = await _client.from('profiles').count(CountOption.exact);

    // 2. PRODUCTOS Y CATEGORÍAS
    var query = _client.from('event_products').select('id, events(type)');

    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }

    final List<dynamic> productsData = await query;

    int products = 0;
    int drinks = 0;
    int shopping = 0;

    for (var item in productsData) {
      final eventData = item['events'] as Map<String, dynamic>?;
      if (eventData != null) {
        final type = (eventData['type'] as String? ?? '').toLowerCase();

        if (type.contains('tapa') || type.contains('gastro')) {
          products++;
        } else if (type.contains('drink') ||
            type.contains('coctel') ||
            type.contains('cóctel')) {
          drinks++;
        } else if (type.contains('shop') ||
            type.contains('tienda') ||
            type.contains('comercio')) {
          shopping++;
        } else {
           products++;
        }
      }
    }

    final totalProducts = products + drinks + shopping;

    // 3. ESTABLECIMIENTOS
    int establishmentsCount = 0;
    
    if (eventId != null) {
      try {
        // Consultamos la vista que me has confirmado que tiene datos
        final List<dynamic> data = await _client
            .from('event_establishments_view')
            .select('id') // Solo traemos el ID para gastar pocos datos
            .eq('event_id', eventId);

        // Usamos un Set para asegurar que son ÚNICOS
        // (Por si la vista devuelve varias filas para el mismo bar)
        final uniqueIds = data.map((e) => e['id']).toSet();
        
        establishmentsCount = uniqueIds.length;
        
        print("✅ Socios (Vista): ${data.length} filas -> $establishmentsCount únicos");
        
      } catch (e) {
        print("❌ Error leyendo la vista de establecimientos: $e");
        establishmentsCount = 0;
      }
    } else {
      // Global (Sin filtro)
      try {
        establishmentsCount = await _client
            .from('establishments')
            .count(CountOption.exact);
      } catch (_) {
        establishmentsCount = 0;
      }
    }

    // 4. ESCANEOS
    int scansCount = 0;
    try {
      var scansQuery = _client.from('passport_entries').count(CountOption.exact);
      if (eventId != null) scansQuery = scansQuery.eq('event_id', eventId);
      scansCount = await scansQuery;
    } catch (_) {
      scansCount = 0;
    }

    // 5. CONSULTA DE DISPOSITIVOS (LÓGICA ACTUALIZADA 🔥)
    Map<String, int> langMap = {};
    int android = 0, ios = 0, web = 0, desktop = 0;

    try {
      final List<dynamic> analyticsData = await _client
          .from('analytics_devices')
          .select('os, locale'); 

      for (var item in analyticsData) {
        // A. Contar OS
        final String os = (item['os'] ?? '').toString().toLowerCase().trim();

        if (os == 'android') {
          android++;
        } else if (os == 'ios') {
          ios++;
        } else if (os == 'windows' || os == 'macos' || os == 'linux') {
          desktop++; // <--- AGRUPAMOS ORDENADORES
        } else {
          web++; // Resto (web generica, etc.)
        }

        // B. Contar Idiomas
        final String code = item['locale'] ?? 'unknown';
        if (code != 'unknown' && code.isNotEmpty) {
           langMap[code] = (langMap[code] ?? 0) + 1;
        }
      }
    } catch (e) {
      print("⚠️ Error leyendo Analytics: $e");
    }

    return DashboardStats(
      totalScans: scansCount,
      totalUsers: usersCount,
      activeProducts: totalProducts,
      activeEstablishments: establishmentsCount,
      countProducts: products,
      countDrinks: drinks,
      countShopping: shopping,
      deviceAndroid: android,
      deviceIOS: ios,
      deviceDesktop: desktop, // <--- PASAMOS EL VALOR
      deviceWeb: web,
      languages: langMap,
    );
  }
}

// --- PROVIDERS ---

@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  return DashboardRepository(Supabase.instance.client);
}

final dashboardSelectedEventProvider = StateProvider<EventModel?>(
  (ref) => null,
);

@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final selectedEvent = ref.watch(dashboardSelectedEventProvider);
  return repo.getStats(eventId: selectedEvent?.id);
}
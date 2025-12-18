import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_repository.g.dart';

class DashboardStats {
  final int totalScans;
  final int totalUsers;
  final int activeProducts;
  final int activeEstablishments;
  
  // --- NUEVOS CAMPOS PARA EL GRÁFICO ---
  final int countTapas;
  final int countDrinks;
  final int countShopping;

  DashboardStats({
    required this.totalScans,
    required this.totalUsers,
    required this.activeProducts,
    required this.activeEstablishments,
    required this.countTapas,
    required this.countDrinks,
    required this.countShopping,
  });
}

class DashboardRepository {
  final SupabaseClient _client;
  DashboardRepository(this._client);

  Future<DashboardStats> getStats({int? eventId}) async {
    // 1. USUARIOS (Global, usando la política de seguridad Admin que creamos)
    final usersCount = await _client.from('profiles').count(CountOption.exact);

    // 2. Preparar query de Productos (y obtenemo el tipo de evento)
    var query = _client.from('event_products').select('id, events(type)');//('id, events!inner(type)'); 
    
    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }

    // Ejecutamos la consulta
    final List<dynamic> productsData = await query;

    // 3. Contar manualmente los tipos (Dart es muy rápido para listas < 10.000 items)
    int tapas = 0;
    int drinks = 0;
    int shopping = 0;

    for (var item in productsData) {
//      final type = (item['type'] as String? ?? '').toLowerCase();
//      if (type == 'gastronomic' || type == 'tapas') tapas++;
//      else if (type == 'drinks' || type == 'coctel' || type == 'cóctel') drinks++;
//      else if (type == 'shopping' || type == 'tienda') shopping++;
      //Recorremos el JSON:
      final eventData = item['events'] as Map<String, dynamic>?;
      if(eventData != null) {
        final type = (eventData['type'] as String ?? '').toLowerCase();

        // Clasificacmos según el tipo de Evento
        if(type == 'gastronomic' || type == 'tapas') {
          tapas++;
        } else if (type == 'drinks' || type == 'coctel') drinks++;
        else if (type == 'shopping') shopping++;
      }
    }
    
    // Total calculado
    final totalProducts = tapas + drinks + shopping;

    // 4. Contar Bares (Lógica según filtro)
    int establishmentsCount = 0;
    if (eventId != null) {
      establishmentsCount = await _client
          .from('event_establishments_view') // Asegúrate de tener esta vista o la relación configurada
          .count(CountOption.exact)
          .eq('event_id', eventId);
    } else {
      establishmentsCount = await _client.from('establishments').count(CountOption.exact);
    }

    // 5. Contar Escaneos
    int scansCount = 0;
    try {
      var scansQuery = _client.from('passport_entries').count(CountOption.exact);
      if (eventId != null) scansQuery = scansQuery.eq('event_id', eventId);
      scansCount = await scansQuery;
    } catch (_) {
      scansCount = 0;
    }

    return DashboardStats(
      totalScans: scansCount,
      totalUsers: usersCount,
      activeProducts: totalProducts,
      activeEstablishments: establishmentsCount,
      countTapas: tapas,        // <--- DATOS REALES
      countDrinks: drinks,      // <--- DATOS REALES
      countShopping: shopping,  // <--- DATOS REALES
    );
  }
}

@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  return DashboardRepository(Supabase.instance.client);
}
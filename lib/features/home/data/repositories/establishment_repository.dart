import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'; // Importante para el provider
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

// Línea necesaria para la generación de código de Riverpod
part 'establishment_repository.g.dart';

class EstablishmentRepository {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  EstablishmentRepository(this._supabase, this._localDb);

  /// 1. READ (APP): Obtiene la lista de bares activos para un evento.
  /// Lógica: Intenta Nube -> Si falla/Offline -> Usa Caché Local
  Future<List<EstablishmentModel>> getEstablishments({required int eventId}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        print('🏘️ Bajando Bares del Evento $eventId...');
        // A. Petición a Supabase (Vista filtrada)
        final response = await _supabase
            .from('event_establishments_view')
            .select()
            .eq('event_id', eventId);

        // Convertir JSON a Objetos
        final List<EstablishmentModel> list = (response as List)
            .map((e) => EstablishmentModel.fromJson(e))
            .toList();

        if (list.isNotEmpty) {
           // B. Guardar en Hive (Caché)
           await _localDb.establishmentsBox.clear();
           await _localDb.establishmentsBox.addAll(list);
        }
        
        return list;

      } catch (e) {
        print('⚠️ ERROR REMOTO: $e. Intentando usar caché...');
        return _getLocalEstablishments();
      }
    } else {
      print('📵 OFFLINE: Cargando desde el móvil.');
      return _getLocalEstablishments();
    }
  } 

  /// 2. READ (APP): Obtiene productos de un evento
  Future<List<ProductModel>> getProducts({required int eventId}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        print('🥘 Bajando Tapas del Evento $eventId...');
        final response = await _supabase
            .from('event_products')
            .select()
            .eq('event_id', eventId); 

        final List<ProductModel> list = (response as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();

        // Guardar en Hive
        await _localDb.productsBox.clear();
        await _localDb.productsBox.addAll(list);
        
        return list;
      } catch (e) {
        print('Error bajando tapas: $e');
        return _getLocalProducts();
      }
    } else {
      return _getLocalProducts();
    }
  }

  // --- HELPERS LOCALES ---
  List<ProductModel> _getLocalProducts() {
    return _localDb.productsBox.values.cast<ProductModel>().toList();
  }
  
  List<EstablishmentModel> _getLocalEstablishments() {
    try {
      final box = _localDb.establishmentsBox;
      if (box.isEmpty) return [];
      return box.values.cast<EstablishmentModel>().toList();
    } catch (e) {
      _localDb.establishmentsBox.clear(); 
      return [];
    }
  }

  // ====================================================================
  // 🛠️ MÉTODOS DE ADMINISTRACIÓN (CRUD)
  // ====================================================================

  /// 3. READ ALL (ADMIN): Obtiene TODOS los establecimientos (maestro)
  Future<List<EstablishmentModel>> getAllEstablishments() async {
    try {
      final response = await _supabase
          .from('establishments') 
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((e) => EstablishmentModel.fromJson(e))
          .toList();
    } catch (e) {
      print('⚠️ Error cargando lista maestra: $e');
      throw Exception('No se pudieron cargar los establecimientos');
    }
  }

  /// 4. CREATE (ADMIN): Crea un nuevo establecimiento
  Future<void> createEstablishment(EstablishmentModel establishment) async {
    // Convertimos a JSON
    final data = establishment.toJson();
    
    // IMPORTANTE: Eliminamos el ID para que Supabase lo genere automáticamente
    data.remove('id'); 

    // Insertamos
    await _supabase.from('establishments').insert(data);
  }

  /// 5. UPDATE (ADMIN): Actualiza un establecimiento existente
  Future<void> updateEstablishment(EstablishmentModel establishment) async {
    final data = establishment.toJson();
    
    // Quitamos el ID del cuerpo de datos a actualizar, 
    // pero lo usamos en la cláusula .eq() para saber cuál actualizar
    data.remove('id');

    await _supabase
        .from('establishments')
        .update(data)
        .eq('id', establishment.id);
  }

  /// 6. DELETE (ADMIN): Borrar establecimiento
  Future<void> deleteEstablishment(int id) async {
    await _supabase.from('establishments').delete().eq('id', id);
  }

}

// ====================================================================
// 💉 PROVIDER (Riverpod)
// ====================================================================

@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  // 1. Obtenemos el cliente de Supabase
  final supabase = Supabase.instance.client;
  
  // 2. Obtenemos la instancia ÚNICA de LocalDbService
  // (Debes importar local_db_service.dart)
  final localDb = ref.watch(localDbServiceProvider);

  // 3. Inyectamos ambos
  return EstablishmentRepository(supabase, localDb);
}
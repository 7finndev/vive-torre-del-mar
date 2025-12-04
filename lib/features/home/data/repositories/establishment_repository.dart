import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

class EstablishmentRepository {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  EstablishmentRepository(this._supabase, this._localDb);

  /// Obtiene la lista de bares activos.
  /// Lógica: Intenta Nube -> Si falla/Offline -> Usa Caché Local
  Future<List<EstablishmentModel>> getEstablishments({required int eventId}) async {
    // 1. Chequear conexión
    final connectivityResult = await Connectivity().checkConnectivity();
    // Nota: connectivity_plus devuelve una lista en versiones nuevas, tomamos el último estado
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
//        print('🌐 ONLINE: Buscando en Supabase...');
        print('🏘️ Bajando Bares del Evento $eventId...');
        // A. Petición a Supabase
        final response = await _supabase
            //.from('establishments')
            .from('event_establishments_view')
            .select()
            //.eq('is_active', true); // Solo los activos pero ya esta implementado en el SQL
            .eq('event_id', eventId);

        // Convertir JSON a Objetos
        final List<EstablishmentModel> list = (response as List)
            .map((e) => EstablishmentModel.fromJson(e))
            .toList();

        if (list.isNotEmpty) {
           // B. Guardar en Hive (Caché) para el futuro
           print('💾 CACHÉ: Guardando ${list.length} locales en el móvil.');
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
  } // Fin getEstableshments.

  // Necesitas importar el ProductModel arriba

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

  List<ProductModel> _getLocalProducts() {
    return _localDb.productsBox.values.cast<ProductModel>().toList();
  }
  
// Helper privado para leer de Hive de forma SEGURA
  List<EstablishmentModel> _getLocalEstablishments() {
    try {
      final box = _localDb.establishmentsBox;
      
      if (box.isEmpty) return [];

      // Intentamos leer y convertir
      return box.values.cast<EstablishmentModel>().toList();
      
    } catch (e) {
      // 🚨 CRÍTICO: Si falla al leer (datos corruptos), BORRAMOS la caché para evitar el crash infinito
      print('⚠️ ERROR DE CORRUPCIÓN EN HIVE: $e');
      print('🧹 Borrando caché corrupta para recuperar la app...');
      _localDb.establishmentsBox.clear(); 
      return [];
    }
  }
}
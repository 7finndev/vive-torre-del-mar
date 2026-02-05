import 'dart:typed_data'; // <--- IMPORTANTE: Necesario para Uint8List
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'; 
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

part 'establishment_repository.g.dart';

class EstablishmentRepository {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  EstablishmentRepository(this._supabase, this._localDb);

  // ====================================================================
  // 📸 NUEVO MÉTODO: SUBIR IMAGEN (STORAGE)
  // ====================================================================
  
  /// Sube una imagen al bucket 'establishments' y devuelve la URL PÚBLICA.
  Future<String> uploadEstablishmentImage(String fileName, Uint8List fileBytes) async {
    try {
      final path = 'establishments/$fileName'; // Ej: establishments/bar-pepe.jpg

      // 1. Subir el archivo binario
      // 'upsert: true' permite sobrescribir si ya existe un archivo con ese nombre
      await _supabase.storage.from('establishment').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Obtener la URL PÚBLICA (Soluciona el error 400 y problemas de caché)
      // Asegúrate de que el bucket sea "Public" en el panel de Supabase.
      final publicUrl = _supabase.storage.from('establishment').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print("⚠️ Error subiendo imagen: $e");
      throw Exception("Error al subir la imagen al servidor.");
    }
  }

  // ====================================================================
  // 📱 MÉTODOS DE LECTURA (APP)
  // ====================================================================

  /// 1. READ (APP): Obtiene la lista de bares activos para un evento.
  Future<List<EstablishmentModel>> getEstablishments({required int eventId}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        print('🏘️ Bajando Bares del Evento $eventId...');
        final response = await _supabase
            .from('event_establishments_view')
            .select()
            .eq('event_id', eventId);

        final List<EstablishmentModel> list = (response as List)
            .map((e) => EstablishmentModel.fromJson(e))
            .toList();

        if (list.isNotEmpty) {
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
    final data = establishment.toJson();
    data.remove('id'); 
    await _supabase.from('establishments').insert(data);
  }

  /// 5. UPDATE (ADMIN): Actualiza un establecimiento existente
  Future<void> updateEstablishment(EstablishmentModel establishment) async {
    final data = establishment.toJson();
    data.remove('id'); // No actualizamos el ID

    await _supabase
        .from('establishments')
        .update(data)
        .eq('id', establishment.id);
  }

  /// 6. DELETE (ADMIN): Borrar establecimiento
  Future<void> deleteEstablishment(int id) async {
    await _supabase.from('establishments').delete().eq('id', id);
  }

  //Nuevo Borrar Imagen:
  Future<void> deleteEstablishmentImage(String imageUrl) async {
    try{
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      await _supabase.storage.from('establishment').remove([fileName]);

    } catch (e) {
      print("⚠️ Error borrando imagen establecimiento:$e");
    }
  }
}

@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbServiceProvider);
  return EstablishmentRepository(supabase, localDb);
}
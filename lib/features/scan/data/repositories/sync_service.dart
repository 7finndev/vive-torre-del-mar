import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/scan/data/models/passport_entry_model.dart';

class SyncService {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  SyncService(this._supabase, this._localDb);

  Future<int> syncPendingVotes({int? targetEventId}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return 0;

    final pendingBox = _localDb.pendingVotesBox;
    final syncedBox = _localDb.syncedStampsBox;
    
    // Ya no dependemos tanto de esta caja para los nombres, pero la mantenemos por si acaso
    final establishmentsBox = _localDb.establishmentsBox; 

    int uploadedCount = 0;
    final keysToDelete = <dynamic>[];

    // ---------------------------------------------------------
    // PASO 1: SUBIDA (Móvil -> Nube) - IGUAL QUE ANTES
    // ---------------------------------------------------------
    for (var key in pendingBox.keys) {
      final entry = pendingBox.get(key) as PassportEntryModel;

      if (!entry.isSynced) {
        try {
          // Buscamos el ID REAL del producto
          final productData = await _supabase
              .from('event_products')
              .select('id')
              .eq('establishment_id', entry.establishmentId)
              .eq('event_id', entry.eventId)
              .maybeSingle();

          if (productData == null) {
            print("⚠️ Error: No existe tapa para el bar ${entry.establishmentName}");
            keysToDelete.add(key);
            continue;
          }

          final int realProductId = productData['id'];

          await _supabase.from('passport_entries').insert({
            'user_id': currentUser.id,
            'product_id': realProductId,
            'event_id': entry.eventId,
            'scanned_at': entry.scannedAt.toIso8601String(),
            'gps_verified': true, 
            'rating': entry.rating, 
          });

          // Movemos a sincronizados
          final syncedEntry = PassportEntryModel(
             establishmentId: entry.establishmentId,
             establishmentName: entry.establishmentName,
             scannedAt: entry.scannedAt,
             isSynced: true,
             rating: entry.rating,
             eventId: entry.eventId,
          );
          
          // Usamos la clave compuesta para guardar también al subir
          final String uniqueKey = "${entry.eventId}_${entry.establishmentId}";
          await syncedBox.put(uniqueKey, syncedEntry);
          
          keysToDelete.add(key);
          uploadedCount++;

        } catch (e) {
          print("⚠️ Error subiendo sello ${entry.establishmentName}: $e");
          if (e.toString().contains("duplicate key")) {
             keysToDelete.add(key);
          }
        }
      }
    }
    await pendingBox.deleteAll(keysToDelete);


    // ---------------------------------------------------------
    // PASO 2: BAJADA (Nube -> Móvil) CON TRADUCCIÓN MEJORADA
    // ---------------------------------------------------------
    try {
      print("⬇️ Descargando historial de la nube...");
      
      // --- CAMBIO CLAVE AQUÍ ---
      // Pedimos:
      // 1. Datos del pasaporte (*)
      // 2. Datos del producto -> establishment_id
      // 3. ¡Y DENTRO DEL PRODUCTO, DATOS DEL ESTABLECIMIENTO -> name!
      var query = _supabase
        .from('passport_entries')
        .select('*, event_products(establishment_id, establishments(name))') 
        .eq('user_id', currentUser.id);

      if(targetEventId != null){
        query = query.eq('event_id', targetEventId);
      }
      
      final response = await query;
      final List<dynamic> cloudEntries = response as List<dynamic>;

      // Limpieza selectiva para evitar duplicados locales
      if(targetEventId != null) {
        final keysToRemove = syncedBox.keys.where((key) {
          final entry = syncedBox.get(key);
          return entry != null && entry.eventId == targetEventId;
        }).toList();
        await syncedBox.deleteAll(keysToRemove);
      } else {
        await syncedBox.clear();
      }

      for (var item in cloudEntries) {
        final String scannedAtStr = item['scanned_at'];
        final int rating = item['rating'] ?? 0;
        final int eventId = item['event_id'] ?? 1;
        
        // EXTRAEMOS LOS DATOS ANIDADOS
        final productData = item['event_products'];
        
        int establishmentId = 0;
        String cloudBarName = ""; // Nombre que viene de la nube

        if (productData != null) {
           establishmentId = productData['establishment_id'];
           
           // Extraemos el nombre desde la relación anidada
           // 'establishments' puede ser un objeto o null
           final establishmentData = productData['establishments'];
           if (establishmentData != null) {
             cloudBarName = establishmentData['name'] ?? "";
           }
        } else {
           establishmentId = item['product_id']; 
        }

        // LÓGICA DE NOMBRE:
        // 1. Prioridad: Nombre que viene de la nube (funciona para eventos pasados).
        // 2. Fallback: Buscar en caja local (funciona para evento activo si falla nube).
        // 3. Último recurso: "ID: 123".
        
        String finalBarName = cloudBarName;

        if (finalBarName.isEmpty) {
          // Si la nube no trajo nombre, intentamos local
           try {
             final match = establishmentsBox.values.cast<EstablishmentModel>().firstWhere(
               (e) => e.id == establishmentId,
             );
             finalBarName = match.name;
           } catch (_) {
             finalBarName = "ID: $establishmentId";
           }
        }

        final downloadedEntry = PassportEntryModel(
          establishmentId: establishmentId,
          establishmentName: finalBarName, // ¡Aquí ya va el nombre correcto!
          scannedAt: DateTime.parse(scannedAtStr),
          isSynced: true,
          rating: rating,
          eventId: eventId,
        );

        // Clave única compuesta para soportar múltiples eventos
        final String uniqueKey = "${eventId}_$establishmentId";
        await syncedBox.put(uniqueKey, downloadedEntry);
      }
      
      print("✅ Sincronización completada. Total: ${cloudEntries.length}");

    } catch (e) {
      print("⚠️ Error descargando de la nube: $e");
    }

    return uploadedCount;
  }
}
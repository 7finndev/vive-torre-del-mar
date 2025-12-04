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
    final establishmentsBox = _localDb.establishmentsBox;

    int uploadedCount = 0;
    final keysToDelete = <dynamic>[];

    // ---------------------------------------------------------
    // PASO 1: SUBIDA (Móvil -> Nube) CON TRADUCCIÓN
    // ---------------------------------------------------------
    for (var key in pendingBox.keys) {
      final entry = pendingBox.get(key) as PassportEntryModel;

      if (!entry.isSynced) {
        try {
          // TRUCO DE MAGIA: Buscamos el ID REAL del producto en la nube
          // usando el ID del bar y el evento.
          final productData = await _supabase
              .from('event_products')
              .select('id')
              .eq('establishment_id', entry.establishmentId)
              .eq('event_id', entry.eventId)
              .maybeSingle();

          if (productData == null) {
            print("⚠️ Error: No existe tapa para el bar ${entry.establishmentName} en el evento ${entry.eventId}");
            // Lo borramos porque es un dato corrupto imposible de subir
            keysToDelete.add(key);
            continue;
          }

          final int realProductId = productData['id'];

          // Insertamos usando el ID de PRODUCTO correcto
          await _supabase.from('passport_entries').insert({
            'user_id': currentUser.id,
            'product_id': realProductId, // <--- ID TRADUCIDO
            'event_id': entry.eventId,
            'scanned_at': entry.scannedAt.toIso8601String(),
            'gps_verified': true, 
            'rating': entry.rating, 
          });

          // Si todo va bien, lo movemos a la caja de sincronizados
          // (Manteniendo el establishmentId local para que la UI lo entienda)
          final syncedEntry = PassportEntryModel(
             establishmentId: entry.establishmentId,
             establishmentName: entry.establishmentName,
             scannedAt: entry.scannedAt,
             isSynced: true,
             rating: entry.rating,
             eventId: entry.eventId,
          );
          
          await syncedBox.put(entry.establishmentId, syncedEntry);
          
          keysToDelete.add(key);
          uploadedCount++;

        } catch (e) {
          print("⚠️ Error subiendo sello ${entry.establishmentName}: $e");
          // Si ya existe (duplicado), lo damos por bueno y borramos de pendientes
          if (e.toString().contains("duplicate key")) {
             keysToDelete.add(key);
          }
        }
      }
    }
    await pendingBox.deleteAll(keysToDelete);


    // ---------------------------------------------------------
    // PASO 2: BAJADA (Nube -> Móvil) CON TRADUCCIÓN
    // ---------------------------------------------------------
    try {
      print("⬇️ Descargando historial de la nube...");
      
      var query = _supabase
        .from('passport_entries')
        .select('*, event_products(establishment_id)')
        .eq('user_id', currentUser.id);

      // Si nos piden un evento concreto, filtramos. Si no, bajamos todo.
      if(targetEventId != null){
        query = query.eq('event_id', targetEventId);
      }
      final response = await query;

 /*     
      // Pedimos los votos Y el dato del establecimiento asociado (JOIN)
      final response = await _supabase
          .from('passport_entries')
          .select('*, event_products(establishment_id)') // <--- JOIN CLAVE
          .eq('user_id', currentUser.id);
*/
      final List<dynamic> cloudEntries = response as List<dynamic>;

      // --- CAMBIO CRÍTICO: NO HACEMOS CLEAR GLOBAL ---
      // await syncedBox.clear(); // <--- ESTO ERA EL ERROR, BORRABA TODO

      //En su lugar: Si estamos filtrando por evento, borramos solo los de ESE
      // evento para evitar duplicados locales antes de insertar los nuevos.
      if(targetEventId != null) {
        final keysToRemove = syncedBox.keys.where((key) {
          final entry = syncedBox.get(key) as PassportEntryModel;
          return entry.eventId == targetEventId;
        }).toList();
        await syncedBox.deleteAll(keysToRemove);
      } else {
        //Si bajamos todo (login inicial), sí podemos limpiar todo
        await syncedBox.clear();
      }

      for (var item in cloudEntries) {
        final String scannedAtStr = item['scanned_at'];
        final int rating = item['rating'] ?? 0;
        final int eventId = item['event_id'] ?? 1;
        
        // RECUPERAMOS EL ID DEL ESTABLECIMIENTO DEL JOIN
        // (Supabase devuelve el objeto anidado en 'event_products')
        final productData = item['event_products'];
        int establishmentId = 0;
        
        if (productData != null) {
           establishmentId = productData['establishment_id'];
        } else {
           // Fallback por si acaso (no debería pasar)
           establishmentId = item['product_id']; 
        }

        // Buscar nombre local
        String barName = "Local Desconocido";
        try {
           final match = establishmentsBox.values.cast<EstablishmentModel>().firstWhere(
             (e) => e.id == establishmentId,
             orElse: () => EstablishmentModel(id: -1, name: "ID: $establishmentId", qrUuid: "", isActive: false)
           );
           barName = match.name;
        } catch (_) {}

        final downloadedEntry = PassportEntryModel(
          establishmentId: establishmentId, // Guardamos el ID del BAR, que es lo que usa la UI
          establishmentName: barName,
          scannedAt: DateTime.parse(scannedAtStr),
          isSynced: true,
          rating: rating,
          eventId: eventId,
        );

        // Usamos una clave compuesta para que no se pisen bares de distintos años
        // (Aunque establishmentId suele ser único, mejor asegurar)
        // OJO: Hive keys deben ser simples. Si usas establishmentId como key, 
        // el bar 19 (Granaino) del 2025 se sobrescribirá con el bar 19 del 2026.
        
        // SOLUCIÓN FINAL DE CLAVE HIVE:
        // Usamos "establishmentId" si solo hay un evento activo.
        // Pero para multievento real, necesitamos una clave única compuesta.
        // Como Hive acepta Strings, haremos "eventId_establishmentId".
        
        final String uniqueKey = "${eventId}_$establishmentId";
        await syncedBox.put(uniqueKey, downloadedEntry);

        //await syncedBox.put(establishmentId, downloadedEntry);
      }
      
      print("✅ Sincronización completada. Total en nube: ${cloudEntries.length}");

    } catch (e) {
      print("⚠️ Error descargando de la nube: $e");
    }

    return uploadedCount;
  }
}
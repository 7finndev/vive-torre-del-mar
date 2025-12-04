import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/scan/data/models/passport_entry_model.dart';

class PassportRepository {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  PassportRepository(this._supabase, this._localDb);

  Future<void> saveStamp({
    required int establishmentId,
    required String establishmentName,
    required bool gpsVerified,
    required int rating,
    required int eventId,
  }) async {
    
    // 1. Creamos el objeto con el NUEVO modelo
    final entry = PassportEntryModel(
      establishmentId: establishmentId, 
      establishmentName: establishmentName, // <--- Asignamos el nombre
      scannedAt: DateTime.now(),
      isSynced: false, 
      rating: rating,
      eventId: eventId,
    );

    // 2. Guardar en LOCAL (Hive)
    // Usamos la caja de pendientes definida en LocalDbService
    await _localDb.pendingVotesBox.add(entry);
    
    print("✅ Sello guardado en el móvil (Offline): $establishmentName");

    // NOTA: La subida a la nube la haremos más adelante cuando tengamos Login.
    // Por ahora solo guardamos en local para que veas el progreso.
  }
}
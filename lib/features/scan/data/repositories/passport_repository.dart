import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/scan/data/models/passport_entry_model.dart';

part 'passport_repository.g.dart';

class PassportRepository {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  PassportRepository(this._supabase, this._localDb);

  bool get hasPendingData => _localDb.pendingVotesBox.isNotEmpty;


  // --- 1. GUARDAR VISADO (MODIFICADO) ---
  Future<void> saveStamp({
    required int establishmentId,
    required String establishmentName,
    required bool gpsVerified,
    required int rating,
    required int eventId,
  }) async {
    // CAMBIO IMPORTANTE: Quitamos el "if (currentUser == null) return;"
    // Ahora permitimos guardar en local aunque sea un invitado.
    
    // Nota: El userId será null si no está logueado, pero no pasa nada
    // porque al sincronizar (SyncService) ya se encargará de ponerle el ID.

    final entry = PassportEntryModel(
      establishmentId: establishmentId, 
      establishmentName: establishmentName,
      scannedAt: DateTime.now(),
      isSynced: false, 
      rating: rating,
      eventId: eventId,
    );

    // Guardamos en la cajita del móvil
    await _localDb.pendingVotesBox.add(entry);
    print("✅ Sello guardado en el móvil (Offline/Guest): $establishmentName");
  }

  // --- 2. LEER VISADOS (MODIFICADO) ---
  List<PassportEntryModel> getPassportEntries(int eventId) {
    // CAMBIO IMPORTANTE: Quitamos el bloqueo de usuario null.
    // Queremos ver lo que hay en el móvil, estemos logueados o no.

    final pending = _localDb.pendingVotesBox.values.cast<PassportEntryModel>();
    final synced = _localDb.syncedStampsBox.values.cast<PassportEntryModel>();

    final allStamps = [...pending, ...synced];

    // EL FILTRO MÁGICO QUE EVITA TU MIEDO DE MEZCLAR EVENTOS:
    return allStamps.where((entry) => entry.eventId == eventId).toList();
  }

  // --- 3. LIMPIAR DATOS LOCALES ---
  // IMPORTANTE: Asegúrate de llamar a esto cuando el usuario pulse "Log Out"
  Future<void> clearLocalData() async {
    await _localDb.pendingVotesBox.clear();
    await _localDb.syncedStampsBox.clear();
    print("🧹 Datos locales del pasaporte eliminados.");
  }
}

// --- PROVIDER ---
@riverpod
PassportRepository passportRepository(PassportRepositoryRef ref) {
  return PassportRepository(
    Supabase.instance.client,
    ref.watch(localDbServiceProvider), 
  );
}
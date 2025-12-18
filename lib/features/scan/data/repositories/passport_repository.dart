import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/scan/data/models/passport_entry_model.dart';

part 'passport_repository.g.dart';

class PassportRepository {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  PassportRepository(this._supabase, this._localDb);

  // ✅ AÑÁDELO AQUÍ, JUSTO DESPUÉS DEL CONSTRUCTOR
  // Getter para saber rápidamente si hay cosas sin subir
  bool get hasPendingData => _localDb.pendingVotesBox.isNotEmpty;


  // --- 1. GUARDAR VISADO ---
  Future<void> saveStamp({
    required int establishmentId,
    required String establishmentName,
    required bool gpsVerified,
    required int rating,
    required int eventId,
  }) async {
    if (_supabase.auth.currentUser == null) return;

    final entry = PassportEntryModel(
      establishmentId: establishmentId, 
      establishmentName: establishmentName,
      scannedAt: DateTime.now(),
      isSynced: false, 
      rating: rating,
      eventId: eventId,
    );

    await _localDb.pendingVotesBox.add(entry);
    print("✅ Sello guardado en el móvil (Offline): $establishmentName");
  }

  // --- 2. LEER VISADOS ---
  List<PassportEntryModel> getPassportEntries(int eventId) {
    // Si no hay usuario, lista vacía para que no se vean datos de otro
    if (_supabase.auth.currentUser == null) {
      return [];
    }

    final pending = _localDb.pendingVotesBox.values.cast<PassportEntryModel>();
    final synced = _localDb.syncedStampsBox.values.cast<PassportEntryModel>();

    final allStamps = [...pending, ...synced];

    return allStamps.where((entry) => entry.eventId == eventId).toList();
  }

  // --- 3. LIMPIAR DATOS LOCALES (Al cerrar sesión) ---
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
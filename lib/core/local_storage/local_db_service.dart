import 'package:hive_flutter/hive_flutter.dart';

// Importaciones de tus modelos
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/scan/data/models/passport_entry_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

// IMPORTS NECESARIOS PARA EL PROVIDER
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_db_service.g.dart';

class LocalDbService {
  // Nombres de las cajas
  static const String establishmentsBoxName = 'establishments_box';
  static const String eventsBoxName = 'events_box';
  static const String pendingVotesBoxName = 'pending_votes_box';
  static const String syncedStampsBoxName = 'synced_stamps_box';
  static const String productsBoxName = 'products_box';
  
  Future<void> init() async {
    await Hive.initFlutter();
    
    // 1. Registrar Adaptadores
    // Si cambias algo en los modelos y regeneras el .g.dart,
    // Hive necesita que los datos en disco coincidan.
    Hive.registerAdapter(EstablishmentModelAdapter());
    Hive.registerAdapter(EventModelAdapter()); 
    Hive.registerAdapter(PassportEntryModelAdapter());
    Hive.registerAdapter(ProductModelAdapter());

    // 2. Abrir TODAS las cajas de forma segura
    // Si alguna falla por incompatibilidad, se reseteará automáticamente.
    await _openBoxSafely(establishmentsBoxName);
    await _openBoxSafely(eventsBoxName);
    await _openBoxSafely(pendingVotesBoxName);
    await _openBoxSafely(syncedStampsBoxName);
    await _openBoxSafely(productsBoxName);
    
    print("✅ Local Database (Hive) initialized correctly.");
  }

  // --- MÉTODO DE SEGURIDAD ---
  Future<void> _openBoxSafely(String boxName) async {
    try {
      // 1. Intentamos abrir normal
      await Hive.openBox(boxName);
    } catch (e) {
      print('⚠️ Error abriendo la caja "$boxName". Reiniciando...');
      
      try {
        // 2. Intentamos borrar. 
        // Envolvemos esto en otro try-catch por si el archivo .lock no existe.
        await Hive.deleteBoxFromDisk(boxName);
      } catch (eDelete) {
        print('ℹ️ No se pudo borrar la caja (quizás no existía archivo físico): $eDelete');
        // No hacemos nada, seguimos adelante.
      }

      // 3. Abrimos de nuevo (ahora debería estar limpia o crearse de cero)
      await Hive.openBox(boxName);
    }
  }

  // Getters
  Box get establishmentsBox => Hive.box(establishmentsBoxName);
  Box get eventsBox => Hive.box(eventsBoxName);
  Box get pendingVotesBox => Hive.box(pendingVotesBoxName);
  Box get syncedStampsBox => Hive.box(syncedStampsBoxName);
  Box get productsBox => Hive.box(productsBoxName);
}

@Riverpod(keepAlive: true)
LocalDbService localDbService(LocalDbServiceRef ref) {
  return LocalDbService();
}
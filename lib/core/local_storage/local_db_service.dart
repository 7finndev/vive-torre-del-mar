import 'package:hive_flutter/hive_flutter.dart';

// Importaciones corregidas:
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/scan/data/models/passport_entry_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

class LocalDbService {
  static const String establishmentsBoxName = 'establishments_box';
  static const String eventsBoxName = 'events_box'; // Añadimos caja para eventos
  static const String pendingVotesBoxName = 'pending_votes_box';
  static const String syncedStampsBoxName = 'synced_stamps_box';
  static const String productsBoxName = 'products_box';
  
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Registramos los adaptadores de los modelos que creamos
    // (Asegúrate de que .g.dart se haya generado correctamente)
    Hive.registerAdapter(EstablishmentModelAdapter());
    Hive.registerAdapter(EventModelAdapter()); // <--- IMPORTANTE: Registrar el Evento también
    Hive.registerAdapter(PassportEntryModelAdapter());
    Hive.registerAdapter(ProductModelAdapter());

    await Hive.openBox(establishmentsBoxName);
    await Hive.openBox(eventsBoxName);
    await Hive.openBox(pendingVotesBoxName);
    await Hive.openBox(syncedStampsBoxName);
    await Hive.openBox(productsBoxName);
  }

  Box get establishmentsBox => Hive.box(establishmentsBoxName);
  Box get eventsBox => Hive.box(eventsBoxName);
  Box get pendingVotesBox => Hive.box(pendingVotesBoxName);
  Box get syncedStampsBox => Hive.box(syncedStampsBoxName);
  Box get productsBox => Hive.box(productsBoxName);
}
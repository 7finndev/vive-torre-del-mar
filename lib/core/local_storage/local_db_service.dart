import 'package:hive_flutter/hive_flutter.dart';

// IMPORTS NECESARIOS
import 'package:flutter/foundation.dart'; // Para poder usar 'kIsWeb'
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform, Directory; // Importamos selectivamente para no ensuciar

// Importaciones de tus modelos
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_item_model.dart';
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
    
    // --- LÓGICA DE INICIALIZACIÓN HÍBRIDA ---
    
    if (kIsWeb) {
      // CASO 1: ESTAMOS EN WEB
      // En Web no hay rutas de archivos. Hive usa IndexedDB automáticamente.
      // No le pasamos ninguna ruta.
      await Hive.initFlutter();
      print("🌐 Base de datos iniciada en Navegador (IndexedDB)");
      
    } else {
      // CASO 2: ESTAMOS EN NATIVO (Móvil o Escritorio)
      // Aquí sí necesitamos definir carpetas físicas.
      
      Directory dir;
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // Escritorio: Carpeta de soporte de aplicación (Limpio y estándar)
        dir = await getApplicationSupportDirectory();
      } else {
        // Móvil: Carpeta de documentos de la App
        dir = await getApplicationDocumentsDirectory();
      }

      await Hive.initFlutter(dir.path);
      print("📂 Base de datos local guardada en: ${dir.path}");
    }

    // --- REGISTRO DE ADAPTADORES (IGUAL PARA TODOS) ---
    // Esto funciona igual en Web y Nativo
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(EstablishmentModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(EventModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ProductModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ProductItemModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(PassportEntryModelAdapter());

    // --- ABRIR CAJAS ---
    await _openBoxSafely(establishmentsBoxName);
    await _openBoxSafely(eventsBoxName);
    await _openBoxSafely(pendingVotesBoxName);
    await _openBoxSafely(syncedStampsBoxName);
    await _openBoxSafely(productsBoxName);
    
    print("✅ Local Database initialized.");
  }

  // --- MÉTODO DE SEGURIDAD ---
  Future<void> _openBoxSafely(String boxName) async {
    try {
      // 1. Intentamos abrir normal
      await Hive.openBox(boxName);
    } catch (e) {
        print('⚠️ Error crítico abriendo "$boxName": $e');
        print('🗑️ Procediendo a eliminar y recrear la caja...');
      
      try {
        // 2. Intentamos borrar. 
        // Envolvemos esto en otro try-catch por si el archivo .lock no existe.
        await Hive.deleteBoxFromDisk(boxName);
      } catch (eDelete) {
        print('ℹ️ No se pudo borrar la caja (quizás no existía archivo físico): $eDelete');
        // No hacemos nada, seguimos adelante.
      }

      // 3. Abrimos de nuevo (ahora debería estar limpia o crearse de cero)
      try {
        await Hive.openBox(boxName);
        print('✅ Caja "$boxName" recreada con éxito.');
      } catch (e2) {
        // Si falla aquí, es un problema de permisos o disco lleno
        print('❌ ERROR FATAL: No se pudo recrear la caja "$boxName": $e2');
      }
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
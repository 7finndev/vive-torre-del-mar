import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Servicio centralizado para gestionar logs y errores.
/// Úsalo en lugar de 'print()' para tener control total.
class Logger {
  
  // 1. INFO: Para cosas normales (ej: "Usuario entró en pantalla X")
  static void info(String message, [String name = 'APP']) {
    if (kDebugMode) {
      // Usamos developer.log para que no se corte si el texto es largo
      developer.log('ℹ️ $message', name: name);
    }
  }

  // 2. WARNING: Algo raro pero no rompe la app (ej: "Imagen no cargó")
  static void warning(String message, [String name = 'APP']) {
    if (kDebugMode) {
      developer.log('⚠️ $message', name: name);
    }
  }

  // 3. ERROR: Fallos críticos (ej: "Fallo conexión API", "Crash")
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // A. Mostrar en consola (Bonito y rojo si el IDE lo soporta)
    if (kDebugMode) {
      developer.log(
        '🛑 $message', 
        name: 'ERROR', 
        error: error, 
        stackTrace: stackTrace
      );
    }

    // B. (FUTURO) Aquí conectaríamos con Firebase Crashlytics
    // if (!kDebugMode) {
    //    FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    // }
  }
}
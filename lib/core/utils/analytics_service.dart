import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
//import 'package:uuid/uuid.dart';

class AnalyticsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Registra el dispositivo usando el ID persistente de Hive
  /// Ahora recibe localDb como parámetro.
  static Future<void> trackDeviceStart(LocalDbService localDb) async {
    try {
      //.-Obtener ID único (Hive):
      final String deviceId = localDb.getDeviceUuid();
      
      String os = '';
      String model = '';
      String osVersion = '';

      //.-Obtener metadatos (solo info descriptiva);
      if (kIsWeb) {
        // --- WEB ---
        os = 'web';
        final webInfo = await _deviceInfo.webBrowserInfo;
        model = webInfo.browserName.name        ;
        osVersion = webInfo.platform ?? '';
        
      } else {
        // --- MÓVILES ---
        if (Platform.isAndroid) {
          os = 'android';
          final androidInfo = await _deviceInfo.androidInfo;
          model = "${androidInfo.brand} ${androidInfo.model}";
          osVersion = androidInfo.version.release;
        } else if (Platform.isIOS) {
          os = 'ios';
          final iosInfo = await _deviceInfo.iosInfo;
          model = iosInfo.utsname.machine; //"${iosInfo.name} ${iosInfo.systemName}";
          osVersion = iosInfo.systemVersion;
        } else {
          os = 'desktop'; // Windows, Mac, Linux
          model = Platform.operatingSystem; 
        }
      }

      //.-Enviar a Supabase (BD):
      await _supabase.from('analytics_devices').upsert(
        {
          'device_id': deviceId,
          'os': os.toLowerCase(), // Forzamos minúsculas para evitar líos
          'model': model,
          'version': osVersion,
          'last_seen': DateTime.now().toIso8601String(),
          // 'created_at': (Esto lo pone Supabase solo al insertar)
        },
        onConflict: 'device_id', // Clave para detectar duplicados
      );

      print("📊 Analytics: Dispositivo registrado ($os [$model]) -> ID: $deviceId");

    } catch (e) {
      print("⚠️ Error en Analytics: $e");
      // No bloqueamos la app si falla la analítica
    }
  }
}
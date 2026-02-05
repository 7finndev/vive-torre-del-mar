import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORTACIONES FIREBASE ---
//import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
// -----------------------------

import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/core/router/app_router.dart';
import 'package:torre_del_mar_app/core/utils/analytics_service.dart';
import 'package:window_manager/window_manager.dart'; 

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar variables de entorno
  await dotenv.load(fileName: '.env');

  // 2. Inicializar formato de fechas
  await initializeDateFormatting('es'); 
  
  // 3. Inicializar Base de Datos Local (Hive)
  final localDb = LocalDbService();
  await localDb.init();

  // 4. Inicializar Supabase 
  // Es vital iniciarlo antes que Firebase para poder guardar el token si ya hay sesión.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', 
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // ------------------------------------------------------------
  // BLOQUE FIREBASE + SINCRONIZACIÓN CON SUPABASE 🔥☁️
  // ------------------------------------------------------------
  /*
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      print("✅ FIREBASE INICIALIZADO");

      final messaging = FirebaseMessaging.instance;
      
      // Pedir permisos
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Obtener Token
      final token = await messaging.getToken();
      
      if (token != null) {
        print("📬 TOKEN FCM: $token");
        
        // --- AQUÍ OCURRE LA MAGIA ---
        // Guardamos el token en Supabase si el usuario ya está logueado
        _saveTokenToSupabase(token);

        // También escuchamos si el token cambia (refresh) para actualizarlo
        messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToSupabase(newToken);
        });
        
        // Y escuchamos si el usuario hace Login ahora mismo para guardar el token
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          if (data.session != null) {
            _saveTokenToSupabase(token);
          }
        });
      }

    } catch (e) {
      print("❌ ERROR FIREBASE: $e");
    }
  }
  */
  // ------------------------------------------------------------

  // BLOQUE DE CONFIGURACIÓN DE VENTANA (SOLO ESCRITORIO)
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(900, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  //.-Iniciamos el 'Tracking' de los dispositivos:
  print("📊 Iniciando registro de dispositivo...");
  await AnalyticsService.trackDeviceStart(localDb);
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// --- FUNCIÓN AUXILIAR PARA GUARDAR EL TOKEN ---
Future<void> _saveTokenToSupabase(String token) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  // Si no hay usuario logueado, no podemos guardar nada en 'profiles' todavía.
  if (userId == null) return;

  try {
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
    
    print("💾 Token FCM guardado en el perfil del usuario: $userId");
  } catch (e) {
    print("⚠️ Error guardando token en Supabase: $e");
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Vive Torre del Mar',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, // <--- ESTO ACTIVA EL ARRASTRE CON RATÓN
    PointerDeviceKind.trackpad,
  };
}
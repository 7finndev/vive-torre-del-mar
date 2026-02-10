import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // <--- NUEVO IMPORT
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORTACIONES FIREBASE ---
//import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
// -----------------------------

import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/core/router/app_router.dart'; // <--- NUEVO IMPORT (Para rootNavigatorKey)
import 'package:torre_del_mar_app/core/utils/analytics_service.dart';
import 'package:window_manager/window_manager.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
  //Protección extra contra Tokens 'Corruptos':
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    print("⚠️ Error inicializando Supabase (Posible token caducado): $e");
  }
  
  // 🔥 BLOQUE NUEVO: ESCUCHA DE RECUPERACIÓN DE CONTRASEÑA 🔥
  // Esto detecta si el usuario acaba de entrar haciendo clic en el email de "Reset Password"
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;

    if (event == AuthChangeEvent.passwordRecovery) {
      print("🔑 Evento de recuperación de contraseña detectado!");

      // Usamos la llave maestra (que hicimos pública en app_router.dart)
      // para navegar sin necesidad de contexto local.
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          // Forzamos la navegación a la pantalla de cambio
          context.go('/update-password');
        }
      });
    }
  });
  // -----------------------------------------------------------

  // ------------------------------------------------------------
  // BLOQUE FIREBASE + SINCRONIZACIÓN CON SUPABASE 🔥☁️
  // ------------------------------------------------------------
  /*
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      // ... (Resto de tu código Firebase comentado) ...
    } catch (e) {
      print("❌ ERROR FIREBASE: $e");
    }
  }
  */

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

  runApp(const ProviderScope(child: MyApp()));
}

// --- FUNCIÓN AUXILIAR PARA GUARDAR EL TOKEN ---
Future<void> _saveTokenToSupabase(String token) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  try {
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
    print("💾 Token FCM guardado: $userId");
  } catch (e) {
    print("⚠️ Error guardando token: $e");
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
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

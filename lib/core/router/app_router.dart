import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io'; // Para Platform
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';

// UTILS
import 'package:torre_del_mar_app/core/router/go_router_refresh_stream.dart'; // <--- NUEVO IMPORT
import 'package:torre_del_mar_app/features/admin/presentation/admin_establishment_detail_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_product_detail_screen.dart';

// PROVIDERS
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart'; // <--- IMPORTANTE

// MODELOS
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

// PANTALLAS MÓVIL
import 'package:torre_del_mar_app/features/hub/presentation/hub_screen.dart';
import 'package:torre_del_mar_app/features/home/presentation/event_shell_screen.dart';
import 'package:torre_del_mar_app/features/home/presentation/home_screen.dart';
import 'package:torre_del_mar_app/features/map/presentation/map_screen.dart';
import 'package:torre_del_mar_app/features/scan/presentation/passport_screen.dart';
import 'package:torre_del_mar_app/features/home/presentation/establishments_list_screen.dart';
import 'package:torre_del_mar_app/features/home/presentation/tapas_list_screen.dart';
import 'package:torre_del_mar_app/features/home/presentation/ranking_screen.dart';
import 'package:torre_del_mar_app/features/home/presentation/establishment_detail_screen.dart';
import 'package:torre_del_mar_app/features/scan/presentation/scan_qr_screen.dart';
import 'package:torre_del_mar_app/features/auth/presentation/profile_screen.dart';
import 'package:torre_del_mar_app/features/auth/presentation/login_screen.dart';
import 'package:torre_del_mar_app/features/home/presentation/splash_screen.dart';

// PANTALLAS ADMIN
import 'package:torre_del_mar_app/features/admin/presentation/admin_shell_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/establishment_form_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_establishments_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_events_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_products_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/product_form_screen.dart';

// WIDGETS COMPARTIDOS
// Asegúrate de que este import es correcto

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // 1. Escuchamos el estado de autenticación
  final authState = ref.watch(authStateProvider);
  
  // 2. Obtenemos el STREAM (para usarlo en 'refreshListenable')
  // Nota el '.stream' al final
  final authStream = ref.watch(authStateProvider.stream);

  // Función auxiliar para saber si es entorno Desktop/Web
  bool isDesktopOrWeb() {
    if (kIsWeb) return true;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return true;
    return false;
  }

  // Lógica de ruta inicial (manteniendo tu lógica)
  String getInitialRoute() {
    if (isDesktopOrWeb()) return '/admin';
    return '/splash';
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: getInitialRoute(),

    // 2. REFRESH: Esto hace que el router se reconstruya si cambia el usuario
    refreshListenable: GoRouterRefreshStream(authStream),

    // 3. SEGURIDAD (REDIRECT ASÍNCRONO)
    // Convertimos la función en 'async' para poder consultar la BD antes de movernos
    redirect: (context, state) async {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.uri.path == '/login';
      final isGoingToAdmin = state.uri.path.startsWith('/admin');

      // -----------------------------------------------------------
      // REGLA 1: SI NO ESTÁ LOGUEADO
      // -----------------------------------------------------------
      if (isGoingToAdmin && !isLoggedIn) {
        return '/login';
      }

      // -----------------------------------------------------------
      // REGLA 2: YA LOGUEADO -> REDIRIGIR
      // -----------------------------------------------------------
      if (isLoggedIn && isLoggingIn) {
        return isDesktopOrWeb() ? '/admin' : '/';
      }

      // -----------------------------------------------------------
      // REGLA 3: EL "PORTERO" (VERIFICACIÓN DE ROL ANTI-FLASH)
      // -----------------------------------------------------------
      // Si intenta entrar al admin y está logueado, verificamos su rol
      // ANTES de dejarle pasar. Esto evita el pantallazo del dashboard.
      if (isLoggedIn && isGoingToAdmin) {
        // 1. Obtenemos el usuario
        final user = Supabase.instance.client.auth.currentUser;

        if (user != null) {
          // 2. Consultamos su rol en la base de datos (Rápido)
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          final role = profile?['role'] ?? 'user';

          // 3. Si NO es admin, le prohibimos el paso aquí mismo.
          if (role != 'admin') {
            // Opcional: Hacemos logout aquí para limpiar, aunque LoginScreen también lo hará.
            // await Supabase.instance.client.auth.signOut();
            return '/login';
          }
        }
      }

      return null; // Todo correcto, pase usted.
    },

    routes: [
      // --- LOGIN ---
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // =====================================================================
      // 🌍 ZONA PÚBLICA (MÓVIL)
      // =====================================================================
      
      // Ruta de Splash Screen:
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(path: '/', builder: (context, state) => const HubScreen()),

      // MODO EVENTO (Con Barra Inferior)
      GoRoute(
        path: '/event/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          if (state.uri.path == '/event/$id') return '/event/$id/dashboard';
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              final eventId = state.pathParameters['id'] ?? '1';
              return EventShellScreen(
                navigationShell: navigationShell,
                eventId: eventId,
              );
            },
            branches: [
              // 0. Dashboard
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) => const HomeScreen(),
                  ),
                ],
              ),
              // 1. Mapa
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'map',
                    builder: (context, state) => const MapScreen(),
                  ),
                ],
              ),
              // 2. Locales
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'locales',
                    //builder: (context, state) => const EstablishmentsListScreen(),
                    builder: (context, state) {
                      // 1. Buscamos el parámetro 'eventId' en la URL
                      // (Asumiendo que tu ruta padre es algo como path: '/event/:eventId')
                      final idString = state.pathParameters['eventId'];

                      // 2. Lo convertimos de Texto a Número (con seguridad)
                      // Si falla o es nulo, usamos 1 por defecto para que no explote.
                      final eventId = int.tryParse(idString ?? '') ?? 1;

                      // 3. Pasamos el ID a la pantalla
                      return EstablishmentsListScreen(eventId: eventId);
                    },
                  ),
                ],
              ),
              // 3. Tapas/Cócteles
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'tapas',
                    builder: (context, state) => const TapasListScreen(),
                  ),
                ],
              ),
              // 4. Ranking
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'ranking',
                    builder: (context, state) => const RankingScreen(),
                  ),
                ],
              ),
              // 5. Pasaporte
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'passport',
                    builder: (context, state) => const PassportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // PANTALLAS SUELTAS
      // Ruta para profile (perfil o usuarios)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile',
        builder: (context, state) {
          final user = authState.valueOrNull;
          if (user == null) return const LoginScreen();

          // --- CAMBIO AQUÍ ---
          // Intentamos leer el 'eventId' si viene en el objeto 'extra'
          // Esto permite que el perfil sepa si venimos de un evento o del Hub
          final int? eventId = state.extra as int?;

          return ProfileScreen(eventId: eventId);
        },
      ),
      // Nueva ruta para vincular pasaporte físico
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/scan_physical_passport',
        builder: (context, state) {
          // TODO: Aquí iría tu pantalla real de escaneo (ej: ScanPhysicalPassportScreen)
          // De momento ponemos un placeholder funcional
          return Scaffold(
            appBar: AppBar(title: const Text("Vincular Pasaporte")),
            body: const Center(
              child: Text("Funcionalidad de escáner en construcción 🚧"),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/detail',
        builder: (context, state) {
          final bar = state.extra as EstablishmentModel;
          return EstablishmentDetailScreen(establishment: bar);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/scan',
        builder: (context, state) {
          final bar = state.extra as EstablishmentModel;
          return ScanQrScreen(establishment: bar);
        },
      ),

      // =====================================================================
      // 🛠️ ZONA PRIVADA (ADMINISTRACIÓN)
      // =====================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShellScreen(navigationShell: navigationShell),
        branches: [
          // 0. Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (_, __) => const AdminDashboardScreen(),
              ),
            ],
          ),
          // 1. Socios (Lista de Bares)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/socios',
                builder: (_, __) => const AdminEstablishmentsScreen(),
                routes: [
                  // Sub-ruta 1: Nuevo
                  GoRoute(
                    path: 'nuevo',
                    builder: (_, __) => const EstablishmentFormScreen(),
                  ),

                  // Sub-ruta 2: Detalle
                  // La URL final será: /admin/socios/detail
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final establishment = state.extra as EstablishmentModel;
                      return AdminEstablishmentDetailScreen(
                        establishment: establishment,
                      );
                    },
                  ),

                  // Sub-ruta 3: Editar
                  GoRoute(
                    path: 'edit', //La url sera '/admin/socios/edit'
                    builder: (context, state) {
                      final establishment = state.extra as EstablishmentModel;
                      //Reutilizamos el formulario pero pasándole el objeto para editar
                      return EstablishmentFormScreen(
                        establishmentToEdit: establishment,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 2. Eventos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/events',
                builder: (_, __) => const AdminEventsScreen(),
              ),
            ],
          ),
          // 3. Participaciones
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/participaciones',
                builder: (context, state) => const AdminProductsScreen(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    name: 'product_form',
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>?;
                      final eventId = args?['eventId'] as int? ?? 0;
                      final product = args?['productToEdit'] as ProductModel?;

                      return ProductFormScreen(
                        initialEventId: eventId,
                        productToEdit: product,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'detail', // URL: /admin/participaciones/detail
                    builder: (context, state) {
                      final product = state.extra as ProductModel;
                      return AdminProductDetailScreen(product: product);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

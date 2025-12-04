import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';

// PANTALLAS ADMIN
import 'package:torre_del_mar_app/features/admin/presentation/admin_shell_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/establishment_form_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_establishments_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // CAMBIA ESTO A '/' PARA PROBAR MÓVIL O '/admin/socios' PARA PROBAR ADMIN
    initialLocation: '/',
    //initialLocation: '/admin/socios',

    // Guarda de seguridad :
    redirect: (context, state) async {
      // 1.- Decisión del usuario a donde ir:
      final String location = state.uri.path;

      // 2.- Zona protegida (/admin ...):
      final bool isGoingToAdmin = location.startsWith('/admin');

      // Si no es zona protegida, seguimos:
      if(!isGoingToAdmin) return null;

      // 3.- Si es zona protegida: comprobar permisos
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // A.- Si no está logueado, pantalla login
      if(user == null){
        print("⛔ Acceso denegado: Usuario no logueado intentando entrar en Zona Admin.");
        return '/profile';
      }
      // B.- ver si es Admin consultando a la BBDD (consulta directa)
      try{
        final profile = await supabase
          .from('profile')
          .select('role')
          .eq('id', user.id)
          .single();

        final String role = profile['role'] ?? 'user';

        if(role != 'admin'){
          print("⛔ Acceso denegado: El usuario ${user.email} no es admin");
          return '/'; // Direccionamos a la pantalla inicial Zona Usuarios
        }
        return null;
      } catch (e){
        // Fallo en la consulta (ej: no internet), volvemos a zona Usuarios.
        return '/';
      }
    },
    routes: [
      // =====================================================================
      // 🌍 ZONA PÚBLICA (MÓVIL)
      // =====================================================================

      // 1. HUB PRINCIPAL
      GoRoute(path: '/', builder: (context, state) => const HubScreen()),

      // 2. MODO EVENTO (Con Barra Inferior)
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
                    builder: (context, state) =>
                        const EstablishmentsListScreen(),
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

      // 3. PANTALLAS SUELTAS
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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
                builder: (_, __) => const Scaffold(
                  body: Center(child: Text("Dashboard Admin")),
                ),
              ),
            ],
          ),
          // 1. Socios (Lista de Bares)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/socios',
                builder: (_, __) =>
                    const AdminEstablishmentsScreen(), // <--- LA LISTA
                routes: [
                  // Sub-ruta para crear uno nuevo
                  GoRoute(
                    path: 'nuevo', // Se accede como /admin/socios/nuevo
                    builder: (_, __) => const EstablishmentFormScreen(),
                  ),
                ],
              ),
            ],
          ), // 2. Eventos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/eventos',
                builder: (_, __) => const Scaffold(
                  body: Center(child: Text("Gestión Eventos")),
                ),
              ),
            ],
          ),
          // 3. Participaciones (Alta Tapas) - AQUÍ PODRÁS AÑADIR LAS TAPAS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/participaciones',
                builder: (_, __) => const Scaffold(
                  body: Center(child: Text("Alta de Tapas (Próximamente)")),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

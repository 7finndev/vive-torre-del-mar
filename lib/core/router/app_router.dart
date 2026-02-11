import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// UTILS
import 'package:torre_del_mar_app/core/router/go_router_refresh_stream.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_news_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_user_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_winner_check_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/screens/admin_sponsors_screen.dart';

// PROVIDERS
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/auth/presentation/register_screen.dart';
import 'package:torre_del_mar_app/features/auth/presentation/update_password_screen.dart';

// MODELOS
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

// PANTALLAS MÓVIL (PÚBLICAS)
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

// PANTALLAS ADMIN (PRIVADAS)
import 'package:torre_del_mar_app/features/admin/presentation/admin_shell_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/establishment_form_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_establishments_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_events_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_products_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/product_form_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_establishment_detail_screen.dart';
import 'package:torre_del_mar_app/features/admin/presentation/admin_product_detail_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);
  
  //Modificación para corregir salto de pantalla (a pantalla inicial) 
  //  al actualizar datos del perfil.
  //final authStream = ref.watch(authStateProvider.stream);
  final authStream = Supabase.instance.client.auth.onAuthStateChange.where(
    (data) => data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // 1. ESTRATEGIA: Siempre entramos al Hub público
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),

    // 2. EL PORTERO SIMPLIFICADO
    redirect: (context, state) async {
      final isLoggedIn = authState.valueOrNull != null;
      final isGoingToAdmin = state.uri.path.startsWith('/admin');
      final isGoingToLogin = state.uri.path == '/login';

      // Si va a recuperar contraseña, dejar pasar siempre:
      final isGoiongToRecovery = state.uri.path == '/update-password';
      if(isGoiongToRecovery){
        return null;
      }

      // CASO A: INTENTA ENTRAR A ZONA ADMIN
      if (isGoingToAdmin) {
        // Si no está logueado -> Al login (con aviso de que es para admin)
        if (!isLoggedIn) {
          return '/login?admin=true';
        }

        // Si está logueado, verificamos ROL en base de datos
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          final role = profile?['role'] ?? 'user';

          // Si NO es admin, lo echamos al Hub público
          if (role != 'admin') {
            return '/';
          }
        }
      }

      // CASO B: ESTÁ EN LOGIN PERO YA TIENE SESIÓN
      if (isLoggedIn && isGoingToLogin) {
        // Si viene de ?admin=true intentaremos mandarlo al admin,
        // si no, al hub. Pero por simplicidad, mandamos al Hub y que él navegue.
        return '/';
      }

      // CASO C: TODO LO DEMÁS (Rutas públicas)
      return null; // Pase usted
    },

    routes: [
      // --- LOGIN ---
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),

      // =====================================================================
      // 🌍 ZONA PÚBLICA (ACCESIBLE PARA TODOS)
      // =====================================================================
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // PÁGINA PRINCIPAL
      GoRoute(path: '/', builder: (context, state) => const HubScreen()),

      // MODO EVENTO (Sub-rutas públicas)
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
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (_, __) => const HomeScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(path: 'map', builder: (_, __) => const MapScreen()),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'locales',
                    builder: (context, state) {
                      final idString = state.pathParameters['eventId'];
                      final eventId = int.tryParse(idString ?? '') ?? 1;
                      return EstablishmentsListScreen(eventId: eventId);
                    },
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'tapas',
                    builder: (_, __) => const TapasListScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'ranking',
                    builder: (_, __) => const RankingScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'passport',
                    builder: (_, __) => const PassportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // PANTALLAS SUELTAS PÚBLICAS
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/profile',
        builder: (context, state) {
          // Si no está logueado, al perfil le mandamos al login
          // (Es el único sitio público que requiere login básico)
          if (authState.valueOrNull == null) return const LoginScreen();
          final int? eventId = state.extra as int?;
          return ProfileScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          // 🛡️ BLINDAJE ANTI-CRASH WEB
          final extra = state.extra;
          EstablishmentModel establishment;

          if (extra is EstablishmentModel) {
            // Caso normal: Viene la clase
            establishment = extra;
          } else if (extra is Map<String, dynamic>) {
            // Caso Web/Restart: Viene un JSON, lo convertimos
            establishment = EstablishmentModel.fromJson(extra);
          } else {
            // Caso de emergencia (evita pantalla roja)
            // Crea un objeto dummy o redirige a error
            return const Scaffold(
              body: Center(child: Text("Error al cargar datos del local")),
            );
          }

          return EstablishmentDetailScreen(establishment: establishment);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/scan',
        builder: (context, state) {
          final bar = state.extra as EstablishmentModel;
          return ScanQrScreen(establishment: bar);
        },
      ),

      // =====================================================================
      // 🛠️ ZONA PRIVADA (ADMINISTRACIÓN) - Protegida por el 'redirect'
      // =====================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (_, __) => const AdminDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'sponsors', // --> /admin/sponsors
                    builder: (context, state) {
                      return const AdminSponsorsScreen();
                    },
                  ),
                  // Sub-ruta: Noticias
                  GoRoute(
                    path: 'news', // --> /admin/news
                    builder: (context, state) => const AdminNewsScreen(),
                  ),
                  // Sub-ruta: Validar Ganador
                  GoRoute(
                    path: 'check-winner', // La URL será /admin/check-winner
                    builder: (context, state) => const AdminWinnerCheckScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/socios',
                builder: (_, __) => const AdminEstablishmentsScreen(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    builder: (_, __) => const EstablishmentFormScreen(),
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final establishment = state.extra as EstablishmentModel;
                      return AdminEstablishmentDetailScreen(
                        establishment: establishment,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final establishment = state.extra as EstablishmentModel;
                      return EstablishmentFormScreen(
                        establishmentToEdit: establishment,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/events',
                builder: (_, __) => const AdminEventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/products',
                builder: (_, __) => const AdminProductsScreen(),
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
                    path: 'detail',
                    builder: (context, state) {
                      final product = state.extra as ProductModel;
                      return AdminProductDetailScreen(product: product);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (_, __) => const AdminUsersScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

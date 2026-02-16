import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// UTILS
import 'package:torre_del_mar_app/core/widgets/error_view.dart'; // Asegúrate de importar ErrorView
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
  
  final authStream = Supabase.instance.client.auth.onAuthStateChange.where(
    (data) => data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),

    redirect: (context, state) async {
      final isLoggedIn = authState.valueOrNull != null;
      final isGoingToAdmin = state.uri.path.startsWith('/admin');
      final isGoingToLogin = state.uri.path == '/login';
      final isGoiongToRecovery = state.uri.path == '/update-password';
      
      if(isGoiongToRecovery) return null;

      if (isGoingToAdmin) {
        if (!isLoggedIn) return '/login?admin=true';

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          final role = profile?['role'] ?? 'user';
          if (role != 'admin') return '/';
        }
      }

      if (isLoggedIn && isGoingToLogin) return '/';

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/update-password', builder: (context, state) => const UpdatePasswordScreen()),
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const HubScreen()),

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
              StatefulShellBranch(routes: [GoRoute(path: 'dashboard', builder: (_, __) => const HomeScreen())]),
              StatefulShellBranch(routes: [GoRoute(path: 'map', builder: (_, __) => const MapScreen())]),
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
              StatefulShellBranch(routes: [GoRoute(path: 'tapas', builder: (_, __) => const TapasListScreen())]),
              StatefulShellBranch(routes: [GoRoute(path: 'ranking', builder: (_, __) => const RankingScreen())]),
              StatefulShellBranch(routes: [GoRoute(path: 'passport', builder: (_, __) => const PassportScreen())]),
            ],
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/profile',
        builder: (context, state) {
          if (authState.valueOrNull == null) return const LoginScreen();
          final int? eventId = state.extra as int?;
          return ProfileScreen(eventId: eventId);
        },
      ),

      // 🛡️ DETAIL: PROTEGIDO (Tu código original)
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final extra = state.extra;
          EstablishmentModel establishment;

          if (extra is EstablishmentModel) {
            establishment = extra;
          } else if (extra is Map) { // Usamos 'is Map' general
            // .from asegura que el cast sea correcto
            establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
          } else {
            return const Scaffold(body: Center(child: Text("Error al cargar datos del local")));
          }

          return EstablishmentDetailScreen(establishment: establishment);
        },
      ),

      // 🔥 SCAN: PROTEGIDO (NUEVO FIX)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/scan',
        builder: (context, state) {
          final extra = state.extra;
          EstablishmentModel establishment;

          // Aquí aplicamos la misma lógica robusta que en /detail
          if (extra is EstablishmentModel) {
            establishment = extra;
          } else if (extra is Map) {
            establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
          } else {
            // Si el usuario recarga la página /scan directamente sin datos, 
            // le mandamos un error o al inicio.
            return const ErrorView(error: "Datos del escáner no encontrados. Vuelve al listado.");
          }

          return ScanQrScreen(establishment: establishment);
        },
      ),

      // =====================================================================
      // 🛠️ ZONA ADMIN
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
                  GoRoute(path: 'sponsors', builder: (context, state) => const AdminSponsorsScreen()),
                  GoRoute(path: 'news', builder: (context, state) => const AdminNewsScreen()),
                  GoRoute(path: 'check-winner', builder: (context, state) => const AdminWinnerCheckScreen()),
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
                  GoRoute(path: 'nuevo', builder: (_, __) => const EstablishmentFormScreen()),
                  
                  // PROTEGIDO TAMBIÉN EN ADMIN POR SI ACASO
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      EstablishmentModel establishment;
                      if (extra is EstablishmentModel) {
                        establishment = extra;
                      } else if (extra is Map) {
                        establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
                      } else {
                        return const ErrorView(error: "Error cargando detalle admin");
                      }
                      return AdminEstablishmentDetailScreen(establishment: establishment);
                    },
                  ),
                  
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final extra = state.extra;
                      EstablishmentModel establishment;
                      if (extra is EstablishmentModel) {
                        establishment = extra;
                      } else if (extra is Map) {
                        establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
                      } else {
                        return const ErrorView(error: "Error cargando edición");
                      }
                      return EstablishmentFormScreen(establishmentToEdit: establishment);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/events', builder: (_, __) => const AdminEventsScreen()),
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
                      // El productToEdit ya viene dentro del mapa, no hay problema de casting directo aquí
                      // porque 'args' ya se trata como mapa.
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
                      // Protección básica también para productos
                      final extra = state.extra;
                      ProductModel product;
                      if (extra is ProductModel) {
                        product = extra;
                      } else if (extra is Map) {
                        product = ProductModel.fromJson(Map<String, dynamic>.from(extra));
                      } else {
                         return const ErrorView(error: "Error cargando producto");
                      }
                      return AdminProductDetailScreen(product: product);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}
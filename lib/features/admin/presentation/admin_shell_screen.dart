import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';

class AdminShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos el usuario actual
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Admin';

    return Scaffold(
      body: Row(
        children: [
          // 1. SINGLE CHILD SCROLL VIEW: Permite scroll si la pantalla es bajita
          SingleChildScrollView(
            // 2. CONSTRAINED BOX: Asegura que ocupe al menos toda la altura
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              // 3. INTRINSIC HEIGHT: Necesario para que el Rail se dibuje bien dentro del scroll
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (int index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  // IMPORTANTE: Definimos un ancho fijo cuando está extendido
                  minExtendedWidth: 220, 
                  extended: true,
                  
                  // CABECERA
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        const Icon(Icons.admin_panel_settings, size: 40, color: Colors.orange),
                        const SizedBox(height: 8),
                        Text(
                          "PANEL ADMIN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // DESTINOS
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.store_outlined),
                      selectedIcon: Icon(Icons.store),
                      label: Text('Establecimientos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.event_outlined),
                      selectedIcon: Icon(Icons.event),
                      label: Text('Eventos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_bar_outlined),
                      selectedIcon: Icon(Icons.local_bar),
                      label: Text('Participaciones'),
                    ),
                  ],
                  
                  // PIE DE PÁGINA
                  trailing: Column( 
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Usamos un Spacer NO funcionaría aquí dentro de un ScrollView.
                      // Usamos un SizedBox grande o dejamos que el mainAxisAlignment lo empuje si usamos Expanded (pero aquí no podemos).
                      // Como estamos en un ScrollView, el contenido se apila.
                      const SizedBox(height: 50), 
                      const Divider(),
                      
                      SizedBox(
                        width: 180, 
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                child: Icon(Icons.person, size: 20),
                              ),
                              const SizedBox(width: 8),
                              
                              Flexible( 
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Hola,", 
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600])
                                    ),
                                    Text(
                                      email,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // Botón Salir
                      SizedBox(
                        width: 180, 
                        child: TextButton.icon(
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).signOut();
                          },
                          icon: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                          label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const VerticalDivider(thickness: 1, width: 1),
          
          // CONTENIDO PRINCIPAL
          Expanded(
            child: navigationShell,
          ),
        ],
      ),
    );
  }
}
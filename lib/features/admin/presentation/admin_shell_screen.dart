import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // BARRA LATERAL (Solo Web/Tablet)
          NavigationRail(
            backgroundColor: Colors.blueGrey[900],
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedIconTheme: const IconThemeData(color: Colors.orange),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            extended: true, // Muestra texto
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.store),
                label: Text('Socios (Bares)'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event),
                label: Text('Eventos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_bar), // O Icon(Icons.tapas)
                label: Text('Participaciones'),
              ),
            ],
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(index);
            },
          ),
          
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(20),
              child: navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}
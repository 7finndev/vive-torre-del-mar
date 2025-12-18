import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // El cuerpo es la rama actual
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Navegar a la rama (tab) correspondiente
          navigationShell.goBranch(
            index,
            // Soporte para ir al inicio de la rama si ya estás en ella
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.qr_code), label: 'Pasaporte'),
          NavigationDestination(icon: Icon(Icons.hub), label: 'Hub'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
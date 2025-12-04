import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';

class EventShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final String eventId;

  const EventShellScreen({
    required this.navigationShell,
    required this.eventId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Actualizar ID global (Lógica técnica)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final int id = int.parse(eventId);
        // Solo actualizamos si ha cambiado para evitar bucles
        if (ref.read(currentEventIdProvider) != id) {
          ref.read(currentEventIdProvider.notifier).state = id;
        }
      } catch (e) {
        print("Error parsing event ID: $e");
      }
    });

    // 2. LEER EVENTO PARA SABER EL TIPO (Lógica Visual)
    final eventAsync = ref.watch(currentEventProvider);

    String productLabel = "Tapas"; // Valor por defecto
    Color themeColor = Colors.orange; //Color por defecto.

    if (eventAsync.hasValue && eventAsync.value != null) {
      final event = eventAsync.value!;
      final type = eventAsync.value!.type;
      if (type == 'drinks') productLabel = "Cócteles";
      if (type == 'shopping') productLabel = "Tiendas";

      try {
         themeColor = Color(int.parse(event.themeColorHex.replaceAll('#', '0xff')));
       } catch (_) {}
    }
    // ------------------------------------------------

    return PopScope(
      // canPop: false significa "no cierres la app automaticamente"
      canPop: false,

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Si ya se procesó, no hacer nada

        //lógica de retorno:
        final currentTab = navigationShell.currentIndex;

        if (currentTab != 0) {
          // Nivel 1: Si no estamos en la primera pestaña (Dashboard), vamos a ella.
          navigationShell.goBranch(0);
        } else {
          // Nivel 2: Si ya estamos en Dashboard, salimos al HUB Principal.
          context.go('/');
        }
      },

      child: Scaffold(
        body: navigationShell,

        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          indicatorColor: themeColor.withOpacity(0.3), //Colors.orange[100],
          backgroundColor: themeColor.withOpacity(0.05),

          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            // Quitamos 'const' porque ahora la lista es dinámica
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Locales',
            ),

            // --- AQUÍ USAMOS LA VARIABLE ---
            NavigationDestination(
              icon: const Icon(Icons.local_dining_outlined),
              selectedIcon: const Icon(Icons.local_dining),
              label: productLabel, // <--- Ahora sí existe
            ),

            // ------------------------------
            const NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Ranking',
            ),
            const NavigationDestination(
              icon: Icon(Icons.verified_outlined),
              selectedIcon: Icon(Icons.verified),
              label: 'Pasaporte',
            ),
          ],
        ),
      ),
    );
  }
}

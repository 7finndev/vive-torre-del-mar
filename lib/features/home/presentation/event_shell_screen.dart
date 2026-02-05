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
    // 1. Lógica de ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final int id = int.parse(eventId);
        if (ref.read(currentEventIdProvider) != id) {
          ref.read(currentEventIdProvider.notifier).state = id;
        }
      } catch (e) {
        print("Error parsing event ID: $e");
      }
    });

    // 2. Lógica Visual (Colores e Iconos)
    final eventAsync = ref.watch(currentEventProvider);
    String productLabel = "Tapas";
    IconData productIcon = Icons.local_dining_outlined;
    IconData productIconSelected = Icons.local_dining;
    Color themeColor = Colors.orange;

    if (eventAsync.hasValue && eventAsync.value != null) {
      final event = eventAsync.value!;
      final type = event.type;
      
      if (type == 'menu') {
        productLabel = "Menús";
        productIcon = Icons.restaurant_menu_outlined;
        productIconSelected = Icons.restaurant_menu;
      } else if (type == 'drinks' || type == 'cocktail') {
        productLabel = "Cócteles";
        productIcon = Icons.local_bar_outlined;
        productIconSelected = Icons.local_bar;
      } else if (type == 'shopping') {
        productLabel = "Tiendas";
        productIcon = Icons.shopping_bag_outlined;
        productIconSelected = Icons.shopping_bag;
      }

      try {
         themeColor = Color(int.parse(event.themeColorHex.replaceAll('#', '0xff')));
       } catch (_) {}
    }

    // 3. Responsive
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isDesktop = width > 900;

    // Destinos
    final destinations = [
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
      const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
      const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Locales'),
      NavigationDestination(icon: Icon(productIcon), selectedIcon: Icon(productIconSelected), label: productLabel),
      const NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Ranking'),
      const NavigationDestination(icon: Icon(Icons.verified_outlined), selectedIcon: Icon(Icons.verified), label: 'Pasaporte'),
    ];

    final railDestinations = destinations.map((d) => NavigationRailDestination(
      icon: d.icon, 
      selectedIcon: d.selectedIcon, 
      label: Text(d.label),
    )).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final currentTab = navigationShell.currentIndex;
        if (currentTab != 0) {
          navigationShell.goBranch(0);
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        body: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BARRA LATERAL (Solo Navegación + Botón Atrás) ---
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: (index) => _onTap(context, navigationShell, index),
                          
                          // 🔥 SOLO BOTÓN ATRÁS (Limpio)
                          leading: Column(
                            children: [
                              const SizedBox(height: 20),
                              FloatingActionButton(
                                elevation: 0,
                                backgroundColor: Colors.grey[200],
                                tooltip: "Volver al inicio",
                                onPressed: () => context.go('/'),
                                child: const Icon(Icons.arrow_back, color: Colors.black87),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),

                          labelType: NavigationRailLabelType.all,
                          destinations: railDestinations,
                          selectedIconTheme: IconThemeData(color: themeColor),
                          useIndicator: true,
                          indicatorColor: themeColor.withOpacity(0.2),
                          elevation: 1,
                          minWidth: 80,
                          groupAlignment: -1.0, 
                        ),
                      ),
                    ),
                  ),
                  
                  const VerticalDivider(thickness: 1, width: 1),

                  // --- CONTENIDO DEL EVENTO (Sin barras extra) ---
                  Expanded(child: navigationShell),
                ],
              )
            // MÓVIL
            : navigationShell,

        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                indicatorColor: themeColor.withOpacity(0.3),
                backgroundColor: themeColor.withOpacity(0.05),
                onDestinationSelected: (index) => _onTap(context, navigationShell, index),
                destinations: destinations,
              ),
      ),
    );
  }

  void _onTap(BuildContext context, StatefulNavigationShell shell, int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }
}
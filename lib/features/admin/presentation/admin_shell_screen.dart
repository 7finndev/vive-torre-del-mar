import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/core/widgets/version_tag.dart';

class AdminShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Detectamos si es pantalla grande
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 900;

    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Admin';

    final menuContent = _AdminMenuContent(
      navigationShell: navigationShell,
      email: email,
      onLogout: () async {
        await ref.read(authRepositoryProvider).signOut();
        if (context.mounted) context.go('/login');
      },
    );

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("Panel Administración", style: TextStyle(color: Colors.white, fontSize: 16)),
              backgroundColor: const Color(0xFF2C3E50),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: isDesktop ? null : Drawer(child: menuContent),
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 250,
              child: menuContent,
            ),
          Expanded(
            child: navigationShell,
          ),
        ],
      ),
    );
  }
}

class _AdminMenuContent extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String email;
  final VoidCallback onLogout;

  const _AdminMenuContent({
    required this.navigationShell,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C3E50),
      child: Column(
        children: [
          // 1. CABECERA (Esta la dejamos fija arriba para identidad)
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            color: const Color(0xFF1A252F),
            width: double.infinity,
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings, size: 50, color: Colors.orange),
                const SizedBox(height: 10),
                const Text("VIVE TORRE DEL MAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                Text(email, style: const TextStyle(color: Colors.white54, fontSize: 10), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // 2. LISTA CON TODO (MENU + OPCIONES FINALES)
          // Usamos Expanded para que ocupe el resto y permita SCROLL
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // --- SECCIÓN PRINCIPAL ---
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text("GESTIÓN", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                _AdminMenuItem(icon: Icons.dashboard, label: "Dashboard", index: 0, navigationShell: navigationShell),
                _AdminMenuItem(icon: Icons.store, label: "Establecimientos", index: 1, navigationShell: navigationShell),
                _AdminMenuItem(icon: Icons.event, label: "Eventos", index: 2, navigationShell: navigationShell),
                _AdminMenuItem(icon: Icons.local_bar, label: "Productos", index: 3, navigationShell: navigationShell),
                
                const Divider(color: Colors.white10, height: 30),

                // --- SECCIÓN SECUNDARIA ---
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text("DATOS", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                ),

                // 1. NOTICIAS (NUEVO) 🆕
                ListTile(
                  leading: const Icon(Icons.newspaper, color: Colors.white70),
                  title: const Text("Noticias", style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    _closeDrawer(context);
                    context.push('/admin/news'); // Navegamos a la ruta nueva
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.white70),
                  title: const Text("Patrocinadores", style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    _closeDrawer(context);
                    context.push('/admin/sponsors');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.white70),
                  title: const Text("Usuarios", style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    _closeDrawer(context);
                    context.push('/admin/users');
                  },
                ),

                const Divider(color: Colors.white10, height: 30),

                // --- 🔥 AQUÍ ESTÁ EL CAMBIO: FOOTER INTEGRADO EN EL SCROLL 🔥 ---
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text("SISTEMA", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                ),

                // 1. VOLVER A APP
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: Colors.greenAccent),
                  title: const Text("Volver a App", style: TextStyle(color: Colors.greenAccent)),
                  onTap: () {
                     context.go('/'); 
                  },
                ),

                // 2. CERRAR SESIÓN
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
                  onTap: onLogout,
                ),

                // 3. VERSIÓN
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: VersionTag(color: Colors.white30)),
                ),
                
                // Un poco de aire al final para que no quede pegado en móviles
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _closeDrawer(BuildContext context) {
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final StatefulNavigationShell navigationShell;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = navigationShell.currentIndex == index;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.orange : Colors.white70),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
      onTap: () {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
        if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      },
    );
  }
}
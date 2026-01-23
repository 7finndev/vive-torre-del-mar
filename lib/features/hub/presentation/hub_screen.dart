import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/core/utils/event_type_helper.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// IMPORTS DEL PROYECTO
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';

// ✅ RUTAS CORREGIDAS:
import 'package:torre_del_mar_app/features/scan/data/repositories/passport_repository.dart';
import 'package:torre_del_mar_app/features/auth/data/repositories/auth_repository.dart'; // <--- ESTA ERA LA QUE FALLABA

import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart'
    hide passportRepositoryProvider;
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/features/hub/data/news_service.dart';

// ✅ WIDGET DE ERROR
import 'package:torre_del_mar_app/core/widgets/error_view.dart';

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Función para recargar datos al deslizar
  Future<void> _refreshData() async {
    ref.refresh(adminEventsListProvider);
    ref.refresh(newsProvider);
    ref.refresh(sponsorsListProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    // 1. LEER ESTADOS
    final selectedFilter = ref.watch(hubFilterProvider);
    final eventsAsync = ref.watch(adminEventsListProvider);
    final sponsorsAsync = ref.watch(sponsorsListProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],

      // --- A. MENÚ LATERAL (RESTAURADO) ---
      endDrawer: const _HubSideMenu(),

      // --- PULL TO REFRESH ---
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.blue[900],
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- B. CABECERA ---
            SliverAppBar(
              title: const Text(
                "VIVE TORRE DEL MAR",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),
              backgroundColor: Colors.white,
              floating: true,
              pinned: true,
              elevation: 0,
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
                const SizedBox(width: 12),
              ],
            ),

            // --- C. CARRUSEL DE NOTICIAS ---
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "DESTACADOS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse("https://www.torredelmar.org/eventos/"),
                          ),
                          child: Text(
                            "Ver web >",
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _NewsCarouselSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // --- D. FILTROS ---
            SliverToBoxAdapter(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: "🔥 Activos",
                        isSelected: selectedFilter == 'active',
                        onTap: () =>
                            ref.read(hubFilterProvider.notifier).state =
                                'active',
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: "🔜 Próximos",
                        isSelected: selectedFilter == 'upcoming',
                        onTap: () =>
                            ref.read(hubFilterProvider.notifier).state =
                                'upcoming',
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: "📜 Historial",
                        isSelected: selectedFilter == 'archived',
                        onTap: () =>
                            ref.read(hubFilterProvider.notifier).state =
                                'archived',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- E. LISTA DE EVENTOS (CON ERRORVIEW) ---
            eventsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(error: err, onRetry: _refreshData),
              ),
              data: (events) {
                final filteredEvents = events.where((e) {
                  final status = e.status.toLowerCase().trim();
                  if (selectedFilter == 'active') return status == 'active';
                  if (selectedFilter == 'upcoming') return status == 'upcoming';
                  if (selectedFilter == 'archived') {
                    return status == 'archived' || status == 'finished';
                  }
                  return true;
                }).toList();

                if (filteredEvents.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(filter: selectedFilter),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = filteredEvents[index];
                      return _HubEventCard(event: event);
                    }, childCount: filteredEvents.length),
                  ),
                );
              },
            ),

            // --- F. COLABORADORES ---
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            const SliverToBoxAdapter(
              child: Center(
                child: Text(
                  "COLABORADORES",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            sponsorsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ErrorView(
                    error: err,
                    isCompact: true,
                    onRetry:
                        _refreshData, // Usamos la función de recarga general
                  ),
                ),
              ),
              data: (sponsors) {
                if (sponsors.isEmpty)
                  return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          mainAxisExtent: 80,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final sponsor = sponsors[index];

                      return Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap:
                              (sponsor.websiteUrl != null &&
                                  sponsor.websiteUrl!.isNotEmpty)
                              ? () async {
                                  final uri = Uri.parse(sponsor.websiteUrl!);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                              child: Image.network(
                                sponsor.logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        Text(
                                          sponsor.name,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: sponsors.length),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

// 1. MENÚ LATERAL CON AVATAR (RESTAURADO)
class _HubSideMenu extends ConsumerWidget {
  const _HubSideMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    String displayName = "Usuario";
    String? avatarUrl;

    if (user != null) {
      final metadata = user.userMetadata;
      if (metadata != null) {
        if (metadata.containsKey('name')) {
          displayName = metadata['name'];
        } else if (metadata.containsKey('full_name')) {
          displayName = metadata['full_name'];
        } else if (user.email != null) {
          displayName = user.email!.split('@')[0];
        }

        if (metadata.containsKey('avatar_url')) {
          avatarUrl = metadata['avatar_url'];
        }
      }
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            width: double.infinity,
            color: Colors.blue[900],
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, size: 35, color: Colors.blue[900])
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                if (user != null) ...[
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email ?? "Sin email",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                    ),
                    child: const Text("Mi Perfil"),
                  ),
                ] else ...[
                  const Text(
                    "Bienvenido",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[900],
                    ),
                    child: const Text("Iniciar Sesión"),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    "INFORMACIÓN",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const _MenuLink(
                  icon: FontAwesomeIcons.globe,
                  label: "Web Oficial ACET",
                  url: "https://www.torredelmar.org/",
                ),
                const _MenuLink(
                  icon: FontAwesomeIcons.calendarDay,
                  label: "Agenda de Eventos",
                  url: "https://www.torredelmar.org/eventos",
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(
                    "SÍGUENOS",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons.facebook,
                        color: Color(0xFF1877F2),
                        url:
                            "https://www.facebook.com/acetempresariostorredelmar",
                      ),
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons.instagram,
                        color: Color(0xFFE4405F),
                        url:
                            "https://www.instagram.com/acet_empresarios_torre_del_mar/?hl=es-la",
                      ),
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons.xTwitter,
                        color: Colors.black,
                        url: "http://www.twitter.com/acettorredelmar/",
                      ),
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons.google,
                        color: Color(0xFFDB4437),
                        url:
                            "https://plus.google.com/114450006770310707428/posts",
                      ),
                    ],
                  ),
                ),

                const Divider(),

                const _MenuLink(
                  icon: Icons.privacy_tip_outlined,
                  label: "Contacto",
                  url: "https://www.torredelmar.org/contact/",
                ),

                if (user != null)
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      "Cerrar Sesión",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      final repo = ref.read(passportRepositoryProvider);
                      final syncService = ref.read(syncServiceProvider);
                      final authRepo = ref.read(authRepositoryProvider);

                      if (repo.hasPendingData) {
                        final bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("⚠️ Datos sin guardar"),
                            content: const Text(
                              "Tienes visados/votos que aún no se han subido a la nube.\n\n"
                              "Si cierras sesión ahora, PERDERÁS esos datos para siempre.\n\n"
                              "Te recomendamos cancelar, entrar en el evento y pulsar 'Sincronizar'.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("CANCELAR (RECOMENDADO)"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text("PERDER DATOS Y SALIR"),
                              ),
                            ],
                          ),
                        );
                        if (confirmDelete != true) return;
                      }

                      await repo.clearLocalData();
                      await authRepo.signOut();
                      if (context.mounted) {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      }
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Vive Torre del Mar - v1.0.4",
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. BOTONES SOCIALES DRAWER (RESTAURADO)
class _DrawerSocialBtn extends StatelessWidget {
  final IconData icon;
  final String url;
  final Color color;

  const _DrawerSocialBtn({
    required this.icon,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: FaIcon(icon, size: 24, color: color),
      ),
    );
  }
}

// 3. CARRUSEL DE NOTICIAS (CORREGIDO CON ERRORVIEW)
class _NewsCarouselSection extends ConsumerWidget {
  const _NewsCarouselSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return SizedBox(
      height: 180,
      child: newsAsync.when(
        // LOADING
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        
        // 🛡️ ERROR (CORREGIDO PARA QUE SE VEA SIEMPRE)
        error: (err, stack) => Center( // Center asegura que no se expanda raro
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
               color: Colors.grey[50],
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.grey.shade300)
            ),
            child: ErrorView(
              error: err, 
              isCompact: true, 
              onRetry: () => ref.refresh(newsProvider),
            ),
          ),
        ),
        
        // DATA
        data: (newsList) {
          if (newsList.isEmpty) {
             return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                   color: Colors.grey[100],
                   borderRadius: BorderRadius.circular(12)
                ),
                child: const Center(child: Text("No hay noticias destacadas")),
             );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(item.link)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SmartImageContainer(
                          imageUrl: item.imageUrl,
                          borderRadius: 0,
                        ),
                      ),
                      // ... (El resto del diseño de la tarjeta de noticias se mantiene igual)
                      // Si lo necesitas completo dímelo, pero solo cambia el 'error' de arriba.
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(4)),
                              child: Text(item.date, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 4. TARJETA DE EVENTO
class _HubEventCard extends StatelessWidget {
  final EventModel event;
  const _HubEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final appearance = EventTypeHelper.getAppearance(event.type);

    return GestureDetector(
      onTap: () => context.go('/event/${event.id}/dashboard'),

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SmartImageContainer(imageUrl: event.bgImageUrl, borderRadius: 0),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: appearance.color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(appearance.icon, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            appearance.label.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. CHIP DE FILTRO
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// 6. ESTADO VACÍO
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              "No hay eventos aquí",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// 7. MENU LINK (RESTAURADO TAMBIÉN)
class _MenuLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  const _MenuLink({required this.icon, required this.label, required this.url});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FaIcon(icon, size: 20, color: Colors.grey[700]),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/core/utils/event_type_helper.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// TUS IMPORTS
import 'package:torre_del_mar_app/core/constants/app_data.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/event_repository.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/features/hub/data/news_service.dart';

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Función para recargar datos al deslizar
  Future<void> _refreshData() async {
    ref.invalidate(adminEventsListProvider);
    ref.invalidate(newsProvider);
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    // 1. LEER ESTADOS
    final selectedFilter = ref.watch(hubFilterProvider);
    final eventsAsync = ref.watch(adminEventsListProvider);
    // authState ya no se usa aquí en el build principal, solo en el Drawer

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],

      // --- A. MENÚ LATERAL ---
      endDrawer: const _HubSideMenu(),

      // --- PULL TO REFRESH ---
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.blue[900],
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- B. CABECERA (LIMPIA) ---
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
                // HEMOS ELIMINADO EL CIRCLE AVATAR DE AQUÍ

                // Botón Menú Hamburguesa
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
                const SizedBox(width: 12), // Un poco de margen a la derecha
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

            // --- E. LISTA DE EVENTOS ---
            eventsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) =>
                  SliverToBoxAdapter(child: Center(child: Text("Error: $err"))),
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

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisExtent: 80,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (AppData.sponsors.isEmpty) return const SizedBox();
                  final s = AppData.sponsors[index % AppData.sponsors.length];
                  final String? url = s['url'];
                  final String imageUrl = s['logo']!;

                  return Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: url != null && url.isNotEmpty
                          ? () async {
                              final uri = Uri.parse(url);
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
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: AppData.sponsors.length),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

// 1. MENÚ LATERAL CON AVATAR
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
        // 1. Nombre
        if (metadata.containsKey('name')) {
          displayName = metadata['name'];
        } else if (metadata.containsKey('full_name'))
          displayName = metadata['full_name'];
        else if (user.email != null)
          displayName = user.email!.split('@')[0];

        // 2. Avatar (CORRECCIÓN IMPORTANTE)
        if (metadata.containsKey('avatar_url')) {
          avatarUrl = metadata['avatar_url'];
        }
      }
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          // CABECERA USUARIO
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
                    // LÓGICA CORREGIDA: Usamos la URL de Supabase si existe
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
                ], // if-else
              ],
            ),
          ),

          // LISTA DE ENLACES
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
                _MenuLink(
                  icon: FontAwesomeIcons.globe,
                  label: "Web Oficial ACET",
                  url: "https://www.torredelmar.org/",
                ),
                _MenuLink(
                  icon: FontAwesomeIcons.calendarDay,
                  label: "Agenda de Eventos",
                  url: "https://www.torredelmar.org/eventos",
                ),

                const Divider(),

                // --- NUEVA SECCIÓN DE REDES SOCIALES EN FILA ---
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
                    mainAxisAlignment: MainAxisAlignment
                        .spaceAround, // Distribuye el espacio uniformemente
                    children: [
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons.facebook,
                        color: const Color(0xFF1877F2), // Azul Facebook
                        url:
                            "https://www.facebook.com/acetempresariostorredelmar",
                      ),
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons.instagram,
                        color: const Color(0xFFE4405F),
                        url:
                            "https://www.instagram.com/acet_empresarios_torre_del_mar/?hl=es-la",
                      ),
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons.xTwitter,
                        color: Colors.black, // Negro X
                        url: "http://www.twitter.com/acettorredelmar/",
                      ),
                      // Nota: Google+ cerró en 2019, pero si el enlace sigue activo para empresas o es Google My Business, lo dejamos.
                      _DrawerSocialBtn(
                        icon: FontAwesomeIcons
                            .google, // Cambiado a Google genérico o MyBusiness
                        color: const Color(0xFFDB4437), // Rojo Google
                        url:
                            "https://plus.google.com/114450006770310707428/posts",
                      ),
                    ],
                  ),
                ),

                // -----------------------------------------------
                const Divider(),

                _MenuLink(
                  icon: Icons.privacy_tip_outlined,
                  label: "Contacto", // Corregido typo 'Conctacto'
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

                      // 1. ¿HAY DATOS PENDIENTES?
                      if (repo.hasPendingData) {
                        // A. Intentamos sincronizar automáticamente primero (INTENTO SILENCIOSO)
                        // Nota: Como syncPendingVotes pide un eventId, y aquí quizás no lo tenemos a mano si estamos en el Hub,
                        // o hay múltiples eventos, lo más seguro es preguntar al usuario.

                        // Mostramos Diálogo de Advertencia
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
                                onPressed: () =>
                                    Navigator.pop(context, false), // Cancelar
                                child: const Text("CANCELAR (RECOMENDADO)"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(
                                  context,
                                  true,
                                ), // Borrar y Salir
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text("PERDER DATOS Y SALIR"),
                              ),
                            ],
                          ),
                        );

                        // Si el usuario dice que NO (o toca fuera), cancelamos el logout
                        if (confirmDelete != true) return;
                      }

                      // 2. PROCEDEMOS AL CIERRE (Si no había pendientes o el usuario aceptó borrarlos)

                      // A. Borrado local
                      await repo.clearLocalData();

                      // B. Logout en Supabase
                      await authRepo.signOut();

                      // C. Cerrar pantalla/menú
                      if (context.mounted) {
                        // Si estamos en un Drawer (Hub)
                        if (Navigator.canPop(context)) Navigator.pop(context);
                        // Si estamos en ProfileScreen (que es una pantalla pusheada)
                        // context.pop() o similar dependiendo de donde estés
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

// --- AÑADIR ESTE PEQUEÑO WIDGET AL FINAL DE TU ARCHIVO ---
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
          color: color.withOpacity(0.1), // Fondo suave del color de la marca
        ),
        child: FaIcon(icon, size: 24, color: color),
      ),
    );
  }
}

// 2. CARRUSEL DE NOTICIAS
class _NewsCarouselSection extends ConsumerWidget {
  const _NewsCarouselSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return SizedBox(
      height: 180,
      child: newsAsync.when(
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
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (err, stack) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.grey),
              const SizedBox(height: 5),
              Text(
                "No se pudieron cargar noticias",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        data: (newsList) {
          if (newsList.isEmpty) return const SizedBox();

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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[900],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.date,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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

// 3. TARJETA DE EVENTO
class _HubEventCard extends StatelessWidget {
  final EventModel event;
  const _HubEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    // 1. RECUPERAMOS LA APARIENCIA (Color, Texto, Icono)
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
              // IMAGEN DE FONDO
              SmartImageContainer(imageUrl: event.bgImageUrl, borderRadius: 0),
              
              // DEGRADADO (Para que se lea el texto)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),
              
              // TEXTOS Y ETIQUETA
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO DEL EVENTO
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

                    // --- AQUÍ ESTABA LA FECHA, AHORA PONEMOS LA ETIQUETA ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: appearance.color, // Color dinámico (Naranja, Morado...)
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Ocupa solo lo necesario
                        children: [
                          Icon(appearance.icon, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            appearance.label.toUpperCase(), // "RUTA DE LA TAPA", etc.
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
                    // -------------------------------------------------------
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

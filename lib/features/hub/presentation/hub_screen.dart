import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:torre_del_mar_app/core/utils/event_type_helper.dart';
import 'package:torre_del_mar_app/core/widgets/version_tag.dart';
import 'package:torre_del_mar_app/core/widgets/web_container.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// IMPORTS DEL PROYECTO
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/scan/data/repositories/passport_repository.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart'
    hide passportRepositoryProvider;
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/features/hub/data/news_service.dart';
import 'package:torre_del_mar_app/core/widgets/error_view.dart';

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _refreshData() async {
    ref.refresh(adminEventsListProvider);
    ref.refresh(newsProvider);
    ref.refresh(sponsorsListProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(hubFilterProvider);
    final eventsAsync = ref.watch(adminEventsListProvider);
    final sponsorsAsync = ref.watch(sponsorsListProvider);

    // Detectamos si es PC
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return WebContainer(
      backgroundColor: Colors.grey[100],
      child: Column(
        children: [
          // AVISO SOLO PARA PC
          /*
          if (isDesktop)
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.phone_android, size: 16, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text(
                    "Para escanear QRs y usar GPS preciso, usa tu móvil.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          */
          // RESTO DE LA APP (EXPANDED PARA OCUPAR TODO EL HUECO)
          Expanded(
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.grey[50],
              endDrawer: const _HubSideMenu(),
              body: RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.blue[900],
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // --- B. CABECERA ---
                    SliverAppBar(
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "VIVE ",
                              style: GoogleFonts.ubuntu(
                                // O usa .montserrat() si te gusta más
                                color: const Color(0xFFEE1935), // ROJO OFICIAL
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: "TORRE DEL MAR",
                              style: GoogleFonts.ubuntu(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.white,
                      floating: true,
                      pinned: true,
                      elevation: 0,
                      centerTitle: false,
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.black,
                            size: 28,
                          ),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openEndDrawer(),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),

                    // --- C. CARRUSEL NOTICIAS ---
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
                                    Uri.parse(
                                      "https://www.torredelmar.org/eventos/",
                                    ),
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
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          color: Colors.transparent,
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            //child: ConstrainedBox(
                            //  constraints: BoxConstraints(
                            //    minWidth: MediaQuery.of(context).size.width - 32,
                            //  ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _FilterChip(
                                  label: "🔥 Activos",
                                  isSelected: selectedFilter == 'active',
                                  onTap: () =>
                                      ref
                                              .read(hubFilterProvider.notifier)
                                              .state =
                                          'active',
                                ),
                                const SizedBox(width: 10),
                                _FilterChip(
                                  label: "🔜 Próximos",
                                  isSelected: selectedFilter == 'upcoming',
                                  onTap: () =>
                                      ref
                                              .read(hubFilterProvider.notifier)
                                              .state =
                                          'upcoming',
                                ),
                                const SizedBox(width: 10),
                                _FilterChip(
                                  label: "📜 Historial",
                                  isSelected: selectedFilter == 'archived',
                                  onTap: () =>
                                      ref
                                              .read(hubFilterProvider.notifier)
                                              .state =
                                          'archived',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- E. LISTA EVENTOS ---
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
                          if (selectedFilter == 'active') {
                            return status == 'active';
                          }
                          if (selectedFilter == 'upcoming') {
                            return status == 'upcoming';
                          }
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

                        // CAMBIO CLAVE: SliverGrid para que en PC se vean varios eventos
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      500, // Ancho máximo tarjeta
                                  mainAxisExtent: 220, // Altura fija tarjeta
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final event = filteredEvents[index];
                              return Center(
                                child: SizedBox(
                                  width: 500,
                                  child: _HubEventCard(event: event),
                                ),
                              );
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
                        child: ErrorView(
                          error: err,
                          isCompact: true,
                          onRetry: _refreshData,
                        ),
                      ),
                      data: (sponsors) {
                        if (sponsors.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  mainAxisExtent: 100,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final sponsor = sponsors[index];
                              return InkWell(
                                onTap: (sponsor.websiteUrl?.isNotEmpty ?? false)
                                    ? () => launchUrl(
                                        Uri.parse(sponsor.websiteUrl!),
                                      )
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Image.network(
                                    sponsor.logoUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
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
            ),
          ),
        ],
      ),
    );
  }
}

// 1. MENÚ LATERAL CON AVATAR (CORREGIDO Y SIN ERRORES DE OVERFLOW)
class _HubSideMenu extends ConsumerWidget {
  const _HubSideMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lógica de Rol y Usuario (Tu código original)
    final roleAsync = ref.watch(userRoleProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final profileAsync = ref.watch(userProfileProvider);
    String displayName = "Usuario";
    String? avatarUrl;

    // A) Primero intentamos sacar datos de la sesión (Auth)
    if (user != null) {
      displayName = user.email?.split('@')[0] ?? "Usuario";
    }

    // B) 🔥 SI TENEMOS PERFIL EN BD, SOBREESCRIBIMOS (Esto arregla tu problema)
    if (profileAsync.value != null) {
      final profile = profileAsync.value!;
      if (profile['full_name'] != null &&
          profile['full_name'].toString().isNotEmpty) {
        displayName = profile['full_name'];
      }
      if (profile['avatar_url'] != null &&
          profile['avatar_url'].toString().isNotEmpty) {
        // Truco: Añadimos timestamp para evitar caché si cambias la foto
        avatarUrl =
            "${profile['avatar_url']}?t=${DateTime.now().millisecondsSinceEpoch}";
      }
    }

    // Cálculo del ancho
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.85).clamp(0.0, 350.0);

    return Drawer(
      width: drawerWidth,
      // 🔥 CAMBIO CLAVE: Usamos un único ListView para TODO.
      // Esto evita el error de "Unbounded height" y permite scroll en horizontal.
      child: ListView(
        padding: EdgeInsets
            .zero, // Para que la cabecera azul toque el borde superior
        children: [
          // 1. CABECERA AZUL (Ahora es el primer elemento de la lista)
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
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius:
                          60, // Ajustado ligeramente para que quepa mejor en apaisado
                      backgroundColor: Colors.grey[200],
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.blue[900],
                            )
                          : null,
                    ),
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
                    textAlign: TextAlign.center,
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

          // 2. ZONA ADMIN (Tu lógica original)
          roleAsync.when(
            data: (role) {
              if (role == 'admin') {
                return Column(
                  children: [
                    Container(
                      color: Colors.orange.shade50,
                      child: ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.deepOrange,
                        ),
                        title: const Text(
                          "PANEL DE CONTROL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward,
                          color: Colors.deepOrange,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin');
                        },
                      ),
                    ),
                    const Divider(),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 3. INFORMACIÓN
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

          // 4. REDES SOCIALES
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _DrawerSocialBtn(
                  icon: FontAwesomeIcons.facebook,
                  color: Color(0xFF1877F2),
                  url: "https://www.facebook.com/acetempresariostorredelmar",
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
                  url: "https://plus.google.com/114450006770310707428/posts",
                ),
              ],
            ),
          ),

          const Divider(),

          // 5. CONTACTO Y LOGOUT
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
                          child: const Text("CANCELAR"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text("SALIR"),
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

          // 6. PIE DE PÁGINA (VERSIÓN)
          Padding(
            /*
            padding: const EdgeInsets.all(20),
            child: Text(
              "Vive Torre del Mar - v1.1.5",
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
              textAlign: TextAlign.center,
            ),
            */
            padding: EdgeInsets.only(bottom: 20),
            child: Center(child: VersionTag()),
          ),

          // Espacio extra al final para asegurar que se pueda hacer scroll hasta el fondo
          const SizedBox(height: 20),
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

// 3. CARRUSEL DE NOTICIAS
// Transforma el widget a Stateful para controlar la página actual (puntitos)
// 3. CARRUSEL DE NOTICIAS (CON AUTO-PLAY) 🎡
class _NewsCarouselSection extends ConsumerStatefulWidget {
  const _NewsCarouselSection();

  @override
  ConsumerState<_NewsCarouselSection> createState() =>
      _NewsCarouselSectionState();
}

class _NewsCarouselSectionState extends ConsumerState<_NewsCarouselSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer; // Variable para el temporizador

  @override
  void initState() {
    super.initState();
    // Iniciamos el movimiento automático al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ¡Importante! Matar el timer al salir para evitar fugas de memoria
    _pageController.dispose();
    super.dispose();
  }

  // --- MOTOR DE MOVIMIENTO ---
  void _startAutoScroll() {
    _timer?.cancel(); // Aseguramos que no haya dos timers a la vez
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // 1. Verificamos si el controlador está listo
      if (!_pageController.hasClients) return;

      // 2. Leemos la lista actual de noticias (sin redibujar)
      final newsList = ref.read(newsProvider).valueOrNull;
      if (newsList == null || newsList.isEmpty) return;

      // 3. Calculamos la siguiente página
      int nextPage = _currentPage + 1;
      if (nextPage >= newsList.length) {
        nextPage = 0; // Si llegamos al final, volvemos al principio
      }

      // 4. Animamos
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800), // Movimiento suave
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return newsAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ErrorView(
          error: err,
          isCompact: true,
          onRetry: () => ref.refresh(newsProvider),
        ),
      ),
      data: (newsList) {
        if (newsList.isEmpty) return const SizedBox.shrink();

        final double height = isDesktop ? 280 : 200;

        return Column(
          children: [
            SizedBox(
              height: height,
              // 🔥 LISTENER: Detecta si el usuario toca para pausar el auto-scroll
              child: Listener(
                onPointerDown: (_) => _stopAutoScroll(), // Usuario toca -> Pausa
                onPointerUp: (_) => _startAutoScroll(),  // Usuario suelta -> Reanuda
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: newsList.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return _buildNewsBanner(context, newsList[index], isDesktop);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            // INDICADORES (Puntitos)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(newsList.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.blue[900]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  // (El método _buildNewsBanner se mantiene igual que lo tenías)
  Widget _buildNewsBanner(BuildContext context, dynamic item, bool isDesktop) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(item.link)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SmartImageContainer(imageUrl: item.imageUrl, borderRadius: 0),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: isDesktop ? 22 : 16,
                        height: 1.2,
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

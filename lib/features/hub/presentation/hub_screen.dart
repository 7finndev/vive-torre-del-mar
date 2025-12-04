import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';

// --- WIDGET TARJETA DE EVENTO (ADAPTABLE) ---
class HubEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const HubEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = event['bg_image_url'] ?? 'https://images.pexels.com/photos/1267320/pexels-photo-1267320.jpeg?auto=compress&cs=tinysrgb&w=600';
    final String name = event['name'] ?? 'Evento';
    final String type = (event['type'] ?? '').toString().toUpperCase();
    final String status = event['status'] ?? 'unknown';
    final String colorHex = event['theme_color_hex'] ?? '#FF9800';

    Color themeColor;
    try {
      themeColor = Color(int.parse(colorHex.replaceAll('#', '0xff')));
    } catch (_) {
      themeColor = Colors.orange;
    }

    String statusText;
    IconData statusIcon;
    Color badgeColor;
    Color itemsColor;

    switch (status) {
      case 'active':
        statusText = "EN CURSO";
        statusIcon = Icons.fiber_manual_record;
        badgeColor = Colors.white;
        itemsColor = Colors.green[700]!;
        break;
      case 'upcoming':
        statusText = "PRÓXIMAMENTE";
        statusIcon = Icons.calendar_today;
        badgeColor = Colors.white;
        itemsColor = Colors.blue[700]!;
        break;
      case 'archived':
      default:
        statusText = "FINALIZADO";
        statusIcon = Icons.flag;
        badgeColor = Colors.black54;
        itemsColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: () => context.go('/event/${event['id']}'),
      child: Container(
        // NOTA: Quitamos el margen inferior y la altura fija.
        // Dejamos que el Grid controle el tamaño.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black, 
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), 
              blurRadius: 15, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.9), 
                Colors.black.withOpacity(0.5),
                Colors.transparent             
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.center, 
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor, 
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type, 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 24, // Un poco más pequeño para que quepa mejor en grid
                  fontWeight: FontWeight.bold, 
                  height: 1.1,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: itemsColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(color: itemsColor, fontSize: 11, fontWeight: FontWeight.bold),
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

// --- PANTALLA PRINCIPAL (HUB) ---
class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  DateTime? _lastPressedAt;
  List<dynamic> _events = [];
  bool _loading = true;
  String _loadingImage = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600';
  String _loadingMessage = 'Cargando...';

  // Datos de Patrocinadores (Fijos por ahora)
  final List<Map<String, String>> _sponsors = [
    {
      "name": "ACET",
      "logo":
          "https://www.torredelmar.org/wp-content/uploads/2024/03/Logo-ACET-Torre-del-Mar--e1711372971163.png",
      "url": "https://www.torredelmar.org/",
    },
    {
      "name": "Torre del Mar",
      "logo":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRp0ljDLY-gdLu9_6WU1DMblFD8frhjonWcGQ&s",
      "url": "https://velezmalaga.es/",
    },
    {
      "name": "Cervezas Victoria",
      "logo":
          "https://www.cervezavictoria.es/sites/default/files/2018-11/posavasos.jpg",
      "url": "https://www.cervezavictoria.es/",
    },
    {
      "name": "APTA Axarquia Costa del Sol",
      "logo":
          "https://www.axarquiacostadelsol.es/wp-content/uploads/2022/06/LogoLineaNegra.png",
      "url": "https://axarquiacostadelsol.es/",
    },
  ];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final supabase = Supabase.instance.client;
    final localDb = LocalDbService(); // Instancia para acceder a las cajas
    // Hay que asegurarse de que Hive ya está init en main.dart, aqui solo
    //  accedemos a la caja abierta.
    final eventsBox = Hive.box(LocalDbService.eventsBoxName);
    
    if(eventsBox.isNotEmpty){
      print("💾 Hub: Cargando eventos desde caché...");
      final cachedEvents = eventsBox.values.map((e) => (e as EventModel).toJson()).toList();
      // Ordenamos localmente también:
      cachedEvents.sort((a, b) => (b['start_date'] ?? '').compareTo(a['start_date'] ?? ''));

      if(mounted){
        setState(() {
          _events = cachedEvents;
          _loading = false; // Ya mostramos algo, quitamos el spinner
        });
      }
    }

    // Intento de actualización online
    try {
      final results = await Future.wait([
        supabase.from('events').select().order('start_date', ascending: false),
        supabase.from('app_config').select(),
      ]);
      final eventsData = results[0] as List<dynamic>;
      final configData = results[1] as List<dynamic>;

      // Guardar configuración:
      String? bgImage;
      String? msg;
      for (var row in configData) {
        if (row['key'] == 'loading_bg_image') bgImage = row['value'];
        if (row['key'] == 'loading_message') msg = row['value'];
      }

      // Guardar Eventos en Hive (para la proxima vez):
      await eventsBox.clear();
      for (var eventMap in eventsData) {
        // Convertimos de Json a Modelo para guardar en Hive
        final eventModel = EventModel.fromJson(eventMap);
        await eventsBox.add(eventModel);
      }

      // Actualiza la UI con datos frescos:      
      if (mounted) {
        setState(() {
          _events = eventsData;
          if (bgImage != null) _loadingImage = bgImage;
          if (msg != null) _loadingMessage = msg;
          _loading = false; 
        });
      }
    } catch (e) {
      print("⚠️ Error de red en Hub (Modo Offline activo): $e");
      // Si falló la red y no teníamos caché, quitamos el loading para mostrar "vacio" o error
      //if (mounted) setState(() => _loading = false);
      if(_events.isEmpty && mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _loadingImage,
              fit: BoxFit.cover,
              placeholder: (_,__) => Container(color: Colors.white),
            ),
            Container(color: Colors.black.withOpacity(0.6)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.orange),
                  const SizedBox(height: 20),
                  Text(_loadingMessage, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pulsa otra vez para salir"), duration: Duration(seconds: 2)));
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            // HEADER
            SliverAppBar(
                pinned: true, expandedHeight: 100.0, backgroundColor: Colors.white, surfaceTintColor: Colors.white, centerTitle: false,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: RichText(text: const TextSpan(children: [TextSpan(text: "VIVE\n", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 24, height: 1.0, fontFamily: 'Roboto')), TextSpan(text: "TORRE DEL MAR", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0))])),
                ),
                actions: [
                  Consumer(builder: (context, ref, _) {
                      final user = ref.watch(authStateProvider).value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                        child: GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: user != null ? Colors.blue[50] : Colors.grey[200],
                            backgroundImage: user != null ? const NetworkImage('https://i.pravatar.cc/150?img=68') : null,
                            child: user == null ? const Icon(Icons.person_outline, color: Colors.black54) : null,
                          ),
                        ),
                      );
                  }),
                ],
            ),

            // 1. TÍTULO AGENDA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: const Text("AGENDA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: Colors.grey)),
              ),
            ),

            // 2. GRID DE EVENTOS (RESPONSIVE)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500, // En móvil (360px) es 1 columna. En PC (>500) son 2+.
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.6, // Relación de aspecto de la tarjeta (Ancho/Alto)
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return HubEventCard(event: _events[index]);
                  },
                  childCount: _events.length,
                ),
              ),
            ),

            // 3. PATROCINADORES
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text("ORGANIZA Y COLABORA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    SizedBox(
                       height: 80,
                       child: ListView.separated(
                         scrollDirection: Axis.horizontal,
                         itemCount: _sponsors.length,
                         separatorBuilder: (_,__) => const SizedBox(width: 16),
                         itemBuilder: (context, index) {
                           final sponsor = _sponsors[index];
                           return GestureDetector(
                             onTap: () async {
                               final Uri url = Uri.parse(sponsor["url"]!);
                               try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (_) {}
                             },
                             child: Container(
                               width: 80, padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))]),
                               child: CachedNetworkImage(imageUrl: sponsor["logo"]!, fit: BoxFit.contain, placeholder: (_,__) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey)),
                             ),
                           );
                         },
                       ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
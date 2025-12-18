import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:torre_del_mar_app/core/constants/app_data.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/ranking_provider.dart';
import 'package:torre_del_mar_app/features/home/presentation/widgets/home_ranking_carousel.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
// IMPORTANTE: Necesitamos el auth provider
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(currentEventProvider);
    final rankingAsync = ref.watch(rankingListProvider);
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    
    // 1. ESCUCHAMOS AL USUARIO PARA EL AVATAR
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    String? avatarUrl;
    if (user != null && user.userMetadata != null && user.userMetadata!.containsKey('avatar_url')) {
      avatarUrl = user.userMetadata!['avatar_url'];
    }

    // Valores por defecto
    String bgImage = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg';
    String eventName = "CARGANDO...";
    int eventId = 1;
    Color themeColor = Colors.orange;

    if (eventAsync.hasValue && eventAsync.value != null) {
      final event = eventAsync.value!;
      eventId = event.id;
      eventName = event.name.toUpperCase();
      if (event.bgImageUrl != null && event.bgImageUrl!.isNotEmpty) {
        bgImage = event.bgImageUrl!;
      }
      try {
        themeColor = Color(int.parse(event.themeColorHex.replaceAll('#', '0xff')));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 1. CABECERA LIMPIA
          SliverAppBar(
            pinned: true,
            expandedHeight: 280.0,
            backgroundColor: themeColor,
            leading: IconButton(
               icon: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                 child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
               ),
               onPressed: () => context.go('/'),
            ),
            actions: [
               // --- AVATAR DINÁMICO ---
               GestureDetector(
                 onTap: () => context.push('/profile', extra: eventId), // Pasamos el ID del evento
                 child: Container(
                   margin: const EdgeInsets.only(right: 16),
                   padding: const EdgeInsets.all(2), // Borde blanco fino
                   decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                   child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      // Si hay URL, la mostramos. Si no, icono por defecto.
                      backgroundImage: avatarUrl != null 
                          ? NetworkImage(avatarUrl) 
                          : null,
                      child: avatarUrl == null
                          ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                          : null,
                   ),
                 ),
               ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                eventName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SmartImageContainer(
                    imageUrl: bgImage,
                    borderRadius: 0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // BOTÓN EXPLORAR RUTA
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go('/event/$eventId/map'),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.map_outlined, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              "EXPLORAR RUTA",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // RANKING (Favoritos)
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        "FAVORITOS DEL PÚBLICO",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HomeRankingCarousel(
                    rankingAsync: rankingAsync,
                    establishmentsAsync: establishmentsAsync,
                  ),

                  const SizedBox(height: 40),

                  // PATROCINADORES DEL EVENTO
                  const Center(
                    child: Text(
                      "PATROCINADORES OFICIALES",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.8, 
                    ),
                    itemCount: AppData.sponsors.length,
                    itemBuilder: (context, index) {
                      final s = AppData.sponsors[index];
                      final String? url = s['url'];
                      final String imageUrl = s['logo']!;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: url != null && url.isNotEmpty
                                  ? () async {
                                      final uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Center(
                                  // Corrección también aquí para evitar bordes dobles
                                  child: Image.network(imageUrl, fit: BoxFit.contain), 
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
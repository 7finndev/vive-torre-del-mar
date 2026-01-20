// Para el shuffle (aleatorio)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:torre_del_mar_app/core/constants/app_data.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/core/utils/event_type_helper.dart';

// IMPORTAMOS LOS WIDGETS NUEVOS
import 'package:torre_del_mar_app/features/home/presentation/widgets/smart_recommendation_card.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CARGA DE DATOS
    final eventAsync = ref.watch(currentEventProvider);
    // Ya no usamos el rankingListProvider aquí
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    // Cargamos los productos para el carrusel aleatorio
    final productsAsync = ref.watch(productsListProvider);
    
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    String? avatarUrl;
    if (user != null && user.userMetadata != null && user.userMetadata!.containsKey('avatar_url')) {
      avatarUrl = user.userMetadata!['avatar_url'];
    }

    // VARIABLES POR DEFECTO
    String bgImage = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg';
    String eventName = "CARGANDO...";
    String fontFamily = 'Roboto'; 
    int eventId = 1;
    Color themeColor = Colors.orange;
    String eventType = 'gastronomic'; 

    if (eventAsync.hasValue && eventAsync.value != null) {
      final event = eventAsync.value!;
      eventId = event.id;
      eventName = event.name.toUpperCase();
      eventType = event.type; 
      
      if (event.bgImageUrl != null && event.bgImageUrl!.isNotEmpty) {
        bgImage = "${event.bgImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}"; 
      }
      
      if (event.fontFamily != null && event.fontFamily!.isNotEmpty) {
        fontFamily = event.fontFamily!;
      }

      try {
        if (event.themeColorHex.isNotEmpty) {
           String cleanHex = event.themeColorHex.replaceAll('#', '');
           if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
           themeColor = Color(int.parse(cleanHex, radix: 16));
        }
      } catch (_) {}
    }

    final appearance = EventTypeHelper.getAppearance(eventType);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        color: themeColor,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(currentEventProvider);
          ref.invalidate(productsListProvider); // Recargamos productos
          ref.invalidate(establishmentsListProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
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
                 GestureDetector(
                   onTap: () => context.push('/profile', extra: eventId),
                   child: Container(
                     margin: const EdgeInsets.only(right: 16),
                     padding: const EdgeInsets.all(2),
                     decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                     child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                            : null,
                     ),
                   ),
                 ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    eventName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.getFont(
                      fontFamily,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18, 
                        shadows: [Shadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, 2))],
                      ),
                    ),
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
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.4, 1.0],
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
                    
                    // BOTÓN EXPLORAR
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
                            children: [
                              Icon(appearance.icon, color: Colors.white, size: 28), 
                              const SizedBox(width: 12),
                              Text(
                                eventType == 'elfos' || eventType == 'adventure' 
                                    ? "EMPEZAR AVENTURA" 
                                    : "EXPLORAR RUTA",
                                style: GoogleFonts.getFont(
                                  fontFamily,
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- 1. RECOMENDADOR INTELIGENTE (NUEVO) ---
                    SmartRecommendationCard(eventId: eventId),

                    const SizedBox(height: 30),

                    // --- 2. CARRUSEL "DESCUBRE" (ALEATORIO) ---
                    const Row(
                      children: [
                        Icon(Icons.explore, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "DESCUBRE NUEVAS PROPUESTAS",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // LÓGICA DEL CARRUSEL ALEATORIO
                    productsAsync.when(
                      loading: () => const SizedBox(
                        height: 200, 
                        child: Center(child: CircularProgressIndicator())
                      ),
                      error: (e,s) => const SizedBox(),
                      data: (products) {
                        if (products.isEmpty) return const Text("No hay datos disponibles");
                        
                        // MEZCLA ALEATORIA (Shuffle)
                        // Creamos una copia para no alterar el orden original
                        final randomProducts = List<ProductModel>.from(products)..shuffle();
                        // Cogemos solo 10 para no saturar
                        final displayProducts = randomProducts.take(10).toList();

                        return SizedBox(
                          height: 230,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: displayProducts.length,
                            itemBuilder: (context, index) {
                              final product = displayProducts[index];
                              
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () async {
                                     // Buscamos el establecimiento para navegar
                                     final establishments = establishmentsAsync.valueOrNull ?? [];
                                     try {
                                       final est = establishments.firstWhere((e) => e.id == product.establishmentId);
                                       context.push('/detail', extra: est);
                                     } catch (_) {}
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              SmartImageContainer(imageUrl: product.imageUrl, borderRadius: 0),
                                              // Precio
                                              Positioned(
                                                bottom: 0, right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.7),
                                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(10)),
                                                  ),
                                                  child: Text(
                                                    "${product.price}€",
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      // Intentamos buscar el nombre del bar si está cargado
                                      Builder(builder: (context) {
                                        final establishments = establishmentsAsync.valueOrNull ?? [];
                                        try {
                                          final barName = establishments.firstWhere((e) => e.id == product.establishmentId).name;
                                          return Text(barName, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis);
                                        } catch (_) { return const SizedBox(); }
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // PATROCINADORES
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
      ),
    );
  }
}
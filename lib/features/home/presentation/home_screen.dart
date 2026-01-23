import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 

import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/core/utils/event_type_helper.dart';

// WIDGETS
import 'package:torre_del_mar_app/features/home/presentation/widgets/smart_recommendation_card.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
import 'package:torre_del_mar_app/features/home/presentation/widgets/next_stop_card.dart';

// 🆕 IMPORTANTE: Importar el ErrorView
import 'package:torre_del_mar_app/core/widgets/error_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. CARGA DE DATOS
    final eventAsync = ref.watch(currentEventProvider);
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    final productsAsync = ref.watch(productsListProvider);
    final sponsorsAsync = ref.watch(sponsorsListProvider);
    
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    // --- FUNCIÓN PARA RECARGAR TODO (Usada en Pull-to-Refresh y Botones Reintentar) ---
    void reloadAll() {
      ref.invalidate(currentEventProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(establishmentsListProvider);
      ref.invalidate(sponsorsListProvider);
    }
    // -----------------------------------------------------------------------------------

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
          reloadAll(); // Usamos la función centralizada
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

                    const SizedBox(height: 20),

                    // --- Tarjeta de Navegación Táctica ---
                    NextStopCard(eventId: eventId),

                    const SizedBox(height: 20),

                    // --- 1. RECOMENDADOR INTELIGENTE ---
                    SmartRecommendationCard(eventId: eventId),

                    const SizedBox(height: 30),

                    // --- 2. CARRUSEL "DESCUBRE" ---
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
                    
                    productsAsync.when(
                      loading: () => const SizedBox(
                        height: 200, 
                        child: Center(child: CircularProgressIndicator())
                      ),
                      
                      // 🛡️ AQUÍ ESTABA EL CAMBIO PRINCIPAL:
                      error: (err, stack) => Container(
                        height: 150,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ErrorView(
                          error: err, 
                          isCompact: true, 
                          onRetry: reloadAll, // Botón reactiva todo
                        ),
                      ),

                      data: (products) {
                        if (products.isEmpty) return const Text("No hay datos disponibles");
                        final randomProducts = List<ProductModel>.from(products)..shuffle();
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

                    // --- 3. PATROCINADORES DINÁMICOS ---
                    const Center(
                      child: Text(
                        "PATROCINADORES OFICIALES",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    sponsorsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      
                      // 🛡️ AQUÍ TAMBIÉN AÑADIMOS EL ERRORVIEW
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ErrorView(
                          error: err, 
                          isCompact: true, 
                          onRetry: reloadAll,
                        ),
                      ),

                      data: (sponsors) {
                        if (sponsors.isEmpty) return const SizedBox();

                        return GridView.builder(
                          shrinkWrap: true, 
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.8, 
                          ),
                          itemCount: sponsors.length,
                          itemBuilder: (context, index) {
                            final sponsor = sponsors[index];
                            
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
                                    onTap: (sponsor.websiteUrl != null && sponsor.websiteUrl!.isNotEmpty)
                                        ? () async {
                                            final uri = Uri.parse(sponsor.websiteUrl!);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            }
                                          }
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Center(
                                        child: Image.network(
                                          sponsor.logoUrl, 
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                                                const SizedBox(height: 4),
                                                Text(sponsor.name, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                                              ],
                                            );
                                          },
                                        ), 
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
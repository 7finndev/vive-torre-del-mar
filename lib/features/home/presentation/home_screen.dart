import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/ranking_provider.dart';
import 'package:torre_del_mar_app/features/home/presentation/widgets/home_event_card.dart';
import 'package:torre_del_mar_app/features/home/presentation/widgets/home_ranking_carousel.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // --- 1. LÓGICA DE SINCRONIZACIÓN Y RED ---
    // Monitor de conexión "inteligente":
    // A. Si vuelve internet, recargamos la lista de bares
    ref.listen(connectivityStreamProvider, (previous, next) {
      //Solo actuamos si hay un cambio real de estado:
      if(previous?.value == null) return; // Ignoramos la carga inicial de la app

      final wasOffline = previous!.value?.contains(ConnectivityResult.none);
      final isNowOnline = !next.value!.contains(ConnectivityResult.none);

      //Solo mosstramos mensaje si estábamos sin internet y ahora volvemos a tener
      if(wasOffline! && isNowOnline){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Conexión recuperada! ☁️ Actualizando datos...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        //Forzamos recarga
        ref.invalidate(establishmentsListProvider);
      }
      /*
      final isOnline = next.value != null && !next.value!.contains(ConnectivityResult.none);
      if (isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Conexión recuperada! ☁️'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        ref.invalidate(establishmentsListProvider);
      }
      */
    });

    // B. Si el usuario cambia (Login), sincronizamos sus votos
    ref.listen(authStateProvider, (previous, next) async {
      if (next.value != null) {
        await ref.read(syncServiceProvider).syncPendingVotes();
      }
    });
    
    // C. Al arrancar la pantalla, si ya hay usuario, sincronizamos silenciosamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Supabase.instance.client.auth.currentUser != null) {
         ref.read(syncServiceProvider).syncPendingVotes();
      }
    });

    // --- 2. DATOS DEL EVENTO ---
    //final establishmentsAsync = ref.watch(establishmentsListProvider);
    final establishmentsAsync = ref.watch(establishmentsListProvider); // <--- ESTA ES LA QUE TE FALTA
    final rankingAsync = ref.watch(rankingListProvider);
    final eventAsync = ref.watch(currentEventProvider);

    // Valores por defecto (mientras carga)
    String bgImage = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600';
    Color themeColor = Colors.orange;
    String titleLine1 = "CARGANDO...";
    String titleLine2 = "TORRE DEL MAR";
    String cardTitle = "Ver Mapa";
    int eventId = 1; // Fallback ID

    // Procesamos los datos del evento si ya llegaron
    if (eventAsync.hasValue && eventAsync.value != null) {
        final event = eventAsync.value!;
        eventId = event.id;
        
        // Imagen de fondo
        if (event.bgImageUrl != null && event.bgImageUrl!.isNotEmpty) {
          bgImage = event.bgImageUrl!;
        }
        
        // Color del tema
        try {
          themeColor = Color(int.parse(event.themeColorHex.replaceAll('#', '0xff')));
        } catch (_) {}
        
        // Título Dinámico (Separa "Ruta..." de "2026")
        final fullName = event.name.toUpperCase();
        final yearRegex = RegExp(r' \d{4}$');
        
        if (yearRegex.hasMatch(fullName)) {
           titleLine1 = fullName.replaceAll(yearRegex, ''); // Ej: RUTA DEL CÓCTEL
           final year = yearRegex.firstMatch(fullName)?.group(0)?.trim();
           titleLine2 = "TORRE DEL MAR $year";
        } else {
           titleLine1 = fullName;
           titleLine2 = "TORRE DEL MAR";
        }

        // Texto de la tarjeta según tipo
        if (event.type == 'drinks') {
          cardTitle = "Ruta de Cócteles";
        } else {
          cardTitle = "Ver Mapa";
        }
    }

    return Scaffold(
      backgroundColor: themeColor.withOpacity(0.03),//Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // --- HEADER DINÁMICO ---
          SliverAppBar(
            pinned: true,
            expandedHeight: 160.0, // Alto para lucir la foto
            backgroundColor: themeColor, // Color de respaldo
            surfaceTintColor: Colors.white,
            
            // Botón "Volver al Hub" 
            leading: IconButton(
              tooltip: "Volver al inicio",
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white, // Fondo blanco para resaltar sobre la foto
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apps_rounded, color: Colors.black87, size: 22),
              ),
              onPressed: () => context.go('/'), 
            ),

            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(left: 60, right: 60, bottom: 16),
              
              // TÍTULO
              title: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     Text(
                      titleLine1, 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 20, 
                        height: 1.0,
                        letterSpacing: -0.5,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                      )
                     ),
                     Text(
                      titleLine2, 
                      style: TextStyle(
                        color: themeColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, // Contraste automático
                        fontWeight: FontWeight.bold, 
                        fontSize: 10,
                        shadows: const [Shadow(color: Colors.black, blurRadius: 5)]
                      )
                     ),
                  ],
                ),
              ),

              // FONDO (IMAGEN)
              background: Stack(
                fit: StackFit.expand,
                children: [
                   CachedNetworkImage(
                     imageUrl: bgImage, 
                     fit: BoxFit.cover,
                     placeholder: (_,__) => Container(color: themeColor),
                     errorWidget: (_,__,___) => Container(color: themeColor),
                   ),
                   // Velo oscuro para leer texto
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                       )
                     )
                   ), 
                ],
              ),
            ),
            
            // Botón Perfil
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final userAsync = ref.watch(authStateProvider);
                  final user = userAsync.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: user != null ? const NetworkImage('https://i.pravatar.cc/150?img=68') : null,
                        child: user == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // --- CONTENIDO DEL DASHBOARD ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta Mapa
                  HomeEventCard(
                    title: cardTitle,
                    imageUrl: bgImage, // Reusamos la imagen del evento para coherencia
                    onTap: () => context.go('/event/$eventId/map'),
                  ),
                  
                  const SizedBox(height: 30),

                  // Sección Destacados
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: 'Favoritos ⭐', color: themeColor),
                      //if (establishmentsAsync.isLoading)
                      if (rankingAsync.isLoading)
                        const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Lista Horizontal
                  //HomeEstablishmentsList(establishmentsAsync: establishmentsAsync),
                  HomeRankingCarousel(rankingAsync: rankingAsync,
                    establishmentsAsync: establishmentsAsync,
                  ),
                  
                  const SizedBox(height: 80), // Espacio final
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar de Título
class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});
  @override
  Widget build(BuildContext context) {
    return Text(
      title, 
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)
    );
  }
}
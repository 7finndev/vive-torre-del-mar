import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// MODELOS
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

// PROVIDERS
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/scan_status_provider.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';

// WIDGETS Y REPOS
import 'package:torre_del_mar_app/features/scan/presentation/widgets/star_rating_selector.dart';
import 'package:torre_del_mar_app/core/utils/smart_image_container.dart';

// --- NUEVO IMPORT ---
import 'package:torre_del_mar_app/features/home/presentation/widgets/menu_product_view.dart';
import 'package:share_plus/share_plus.dart';
// --------------------

class EstablishmentDetailScreen extends ConsumerWidget {
  final EstablishmentModel establishment;

  const EstablishmentDetailScreen({super.key, required this.establishment});

  // --- Funciones auxiliares para acciones ---
  Future<void> _launchSocial(
    BuildContext context,
    String? urlString, {
    bool isTel = false,
  }) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Dato no disponible")));
      return;
    }
    final Uri uri = isTel
        ? Uri(scheme: 'tel', path: urlString)
        : Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir la aplicación")),
        );
      }
    }
  }

  Future<void> _openMap(BuildContext context) async {
    if (establishment.latitude == null || establishment.longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ubicación no disponible")));
      return;
    }
    final url =
        "http://googleusercontent.com/maps.google.com/maps?q=${establishment.latitude},${establishment.longitude}";
    _launchSocial(context, url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. DATOS GENERALES
    final productsAsync = ref.watch(productsListProvider);
    final eventAsync = ref.watch(currentEventProvider);

    // 2. ESTADO DEL EVENTO
    String eventStatus = 'active';
    int currentEventId = 1;
    double? basePrice;

    if (eventAsync.hasValue && eventAsync.value != null) {
      eventStatus = eventAsync.value!.computedStatus; //.status;
      currentEventId = eventAsync.value!.id;
      basePrice = eventAsync.value!.basePrice;
    }

    // 3. BUSCAR TAPA DE ESTE LOCAL
    ProductModel? product;
    if (productsAsync.hasValue) {
      try {
        product = productsAsync.value!.firstWhere(
          (p) => p.establishmentId == establishment.id,
        );
      } catch (_) {}
    }

    // 4. ESTADO DEL VISADO (¿Ya lo tengo sellado?)
    final hasStamp = ref.watch(
      hasStampProvider(
        establishmentId: establishment.id,
        eventId: currentEventId,
      ),
    );

    // 5. PRECIO
    String priceText = "";
    if (product != null) {
      final double? price = product.price ?? basePrice;
      if (price != null) priceText = "${price.toStringAsFixed(2)} €";
    }

    // Lógica de disponibilidad
    final bool isProductAvailable = product?.isAvailable ?? true;

    //Deteccióin de tipo
    final bool isMenu = product != null && product.items.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // A. HEADER (Imagen Principal)
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                establishment.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // IMAGEN MEJORADA
                  SmartImageContainer(
                    imageUrl: establishment.coverImage,
                    borderRadius: 0, // 0 porque llena la pantalla
                  ),
                  // Degradado para que se lea el título
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // B. CUERPO DE LA PANTALLA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ACCIONES RÁPIDAS (Llamar, Web, Ir) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.call,
                        label: "Llamar",
                        onTap: () => _launchSocial(
                          context,
                          establishment.phone,
                          isTel: true,
                        ),
                      ),
                      _ActionButton(
                        icon: Icons.language,
                        label: "Web",
                        color: establishment.website != null
                            ? Colors.orange
                            : Colors.grey,
                        onTap: () =>
                            _launchSocial(context, establishment.website),
                      ),
                      _ActionButton(
                        icon: Icons.directions,
                        label: "Ir",
                        onTap: () => _openMap(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- REDES SOCIALES ---
                  if (establishment.facebook != null ||
                      establishment.instagram != null ||
                      establishment.socialTiktok != null) ...[
                    const Text(
                      "Síguenos en redes",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (establishment.facebook != null)
                          _SocialButton(
                            icon: FontAwesomeIcons.facebook,
                            color: const Color(0xFF1877F2),
                            onTap: () =>
                                _launchSocial(context, establishment.facebook),
                          ),
                        if (establishment.instagram != null)
                          _SocialButton(
                            icon: FontAwesomeIcons.instagram,
                            color: const Color(0xFFE4405F),
                            onTap: () =>
                                _launchSocial(context, establishment.instagram),
                          ),
                        if (establishment.socialTiktok != null)
                          _SocialButton(
                            icon: FontAwesomeIcons.tiktok,
                            color: Colors.black,
                            onTap: () => _launchSocial(
                              context,
                              establishment.socialTiktok,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- DESCRIPCIÓN Y HORARIO ---
                  const Text(
                    "Sobre el local",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    establishment.description ?? "Sin descripción disponible.",
                    style: const TextStyle(color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          establishment.schedule ?? "Horario no disponible",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 40),

                  // --- C. TARJETA DE PRODUCTO ---
                  const Text(
                    "Propuesta Gastronómica",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // LÓGICA DE VISUALIZACIÓN (Menú vs Tapa)
                  if (isMenu)
                    // OPCIÓN 1: MENÚ ESTILO PLEX
                    MenuProductView(product: product)
                  else
                    // OPCIÓN 2: TAPA CLÁSICA
                    Opacity(
                      opacity: isProductAvailable ? 1.0 : 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: hasStamp
                              ? Border.all(color: Colors.green, width: 2)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. BANNER GANADOR
                            if (product?.isWinner == true)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD700),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        eventAsync.value != null
                                            ? "GANADOR - ${eventAsync.value!.name.toUpperCase()}"
                                            : "GANADOR",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 2. FOTO
                            SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: product?.isWinner == true
                                        ? BorderRadius.zero
                                        : const BorderRadius.vertical(
                                            top: Radius.circular(14),
                                          ),
                                    child: ColorFiltered(
                                      colorFilter: isProductAvailable
                                          ? const ColorFilter.mode(
                                              Colors.transparent,
                                              BlendMode.dst,
                                            )
                                          : const ColorFilter.matrix(<double>[
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                            ]),
                                      child: SmartImageContainer(
                                        imageUrl: product?.imageUrl,
                                        borderRadius: 0,
                                      ),
                                    ),
                                  ),
                                  if (!isProductAvailable)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black38,
                                        child: const Center(
                                          child: Text(
                                            "AGOTADO",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 3. INFO DE LA TAPA
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product?.name ?? "Cargando...",
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (priceText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            priceText,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  // Resto de info (descripción, ingredientes, alergenos...)
                                  const SizedBox(height: 8),
                                  Text(
                                    product?.description ?? "...",
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 15,
                                    ),
                                  ),

                                  if (product?.ingredients != null &&
                                      product!.ingredients!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      "Ingredientes:",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      product.ingredients!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],

                                  if (product?.allergens != null &&
                                      product!.allergens!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: product.allergens!
                                          .map((l) => _AllergenChip(label: l))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // --- D. BOTÓN DE ESCANEAR / VOTAR ---
                  Builder(
                    builder: (context) {
                      String label = "ESCANEAR CÓDIGO";
                      IconData icon = Icons.qr_code_scanner;
                      Color btnColor = Colors.orange;
                      VoidCallback? action;

                      if (!isProductAvailable) {
                        label = "NO DISPONIBLE";
                        icon = Icons.block;
                        btnColor = Colors.grey;
                        action = null;
                      } else if (hasStamp) {
                        label = "¡VISADO!";
                        icon = Icons.check_circle;
                        btnColor = Colors.green;
                        action = () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("¡Ya completado!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                      } else if (eventStatus == 'upcoming') {
                        label = "PRÓXIMAMENTE";
                        icon = Icons.calendar_today;
                        btnColor = Colors.blue;
                        action = () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Este evento aún no ha comenzado.",
                                ),
                              ),
                            );
                      } else if (eventStatus == 'archived') {
                        label = "EVENTO FINALIZADO";
                        icon = Icons.history;
                        btnColor = Colors.grey;
                        action = null;
                      } else {
                        action = () async {
                          final bool? result = await context.push<bool>(
                            '/scan',
                            extra: establishment,
                          );
                          if (result == true && context.mounted) {
                            _showVotingDialog(
                              context,
                              ref,
                              establishment,
                              currentEventId,
                            );
                          }
                        };
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: action,
                          icon: Icon(icon),
                          label: Text(label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: action == null ? 0 : 4,
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 40),

                  // --- MAPA ---
                  const Text(
                    "Ubicación",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (establishment.latitude != null &&
                      establishment.longitude != null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              establishment.latitude!,
                              establishment.longitude!,
                            ),
                            initialZoom: 16.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    establishment.latitude!,
                                    establishment.longitude!,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

// --- WIDGETS AUXILIARES ---

void _showVotingDialog(
  BuildContext context,
  WidgetRef ref,
  EstablishmentModel establishment,
  int eventId,
) {
  int rating = 0;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("¡Código Correcto! ✅"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Por favor, valora la tapa:"),
            const SizedBox(height: 20),
            StarRatingSelector(
              onRatingChanged: (v) => setState(() => rating = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: rating == 0
                ? null
                : () async {
                    // 1. CERRAR EL DIÁLOGO DE ESTRELLAS
                    Navigator.pop(context); 

                    // 2. GUARDAR EN BD
                    await ref
                        .read(passportRepositoryProvider)
                        .saveStamp(
                          establishmentId: establishment.id,
                          establishmentName: establishment.name,
                          gpsVerified: true,
                          rating: rating,
                          eventId: eventId,
                        );
                    
                    // 3. ACTUALIZAR ESTADO LOCAL
                    ref.invalidate(
                      hasStampProvider(
                        establishmentId: establishment.id,
                        eventId: eventId,
                      ),
                    );

                    // 4. SINCRONIZAR EN SEGUNDO PLANO
                    ref.read(syncServiceProvider).syncPendingVotes(targetEventId: eventId);

                    // 5. ✨ MOSTRAR EL DIÁLOGO DE COMPARTIR (NUEVO)
                    if (context.mounted) {
                      _showSuccessAndShareDialog(context, establishment.name, rating);
                    }
                  },
            child: const Text("GUARDAR VISADO"),
          ),
        ],
      ),
    ),
  );
}

// --- NUEVA FUNCIÓN PARA COMPARTIR ---
void _showSuccessAndShareDialog(BuildContext context, String barName, int rating) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 10),
          const Text("¡Voto Guardado!", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            "Has dado $rating estrellas ⭐", 
            style: const TextStyle(fontSize: 14, color: Colors.grey)
          ),
        ],
      ),
      content: const Text(
        "Tu visita ha quedado registrada en el Pasaporte.\n¿Quieres compartirlo con tus amigos?",
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center, // Centrados
      actions: [
        // BOTÓN SALIR (Gris/Simple)
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Salir", style: TextStyle(color: Colors.grey)),
        ),
        
        const SizedBox(width: 10),

        // BOTÓN COMPARTIR (Verde/Llamativo) 🚀
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, 
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          icon: const Icon(Icons.share, size: 18),
          label: const Text("Compartir"),
          onPressed: () {
            final String stars = "⭐" * rating;
            final String message = "¡Acabo de probar la tapa de *$barName* en la Ruta de la Tapa! 🥘😋\n\nMi valoración: $rating/5 $stars\n\nDescarga la App y participa: www.torredelmar.org";
            
            // Lanza el menú nativo del móvil
            Share.share(message);
            
            // Cerramos el diálogo tras pulsar compartir
            Navigator.pop(ctx); 
          },
        ),
      ],
    ),
  );
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.orange,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _AllergenChip extends StatelessWidget {
  final String label;
  const _AllergenChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.orange[900],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

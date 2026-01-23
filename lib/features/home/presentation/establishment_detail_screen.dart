import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http; 
import 'package:geolocator/geolocator.dart'; 

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
import 'package:torre_del_mar_app/features/home/presentation/widgets/menu_product_view.dart';
import 'package:share_plus/share_plus.dart';

// WIDGET DE ERROR
import 'package:torre_del_mar_app/core/widgets/error_view.dart';

class EstablishmentDetailScreen extends ConsumerStatefulWidget {
  final EstablishmentModel establishment;

  const EstablishmentDetailScreen({super.key, required this.establishment});

  @override
  ConsumerState<EstablishmentDetailScreen> createState() =>
      _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState
    extends ConsumerState<EstablishmentDetailScreen> {
  // Variables de Estado para el Mapa y Ruta
  List<LatLng> routePoints = [];
  bool isRouteLoading = false;
  LatLng? myPosition;

  // --- LÓGICA DE CÁLCULO DE RUTA (OSRM) ---
  Future<void> _calculateRoute() async {
    if (widget.establishment.latitude == null ||
        widget.establishment.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Este local no tiene ubicación definida")),
        );
      }
      return;
    }

    setState(() => isRouteLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "El GPS está desactivado. Actívalo para ver la ruta.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Necesitamos permiso de ubicación para trazar la ruta.";
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw "Permisos de ubicación denegados permanentemente.";
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        myPosition = LatLng(position.latitude, position.longitude);
      });

      final distanceInMeters = const Distance().as(
        LengthUnit.Meter,
        LatLng(position.latitude, position.longitude),
        LatLng(widget.establishment.latitude!, widget.establishment.longitude!),
      );

      final String profile = distanceInMeters > 1500 ? 'driving' : 'foot';

      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/$profile/${position.longitude},${position.latitude};${widget.establishment.longitude},${widget.establishment.latitude}?geometries=geojson&overview=full');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          throw "No se encontró una ruta disponible.";
        }
        final List<dynamic> coords =
            data['routes'][0]['geometry']['coordinates'];
        
        setState(() {
          routePoints =
              coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        });
      } else {
        throw "Error al conectar con el servidor de rutas (OSRM).";
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isRouteLoading = false);
    }
  }

  Future<void> _openExternalMap() async {
    if (widget.establishment.latitude == null ||
        widget.establishment.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ubicación no disponible")),
      );
      return;
    }

    final Uri mapUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${widget.establishment.latitude},${widget.establishment.longitude}");

    try {
      if (!await launchUrl(mapUrl, mode: LaunchMode.externalApplication)) {
        await launchUrl(mapUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el mapa externo")),
        );
      }
    }
  }

  Future<void> _launchSocial(
    BuildContext context,
    String? urlString, {
    bool isTel = false,
  }) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dato no disponible")));
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

  @override
  Widget build(BuildContext context) {
    // 1. DATOS GENERALES
    final productsAsync = ref.watch(productsListProvider);
    final eventAsync = ref.watch(currentEventProvider);

    // 2. ESTADO DEL EVENTO
    String eventStatus = 'active';
    int currentEventId = 1;
    double? basePrice;
    Color refreshColor = Colors.orange; // Color por defecto para el RefreshIndicator

    if (eventAsync.hasValue && eventAsync.value != null) {
      eventStatus = eventAsync.value!.computedStatus;
      currentEventId = eventAsync.value!.id;
      basePrice = eventAsync.value!.basePrice;
      
      // Intentamos sacar el color del tema
      try {
        if (eventAsync.value!.themeColorHex.isNotEmpty) {
           String cleanHex = eventAsync.value!.themeColorHex.replaceAll('#', '');
           if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
           refreshColor = Color(int.parse(cleanHex, radix: 16));
        }
      } catch (_) {}
    }

    // 3. ESTADO DEL VISADO (¿Ya lo tengo sellado?)
    final hasStamp = ref.watch(
      hasStampProvider(
        establishmentId: widget.establishment.id,
        eventId: currentEventId,
      ),
    );

    final ProductModel? safeProduct = productsAsync.valueOrNull?.where(
        (p) => p.establishmentId == widget.establishment.id
    ).firstOrNull;

    final bool isProductAvailable = safeProduct?.isAvailable ?? true;
    
    return Scaffold(
      // ✅ AÑADIDO: RefreshIndicator para recargar deslizando
      body: RefreshIndicator(
        color: refreshColor,
        backgroundColor: Colors.white,
        onRefresh: () async {
          // Invalidamos proveedores clave
          ref.invalidate(productsListProvider); // Recargar tapas
          ref.invalidate(currentEventProvider); // Recargar evento (precios, estado)
          ref.invalidate(establishmentsListProvider); // Recargar lista de bares (por si cambió info del local)
          
          // Recargamos el estado del sello específico
          ref.invalidate(hasStampProvider(
            establishmentId: widget.establishment.id,
            eventId: currentEventId
          ));
          
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Necesario para que funcione el gesto
          slivers: [
            // A. HEADER
            SliverAppBar(
              expandedHeight: 250.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.establishment.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmartImageContainer(
                      imageUrl: widget.establishment.coverImage,
                      borderRadius: 0,
                    ),
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
                    // --- ACCIONES RÁPIDAS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.call,
                          label: "Llamar",
                          onTap: () => _launchSocial(
                            context,
                            widget.establishment.phone,
                            isTel: true,
                          ),
                        ),
                        _ActionButton(
                          icon: Icons.language,
                          label: "Web",
                          color: widget.establishment.website != null
                              ? Colors.orange
                              : Colors.grey,
                          onTap: () => _launchSocial(
                              context, widget.establishment.website),
                        ),
                        _ActionButton(
                          icon: Icons.directions,
                          label: "Ir",
                          onTap: _openExternalMap, 
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- REDES SOCIALES ---
                    if (widget.establishment.facebook != null ||
                        widget.establishment.instagram != null ||
                        widget.establishment.socialTiktok != null) ...[
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
                          if (widget.establishment.facebook != null)
                            _SocialButton(
                              icon: FontAwesomeIcons.facebook,
                              color: const Color(0xFF1877F2),
                              onTap: () => _launchSocial(
                                  context, widget.establishment.facebook),
                            ),
                          if (widget.establishment.instagram != null)
                            _SocialButton(
                              icon: FontAwesomeIcons.instagram,
                              color: const Color(0xFFE4405F),
                              onTap: () => _launchSocial(
                                  context, widget.establishment.instagram),
                            ),
                          if (widget.establishment.socialTiktok != null)
                            _SocialButton(
                              icon: FontAwesomeIcons.tiktok,
                              color: Colors.black,
                              onTap: () => _launchSocial(
                                context,
                                widget.establishment.socialTiktok,
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
                      widget.establishment.description ?? "Sin descripción disponible.",
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
                            widget.establishment.schedule ?? "Horario no disponible",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 40),

                    // --- C. TARJETA DE PRODUCTO (BLINDADA CON ERRORVIEW) ---
                    const Text(
                      "Propuesta Gastronómica",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    productsAsync.when(
                      // 1. Cargando
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      
                      // 2. Error (Sin conexión) -> Muestra widget amigable y botón refrescar
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ErrorView(
                           error: err, 
                           isCompact: true,
                           onRetry: () => ref.invalidate(productsListProvider),
                        ),
                      ),

                      // 3. Datos listos
                      data: (products) {
                        ProductModel? product;
                        try {
                          product = products.firstWhere((p) => p.establishmentId == widget.establishment.id);
                        } catch (_) {}

                        if (product == null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Este establecimiento no tiene tapa/producto asignado en este evento.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // LOGICA DE VISUALIZACIÓN
                        String priceText = "";
                        final double? price = product.price ?? basePrice;
                        if (price != null) priceText = "${price.toStringAsFixed(2)} €";
                        
                        final bool isMenu = product.items.isNotEmpty;
                        final bool isAvailable = product.isAvailable;

                        if (isMenu) return MenuProductView(product: product);
                        
                        return Opacity(
                          opacity: isAvailable ? 1.0 : 0.6,
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
                                // Banner Ganador
                                if (product.isWinner)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFD700),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.emoji_events, color: Colors.black87, size: 20),
                                        const SizedBox(width: 8),
                                        const Text("GANADOR", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13)),
                                      ],
                                    ),
                                  ),

                                // Foto
                                SizedBox(
                                  height: 220,
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: product.isWinner 
                                            ? BorderRadius.zero 
                                            : const BorderRadius.vertical(top: Radius.circular(14)),
                                        child: SmartImageContainer(imageUrl: product.imageUrl, borderRadius: 0),
                                      ),
                                      if (!isAvailable)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black38,
                                            child: const Center(
                                              child: Text("AGOTADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Info Tapa
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product!.name,
                                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (priceText.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(priceText, style: TextStyle(fontSize: 18, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Descripción segura
                                      Text(
                                        product.description ?? "Sin descripción disponible.", 
                                        style: TextStyle(color: Colors.grey[800], fontSize: 15)
                                      ),
                                      
                                      if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text("Ingredientes:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                        Text(product.ingredients!, style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
                                      ],

                                      if (product.allergens != null && product.allergens!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 6, runSpacing: 6,
                                          children: product.allergens!.map((l) => _AllergenChip(label: l)).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- D. BOTÓN DE ESCANEAR / VOTAR (BLINDADO) ---
                    Builder(
                      builder: (context) {
                        String label = "ESCANEAR CÓDIGO";
                        IconData icon = Icons.qr_code_scanner;
                        Color btnColor = Colors.orange;
                        VoidCallback? action;

                        // 1. 🛡️ BLOQUEO POR ERROR DE CONEXIÓN
                        if (productsAsync.hasError) {
                          label = "SIN CONEXIÓN";
                          icon = Icons.wifi_off;
                          btnColor = Colors.grey;
                          action = null; // Botón desactivado
                        } 
                        // 2. ⏳ BLOQUEO POR CARGA
                        else if (productsAsync.isLoading) {
                          label = "CARGANDO...";
                          icon = Icons.hourglass_top;
                          btnColor = Colors.grey;
                          action = null; 
                        }
                        // 3. 🚫 BLOQUEO SI NO HAY DATOS DE TAPA
                        else if (safeProduct == null) {
                          label = "INFO NO DISPONIBLE";
                          icon = Icons.error_outline;
                          btnColor = Colors.grey;
                          action = null; 
                        }
                        // 4. LÓGICA DE NEGOCIO NORMAL
                        else if (!isProductAvailable) {
                          label = "AGOTADO / NO DISPONIBLE";
                          icon = Icons.block;
                          btnColor = Colors.grey;
                          action = null;
                        } else if (hasStamp) {
                          label = "¡VISADO!";
                          icon = Icons.check_circle;
                          btnColor = Colors.green;
                          action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ya completado!"), backgroundColor: Colors.green));
                        } else if (eventStatus == 'upcoming') {
                          label = "PRÓXIMAMENTE";
                          icon = Icons.calendar_today;
                          btnColor = Colors.blue;
                          action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Este evento aún no ha comenzado.")));
                        } else if (eventStatus == 'archived') {
                          label = "EVENTO FINALIZADO";
                          icon = Icons.history;
                          btnColor = Colors.grey;
                          action = null;
                        } else {
                          // ACCIÓN PRINCIPAL
                          action = () async {
                            final bool? result = await context.push<bool>(
                              '/scan',
                              extra: widget.establishment,
                            );
                            if (result == true && context.mounted) {
                              _showVotingDialog(
                                context,
                                ref,
                                widget.establishment,
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
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 40),

                    // --- E. MAPA INTERACTIVO ---
                    const Text("Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (widget.establishment.latitude != null && widget.establishment.longitude != null)
                      Stack(
                        children: [
                          Container(
                            height: 350,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(widget.establishment.latitude!, widget.establishment.longitude!),
                                  initialZoom: 15.0,
                                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.torredelmar.acet.app',
                                    errorTileCallback: (tile, error, stackTrace) {},
                                  ),
                                  if (routePoints.isNotEmpty)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(points: routePoints, strokeWidth: 5.0, color: Colors.blueAccent),
                                      ],
                                    ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(widget.establishment.latitude!, widget.establishment.longitude!),
                                        width: 60, height: 60,
                                        child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                                      ),
                                      if (myPosition != null)
                                        Marker(
                                          point: myPosition!,
                                          width: 40, height: 40,
                                          child: Container(
                                            decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]),
                                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16, right: 16,
                            child: FloatingActionButton.extended(
                              heroTag: "btn_route_internal",
                              onPressed: isRouteLoading ? null : _calculateRoute,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue[800],
                              icon: isRouteLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.route),
                              label: Text(routePoints.isEmpty ? "Ver Ruta (GPS)" : "Recalcular"),
                            ),
                          ),
                        ],
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

// --- WIDGETS AUXILIARES (Sin cambios) ---

void _showVotingDialog(BuildContext context, WidgetRef ref, EstablishmentModel establishment, int eventId) {
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
            StarRatingSelector(onRatingChanged: (v) => setState(() => rating = v)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: rating == 0 ? null : () async {
              Navigator.pop(context);
              await ref.read(passportRepositoryProvider).saveStamp(
                    establishmentId: establishment.id,
                    establishmentName: establishment.name,
                    gpsVerified: true,
                    rating: rating,
                    eventId: eventId,
                  );
              ref.invalidate(hasStampProvider(establishmentId: establishment.id, eventId: eventId));
              ref.read(syncServiceProvider).syncPendingVotes(targetEventId: eventId);
              if (context.mounted) _showSuccessAndShareDialog(context, establishment.name, rating);
            },
            child: const Text("GUARDAR VISADO"),
          ),
        ],
      ),
    ),
  );
}

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
          Text("Has dado $rating estrellas ⭐", style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
      content: const Text("Tu visita ha quedado registrada en el Pasaporte.\n¿Quieres compartirlo con tus amigos?", textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Salir", style: TextStyle(color: Colors.grey))),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 2),
          icon: const Icon(Icons.share, size: 18),
          label: const Text("Compartir"),
          onPressed: () {
            final String stars = "⭐" * rating;
            final String message = "¡Acabo de probar la tapa de *$barName* en la Ruta de la Tapa! 🥘😋\n\nMi valoración: $rating/5 $stars\n\nDescarga la App y participa: www.torredelmar.org";
            Share.share(message);
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
  const _SocialButton({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
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
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color = Colors.orange});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(radius: 26, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 24)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
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
      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)),
      child: Text(label.toUpperCase(), style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
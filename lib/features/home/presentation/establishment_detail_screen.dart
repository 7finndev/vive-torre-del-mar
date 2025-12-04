import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; // Para llamadas/mapas

// MODELOS
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';

// PROVIDERS
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/scan_status_provider.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';

// WIDGETS Y REPOS
import 'package:torre_del_mar_app/features/scan/presentation/widgets/star_rating_selector.dart';
import 'package:torre_del_mar_app/features/scan/data/repositories/passport_repository.dart';

class EstablishmentDetailScreen extends ConsumerWidget {
  final EstablishmentModel establishment;

  const EstablishmentDetailScreen({super.key, required this.establishment});

  // Funciones auxiliares para botones de acción (Llamar, Web, Ir)
  Future<void> _launchSocial(BuildContext context, String? urlString, {bool isTel = false}) async {
    if (urlString == null || urlString.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dato no disponible")));
       return;
    }
    final Uri uri = isTel ? Uri(scheme: 'tel', path: urlString) : Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw 'Could not launch';
    } catch (e) {
       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir la aplicación")));
    }
  }
  
  Future<void> _openMap(BuildContext context) async {
    if (establishment.latitude == null || establishment.longitude == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ubicación no disponible")));
       return;
    }
    final url = "https://www.google.com/maps/dir/?api=1&destination=${establishment.latitude},${establishment.longitude}";
    _launchSocial(context, url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. DATOS GENERALES
    final productsAsync = ref.watch(productsListProvider);
    final eventAsync = ref.watch(currentEventProvider);

    // 2. ESTADO DEL EVENTO (Lógica de 3 estados)
    String eventStatus = 'active'; // Por defecto asumimos activo
    int currentEventId = 1;
    double? basePrice;

    if (eventAsync.hasValue && eventAsync.value != null) {
      eventStatus = eventAsync.value!.status; // 'active', 'upcoming', 'archived'
      currentEventId = eventAsync.value!.id;
      basePrice = eventAsync.value!.basePrice;
    }

    // 3. BUSCAR TAPA
    ProductModel? tapa;
    if (productsAsync.hasValue) {
      try {
        tapa = productsAsync.value!.firstWhere((p) => p.establishmentId == establishment.id);
      } catch (_) {}
    }

    // 4. ESTADO DEL VISADO (Filtrado por evento actual)
    final hasStamp = ref.watch(hasStampProvider(
      establishmentId: establishment.id, 
      eventId: currentEventId
    ));

    // 5. PRECIO
    String priceText = "";
    if (tapa != null) {
       final double? price = tapa.price ?? basePrice;
       if (price != null) priceText = "${price.toStringAsFixed(2)} €";
    }
    
    // Lógica de disponibilidad del local
    final bool isTapaAvailable = tapa?.isAvailable ?? true;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // A. HEADER
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(establishment.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
              background: CachedNetworkImage(
                imageUrl: establishment.coverImage ?? 'https://via.placeholder.com/600x400',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[300]),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.store)),
              ),
            ),
          ),

          // B. CUERPO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACCIONES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(icon: Icons.call, label: "Llamar", onTap: () => _launchSocial(context, establishment.phone, isTel: true)),
                      _ActionButton(icon: Icons.language, label: "Web", color: establishment.website != null ? Colors.orange : Colors.grey, onTap: () => _launchSocial(context, establishment.website)),
                      _ActionButton(icon: Icons.directions, label: "Ir", onTap: () => _openMap(context)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text("Sobre el local", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(establishment.description ?? "Sin descripción disponible.", style: const TextStyle(color: Colors.grey, height: 1.4)),
                  
                  const SizedBox(height: 16),
                  Row(children: [
                      const Icon(Icons.access_time, size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(establishment.schedule ?? "Horario no disponible", style: const TextStyle(fontWeight: FontWeight.w500))),
                  ]),
                  
                  const Divider(height: 40),

                  // C. TARJETA TAPA
                  const Text("Propuesta Gastronómica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,4))],
                      border: Border.all(color: hasStamp ? Colors.green : Colors.transparent, width: 2)
                    ),
                    child: Column(
                      children: [
                        // Banner Ganador
                        if (tapa?.isWinner == true)
                          Container(
                            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: const BoxDecoration(color: Color(0xFFFFD700), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.emoji_events, color: Colors.black87, size: 20), SizedBox(width: 8), Text("MEJOR TAPA 2025", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900))]),
                          ),

                        ClipRRect(
                          borderRadius: tapa?.isWinner == true ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(14)),
                          child: CachedNetworkImage(
                            imageUrl: tapa?.imageUrl ?? '', height: 200, width: double.infinity, fit: BoxFit.cover,
                            errorWidget: (_,__,___) => Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.restaurant)),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: Text(tapa?.name ?? "Cargando...", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                  if (priceText.isNotEmpty) Text(priceText, style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(tapa?.description ?? "...", style: TextStyle(color: Colors.grey[700])),
                              
                              // Alérgenos
                              if (tapa?.allergens != null && tapa!.allergens!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Wrap(spacing: 6, runSpacing: 6, children: tapa.allergens!.map((l) => _AllergenChip(label: l)).toList()),
                              ],

                              const SizedBox(height: 20),
                              
                              // --- BOTÓN INTELIGENTE (CORREGIDO) ---
                              Builder(
                                builder: (context) {
                                  String label = "ESCANEAR CÓDIGO";
                                  IconData icon = Icons.qr_code_scanner;
                                  Color btnColor = Colors.orange;
                                  VoidCallback? action;

                                  // 1. Si no está disponible (Técnico)
                                  if (!isTapaAvailable) {
                                    label = "NO DISPONIBLE";
                                    icon = Icons.block;
                                    btnColor = Colors.grey;
                                    action = null;
                                  }
                                  // 2. Si ya está visado (Prioridad sobre estado del evento)
                                  else if (hasStamp) {
                                    label = "¡VISADO!";
                                    icon = Icons.check_circle;
                                    btnColor = Colors.green;
                                    action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ya completado!"), backgroundColor: Colors.green));
                                  }
                                  // 3. Si el evento es FUTURO
                                  else if (eventStatus == 'upcoming') {
                                    label = "PRÓXIMAMENTE"; // <--- AQUÍ ESTÁ LA CORRECCIÓN
                                    icon = Icons.calendar_today;
                                    btnColor = Colors.blue;
                                    action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Este evento aún no ha comenzado.")));
                                  }
                                  // 4. Si el evento es PASADO
                                  else if (eventStatus == 'archived') {
                                    label = "EVENTO FINALIZADO";
                                    icon = Icons.history;
                                    btnColor = Colors.grey;
                                    action = null;
                                  }
                                  // 5. ESTADO ACTIVO (Escanear)
                                  else {
                                    action = () async {
                                        final bool? result = await context.push<bool>('/scan', extra: establishment);
                                        if (result == true && context.mounted) {
                                           _showVotingDialog(context, ref, establishment, currentEventId);
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
                                }
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 40),
                  // Mapa estático y resto...
                  const Text("Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (establishment.latitude != null && establishment.longitude != null)
                    Container(height: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(initialCenter: LatLng(establishment.latitude!, establishment.longitude!), initialZoom: 16.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                          children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'), MarkerLayer(markers: [Marker(point: LatLng(establishment.latitude!, establishment.longitude!), child: const Icon(Icons.location_on, color: Colors.red, size: 40))])],
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

// --- FUNCIONES AUXILIARES (MANTENER) ---
void _showVotingDialog(BuildContext context, WidgetRef ref, EstablishmentModel establishment, int eventId) {
  int rating = 0;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("¡Código Correcto! ✅"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Por favor, valora la tapa:"), const SizedBox(height: 20), StarRatingSelector(onRatingChanged: (v) => setState(() => rating = v))]),
        actions: [
          TextButton(
            onPressed: rating == 0 ? null : () async {
              Navigator.pop(context);
              await ref.read(passportRepositoryProvider).saveStamp(establishmentId: establishment.id, establishmentName: establishment.name, gpsVerified: true, rating: rating, eventId: eventId);
              ref.invalidate(hasStampProvider(establishmentId: establishment.id, eventId: eventId));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Visado guardado!"), backgroundColor: Colors.green));
              ref.read(syncServiceProvider).syncPendingVotes(targetEventId: eventId);
            },
            child: const Text("GUARDAR VISADO"),
          )
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color color;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color = Colors.orange});
  @override
  Widget build(BuildContext context) {
    return Column(children: [CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.1), child: IconButton(icon: Icon(icon, color: color), onPressed: onTap)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]);
  }
}

class _AllergenChip extends StatelessWidget {
  final String label;
  const _AllergenChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.shade100)), child: Text(label.toUpperCase(), style: TextStyle(color: Colors.orange[900], fontSize: 10, fontWeight: FontWeight.bold)));
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:torre_del_mar_app/core/widgets/error_view.dart';
import 'package:torre_del_mar_app/features/admin/data/dashboard_repository.dart';
import 'package:torre_del_mar_app/features/admin/presentation/screens/admin_sponsors_screen.dart';

// --- IMPORTS DE TU PROYECTO ---
// Ajusta las rutas relativas según tu estructura exacta
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/event_repository.dart'; // Para adminEventsListProvider
import 'providers/dashboard_providers.dart'; // <--- El archivo de providers que creamos antes

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Lista de eventos (para el Dropdown)
    final eventsListAsync = ref.watch(adminEventsListProvider);

    // 2. Evento seleccionado actualmente (Filtro)
    final selectedEvent = ref.watch(dashboardSelectedEventProvider);

    // 3. Estadísticas (reaccionan al cambio de selectedEvent)
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo limpio
      appBar: AppBar(
        title: const Text("Panel de Control"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Esto invalida la caché y fuerza la recarga de TODOS los contadores
              ref.invalidate(dashboardStatsProvider); 
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Actualizando datos..."), 
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Al tirar hacia abajo, recargamos todo
          ref.refresh(dashboardStatsProvider);
          ref.refresh(adminEventsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // 1. SELECTOR DE EVENTO (FILTRO)
              // ============================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: eventsListAsync.when(
                  loading: () => const SizedBox(
                    height: 50,
                    child: Center(child: LinearProgressIndicator()),
                  ),
                  //ErrorView:
                  error: (err, _) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.red),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Sin conexión", style: TextStyle(color: Colors.red))),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => ref.invalidate(adminEventsListProvider)
                          )
                        ],
                      ),
                  ),
                  /*
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Error cargando eventos'),
                  ),
                  */
                  data: (events) {
                    // 1. Auto-selección inicial (si no hay nada seleccionado)
                    if (selectedEvent == null && events.isNotEmpty) {
                      Future.microtask(() {
                        try {
                          final active = events.firstWhere(
                            (e) => e.status == 'active',
                          );
                          ref
                                  .read(dashboardSelectedEventProvider.notifier)
                                  .state =
                              active;
                        } catch (_) {}
                      });
                    }

                    // 2. CORRECCIÓN DEL ERROR (ANTI-CRASH)
                    // Buscamos el objeto "fresco" en la lista nueva que coincida con el ID del seleccionado.
                    EventModel? safeValue = selectedEvent;

                    if (safeValue != null) {
                      try {
                        // Intentamos encontrar el equivalente en la nueva lista por ID
                        safeValue = events.firstWhere(
                          (e) => e.id == safeValue!.id,
                        );
                      } catch (_) {
                        // Si no lo encuentra (ej: el evento seleccionado fue borrado),
                        // ponemos null para evitar el pantallazo rojo.
                        safeValue = null;

                        // Opcional: Limpiamos el provider globalmente
                        Future.microtask(
                          () =>
                              ref
                                      .read(
                                        dashboardSelectedEventProvider.notifier,
                                      )
                                      .state =
                                  null,
                        );
                      }
                    }

                    return DropdownButtonHideUnderline(
                      child: DropdownButton<EventModel>(
                        isExpanded: true,
                        hint: const Text("Selecciona un evento"),

                        // USAMOS EL VALOR "SEGURO" CALCULADO ARRIBA
                        value: safeValue,

                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.blue,
                        ),
                        items: events.map((event) {
                          return DropdownMenuItem(
                            value: event,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStatusColor(event.status),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    event.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: event.status == 'active'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: event.status == 'archived'
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newEvent) {
                          ref
                                  .read(dashboardSelectedEventProvider.notifier)
                                  .state =
                              newEvent;
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // 2. BANNER DE ESTADO DEL EVENTO
              // ============================================================
              if (selectedEvent != null) _buildEventStatusBanner(selectedEvent),

              const SizedBox(height: 20),

              // ============================================================
              // 3. GRID DE MÉTRICAS (DATOS REALES)
              // ============================================================
              const Text(
                'Métricas Clave',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              statsAsync.when(
                data: (stats) {
                  // 1. Calculamos los textos antes de pintar
                  final labels = _getDynamicLabels(selectedEvent);
                  final productIcon = _getProductIcon(selectedEvent);

                  //Calculo responsivo
                  //Obtenemos el ancho de pantalla
                  final width = MediaQuery.of(context).size.width;
                  //Si es > 1100px (Pantalla grande) -> 4 columnas.
                  //Si es > 700px (tablet/pantalla pequeña) -> 2 columnas.
                  //Si es movil -> 1 columna
                  int crossAxisCount = width > 1100 ? 4 : (width > 700 ? 2: 1);

                  //Ajustamos la proporción (ancho/alto) para que no se vea estirado
                  double childAspectRatio = width > 1100 ? 1.8 : (width > 700 ? 1.6 : 2.5);

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount, //2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,//1.5,
                    children: [
                      _StatCard(
                        title: 'Escaneos QR',
                        value: stats.totalScans.toString(),
                        icon: Icons.qr_code_scanner,
                        color: Colors.purple,
                        gradient: [
                          Colors.purple.shade50,
                          Colors.purple.shade100,
                        ],
                      ),
                      _StatCard(
                        title: 'Usuarios Totales',
                        value: stats.totalUsers.toString(),
                        icon: Icons.group,
                        color: Colors.blue,
                        gradient: [Colors.blue.shade50, Colors.blue.shade100],
                      ),

                      // TARJETA DINÁMICA 1: PRODUCTOS
                      _StatCard(
                        title: labels['product']!, // <--- TEXTO DINÁMICO
                        value: stats.activeProducts.toString(),
                        icon: productIcon, // <--- ICONO DINÁMICO
                        color: Colors.orange,
                        gradient: [
                          Colors.orange.shade50,
                          Colors.orange.shade100,
                        ],
                      ),

                      // TARJETA DINÁMICA 2: ESTABLECIMIENTOS
                      _StatCard(
                        title: labels['partner']!, // <--- TEXTO DINÁMICO
                        value: stats.activeEstablishments.toString(),
                        icon: Icons.store,
                        color: Colors.teal,
                        gradient: [Colors.teal.shade50, Colors.teal.shade100],
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                //Modificamos esta sección para mostrar mensaje adecuado de error
                // al fallar la conexión:
                error: (err, _) => ErrorView(
                  error: err,
                  onRetry: () => ref.invalidate(dashboardStatsProvider),
                ),
                /* Antiguo mensaje de error.
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Text(
                    'Error cargando datos: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                */
              ),

              const SizedBox(height: 24),

              // ============================================================
              // 4. GRÁFICO (VISUALIZACIÓN)
              // ============================================================
              const Text(
                'Distribución de Participación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              //const _DistributionChart(), // Gráfico de tarta
              statsAsync.when(
                data: (stats) =>
                    _DistributionChart(stats: stats), // Pasamos los datos
                error: (_, __) => const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text("No se pueden cargar datos del gráfico.", 
                    style: TextStyle(color: Colors.grey)
                    )
                  )
                ),
                loading: () => const Center(child: LinearProgressIndicator()),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // 5. ACCESOS RÁPIDOS (NAVEGACIÓN)
              // ============================================================
              const Text(
                'Gestión Rápida',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _QuickActionCard(
                title: 'Eventos',
                subtitle: 'Crear nuevas rutas o modificar fechas',
                icon: Icons.event_note,
                color: Colors.indigo,
                onTap: () => context.go('/admin/events'),
              ),
              _QuickActionCard(
                title: 'Socios y Bares',
                subtitle: 'Gestionar establecimientos locales',
                icon: Icons.storefront,
                color: Colors.green,
                onTap: () => context.go('/admin/socios'),
              ),
              _QuickActionCard(
                title: 'Participaciones',
                subtitle: 'Altas y bajas de Tapas y Cócteles',
                icon: Icons.local_dining,
                color: Colors.redAccent,
                onTap: () => context.go('/admin/participaciones'),
              ),
              // --- NUEVO BOTÓN AÑADIDO ---
              _QuickActionCard(
                title: 'Patrocinadores',
                subtitle: 'Gestionar logos y colaboradores',
                icon: Icons.handshake, // Icono de apretón de manos
                color: Colors.purpleAccent,
                onTap: () {
                   // Navegación directa sin configurar GoRouter
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (context) => const AdminSponsorsScreen()),
                   );
                },
              ),
              // ---------------------------
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS VISUALES ---

  Color _getStatusColor(String status) {
    if (status == 'active') return Colors.green;
    if (status == 'upcoming') return Colors.orange;
    return Colors.grey;
  }

  Widget _buildEventStatusBanner(EventModel event) {
    final isActive = event.status == 'active';
    final isUpcoming = event.status == 'upcoming';

    Color bgColor;
    Color iconColor;
    String text;
    IconData icon;

    if (isActive) {
      bgColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
      text = "Mostrando datos del evento ACTIVO en curso.";
      icon = Icons.online_prediction;
    } else if (isUpcoming) {
      bgColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade700;
      text = "Mostrando datos de un evento PRÓXIMO.";
      icon = Icons.schedule;
    } else {
      bgColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade600;
      text = "Visualizando histórico de evento FINALIZADO.";
      icon = Icons.history;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: iconColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Función para obtener etiquetas dinámicas según el tipo de evento
  Map<String, String> _getDynamicLabels(EventModel? event) {
    // Valores por defecto (Vista Global)
    String productLabel = 'Productos';
    String partnerLabel = 'Socios / Locales';
    IconData productIcon = Icons.local_offer;

    if (event != null) {
      final t = event.type.toLowerCase();
      if (t == 'gastronomic' || t == 'tapas') {
        productLabel = 'Tapas Activas';
        partnerLabel = 'Bares Socios';
        productIcon = Icons.restaurant;
      } else if (t == 'drinks' || t == 'coctel') {
        productLabel = 'Cócteles';
        partnerLabel = 'Pubs / Bares';
        productIcon = Icons.local_bar;
      } else if (t == 'shopping') {
        productLabel = 'Tiendas / Ofertas';
        partnerLabel = 'Comercios';
        productIcon = Icons.shopping_bag;
      }
    }

    return {
      'product': productLabel,
      'partner': partnerLabel,
      // Truco: Pasamos el código del icono como string si quisiéramos,
      // pero aquí mejor devolvemos solo texto y manejamos el icono en el switch de abajo si quieres ser muy detallista.
    };
  }

  // Helper para el icono dinámico (Opcional, si quieres cambiar el icono de tenedor a bolsa)
  IconData _getProductIcon(EventModel? event) {
    if (event?.type == 'shopping') return Icons.shopping_bag;
    if (event?.type == 'drinks') return Icons.local_bar;
    return Icons.restaurant; // Por defecto Tapas
  }
}

// -----------------------------------------------------------------------------
// WIDGET: TARJETA DE ESTADÍSTICA
// -----------------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Quitamos altura fija, dejamos que el Grid controle el tamaño
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye espacio
            children: [
              // 1. ICONO
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

              // 2. VALOR (FittedBox reduce el tamaño del texto si no cabe)
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87
                    ),
                  ),
                ),
              ),
              
              // 3. TÍTULO (Flexible para evitar overflow vertical)
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// WIDGET: TARJETA DE NAVEGACIÓN RÁPIDA
// -----------------------------------------------------------------------------
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: GRÁFICO DE TARTA (FL_CHART) - VERSIÓN CON DATOS REALES
// -----------------------------------------------------------------------------
class _DistributionChart extends StatefulWidget {
  // Aceptamos las estadísticas como argumento
  final DashboardStats stats;

  const _DistributionChart({required this.stats});

  @override
  State<_DistributionChart> createState() => _DistributionChartState();
}

class _DistributionChartState extends State<_DistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Si no hay productos, mostramos un aviso en lugar del gráfico
    if (widget.stats.activeProducts == 0) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "No hay datos suficientes para el gráfico",
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    // Llamamos a la función que calcula los datos reales
                    sections: showingSections(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Leyenda con números reales
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Indicator(
                    color: Colors.blue,
                    text: 'Tapas (${widget.stats.countTapas})',
                  ),
                  const SizedBox(height: 8),
                  _Indicator(
                    color: Colors.orange,
                    text: 'Cócteles (${widget.stats.countDrinks})',
                  ),
                  const SizedBox(height: 8),
                  _Indicator(
                    color: Colors.green,
                    text: 'Tiendas (${widget.stats.countShopping})',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final total = widget.stats.activeProducts.toDouble();
    if (total == 0) return []; // Protección contra división por cero

    // Calculamos porcentajes reales
    final pTapas = (widget.stats.countTapas / total) * 100;
    final pDrinks = (widget.stats.countDrinks / total) * 100;
    final pShop = (widget.stats.countShopping / total) * 100;

    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 55.0 : 45.0;

      switch (i) {
        case 0: // TAPAS
          return PieChartSectionData(
            color: Colors.blue,
            value: pTapas,
            title: pTapas > 5 ? '${pTapas.toStringAsFixed(0)}%' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 1: // CÓCTELES
          return PieChartSectionData(
            color: Colors.orange,
            value: pDrinks,
            title: pDrinks > 5 ? '${pDrinks.toStringAsFixed(0)}%' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 2: // TIENDAS
          return PieChartSectionData(
            color: Colors.green,
            value: pShop,
            title: pShop > 5 ? '${pShop.toStringAsFixed(0)}%' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        default:
          throw Error();
      }
    });
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

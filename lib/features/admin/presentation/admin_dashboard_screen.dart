import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:torre_del_mar_app/core/widgets/error_view.dart';
// import 'package:torre_del_mar_app/core/widgets/version_tag.dart'; // No hace falta aquí, irá en el Shell
import 'package:torre_del_mar_app/features/admin/data/dashboard_repository.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/event_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsListAsync = ref.watch(adminEventsListProvider);
    final selectedEvent = ref.watch(dashboardSelectedEventProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      // SIN DRAWER (Ya lo maneja tu AdminShellScreen)
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text("Panel de Control", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white,
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                iconTheme: const IconThemeData(color: Colors.black87),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref.invalidate(dashboardStatsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Actualizando..."), duration: Duration(milliseconds: 500)));
                    },
                  ),
                ],
                // 🔥 ARREGLO ERROR 5PX OVERFLOW: Aumentamos a 150
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(150),
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildEventSelector(context, ref, eventsListAsync, selectedEvent),
                      ),
                      Container(
                        color: Colors.white,
                        child: const TabBar(
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: [
                            Tab(text: "Resumen", icon: Icon(Icons.dashboard_outlined)),
                            Tab(text: "Oferta", icon: Icon(Icons.pie_chart_outline)),
                            Tab(text: "Tecnología", icon: Icon(Icons.devices)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: ErrorView(error: err, onRetry: () => ref.invalidate(dashboardStatsProvider))),
            data: (stats) => TabBarView(
              children: [
                _SummaryTab(stats: stats, selectedEvent: selectedEvent),
                _ChartsTab(stats: stats),
                _DevicesTab(stats: stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventSelector(BuildContext context, WidgetRef ref, AsyncValue<List<EventModel>> eventsAsync, EventModel? selectedEvent) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: eventsAsync.when(
        loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const Text("Error"),
        data: (events) {
          EventModel? value = selectedEvent;
          if (value != null && !events.any((e) => e.id == value?.id)) value = null;
          return DropdownButtonHideUnderline(
            child: DropdownButton<EventModel>(
              isExpanded: true,
              hint: const Text("🌍 Todos los Eventos"),
              value: value,
              items: [
                const DropdownMenuItem(value: null, child: Text("🌍 Global (Todos)")),
                ...events.map((e) => DropdownMenuItem(value: e, child: Text(e.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) {
                ref.read(dashboardSelectedEventProvider.notifier).state = v;
                Future.delayed(const Duration(milliseconds: 100), () => ref.invalidate(dashboardStatsProvider));
              },
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// 📊 TAB 1: RESUMEN
// -----------------------------------------------------------
class _SummaryTab extends StatelessWidget {
  final DashboardStats stats;
  final EventModel? selectedEvent;
  const _SummaryTab({required this.stats, this.selectedEvent});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false, bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (selectedEvent != null) ...[_EventStatusBanner(event: selectedEvent!), const SizedBox(height: 16)],
          const Text("Métricas Clave", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            double ratio = constraints.maxWidth > 600 ? 1.5 : 1.3; 
            return GridView.count(
              crossAxisCount: crossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: ratio,
              children: [
                _StatCard(title: 'Escaneos', value: stats.totalScans.toString(), icon: Icons.qr_code, color: Colors.indigo),
                _StatCard(title: 'Usuarios', value: stats.totalUsers.toString(), icon: Icons.people, color: Colors.blue),
                _StatCard(title: 'Productos', value: stats.activeProducts.toString(), icon: Icons.restaurant, color: Colors.orange),
                _StatCard(title: 'Socios', value: stats.activeEstablishments.toString(), icon: Icons.store, color: Colors.teal),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// 🥧 TAB 2: GRÁFICAS (DONUT CENTRADO)
// -----------------------------------------------------------
class _ChartsTab extends StatefulWidget {
  final DashboardStats stats;
  const _ChartsTab({required this.stats});
  @override
  State<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<_ChartsTab> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.stats.activeProducts == 0) return const Center(child: Text("Sin datos suficientes"));

    final tapas = widget.stats.countProducts;
    final drinks = widget.stats.countDrinks;
    final shop = widget.stats.countShopping;
    final total = tapas + drinks + shop;

    final isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000), 
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(
                  children: [
                    const Text("Oferta Gastronómica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),

                    Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.center, 
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 250, 
                          // 🔥 AJUSTE ANCHO PARA EVITAR OVERFLOW EN MÓVIL
                          width: isMobile ? MediaQuery.of(context).size.width * 0.6 : 250,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(touchCallback: (e, r) {
                                setState(() {
                                  if (r != null && r.touchedSection != null) {
                                    touchedIndex = r.touchedSection!.touchedSectionIndex;
                                  } else {
                                    touchedIndex = -1;
                                  }
                                });
                              }),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2, centerSpaceRadius: 40,
                              sections: [
                                _buildSection(0, tapas, total, Colors.orange, Icons.restaurant),
                                _buildSection(1, drinks, total, Colors.purple, Icons.local_bar),
                                _buildSection(2, shop, total, Colors.teal, Icons.shopping_bag),
                              ],
                            ),
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 60) else const SizedBox(height: 30),
                        Column(
                          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                          children: _buildLegendItems(tapas, drinks, shop, total),
                        )
                      ],
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

  List<Widget> _buildLegendItems(int tapas, int drinks, int shop, int total) {
      return [
        _LegendIndicator(color: Colors.orange, text: "Tapas", value: tapas, total: total, isTouched: touchedIndex == 0),
        const SizedBox(height: 10),
        _LegendIndicator(color: Colors.purple, text: "Bebidas", value: drinks, total: total, isTouched: touchedIndex == 1),
        const SizedBox(height: 10),
        _LegendIndicator(color: Colors.teal, text: "Tienda", value: shop, total: total, isTouched: touchedIndex == 2),
      ];
    }
  PieChartSectionData _buildSection(int index, int value, int total, Color color, IconData icon) {
      final isTouched = index == touchedIndex;
      final double radius = isTouched ? 100 : 80;
      final double fontSize = isTouched ? 20 : 14;
      return PieChartSectionData(
        color: color, value: value.toDouble(), title: total > 0 ? '${(value/total*100).toStringAsFixed(0)}%' : '0%',
        radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: _Badge(icon, size: isTouched ? 40 : 30, borderColor: color), badgePositionPercentageOffset: .98,
      );
    }
}

// -----------------------------------------------------------
// 📱 TAB 3: DISPOSITIVOS
// -----------------------------------------------------------
class _DevicesTab extends StatelessWidget {
  final DashboardStats stats;
  const _DevicesTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.deviceAndroid + stats.deviceIOS + stats.deviceWeb;
    if (total == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phonelink_off, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("No se han registrado dispositivos aún.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tecnología de Usuarios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _DeviceBar(label: "Android", count: stats.deviceAndroid, total: total, color: Colors.green, icon: Icons.android),
              const SizedBox(height: 16),
              _DeviceBar(label: "iOS (iPhone)", count: stats.deviceIOS, total: total, color: Colors.black, icon: Icons.apple),
              const SizedBox(height: 16),
              _DeviceBar(label: "Web / Escritorio", count: stats.deviceWeb, total: total, color: Colors.blue, icon: Icons.web),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceBar extends StatelessWidget {
  final String label; final int count; final int total; final Color color; final IconData icon;
  const _DeviceBar({required this.label, required this.count, required this.total, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final double percentage = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),
            Text("$count (${(percentage * 100).toStringAsFixed(1)}%)", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage, minHeight: 10, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  @override 
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))]),
      child: Stack(
        children: [
          Positioned(right: -10, top: -10, child: Icon(icon, size: 60, color: Colors.white.withOpacity(0.2))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: Colors.white, size: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))), Text(title, style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)])])
        ],
      )
    );
  }
}
class _Badge extends StatelessWidget {
  final IconData icon; final double size; final Color borderColor;
  const _Badge(this.icon, {required this.size, required this.borderColor});
  @override Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderColor)), child: Icon(icon, size: size * 0.6, color: borderColor));
}
class _LegendIndicator extends StatelessWidget {
  final Color color; final String text; final int value; final int total; final bool isTouched;
  const _LegendIndicator({required this.color, required this.text, required this.value, required this.total, required this.isTouched});
  @override Widget build(BuildContext context) => Row(children: [Container(width: 12, height: 12, color: color), const SizedBox(width: 8), Text("$text: $value")]);
}
class _EventStatusBanner extends StatelessWidget {
  final EventModel event; const _EventStatusBanner({required this.event});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(8), color: Colors.blue[50], child: Text(event.status));
}
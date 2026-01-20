import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/ranking_provider.dart';
import 'package:torre_del_mar_app/features/home/presentation/widgets/establishment_card.dart';

class EstablishmentsListScreen extends ConsumerStatefulWidget {
  final int eventId;
  const EstablishmentsListScreen({super.key, required this.eventId});

  @override
  ConsumerState<EstablishmentsListScreen> createState() => _EstablishmentsListScreenState();
}

class _EstablishmentsListScreenState extends ConsumerState<EstablishmentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. OBTENER DATOS
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    final rankingAsync = ref.watch(rankingListProvider);
    
    // 2. OBTENER COLOR DEL EVENTO (Para la ruedecita de carga)
    final eventAsync = ref.watch(currentEventProvider);
    Color themeColor = Colors.orange; // Color por defecto
    if (eventAsync.hasValue && eventAsync.value != null) {
      try {
        String hex = eventAsync.value!.themeColorHex.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        themeColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // 1. ENVOLVEMOS CON REFRESH INDICATOR
      body: RefreshIndicator(
        color: themeColor,
        backgroundColor: Colors.white,
        onRefresh: () async {
          // Invocamos la recarga de los proveedores
          ref.invalidate(establishmentsListProvider);
          ref.invalidate(rankingListProvider);
          // Esperamos un segundo para efecto visual
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          // 2. SIEMPRE SCROLLABLE (para que funcione el gesto)
          physics: const AlwaysScrollableScrollPhysics(),
          
          slivers: [
            // A. BARRA DE BÚSQUEDA FLOTANTE
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar bar o tapa...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // C. LISTA DE ESTABLECIMIENTOS (FILTRADA)
            establishmentsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error cargando locales: $err'),
                ),
              ),
              data: (list) {
                // Lógica de filtrado
                final filtered = list.where((est) {
                  final q = _searchQuery.toLowerCase();
                  final matchName = est.name.toLowerCase().contains(q);
                  final matchProduct = est.products?.any((p) => p.name.toLowerCase().contains(q)) ?? false;
                  return matchName || matchProduct;
                }).toList();

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    // Importante: Si está vacío, permitimos scroll para poder refrescar
                    hasScrollBody: false, 
                    child: Center(child: Text("No se encontraron resultados")),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final est = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: EstablishmentCard(establishment: est),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }
}
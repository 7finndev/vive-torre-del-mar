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
    // 1. OBTENER DATOS (Ahora sí, porque el usuario YA ha entrado al evento)
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    
    // 2. OBTENER RANKING (Solo para este evento)
    final rankingAsync = ref.watch(rankingListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
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
              // Lógica de filtrado por buscador
              final filtered = list.where((est) {
                final q = _searchQuery.toLowerCase();
                final matchName = est.name.toLowerCase().contains(q);
                // También buscamos por nombre de tapa si quieres
                final matchProduct = est.products?.any((p) => p.name.toLowerCase().contains(q)) ?? false;
                return matchName || matchProduct;
              }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
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
          
          // Espacio extra al final para que no lo tape el botón flotante si lo hubiera
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}
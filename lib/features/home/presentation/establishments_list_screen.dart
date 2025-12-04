import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
// IMPORTANTE: Importamos la tarjeta nueva
import 'package:torre_del_mar_app/features/home/presentation/widgets/establishment_card.dart'; 

class EstablishmentsListScreen extends ConsumerWidget {
  const EstablishmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final establishmentsAsync = ref.watch(establishmentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Locales Participantes"),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50], 
      body: establishmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (establishments) {
          if (establishments.isEmpty) {
            return const Center(child: Text("No hay locales activos para este evento."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: establishments.length,
            itemBuilder: (context, index) {
              final bar = establishments[index];
              // AQUÍ USAMOS LA TARJETA NUEVA
              return EstablishmentCard(establishment: bar);
            },
          );
        },
      ),
    );
  }
}
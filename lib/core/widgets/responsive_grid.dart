import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double itemWidth; // Ancho deseado de cada tarjeta en PC

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.itemWidth = 350, // Un tamaño bueno para tarjetas de eventos
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder nos dice cuánto espacio tenemos disponible
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho es pequeño (móvil), usamos lista normal
        if (constraints.maxWidth < 600) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: children.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: c,
            )).toList(),
          );
        }

        // Si es ancho (PC/Tablet), usamos Wrap o GridView. 
        // Wrap es más flexible para contenidos variados.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Wrap(
              spacing: 24, // Espacio horizontal entre tarjetas
              runSpacing: 24, // Espacio vertical entre tarjetas
              alignment: WrapAlignment.start,
              children: children.map((child) {
                return SizedBox(
                  width: itemWidth, 
                  child: child,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
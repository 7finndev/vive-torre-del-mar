import 'package:flutter/material.dart';

class StarRatingSelector extends StatefulWidget {
  final Function(int) onRatingChanged;

  const StarRatingSelector({super.key, required this.onRatingChanged});

  @override
  State<StarRatingSelector> createState() => _StarRatingSelectorState();
}

class _StarRatingSelectorState extends State<StarRatingSelector> {
  int _currentRating = 0;

  @override
  Widget build(BuildContext context) {
    // Usamos Wrap para que si no caben, bajen de línea sin dar error
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4.0, // Espacio horizontal entre estrellas
      runSpacing: 4.0, // Espacio vertical si saltan de línea
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = index + 1;
            });
            widget.onRatingChanged(_currentRating);
          },
          // Construimos el icono manualmente sin el padding gigante de IconButton
          child: Icon(
            index < _currentRating
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.orange,
            size: 36, // Tamaño generoso pero controlado
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';

/// Muestra estrellas (con media estrella). Si se pasa [onChanged] el usuario puede tocar para votar.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 20,
  });

  final double rating;
  final ValueChanged<int>? onChanged;
  final double size;

  IconData _iconFor(int index) {
    if (rating >= index + 1) return Icons.star;
    if (rating >= index + 0.5) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = Icon(_iconFor(i), size: size, color: Colors.amber.shade700);
        if (onChanged == null) return icon;
        return InkResponse(
          onTap: () => onChanged!(i + 1),
          radius: size,
          child: Padding(padding: const EdgeInsets.all(2), child: icon),
        );
      }),
    );
  }
}

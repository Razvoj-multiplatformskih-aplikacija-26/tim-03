import 'package:flutter/material.dart';

/// The center's mark: a paw in a circle, drawn from the Material icon font, so the package needs no image asset.
class SapaMark extends StatelessWidget {
  const SapaMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Šapa',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(Icons.pets, size: size * 0.55, color: scheme.primary),
      ),
    );
  }
}

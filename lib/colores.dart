import 'package:flutter/material.dart';
import 'tablero.dart';

Color colorDeRegion(ColorRegion c) {
  switch (c) {
    case ColorRegion.amarillo:
      return Colors.yellow.shade600;
    case ColorRegion.verde:
      return Colors.green.shade400;
    case ColorRegion.morado:
      return Colors.purple.shade300;
    case ColorRegion.azul:
      return Colors.lightBlue.shade400;
    case ColorRegion.rojo:
      return Colors.red.shade300;
  }
}

String nombreReglaDeColor(ColorRegion c) {
  switch (c) {
    case ColorRegion.amarillo:
    case ColorRegion.rojo:
      return 'Todos diferentes';
    case ColorRegion.verde:
      return 'Cualquiera';
    case ColorRegion.azul:
      return 'Todos iguales';
    case ColorRegion.morado:
      return 'Máximo 2 valores distintos';
  }
}

/// Fila de chips mostrando cada color del tablero y su regla, para
/// que el jugador no tenga que memorizarlas.
class LeyendaColores extends StatelessWidget {
  const LeyendaColores({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: ColorRegion.values.map((color) {
        return Chip(
          avatar: CircleAvatar(backgroundColor: colorDeRegion(color)),
          label: Text(
            nombreReglaDeColor(color),
            style: const TextStyle(fontSize: 11),
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
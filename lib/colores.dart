import 'package:flutter/material.dart';
import 'tablero.dart';

/// Paleta más saturada que la original (antes usaba shade300/400,
/// que se veían muy parecidos entre sí, sobre todo morado/azul/rojo).
Color colorDeRegion(ColorRegion c) {
  switch (c) {
    case ColorRegion.amarillo:
      return const Color(0xFFFFC107);
    case ColorRegion.verde:
      return const Color(0xFF43A047);
    case ColorRegion.morado:
      return const Color(0xFFAB47BC);
    case ColorRegion.azul:
      return const Color(0xFF1E88E5);
    case ColorRegion.rojo:
      return const Color(0xFFE53935);
    case ColorRegion.gris:
      return const Color(0xFFBDBDBD);
    case ColorRegion.naranjaAlto:
    case ColorRegion.naranjaBajo:
      return const Color(0xFFFB8C00);
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
    case ColorRegion.gris:
      return 'Todos iguales';
    case ColorRegion.morado:
      return 'Máximo 2 valores distintos';
    case ColorRegion.naranjaAlto:
      return 'Solo del 4 al 6';
    case ColorRegion.naranjaBajo:
      return 'Solo del 1 al 3';
  }
}

/// Un símbolo corto por regla, para no depender solo del color
/// (ayuda también a quien tiene dificultad para distinguir colores).
String simboloDeRegion(ColorRegion c) {
  switch (c) {
    case ColorRegion.amarillo:
    case ColorRegion.rojo:
      return '≠';
    case ColorRegion.verde:
      return '✓';
    case ColorRegion.azul:
    case ColorRegion.gris:
      return '=';
    case ColorRegion.morado:
      return '2';
    case ColorRegion.naranjaAlto:
      return '4-6';
    case ColorRegion.naranjaBajo:
      return '1-3';
  }
}

/// Texto legible sobre cada color (blanco u oscuro según el fondo),
/// para que el número/símbolo siempre se lea bien.
Color colorTextoSobre(ColorRegion c) {
  switch (c) {
    case ColorRegion.amarillo:
    case ColorRegion.gris:
      return Colors.black87;
    default:
      return Colors.white;
  }
}

/// Fila de chips mostrando cada color del tablero, su símbolo y su
/// regla, para que el jugador no tenga que memorizarlas.
class LeyendaColores extends StatelessWidget {
  /// Colores a mostrar (los que tiene el nivel actual). Si es null se
  /// muestran todos.
  final Set<ColorRegion>? colores;

  const LeyendaColores({super.key, this.colores});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: ColorRegion.values
          .where((c) => colores == null || colores!.contains(c))
          .map((color) {
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: colorDeRegion(color),
            child: Text(
              simboloDeRegion(color),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: colorTextoSobre(color),
              ),
            ),
          ),
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
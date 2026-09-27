import 'dart:math';

enum ColorRegion {
  amarillo,
  verde,
  morado,
  azul,
  rojo,
}

/// Posición vertical de una zona dentro del tablero.
enum Vertical { arriba, centro, abajo }

/// Posición horizontal de una zona dentro del tablero.
enum Horizontal { izquierda, centro, derecha }

/// Casilla del tablero. [zonaId] identifica la zona específica
/// (no el color) — dos zonas del mismo color tendrán ids distintos.
class Celda {
  final int fila;
  final int columna;
  final int zonaId;
  final int? valor;

  const Celda({
    required this.fila,
    required this.columna,
    required this.zonaId,
    this.valor,
  });
}

/// A partir de una cuadrícula de colores (fila por fila), agrupa las
/// celdas conectadas (horizontal/vertical, sin diagonales) del mismo
/// color en zonas independientes y devuelve la lista de celdas del
/// tablero (todas sin número todavía) junto con el color de cada zona.
class TableroGenerado {
  final List<Celda> celdas;
  final Map<int, ColorRegion> colorPorZona;

  TableroGenerado(this.celdas, this.colorPorZona);
}

TableroGenerado construirTableroDesdeColores(List<List<ColorRegion>> grid) {
  final filas = grid.length;
  final columnas = grid[0].length;
  final idZona = List.generate(filas, (_) => List<int?>.filled(columnas, null));
  final colorPorZona = <int, ColorRegion>{};
  final celdas = <Celda>[];
  int siguienteId = 0;

  for (int f = 0; f < filas; f++) {
    for (int c = 0; c < columnas; c++) {
      if (idZona[f][c] != null) continue;

      final color = grid[f][c];
      final zonaActual = siguienteId++;
      final pila = <Point<int>>[Point(f, c)];
      idZona[f][c] = zonaActual;

      while (pila.isNotEmpty) {
        final p = pila.removeLast();
        for (final d in [
          [-1, 0], [1, 0], [0, -1], [0, 1],
        ]) {
          final nf = p.x + d[0];
          final nc = p.y + d[1];
          if (nf >= 0 && nf < filas && nc >= 0 && nc < columnas &&
              idZona[nf][nc] == null && grid[nf][nc] == color) {
            idZona[nf][nc] = zonaActual;
            pila.add(Point(nf, nc));
          }
        }
      }

      colorPorZona[zonaActual] = color;
    }
  }

  for (int f = 0; f < filas; f++) {
    for (int c = 0; c < columnas; c++) {
      celdas.add(Celda(fila: f, columna: c, zonaId: idZona[f][c]!));
    }
  }

  return TableroGenerado(celdas, colorPorZona);
}

/// Extrae los valores presentes en UNA zona específica (por zonaId),
/// sin importar si está vacía, incompleta o completa.
List<int> extraerValoresDeZona(List<Celda> celdas, int zonaId) {
  return celdas
      .where((c) => c.zonaId == zonaId && c.valor != null)
      .map((c) => c.valor!)
      .toList();
}

/// Calcula el centro (fila y columna promedio) de una zona.
Point<double> _centroide(List<Celda> celdasZona) {
  final sumaFila = celdasZona.fold<int>(0, (s, c) => s + c.fila);
  final sumaColumna = celdasZona.fold<int>(0, (s, c) => s + c.columna);
  return Point(sumaFila / celdasZona.length, sumaColumna / celdasZona.length);
}

Vertical _clasificarVertical(double filaProm, int filas) {
  if (filaProm < filas / 3) return Vertical.arriba;
  if (filaProm > filas * 2 / 3) return Vertical.abajo;
  return Vertical.centro;
}

Horizontal _clasificarHorizontal(double columnaProm, int columnas) {
  if (columnaProm < columnas / 3) return Horizontal.izquierda;
  if (columnaProm > columnas * 2 / 3) return Horizontal.derecha;
  return Horizontal.centro;
}

/// Extrae los valores de las celdas del color [region] que además caigan
/// en la posición pedida. Deja [vertical] u [horizontal] en null para no
/// filtrar por ese eje (ej. dejar ambos en null = "todos los <color>").
List<int> valoresPorColorYPosicion(
  List<Celda> celdas,
  Map<int, ColorRegion> colorPorZona,
  int filas,
  int columnas,
  ColorRegion region, {
  Vertical? vertical,
  Horizontal? horizontal,
}) {
  final porZona = <int, List<Celda>>{};
  for (final c in celdas) {
    porZona.putIfAbsent(c.zonaId, () => []).add(c);
  }

  final resultado = <int>[];

  for (final entrada in porZona.entries) {
    final zonaId = entrada.key;
    final celdasZona = entrada.value;
    if (colorPorZona[zonaId] != region) continue;

    if (vertical != null || horizontal != null) {
      final centro = _centroide(celdasZona);
      if (vertical != null &&
          _clasificarVertical(centro.x, filas) != vertical) continue;
      if (horizontal != null &&
          _clasificarHorizontal(centro.y, columnas) != horizontal) continue;
    }

    resultado.addAll(
      celdasZona.where((c) => c.valor != null).map((c) => c.valor!),
    );
  }

  return resultado;
}

/// El tablero real "Level 1" de Brilliant (leído de la foto oficial).
final tableroNivel1 = [
  [ColorRegion.amarillo, ColorRegion.verde, ColorRegion.azul, ColorRegion.morado, ColorRegion.morado, ColorRegion.morado, ColorRegion.amarillo],
  [ColorRegion.verde, ColorRegion.verde, ColorRegion.azul, ColorRegion.azul, ColorRegion.morado, ColorRegion.morado, ColorRegion.verde],
  [ColorRegion.verde, ColorRegion.rojo, ColorRegion.rojo, ColorRegion.azul, ColorRegion.morado, ColorRegion.verde, ColorRegion.verde],
  [ColorRegion.verde, ColorRegion.rojo, ColorRegion.morado, ColorRegion.amarillo, ColorRegion.verde, ColorRegion.verde, ColorRegion.verde],
  [ColorRegion.verde, ColorRegion.rojo, ColorRegion.morado, ColorRegion.morado, ColorRegion.rojo, ColorRegion.rojo, ColorRegion.azul],
  [ColorRegion.rojo, ColorRegion.rojo, ColorRegion.morado, ColorRegion.rojo, ColorRegion.rojo, ColorRegion.azul, ColorRegion.azul],
  [ColorRegion.amarillo, ColorRegion.morado, ColorRegion.morado, ColorRegion.rojo, ColorRegion.rojo, ColorRegion.azul, ColorRegion.amarillo],
];

/// Las 6 casillas marcadas con estrella en el tablero real: ahí van
/// los valores iniciales (1 al 6, cada uno una sola vez) antes de jugar.
final estrellasNivel1 = <Point<int>>{
  const Point(0, 2), // azul
  const Point(1, 5), // morado
  const Point(3, 1), // rojo
  const Point(3, 4), // verde
  const Point(5, 2), // morado
  const Point(6, 4), // rojo
};
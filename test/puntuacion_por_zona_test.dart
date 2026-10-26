import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/tablero.dart';
import 'package:brillant_app/juego.dart';

void main() {
  // amarillo - verde - amarillo: los dos amarillos están separados.
  final grid = <List<ColorRegion>>[
    [ColorRegion.amarillo, ColorRegion.verde, ColorRegion.amarillo],
  ];

  group('Colores agrupados (el amarillo es una sola zona)', () {
    test('sin agrupar, cada amarillo es su propia zona', () {
      final t = TableroJuego.desdeColores(grid);
      expect(t.celdaEn(0, 0).zonaId, isNot(t.celdaEn(0, 2).zonaId));
    });

    test('agrupado, los dos amarillos comparten zona', () {
      final t = TableroJuego.desdeColores(
        grid,
        coloresAgrupados: {ColorRegion.amarillo},
      );
      expect(t.celdaEn(0, 0).zonaId, t.celdaEn(0, 2).zonaId);
      expect(
        t.colorPorZona.values.where((c) => c == ColorRegion.amarillo).length,
        1,
      );
    });

    test('"todos diferentes" vale entre amarillos separados', () {
      final t = TableroJuego.desdeColores(
        grid,
        coloresAgrupados: {ColorRegion.amarillo},
      )
        ..colocar(0, 1, 2)
        ..colocar(0, 0, 3);

      // El otro amarillo no puede repetir el 3, aunque no se toquen.
      expect(t.puedeColocar(0, 2, 3), isFalse);
      expect(t.puedeColocar(0, 2, 4), isTrue);
    });

    test('sin agrupar, el mismo 3 sí se permite en el otro amarillo', () {
      final t = TableroJuego.desdeColores(grid)
        ..colocar(0, 1, 2)
        ..colocar(0, 0, 3);
      expect(t.puedeColocar(0, 2, 3), isTrue);
    });

    test('solo puntúa cuando se completan TODOS los amarillos', () {
      final t = TableroJuego.desdeColores(
        grid,
        coloresAgrupados: {ColorRegion.amarillo},
        puntosPorColor: {
          ColorRegion.amarillo: [8, 6, 4],
          ColorRegion.verde: [4, 3, 2],
        },
      );

      t.colocar(0, 1, 2); // completa la zona verde
      expect(t.comprobarPuntuacion(), 4);

      t.colocar(0, 0, 3); // falta un amarillo
      expect(t.comprobarPuntuacion(), 0);

      t.colocar(0, 2, 4); // ya están todos los amarillos
      expect(t.comprobarPuntuacion(), 8);
      expect(t.puntuacionTotal, 12);
    });
  });

  group('Puntos según el lugar en que se completa la zona', () {
    final azul = <List<ColorRegion>>[
      [ColorRegion.azul],
    ];
    final puntos = {
      ColorRegion.azul: [7, 5, 3],
    };

    int puntosEn(int puesto) {
      final t = TableroJuego.desdeColores(azul, puntosPorColor: puntos)
        ..colocar(0, 0, 3);
      return t.comprobarPuntuacion(puesto: puesto);
    }

    test('1.er lugar da el primer número de la leyenda', () {
      expect(puntosEn(1), 7);
    });

    test('2.º y 3.er lugar dan el segundo y el tercero', () {
      expect(puntosEn(2), 5);
      expect(puntosEn(3), 3);
    });

    test('del 4.º lugar en adelante no da puntos', () {
      expect(puntosEn(4), 0);
      expect(puntosEn(5), 0);
    });

    test('por defecto se cuenta como 1.er lugar', () {
      final t = TableroJuego.desdeColores(azul, puntosPorColor: puntos)
        ..colocar(0, 0, 3);
      expect(t.comprobarPuntuacion(), 7);
    });

    test('una zona ya puntuada no vuelve a dar puntos', () {
      final t = TableroJuego.desdeColores(azul, puntosPorColor: puntos)
        ..colocar(0, 0, 3);
      expect(t.comprobarPuntuacion(), 7);
      expect(t.comprobarPuntuacion(), 0);
      expect(t.puntuacionTotal, 7);
    });

    test('cada zona usa los puntos de su propio color', () {
      final t = TableroJuego.desdeColores(
        [
          [ColorRegion.azul, ColorRegion.rojo],
        ],
        puntosPorColor: {
          ColorRegion.azul: [7, 5, 3],
          ColorRegion.rojo: [6, 4, 2],
        },
      )
        ..colocar(0, 0, 3)
        ..colocar(0, 1, 4);
      expect(t.comprobarPuntuacion(), 13);
    });
  });

  group('Sin tabla de puntos (comportamiento anterior)', () {
    test('una zona vale tantos puntos como celdas tiene', () {
      final t = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.verde],
      ])
        ..colocar(0, 0, 3)
        ..colocar(0, 1, 5);
      expect(t.comprobarPuntuacion(), 2);
    });
  });
}
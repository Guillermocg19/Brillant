import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/tablero.dart';
import 'package:brillant_app/juego.dart';

void main() {
  group('comprobarPuntuacion', () {
    test('una zona incompleta no da puntos', () {
      // Una zona verde de 2 celdas, solo se llena 1.
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.verde],
      ]);
      juego.colocar(0, 0, 3);

      expect(juego.comprobarPuntuacion(), 0);
      expect(juego.puntuacionTotal, 0);
    });

    test('completar una zona da tantos puntos como celdas tiene', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.verde],
      ]);
      juego.colocar(0, 0, 3);
      juego.colocar(0, 1, 5);

      expect(juego.comprobarPuntuacion(), 2);
      expect(juego.puntuacionTotal, 2);
    });

    test('una zona no suma sus puntos dos veces', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.verde],
      ]);
      juego.colocar(0, 0, 3);
      juego.colocar(0, 1, 5);

      juego.comprobarPuntuacion();
      expect(juego.comprobarPuntuacion(), 0); // ya estaba contada
      expect(juego.puntuacionTotal, 2);
    });

    test('varias zonas completadas se acumulan en el total', () {
      // Dos zonas distintas de 1 celda cada una (colores diferentes).
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.rojo],
      ]);

      juego.colocar(0, 0, 4);
      expect(juego.comprobarPuntuacion(), 1);

      juego.colocar(0, 1, 2); // adyacente a (0,0)
      expect(juego.comprobarPuntuacion(), 1);

      expect(juego.puntuacionTotal, 2);
    });

    test('completar dos zonas en la misma jugada suma ambas', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.rojo],
      ]);
      // Se llenan sin revisar puntos en medio.
      juego.colocar(0, 0, 4);
      juego.colocar(0, 1, 2);

      expect(juego.comprobarPuntuacion(), 2);
    });
  });

  group('puntos con valores iniciales', () {
    test('si los valores iniciales completan una zona, ya cuentan', () {
      final juego = TableroJuego.iniciar(
        [
          [ColorRegion.verde, ColorRegion.rojo],
        ],
        {
          const Point(0, 0): 1,
          const Point(0, 1): 2,
        },
      );

      expect(juego.puntuacionTotal, 2);
    });

    test('valores iniciales que no completan nada dejan el marcador en 0', () {
      final juego = TableroJuego.iniciar(
        [
          [ColorRegion.verde, ColorRegion.verde, ColorRegion.rojo],
        ],
        {const Point(0, 0): 1},
      );

      expect(juego.puntuacionTotal, 0);
    });
  });
}
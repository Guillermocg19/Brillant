import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/tablero.dart';
import 'package:brillant_app/juego.dart';
import 'package:brillant_app/niveles.dart';

void main() {
  group('Todos los niveles', () {
    for (final nivel in niveles) {
      group('Nivel ${nivel.numero}', () {
        test('es de 7x7', () {
          expect(nivel.tablero.length, 7);
          for (final fila in nivel.tablero) {
            expect(fila.length, 7);
          }
        });

        test('tiene 6 estrellas dentro del tablero', () {
          expect(nivel.estrellas.length, 6);
          for (final e in nivel.estrellas) {
            expect(e.x, inInclusiveRange(0, 6));
            expect(e.y, inInclusiveRange(0, 6));
          }
        });

        test('cada estrella cae en una zona distinta', () {
          final juego = nivel.crearJuego();
          final zonas = nivel.estrellas
              .map((e) => juego.celdaEn(e.x, e.y).zonaId)
              .toSet();
          expect(zonas.length, 6);
        });

        test('se puede terminar: ninguna zona de "todos diferentes" pasa de 6',
            () {
          final juego = nivel.crearJuego();
          final tamano = <int, int>{};
          for (final c in juego.celdas) {
            tamano[c.zonaId] = (tamano[c.zonaId] ?? 0) + 1;
          }
          juego.colorPorZona.forEach((zonaId, color) {
            if (color == ColorRegion.rojo || color == ColorRegion.amarillo) {
              expect(tamano[zonaId], lessThanOrEqualTo(6),
                  reason: 'Zona $zonaId ($color) mide ${tamano[zonaId]}');
            }
          });
        });

        test('al empezar hay jugadas posibles', () {
          final juego = nivel.crearJuego();
          expect(juego.hayAlgunaJugadaPosible, isTrue);
        });
      });
    }
  });

  group('Valores iniciales válidos', () {
    test('Nivel 2: acepta 1 a 6 en el orden de las estrellas', () {
      final valores = <Point<int>, int>{};
      var n = 1;
      for (final e in estrellasNivel2) {
        valores[e] = n++;
      }
      final juego = niveles[1].crearJuego(valores);
      expect(juego.tableroVacio, isFalse);
    });

    test('Nivel 3: acepta 1 a 6 en el orden de las estrellas', () {
      final valores = <Point<int>, int>{};
      var n = 1;
      for (final e in estrellasNivel3) {
        valores[e] = n++;
      }
      final juego = niveles[2].crearJuego(valores);
      expect(juego.tableroVacio, isFalse);
    });

    test('Nivel 4: 4-6 arriba y 1-3 abajo, el resto libre', () {
      final juego = niveles[3].crearJuego({
        const Point(0, 4): 6, // naranja 4-6
        const Point(6, 1): 3, // naranja 1-3
        const Point(2, 2): 1,
        const Point(2, 5): 2,
        const Point(3, 0): 4,
        const Point(5, 4): 5,
      });
      expect(juego.celdaEn(0, 4).valor, 6);
      expect(juego.celdaEn(6, 1).valor, 3);
    });

    test('Nivel 4: un 2 en la estrella naranja 4-6 se rechaza', () {
      expect(
        () => niveles[3].crearJuego({
          const Point(0, 4): 2, // fuera del rango 4-6
          const Point(6, 1): 3,
          const Point(2, 2): 1,
          const Point(2, 5): 6,
          const Point(3, 0): 4,
          const Point(5, 4): 5,
        }),
        throwsA(anything),
      );
    });
  });

  group('Detalles de cada mapa', () {
    int zonasDeColor(List<List<ColorRegion>> tablero, ColorRegion color) {
      final juego = TableroJuego.desdeColores(tablero);
      return juego.colorPorZona.values.where((c) => c == color).length;
    }

    test('Nivel 2: dos casillas grises sueltas', () {
      expect(zonasDeColor(tableroNivel2, ColorRegion.gris), 2);
    });

    test('Nivel 3: cinco casillas grises sueltas', () {
      expect(zonasDeColor(tableroNivel3, ColorRegion.gris), 5);
    });

    test('Nivel 4: una fila naranja 4-6 arriba y otra 1-3 abajo', () {
      expect(tableroNivel4.first.every((c) => c == ColorRegion.naranjaAlto),
          isTrue);
      expect(tableroNivel4.last.every((c) => c == ColorRegion.naranjaBajo),
          isTrue);
      expect(zonasDeColor(tableroNivel4, ColorRegion.naranjaAlto), 1);
      expect(zonasDeColor(tableroNivel4, ColorRegion.naranjaBajo), 1);
    });
  });

  group('Puntos y zonas de cada nivel', () {
    test('cada nivel tiene puntos para todos los colores de su tablero', () {
      for (final nivel in niveles) {
        final colores = nivel.tablero.expand((f) => f).toSet();
        for (final color in colores) {
          expect(nivel.puntos[color], isNotNull,
              reason: 'Nivel ${nivel.numero} sin puntos para $color');
          expect(nivel.puntos[color]!.length, 3);
        }
      }
    });

    test('los puntos coinciden con la leyenda del tablero físico', () {
      expect(niveles[0].puntos[ColorRegion.amarillo], [8, 6, 4]);
      expect(niveles[1].puntos[ColorRegion.gris], [3, 2, 1]);
      expect(niveles[2].puntos[ColorRegion.verde], [6, 5, 4]);
      expect(niveles[3].puntos[ColorRegion.naranjaAlto], [6, 4, 3]);
      expect(niveles[3].puntos[ColorRegion.naranjaBajo], [6, 4, 3]);
    });

    test('todos los amarillos de cada nivel son una sola zona', () {
      for (final nivel in niveles) {
        final juego = nivel.crearJuego();
        final amarillas = juego.colorPorZona.values
            .where((c) => c == ColorRegion.amarillo)
            .length;
        expect(amarillas, 1, reason: 'Nivel ${nivel.numero}');
      }
    });
  });
}
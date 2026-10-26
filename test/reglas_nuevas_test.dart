import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/reglas.dart';
import 'package:brillant_app/juego.dart';
import 'package:brillant_app/tablero.dart';

void main() {
  group('Naranja 4-6', () {
    test('acepta 4, 5 y 6', () {
      for (final n in [4, 5, 6]) {
        expect(cumpleNaranjaAlto([], n), isTrue);
      }
    });

    test('rechaza 1, 2 y 3', () {
      for (final n in [1, 2, 3]) {
        expect(cumpleNaranjaAlto([], n), isFalse);
      }
    });

    test('permite repetir números', () {
      expect(cumpleNaranjaAlto([4, 4, 5], 4), isTrue);
    });
  });

  group('Naranja 1-3', () {
    test('acepta 1, 2 y 3', () {
      for (final n in [1, 2, 3]) {
        expect(cumpleNaranjaBajo([], n), isTrue);
      }
    });

    test('rechaza 4, 5 y 6', () {
      for (final n in [4, 5, 6]) {
        expect(cumpleNaranjaBajo([], n), isFalse);
      }
    });

    test('permite repetir números', () {
      expect(cumpleNaranjaBajo([1, 2, 1], 1), isTrue);
    });
  });

  group('reglaParaColor con los colores nuevos', () {
    test('gris se comporta como azul (todos iguales)', () {
      final regla = reglaParaColor(ColorRegion.gris);
      expect(regla([], 5), isTrue);
      expect(regla([3], 3), isTrue);
      expect(regla([3], 4), isFalse);
    });

    test('naranjaAlto y naranjaBajo usan su rango', () {
      expect(reglaParaColor(ColorRegion.naranjaAlto)([], 5), isTrue);
      expect(reglaParaColor(ColorRegion.naranjaAlto)([], 2), isFalse);
      expect(reglaParaColor(ColorRegion.naranjaBajo)([], 2), isTrue);
      expect(reglaParaColor(ColorRegion.naranjaBajo)([], 5), isFalse);
    });
  });

  group('Regla del ancla con naranja', () {
    test('el número a colocar también debe caer en el rango', () {
      // Fila de arriba naranja 4-6, fila de abajo verde.
      final t = TableroJuego.desdeColores([
        [ColorRegion.naranjaAlto, ColorRegion.naranjaAlto],
        [ColorRegion.verde, ColorRegion.verde],
      ])
        ..colocar(1, 0, 3);

      // Ancla 3 está pegado a (0,0): el 5 cabe, el 2 no.
      expect(t.puedeColocarConAncla(0, 0, 5, 3), isTrue);
      expect(t.puedeColocarConAncla(0, 0, 2, 3), isFalse);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/juego.dart';
import 'package:brillant_app/reglas.dart';
import 'package:brillant_app/tablero.dart';

void main() {
  group('reglas por color: casos límite', () {
    test('rojo y amarillo no permiten repetir valores', () {
      expect(cumpleTodosDiferentes([1, 3, 5], 3), isFalse);
      expect(cumpleTodosDiferentes([1, 3, 5], 2), isTrue);
    });

    test('azul acepta el mismo valor y rechaza uno diferente', () {
      expect(cumpleAzul([4, 4], 4), isTrue);
      expect(cumpleAzul([4, 4], 2), isFalse);
    });

    test('morado permite como máximo dos valores distintos', () {
      expect(cumpleMorado([2], 5), isTrue);
      expect(cumpleMorado([2, 5, 2, 5], 5), isTrue);
      expect(cumpleMorado([2, 5], 6), isFalse);
    });
  });

  group('construirTableroDesdeColores', () {
        test('las celdas del mismo color conectadas comparten zona', () {
      final generado = construirTableroDesdeColores([
        [ColorRegion.verde, ColorRegion.verde],
        [ColorRegion.rojo, ColorRegion.verde],
      ]);

      expect(generado.celdas, hasLength(4));
      expect(generado.celdas[0].zonaId, generado.celdas[1].zonaId);
      // (1,1) también es verde y toca a (0,1): es la misma zona.
      expect(generado.celdas[0].zonaId, generado.celdas[3].zonaId);
      // (1,0) es roja: otra zona.
      expect(generado.celdas[0].zonaId, isNot(generado.celdas[2].zonaId));
    });

    test('dos celdas del mismo color conectadas solo en diagonal son zonas distintas', () {
      final generado = construirTableroDesdeColores([
        [ColorRegion.azul, ColorRegion.rojo],
        [ColorRegion.rojo, ColorRegion.azul],
      ]);

      expect(generado.celdas[0].zonaId, isNot(generado.celdas[3].zonaId));
    });
  });

  group('TableroJuego: colocación y adyacencia', () {
    test('el tablero comienza vacío y la primera jugada puede ir en cualquier celda', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.verde],
        [ColorRegion.verde, ColorRegion.verde],
      ]);

      expect(juego.tableroVacio, isTrue);
      expect(juego.puedeColocar(1, 1, 6), isTrue);
      expect(juego.colocar(1, 1, 6), isTrue);
      expect(juego.tableroVacio, isFalse);
    });

    test('permite colocar junto a una celda ocupada, pero no en diagonal', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.verde],
        [ColorRegion.verde, ColorRegion.verde],
      ]);
      expect(juego.colocar(0, 0, 3), isTrue);

      expect(juego.puedeColocar(0, 1, 4), isTrue);
      expect(juego.puedeColocar(1, 0, 4), isTrue);
      expect(juego.puedeColocar(1, 1, 4), isFalse);
    });

    test('no permite ocupar dos veces la misma celda', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde],
      ]);

      expect(juego.colocar(0, 0, 2), isTrue);
      expect(juego.colocar(0, 0, 4), isFalse);
      expect(juego.celdaEn(0, 0).valor, 2);
    });

    test('la regla del color se aplica al colocar', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.azul, ColorRegion.azul],
      ]);

      expect(juego.colocar(0, 0, 2), isTrue);
      expect(juego.puedeColocar(0, 1, 5), isFalse);
      expect(juego.puedeColocar(0, 1, 2), isTrue);
    });

    test('celdasValidasPara solo devuelve posiciones vacías válidas', () {
      final juego = TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.verde],
        [ColorRegion.verde, ColorRegion.verde],
      ]);
      juego.colocar(0, 0, 3);

      final posiciones = juego.celdasValidasPara(4)
          .map((c) => '${c.fila},${c.columna}')
          .toSet();

      expect(posiciones, {'0,1', '1,0'});
      expect(juego.tableroCompleto, isFalse);
    });
  });
}

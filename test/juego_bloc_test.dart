import 'dart:math';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/tablero.dart';
import 'package:brillant_app/juego.dart';
import 'package:brillant_app/juego_bloc.dart';
import 'helpers/random_fijo.dart';

void main() {
  // verde | rojo
  // azul  | morado
  TableroJuego tableroPrueba() => TableroJuego.desdeColores([
        [ColorRegion.verde, ColorRegion.rojo],
        [ColorRegion.azul, ColorRegion.morado],
      ]);

  // bloc.add() solo encola el evento: el handler corre en un tick
  // posterior. Esto deja que se procese antes de leer bloc.state.
  Future<void> tick() => Future<void>.delayed(Duration.zero);

  group('dados automáticos', () {
    test('el estado inicial ya trae los dos dados tirados', () {
      final bloc = JuegoBloc(tableroPrueba(), random: RandomFijo([3, 5]));
      expect(bloc.state.dado1, 3);
      expect(bloc.state.dado2, 5);
      expect(bloc.state.numeroSeleccionado, isNull);
      expect(bloc.state.terminado, isFalse);
      bloc.close();
    });

    test('si la tirada inicial no da jugada, se vuelve a tirar sola', () {
      final t = tableroPrueba()..colocar(0, 0, 3);
      // (4,5): no hay ni 4 ni 5 en el tablero -> re-tira -> (3,5) sí sirve.
      final bloc = JuegoBloc(t, random: RandomFijo([4, 5, 3, 5]));
      expect(bloc.state.dado1, 3);
      expect(bloc.state.dado2, 5);
      expect(bloc.state.mensaje, contains('se volvieron a tirar'));
      bloc.close();
    });
  });

  group('ElegirNumero (elegir el ancla)', () {
    blocTest<JuegoBloc, JuegoState>(
      'el dado elegido es el ancla y el otro es el que se coloca',
      build: () => JuegoBloc(tableroPrueba(), random: RandomFijo([3, 5])),
      act: (bloc) => bloc.add(ElegirNumero(3)),
      verify: (bloc) {
        expect(bloc.state.numeroSeleccionado, 3);
        expect(bloc.state.numeroAColocar, 5);
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'elegir el otro dado invierte los papeles',
      build: () => JuegoBloc(tableroPrueba(), random: RandomFijo([3, 5])),
      act: (bloc) => bloc.add(ElegirNumero(5)),
      verify: (bloc) {
        expect(bloc.state.numeroSeleccionado, 5);
        expect(bloc.state.numeroAColocar, 3);
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'ignora un número que no salió en los dados',
      build: () => JuegoBloc(tableroPrueba(), random: RandomFijo([3, 5])),
      act: (bloc) => bloc.add(ElegirNumero(6)),
      expect: () => [],
    );

    blocTest<JuegoBloc, JuegoState>(
      'resalta solo las casillas pegadas al ancla',
      build: () {
        final t = tableroPrueba()..colocar(0, 0, 3);
        return JuegoBloc(t, random: RandomFijo([3, 5]));
      },
      act: (bloc) => bloc.add(ElegirNumero(3)),
      verify: (bloc) {
        expect(bloc.state.celdasValidas, {const Point(0, 1), const Point(1, 0)});
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'si el ancla elegida no deja colocar nada, avisa y no resalta nada',
      build: () {
        final t = tableroPrueba()..colocar(0, 0, 3);
        return JuegoBloc(t, random: RandomFijo([3, 5]));
      },
      // ancla 5 (no está en el tablero), coloca 3
      act: (bloc) => bloc.add(ElegirNumero(5)),
      verify: (bloc) {
        expect(bloc.state.celdasValidas, isEmpty);
        expect(bloc.state.mensaje, contains('No hay dónde colocar'));
      },
    );
  });

  group('ColocarNumero', () {
    blocTest<JuegoBloc, JuegoState>(
      'coloca el dado que NO es el ancla y tira dados nuevos solos',
      build: () => JuegoBloc(
        tableroPrueba(),
        // inicial (3,5); luego (5,1): ancla 5 ya está en el tablero.
        random: RandomFijo([3, 5, 5, 1]),
      ),
      act: (bloc) async {
        bloc.add(ElegirNumero(3)); // ancla 3 -> se coloca el 5
        await tick();
        bloc.add(ColocarNumero(const Point(0, 0))); // tablero vacío: libre
      },
      verify: (bloc) {
        expect(bloc.state.tablero.celdaEn(0, 0).valor, 5);
        expect(bloc.state.numeroSeleccionado, isNull);
        expect(bloc.state.dado1, 5);
        expect(bloc.state.dado2, 1);
        expect(bloc.state.terminado, isFalse);
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'si los dados nuevos no dan jugada, se re-tiran solos',
      build: () => JuegoBloc(
        tableroPrueba(),
        // (3,5) -> coloca 5 en (0,0). Salen (2,4): no hay 2 ni 4 -> re-tira
        // -> (5,1): ancla 5 existe.
        random: RandomFijo([3, 5, 2, 4, 5, 1]),
      ),
      act: (bloc) async {
        bloc.add(ElegirNumero(3));
        await tick();
        bloc.add(ColocarNumero(const Point(0, 0)));
      },
      verify: (bloc) {
        expect(bloc.state.dado1, 5);
        expect(bloc.state.dado2, 1);
        expect(bloc.state.mensaje, contains('se volvieron a tirar'));
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'en celda que no toca al ancla: no coloca y conserva la selección',
      build: () {
        final t = tableroPrueba()..colocar(0, 0, 3);
        return JuegoBloc(t, random: RandomFijo([3, 5]));
      },
      act: (bloc) async {
        bloc.add(ElegirNumero(3));
        await tick();
        bloc.add(ColocarNumero(const Point(1, 1))); // diagonal a (0,0)
      },
      verify: (bloc) {
        expect(bloc.state.tablero.celdaEn(1, 1).valor, isNull);
        expect(bloc.state.numeroSeleccionado, 3);
        expect(bloc.state.mensaje, contains('no se puede'));
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'sin ancla elegida no hace nada',
      build: () => JuegoBloc(tableroPrueba(), random: RandomFijo([3, 5])),
      act: (bloc) => bloc.add(ColocarNumero(const Point(0, 0))),
      expect: () => [],
    );
  });

  group('PasarTurno', () {
    blocTest<JuegoBloc, JuegoState>(
      'descarta la tirada, limpia la selección y tira dados nuevos',
      build: () => JuegoBloc(tableroPrueba(), random: RandomFijo([3, 5, 6, 2])),
      act: (bloc) async {
        bloc.add(ElegirNumero(3));
        await tick();
        bloc.add(PasarTurno());
      },
      verify: (bloc) {
        expect(bloc.state.numeroSeleccionado, isNull);
        expect(bloc.state.dado1, 6);
        expect(bloc.state.dado2, 2);
        expect(bloc.state.tablero.tableroVacio, isTrue);
        expect(bloc.state.puntuacion, 0);
      },
    );
  });

  group('puntuación y fin de partida', () {
    blocTest<JuegoBloc, JuegoState>(
      'completar una zona suma sus puntos (tamaño de la zona)',
      build: () => JuegoBloc(
        TableroJuego.desdeColores([
          [ColorRegion.verde, ColorRegion.verde],
        ]),
        // (3,3): coloca 3 en (0,0). Luego (3,3): ancla 3, coloca 3 en (0,1).
        random: RandomFijo([3, 3, 3, 3]),
      ),
      act: (bloc) async {
        bloc.add(ElegirNumero(3));
        await tick();
        bloc.add(ColocarNumero(const Point(0, 0)));
        await tick();
        bloc.add(ElegirNumero(3));
        await tick();
        bloc.add(ColocarNumero(const Point(0, 1)));
      },
      verify: (bloc) {
        expect(bloc.state.puntuacion, 2);
        expect(bloc.state.terminado, isTrue);
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'al completar el tablero termina y ya no hay dados',
      build: () => JuegoBloc(
        TableroJuego.desdeColores([
          [ColorRegion.verde],
        ]),
        random: RandomFijo([4, 4]),
      ),
      act: (bloc) async {
        bloc.add(ElegirNumero(4));
        await tick();
        bloc.add(ColocarNumero(const Point(0, 0)));
      },
      verify: (bloc) {
        expect(bloc.state.terminado, isTrue);
        expect(bloc.state.dado1, isNull);
        expect(bloc.state.dado2, isNull);
        expect(bloc.state.puntuacion, 1);
      },
    );

    test('si el tablero ya viene completo, el juego arranca terminado', () {
      final tablero = TableroJuego.desdeColores([
        [ColorRegion.verde],
      ]);
      tablero.colocar(0, 0, 4);
      tablero.comprobarPuntuacion();

      final bloc = JuegoBloc(tablero, random: RandomFijo([]));
      expect(bloc.state.terminado, isTrue);
      expect(bloc.state.dado1, isNull);
      expect(bloc.state.puntuacion, 1);
      bloc.close();
    });

    test('si ya no existe ninguna jugada posible, la partida termina', () {
      // Zona roja de 7 celdas con 1..6 puestos: la 7ª no admite nada.
      final t = TableroJuego.desdeColores(<List<ColorRegion>>[
        List.filled(7, ColorRegion.rojo),
      ]);
      for (var c = 0; c < 6; c++) {
        t.colocar(0, c, c + 1);
      }

      final bloc = JuegoBloc(t, random: RandomFijo([]));
      expect(bloc.state.terminado, isTrue);
      expect(bloc.state.mensaje, contains('No quedan jugadas posibles'));
      bloc.close();
    });
  });
}
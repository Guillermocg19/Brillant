import 'dart:math';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/tablero.dart';
import 'package:brillant_app/juego.dart';
import 'package:brillant_app/juego_bloc.dart';

void main() {
  TableroJuego tableroPrueba() {
    final grid = [
      [ColorRegion.verde, ColorRegion.rojo],
      [ColorRegion.azul, ColorRegion.morado],
    ];
    return TableroJuego.desdeColores(grid);
  }

  // bloc.add() solo encola el evento: el handler corre en un tick
  // posterior. Esto deja que se procese antes de leer bloc.state.
  Future<void> tick() => Future<void>.delayed(Duration.zero);

  group('dados automáticos', () {
    test('el estado inicial ya trae los dos dados tirados (1-6)', () {
      final bloc = JuegoBloc(tableroPrueba(), random: Random(5));
      expect(bloc.state.dado1, inInclusiveRange(1, 6));
      expect(bloc.state.dado2, inInclusiveRange(1, 6));
      expect(bloc.state.numeroSeleccionado, isNull);
      expect(bloc.state.terminado, isFalse);
      bloc.close();
    });
  });

  group('ElegirNumero', () {
    blocTest<JuegoBloc, JuegoState>(
      'guarda el número elegido si es uno de los dos dados',
      build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
      act: (bloc) => bloc.add(ElegirNumero(bloc.state.dado1!)),
      verify: (bloc) {
        expect(bloc.state.numeroSeleccionado, bloc.state.dado1);
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'ignora un número que no salió en los dados',
      build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
      act: (bloc) => bloc.add(ElegirNumero(999)),
      expect: () => [],
    );
  });

  group('ColocarNumero', () {
    blocTest<JuegoBloc, JuegoState>(
      'en celda válida: coloca el número y tira dados nuevos solos',
      build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
      act: (bloc) async {
        bloc.add(ElegirNumero(bloc.state.dado1!));
        await tick();
        // Tablero vacío -> cualquier celda sirve como primer movimiento.
        bloc.add(ColocarNumero(const Point(0, 0)));
      },
      verify: (bloc) {
        expect(bloc.state.tablero.celdaEn(0, 0).valor, isNotNull);
        expect(bloc.state.numeroSeleccionado, isNull);
        // Los dados se volvieron a tirar automáticamente.
        expect(bloc.state.dado1, inInclusiveRange(1, 6));
        expect(bloc.state.dado2, inInclusiveRange(1, 6));
        expect(bloc.state.terminado, isFalse);
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'en celda inválida (no adyacente): no avanza, conserva la selección',
      build: () {
        final tablero = tableroPrueba();
        tablero.colocar(0, 0, 3); // (1,1) solo toca a (0,0) en diagonal
        return JuegoBloc(tablero, random: Random(5));
      },
      act: (bloc) async {
        bloc.add(ElegirNumero(bloc.state.dado1!));
        await tick();
        bloc.add(ColocarNumero(const Point(1, 1)));
      },
      verify: (bloc) {
        expect(bloc.state.tablero.celdaEn(1, 1).valor, isNull);
        expect(bloc.state.numeroSeleccionado, isNotNull);
      },
    );

    blocTest<JuegoBloc, JuegoState>(
      'sin número elegido no hace nada',
      build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
      act: (bloc) => bloc.add(ColocarNumero(const Point(0, 0))),
      expect: () => [],
    );
  });

  group('PasarTurno', () {
    blocTest<JuegoBloc, JuegoState>(
      'descarta la tirada, limpia la selección y tira dados nuevos',
      build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
      act: (bloc) async {
        bloc.add(ElegirNumero(bloc.state.dado1!));
        await tick();
        bloc.add(PasarTurno());
      },
      verify: (bloc) {
        expect(bloc.state.numeroSeleccionado, isNull);
        expect(bloc.state.dado1, inInclusiveRange(1, 6));
        expect(bloc.state.dado2, inInclusiveRange(1, 6));
        // No se colocó nada en el tablero.
        expect(bloc.state.tablero.tableroVacio, isTrue);
        expect(bloc.state.puntuacion, 0);
      },
    );
  });

  group('puntuación y fin de partida', () {
    blocTest<JuegoBloc, JuegoState>(
      'completar una zona suma sus puntos (tamaño de la zona)',
      build: () {
        // Una sola zona verde de 2 celdas.
        final grid = [
          [ColorRegion.verde, ColorRegion.verde],
        ];
        return JuegoBloc(TableroJuego.desdeColores(grid), random: Random(5));
      },
      act: (bloc) async {
        bloc.add(ElegirNumero(bloc.state.dado1!));
        await tick();
        bloc.add(ColocarNumero(const Point(0, 0)));
        await tick();
        bloc.add(ElegirNumero(bloc.state.dado1!));
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
      build: () {
        final grid = [
          [ColorRegion.verde],
        ];
        return JuegoBloc(TableroJuego.desdeColores(grid), random: Random(5));
      },
      act: (bloc) async {
        bloc.add(ElegirNumero(bloc.state.dado1!));
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

      final bloc = JuegoBloc(tablero, random: Random(5));
      expect(bloc.state.terminado, isTrue);
      expect(bloc.state.dado1, isNull);
      expect(bloc.state.puntuacion, 1);
      bloc.close();
    });
  });
}
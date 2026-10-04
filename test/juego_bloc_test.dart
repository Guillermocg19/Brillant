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

  // Deja que el bloc procese el último evento encolado antes de seguir.
  // bloc.add() es "fire and forget": el handler corre en un tick
  // posterior, así que leer bloc.state justo después de add() sin
  // esperar puede ver el estado viejo todavía.
  Future<void> tick() => Future<void>.delayed(Duration.zero);

  blocTest<JuegoBloc, JuegoState>(
    'LanzarDados llena dado1 y dado2 (1-6) y limpia la selección',
    build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
    act: (bloc) => bloc.add(LanzarDados()),
    verify: (bloc) {
      expect(bloc.state.dado1, inInclusiveRange(1, 6));
      expect(bloc.state.dado2, inInclusiveRange(1, 6));
      expect(bloc.state.numeroSeleccionado, isNull);
    },
  );

  blocTest<JuegoBloc, JuegoState>(
    'no se puede lanzar de nuevo si ya hay un número elegido',
    build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
    act: (bloc) async {
      bloc.add(LanzarDados());
      await tick();
      final n = bloc.state.dado1!;
      bloc.add(ElegirNumero(n));
      await tick();
      bloc.add(LanzarDados()); // no debería cambiar los dados
    },
    verify: (bloc) {
      expect(bloc.state.numeroSeleccionado, isNotNull);
    },
  );

  blocTest<JuegoBloc, JuegoState>(
    'ElegirNumero solo acepta uno de los dos valores tirados',
    build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
    act: (bloc) async {
      bloc.add(LanzarDados());
      await tick();
      bloc.add(ElegirNumero(999)); // valor inválido, no estaba en los dados
    },
    verify: (bloc) {
      expect(bloc.state.numeroSeleccionado, isNull);
    },
  );

  blocTest<JuegoBloc, JuegoState>(
    'ColocarNumero en una celda válida limpia los dados y avanza el turno',
    build: () => JuegoBloc(tableroPrueba(), random: Random(5)),
    act: (bloc) async {
      bloc.add(LanzarDados());
      await tick();
      final n = bloc.state.dado1!;
      bloc.add(ElegirNumero(n));
      await tick();
      // El tablero empieza vacío -> cualquier celda es válida para el
      // primer movimiento.
      bloc.add(ColocarNumero(const Point(0, 0)));
    },
    verify: (bloc) {
      expect(bloc.state.dado1, isNull);
      expect(bloc.state.dado2, isNull);
      expect(bloc.state.numeroSeleccionado, isNull);
      expect(bloc.state.tablero.celdaEn(0, 0).valor, isNotNull);
    },
  );

  blocTest<JuegoBloc, JuegoState>(
    'ColocarNumero en una celda inválida no mueve el turno',
    build: () {
      final tablero = tableroPrueba();
      // Ocupa (0,0) para que (1,1) ya no sea adyacente válida sin más.
      tablero.colocar(0, 0, 3);
      return JuegoBloc(tablero, random: Random(5));
    },
    act: (bloc) async {
      bloc.add(LanzarDados());
      await tick();
      final n = bloc.state.dado1!;
      bloc.add(ElegirNumero(n));
      await tick();
      bloc.add(ColocarNumero(const Point(1, 1))); // no adyacente
    },
    verify: (bloc) {
      // Los dados siguen ahí porque el movimiento falló.
      expect(bloc.state.dado1, isNotNull);
      expect(bloc.state.numeroSeleccionado, isNotNull);
    },
  );

  blocTest<JuegoBloc, JuegoState>(
    'el juego se marca terminado cuando el tablero queda completo',
    build: () {
      // Tablero 1x1: un solo movimiento y ya está completo.
      final grid = [
        [ColorRegion.verde],
      ];
      return JuegoBloc(TableroJuego.desdeColores(grid), random: Random(5));
    },
    act: (bloc) async {
      bloc.add(LanzarDados());
      await tick();
      final n = bloc.state.dado1!;
      bloc.add(ElegirNumero(n));
      await tick();
      bloc.add(ColocarNumero(const Point(0, 0)));
    },
    verify: (bloc) {
      expect(bloc.state.terminado, isTrue);
    },
  );
}
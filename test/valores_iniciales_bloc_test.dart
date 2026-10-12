import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/valores_iniciales_bloc.dart';

void main() {
  final estrellas = <Point<int>>{
    const Point(0, 0),
    const Point(0, 1),
    const Point(1, 0),
  };

  group('ValoresInicialesBloc', () {
    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'inicia sin valores y con todos los números disponibles',
      build: () => ValoresInicialesBloc(estrellas, random: Random(7)),
      verify: (bloc) {
        expect(bloc.state.valores, isEmpty);
        expect(bloc.state.numeroSeleccionado, isNull);
        expect(bloc.state.numerosDisponibles, [1, 2, 3, 4, 5, 6]);
        expect(bloc.state.listo, isFalse);
      },
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'seleccionar un número lo deja preparado para colocar',
      build: () => ValoresInicialesBloc(estrellas, random: Random(7)),
      act: (bloc) => bloc.add(SeleccionarNumero(4)),
      expect: () => [
        isA<ValoresInicialesState>()
            .having((s) => s.numeroSeleccionado, 'numeroSeleccionado', 4)
            .having((s) => s.valores, 'valores', isEmpty),
      ],
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'colocar en una estrella guarda el valor y limpia la selección',
      build: () => ValoresInicialesBloc(estrellas, random: Random(7)),
      act: (bloc) async {
        bloc.add(SeleccionarNumero(3));
        await Future<void>.delayed(Duration.zero);
        bloc.add(TocarCelda(const Point(0, 1)));
      },
      verify: (bloc) {
        expect(bloc.state.valores[const Point(0, 1)], 3);
        expect(bloc.state.numeroSeleccionado, isNull);
        expect(bloc.state.numerosDisponibles, [1, 2, 4, 5, 6]);
      },
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'tocar una celda que ya tiene valor lo elimina',
      build: () => ValoresInicialesBloc(estrellas, random: Random(7)),
      act: (bloc) async {
        bloc.add(SeleccionarNumero(2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(TocarCelda(const Point(0, 0)));
        await Future<void>.delayed(Duration.zero);
        bloc.add(TocarCelda(const Point(0, 0)));
      },
      verify: (bloc) {
        expect(bloc.state.valores, isEmpty);
        expect(bloc.state.numerosDisponibles, [1, 2, 3, 4, 5, 6]);
      },
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'ignora una posición que no está marcada como estrella',
      build: () => ValoresInicialesBloc(estrellas, random: Random(7)),
      act: (bloc) async {
        bloc.add(SeleccionarNumero(5));
        await Future<void>.delayed(Duration.zero);
        bloc.add(TocarCelda(const Point(8, 8)));
      },
      verify: (bloc) {
        expect(bloc.state.valores, isEmpty);
        expect(bloc.state.numeroSeleccionado, 5);
      },
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'ColocarAleatorio rellena las estrellas sin repetir números',
      build: () => ValoresInicialesBloc(estrellas, random: Random(7)),
      act: (bloc) => bloc.add(ColocarAleatorio()),
      verify: (bloc) {
        expect(bloc.state.valores.keys.toSet(), estrellas);
        expect(bloc.state.valores.values.toSet().length, estrellas.length);
        expect(bloc.state.valores.values, everyElement(inInclusiveRange(1, 6)));
        expect(bloc.state.numeroSeleccionado, isNull);
        expect(bloc.state.listo, isTrue);
      },
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'Reiniciar limpia los valores y la selección',
      build: () => ValoresInicialesBloc(estrellas, random: Random(7)),
      act: (bloc) async {
        bloc.add(ColocarAleatorio());
        await Future<void>.delayed(Duration.zero);
        bloc.add(SeleccionarNumero(2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(Reiniciar());
      },
      verify: (bloc) {
        expect(bloc.state.valores, isEmpty);
        expect(bloc.state.numeroSeleccionado, isNull);
        expect(bloc.state.listo, isFalse);
      },
    );
  });
}

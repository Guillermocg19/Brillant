import 'dart:math';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/tablero.dart';
import 'package:brillant_app/niveles.dart';
import 'package:brillant_app/valores_iniciales_bloc.dart';

void main() {
  Future<void> tick() => Future<void>.delayed(Duration.zero);

  // [naranja 4-6] [naranja 1-3]
  final tableroRango = <List<ColorRegion>>[
    [ColorRegion.naranjaAlto, ColorRegion.naranjaBajo],
  ];
  final estrellasRango = <Point<int>>{const Point(0, 0), const Point(0, 1)};

  group('ValoresInicialesBloc con zonas de rango', () {
    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'no deja poner un 2 en la estrella naranja 4-6',
      build: () => ValoresInicialesBloc(estrellasRango, tablero: tableroRango),
      act: (bloc) async {
        bloc.add(SeleccionarNumero(2));
        await tick();
        bloc.add(TocarCelda(const Point(0, 0)));
      },
      verify: (bloc) {
        expect(bloc.state.valores, isEmpty);
        expect(bloc.state.numeroSeleccionado, 2); // sigue seleccionado
      },
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'sí deja poner un 5 en la estrella naranja 4-6',
      build: () => ValoresInicialesBloc(estrellasRango, tablero: tableroRango),
      act: (bloc) async {
        bloc.add(SeleccionarNumero(5));
        await tick();
        bloc.add(TocarCelda(const Point(0, 0)));
      },
      verify: (bloc) {
        expect(bloc.state.valores[const Point(0, 0)], 5);
      },
    );

    blocTest<ValoresInicialesBloc, ValoresInicialesState>(
      'no deja poner un 5 en la estrella naranja 1-3',
      build: () => ValoresInicialesBloc(estrellasRango, tablero: tableroRango),
      act: (bloc) async {
        bloc.add(SeleccionarNumero(5));
        await tick();
        bloc.add(TocarCelda(const Point(0, 1)));
      },
      verify: (bloc) => expect(bloc.state.valores, isEmpty),
    );

    test('colocar al azar en el Nivel 4 siempre respeta los rangos', () async {
      for (var semilla = 0; semilla < 50; semilla++) {
        final bloc = ValoresInicialesBloc(
          estrellasNivel4,
          random: Random(semilla),
          tablero: tableroNivel4,
        );
        bloc.add(ColocarAleatorio());
        await tick();

        final v = bloc.state.valores;
        expect(v.length, 6, reason: 'semilla $semilla');
        expect(v.values.toSet().length, 6, reason: 'semilla $semilla');
        expect(v[const Point(0, 4)], inInclusiveRange(4, 6),
            reason: 'semilla $semilla');
        expect(v[const Point(6, 1)], inInclusiveRange(1, 3),
            reason: 'semilla $semilla');
        await bloc.close();
      }
    });
  });
}
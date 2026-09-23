import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/tablero.dart';
import 'package:brillant_app/pantalla_valores_iniciales.dart';
import 'package:brillant_app/juego.dart';

void main() {
  final tableroPrueba = [
    [ColorRegion.azul, ColorRegion.rojo],
    [ColorRegion.verde, ColorRegion.morado],
  ];
  final estrellasPrueba = <Point<int>>{
    const Point(0, 0),
    const Point(1, 1),
  };

  // La ventana de prueba por defecto (800x600) es muy chica para que
  // el GridView quepa sin scroll -> las celdas fuera de la vista nunca
  // se "construyen" y los finders no las encuentran. Por eso agrandamos
  // la superficie ANTES de pintar el widget en cada prueba.
  Future<void> pintarPantalla(
    WidgetTester tester, {
    required void Function(Map<Point<int>, int>) alContinuar,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: PantallaValoresIniciales(
        tablero: tableroPrueba,
        estrellas: estrellasPrueba,
        alContinuar: alContinuar,
      ),
    ));
  }

  testWidgets('el botón continuar empieza deshabilitado', (tester) async {
    Map<Point<int>, int>? resultado;
    await pintarPantalla(tester, alContinuar: (v) => resultado = v);

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boton.onPressed, isNull);
    expect(resultado, isNull);
  });

  testWidgets('colocar un número en una estrella lo quita de la lista disponible',
      (tester) async {
    await pintarPantalla(tester, alContinuar: (_) {});

    await tester.tap(find.widgetWithText(ChoiceChip, '3'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('celda_0_0')));
    await tester.pump();

    expect(find.widgetWithText(ChoiceChip, '3'), findsNothing);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('el botón se habilita cuando todas las estrellas tienen valor',
      (tester) async {
    Map<Point<int>, int>? resultado;
    await pintarPantalla(tester, alContinuar: (v) => resultado = v);

    await tester.tap(find.widgetWithText(ChoiceChip, '1'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('celda_0_0')));
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, '5'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('celda_1_1')));
    await tester.pump();

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boton.onPressed, isNotNull);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(resultado, {
      const Point(0, 0): 1,
      const Point(1, 1): 5,
    });
  });

  testWidgets('quitar un valor de una estrella vuelve a bloquear el avance',
      (tester) async {
    await pintarPantalla(tester, alContinuar: (_) {});

    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('celda_0_0')));
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('celda_1_1')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('celda_0_0')));
    await tester.pump();

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boton.onPressed, isNull);
    expect(find.widgetWithText(ChoiceChip, '2'), findsOneWidget);
  });

  group('colocarValoresIniciales', () {
    test('coloca los valores en las posiciones indicadas', () {
      final grid = [
        [ColorRegion.azul, ColorRegion.rojo],
        [ColorRegion.verde, ColorRegion.morado],
      ];
      final juego = TableroJuego.desdeColores(grid);
 
      juego.colocarValoresIniciales({
        const Point(0, 0): 3,
        const Point(1, 1): 5,
      });
 
      expect(juego.celdaEn(0, 0).valor, 3);
      expect(juego.celdaEn(1, 1).valor, 5);
      // Las que no eran estrella siguen vacías.
      expect(juego.celdaEn(0, 1).valor, isNull);
      expect(juego.celdaEn(1, 0).valor, isNull);
    });
 
    test('el tablero no queda completo si aún faltan celdas', () {
      final grid = [
        [ColorRegion.azul, ColorRegion.rojo],
        [ColorRegion.verde, ColorRegion.morado],
      ];
      final juego = TableroJuego.desdeColores(grid);
      juego.colocarValoresIniciales({const Point(0, 0): 3});
 
      expect(juego.tableroCompleto, isFalse);
    });
 
    test('lanza error si un valor inicial rompe la regla de su zona', () {
      // Dos celdas azules conectadas (misma zona) -> regla "todos iguales".
      final grid = [
        [ColorRegion.azul, ColorRegion.azul],
        [ColorRegion.rojo, ColorRegion.rojo],
      ];
      final juego = TableroJuego.desdeColores(grid);
 
      expect(
        () => juego.colocarValoresIniciales({
          const Point(0, 0): 2,
          const Point(0, 1): 5, // distinto -> viola "todos iguales"
        }),
        throwsArgumentError,
      );
    });
 
    test('valores iguales en la misma zona azul sí se permiten', () {
      final grid = [
        [ColorRegion.azul, ColorRegion.azul],
        [ColorRegion.rojo, ColorRegion.rojo],
      ];
      final juego = TableroJuego.desdeColores(grid);
 
      juego.colocarValoresIniciales({
        const Point(0, 0): 4,
        const Point(0, 1): 4,
      });
 
      expect(juego.celdaEn(0, 0).valor, 4);
      expect(juego.celdaEn(0, 1).valor, 4);
    });
  });
 
  group('TableroJuego.iniciar', () {
    test('crea el tablero y coloca los valores iniciales de una vez', () {
      final grid = [
        [ColorRegion.verde, ColorRegion.rojo],
        [ColorRegion.morado, ColorRegion.amarillo],
      ];
      final juego = TableroJuego.iniciar(grid, {
        const Point(0, 0): 6,
        const Point(1, 1): 1,
      });
 
      expect(juego.celdaEn(0, 0).valor, 6);
      expect(juego.celdaEn(1, 1).valor, 1);
      expect(juego.tableroCompleto, isFalse);
    });
 
    test('el tablero real de Nivel 1 acepta sus 6 valores iniciales', () {
      final juego = TableroJuego.iniciar(tableroNivel1, {
        const Point(0, 2): 1,
        const Point(1, 5): 2,
        const Point(3, 1): 3,
        const Point(3, 4): 4,
        const Point(5, 2): 5,
        const Point(6, 4): 6,
      });
 
      for (final estrella in estrellasNivel1) {
        expect(juego.celdaEn(estrella.x, estrella.y).valor, isNotNull);
      }
    });
  });
}
 

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/pantalla_inicio.dart';

void main() {
  Future<void> abrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: PantallaInicio()));
  }

  testWidgets('muestra un selector con los 4 niveles', (tester) async {
    await abrir(tester);

    for (final n in [1, 2, 3, 4]) {
      expect(find.text('Nivel $n'), findsOneWidget);
    }
  });

  testWidgets('Nivel 1 no muestra las reglas naranja en la leyenda',
      (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();

    expect(find.text('Solo del 4 al 6'), findsNothing);
    expect(find.text('Solo del 1 al 3'), findsNothing);
  });

  testWidgets('Nivel 4 muestra las dos reglas naranja en la leyenda',
      (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Nivel 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();

    expect(find.text('Solo del 4 al 6'), findsOneWidget);
    expect(find.text('Solo del 1 al 3'), findsOneWidget);
  });
}
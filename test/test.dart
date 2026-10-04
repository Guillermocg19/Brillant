import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillant_app/reglas.dart';
import 'package:brillant_app/tablero.dart';


import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------- REGLAS POR COLOR ----------

  group('cumpleTodosDiferentes', () {
    test('retorna true cuando la lista está vacía', () {
      expect(cumpleTodosDiferentes([], 5), isTrue);
    });

    test('retorna true cuando el número no está en la lista', () {
      expect(cumpleTodosDiferentes([1, 2, 3], 4), isTrue);
    });

    test('retorna false cuando el número ya está en la lista', () {
      expect(cumpleTodosDiferentes([1, 2, 3], 2), isFalse);
    });

    test('retorna false con lista de un solo elemento repetido', () {
      expect(cumpleTodosDiferentes([6], 6), isFalse);
    });

    test('retorna true con varios números del dado sin repetir', () {
      expect(cumpleTodosDiferentes([2, 4, 6], 5), isTrue);
    });
  });

  group('cumpleVerde', () {
    test('retorna true con lista vacía', () {
      expect(cumpleVerde([], 1), isTrue);
    });

    test('retorna true con lista llena de repetidos', () {
      expect(cumpleVerde([5, 5, 5], 5), isTrue);
    });

    test('retorna true con cualquier número nuevo', () {
      expect(cumpleVerde([1, 2, 3], 6), isTrue);
    });

    test('retorna true con el valor mínimo del dado', () {
      expect(cumpleVerde([1, 2], 1), isTrue);
    });
  });

  group('cumpleAzul', () {
    test('retorna true cuando la lista está vacía', () {
      expect(cumpleAzul([], 4), isTrue);
    });

    test('retorna true cuando el número coincide con todos los existentes', () {
      expect(cumpleAzul([3, 3, 3], 3), isTrue);
    });

    test('retorna false cuando el número no coincide con los existentes', () {
      expect(cumpleAzul([3, 3, 3], 4), isFalse);
    });

    test('retorna false si la lista ya tiene valores distintos entre sí', () {
      expect(cumpleAzul([2, 5], 2), isFalse);
    });

    test('retorna true con un solo elemento igual al nuevo número', () {
      expect(cumpleAzul([6], 6), isTrue);
    });
  });

  group('cumpleMorado', () {
    test('retorna true cuando la lista está vacía (primer valor)', () {
      expect(cumpleMorado([], 5), isTrue);
    });

    test('retorna true al repetir el único valor existente', () {
      expect(cumpleMorado([5, 5], 5), isTrue);
    });

    test('retorna true al introducir un segundo valor distinto', () {
      expect(cumpleMorado([5, 5], 6), isTrue);
    });

    test('retorna true al repetir cualquiera de los dos valores ya usados', () {
      expect(cumpleMorado([5, 6, 5, 6], 6), isTrue);
    });

    test('retorna false al intentar un tercer valor distinto', () {
      expect(cumpleMorado([5, 6], 3), isFalse);
    });

    test('retorna false con tercer valor aunque los dos primeros se repitan varias veces', () {
      expect(cumpleMorado([5, 5, 6, 6, 5], 2), isFalse);
    });
  });

  // ---------- EXTRACCIÓN POR ZONA ESPECÍFICA ----------

  group('extraerValoresDeZona', () {
    test('distingue zonas del mismo color usando zonaId', () {
      const celdas = [
        Celda(fila: 0, columna: 0, zonaId: 1, valor: 5),
        Celda(fila: 5, columna: 3, zonaId: 7, valor: 5),
      ];
      expect(extraerValoresDeZona(celdas, 1), [5]);
    });

    test('retorna solo los valores presentes en una zona incompleta', () {
      const celdas = [
        Celda(fila: 0, columna: 0, zonaId: 2, valor: 4),
        Celda(fila: 0, columna: 1, zonaId: 2),
        Celda(fila: 1, columna: 0, zonaId: 2),
      ];
      expect(extraerValoresDeZona(celdas, 2), [4]);
    });

    test('lista vacía si la zona no tiene números aún', () {
      const celdas = [
        Celda(fila: 0, columna: 0, zonaId: 3),
      ];
      expect(extraerValoresDeZona(celdas, 3), isEmpty);
    });
  });

  // ---------- EXTRACCIÓN POR COLOR + POSICIÓN ----------

  group('valoresPorColorYPosicion', () {
    // Tablero sintético 6x6: 2 zonas azules (arriba y abajo)
    // y 2 zonas amarillas (arriba-izquierda y arriba-derecha).
    final grid = [
      [ColorRegion.amarillo, ColorRegion.amarillo, ColorRegion.verde, ColorRegion.verde, ColorRegion.amarillo, ColorRegion.amarillo],
      [ColorRegion.azul, ColorRegion.azul, ColorRegion.verde, ColorRegion.verde, ColorRegion.azul, ColorRegion.azul],
      [ColorRegion.rojo, ColorRegion.rojo, ColorRegion.rojo, ColorRegion.rojo, ColorRegion.rojo, ColorRegion.rojo],
      [ColorRegion.morado, ColorRegion.morado, ColorRegion.morado, ColorRegion.morado, ColorRegion.morado, ColorRegion.morado],
      [ColorRegion.azul, ColorRegion.azul, ColorRegion.verde, ColorRegion.verde, ColorRegion.azul, ColorRegion.azul],
      [ColorRegion.azul, ColorRegion.azul, ColorRegion.verde, ColorRegion.verde, ColorRegion.azul, ColorRegion.azul],
    ];

    late TableroGenerado generado;

    setUp(() {
      generado = construirTableroDesdeColores(grid);
    });

    List<Celda> conValores(List<Celda> celdas, Map<Point<int>, int> valores) {
      return celdas.map((c) {
        final v = valores[Point(c.fila, c.columna)];
        return v == null
            ? c
            : Celda(fila: c.fila, columna: c.columna, zonaId: c.zonaId, valor: v);
      }).toList();
    }

    test('todos los azules (sin filtrar posición) junta ambas zonas azules', () {
      final celdasConValor = conValores(generado.celdas, {
        const Point(1, 0): 3, // azul arriba
        const Point(4, 0): 5, // azul abajo
      });
      final resultado = valoresPorColorYPosicion(
        celdasConValor, generado.colorPorZona, 6, 6, ColorRegion.azul,
      );
      expect(resultado.toSet(), {3, 5});
    });

    test('azul de arriba solo trae la zona azul superior', () {
      final celdasConValor = conValores(generado.celdas, {
        const Point(1, 0): 3,
        const Point(4, 0): 5,
      });
      final resultado = valoresPorColorYPosicion(
        celdasConValor, generado.colorPorZona, 6, 6, ColorRegion.azul,
        vertical: Vertical.arriba,
      );
      expect(resultado, [3]);
    });

    test('azul de abajo solo trae la zona azul inferior', () {
      final celdasConValor = conValores(generado.celdas, {
        const Point(1, 0): 3,
        const Point(4, 0): 5,
        const Point(4, 1): 5,
      });
      final resultado = valoresPorColorYPosicion(
        celdasConValor, generado.colorPorZona, 6, 6, ColorRegion.azul,
        vertical: Vertical.abajo,
      );
      expect(resultado.toSet(), {5});
    });

    test('amarillo arriba izquierda solo trae esa zona específica', () {
      final celdasConValor = conValores(generado.celdas, {
        const Point(0, 0): 1,
        const Point(0, 4): 6,
      });
      final resultado = valoresPorColorYPosicion(
        celdasConValor, generado.colorPorZona, 6, 6, ColorRegion.amarillo,
        vertical: Vertical.arriba, horizontal: Horizontal.izquierda,
      );
      expect(resultado, [1]);
    });

    test('amarillo arriba derecha solo trae esa zona específica', () {
      final celdasConValor = conValores(generado.celdas, {
        const Point(0, 0): 1,
        const Point(0, 4): 6,
      });
      final resultado = valoresPorColorYPosicion(
        celdasConValor, generado.colorPorZona, 6, 6, ColorRegion.amarillo,
        vertical: Vertical.arriba, horizontal: Horizontal.derecha,
      );
      expect(resultado, [6]);
    });

    test('sin celdas con valor -> lista vacía', () {
      final resultado = valoresPorColorYPosicion(
        generado.celdas, generado.colorPorZona, 6, 6, ColorRegion.rojo,
      );
      expect(resultado, isEmpty);
    });
  });

  // ---------- GENERACIÓN DEL TABLERO REAL ----------

  group('construirTableroDesdeColores (tablero real)', () {
    test('el tablero de 7x7 genera 49 celdas', () {
      final resultado = construirTableroDesdeColores(tableroNivel1);
      expect(resultado.celdas.length, 49);
    });
  });
}
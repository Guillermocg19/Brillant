import 'dart:math';
import 'package:equatable/equatable.dart';

class ValoresInicialesState extends Equatable {
  final Map<Point<int>, int> valores;
  final int? numeroSeleccionado;

  const ValoresInicialesState({
    this.valores = const {},
    this.numeroSeleccionado,
  });

  List<int> get numerosDisponibles {
    final usados = valores.values.toSet();
    return [1, 2, 3, 4, 5, 6].where((n) => !usados.contains(n)).toList();
  }

  bool listo(int totalEstrellas) => valores.length == totalEstrellas;

  ValoresInicialesState copyWith({
    Map<Point<int>, int>? valores,
    int? numeroSeleccionado,
    bool limpiarSeleccion = false,
  }) {
    return ValoresInicialesState(
      valores: valores ?? this.valores,
      numeroSeleccionado:
          limpiarSeleccion ? null : (numeroSeleccionado ?? this.numeroSeleccionado),
    );
  }

  @override
  List<Object?> get props => [valores, numeroSeleccionado];
}
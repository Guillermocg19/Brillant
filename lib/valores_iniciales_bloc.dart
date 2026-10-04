import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------- Eventos ----------

abstract class ValoresInicialesEvent {}

/// El jugador eligió un número (1-6) para colocar a continuación.
class SeleccionarNumero extends ValoresInicialesEvent {
  final int numero;
  SeleccionarNumero(this.numero);
}

/// El jugador tocó una celda con estrella: coloca el número
/// seleccionado ahí, o si ya tenía valor, lo quita.
class TocarCelda extends ValoresInicialesEvent {
  final Point<int> posicion;
  TocarCelda(this.posicion);
}

/// Reparte los números 1-6 al azar entre las estrellas, uno por
/// estrella, sin repetir.
class ColocarAleatorio extends ValoresInicialesEvent {}

/// Vacía todas las estrellas para empezar de nuevo.
class Reiniciar extends ValoresInicialesEvent {}

// ---------- Estado ----------

class ValoresInicialesState {
  final Map<Point<int>, int> valores;
  final int? numeroSeleccionado;
  final Set<Point<int>> estrellas;

  const ValoresInicialesState({
    required this.valores,
    required this.numeroSeleccionado,
    required this.estrellas,
  });

  List<int> get numerosDisponibles {
    final usados = valores.values.toSet();
    return [1, 2, 3, 4, 5, 6].where((n) => !usados.contains(n)).toList();
  }

  bool get listo => valores.length == estrellas.length;

  ValoresInicialesState copyWith({
    Map<Point<int>, int>? valores,
    int? numeroSeleccionado,
    bool limpiarSeleccion = false,
  }) {
    return ValoresInicialesState(
      valores: valores ?? this.valores,
      numeroSeleccionado:
          limpiarSeleccion ? null : (numeroSeleccionado ?? this.numeroSeleccionado),
      estrellas: estrellas,
    );
  }
}

// ---------- Bloc ----------

class ValoresInicialesBloc
    extends Bloc<ValoresInicialesEvent, ValoresInicialesState> {
  final Random _random;

  ValoresInicialesBloc(Set<Point<int>> estrellas, {Random? random})
      : _random = random ?? Random(),
        super(ValoresInicialesState(
          valores: const {},
          numeroSeleccionado: null,
          estrellas: estrellas,
        )) {
    on<SeleccionarNumero>((event, emit) {
      emit(state.copyWith(numeroSeleccionado: event.numero));
    });

    on<TocarCelda>((event, emit) {
      if (!state.estrellas.contains(event.posicion)) return;

      final nuevosValores = Map<Point<int>, int>.from(state.valores);

      if (nuevosValores.containsKey(event.posicion)) {
        // Ya tenía valor -> tocarla de nuevo la vacía.
        nuevosValores.remove(event.posicion);
        emit(state.copyWith(valores: nuevosValores));
      } else {
        if (state.numeroSeleccionado == null) return;
        nuevosValores[event.posicion] = state.numeroSeleccionado!;
        emit(ValoresInicialesState(
          valores: nuevosValores,
          numeroSeleccionado: null,
          estrellas: state.estrellas,
        ));
      }
    });

    on<ColocarAleatorio>((event, emit) {
      final numeros = [1, 2, 3, 4, 5, 6]..shuffle(_random);
      final estrellasLista = state.estrellas.toList();

      final nuevosValores = <Point<int>, int>{};
      for (var i = 0; i < estrellasLista.length; i++) {
        nuevosValores[estrellasLista[i]] = numeros[i];
      }

      emit(ValoresInicialesState(
        valores: nuevosValores,
        numeroSeleccionado: null,
        estrellas: state.estrellas,
      ));
    });

    on<Reiniciar>((event, emit) {
      emit(ValoresInicialesState(
        valores: const {},
        numeroSeleccionado: null,
        estrellas: state.estrellas,
      ));
    });
  }
}
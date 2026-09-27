import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'valores_iniciales_event.dart';
import 'valores_iniciales_state.dart';

class ValoresInicialesBloc
    extends Bloc<ValoresInicialesEvent, ValoresInicialesState> {
  ValoresInicialesBloc() : super(const ValoresInicialesState()) {
    on<SeleccionarNumero>(_alSeleccionarNumero);
    on<TocarEstrella>(_alTocarEstrella);
  }

  void _alSeleccionarNumero(
    SeleccionarNumero event,
    Emitter<ValoresInicialesState> emit,
  ) {
    final yaEstabaSeleccionado = state.numeroSeleccionado == event.numero;
    emit(state.copyWith(
      numeroSeleccionado: event.numero,
      limpiarSeleccion: yaEstabaSeleccionado, // tocar el mismo = deseleccionar
    ));
  }

  void _alTocarEstrella(
    TocarEstrella event,
    Emitter<ValoresInicialesState> emit,
  ) {
    final nuevosValores = Map<Point<int>, int>.from(state.valores);

    if (nuevosValores.containsKey(event.posicion)) {
      nuevosValores.remove(event.posicion);
      emit(state.copyWith(valores: nuevosValores));
      return;
    }

    final numero = state.numeroSeleccionado;
    if (numero == null) return; // nada seleccionado, no hace nada

    nuevosValores[event.posicion] = numero;
    emit(state.copyWith(valores: nuevosValores, limpiarSeleccion: true));
  }
}
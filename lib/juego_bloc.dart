import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'juego.dart';

// ---------- Eventos ----------

abstract class JuegoEvent {}

/// Tira los dos dados del turno (solo si no hay un número pendiente
/// de colocar).
class LanzarDados extends JuegoEvent {}

/// El jugador eligió uno de los dos números tirados.
class ElegirNumero extends JuegoEvent {
  final int numero;
  ElegirNumero(this.numero);
}

/// El jugador tocó una celda para colocar el número elegido ahí.
class ColocarNumero extends JuegoEvent {
  final Point<int> posicion;
  ColocarNumero(this.posicion);
}

// ---------- Estado ----------

class JuegoState {
  final TableroJuego tablero;
  final int? dado1;
  final int? dado2;
  final int? numeroSeleccionado;
  final String mensaje;
  final bool terminado;

  const JuegoState({
    required this.tablero,
    required this.dado1,
    required this.dado2,
    required this.numeroSeleccionado,
    required this.mensaje,
    required this.terminado,
  });

  /// Casillas donde el número elegido se puede colocar ahora mismo
  /// (para resaltarlas en el tablero).
  Set<Point<int>> get celdasValidas {
    if (numeroSeleccionado == null) return {};
    return tablero
        .celdasValidasPara(numeroSeleccionado!)
        .map((c) => Point(c.fila, c.columna))
        .toSet();
  }

  JuegoState copyWith({
    int? dado1,
    int? dado2,
    int? numeroSeleccionado,
    String? mensaje,
    bool? terminado,
    bool limpiarDados = false,
    bool limpiarSeleccion = false,
  }) {
    return JuegoState(
      tablero: tablero,
      dado1: limpiarDados ? null : (dado1 ?? this.dado1),
      dado2: limpiarDados ? null : (dado2 ?? this.dado2),
      numeroSeleccionado:
          limpiarSeleccion ? null : (numeroSeleccionado ?? this.numeroSeleccionado),
      mensaje: mensaje ?? this.mensaje,
      terminado: terminado ?? this.terminado,
    );
  }
}

// ---------- Bloc ----------

class JuegoBloc extends Bloc<JuegoEvent, JuegoState> {
  final Random _random;

  JuegoBloc(TableroJuego tablero, {Random? random})
      : _random = random ?? Random(),
        super(JuegoState(
          tablero: tablero,
          dado1: null,
          dado2: null,
          numeroSeleccionado: null,
          mensaje: 'Lanza los dados para empezar tu turno.',
          terminado: tablero.tableroCompleto,
        )) {
    on<LanzarDados>((event, emit) {
      if (state.terminado) return;
      if (state.numeroSeleccionado != null) {
        emit(state.copyWith(
          mensaje: 'Coloca el número elegido antes de volver a tirar.',
        ));
        return;
      }
      final d1 = _random.nextInt(6) + 1;
      final d2 = _random.nextInt(6) + 1;
      emit(state.copyWith(
        dado1: d1,
        dado2: d2,
        limpiarSeleccion: true,
        mensaje: 'Elige uno de los dos números.',
      ));
    });

    on<ElegirNumero>((event, emit) {
      if (state.dado1 == null || state.dado2 == null) return;
      if (event.numero != state.dado1 && event.numero != state.dado2) return;
      emit(state.copyWith(
        numeroSeleccionado: event.numero,
        mensaje: 'Toca una casilla resaltada para colocar el ${event.numero}.',
      ));
    });

    on<ColocarNumero>((event, emit) {
      if (state.numeroSeleccionado == null) return;

      final exito = state.tablero.colocar(
        event.posicion.x,
        event.posicion.y,
        state.numeroSeleccionado!,
      );

      if (!exito) {
        emit(state.copyWith(
          mensaje: 'Ahí no se puede colocar ese número.',
        ));
        return;
      }

      final completo = state.tablero.tableroCompleto;
      emit(state.copyWith(
        limpiarDados: true,
        limpiarSeleccion: true,
        terminado: completo,
        mensaje: completo
            ? '¡Tablero completo! Partida terminada.'
            : 'Número colocado. Lanza los dados de nuevo.',
      ));
    });
  }
}
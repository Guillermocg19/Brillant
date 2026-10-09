import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'juego.dart';

// ---------- Eventos ----------

abstract class JuegoEvent {}

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

/// El jugador decide NO colocar ninguno de los dos números de esta
/// tirada: se descartan y se tiran dados nuevos de inmediato.
class PasarTurno extends JuegoEvent {}

// ---------- Estado ----------

class JuegoState {
  final TableroJuego tablero;
  final int? dado1;
  final int? dado2;
  final int? numeroSeleccionado;
  final String mensaje;
  final bool terminado;
  final int puntuacion;
  final int puntosUltimaJugada;

  const JuegoState({
    required this.tablero,
    required this.dado1,
    required this.dado2,
    required this.numeroSeleccionado,
    required this.mensaje,
    required this.terminado,
    required this.puntuacion,
    required this.puntosUltimaJugada,
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
    int? puntuacion,
    int? puntosUltimaJugada,
    bool limpiarDados = false,
    bool limpiarSeleccion = false,
  }) {
    return JuegoState(
      tablero: tablero,
      dado1: limpiarDados ? null : (dado1 ?? this.dado1),
      dado2: limpiarDados ? null : (dado2 ?? this.dado2),
      numeroSeleccionado: limpiarSeleccion
          ? null
          : (numeroSeleccionado ?? this.numeroSeleccionado),
      mensaje: mensaje ?? this.mensaje,
      terminado: terminado ?? this.terminado,
      puntuacion: puntuacion ?? this.puntuacion,
      puntosUltimaJugada: puntosUltimaJugada ?? 0,
    );
  }
}

// ---------- Bloc ----------

class JuegoBloc extends Bloc<JuegoEvent, JuegoState> {
  final Random _random;

  JuegoBloc(TableroJuego tablero, {Random? random})
      : this._(tablero, random ?? Random());

  // El estado inicial ya trae los dados tirados: así la pantalla abre
  // con los dados listos, sin botón de "lanzar" y sin parpadeo.
  JuegoBloc._(TableroJuego tablero, Random random)
      : _random = random,
        super(_estadoInicial(tablero, random)) {
    on<ElegirNumero>((event, emit) {
      if (state.terminado) return;
      if (state.dado1 == null || state.dado2 == null) return;
      if (event.numero != state.dado1 && event.numero != state.dado2) return;
      emit(state.copyWith(
        numeroSeleccionado: event.numero,
        mensaje: 'Toca una casilla resaltada para colocar el ${event.numero}.',
      ));
    });

    on<ColocarNumero>((event, emit) {
      if (state.terminado) return;
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

      final puntosGanados = state.tablero.comprobarPuntuacion();
      final total = state.tablero.puntuacionTotal;

      if (state.tablero.tableroCompleto) {
        emit(state.copyWith(
          limpiarDados: true,
          limpiarSeleccion: true,
          terminado: true,
          puntuacion: total,
          puntosUltimaJugada: puntosGanados,
          mensaje: '¡Tablero completo! Partida terminada.',
        ));
        return;
      }

      // Colocó con éxito -> los dados siguientes se tiran solos.
      emit(state.copyWith(
        dado1: _tirar(),
        dado2: _tirar(),
        limpiarSeleccion: true,
        puntuacion: total,
        puntosUltimaJugada: puntosGanados,
        mensaje: puntosGanados > 0
            ? '¡Zona completada! +$puntosGanados puntos. Elige un número.'
            : 'Elige uno de los dos números.',
      ));
    });

    on<PasarTurno>((event, emit) {
      if (state.terminado) return;
      emit(state.copyWith(
        dado1: _tirar(),
        dado2: _tirar(),
        limpiarSeleccion: true,
        mensaje: 'Pasaste el turno. Elige uno de los dos números.',
      ));
    });
  }

  int _tirar() => _random.nextInt(6) + 1;

  static JuegoState _estadoInicial(TableroJuego tablero, Random random) {
    final terminado = tablero.tableroCompleto;
    return JuegoState(
      tablero: tablero,
      dado1: terminado ? null : random.nextInt(6) + 1,
      dado2: terminado ? null : random.nextInt(6) + 1,
      numeroSeleccionado: null,
      mensaje: terminado
          ? '¡Tablero completo! Partida terminada.'
          : 'Elige uno de los dos números.',
      terminado: terminado,
      puntuacion: tablero.puntuacionTotal,
      puntosUltimaJugada: 0,
    );
  }
}
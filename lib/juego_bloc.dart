import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'juego.dart';

// ---------- Eventos ----------

abstract class JuegoEvent {}

/// El jugador eligió uno de los dos dados como ANCLA. El otro dado es
/// el número que se va a colocar.
class ElegirNumero extends JuegoEvent {
  final int numero;
  ElegirNumero(this.numero);
}

/// El jugador tocó una celda para colocar ahí el número (el dado que
/// NO es el ancla).
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

  /// El dado elegido como ANCLA (null si todavía no elige).
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

  /// El número que se colocaría: el dado que NO es el ancla.
  int? get numeroAColocar {
    if (numeroSeleccionado == null || dado1 == null || dado2 == null) {
      return null;
    }
    return numeroSeleccionado == dado1 ? dado2 : dado1;
  }

  /// Casillas donde el número a colocar se puede poner ahora mismo con
  /// el ancla elegida (para resaltarlas en el tablero).
  Set<Point<int>> get celdasValidas {
    final ancla = numeroSeleccionado;
    final aColocar = numeroAColocar;
    if (ancla == null || aColocar == null) return {};
    return tablero
        .celdasValidasConAncla(ancla, aColocar)
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

// ---------- Tirada ----------

/// Resultado de tirar hasta que salga una tirada con jugada posible.
class _Tirada {
  final int dado1;
  final int dado2;

  /// Cuántas veces hubo que volver a tirar porque no había jugada.
  final int relanzamientos;
  const _Tirada(this.dado1, this.dado2, this.relanzamientos);
}

/// Tira los dos dados; si con esa tirada no hay jugada posible (ningún
/// dado sirve de ancla para colocar el otro), vuelve a tirar solo.
/// Devuelve null si ya no existe ninguna jugada posible en el tablero.
_Tirada? _tirarConJugada(TableroJuego tablero, Random random) {
  if (!tablero.hayAlgunaJugadaPosible) return null;
  for (var i = 0; i < 1000; i++) {
    final d1 = random.nextInt(6) + 1;
    final d2 = random.nextInt(6) + 1;
    if (tablero.hayJugadaPosible(d1, d2)) return _Tirada(d1, d2, i);
  }
  return null;
}

const _avisoRelanzado = ' No había jugada con esos dados y se volvieron a tirar.';

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

      final ancla = event.numero;
      final aColocar = ancla == state.dado1 ? state.dado2! : state.dado1!;
      final hayDonde =
          state.tablero.celdasValidasConAncla(ancla, aColocar).isNotEmpty;

      emit(state.copyWith(
        numeroSeleccionado: ancla,
        mensaje: hayDonde
            ? 'Ancla: $ancla. Toca una casilla resaltada para colocar el '
                '$aColocar.'
            : 'No hay dónde colocar el $aColocar junto a un $ancla. '
                'Prueba con el otro dado o pasa el turno.',
      ));
    });

    on<ColocarNumero>((event, emit) {
      if (state.terminado) return;
      final ancla = state.numeroSeleccionado;
      final aColocar = state.numeroAColocar;
      if (ancla == null || aColocar == null) return;

      final exito = state.tablero.colocarConAncla(
        event.posicion.x,
        event.posicion.y,
        aColocar,
        ancla,
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
      emit(_conNuevaTirada(
        prefijo: puntosGanados > 0
            ? '¡Zona completada! +$puntosGanados puntos.'
            : '',
        puntuacion: total,
        puntosUltimaJugada: puntosGanados,
      ));
    });

    on<PasarTurno>((event, emit) {
      if (state.terminado) return;
      emit(_conNuevaTirada(prefijo: 'Pasaste el turno.'));
    });
  }

  /// Tira dados nuevos garantizando que haya jugada. Si ya no queda
  /// ninguna jugada posible en el tablero, termina la partida.
  JuegoState _conNuevaTirada({
    required String prefijo,
    int? puntuacion,
    int puntosUltimaJugada = 0,
  }) {
    final tirada = _tirarConJugada(state.tablero, _random);

    if (tirada == null) {
      return state.copyWith(
        limpiarDados: true,
        limpiarSeleccion: true,
        terminado: true,
        puntuacion: puntuacion,
        puntosUltimaJugada: puntosUltimaJugada,
        mensaje: 'No quedan jugadas posibles. Partida terminada.',
      );
    }

    return state.copyWith(
      dado1: tirada.dado1,
      dado2: tirada.dado2,
      limpiarSeleccion: true,
      puntuacion: puntuacion,
      puntosUltimaJugada: puntosUltimaJugada,
      mensaje: '$prefijo Elige un dado como ancla.'
              '${tirada.relanzamientos > 0 ? _avisoRelanzado : ''}'
          .trim(),
    );
  }

  static JuegoState _estadoInicial(TableroJuego tablero, Random random) {
    if (tablero.tableroCompleto) {
      return JuegoState(
        tablero: tablero,
        dado1: null,
        dado2: null,
        numeroSeleccionado: null,
        mensaje: '¡Tablero completo! Partida terminada.',
        terminado: true,
        puntuacion: tablero.puntuacionTotal,
        puntosUltimaJugada: 0,
      );
    }

    final tirada = _tirarConJugada(tablero, random);
    if (tirada == null) {
      return JuegoState(
        tablero: tablero,
        dado1: null,
        dado2: null,
        numeroSeleccionado: null,
        mensaje: 'No quedan jugadas posibles. Partida terminada.',
        terminado: true,
        puntuacion: tablero.puntuacionTotal,
        puntosUltimaJugada: 0,
      );
    }

    return JuegoState(
      tablero: tablero,
      dado1: tirada.dado1,
      dado2: tirada.dado2,
      numeroSeleccionado: null,
      mensaje: 'Elige un dado como ancla.'
              '${tirada.relanzamientos > 0 ? _avisoRelanzado : ''}'
          .trim(),
      terminado: false,
      puntuacion: tablero.puntuacionTotal,
      puntosUltimaJugada: 0,
    );
  }
}
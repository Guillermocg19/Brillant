import 'dart:math';

import 'package:equatable/equatable.dart';

import '../tablero.dart' show ColorRegion;

enum RoomStatus { lobby, preparando, jugando, terminada }

class PlayerInfo extends Equatable {
  const PlayerInfo({
    required this.id,
    required this.name,
    required this.connected,
    required this.active,
    required this.lobbyReady,
    required this.roundReady,
    required this.score,
    required this.setupReady,
    required this.filled,
    required this.isHost,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> j) => PlayerInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        connected: j['connected'] as bool,
        active: j['active'] as bool,
        lobbyReady: j['lobbyReady'] as bool,
        roundReady: j['roundReady'] as bool,
        score: j['score'] as int,
        setupReady: j['setupReady'] as bool,
        filled: j['filled'] as int,
        isHost: j['isHost'] as bool,
      );

  final String id;
  final String name;
  final bool connected;

  /// false si se rindió, abandonó o salió (puede seguir mirando).
  final bool active;
  final bool lobbyReady;

  /// Ya dio "listo" en esta ronda.
  final bool roundReady;
  final int score;

  /// Ya confirmó sus números iniciales (fase de preparación).
  final bool setupReady;

  /// Celdas ya llenas de su tablero (progreso visible para todos).
  final int filled;
  final bool isHost;

  @override
  List<Object?> get props =>
      [id, name, connected, active, lobbyReady, roundReady, score, setupReady, filled, isHost];
}

/// Casillas donde puedes poner [valor] si eliges [ancla]. Las calcula el
/// servidor con las reglas reales: la app solo las dibuja.
class AnchorOption extends Equatable {
  const AnchorOption({
    required this.ancla,
    required this.valor,
    required this.cells,
  });

  factory AnchorOption.fromJson(Map<String, dynamic> j) => AnchorOption(
        ancla: j['ancla'] as int,
        valor: j['valor'] as int,
        cells: {
          for (final c in (j['cells'] as List).cast<List<dynamic>>())
            Point<int>(c[0] as int, c[1] as int),
        },
      );

  final int ancla;
  final int valor;
  final Set<Point<int>> cells;

  @override
  List<Object?> get props => [ancla, valor, cells];
}

/// Fase de preparación: cada jugador coloca el 1 al 6 en las estrellas.
class SetupInfo extends Equatable {
  const SetupInfo({
    required this.stars,
    required this.allowed,
    required this.confirmed,
  });

  factory SetupInfo.fromJson(Map<String, dynamic> j) => SetupInfo(
        stars: [
          for (final c in (j['stars'] as List).cast<List<dynamic>>())
            Point<int>(c[0] as int, c[1] as int),
        ],
        allowed: [
          for (final l in (j['allowed'] as List).cast<List<dynamic>>())
            {for (final v in l) v as int},
        ],
        confirmed: j['confirmed'] as bool,
      );

  /// Casillas con estrella, en orden: el valor i del envío va en la estrella i.
  final List<Point<int>> stars;

  /// Por estrella, los números que su zona admite (el servidor decide).
  final List<Set<int>> allowed;

  /// Ya confirmaste tus números (puedes cambiarlos hasta que todos terminen).
  final bool confirmed;

  @override
  List<Object?> get props => [stars, allowed, confirmed];
}

class GameResult extends Equatable {
  const GameResult({
    required this.reason,
    required this.winnerIds,
    required this.scores,
  });

  factory GameResult.fromJson(Map<String, dynamic> j) => GameResult(
        reason: j['reason'] as String,
        winnerIds: (j['winnerIds'] as List).cast<String>(),
        scores: {
          for (final e in (j['scores'] as Map).entries)
            e.key as String: e.value as int,
        },
      );

  /// completed | last_standing | no_moves | everyone_left
  final String reason;
  final List<String> winnerIds;
  final Map<String, int> scores;

  bool get isTie => winnerIds.length > 1;

  @override
  List<Object?> get props => [reason, winnerIds, scores];
}

class RoomSnapshot extends Equatable {
  const RoomSnapshot({
    required this.code,
    required this.nivel,
    required this.status,
    required this.hostId,
    required this.youId,
    required this.round,
    required this.dice,
    required this.grid,
    required this.board,
    required this.players,
    required this.pending,
    required this.options,
    required this.canPlay,
    required this.setup,
    required this.result,
  });

  factory RoomSnapshot.fromJson(Map<String, dynamic> j) {
    final pending = j['yourPending'] as Map<String, dynamic>?;
    final result = j['result'] as Map<String, dynamic>?;
    final setup = j['setup'] as Map<String, dynamic>?;
    return RoomSnapshot(
      code: j['code'] as String,
      nivel: j['nivel'] as int,
      status: switch (j['status'] as String) {
        'lobby' => RoomStatus.lobby,
        'preparando' => RoomStatus.preparando,
        'jugando' => RoomStatus.jugando,
        _ => RoomStatus.terminada,
      },
      hostId: j['hostId'] as String?,
      youId: j['you'] as String,
      round: j['round'] as int,
      dice: (j['dice'] as List).cast<int>(),
      // Los colores vienen del servidor: una sola fuente de verdad.
      grid: [
        for (final fila in (j['grid'] as List))
          [
            for (final c in (fila as List))
              ColorRegion.values.byName(c as String),
          ],
      ],
      board: [
        for (final fila in ((j['board'] as List?) ?? const []))
          [for (final v in (fila as List)) v as int?],
      ],
      players: [
        for (final p in (j['players'] as List))
          PlayerInfo.fromJson(p as Map<String, dynamic>),
      ],
      pending: pending == null
          ? null
          : (
              ancla: pending['ancla'] as int,
              valor: pending['valor'] as int,
              fila: pending['fila'] as int,
              columna: pending['columna'] as int,
            ),
      options: [
        for (final o in (j['options'] as List))
          AnchorOption.fromJson(o as Map<String, dynamic>),
      ],
      canPlay: j['canPlay'] as bool,
      setup: setup == null ? null : SetupInfo.fromJson(setup),
      result: result == null ? null : GameResult.fromJson(result),
    );
  }

  final String code;
  final int nivel;
  final RoomStatus status;
  final String? hostId;
  final String youId;
  final int round;
  final List<int> dice;

  /// Colores del nivel (igual para todos).
  final List<List<ColorRegion>> grid;

  /// TU tablero: valor por celda (null = vacía). Vacío en el lobby.
  final List<List<int?>> board;
  final List<PlayerInfo> players;

  /// Tu jugada de la ronda (corregible hasta dar "listo").
  final ({int ancla, int valor, int fila, int columna})? pending;
  final List<AnchorOption> options;

  /// false si con estos dados no tienes ninguna jugada (el servidor te da
  /// "listo" solo).
  final bool canPlay;

  /// Datos de la fase de preparación (null fuera de ella).
  final SetupInfo? setup;
  final GameResult? result;

  PlayerInfo get me => players.firstWhere((p) => p.id == youId);
  bool get amHost => hostId == youId;
  bool get iWon => result?.winnerIds.contains(youId) ?? false;

  String nameOf(String id) =>
      players.firstWhere((p) => p.id == id, orElse: () => me).name;

  @override
  List<Object?> get props => [
        code, nivel, status, hostId, youId, round, dice, grid, board,
        players, pending, options, canPlay, setup, result,
      ];
}
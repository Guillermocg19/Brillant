import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../celda_widget.dart';
import '../colores.dart';
import '../tablero.dart' show ColorRegion;
import 'multijugador_cubit.dart';
import 'multijugador_modelos.dart';

/// Abre una hoja con dos pestañas: los tableros de TODOS los jugadores
/// (se actualizan solos) y el registro de cada ronda.
Future<void> mostrarHojaPartida(BuildContext context) {
  final cubit = context.read<MultijugadorCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _HojaPartida(),
    ),
  );
}

/// Tablero en pequeño. Sirve para ver el de otro jugador ([board] con sus
/// números) o para enseñar cómo es un nivel ([board] null y, si quieres,
/// [estrellas] para marcar dónde empieza cada quien).
class TableroMini extends StatelessWidget {
  const TableroMini({
    super.key,
    required this.grid,
    this.board,
    this.estrellas = const [],
  });

  final List<List<ColorRegion>> grid;
  final List<List<int?>>? board;
  final List<Point<int>> estrellas;

  @override
  Widget build(BuildContext context) {
    final filas = grid.length;
    final columnas = grid.first.length;
    final tablero = board;
    return AspectRatio(
      aspectRatio: columnas / filas,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: filas * columnas,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnas,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, i) {
          final f = i ~/ columnas;
          final c = i % columnas;
          final valor =
              (tablero == null || tablero.isEmpty) ? null : tablero[f][c];
          final celda = CeldaTablero(
            color: grid[f][c],
            valor: valor,
            resaltada: false,
            onTap: null,
          );
          if (!estrellas.contains(Point(f, c))) return celda;
          return Stack(
            fit: StackFit.expand,
            children: [
              celda,
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.star, size: 13, color: Colors.amber.shade700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Cómo es el nivel que está elegido en la sala (colores y estrellas).
/// Ponlo en la pantalla del lobby: se actualiza cuando el anfitrión cambia de nivel.
class VistaPreviaNivel extends StatelessWidget {
  const VistaPreviaNivel({super.key, required this.sala});
  final RoomSnapshot sala;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Nivel ${sala.nivel}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: TableroMini(grid: sala.grid, estrellas: sala.stars),
        ),
        const SizedBox(height: 8),
        LeyendaColores(colores: sala.grid.expand((f) => f).toSet()),
        const SizedBox(height: 4),
        const Text('★ casillas con las que empiezas', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ───────────────────────── Hoja de la partida ─────────────────────────

class _HojaPartida extends StatelessWidget {
  const _HojaPartida();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [Tab(text: 'Tableros'), Tab(text: 'Registro')],
            ),
            Expanded(
              child: BlocBuilder<MultijugadorCubit, MultijugadorState>(
                builder: (context, st) {
                  final sala = st.sala;
                  if (sala == null) return const SizedBox.shrink();
                  return TabBarView(
                    children: [
                      _PestanaTableros(sala: sala),
                      _PestanaRegistro(sala: sala),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PestanaTableros extends StatelessWidget {
  const _PestanaTableros({required this.sala});
  final RoomSnapshot sala;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final dosColumnas = c.maxWidth >= 720;
        final ancho = min(
          dosColumnas ? (c.maxWidth - 48) / 2 : c.maxWidth - 32,
          380.0,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              for (final p in sala.players)
                SizedBox(
                  width: ancho,
                  child: _TarjetaTablero(sala: sala, jugador: p),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaTablero extends StatelessWidget {
  const _TarjetaTablero({required this.sala, required this.jugador});
  final RoomSnapshot sala;
  final PlayerInfo jugador;

  @override
  Widget build(BuildContext context) {
    final soyYo = jugador.id == sala.youId;
    final tablero = jugador.board;
    final error = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                soyYo ? '${jugador.name} (tú)' : jugador.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Text('${jugador.score} pts · ${jugador.filled} casillas'),
          ],
        ),
        if (!jugador.active)
          Text('Ya no participa', style: TextStyle(color: error, fontSize: 12))
        else if (!jugador.connected)
          Text('Sin conexión', style: TextStyle(color: error, fontSize: 12)),
        const SizedBox(height: 6),
        if (tablero == null || tablero.isEmpty)
          const AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: Text(
                'Se verá cuando empiece la partida',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TableroMini(grid: sala.grid, board: tablero),
          ),
      ],
    );
  }
}

class _PestanaRegistro extends StatelessWidget {
  const _PestanaRegistro({required this.sala});
  final RoomSnapshot sala;

  String _texto(PlayLog p) {
    final quien = p.id == sala.youId ? 'Tú' : p.name;
    if (p.passed) {
      return p.noMoves ? '$quien no tenía jugadas posibles' : '$quien pasó';
    }
    return '$quien eligió el ancla ${p.ancla} y puso el ${p.valor} '
        'en fila ${p.fila! + 1}, columna ${p.columna! + 1}';
  }

  @override
  Widget build(BuildContext context) {
    if (sala.log.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no se ha cerrado ninguna ronda.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final rondas = sala.log.reversed.toList(); // la más reciente arriba
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rondas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = rondas[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ronda ${r.round} · dados ${r.dice.join(' y ')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                for (final p in r.plays)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_texto(p)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

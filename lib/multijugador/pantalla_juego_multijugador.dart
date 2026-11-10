import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../celda_widget.dart';
import '../colores.dart';
import 'multijugador_cubit.dart';
import 'multijugador_modelos.dart';

/// Igual que tu PantallaJuego, pero en línea: los dados son los mismos para
/// todos (los tira el servidor), eliges un dado como ANCLA y colocas el otro;
/// después das "Listo" (o "Pasar") y la ronda avanza cuando todos lo hicieron.
///
/// Las casillas resaltadas las calcula el servidor con tus reglas, así que lo
/// que ves como válido es exactamente lo que el servidor aceptará.
class PantallaJuegoMultijugador extends StatefulWidget {
  const PantallaJuegoMultijugador({super.key, required this.sala});
  final RoomSnapshot sala;

  @override
  State<PantallaJuegoMultijugador> createState() =>
      _PantallaJuegoMultijugadorState();
}

class _PantallaJuegoMultijugadorState extends State<PantallaJuegoMultijugador> {
  /// Dado elegido como ancla antes de colocar (se reinicia cada ronda).
  int? _ancla;

  @override
  void didUpdateWidget(PantallaJuegoMultijugador anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.sala.round != widget.sala.round) _ancla = null;
  }

  Future<void> _confirmarRendirse(BuildContext context) async {
    final cubit = context.read<MultijugadorCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Conceder la partida?'),
        content: const Text(
          'Dejarás de jugar, pero podrás seguir mirando. '
          'Los demás continúan sin ti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Conceder'),
          ),
        ],
      ),
    );
    if (ok == true) cubit.rendirse();
  }

  @override
  Widget build(BuildContext context) {
    final sala = widget.sala;
    final yo = sala.me;
    final cubit = context.read<MultijugadorCubit>();

    final puedeActuar = yo.active && !yo.roundReady && sala.canPlay;
    final ancla = _ancla ?? sala.pending?.ancla;
    AnchorOption? opcion;
    for (final o in sala.options) {
      if (o.ancla == ancla) opcion = o;
    }
    final validas = puedeActuar ? (opcion?.cells ?? const <Point<int>>{}) : const <Point<int>>{};
    final pend = sala.pending;

    final activos = sala.players.where((p) => p.active).toList();
    final listos = activos.where((p) => p.roundReady).length;

    final String mensaje;
    if (!yo.active) {
      mensaje = 'Estás mirando la partida.';
    } else if (yo.roundReady && !sala.canPlay) {
      mensaje = 'Sin jugadas posibles con estos dados. Esperando a los demás ($listos/${activos.length}).';
    } else if (yo.roundReady) {
      mensaje = 'Listo. Esperando a los demás ($listos/${activos.length}).';
    } else if (ancla == null) {
      mensaje = 'Elige un dado como ancla.';
    } else if (pend != null && pend.ancla == ancla) {
      mensaje = 'Pondrás el ${pend.valor} ahí. Pulsa Listo, o toca otra casilla para cambiar.';
    } else if (opcion == null || validas.isEmpty) {
      mensaje = 'No hay dónde colocar junto a un $ancla. Prueba el otro dado o pasa.';
    } else {
      mensaje = 'Ancla $ancla: toca una casilla resaltada para colocar el ${opcion.valor}.';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ronda ${sala.round}'),
        actions: [
          if (yo.active)
            IconButton(
              tooltip: 'Conceder',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _confirmarRendirse(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Marcadores(jugadores: sala.players, yoId: sala.youId),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                mensaje,
                key: ValueKey(mensaje),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            LeyendaColores(colores: sala.grid.expand((f) => f).toSet()),
            const SizedBox(height: 14),
            if (yo.active)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < sala.dice.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _Dado(
                      key: ValueKey('dado_${i + 1}'),
                      valor: sala.dice[i],
                      seleccionado: ancla == sala.dice[i] &&
                          i == sala.dice.indexOf(sala.dice[i]),
                      etiqueta: ancla == null
                          ? null
                          : (ancla == sala.dice[i] &&
                                  i == sala.dice.indexOf(sala.dice[i])
                              ? 'ancla'
                              : 'a colocar'),
                      onTap: puedeActuar
                          ? () => setState(() => _ancla = sala.dice[i])
                          : null,
                    ),
                  ],
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    key: const ValueKey('boton_listo'),
                    icon: Icon(pend == null ? Icons.skip_next : Icons.check),
                    label: Text(pend == null ? 'Pasar' : 'Listo'),
                    onPressed: puedeActuar ? cubit.confirmarRonda : null,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final lado = min(constraints.maxWidth, constraints.maxHeight);
                  final filas = sala.grid.length;
                  final columnas = sala.grid.first.length;
                  return Center(
                    child: Container(
                      width: lado,
                      height: lado,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filas * columnas,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnas,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                        ),
                        itemBuilder: (context, i) {
                          final f = i ~/ columnas;
                          final c = i % columnas;
                          final esPendiente =
                              pend != null && pend.fila == f && pend.columna == c;
                          final valor = esPendiente
                              ? pend!.valor
                              : (sala.board.isEmpty ? null : sala.board[f][c]);
                          final esValida = validas.contains(Point(f, c));
                          return CeldaTablero(
                            key: ValueKey('celda_${f}_$c'),
                            color: sala.grid[f][c],
                            valor: valor,
                            resaltada: esValida,
                            onTap: !esValida || ancla == null
                                ? null
                                : () => cubit.colocar(ancla: ancla, fila: f, columna: c),
                          );
                        },
                      ),
                    ),
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

/// Puntos y estado de cada jugador: quién ya dio "listo", quién se cayó.
class _Marcadores extends StatelessWidget {
  const _Marcadores({required this.jugadores, required this.yoId});
  final List<PlayerInfo> jugadores;
  final String yoId;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final p in jugadores)
          Chip(
            visualDensity: VisualDensity.compact,
            backgroundColor: p.id == yoId ? esquema.primaryContainer : null,
            avatar: !p.active
                ? const Icon(Icons.flag, size: 16)
                : !p.connected
                    ? Icon(Icons.wifi_off, size: 16, color: esquema.error)
                    : p.roundReady
                        ? const Icon(Icons.check_circle, size: 16, color: Colors.green)
                        : const Icon(Icons.hourglass_empty, size: 16),
            label: Text(
              '${p.id == yoId ? 'Tú' : p.name}: ${p.score} pts',
              style: TextStyle(
                decoration: p.active ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado({
    super.key,
    required this.valor,
    required this.seleccionado,
    required this.onTap,
    this.etiqueta,
  });

  final int valor;
  final bool seleccionado;
  final String? etiqueta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: seleccionado ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: seleccionado ? Colors.indigo.shade400 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: seleccionado ? Colors.indigo.shade700 : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$valor',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: seleccionado ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: Text(
                etiqueta ?? '',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'multijugador_cliente.dart';
import 'multijugador_cubit.dart';
import 'multijugador_modelos.dart';
import 'pantalla_juego_multijugador.dart';
import 'pantalla_preparacion_multijugador.dart';

/// Punto de entrada de la UI multijugador. Decide qué pantalla mostrar según
/// el estado de la sala y muestra avisos (desconexiones, abandonos, errores).
///
/// [niveles]: número de nivel -> nombre para mostrar, p. ej. {1: 'Nivel 1', …}.
class MultijugadorFlujo extends StatelessWidget {
  const MultijugadorFlujo({super.key, required this.niveles});

  final Map<int, String> niveles;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MultijugadorCubit, MultijugadorState>(
      listenWhen: (a, b) => b.aviso != null && a.aviso != b.aviso,
      listener: (context, s) {
        final a = s.aviso!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(a.texto),
            backgroundColor: a.esError ? Theme.of(context).colorScheme.error : null,
          ));
      },
      builder: (context, s) {
        final sala = s.sala;
        final enPartida = sala != null &&
            (sala.status == RoomStatus.jugando || sala.status == RoomStatus.preparando);

        final Widget pantalla;
        if (sala == null) {
          pantalla = PaginaEntrada(niveles: niveles);
        } else {
          switch (sala.status) {
            case RoomStatus.lobby:
              pantalla = PaginaLobby(sala: sala, niveles: niveles);
            case RoomStatus.preparando:
              pantalla = Column(
                children: [
                  if (s.enlace != LinkStatus.conectado) const _BannerReconectando(),
                  if (!sala.me.active) const _BannerEspectador(),
                  Expanded(child: PantallaPreparacionMultijugador(sala: sala)),
                ],
              );
            case RoomStatus.jugando:
              pantalla = Column(
                children: [
                  if (s.enlace != LinkStatus.conectado) const _BannerReconectando(),
                  if (!sala.me.active) const _BannerEspectador(),
                  Expanded(child: PantallaJuegoMultijugador(sala: sala)),
                ],
              );
            case RoomStatus.terminada:
              pantalla = PaginaResultado(sala: sala);
          }
        }

        // Atrás en plena partida = abandonarla: se pide confirmación.
        return PopScope(
          canPop: !enPartida,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final salir = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¿Abandonar la partida?'),
                content: const Text('Saldrás de la sala y perderás tu lugar.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Seguir jugando'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Abandonar'),
                  ),
                ],
              ),
            );
            if (salir == true && context.mounted) {
              await context.read<MultijugadorCubit>().salir();
              if (context.mounted) Navigator.of(context).maybePop();
            }
          },
          child: pantalla,
        );
      },
    );
  }
}

class _BannerReconectando extends StatelessWidget {
  const _BannerReconectando();

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Conexión perdida. Reconectando…'),
            ],
          ),
        ),
      );
}

class _BannerEspectador extends StatelessWidget {
  const _BannerEspectador();

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ya no participas. Estás mirando la partida.'),
              TextButton(
                onPressed: () => context.read<MultijugadorCubit>().salir(),
                child: const Text('Salir'),
              ),
            ],
          ),
        ),
      );
}

// ───────────────────────── Entrada ─────────────────────────

class PaginaEntrada extends StatefulWidget {
  const PaginaEntrada({super.key, required this.niveles});
  final Map<int, String> niveles;

  @override
  State<PaginaEntrada> createState() => _PaginaEntradaState();
}

class _PaginaEntradaState extends State<PaginaEntrada> {
  final _codigo = TextEditingController();
  late int _nivel = widget.niveles.keys.first;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MultijugadorCubit>();
    final ocupado = context.select((MultijugadorCubit c) => c.state.ocupado);
    return Scaffold(
      appBar: AppBar(title: const Text('Multijugador')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ocupado) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Crear sala', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownMenu<int>(
            initialSelection: _nivel,
            label: const Text('Tablero'),
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => _nivel = v ?? _nivel),
            dropdownMenuEntries: [
              for (final e in widget.niveles.entries)
                DropdownMenuEntry(value: e.key, label: e.value),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: ocupado ? null : () => cubit.crearSala(nivel: _nivel),
            child: const Text('Crear sala'),
          ),
          const Divider(height: 48),
          Text('Unirse con código', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _codigo,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Código de 6 caracteres'),
            onChanged: (_) => setState(() {}),
          ),
          OutlinedButton(
            onPressed: ocupado || _codigo.text.trim().length != 6
                ? null
                : () => cubit.unirse(codigo: _codigo.text),
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Lobby ─────────────────────────

class PaginaLobby extends StatelessWidget {
  const PaginaLobby({super.key, required this.sala, required this.niveles});
  final RoomSnapshot sala;
  final Map<int, String> niveles;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MultijugadorCubit>();
    final enlace = context.select((MultijugadorCubit c) => c.state.enlace);
    final yo = sala.me;
    final resto = sala.players.where((p) => !p.isHost);
    final puedeIniciar = sala.amHost &&
        sala.players.length >= 2 &&
        sala.players.every((p) => p.connected) &&
        resto.every((p) => p.lobbyReady);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Salir de la sala',
          onPressed: cubit.salir,
        ),
      ),
      body: Column(
        children: [
          if (enlace != LinkStatus.conectado) const _BannerReconectando(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TarjetaCodigo(codigo: sala.code),
                const SizedBox(height: 16),
                if (sala.amHost)
                  DropdownMenu<int>(
                    key: ValueKey(sala.nivel),
                    initialSelection: sala.nivel,
                    label: const Text('Tablero (igual para todos)'),
                    expandedInsets: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v != null && v != sala.nivel) cubit.cambiarNivel(v);
                    },
                    dropdownMenuEntries: [
                      for (final e in niveles.entries)
                        DropdownMenuEntry(value: e.key, label: e.value),
                    ],
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.grid_view),
                    title: const Text('Tablero'),
                    subtitle: Text(niveles[sala.nivel] ?? 'Nivel ${sala.nivel}'),
                  ),
                const SizedBox(height: 16),
                Text('Jugadores (${sala.players.length}/6)',
                    style: Theme.of(context).textTheme.titleMedium),
                for (final p in sala.players) _FilaJugador(p: p, yo: p.id == yo.id),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: sala.amHost
                    ? FilledButton(
                        onPressed: puedeIniciar ? cubit.iniciarPartida : null,
                        child: Text(sala.players.length < 2
                            ? 'Esperando jugadores…'
                            : puedeIniciar
                                ? 'Iniciar partida'
                                : 'Esperando a que todos estén listos…'),
                      )
                    : FilledButton.tonal(
                        onPressed: () => cubit.marcarListoLobby(!yo.lobbyReady),
                        child: Text(yo.lobbyReady ? 'Quitar "listo"' : 'Estoy listo'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCodigo extends StatelessWidget {
  const _TarjetaCodigo({required this.codigo});
  final String codigo;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Código de invitación'),
              const SizedBox(height: 4),
              SelectableText(
                codigo,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(letterSpacing: 6, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.copy),
                label: const Text('Copiar invitación'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(
                    text: 'Únete a mi partida de Brillant con el código $codigo',
                  ));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitación copiada')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
}

class _FilaJugador extends StatelessWidget {
  const _FilaJugador({required this.p, required this.yo});
  final PlayerInfo p;
  final bool yo;

  @override
  Widget build(BuildContext context) {
    final estado = !p.connected
        ? 'Desconectado'
        : p.isHost
            ? 'Anfitrión'
            : p.lobbyReady
                ? 'Listo'
                : 'Esperando';
    return ListTile(
      leading: Icon(
        p.connected ? Icons.person : Icons.wifi_off,
        color: p.connected ? null : Theme.of(context).colorScheme.error,
      ),
      title: Text(yo ? '${p.name} (tú)' : p.name),
      trailing: Chip(label: Text(estado)),
    );
  }
}

// ───────────────────────── Resultado ─────────────────────────

class PaginaResultado extends StatelessWidget {
  const PaginaResultado({super.key, required this.sala});
  final RoomSnapshot sala;

  @override
  Widget build(BuildContext context) {
    final r = sala.result!;
    final String titulo;
    if (r.winnerIds.isEmpty) {
      titulo = 'Partida terminada';
    } else if (r.isTie) {
      titulo = 'Empate: ${r.winnerIds.map(sala.nameOf).join(', ')}';
    } else {
      titulo = sala.iWon ? '¡Ganaste!' : 'Ganó ${sala.nameOf(r.winnerIds.first)}';
    }
    final motivo = switch (r.reason) {
      'completed' => 'Llenó el tablero primero.',
      'last_standing' => 'Los demás se rindieron o abandonaron.',
      'no_moves' => 'Ya nadie tenía jugadas posibles.',
      _ => 'Todos abandonaron la partida.',
    };
    final totalCeldas = sala.grid.length * sala.grid.first.length;
    final ordenados = [...sala.players]
      ..sort((a, b) => (r.scores[b.id] ?? 0).compareTo(r.scores[a.id] ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado'), automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titulo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(motivo),
              const SizedBox(height: 24),
              for (final p in ordenados)
                ListTile(
                  title: Text(p.id == sala.youId ? '${p.name} (tú)' : p.name),
                  subtitle: Text('${r.scores[p.id] ?? 0} puntos · ${p.filled}/$totalCeldas celdas'),
                  trailing: r.winnerIds.contains(p.id) ? const Icon(Icons.emoji_events) : null,
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<MultijugadorCubit>().salir(),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
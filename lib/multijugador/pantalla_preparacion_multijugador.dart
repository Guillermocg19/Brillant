import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../celda_widget.dart';
import '../colores.dart';
import 'multijugador_cubit.dart';
import 'multijugador_modelos.dart';

/// Antes de la primera tirada, cada jugador decide dónde pone sus números
/// iniciales: el 1 al 6, una vez cada uno, en las 6 casillas con estrella.
///
/// Se elige un número y se toca una estrella. Tocar una estrella ya ocupada
/// recoge su número para moverlo. Las estrellas que admiten el número elegido
/// se resaltan (las reglas las decide el servidor). Al confirmar, esperas a que
/// todos terminen; hasta entonces puedes cambiar tus números.
class PantallaPreparacionMultijugador extends StatefulWidget {
  const PantallaPreparacionMultijugador({super.key, required this.sala});
  final RoomSnapshot sala;

  @override
  State<PantallaPreparacionMultijugador> createState() =>
      _PantallaPreparacionMultijugadorState();
}

class _PantallaPreparacionMultijugadorState
    extends State<PantallaPreparacionMultijugador> {
  /// índice de estrella -> número colocado (todavía sin confirmar).
  final Map<int, int> _asignado = {};
  int? _seleccion;

  @override
  void initState() {
    super.initState();
    _recuperarDelServidor();
  }

  /// Si ya habías confirmado (p. ej. cerraste la app y volviste), parte de eso.
  void _recuperarDelServidor() {
    final setup = widget.sala.setup;
    final board = widget.sala.board;
    if (setup == null || board.isEmpty) return;
    for (var i = 0; i < setup.stars.length; i++) {
      final v = board[setup.stars[i].x][setup.stars[i].y];
      if (v != null) _asignado[i] = v;
    }
  }

  void _tocarEstrella(int i, SetupInfo setup) {
    if (setup.confirmed) return;
    final sel = _seleccion;
    if (sel == null) {
      // Sin número elegido: tocar una estrella ocupada recoge su número.
      final puesto = _asignado.remove(i);
      if (puesto != null) setState(() => _seleccion = puesto);
      return;
    }
    if (!setup.allowed[i].contains(sel)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('El $sel no puede ir en esa zona. Prueba en otra estrella.'),
        ));
      return;
    }
    setState(() {
      _asignado.removeWhere((_, v) => v == sel); // un número solo puede estar una vez
      _asignado[i] = sel;
      _seleccion = null;
    });
  }

  /// Reparte el 1 al 6 al azar respetando lo que admite cada estrella
  /// (p. ej. nivel 4: naranja de arriba solo 4-6, la de abajo solo 1-3).
  /// Usa vuelta atrás: prueba un número, y si más adelante no hay forma de
  /// completar, retrocede y prueba otro; así nunca se queda atascado.
  void _alAzar() {
    final setup = widget.sala.setup;
    if (setup == null || setup.confirmed) return;
    final azar = Random();
    final n = setup.stars.length;
    final usados = <int>{};
    final resultado = <int, int>{};

    bool resolver(int i) {
      if (i == n) return true;
      final candidatos = setup.allowed[i].toList()..shuffle(azar);
      for (final v in candidatos) {
        if (usados.contains(v)) continue;
        usados.add(v);
        resultado[i] = v;
        if (resolver(i + 1)) return true;
        usados.remove(v);
        resultado.remove(i);
      }
      return false;
    }

    if (resolver(0)) {
      setState(() {
        _asignado
          ..clear()
          ..addAll(resultado);
        _seleccion = null;
      });
    }
  }

  Future<void> _confirmarRendirse() async {
    final cubit = context.read<MultijugadorCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Conceder la partida?'),
        content: const Text('Dejarás de jugar, pero podrás seguir mirando.'),
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
    final setup = sala.setup;
    final cubit = context.read<MultijugadorCubit>();
    if (setup == null) return const SizedBox.shrink();

    final yo = sala.me;
    final total = setup.stars.length;
    final completo = _asignado.length == total;
    final activos = sala.players.where((p) => p.active).toList();
    final listos = activos.where((p) => p.setupReady).length;

    final String mensaje;
    if (!yo.active) {
      mensaje = 'Estás mirando la partida.';
    } else if (setup.confirmed) {
      mensaje = 'Listo. Esperando a los demás ($listos/${activos.length}).';
    } else if (_seleccion != null) {
      mensaje = 'Toca una estrella resaltada para colocar el $_seleccion.';
    } else if (completo) {
      mensaje = 'Todos colocados. Confirma, o toca un número para moverlo.';
    } else {
      mensaje = 'Elige un número y toca una estrella ★ para colocarlo '
          '(${_asignado.length}/$total), o usa "Al azar".';
    }

    final editable = yo.active && !setup.confirmed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepara tu tablero'),
        actions: [
          if (yo.active)
            IconButton(
              tooltip: 'Conceder',
              icon: const Icon(Icons.flag_outlined),
              onPressed: _confirmarRendirse,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Preparados(jugadores: sala.players, yoId: sala.youId),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var n = 1; n <= 6; n++)
                    _NumeroPaleta(
                      key: ValueKey('numero_$n'),
                      numero: n,
                      seleccionado: _seleccion == n,
                      colocado: _asignado.containsValue(n),
                      onTap: editable
                          ? () => setState(
                                () => _seleccion = _seleccion == n ? null : n,
                              )
                          : null,
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
                        itemBuilder: (context, k) {
                          final f = k ~/ columnas;
                          final c = k % columnas;
                          final idx = setup.stars.indexOf(Point(f, c));
                          final esEstrella = idx >= 0;
                          // Confirmado: lo que dice el servidor. Si no: lo local.
                          final int? valor = !esEstrella
                              ? null
                              : (setup.confirmed
                                  ? (sala.board.isEmpty ? null : sala.board[f][c])
                                  : _asignado[idx]);
                          final resaltada = esEstrella &&
                              editable &&
                              (_seleccion == null || setup.allowed[idx].contains(_seleccion));
                          final Widget celda = CeldaTablero(
                            key: ValueKey('celda_${f}_$c'),
                            color: sala.grid[f][c],
                            valor: valor,
                            resaltada: resaltada,
                            onTap: esEstrella && editable
                                ? () => _tocarEstrella(idx, setup)
                                : null,
                          );
                          if (esEstrella) {
                            // Estrella: marco dorado con brillo (más si aún está vacía).
                            return _MarcoEstrella(
                              vacia: valor == null,
                              activa: editable &&
                                  (_seleccion == null ||
                                      setup.allowed[idx].contains(_seleccion)),
                              atenuada: editable &&
                                  _seleccion != null &&
                                  !setup.allowed[idx].contains(_seleccion),
                              hijo: celda,
                            );
                          }
                          // El resto del tablero se apaga mientras eliges, para
                          // que se vea dónde van los números.
                          return setup.confirmed
                              ? celda
                              : Opacity(opacity: 0.45, child: celda);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (yo.active)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: setup.confirmed
                    ? OutlinedButton.icon(
                        key: const ValueKey('boton_cambiar'),
                        icon: const Icon(Icons.edit),
                        label: const Text('Cambiar mis números'),
                        onPressed: cubit.editarPreparacion,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('boton_azar'),
                              icon: const Icon(Icons.casino_outlined),
                              label: const Text('Al azar'),
                              onPressed: _alAzar,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              key: const ValueKey('boton_confirmar'),
                              icon: const Icon(Icons.check),
                              label: const Text('Confirmar'),
                              onPressed: completo
                                  ? () => cubit.confirmarPreparacion([
                                        for (var i = 0; i < total; i++) _asignado[i]!,
                                      ])
                                  : null,
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Marco dorado con brillo pulsante alrededor de una estrella, para que las
/// casillas donde van los números iniciales destaquen sobre el resto.
class _MarcoEstrella extends StatefulWidget {
  const _MarcoEstrella({
    required this.hijo,
    required this.vacia,
    required this.activa,
    required this.atenuada,
  });

  final Widget hijo;

  /// Todavía no tiene número: se dibuja una estrella encima.
  final bool vacia;

  /// Se puede tocar ahora: el brillo pulsa.
  final bool activa;

  /// Hay un número elegido que esta estrella no admite: se apaga.
  final bool atenuada;

  @override
  State<_MarcoEstrella> createState() => _MarcoEstrellaState();
}

class _MarcoEstrellaState extends State<_MarcoEstrella>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _actualizarAnimacion();
  }

  @override
  void didUpdateWidget(_MarcoEstrella anterior) {
    super.didUpdateWidget(anterior);
    _actualizarAnimacion();
  }

  void _actualizarAnimacion() {
    if (widget.activa) {
      if (!_pulso.isAnimating) _pulso.repeat(reverse: true);
    } else {
      _pulso.stop();
      _pulso.value = 0.5;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulso,
      builder: (context, hijo) {
        final t = _pulso.value;
        final color = widget.atenuada ? Colors.grey : Colors.amber.shade700;
        return Stack(
          fit: StackFit.expand,
          children: [
            hijo!,
            // El marco no intercepta toques: pasan a la celda de abajo.
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: widget.atenuada ? 2 : 3.5),
                  boxShadow: widget.atenuada
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.30 + 0.40 * t),
                            blurRadius: 5 + 9 * t,
                            spreadRadius: 1 + 2 * t,
                          ),
                        ],
                ),
                child: widget.vacia
                    ? Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.55,
                          heightFactor: 0.55,
                          child: FittedBox(
                            child: Icon(
                              Icons.star_rounded,
                              color: Colors.white.withOpacity(widget.atenuada ? 0.35 : 0.95),
                              shadows: const [
                                Shadow(color: Colors.black38, blurRadius: 3),
                              ],
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
      child: widget.hijo,
    );
  }
}

/// Quién ya confirmó sus números.
class _Preparados extends StatelessWidget {
  const _Preparados({required this.jugadores, required this.yoId});
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
                    : p.setupReady
                        ? const Icon(Icons.check_circle, size: 16, color: Colors.green)
                        : const Icon(Icons.hourglass_empty, size: 16),
            label: Text(
              p.id == yoId ? 'Tú' : p.name,
              style: TextStyle(
                decoration: p.active ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }
}

class _NumeroPaleta extends StatelessWidget {
  const _NumeroPaleta({
    super.key,
    required this.numero,
    required this.seleccionado,
    required this.colocado,
    required this.onTap,
  });

  final int numero;
  final bool seleccionado;

  /// Ya está puesto en alguna estrella (se puede volver a elegir para moverlo).
  final bool colocado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : (colocado && !seleccionado ? 0.45 : 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
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
              '$numero',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: seleccionado ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
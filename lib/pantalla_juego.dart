import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'juego.dart';
import 'juego_bloc.dart';
import 'colores.dart';
import 'celda_widget.dart';

/// Pantalla del juego: los dados se tiran solos; el jugador elige uno
/// como ANCLA y coloca el otro junto a un número igual al ancla. Si con
/// la tirada no hay jugada posible, los dados se vuelven a tirar solos.
/// También puede pasar el turno si no quiere colocar ninguno.
class PantallaJuego extends StatelessWidget {
  final TableroJuego tableroJuego;

  /// Solo para pruebas: permite controlar los dados.
  final Random? random;

  const PantallaJuego({super.key, required this.tableroJuego, this.random});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JuegoBloc(tableroJuego, random: random),
      child: const _VistaJuego(),
    );
  }
}

class _VistaJuego extends StatelessWidget {
  const _VistaJuego();

  /// 'ancla' en el dado elegido, 'a colocar' en el otro, null si aún no
  /// elige. Con dados iguales el primero hace de ancla.
  static String? _etiqueta(JuegoState s, int indice) {
    final sel = s.numeroSeleccionado;
    if (sel == null) return null;
    final esAncla = indice == 1
        ? sel == s.dado1
        : (sel == s.dado2 && s.dado1 != s.dado2);
    return esAncla ? 'ancla' : 'a colocar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brillant')),
      body: BlocBuilder<JuegoBloc, JuegoState>(
        builder: (context, state) {
          final filas = state.tablero.filas;
          final columnas = state.tablero.columnas;
          final celdasValidas = state.celdasValidas;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Marcador(puntos: state.puntuacion),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    state.mensaje,
                    key: ValueKey(state.mensaje),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const LeyendaColores(),
                const SizedBox(height: 14),
                if (!state.terminado &&
                    state.dado1 != null &&
                    state.dado2 != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DadoBoton(
                        key: const ValueKey('dado_1'),
                        valor: state.dado1!,
                        etiqueta: _etiqueta(state, 1),
                        seleccionado: _etiqueta(state, 1) == 'ancla',
                        onTap: () => context
                            .read<JuegoBloc>()
                            .add(ElegirNumero(state.dado1!)),
                      ),
                      const SizedBox(width: 10),
                      _DadoBoton(
                        key: const ValueKey('dado_2'),
                        valor: state.dado2!,
                        etiqueta: _etiqueta(state, 2),
                        seleccionado: _etiqueta(state, 2) == 'ancla',
                        onTap: () => context
                            .read<JuegoBloc>()
                            .add(ElegirNumero(state.dado2!)),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        key: const ValueKey('boton_pasar'),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Pasar'),
                        onPressed: () =>
                            context.read<JuegoBloc>().add(PasarTurno()),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lado =
                          constraints.maxWidth < constraints.maxHeight
                              ? constraints.maxWidth
                              : constraints.maxHeight;

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
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columnas,
                              crossAxisSpacing: 3,
                              mainAxisSpacing: 3,
                            ),
                            itemBuilder: (context, i) {
                              final f = i ~/ columnas;
                              final c = i % columnas;
                              final celda = state.tablero.celdaEn(f, c);
                              final color =
                                  state.tablero.colorPorZona[celda.zonaId]!;
                              final esValida =
                                  celdasValidas.contains(Point(f, c));

                              return CeldaTablero(
                                key: ValueKey('celda_${f}_$c'),
                                color: color,
                                valor: celda.valor,
                                resaltada: esValida,
                                onTap: !esValida
                                    ? null
                                    : () => context
                                        .read<JuegoBloc>()
                                        .add(ColocarNumero(Point(f, c))),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (state.terminado) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '¡Partida terminada! Puntuación final: ${state.puntuacion}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Marcador de puntos: el número "salta" cada vez que cambia.
class _Marcador extends StatelessWidget {
  final int puntos;

  const _Marcador({required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Text(
            '$puntos puntos',
            key: ValueKey(puntos),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DadoBoton extends StatelessWidget {
  final int valor;
  final bool seleccionado;
  final String? etiqueta;
  final VoidCallback onTap;

  const _DadoBoton({
    super.key,
    required this.valor,
    required this.seleccionado,
    required this.onTap,
    this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  color: seleccionado
                      ? Colors.indigo.shade700
                      : Colors.grey.shade300,
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
    );
  }
}
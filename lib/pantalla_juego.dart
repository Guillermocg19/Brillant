import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'juego.dart';
import 'juego_bloc.dart';
import 'colores.dart';

/// Pantalla del juego: tirar dados, elegir uno de los dos números y
/// colocarlo en cualquier celda válida (adyacente + regla de la zona).
class PantallaJuego extends StatelessWidget {
  final TableroJuego tableroJuego;

  const PantallaJuego({super.key, required this.tableroJuego});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JuegoBloc(tableroJuego),
      child: const _VistaJuego(),
    );
  }
}

class _VistaJuego extends StatelessWidget {
  const _VistaJuego();

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
                Text(
                  state.mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const LeyendaColores(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.casino),
                      label: const Text('Lanzar dados'),
                      onPressed: (state.terminado ||
                              state.numeroSeleccionado != null)
                          ? null
                          : () => context.read<JuegoBloc>().add(LanzarDados()),
                    ),
                    const SizedBox(width: 16),
                    if (state.dado1 != null && state.dado2 != null) ...[
                      _DadoBoton(
                        valor: state.dado1!,
                        seleccionado: state.numeroSeleccionado == state.dado1,
                        onTap: () => context
                            .read<JuegoBloc>()
                            .add(ElegirNumero(state.dado1!)),
                      ),
                      const SizedBox(width: 8),
                      _DadoBoton(
                        valor: state.dado2!,
                        seleccionado: state.numeroSeleccionado == state.dado2,
                        onTap: () => context
                            .read<JuegoBloc>()
                            .add(ElegirNumero(state.dado2!)),
                      ),
                    ],
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
                        child: SizedBox(
                          width: lado,
                          height: lado,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filas * columnas,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columnas,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemBuilder: (context, i) {
                              final f = i ~/ columnas;
                              final c = i % columnas;
                              final celda = state.tablero.celdaEn(f, c);
                              final color =
                                  state.tablero.colorPorZona[celda.zonaId]!;
                              final esValida =
                                  celdasValidas.contains(Point(f, c));

                              return GestureDetector(
                                key: ValueKey('celda_${f}_$c'),
                                onTap: !esValida
                                    ? null
                                    : () => context
                                        .read<JuegoBloc>()
                                        .add(ColocarNumero(Point(f, c))),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorDeRegion(color),
                                    border: Border.all(
                                      color: esValida
                                          ? Colors.blue
                                          : Colors.black26,
                                      width: esValida ? 3 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: celda.valor != null
                                        ? Text(
                                            '${celda.valor}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
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
                  const Text(
                    '¡Partida terminada!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

class _DadoBoton extends StatelessWidget {
  final int valor;
  final bool seleccionado;
  final VoidCallback onTap;

  const _DadoBoton({
    required this.valor,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: seleccionado ? Colors.indigo.shade200 : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$valor',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tablero.dart';
import 'valores_iniciales_bloc.dart';
import 'colores.dart';

/// Pantalla previa al juego: el jugador coloca los números 1-6
/// (sin repetir) en las casillas con estrella. Toda la lógica de
/// selección/colocación vive en ValoresInicialesBloc; esta clase
/// solo arma la UI y despacha eventos.
class PantallaValoresIniciales extends StatelessWidget {
  final List<List<ColorRegion>> tablero;
  final Set<Point<int>> estrellas;
  final void Function(Map<Point<int>, int> valoresIniciales) alContinuar;

  const PantallaValoresIniciales({
    super.key,
    required this.tablero,
    required this.estrellas,
    required this.alContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ValoresInicialesBloc(estrellas),
      child: _Vista(tablero: tablero, alContinuar: alContinuar),
    );
  }
}

class _Vista extends StatelessWidget {
  final List<List<ColorRegion>> tablero;
  final void Function(Map<Point<int>, int>) alContinuar;

  const _Vista({required this.tablero, required this.alContinuar});

  @override
  Widget build(BuildContext context) {
    final filas = tablero.length;
    final columnas = tablero[0].length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coloca los valores iniciales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Colocar al azar',
            onPressed: () =>
                context.read<ValoresInicialesBloc>().add(ColocarAleatorio()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar',
            onPressed: () =>
                context.read<ValoresInicialesBloc>().add(Reiniciar()),
          ),
        ],
      ),
      body: BlocBuilder<ValoresInicialesBloc, ValoresInicialesState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Toca un número y luego una casilla marcada con ✦ para '
                  'colocarlo ahí, o usa el botón de mezclar para repartirlos '
                  'al azar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const LeyendaColores(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: state.numerosDisponibles.map((n) {
                    final seleccionado = state.numeroSeleccionado == n;
                    return ChoiceChip(
                      label: Text('$n'),
                      selected: seleccionado,
                      onSelected: (_) => context
                          .read<ValoresInicialesBloc>()
                          .add(SeleccionarNumero(n)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lado = constraints.maxWidth < constraints.maxHeight
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
                              final pos = Point(f, c);
                              final color = tablero[f][c];
                              final esEstrella =
                                  state.estrellas.contains(pos);
                              final valor = state.valores[pos];

                              // Jugable ahora mismo: es estrella, sigue
                              // vacía, y hay un número en mano para poner.
                              final esJugable = esEstrella &&
                                  valor == null &&
                                  state.numeroSeleccionado != null;

                              final Color colorBorde;
                              final double grosorBorde;
                              if (esJugable) {
                                colorBorde = Colors.blue;
                                grosorBorde = 3;
                              } else if (esEstrella) {
                                colorBorde = Colors.black;
                                grosorBorde = 2.5;
                              } else {
                                colorBorde = Colors.black26;
                                grosorBorde = 1;
                              }

                              return GestureDetector(
                                key: ValueKey('celda_${f}_$c'),
                                onTap: !esEstrella
                                    ? null
                                    : () => context
                                        .read<ValoresInicialesBloc>()
                                        .add(TocarCelda(pos)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorDeRegion(color),
                                    border: Border.all(
                                      color: colorBorde,
                                      width: grosorBorde,
                                    ),
                                  ),
                                  child: Center(
                                    child: valor != null
                                        ? Text(
                                            '$valor',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          )
                                        : (esEstrella
                                            ? const Text('✦',
                                                style:
                                                    TextStyle(fontSize: 18))
                                            : null),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.listo
                        ? () => alContinuar(state.valores)
                        : null,
                    child: Text(state.listo
                        ? 'Inicio'
                        : 'Coloca los ${state.estrellas.length - state.valores.length} valores restantes'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
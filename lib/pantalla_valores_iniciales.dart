import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tablero.dart';
import 'valores_iniciales_bloc.dart';
import 'colores.dart';
import 'celda_widget.dart';

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
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text('Coloca los valores iniciales'),
        centerTitle: true,
        elevation: 0,
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
                Text(
                  'Toca un número y luego una casilla marcada con ✦ para '
                  'colocarlo ahí, o usa el botón de mezclar para repartirlos '
                  'al azar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 10),
                const LeyendaColores(),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: state.numerosDisponibles.map((n) {
                    final seleccionado = state.numeroSeleccionado == n;
                    return ChoiceChip(
                      label: Text('$n'),
                      selected: seleccionado,
                      selectedColor: Colors.indigo.shade400,
                      labelStyle: TextStyle(
                        color: seleccionado ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
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
                              final pos = Point(f, c);
                              final color = tablero[f][c];
                              final esEstrella =
                                  state.estrellas.contains(pos);
                              final valor = state.valores[pos];

                              final esJugable = esEstrella &&
                                  valor == null &&
                                  state.numeroSeleccionado != null;

                              return CeldaTablero(
                                key: ValueKey('celda_${f}_$c'),
                                color: color,
                                valor: valor,
                                mostrarEstrella: esEstrella,
                                resaltada: esJugable,
                                onTap: !esEstrella
                                    ? null
                                    : () => context
                                        .read<ValoresInicialesBloc>()
                                        .add(TocarCelda(pos)),
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
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
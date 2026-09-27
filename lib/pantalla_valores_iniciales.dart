import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tablero.dart';
import 'valores_iniciales_bloc.dart';
import 'valores_iniciales_event.dart';
import 'valores_iniciales_state.dart';

/// Pantalla previa al juego: el jugador debe colocar los números 1-6
/// (cada uno una sola vez) en las 6 casillas marcadas con estrella.
/// Requiere que un ValoresInicialesBloc ya esté provisto arriba en el
/// árbol (ver main.dart).
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

  Color _colorDe(ColorRegion c) {
    switch (c) {
      case ColorRegion.amarillo:
        return const Color(0xFFFDD835);
      case ColorRegion.verde:
        return const Color(0xFF66BB6A);
      case ColorRegion.morado:
        return const Color(0xFFBA68C8);
      case ColorRegion.azul:
        return const Color(0xFF4FC3F7);
      case ColorRegion.rojo:
        return const Color(0xFFE57373);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filas = tablero.length;
    final columnas = tablero[0].length;

    return Scaffold(
      appBar: AppBar(title: const Text('Coloca los valores iniciales')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<ValoresInicialesBloc, ValoresInicialesState>(
            builder: (context, state) {
              final listo = state.listo(estrellas.length);
              return Column(
                children: [
                  const Text(
                    'Toca un número y luego una casilla marcada con ✦ para '
                    'colocarlo ahí. Cada número del 1 al 6 se usa una sola vez.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildChips(context, state),
                  const SizedBox(height: 16),
                  // El tablero ocupa el menor entre ancho y alto
                  // disponibles, así nunca se desborda.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final lado =
                            min(constraints.maxWidth, constraints.maxHeight);
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
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, i) =>
                                  _buildCelda(context, state, i, columnas),
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
                      onPressed:
                          listo ? () => alContinuar(state.valores) : null,
                      child: Text(listo
                          ? 'Inicio'
                          : 'Coloca los ${estrellas.length - state.valores.length} valores restantes'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChips(BuildContext context, ValoresInicialesState state) {
    final disponibles = state.numerosDisponibles;
    if (disponibles.isEmpty) {
      return const Text(
        'Todos los números están colocados ✓',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: disponibles.map((n) {
        final seleccionado = state.numeroSeleccionado == n;
        return ChoiceChip(
          label: Text('$n'),
          selected: seleccionado,
          onSelected: (_) =>
              context.read<ValoresInicialesBloc>().add(SeleccionarNumero(n)),
        );
      }).toList(),
    );
  }

  Widget _buildCelda(
    BuildContext context,
    ValoresInicialesState state,
    int i,
    int columnas,
  ) {
    final f = i ~/ columnas;
    final c = i % columnas;
    final pos = Point(f, c);
    final color = tablero[f][c];
    final esEstrella = estrellas.contains(pos);
    final valor = state.valores[pos];

    return GestureDetector(
      key: ValueKey('celda_${f}_$c'),
      onTap: esEstrella
          ? () => context.read<ValoresInicialesBloc>().add(TocarEstrella(pos))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: _colorDe(color),
          border: Border.all(color: Colors.black.withOpacity(0.35), width: 1),
        ),
        child: Center(
          child: valor != null
              ? Text(
                  '$valor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                )
              : (esEstrella
                  ? const Text('✦', style: TextStyle(fontSize: 18))
                  : null),
        ),
      ),
    );
  }
}
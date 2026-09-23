import 'dart:math';
import 'package:flutter/material.dart';
import 'tablero.dart';

/// Pantalla previa al juego: el jugador debe colocar los números 1-6
/// (cada uno una sola vez) en las 6 casillas marcadas con estrella.
/// El botón de continuar queda BLOQUEADO (estado local, sin paquetes
/// externos) hasta que las 6 estrellas tengan un valor.
class PantallaValoresIniciales extends StatefulWidget {
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
  State<PantallaValoresIniciales> createState() =>
      _PantallaValoresInicialesState();
}

class _PantallaValoresInicialesState extends State<PantallaValoresIniciales> {
  final Map<Point<int>, int> _valores = {};
  int? _numeroSeleccionado;

  List<int> get _numerosDisponibles {
    final usados = _valores.values.toSet();
    return [1, 2, 3, 4, 5, 6].where((n) => !usados.contains(n)).toList();
  }

  bool get _listo => _valores.length == widget.estrellas.length;

  void _seleccionarNumero(int n) {
    setState(() => _numeroSeleccionado = n);
  }

  void _tocarEstrella(Point<int> pos) {
    if (_numeroSeleccionado == null) return;
    setState(() {
      _valores[pos] = _numeroSeleccionado!;
      _numeroSeleccionado = null;
    });
  }

  void _quitarValor(Point<int> pos) {
    setState(() => _valores.remove(pos));
  }

  Color _colorDe(ColorRegion c) {
    switch (c) {
      case ColorRegion.amarillo:
        return Colors.yellow.shade600;
      case ColorRegion.verde:
        return Colors.green.shade400;
      case ColorRegion.morado:
        return Colors.purple.shade300;
      case ColorRegion.azul:
        return Colors.lightBlue.shade400;
      case ColorRegion.rojo:
        return Colors.red.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filas = widget.tablero.length;
    final columnas = widget.tablero[0].length;

    return Scaffold(
      appBar: AppBar(title: const Text('Coloca los valores iniciales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Toca un número y luego una casilla marcada con ✦ para '
              'colocarlo ahí. Cada número del 1 al 6 se usa una sola vez.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _numerosDisponibles.map((n) {
                final seleccionado = _numeroSeleccionado == n;
                return ChoiceChip(
                  label: Text('$n'),
                  selected: seleccionado,
                  onSelected: (_) => _seleccionarNumero(n),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: filas * columnas,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemBuilder: (context, i) {
                  final f = i ~/ columnas;
                  final c = i % columnas;
                  final pos = Point(f, c);
                  final color = widget.tablero[f][c];
                  final esEstrella = widget.estrellas.contains(pos);
                  final valor = _valores[pos];

                  return GestureDetector(
                    // Key única por celda: así las pruebas (y cualquier
                    // código que necesite ubicar una celda exacta) no
                    // dependen de "cuál GestureDetector encontré primero".
                    key: ValueKey('celda_${f}_$c'),
                    onTap: !esEstrella
                        ? null
                        : (valor == null
                            ? () => _tocarEstrella(pos)
                            : () => _quitarValor(pos)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorDe(color),
                        border: Border.all(
                          color: esEstrella ? Colors.black : Colors.black26,
                          width: esEstrella ? 2.5 : 1,
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
                                ? const Text('✦', style: TextStyle(fontSize: 18))
                                : null),
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
                onPressed: _listo
                    ? () => widget.alContinuar(_valores)
                    : null,
                child: Text(_listo
                    ? 'Continuar'
                    : 'Coloca los ${widget.estrellas.length - _valores.length} valores restantes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
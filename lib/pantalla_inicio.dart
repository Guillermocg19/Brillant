import 'package:flutter/material.dart';
import 'tablero.dart';
import 'colores.dart';
import 'transiciones.dart';
import 'pantalla_valores_iniciales.dart';
import 'pantalla_juego.dart';
import 'juego.dart';

/// Pantalla de bienvenida: el nombre del juego, una cuadrícula
/// decorativa con los colores del tablero, y el botón para empezar.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const _MosaicoDecorativo(),
              const SizedBox(height: 32),
              const Text(
                'Brillant',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lanza, piensa y apunta alto',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Jugar'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      rutaConTransicion(
                        PantallaValoresIniciales(
                          tablero: tableroNivel1,
                          estrellas: estrellasNivel1,
                          alContinuar: (valoresIniciales) {
                            final juego = TableroJuego.iniciar(
                              tableroNivel1,
                              valoresIniciales,
                            );
                            Navigator.push(
                              context,
                              rutaConTransicion(
                                PantallaJuego(tableroJuego: juego),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pequeño mosaico de cuadritos de colores, solo decorativo, usando
/// la misma paleta que el tablero real para que se sienta coherente
/// desde el primer segundo que se abre la app.
class _MosaicoDecorativo extends StatelessWidget {
  const _MosaicoDecorativo();

  @override
  Widget build(BuildContext context) {
    const patron = [
      ColorRegion.amarillo, ColorRegion.verde, ColorRegion.azul, ColorRegion.morado,
      ColorRegion.rojo, ColorRegion.morado, ColorRegion.verde, ColorRegion.amarillo,
      ColorRegion.azul, ColorRegion.rojo, ColorRegion.amarillo, ColorRegion.verde,
      ColorRegion.morado, ColorRegion.azul, ColorRegion.rojo, ColorRegion.verde,
    ];

    return SizedBox(
      width: 160,
      height: 160,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: patron.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (context, i) {
          return Container(
            decoration: BoxDecoration(
              color: colorDeRegion(patron[i]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'tablero.dart';
import 'colores.dart';

/// Celda visual compartida entre la pantalla de valores iniciales y
/// la pantalla de juego, para que ambas se vean consistentes.
class CeldaTablero extends StatelessWidget {
  final ColorRegion color;
  final int? valor;
  final bool resaltada;
  final bool mostrarEstrella;
  final VoidCallback? onTap;

  const CeldaTablero({
    super.key,
    required this.color,
    this.valor,
    this.resaltada = false,
    this.mostrarEstrella = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorFondo = colorDeRegion(color);
    final colorTexto = colorTextoSobre(color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: resaltada ? Colors.white : Colors.black.withOpacity(0.15),
            width: resaltada ? 3 : 1,
          ),
          boxShadow: [
            if (resaltada)
              BoxShadow(
                color: colorFondo.withOpacity(0.7),
                blurRadius: 10,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Símbolo de la regla en la esquina, discreto.
            Positioned(
              top: 3,
              left: 4,
              child: Text(
                simboloDeRegion(color),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: colorTexto.withOpacity(0.45),
                ),
              ),
            ),
            Center(
              child: valor != null
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.elasticOut,
                      builder: (context, escala, child) => Transform.scale(
                        scale: escala,
                        child: child,
                      ),
                      child: Text(
                        '$valor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorTexto,
                        ),
                      ),
                    )
                  : (mostrarEstrella
                      ? Text(
                          '✦',
                          style: TextStyle(fontSize: 18, color: colorTexto),
                        )
                      : null),
            ),
          ],
        ),
      ),
    );
  }
}
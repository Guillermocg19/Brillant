import 'package:flutter/material.dart';

/// Ruta con una transición suave (fundido + deslizado desde la
/// derecha), para usar en vez de MaterialPageRoute en toda la app.
Route<T> rutaConTransicion<T>(Widget pantalla) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) => pantalla,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curva = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curva),
          child: child,
        ),
      );
    },
  );
}
import 'package:flutter/material.dart';
import 'tablero.dart';
import 'juego.dart';
import 'pantalla_valores_iniciales.dart';

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PantallaValoresIniciales(
        tablero: tableroNivel1,
        estrellas: estrellasNivel1,
        alContinuar: (valoresIniciales) {
          // Aquí ya tienes el TableroJuego real, con las 6 estrellas
          // precargadas y listo para empezar a tirar dados.
          final juego = TableroJuego.iniciar(tableroNivel1, valoresIniciales);

          // Siguiente paso: navegar a la pantalla del juego pasándole `juego`.
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => PantallaJuego(tableroJuego: juego),
          // ));
        },
      ),
    );
  }
}
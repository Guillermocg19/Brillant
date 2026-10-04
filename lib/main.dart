import 'package:flutter/material.dart';
import 'tablero.dart';
import 'juego.dart';
import 'pantalla_valores_iniciales.dart';
import 'pantalla_juego.dart';

void main() => runApp(const BrillantApp());

class BrillantApp extends StatelessWidget {
  const BrillantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brillant',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Builder(
        builder: (context) => PantallaValoresIniciales(
          tablero: tableroNivel1,
          estrellas: estrellasNivel1,
          alContinuar: (valoresIniciales) {
            final juego = TableroJuego.iniciar(tableroNivel1, valoresIniciales);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PantallaJuego(tableroJuego: juego),
              ),
            );
          },
        ),
      ),
    );
  }
}
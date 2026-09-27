import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tablero.dart';
import 'pantalla_valores_iniciales.dart';
import 'valores_iniciales_bloc.dart';

void main() => runApp(const BrillantApp());

class BrillantApp extends StatelessWidget {
  const BrillantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brillant',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: BlocProvider(
        create: (_) => ValoresInicialesBloc(),
        child: PantallaValoresIniciales(
          tablero: tableroNivel1,
          estrellas: estrellasNivel1,
          alContinuar: (valoresIniciales) {
            // Aquí seguiría la lógica para arrancar la partida
            // usando los valores que el jugador colocó.
            debugPrint('Valores iniciales: $valoresIniciales');
          },
        ),
      ),
    );
  }
}
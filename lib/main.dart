import 'package:flutter/material.dart';
import 'tema.dart';
import 'pantalla_inicio.dart';

void main() => runApp(const BrillantApp());

class BrillantApp extends StatelessWidget {
  const BrillantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brillant',
      debugShowCheckedModeBanner: false,
      theme: temaBrillant,
      home: const PantallaInicio(),
    );
  }
}
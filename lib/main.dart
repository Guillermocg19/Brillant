import 'package:flutter/material.dart';
import 'tema.dart';
import 'pantalla_inicio.dart';
import 'auth/servicio_auth.dart';
import 'auth/pantalla_acceso.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(BrillantApp(auth: ServicioAuth()..restaurarSesion()));
}

class BrillantApp extends StatelessWidget {
  const BrillantApp({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brillant',
      debugShowCheckedModeBanner: false,
      theme: temaBrillant,
      // Se vuelve a dibujar cada vez que alguien entra o sale de su cuenta.
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          if (auth.iniciando) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (auth.usuario == null) return PantallaAcceso(auth: auth);
          return PantallaInicio(auth: auth);
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'multijugador_cliente.dart';
import 'multijugador_cubit.dart';
import 'multijugador_paginas.dart';

/// Botón que abre el multijugador. Ponlo en tu pantalla de inicio, al lado de "Jugar":
///
///   BotonMultijugador(tokenProvider: () => servicioAuth.token)
///
/// [tokenProvider] debe devolver el token de tu ServicioAuth (null si no hay sesión).
class BotonMultijugador extends StatelessWidget {
  const BotonMultijugador({super.key, required this.tokenProvider});

  final String? Function() tokenProvider;

  static const _niveles = {
    1: 'Nivel 1',
    2: 'Nivel 2',
    3: 'Nivel 3',
    4: 'Nivel 4',
  };

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.groups),
      label: const Text('Multijugador'),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => MultijugadorCubit(
                cliente: MultijugadorCliente(),
                tokenProvider: tokenProvider,
              )..reanudar(),
              child: const MultijugadorFlujo(niveles: _niveles),
            ),
          ),
        );
      },
    );
  }
}
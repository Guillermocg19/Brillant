import 'dart:math';
import 'package:equatable/equatable.dart';

abstract class ValoresInicialesEvent extends Equatable {
  const ValoresInicialesEvent();

  @override
  List<Object?> get props => [];
}

/// El jugador tocó un chip de número (para seleccionarlo o
/// deseleccionarlo si ya estaba elegido).
class SeleccionarNumero extends ValoresInicialesEvent {
  final int numero;
  const SeleccionarNumero(this.numero);

  @override
  List<Object?> get props => [numero];
}

/// El jugador tocó una casilla con estrella: coloca el número
/// seleccionado ahí, o lo quita si ya tenía un valor.
class TocarEstrella extends ValoresInicialesEvent {
  final Point<int> posicion;
  const TocarEstrella(this.posicion);

  @override
  List<Object?> get props => [posicion];
}
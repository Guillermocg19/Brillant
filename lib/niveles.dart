import 'dart:math';
import 'tablero.dart';
import 'juego.dart';


// Abreviaturas para que cada tablero se lea casi como el físico.
const _am = ColorRegion.amarillo;
const _ve = ColorRegion.verde;
const _mo = ColorRegion.morado;
const _az = ColorRegion.azul;
const _ro = ColorRegion.rojo;
const _gr = ColorRegion.gris; // "=" (todos iguales)
const _alto = ColorRegion.naranjaAlto; // solo 4 a 6
const _bajo = ColorRegion.naranjaBajo; // solo 1 a 3

/// Un nivel del juego: su tablero y las casillas con estrella.
class Nivel {
  final int numero;
  final List<List<ColorRegion>> tablero;
  final Set<Point<int>> estrellas;

  /// [1.º, 2.º, 3.º] lugar en completar una zona de ese color.
  final Map<ColorRegion, List<int>> puntos;

  /// Colores cuyas casillas cuentan como UNA sola zona aunque estén
  /// separadas (en el tablero físico: el amarillo).
  final Set<ColorRegion> coloresAgrupados;

  const Nivel({
    required this.numero,
    required this.tablero,
    required this.estrellas,
    required this.puntos,
    this.coloresAgrupados = const {ColorRegion.amarillo},
  });

  /// Arma la partida de este nivel con los valores iniciales de las
  /// estrellas (vacío por defecto).
  TableroJuego crearJuego([Map<Point<int>, int> valoresIniciales = const {}]) {
    return TableroJuego.iniciar(
      tablero,
      valoresIniciales,
      coloresAgrupados: coloresAgrupados,
      puntosPorColor: puntos,
    );
  }
}


// ---------- Nivel 2 ----------

final tableroNivel2 = <List<ColorRegion>>[
  [_mo, _mo, _mo, _gr, _ve, _ve, _ve],
  [_mo, _am, _az, _az, _az, _am, _ve],
  [_mo, _ro, _ro, _az, _az, _ro, _ve],
  [_ro, _ro, _ro, _am, _ro, _ro, _ro],
  [_ve, _ro, _az, _az, _ro, _ro, _mo],
  [_ve, _am, _az, _az, _az, _am, _mo],
  [_ve, _ve, _ve, _gr, _mo, _mo, _mo],
];

final estrellasNivel2 = <Point<int>>{
  const Point(0, 4), // verde
  const Point(2, 0), // morado
  const Point(3, 2), // rojo
  const Point(4, 5), // rojo
  const Point(5, 1), // amarillo
  const Point(6, 4), // morado
};

// ---------- Nivel 3 ----------

final tableroNivel3 = <List<ColorRegion>>[
  [_am, _am, _mo, _gr, _mo, _am, _am],
  [_gr, _am, _mo, _mo, _mo, _am, _gr],
  [_ro, _ro, _ro, _mo, _ro, _ro, _ro],
  [_ro, _ro, _ro, _gr, _ro, _ro, _ro],
  [_ve, _az, _az, _az, _az, _az, _ve],
  [_ve, _ve, _ve, _ve, _ve, _ve, _ve],
  [_mo, _mo, _mo, _gr, _mo, _mo, _mo],
];

final estrellasNivel3 = <Point<int>>{
  const Point(1, 2), // morado
  const Point(1, 5), // amarillo
  const Point(3, 3), // gris
  const Point(4, 1), // azul
  const Point(4, 6), // verde
  const Point(6, 2), // morado
};

// ---------- Nivel 4 ----------

final tableroNivel4 = <List<ColorRegion>>[
  [_alto, _alto, _alto, _alto, _alto, _alto, _alto],
  [_am, _ro, _az, _ve, _az, _ro, _am],
  [_ro, _ro, _mo, _mo, _mo, _ro, _ro],
  [_am, _ve, _az, _mo, _az, _ve, _am],
  [_ro, _ro, _mo, _mo, _mo, _ro, _ro],
  [_am, _ro, _az, _ve, _az, _ro, _am],
  [_bajo, _bajo, _bajo, _bajo, _bajo, _bajo, _bajo],
];

final estrellasNivel4 = <Point<int>>{
  const Point(0, 4), // naranja 4-6
  const Point(2, 2), // morado
  const Point(2, 5), // rojo
  const Point(3, 0), // amarillo
  const Point(5, 4), // azul
  const Point(6, 1), // naranja 1-3
};

// ---------- Lista de niveles ----------

/// Todos los niveles, en orden. El Nivel 1 está en tablero.dart.
final niveles = <Nivel>[
  Nivel(
    numero: 1,
    tablero: tableroNivel1,
    estrellas: estrellasNivel1,
    puntos: {
      ColorRegion.azul: [7, 5, 3],
      ColorRegion.morado: [6, 4, 2],
      ColorRegion.amarillo: [8, 6, 4],
      ColorRegion.verde: [4, 3, 2],
      ColorRegion.rojo: [6, 4, 2],
    },
  ),
  Nivel(
    numero: 2,
    tablero: tableroNivel2,
    estrellas: estrellasNivel2,
    puntos: {
      ColorRegion.amarillo: [6, 4, 2],
      ColorRegion.morado: [6, 4, 2],
      ColorRegion.rojo: [6, 4, 2],
      ColorRegion.azul: [7, 5, 3],
      ColorRegion.verde: [4, 3, 2],
      ColorRegion.gris: [3, 2, 1],
    },
  ),
  Nivel(
    numero: 3,
    tablero: tableroNivel3,
    estrellas: estrellasNivel3,
    puntos: {
      ColorRegion.morado: [7, 5, 3],
      ColorRegion.rojo: [6, 4, 2],
      ColorRegion.azul: [7, 5, 3],
      ColorRegion.amarillo: [7, 5, 3],
      ColorRegion.verde: [6, 5, 4],
      ColorRegion.gris: [8, 6, 4],
    },
  ),
  Nivel(
    numero: 4,
    tablero: tableroNivel4,
    estrellas: estrellasNivel4,
    puntos: {
      ColorRegion.morado: [7, 5, 3],
      ColorRegion.azul: [8, 6, 4],
      ColorRegion.rojo: [6, 4, 2],
      ColorRegion.amarillo: [8, 6, 4],
      ColorRegion.verde: [3, 2, 1],
      ColorRegion.naranjaAlto: [6, 4, 3],
      ColorRegion.naranjaBajo: [6, 4, 3],
    },
  ),
];
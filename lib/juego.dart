import 'dart:math';
import 'tablero.dart';
import 'reglas.dart';

/// Mapea cada color de zona a la función de validación que le corresponde.
bool Function(List<int>, int) reglaParaColor(ColorRegion color) {
  switch (color) {
    case ColorRegion.rojo:
    case ColorRegion.amarillo:
      return cumpleTodosDiferentes;
    case ColorRegion.verde:
      return cumpleVerde;
    case ColorRegion.azul:
    case ColorRegion.gris:
      return cumpleAzul;
    case ColorRegion.morado:
      return cumpleMorado;
    case ColorRegion.naranjaAlto:
      return cumpleNaranjaAlto;
    case ColorRegion.naranjaBajo:
      return cumpleNaranjaBajo;
  }
}

/// Resultado de tirar los dos dados del turno.
class TiroDados {
  final int dado1;
  final int dado2;
  const TiroDados(this.dado1, this.dado2);
  List<int> get valores => [dado1, dado2];
}

TiroDados tirarDados([Random? random]) {
  final r = random ?? Random();
  return TiroDados(r.nextInt(6) + 1, r.nextInt(6) + 1);
}

/// Controlador de partida: guarda el estado mutable del tablero
/// (zonas + valores colocados) y aplica la regla de cada zona al colocar.
class TableroJuego {
  final List<List<Celda?>> _celdas;
  final Map<int, ColorRegion> colorPorZona;
  final int filas;
  final int columnas;

  /// Zonas que ya dieron sus puntos (para no sumarlos dos veces).
  final Set<int> _zonasPuntuadas = {};

  /// Puntuación acumulada de la partida.
  int puntuacionTotal = 0;

 final Map<ColorRegion, List<int>>? puntosPorColor;

  TableroJuego._(
    this._celdas,
    this.colorPorZona,
    this.filas,
    this.columnas,
    this.puntosPorColor,
  );

  factory TableroJuego.desdeColores(
    List<List<ColorRegion>> grid, {
    Set<ColorRegion> coloresAgrupados = const {},
    Map<ColorRegion, List<int>>? puntosPorColor,
  }) {
    final generado =
        construirTableroDesdeColores(grid, coloresAgrupados: coloresAgrupados);
    final filas = grid.length;
    final columnas = grid[0].length;
    final matriz =
        List.generate(filas, (_) => List<Celda?>.filled(columnas, null));
    for (final c in generado.celdas) {
      matriz[c.fila][c.columna] = c;
    }
    return TableroJuego._(
      matriz,
      generado.colorPorZona,
      filas,
      columnas,
      puntosPorColor,
    );
  }
  Celda celdaEn(int fila, int columna) => _celdas[fila][columna]!;

  List<Celda> get celdas =>
      _celdas.expand((f) => f).whereType<Celda>().toList();

  /// Valores ya colocados en la zona [zonaId].
  List<int> valoresDeZona(int zonaId) => extraerValoresDeZona(celdas, zonaId);

  /// Valores de un color, opcionalmente filtrados por posición
  /// ("azul de arriba", "amarillo arriba izquierda", "todos los azules", etc.).
  List<int> valoresDeColor(
    ColorRegion region, {
    Vertical? vertical,
    Horizontal? horizontal,
  }) {
    return valoresPorColorYPosicion(
      celdas, colorPorZona, filas, columnas, region,
      vertical: vertical, horizontal: horizontal,
    );
  }

  bool get tableroVacio => celdas.every((c) => c.valor == null);

  bool _tieneVecinoConNumero(int fila, int columna) {
    const direcciones = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // arriba, abajo, izq, der — sin diagonales
    ];
    for (final d in direcciones) {
      final f = fila + d[0];
      final c = columna + d[1];
      if (f >= 0 && f < filas && c >= 0 && c < columnas) {
        if (celdaEn(f, c).valor != null) return true;
      }
    }
    return false;
  }

  /// True si [valor] puede colocarse en (fila, columna): la celda debe
  /// estar vacía, debe ser adyacente (sin diagonales) a otra celda ya
  /// ocupada — salvo que el tablero esté completamente vacío, en cuyo
  /// caso cualquier celda sirve como primer movimiento — y debe cumplir
  /// la regla de su zona.
  bool puedeColocar(int fila, int columna, int valor) {
    final celda = celdaEn(fila, columna);
    if (celda.valor != null) return false;
    if (!tableroVacio && !_tieneVecinoConNumero(fila, columna)) return false;
    final regla = reglaParaColor(colorPorZona[celda.zonaId]!);
    return regla(valoresDeZona(celda.zonaId), valor);
  }

  /// Coloca [valor] en (fila, columna) si es válido. Devuelve true si tuvo éxito.
  bool colocar(int fila, int columna, int valor) {
    if (!puedeColocar(fila, columna, valor)) return false;
    final celda = celdaEn(fila, columna);
    _celdas[fila][columna] =
        Celda(fila: fila, columna: columna, zonaId: celda.zonaId, valor: valor);
    return true;
  }

  /// Casillas vacías donde [valor] es colocable ahora mismo (útil para
  /// mostrarle al jugador dónde puede poner el número que le tocó en el dado).
  List<Celda> celdasValidasPara(int valor) => celdas
      .where((c) => c.valor == null && puedeColocar(c.fila, c.columna, valor))
      .toList();

  bool get tableroCompleto => celdas.every((c) => c.valor != null);
  

  // ---------- Regla del ancla ----------
  //
  // Se tiran dos dados. El jugador elige uno como ANCLA y el otro es el
  // número que se coloca: solo puede ir en una casilla vacía que toque
  // (sin diagonales) una casilla que ya tenga el valor del ancla, y que
  // además cumpla la regla de su zona.

  bool _tieneVecinoConValor(int fila, int columna, int valor) {
    const direcciones = [
      [-1, 0], [1, 0], [0, -1], [0, 1],
    ];
    for (final d in direcciones) {
      final f = fila + d[0];
      final c = columna + d[1];
      if (f >= 0 && f < filas && c >= 0 && c < columnas) {
        if (celdaEn(f, c).valor == valor) return true;
      }
    }
    return false;
  }

  /// True si [valor] se puede colocar en (fila, columna) usando [ancla].
  /// Si el tablero está totalmente vacío (sin valores iniciales) no hay
  /// ancla que buscar y cualquier celda sirve como primer movimiento.
  bool puedeColocarConAncla(int fila, int columna, int valor, int ancla) {
    final celda = celdaEn(fila, columna);
    if (celda.valor != null) return false;
    if (!tableroVacio && !_tieneVecinoConValor(fila, columna, ancla)) {
      return false;
    }
    final regla = reglaParaColor(colorPorZona[celda.zonaId]!);
    return regla(valoresDeZona(celda.zonaId), valor);
  }

  /// Coloca [valor] si cumple la regla del ancla. Devuelve true si pudo.
  bool colocarConAncla(int fila, int columna, int valor, int ancla) {
    if (!puedeColocarConAncla(fila, columna, valor, ancla)) return false;
    final celda = celdaEn(fila, columna);
    _celdas[fila][columna] =
        Celda(fila: fila, columna: columna, zonaId: celda.zonaId, valor: valor);
    return true;
  }

  /// Casillas donde [valor] se puede colocar usando [ancla].
  List<Celda> celdasValidasConAncla(int ancla, int valor) => celdas
      .where((c) =>
          c.valor == null &&
          puedeColocarConAncla(c.fila, c.columna, valor, ancla))
      .toList();

  /// True si con esta tirada hay al menos una jugada: usando [dado1] de
  /// ancla y colocando [dado2], o al revés.
  bool hayJugadaPosible(int dado1, int dado2) =>
      celdasValidasConAncla(dado1, dado2).isNotEmpty ||
      celdasValidasConAncla(dado2, dado1).isNotEmpty;

  /// True si existe CUALQUIER tirada (de las 36 posibles) con jugada.
  /// Si es false y el tablero no está completo, la partida ya no se
  /// puede continuar.
  bool get hayAlgunaJugadaPosible {
    for (var ancla = 1; ancla <= 6; ancla++) {
      for (var valor = 1; valor <= 6; valor++) {
        if (celdasValidasConAncla(ancla, valor).isNotEmpty) return true;
      }
    }
    return false;
  }

  // ---------- Puntuación ----------

  int _tamanoDeZona(int zonaId) =>
      celdas.where((c) => c.zonaId == zonaId).length;

  /// Revisa todas las zonas y suma puntos la primera vez que cada una
  /// queda completamente llena. Una zona vale tantos puntos como
  /// celdas tiene (mientras más grande, más cuesta llenarla y más vale).
  /// Devuelve los puntos ganados en ESTA revisión (0 si no se completó
  /// ninguna zona nueva).
  int _puntosDeZona(int zonaId, int tamano, int puesto) {
    final tabla = puntosPorColor?[colorPorZona[zonaId]];
    if (tabla == null) return tamano;
    final i = puesto - 1;
    return (i >= 0 && i < tabla.length) ? tabla[i] : 0;
  }

  /// Revisa todas las zonas y suma puntos la primera vez que cada una
  /// queda completamente llena. [puesto] es el lugar en que se completa
  /// (1 por defecto: en solitario siempre eres el primero).
  /// Devuelve los puntos ganados en ESTA revisión (0 si no se completó
  /// ninguna zona nueva).
  int comprobarPuntuacion({int puesto = 1}) {
    int ganados = 0;
    for (final zonaId in colorPorZona.keys) {
      if (_zonasPuntuadas.contains(zonaId)) continue;
      final tamano = _tamanoDeZona(zonaId);
      if (valoresDeZona(zonaId).length == tamano) {
        ganados += _puntosDeZona(zonaId, tamano, puesto);
        _zonasPuntuadas.add(zonaId);
      }
    }
    puntuacionTotal += ganados;
    return ganados;
  }

  // ---------- Valores iniciales ----------

  /// Coloca los valores iniciales (las casillas con estrella) al
  /// arrancar la partida. A diferencia de colocar() durante el juego,
  /// esto NO exige que la celda tenga un vecino con número (el tablero
  /// todavía está vacío al inicio), pero sí valida la regla de la zona
  /// por seguridad, ya que sigue siendo parte del mismo tablero.
  void colocarValoresIniciales(Map<Point<int>, int> valoresIniciales) {
    valoresIniciales.forEach((pos, valor) {
      final celda = celdaEn(pos.x, pos.y);
      final regla = reglaParaColor(colorPorZona[celda.zonaId]!);
      if (!regla(valoresDeZona(celda.zonaId), valor)) {
        throw ArgumentError(
          'El valor $valor en (${pos.x}, ${pos.y}) no cumple la regla '
          'de su zona.',
        );
      }
      _celdas[pos.x][pos.y] = Celda(
        fila: pos.x,
        columna: pos.y,
        zonaId: celda.zonaId,
        valor: valor,
      );
    });

    // Si justo esos valores completaron alguna zona, ya cuenta.
    comprobarPuntuacion();
  }

  /// Crea el tablero y de una vez coloca los valores iniciales.
  /// Es el punto de entrada que usa PantallaValoresIniciales.alContinuar.
  factory TableroJuego.iniciar(
    List<List<ColorRegion>> grid,
    Map<Point<int>, int> valoresIniciales, {
    Set<ColorRegion> coloresAgrupados = const {},
    Map<ColorRegion, List<int>>? puntosPorColor,
  }) {
    final juego = TableroJuego.desdeColores(
      grid,
      coloresAgrupados: coloresAgrupados,
      puntosPorColor: puntosPorColor,
    );
    juego.colocarValoresIniciales(valoresIniciales);
    return juego;
  }
}
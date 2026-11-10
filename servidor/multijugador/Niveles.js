// Port de tablero.dart (construirTableroDesdeColores, nivel 1) y niveles.dart.
// Los nombres de color coinciden con el enum ColorRegion de Dart, porque el
// servidor se los manda tal cual a la app.

const am = 'amarillo';
const ve = 'verde';
const mo = 'morado';
const az = 'azul';
const ro = 'rojo';
const gr = 'gris';
const alto = 'naranjaAlto';
const bajo = 'naranjaBajo';

export const NIVELES = {
  1: {
    numero: 1,
    grid: [
      [am, ve, az, mo, mo, mo, am],
      [ve, ve, az, az, mo, mo, ve],
      [ve, ro, ro, az, mo, ve, ve],
      [ve, ro, mo, am, ve, ve, ve],
      [ve, ro, mo, mo, ro, ro, az],
      [ro, ro, mo, ro, ro, az, az],
      [am, mo, mo, ro, ro, az, am],
    ],
    estrellas: [[0, 2], [1, 5], [3, 1], [3, 4], [5, 2], [6, 4]],
    puntos: {
      azul: [7, 5, 3],
      morado: [6, 4, 2],
      amarillo: [8, 6, 4],
      verde: [4, 3, 2],
      rojo: [6, 4, 2],
    },
  },
  2: {
    numero: 2,
    grid: [
      [mo, mo, mo, gr, ve, ve, ve],
      [mo, am, az, az, az, am, ve],
      [mo, ro, ro, az, az, ro, ve],
      [ro, ro, ro, am, ro, ro, ro],
      [ve, ro, az, az, ro, ro, mo],
      [ve, am, az, az, az, am, mo],
      [ve, ve, ve, gr, mo, mo, mo],
    ],
    estrellas: [[0, 4], [2, 0], [3, 2], [4, 5], [5, 1], [6, 4]],
    puntos: {
      amarillo: [6, 4, 2],
      morado: [6, 4, 2],
      rojo: [6, 4, 2],
      azul: [7, 5, 3],
      verde: [4, 3, 2],
      gris: [3, 2, 1],
    },
  },
  3: {
    numero: 3,
    grid: [
      [am, am, mo, gr, mo, am, am],
      [gr, am, mo, mo, mo, am, gr],
      [ro, ro, ro, mo, ro, ro, ro],
      [ro, ro, ro, gr, ro, ro, ro],
      [ve, az, az, az, az, az, ve],
      [ve, ve, ve, ve, ve, ve, ve],
      [mo, mo, mo, gr, mo, mo, mo],
    ],
    estrellas: [[1, 2], [1, 5], [3, 3], [4, 1], [4, 6], [6, 2]],
    puntos: {
      morado: [7, 5, 3],
      rojo: [6, 4, 2],
      azul: [7, 5, 3],
      amarillo: [7, 5, 3],
      verde: [6, 5, 4],
      gris: [8, 6, 4],
    },
  },
  4: {
    numero: 4,
    grid: [
      [alto, alto, alto, alto, alto, alto, alto],
      [am, ro, az, ve, az, ro, am],
      [ro, ro, mo, mo, mo, ro, ro],
      [am, ve, az, mo, az, ve, am],
      [ro, ro, mo, mo, mo, ro, ro],
      [am, ro, az, ve, az, ro, am],
      [bajo, bajo, bajo, bajo, bajo, bajo, bajo],
    ],
    estrellas: [[0, 4], [2, 2], [2, 5], [3, 0], [5, 4], [6, 1]],
    puntos: {
      morado: [7, 5, 3],
      azul: [8, 6, 4],
      rojo: [6, 4, 2],
      amarillo: [8, 6, 4],
      verde: [3, 2, 1],
      naranjaAlto: [6, 4, 3],
      naranjaBajo: [6, 4, 3],
    },
  },
};

// En el tablero físico todos los amarillos cuentan como UNA zona (Nivel.coloresAgrupados).
const COLORES_AGRUPADOS = ['amarillo'];
const DIRECCIONES = [[-1, 0], [1, 0], [0, -1], [0, 1]]; // sin diagonales

/** Agrupa celdas conectadas del mismo color en zonas (flood fill). */
export function construirZonas(grid, coloresAgrupados = COLORES_AGRUPADOS) {
  const filas = grid.length;
  const columnas = grid[0].length;
  const idZona = Array.from({ length: filas }, () => Array(columnas).fill(null));
  const colorPorZona = new Map();
  let siguiente = 0;

  for (let f = 0; f < filas; f++) {
    for (let c = 0; c < columnas; c++) {
      if (idZona[f][c] !== null) continue;
      const color = grid[f][c];
      const actual = siguiente++;
      const pila = [[f, c]];
      idZona[f][c] = actual;
      while (pila.length) {
        const [pf, pc] = pila.pop();
        for (const [df, dc] of DIRECCIONES) {
          const nf = pf + df;
          const nc = pc + dc;
          if (nf >= 0 && nf < filas && nc >= 0 && nc < columnas &&
              idZona[nf][nc] === null && grid[nf][nc] === color) {
            idZona[nf][nc] = actual;
            pila.push([nf, nc]);
          }
        }
      }
      colorPorZona.set(actual, color);
    }
  }

  // Une en una sola zona todas las zonas de los colores agrupados.
  for (const color of coloresAgrupados) {
    const ids = [...colorPorZona].filter(([, v]) => v === color).map(([k]) => k);
    if (ids.length < 2) continue;
    const principal = ids[0];
    for (const id of ids.slice(1)) {
      colorPorZona.delete(id);
      for (let f = 0; f < filas; f++) {
        for (let c = 0; c < columnas; c++) {
          if (idZona[f][c] === id) idZona[f][c] = principal;
        }
      }
    }
  }

  const celdasPorZona = new Map();
  for (let f = 0; f < filas; f++) {
    for (let c = 0; c < columnas; c++) {
      const id = idZona[f][c];
      if (!celdasPorZona.has(id)) celdasPorZona.set(id, []);
      celdasPorZona.get(id).push([f, c]);
    }
  }

  return { filas, columnas, idZona, colorPorZona, celdasPorZona };
}

const cache = new Map();

/** Zonas de un nivel (se calculan una vez y se comparten entre salas). */
export function zonasDeNivel(numero) {
  if (!cache.has(numero)) cache.set(numero, construirZonas(NIVELES[numero].grid));
  return cache.get(numero);
}
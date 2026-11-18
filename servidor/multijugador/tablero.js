// Port de TableroJuego (juego.dart): el tablero de UN jugador.
// Las zonas (geometría) se comparten entre jugadores; los valores son propios.

import { reglaParaColor } from './reglas.js';

const DIRECCIONES = [[-1, 0], [1, 0], [0, -1], [0, 1]];

export class Tablero {
  constructor(zonas) {
    this.zonas = zonas;
    this.filas = zonas.filas;
    this.columnas = zonas.columnas;
    this.celdas = Array.from({ length: this.filas }, () => Array(this.columnas).fill(null));
    this._llenas = 0;
  }

  get llenas() { return this._llenas; }
  get vacio() { return this._llenas === 0; }
  get completo() { return this._llenas === this.filas * this.columnas; }

  dentro(f, c) {
    return Number.isInteger(f) && Number.isInteger(c) &&
      f >= 0 && f < this.filas && c >= 0 && c < this.columnas;
  }

  valoresDeZona(zonaId) {
    const vals = [];
    for (const [f, c] of this.zonas.celdasPorZona.get(zonaId)) {
      if (this.celdas[f][c] !== null) vals.push(this.celdas[f][c]);
    }
    return vals;
  }

  zonaCompleta(zonaId) {
    return this.valoresDeZona(zonaId).length === this.zonas.celdasPorZona.get(zonaId).length;
  }

  _vecinoConValor(f, c, valor) {
    return DIRECCIONES.some(([df, dc]) => {
      const nf = f + df;
      const nc = c + dc;
      return this.dentro(nf, nc) && this.celdas[nf][nc] === valor;
    });
  }

  /** Regla del ancla: celda vacía, vecina (sin diagonales) de una celda con el
   *  valor del ancla, y que cumpla la regla de su zona. Con el tablero
   *  totalmente vacío cualquier celda sirve. */
  puedeColocarConAncla(f, c, valor, ancla) {
    if (!this.dentro(f, c) || this.celdas[f][c] !== null) return false;
    if (!this.vacio && !this._vecinoConValor(f, c, ancla)) return false;
    const zona = this.zonas.idZona[f][c];
    const regla = reglaParaColor(this.zonas.colorPorZona.get(zona));
    return regla(this.valoresDeZona(zona), valor);
  }

  /** Coloca sin validar: quien llama debe haber validado antes. */
  colocar(f, c, valor) {
    if (this.celdas[f][c] === null) this._llenas++;
    this.celdas[f][c] = valor;
  }

  celdasValidasConAncla(ancla, valor) {
    const res = [];
    for (let f = 0; f < this.filas; f++) {
      for (let c = 0; c < this.columnas; c++) {
        if (this.puedeColocarConAncla(f, c, valor, ancla)) res.push([f, c]);
      }
    }
    return res;
  }

  /** ¿Hay jugada con esta tirada? (d1 de ancla colocando d2, o al revés) */
  hayJugadaPosible(d1, d2) {
    return this.celdasValidasConAncla(d1, d2).length > 0 ||
      this.celdasValidasConAncla(d2, d1).length > 0;
  }

  /** ¿Existe CUALQUIER tirada (de las 36) con jugada? */
  hayAlgunaJugadaPosible() {
    for (let ancla = 1; ancla <= 6; ancla++) {
      for (let valor = 1; valor <= 6; valor++) {
        if (this.celdasValidasConAncla(ancla, valor).length > 0) return true;
      }
    }
    return false;
  }

  copiaCeldas() {
    return this.celdas.map((fila) => [...fila]);
  }
}

function barajar(lista, rng) {
  const a = [...lista];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/** Valores iniciales de las 6 estrellas: 1 al 6, cada uno una vez, respetando
 *  la regla de la zona de cada estrella (p. ej. las naranjas del nivel 4).
 *  Se sortea hasta que cumpla; el MISMO resultado se da a todos los jugadores. */
export function generarValoresIniciales(nivel, zonas, rng = Math.random) {
  for (let intento = 0; intento < 5000; intento++) {
    const perm = barajar([1, 2, 3, 4, 5, 6], rng);
    const t = new Tablero(zonas);
    let ok = true;
    for (let i = 0; i < nivel.estrellas.length; i++) {
      const [f, c] = nivel.estrellas[i];
      const zona = zonas.idZona[f][c];
      const regla = reglaParaColor(zonas.colorPorZona.get(zona));
      if (!regla(t.valoresDeZona(zona), perm[i])) { ok = false; break; }
      t.colocar(f, c, perm[i]);
    }
    if (ok) return nivel.estrellas.map(([f, c], i) => ({ f, c, valor: perm[i] }));
  }
  throw new Error(`No se pudieron generar valores iniciales válidos (nivel ${nivel.numero})`);
}
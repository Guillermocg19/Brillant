import { randomInt } from 'node:crypto';
import { Sala, ErrorSala } from './sala.js';

// Sin 0/O ni 1/I/L: el código se puede dictar por voz sin confusiones.
const ALFABETO = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

export class Gestor {
  constructor(opcionesSala = {}) {
    this.opcionesSala = opcionesSala;
    this.salas = new Map();
  }

  get cantidad() { return this.salas.size; }

  crear(nivel) {
    const codigo = this._codigoNuevo();
    // Si el nivel no existe, Sala lanza ErrorSala antes de registrarse.
    const sala = new Sala({
      ...this.opcionesSala,
      codigo,
      nivel,
      alCerrar: (c) => this.salas.delete(c),
    });
    this.salas.set(codigo, sala);
    return sala;
  }

  buscar(codigo) {
    return this.salas.get(String(codigo ?? '').trim().toUpperCase());
  }

  /** Sala donde este usuario tiene una sesión que reanudar (o undefined). */
  salaDe(userId) {
    for (const sala of this.salas.values()) {
      if (sala.tieneJugador(userId)) return sala;
    }
    return undefined;
  }

  _codigoNuevo() {
    for (let i = 0; i < 100; i++) {
      let codigo = '';
      for (let k = 0; k < 6; k++) codigo += ALFABETO[randomInt(ALFABETO.length)];
      if (!this.salas.has(codigo)) return codigo;
    }
    throw new ErrorSala('busy', 'Servidor ocupado, intenta de nuevo.');
  }
}
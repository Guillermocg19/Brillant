import { NIVELES, zonasDeNivel } from './niveles.js';
import { Tablero } from './tablero.js';
import { reglaParaColor } from './reglas.js';

export const MIN_JUGADORES = 2;
export const MAX_JUGADORES = 6;

export class ErrorSala extends Error {
  constructor(codigo, mensaje) {
    super(mensaje);
    this.codigo = codigo;
  }
}

class Jugador {
  constructor(id, nombre) {
    this.id = id;
    this.nombre = nombre;
    this.sink = null; // función que envía a ESTA conexión; null = desconectado
    this.activo = true; // false tras rendirse/abandonar: solo mira
    this.salio = false; // salió a propósito: ya no se reanuda su sesión
    this.listoLobby = false;
    this.preparado = false; // ya confirmó sus números iniciales
    this.tablero = null;
    this.pendiente = null; // { ancla, valor, fila, columna }
    this.listoRonda = false;
    this.sinMovimiento = false;
    this.puntos = 0;
    this.zonasPuntuadas = new Set();
    this.timerGracia = null;
  }
  get conectado() { return this.sink !== null; }
  enviar(msg) { if (this.sink) this.sink(msg); }
}

/** Puntos de una zona según el puesto (1.º, 2.º, 3.º…) en completarla. */
export function puntosDeZona(tabla, tamano, puesto) {
  if (!tabla) return tamano;
  const i = puesto - 1;
  return i >= 0 && i < tabla.length ? tabla[i] : 0;
}

export class Sala {
  /**
   * modoGanador:
   *  - 'primero': gana quien llena el tablero primero (como pediste).
   *  - 'puntos':  al terminar gana quien tenga más puntos.
   */
  constructor({
    codigo, nivel, alCerrar,
    graciaMs = 60_000, ttlLobbyMs = 600_000, ttlTerminadaMs = 300_000,
    rng = Math.random, tirarDados, modoGanador = 'primero',
  }) {
    if (!NIVELES[nivel]) throw new ErrorSala('unknown_level', `El nivel ${nivel} no existe.`);
    this.codigo = codigo;
    this.nivel = nivel;
    this.alCerrar = alCerrar;
    this.graciaMs = graciaMs;
    this.ttlTerminadaMs = ttlTerminadaMs;
    this.rng = rng;
    this.modoGanador = modoGanador;
    this.tirarDados = tirarDados ?? (() => [
      1 + Math.floor(rng() * 6),
      1 + Math.floor(rng() * 6),
    ]);

    this.jugadores = new Map(); // id -> Jugador (orden de llegada)
    this.hostId = null;
    this.estado = 'lobby'; // lobby | preparando | jugando | terminada
    this.ronda = 0;
    this.dados = [];
    this.resultado = null;
    this.zonas = null;
    this.completadasPorZona = new Map(); // zona -> cuántos ya la completaron
    this.cerrada = false;

    this._timerLobby = this._temporizador(ttlLobbyMs, () => {
      if (this.estado === 'lobby') this.cerrar();
    });
    this._timerTerminada = null;
  }

  // ───────────────────────── Consultas ─────────────────────────

  lista() { return [...this.jugadores.values()]; }
  activos() { return this.lista().filter((p) => p.activo); }
  jugador(id) { return this.jugadores.get(id); }
  tieneJugador(id) {
    const j = this.jugadores.get(id);
    return !!j && !j.salio;
  }
  get enPartida() { return this.estado === 'preparando' || this.estado === 'jugando'; }
  esVigente(j, sink) { return j.sink === sink; }
  valorParaAncla(ancla) { return this.dados[0] === ancla ? this.dados[1] : this.dados[0]; }

  // ───────────────────────── Lobby ─────────────────────────

  /** Crea al jugador (o devuelve el existente). No lo conecta: usar [conectar]. */
  unirse(id, nombre) {
    this._abierta();
    const existente = this.jugadores.get(id);
    if (existente) return existente;
    if (this.estado !== 'lobby') throw new ErrorSala('already_started', 'La partida ya empezó.');
    if (this.jugadores.size >= MAX_JUGADORES) {
      throw new ErrorSala('room_full', `La sala está llena (máximo ${MAX_JUGADORES}).`);
    }
    const j = new Jugador(id, nombre);
    this.jugadores.set(id, j);
    this.hostId ??= id;
    return j;
  }

  setNivel(por, nivel) {
    this._exigirLobby();
    this._exigirHost(por);
    if (!NIVELES[nivel]) throw new ErrorSala('unknown_level', `El nivel ${nivel} no existe.`);
    this.nivel = nivel;
    // Todos deben volver a confirmar: nadie empieza con un nivel que no vio.
    for (const p of this.lista()) p.listoLobby = false;
    this._sincronizarTodos();
  }

  setListoLobby(j, listo) {
    this._exigirLobby();
    j.listoLobby = !!listo;
    this._sincronizarTodos();
  }

  iniciar(por) {
    this._exigirLobby();
    this._exigirHost(por);
    const todos = this.lista();
    if (todos.length < MIN_JUGADORES) {
      throw new ErrorSala('not_enough_players', `Se necesitan al menos ${MIN_JUGADORES} jugadores.`);
    }
    if (todos.some((p) => !p.conectado)) {
      throw new ErrorSala('player_disconnected', 'Hay un jugador desconectado.');
    }
    if (todos.some((p) => p.id !== this.hostId && !p.listoLobby)) {
      throw new ErrorSala('not_ready', 'Faltan jugadores por marcar "listo".');
    }

    // Fase de preparación: cada jugador elige dónde pone sus números iniciales.
    this.estado = 'preparando';
    clearTimeout(this._timerLobby);
    this.zonas = zonasDeNivel(this.nivel);
    this.permitidos = this._calcularPermitidos();
    this.ronda = 0;
    for (const p of todos) {
      p.tablero = new Tablero(this.zonas);
      p.preparado = false;
    }
    this._sincronizarTodos();
  }

  // ───────────────────── Preparación (números iniciales) ─────────────────────

  /** Por cada estrella, los valores que su zona admite estando vacía. Sirve para
   *  que la app deshabilite de antemano lo imposible (p. ej. naranjas del nivel 4). */
  _calcularPermitidos() {
    return NIVELES[this.nivel].estrellas.map(([f, c]) => {
      const zona = this.zonas.idZona[f][c];
      const regla = reglaParaColor(this.zonas.colorPorZona.get(zona));
      return [1, 2, 3, 4, 5, 6].filter((v) => regla([], v));
    });
  }

  /** El jugador coloca sus 6 números: valores[i] va en la estrella i.
   *  Debe usar el 1 al 6 una sola vez y respetar la regla de cada zona. */
  confirmarPreparacion(j, valores) {
    this._exigirPreparando();
    this._exigirActivo(j);
    const estrellas = NIVELES[this.nivel].estrellas;
    if (!Array.isArray(valores) || valores.length !== estrellas.length ||
        !valores.every(Number.isInteger)) {
      throw new ErrorSala('bad_request', 'Datos inválidos.');
    }
    if (new Set(valores).size !== valores.length || valores.some((v) => v < 1 || v > 6)) {
      throw new ErrorSala('invalid_setup', 'Usa cada número del 1 al 6 una sola vez.');
    }
    const t = new Tablero(this.zonas);
    for (let i = 0; i < estrellas.length; i++) {
      const [f, c] = estrellas[i];
      const zona = this.zonas.idZona[f][c];
      const regla = reglaParaColor(this.zonas.colorPorZona.get(zona));
      if (!regla(t.valoresDeZona(zona), valores[i])) {
        throw new ErrorSala('invalid_setup', `El ${valores[i]} no cumple la regla de esa zona.`);
      }
      t.colocar(f, c, valores[i]);
    }
    j.tablero = t;
    j.preparado = true;
    this._sincronizar(j);
    this._avanzar();
  }

  /** Deshace tu confirmación para cambiar tus números (mientras otros no terminan). */
  editarPreparacion(j) {
    this._exigirPreparando();
    this._exigirActivo(j);
    j.preparado = false;
    j.tablero = new Tablero(this.zonas);
    this._sincronizarTodos();
  }

  /** Todos confirmaron: empieza el juego con la primera tirada. */
  _empezarJuego() {
    this.estado = 'jugando';
    this._puntuarZonas(this.activos()); // por si los números iniciales completan alguna zona
    this.ronda = 0;
    this._empezarRonda();
  }

  // ─────────────────────── Conexión ───────────────────────

  /** Asocia una conexión al jugador (primera vez o reconexión). */
  conectar(j, sink, reconectado = false) {
    this._abierta();
    const vieja = j.sink;
    j.sink = sink;
    clearTimeout(j.timerGracia);
    j.timerGracia = null;
    if (vieja && vieja !== sink) vieja({ type: 'replaced' }); // otra conexión tomó su lugar
    this._evento(reconectado ? 'player_reconnected' : 'player_joined', j);
    this._sincronizarTodos();
  }

  /** La conexión [sink] se cayó. Solo cuenta si sigue siendo la vigente. */
  desconectar(j, sink) {
    if (this.cerrada || j.sink !== sink) return;
    j.sink = null;
    if (this.estado === 'terminada' || !j.activo) {
      this._cerrarSiTerminadaYSola();
      return;
    }
    this._evento('player_disconnected', j, { graceSeconds: Math.round(this.graciaMs / 1000) });
    clearTimeout(j.timerGracia);
    j.timerGracia = this._temporizador(this.graciaMs, () => this._graciaVencida(j));
    this._sincronizarTodos();
  }

  _graciaVencida(j) {
    if (this.cerrada || j.conectado) return;
    if (this.estado === 'lobby') this._quitarDelLobby(j, 'timeout');
    else if (this.enPartida) this._desactivar(j, 'abandoned');
  }

  // ───────────────────────── Juego ─────────────────────────

  /** Elige (o cambia) tu jugada de la ronda. Se puede corregir hasta dar "listo". */
  colocar(j, ronda, ancla, fila, columna) {
    this._exigirJugando();
    this._exigirActivo(j);
    if (![ronda, ancla, fila, columna].every(Number.isInteger)) {
      throw new ErrorSala('bad_request', 'Datos inválidos.');
    }
    if (ronda !== this.ronda || j.listoRonda) { // mensaje viejo o repetido
      this._sincronizar(j);
      return;
    }
    if (!this.dados.includes(ancla)) {
      throw new ErrorSala('anchor_not_rolled', 'Ese número no salió en los dados.');
    }
    const valor = this.valorParaAncla(ancla);
    if (!j.tablero.puedeColocarConAncla(fila, columna, valor, ancla)) {
      throw new ErrorSala('invalid_placement', 'No puedes colocar ahí.');
    }
    j.pendiente = { ancla, valor, fila, columna };
    this._sincronizar(j);
  }

  /** "Listo": confirma tu jugada (o pasas si no elegiste ninguna). */
  listo(j, ronda) {
    this._exigirJugando();
    this._exigirActivo(j);
    if (!Number.isInteger(ronda)) throw new ErrorSala('bad_request', 'Datos inválidos.');
    if (ronda !== this.ronda || j.listoRonda) {
      this._sincronizar(j);
      return;
    }
    j.listoRonda = true;
    this._avanzar();
  }

  rendirse(j) {
    if (this.estado === 'lobby') this._quitarDelLobby(j, 'left');
    else if (this.enPartida) this._desactivar(j, 'resigned'); // queda de espectador
  }

  /** Salir del todo: ya no se reanuda su sesión. */
  salir(j) {
    if (this.estado === 'lobby') {
      this._quitarDelLobby(j, 'left');
    } else if (this.enPartida) {
      j.sink = null;
      j.salio = true;
      this._desactivar(j, 'left');
    } else {
      j.sink = null;
      j.salio = true;
      this._cerrarSiTerminadaYSola();
    }
  }

  _desactivar(j, motivo) {
    if (!j.activo) return;
    j.activo = false;
    j.pendiente = null;
    j.listoRonda = false;
    clearTimeout(j.timerGracia);
    this._evento('player_left', j, { reason: motivo });
    this._avanzar(); // IMPORTANTE: quitar a alguien puede completar la barrera
  }

  _quitarDelLobby(j, motivo) {
    if (!this.jugadores.delete(j.id)) return;
    clearTimeout(j.timerGracia);
    j.sink = null;
    j.salio = true;
    if (this.jugadores.size === 0) {
      this.cerrar();
      return;
    }
    if (this.hostId === j.id) {
      const siguiente = this.lista().find((p) => p.conectado) ?? this.lista()[0];
      this.hostId = siguiente.id;
    }
    this._evento('player_left', j, { reason: motivo });
    this._sincronizarTodos();
  }

  /** Punto único de avance: fin por abandonos, barrera (de preparación o de
   *  ronda), o solo sincroniza. */
  _avanzar() {
    if (!this.enPartida) return;
    const vivos = this.activos();
    if (vivos.length === 0) {
      this._terminar('everyone_left', []);
    } else if (vivos.length === 1) {
      this._terminar('last_standing', [vivos[0].id]);
    } else if (this.estado === 'preparando') {
      if (vivos.every((p) => p.preparado)) this._empezarJuego();
      else this._sincronizarTodos();
    } else if (vivos.every((p) => p.listoRonda)) {
      this._resolverRonda(vivos);
    } else {
      this._sincronizarTodos();
    }
  }

  _resolverRonda(vivos) {
    for (const p of vivos) {
      const pl = p.pendiente;
      if (pl) p.tablero.colocar(pl.fila, pl.columna, pl.valor);
      p.pendiente = null;
      p.listoRonda = false;
    }
    this._puntuarZonas(vivos);

    const completaron = vivos.filter((p) => p.tablero.completo);
    if (completaron.length > 0) {
      this._terminar('completed', this._ganadores('completed', vivos));
    } else {
      this._empezarRonda(); // termina solo ('no_moves') si ya nadie puede jugar
    }
  }

  /** Puntos por puesto: quien completa una zona antes cobra más. Si varios la
   *  completan en la misma ronda comparten puesto; el siguiente puesto libre
   *  cuenta a todos los que ya la completaron. */
  _puntuarZonas(candidatos) {
    const { colorPorZona, celdasPorZona } = this.zonas;
    const tabla = NIVELES[this.nivel].puntos;
    for (const [zona, color] of colorPorZona) {
      const ahora = candidatos.filter(
        (p) => !p.zonasPuntuadas.has(zona) && p.tablero.zonaCompleta(zona),
      );
      if (ahora.length === 0) continue;
      const yaCompletadas = this.completadasPorZona.get(zona) ?? 0;
      const tamano = celdasPorZona.get(zona).length;
      const pts = puntosDeZona(tabla[color], tamano, yaCompletadas + 1);
      for (const p of ahora) {
        p.puntos += pts;
        p.zonasPuntuadas.add(zona);
      }
      this.completadasPorZona.set(zona, yaCompletadas + ahora.length);
    }
  }

  /** Tira dados (iguales para todos) hasta que alguien tenga jugada. */
  _tirarConJugada(vivos) {
    if (!vivos.some((p) => p.tablero.hayAlgunaJugadaPosible())) return null;
    for (let i = 0; i < 1000; i++) {
      const dados = this.tirarDados();
      if (vivos.some((p) => p.tablero.hayJugadaPosible(dados[0], dados[1]))) {
        return { dados, relanzamientos: i };
      }
    }
    return null;
  }

  _empezarRonda() {
    this.ronda++;
    const vivos = this.activos();
    const tirada = this._tirarConJugada(vivos);
    if (!tirada) {
      this._terminar('no_moves', this._ganadores('no_moves', vivos));
      return;
    }
    this.dados = tirada.dados;
    this.relanzamientos = tirada.relanzamientos;
    for (const p of this.lista()) {
      p.pendiente = null;
      p.listoRonda = false;
      p.sinMovimiento = false;
    }
    // Quien no tiene jugada posible no puede hacer nada: ya está "listo".
    for (const p of vivos) {
      p.sinMovimiento = !p.tablero.hayJugadaPosible(this.dados[0], this.dados[1]);
      if (p.sinMovimiento) p.listoRonda = true;
    }
    this._sincronizarTodos();
  }

  _ganadores(razon, vivos) {
    if (razon === 'completed' && this.modoGanador === 'primero') {
      return vivos.filter((p) => p.tablero.completo).map((p) => p.id);
    }
    const max = Math.max(...vivos.map((p) => p.puntos));
    return vivos.filter((p) => p.puntos === max).map((p) => p.id);
  }

  _terminar(razon, ganadores) {
    this.estado = 'terminada';
    this.resultado = {
      reason: razon,
      winnerIds: ganadores,
      scores: Object.fromEntries(this.lista().map((p) => [p.id, p.puntos])),
    };
    for (const p of this.lista()) clearTimeout(p.timerGracia);
    this._timerTerminada = this._temporizador(this.ttlTerminadaMs, () => this.cerrar());
    this._sincronizarTodos();
    this._cerrarSiTerminadaYSola();
  }

  _cerrarSiTerminadaYSola() {
    if (this.estado === 'terminada' && this.lista().every((p) => !p.conectado)) this.cerrar();
  }

  cerrar() {
    if (this.cerrada) return;
    this.cerrada = true;
    clearTimeout(this._timerLobby);
    clearTimeout(this._timerTerminada);
    for (const p of this.lista()) {
      clearTimeout(p.timerGracia);
      p.enviar({ type: 'closed' });
      p.sink = null;
    }
    if (this.alCerrar) this.alCerrar(this.codigo);
  }

  // ───────────────────── Mensajes salientes ─────────────────────

  snapshotPara(yo) {
    const jugando = this.estado === 'jugando' && yo.activo && yo.tablero;
    const opciones = [];
    if (jugando) {
      for (const ancla of new Set(this.dados)) {
        const valor = this.valorParaAncla(ancla);
        opciones.push({ ancla, valor, cells: yo.tablero.celdasValidasConAncla(ancla, valor) });
      }
    }
    return {
      type: 'state',
      code: this.codigo,
      nivel: this.nivel,
      status: this.estado,
      hostId: this.hostId,
      you: yo.id,
      round: this.ronda,
      dice: this.dados,
      grid: NIVELES[this.nivel].grid,
      board: yo.tablero ? yo.tablero.copiaCeldas() : null,
      players: this.lista().map((p) => ({
        id: p.id,
        name: p.nombre,
        connected: p.conectado,
        active: p.activo,
        lobbyReady: p.listoLobby,
        roundReady: p.listoRonda,
        score: p.puntos,
        setupReady: p.preparado,
        filled: p.tablero ? p.tablero.llenas : 0,
        isHost: p.id === this.hostId,
      })),
      yourPending: yo.pendiente
        ? { ancla: yo.pendiente.ancla, valor: yo.pendiente.valor, fila: yo.pendiente.fila, columna: yo.pendiente.columna }
        : null,
      options: opciones,
      canPlay: jugando ? !yo.sinMovimiento : false,
      setup: this.estado === 'preparando'
        ? { stars: NIVELES[this.nivel].estrellas, allowed: this.permitidos, confirmed: yo.preparado }
        : null,
      result: this.resultado,
    };
  }

  _sincronizar(j) { j.enviar(this.snapshotPara(j)); }

  _sincronizarTodos() {
    for (const p of this.lista()) if (p.conectado) this._sincronizar(p);
  }

  _evento(tipo, quien, extra = {}) {
    const msg = { type: 'event', kind: tipo, playerId: quien.id, name: quien.nombre, ...extra };
    for (const p of this.lista()) if (p.conectado) p.enviar(msg);
  }

  // ───────────────────────── Guardas ─────────────────────────

  _temporizador(ms, fn) {
    const t = setTimeout(fn, ms);
    t.unref?.();
    return t;
  }

  _abierta() {
    if (this.cerrada) throw new ErrorSala('room_closed', 'La sala ya no existe.');
  }
  _exigirLobby() {
    this._abierta();
    if (this.estado !== 'lobby') throw new ErrorSala('not_in_lobby', 'La partida ya empezó.');
  }
  _exigirJugando() {
    this._abierta();
    if (this.estado !== 'jugando') throw new ErrorSala('not_playing', 'La partida no está en curso.');
  }
  _exigirPreparando() {
    this._abierta();
    if (this.estado !== 'preparando') {
      throw new ErrorSala('not_preparing', 'No es momento de elegir los números iniciales.');
    }
  }
  _exigirHost(j) {
    if (j.id !== this.hostId) throw new ErrorSala('not_host', 'Solo el anfitrión puede hacer eso.');
  }
  _exigirActivo(j) {
    if (!j.activo) throw new ErrorSala('not_active', 'Ya no participas en esta partida.');
  }
}
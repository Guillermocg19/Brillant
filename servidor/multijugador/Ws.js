import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';
import { Gestor } from './Gestor.js';
import { ErrorSala } from './sala.js';

/**
 * Engancha el multijugador al servidor HTTP que ya usa tu API.
 * Los jugadores se identifican con el MISMO token JWT del login: se manda en el
 * primer mensaje ({type:'auth', token}), no en la URL (las URL quedan en logs).
 */
export function adjuntarMultijugador(servidorHttp, { db, secreto, gestor = new Gestor() }) {
  const wss = new WebSocketServer({ server: servidorHttp, path: '/ws', maxPayload: 4096 });

  wss.on('connection', (ws) => {
    ws.vivo = true;
    ws.on('pong', () => { ws.vivo = true; });
    new Conexion(ws, { db, secreto, gestor });
  });

  // Latido: si un socket no responde en 10 s se da por muerto y la sala
  // arranca el periodo de gracia de ese jugador.
  const latido = setInterval(() => {
    for (const ws of wss.clients) {
      if (ws.vivo === false) { ws.terminate(); continue; }
      ws.vivo = false;
      ws.ping();
    }
  }, 10_000);
  latido.unref?.();
  wss.on('close', () => clearInterval(latido));

  return { wss, gestor };
}

class Conexion {
  constructor(ws, { db, secreto, gestor }) {
    this.ws = ws;
    this.db = db;
    this.secreto = secreto;
    this.gestor = gestor;
    this.usuario = null; // { id: string, nombre }
    this.sala = null;
    this.jugador = null;
    this.t0 = Date.now();
    this.n = 0;
    // La identidad de este closure identifica a ESTA conexión.
    this.sink = (msg) => this.enviar(msg);

    ws.on('message', (data) => this.alRecibir(data));
    ws.on('close', () => this.alCerrar());
    ws.on('error', () => this.alCerrar());
  }

  enviar(msg) {
    try {
      if (this.ws.readyState === this.ws.OPEN) this.ws.send(JSON.stringify(msg));
      if (msg.type === 'replaced' || msg.type === 'closed') this.ws.close();
    } catch {
      // El socket ya está cerrado: alCerrar se encarga del resto.
    }
  }

  error(codigo, mensaje) {
    this.enviar({ type: 'error', code: codigo, message: mensaje });
  }

  alCerrar() {
    if (this.sala && this.jugador) this.sala.desconectar(this.jugador, this.sink);
  }

  alRecibir(data) {
    this.ws.vivo = true;
    // Límite de ritmo: más de 20 mensajes por segundo se ignoran.
    const ahora = Date.now();
    if (ahora - this.t0 > 1000) { this.t0 = ahora; this.n = 0; }
    if (++this.n > 20) return this.error('rate_limited', 'Demasiados mensajes.');

    try {
      const msg = JSON.parse(data.toString());
      if (!msg || typeof msg.type !== 'string') throw new Error('formato');
      this.despachar(msg);
    } catch (e) {
      if (e instanceof ErrorSala) return this.error(e.codigo, e.message);
      if (!(e instanceof SyntaxError) && e.message !== 'formato') console.error('[ws]', e);
      this.error('bad_request', 'Mensaje inválido.');
    }
  }

  despachar(msg) {
    if (msg.type === 'ping') return this.enviar({ type: 'pong' });
    if (msg.type === 'auth') return this.autenticar(msg);
    if (!this.usuario) throw new ErrorSala('unauthenticated', 'Primero inicia sesión.');

    switch (msg.type) {
      case 'create_room': {
        this.liberarSalaPrevia();
        const sala = this.gestor.crear(Number(msg.nivel));
        let j;
        try {
          j = sala.unirse(this.usuario.id, this.usuario.nombre);
        } catch (e) {
          sala.cerrar(); // no dejar salas huérfanas
          throw e;
        }
        return this.entrar(sala, j, false);
      }
      case 'join_room': {
        const sala = this.gestor.buscar(msg.code);
        if (!sala) throw new ErrorSala('room_not_found', 'No existe una sala con ese código.');
        if (!sala.tieneJugador(this.usuario.id)) this.liberarSalaPrevia();
        const j = sala.unirse(this.usuario.id, this.usuario.nombre);
        return this.entrar(sala, j, sala.estado !== 'lobby');
      }
      default:
        return this.accionDeSala(msg);
    }
  }

  autenticar(msg) {
    if (this.usuario) return;
    let id;
    try {
      ({ id } = jwt.verify(String(msg.token ?? ''), this.secreto, { algorithms: ['HS256'] }));
    } catch {
      this.error('unauthorized', 'Sesión no válida. Inicia sesión de nuevo.');
      return this.ws.close();
    }
    const u = this.db.prepare('SELECT id, nombre FROM usuarios WHERE id = ?').get(id);
    if (!u) {
      this.error('unauthorized', 'La cuenta ya no existe.');
      return this.ws.close();
    }
    this.usuario = { id: String(u.id), nombre: u.nombre };
    // Si ya estaba en una partida (se cayó, cerró la app o abrió otro dispositivo), la retoma.
    const sala = this.gestor.salaDe(this.usuario.id);
    this.enviar({ type: 'auth_ok', inRoom: !!sala });
    if (sala) this.entrar(sala, sala.jugador(this.usuario.id), true);
  }

  /** Antes de crear o unirse a otra sala: suelta la anterior si ya terminó o
   *  el jugador ya no participaba; si sigue jugando, no se puede. */
  liberarSalaPrevia() {
    const previa = this.gestor.salaDe(this.usuario.id);
    if (!previa) return;
    const j = previa.jugador(this.usuario.id);
    if (previa.estado === 'terminada' || !j.activo) {
      previa.salir(j);
      if (this.sala === previa) { this.sala = null; this.jugador = null; }
    } else {
      throw new ErrorSala('already_in_room', 'Ya estás en una partida.');
    }
  }

  entrar(sala, jugador, reconectado) {
    this.sala = sala;
    this.jugador = jugador;
    this.enviar({ type: 'joined', code: sala.codigo, playerId: jugador.id });
    sala.conectar(jugador, this.sink, reconectado);
  }

  accionDeSala(msg) {
    const { sala, jugador } = this;
    if (!sala || !jugador || !sala.esVigente(jugador, this.sink)) {
      throw new ErrorSala('no_session', 'No estás en ninguna sala.');
    }
    switch (msg.type) {
      case 'set_level': return sala.setNivel(jugador, Number(msg.nivel));
      case 'lobby_ready': return sala.setListoLobby(jugador, msg.ready === true);
      case 'start': return sala.iniciar(jugador);
      case 'confirm_setup': return sala.confirmarPreparacion(jugador, msg.valores);
      case 'edit_setup': return sala.editarPreparacion(jugador);
      case 'place': return sala.colocar(jugador, msg.round, msg.ancla, msg.fila, msg.columna);
      case 'ready': return sala.listo(jugador, msg.round);
      case 'resign': return sala.rendirse(jugador);
      case 'leave': {
        sala.salir(jugador);
        this.sala = null;
        this.jugador = null;
        return this.enviar({ type: 'left' });
      }
      default:
        throw new ErrorSala('unknown_type', `Tipo de mensaje desconocido: ${msg.type}`);
    }
  }
}
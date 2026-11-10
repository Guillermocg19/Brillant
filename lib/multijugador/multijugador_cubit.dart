import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'multijugador_cliente.dart';
import 'multijugador_modelos.dart';

/// Aviso para la UI (snackbar). Sin `const` a propósito: cada instancia es
/// distinta, así dos avisos con el mismo texto seguidos se muestran ambos.
class Aviso {
  Aviso(this.texto, {this.esError = false});
  final String texto;
  final bool esError;
}

class MultijugadorState extends Equatable {
  const MultijugadorState({
    this.enlace = LinkStatus.desconectado,
    this.sala,
    this.aviso,
    this.ocupado = false,
  });

  final LinkStatus enlace;
  final RoomSnapshot? sala;
  final Aviso? aviso;

  /// true mientras se espera respuesta a crear/unirse/reanudar.
  final bool ocupado;

  MultijugadorState copyWith({
    LinkStatus? enlace,
    RoomSnapshot? sala,
    Aviso? aviso,
    bool? ocupado,
  }) =>
      MultijugadorState(
        enlace: enlace ?? this.enlace,
        sala: sala ?? this.sala,
        aviso: aviso, // los avisos no se arrastran
        ocupado: ocupado ?? this.ocupado,
      );

  @override
  List<Object?> get props => [enlace, sala, aviso, ocupado];
}

/// Multijugador sobre tu login: el jugador ES su cuenta. No hay códigos de
/// sesión que guardar: al reconectar, el servidor reconoce tu token y te
/// devuelve a tu partida.
class MultijugadorCubit extends Cubit<MultijugadorState> {
  MultijugadorCubit({
    required this.cliente,
    required this.tokenProvider,
    FlutterSecureStorage? almacen,
  })  : _almacen = almacen ?? const FlutterSecureStorage(),
        super(const MultijugadorState()) {
    cliente.onOpen = _alAbrir;
    _subMensajes = cliente.mensajes.listen(_alMensaje);
    _subEnlace = cliente.estado.listen((s) => emit(state.copyWith(enlace: s)));
  }

  static const _claveEnPartida = 'brillant_mp_en_partida';

  final MultijugadorCliente cliente;

  /// Devuelve el token de tu `ServicioAuth` (añade `String? get token => _token;`).
  final String? Function() tokenProvider;
  final FlutterSecureStorage _almacen;
  late final StreamSubscription<Map<String, dynamic>> _subMensajes;
  late final StreamSubscription<LinkStatus> _subEnlace;

  /// create_room / join_room pendiente: se reenvía si la conexión se cae
  /// antes de recibir `joined`.
  Map<String, dynamic>? _accionPendiente;
  bool _reanudando = false;

  /// Tu id de jugador en la sala (viene en `joined`).
  String? _miId;

  // ───────────────────────── Acciones ─────────────────────────

  /// Al abrir la pantalla: si estabas en una partida, vuelve a ella.
  Future<void> reanudar() async {
    if (await _almacen.read(key: _claveEnPartida) == null) return;
    _reanudando = true;
    emit(state.copyWith(ocupado: true));
    await cliente.conectar();
  }

  Future<void> crearSala({required int nivel}) =>
      _iniciar({'type': 'create_room', 'nivel': nivel});

  Future<void> unirse({required String codigo}) =>
      _iniciar({'type': 'join_room', 'code': codigo.trim().toUpperCase()});

  void cambiarNivel(int nivel) => _enviar({'type': 'set_level', 'nivel': nivel});
  void marcarListoLobby(bool listo) => _enviar({'type': 'lobby_ready', 'ready': listo});
  void iniciarPartida() => _enviar({'type': 'start'});

  /// Fase de preparación: confirma dónde pones tus números iniciales.
  /// [valores] tiene 6 números (el 1 al 6, una vez cada uno): el valor i va
  /// en la estrella i (el orden de `sala.setup.stars`).
  void confirmarPreparacion(List<int> valores) =>
      _enviar({'type': 'confirm_setup', 'valores': valores});

  /// Deshace tu confirmación para cambiar tus números (hasta que todos terminen).
  void editarPreparacion() => _enviar({'type': 'edit_setup'});

  /// Elige (o cambia) tu jugada: [ancla] es el dado que haces de ancla; el
  /// otro dado es el número que se coloca en ([fila], [columna]).
  void colocar({required int ancla, required int fila, required int columna}) {
    final sala = state.sala;
    if (sala == null) return;
    _enviar({
      'type': 'place',
      'round': sala.round,
      'ancla': ancla,
      'fila': fila,
      'columna': columna,
    });
  }

  /// "Listo": confirma tu jugada, o pasa si no elegiste ninguna.
  void confirmarRonda() {
    final sala = state.sala;
    if (sala == null) return;
    _enviar({'type': 'ready', 'round': sala.round});
  }

  /// Conceder la partida. Te quedas como espectador hasta que salgas.
  void rendirse() => _enviar({'type': 'resign'});

  Future<void> salir() async {
    cliente.enviar({'type': 'leave'});
    await _limpiar();
    cliente.desconectar();
    emit(MultijugadorState(enlace: cliente.estadoActual));
  }

  // ─────────────────────────── Interno ───────────────────────────

  Future<void> _iniciar(Map<String, dynamic> accion) async {
    _accionPendiente = accion;
    emit(state.copyWith(ocupado: true));
    await cliente.conectar();
  }

  void _enviar(Map<String, dynamic> m) {
    if (!cliente.enviar(m)) {
      emit(state.copyWith(
        aviso: Aviso('Sin conexión. Reconectando…', esError: true),
      ));
    }
  }

  Future<void> _alAbrir() async {
    final token = tokenProvider();
    if (token == null) {
      cliente.desconectar();
      emit(MultijugadorState(
        enlace: cliente.estadoActual,
        aviso: Aviso('Inicia sesión para jugar en línea.', esError: true),
      ));
      return;
    }
    cliente.enviar({'type': 'auth', 'token': token});
    // El servidor procesa los mensajes en orden: auth siempre llega antes.
    final accion = _accionPendiente;
    if (accion != null) cliente.enviar(accion);
  }

  Future<void> _alMensaje(Map<String, dynamic> msg) async {
    switch (msg['type']) {
      case 'auth_ok':
        // Quería reanudar pero el servidor no tiene tu partida (terminó o se reinició).
        if (_reanudando && msg['inRoom'] != true) {
          _reanudando = false;
          await _limpiar();
          cliente.desconectar();
          emit(MultijugadorState(
            enlace: cliente.estadoActual,
            aviso: Aviso('Tu partida anterior ya no existe.', esError: true),
          ));
        }
      case 'joined':
        _accionPendiente = null;
        _miId = msg['playerId'] as String?;
        await _almacen.write(key: _claveEnPartida, value: msg['code'] as String);
      case 'state':
        _reanudando = false;
        emit(state.copyWith(sala: RoomSnapshot.fromJson(msg), ocupado: false));
      case 'event':
        final texto = _textoEvento(msg);
        if (texto != null) emit(state.copyWith(aviso: Aviso(texto)));
      case 'error':
        _accionPendiente = null;
        if (msg['code'] == 'unauthorized') {
          await _limpiar();
          cliente.desconectar();
          emit(MultijugadorState(
            enlace: cliente.estadoActual,
            aviso: Aviso('Tu sesión caducó. Inicia sesión otra vez.', esError: true),
          ));
        } else {
          emit(state.copyWith(
            ocupado: false,
            aviso: Aviso(msg['message'] as String? ?? 'Error', esError: true),
          ));
        }
      case 'replaced':
        await _limpiar();
        cliente.desconectar();
        emit(MultijugadorState(
          enlace: cliente.estadoActual,
          aviso: Aviso('Abriste esta partida en otro dispositivo.', esError: true),
        ));
      case 'closed':
        await _limpiar();
        cliente.desconectar();
        emit(MultijugadorState(
          enlace: cliente.estadoActual,
          aviso: Aviso('La sala se cerró.', esError: true),
        ));
    }
  }

  String? _textoEvento(Map<String, dynamic> m) {
    final n = m['name'] as String? ?? 'Alguien';
    // No avisar de lo que haces tú.
    if (m['playerId'] == _miId) return null;
    switch (m['kind']) {
      case 'player_joined':
        return '$n se unió a la sala';
      case 'player_reconnected':
        return '$n volvió a conectarse';
      case 'player_disconnected':
        return '$n perdió la conexión (se le esperan ${m['graceSeconds']} s)';
      case 'player_left':
        return switch (m['reason']) {
          'resigned' => '$n se rindió',
          'abandoned' => '$n abandonó por desconexión',
          'timeout' => '$n salió por inactividad',
          _ => '$n salió de la partida',
        };
    }
    return null;
  }

  Future<void> _limpiar() async {
    _accionPendiente = null;
    _reanudando = false;
    _miId = null;
    await _almacen.delete(key: _claveEnPartida);
  }

  @override
  Future<void> close() async {
    await _subMensajes.cancel();
    await _subEnlace.cancel();
    await cliente.dispose();
    return super.close();
  }
}
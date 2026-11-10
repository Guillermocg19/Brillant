import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/servicio_auth.dart' show urlServidor;

/// ws://… (o wss://… si tu API usa https) en la misma dirección que la API.
Uri urlWebSocket() {
  final base = Uri.parse(urlServidor());
  return base.replace(
    scheme: base.scheme == 'https' ? 'wss' : 'ws',
    path: '/ws',
  );
}

enum LinkStatus { desconectado, conectando, conectado }

/// Conexión WebSocket que se reabre sola si se cae.
///
/// - Latido: envía `ping` cada 10 s; si pasan 25 s sin recibir nada (ni `pong`
///   ni estado) da la conexión por muerta y reconecta.
/// - Backoff exponencial: 1, 2, 4, 8, 16 y 30 s entre intentos.
/// - [onOpen] se llama en CADA apertura: ahí se envía `auth` con tu token.
class MultijugadorCliente {
  MultijugadorCliente([Uri? url]) : url = url ?? urlWebSocket();

  final Uri url;

  /// Se invoca tras cada conexión exitosa (la primera y las reconexiones).
  Future<void> Function()? onOpen;

  WebSocketChannel? _canal;
  StreamSubscription<dynamic>? _sub;
  Timer? _latido;
  Timer? _reintento;
  DateTime _ultimaVez = DateTime.now();
  int _intento = 0;
  bool _quiereAbierto = false;
  LinkStatus _actual = LinkStatus.desconectado;

  final _mensajes = StreamController<Map<String, dynamic>>.broadcast();
  final _estado = StreamController<LinkStatus>.broadcast();

  Stream<Map<String, dynamic>> get mensajes => _mensajes.stream;
  Stream<LinkStatus> get estado => _estado.stream;
  LinkStatus get estadoActual => _actual;

  Future<void> conectar() async {
    _quiereAbierto = true;
    if (_actual == LinkStatus.conectado) {
      await onOpen?.call();
      return;
    }
    await _abrir();
  }

  /// Cierre voluntario: no reintenta.
  void desconectar() {
    _quiereAbierto = false;
    _reintento?.cancel();
    _reintento = null;
    _desmontar();
    _fijarEstado(LinkStatus.desconectado);
  }

  /// false si no hay conexión en este momento (el mensaje NO se encola).
  bool enviar(Map<String, dynamic> mensaje) {
    final canal = _canal;
    if (canal == null || _actual != LinkStatus.conectado) return false;
    try {
      canal.sink.add(jsonEncode(mensaje));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    desconectar();
    await _mensajes.close();
    await _estado.close();
  }

  Future<void> _abrir() async {
    if (!_quiereAbierto || _actual == LinkStatus.conectando) return;
    _fijarEstado(LinkStatus.conectando);
    try {
      final canal = WebSocketChannel.connect(url);
      await canal.ready;
      if (!_quiereAbierto) {
        await canal.sink.close();
        _fijarEstado(LinkStatus.desconectado);
        return;
      }
      _canal = canal;
      _intento = 0;
      _ultimaVez = DateTime.now();
      _sub = canal.stream.listen(
        _alRecibir,
        onDone: _alCerrarse,
        onError: (_) => _alCerrarse(),
        cancelOnError: true,
      );
      _fijarEstado(LinkStatus.conectado);
      _iniciarLatido();
      await onOpen?.call();
    } catch (_) {
      _alCerrarse();
    }
  }

  void _alRecibir(dynamic crudo) {
    _ultimaVez = DateTime.now();
    final msg = jsonDecode(crudo as String) as Map<String, dynamic>;
    if (msg['type'] == 'pong') return;
    if (!_mensajes.isClosed) _mensajes.add(msg);
  }

  void _alCerrarse() {
    _desmontar();
    _fijarEstado(LinkStatus.desconectado);
    if (_quiereAbierto && !(_reintento?.isActive ?? false)) {
      final espera = Duration(seconds: min(30, 1 << min(_intento, 5)));
      _intento++;
      _reintento = Timer(espera, _abrir);
    }
  }

  void _iniciarLatido() {
    _latido?.cancel();
    _latido = Timer.periodic(const Duration(seconds: 10), (_) {
      if (DateTime.now().difference(_ultimaVez) > const Duration(seconds: 25)) {
        _alCerrarse(); // conexión zombi: reintentar
        return;
      }
      enviar({'type': 'ping'});
    });
  }

  void _desmontar() {
    _latido?.cancel();
    _latido = null;
    _sub?.cancel();
    _sub = null;
    try {
      _canal?.sink.close();
    } catch (_) {}
    _canal = null;
  }

  void _fijarEstado(LinkStatus s) {
    if (_actual == s) return;
    _actual = s;
    if (!_estado.isClosed) _estado.add(s);
  }
}

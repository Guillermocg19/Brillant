import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Dirección del servidor. Se puede cambiar al ejecutar:
///   flutter run --dart-define=API_URL=https://mi-servidor.com
String urlServidor() {
  const definida = String.fromEnvironment('API_URL');
  if (definida.isNotEmpty) return definida;
  // En el emulador de Android "localhost" es el propio emulador: tu PC es 10.0.2.2.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

class Usuario {
  final int id;
  final String nombre;
  final String correo;

  const Usuario({required this.id, required this.nombre, required this.correo});

  factory Usuario.desdeJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
      );
}

/// Error con un mensaje listo para mostrarle al usuario.
class AuthError implements Exception {
  final String mensaje;

  /// Código HTTP de la respuesta (null si ni siquiera hubo respuesta).
  final int? estado;

  const AuthError(this.mensaje, [this.estado]);

  @override
  String toString() => mensaje;
}

/// Habla con el servidor y guarda la sesión. Las pantallas lo escuchan
/// (es un ChangeNotifier) y se actualizan solas cuando alguien entra o sale.
class ServicioAuth extends ChangeNotifier {
  ServicioAuth({
    String? urlBase,
    http.Client? cliente,
    FlutterSecureStorage? almacen,
  })  : _url = urlBase ?? urlServidor(),
        _http = cliente ?? http.Client(),
        _almacen = almacen ?? const FlutterSecureStorage();

  final String _url;
  final http.Client _http;
  final FlutterSecureStorage _almacen;

  static const _claveToken = 'brillant_token';

  String? _token;
  Usuario? _usuario;

  /// La cuenta que tiene la sesión abierta (null si no hay sesión).
  Usuario? get usuario => _usuario;

  /// true mientras la app revisa si ya había una sesión guardada.
  bool iniciando = true;

  /// true si la cuenta se acaba de borrar (para avisarlo en la pantalla de acceso).
  bool cuentaBorrada = false;

  /// Al abrir la app: si hay un token guardado, comprueba que siga sirviendo.
  Future<void> restaurarSesion() async {
    try {
      _token = await _almacen.read(key: _claveToken);
      if (_token != null) {
        final datos = await _pedir('GET', '/yo');
        _usuario = Usuario.desdeJson(datos['usuario'] as Map<String, dynamic>);
      }
    } on AuthError catch (e) {
      // Si el servidor dijo que el token no sirve, se borra.
      // Si solo fue falta de conexión, se conserva para el próximo intento.
      if (e.estado == 401 || e.estado == 403) {
        await _salir();
      }
    } catch (_) {
      // Respuesta inesperada: se queda en la pantalla de acceso.
    } finally {
      iniciando = false;
      notifyListeners();
    }
  }

  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final datos = await _pedir('POST', '/registro', cuerpo: {
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
    });
    await _entrar(datos);
  }

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final datos = await _pedir('POST', '/login', cuerpo: {
      'correo': correo,
      'contrasena': contrasena,
    });
    await _entrar(datos);
  }

  Future<void> cerrarSesion() async {
    await _salir();
  }

  /// Borra la cuenta en el servidor (hay que volver a escribir la contraseña).
  Future<void> borrarCuenta(String contrasena) async {
    await _pedir('DELETE', '/cuenta', cuerpo: {'contrasena': contrasena});
    cuentaBorrada = true; // antes de _salir(), que ya notifica
    await _salir();
  }

  // ---------- Internos ----------

  Future<void> _entrar(Map<String, dynamic> datos) async {
    _token = datos['token'] as String;
    _usuario = Usuario.desdeJson(datos['usuario'] as Map<String, dynamic>);
    cuentaBorrada = false;
    // El token se guarda cifrado (Keystore / Keychain), no en SharedPreferences.
    await _almacen.write(key: _claveToken, value: _token);
    notifyListeners();
  }

  Future<void> _salir() async {
    _token = null;
    _usuario = null;
    await _almacen.delete(key: _claveToken);
    notifyListeners();
  }

  Future<Map<String, dynamic>> _pedir(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
  }) async {
    final peticion = http.Request(metodo, Uri.parse('$_url$ruta'))
      ..headers['Content-Type'] = 'application/json';
    if (_token != null) peticion.headers['Authorization'] = 'Bearer $_token';
    if (cuerpo != null) peticion.body = jsonEncode(cuerpo);

    http.Response respuesta;
    try {
      final flujo =
          await _http.send(peticion).timeout(const Duration(seconds: 15));
      respuesta = await http.Response.fromStream(flujo);
    } on TimeoutException {
      throw const AuthError('El servidor tardó demasiado en responder.');
    } catch (_) {
      // ClientException, SocketException, etc.
      throw const AuthError('No se pudo conectar con el servidor.');
    }

    var datos = <String, dynamic>{};
    try {
      if (respuesta.body.isNotEmpty) {
        datos = jsonDecode(utf8.decode(respuesta.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (_) {
      // Respuesta que no es JSON (p. ej. una página de error de un proxy).
    }

    if (respuesta.statusCode >= 400) {
      throw AuthError(
        datos['error'] as String? ??
            'Error del servidor (${respuesta.statusCode}).',
        respuesta.statusCode,
      );
    }
    return datos;
  }
}
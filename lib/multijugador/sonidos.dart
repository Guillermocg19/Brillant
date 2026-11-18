import 'package:audioplayers/audioplayers.dart';

/// Efectos de sonido del multijugador. Los archivos están en assets/sonidos/.
///
/// Nunca lanza errores: si el dispositivo o el navegador no deja reproducir
/// (en web el primer sonido se bloquea hasta que la persona toca la pantalla),
/// simplemente no suena.
class Sonidos {
  Sonidos._();

  /// Se puede apagar desde el botón de volumen de la pantalla de juego.
  static bool activado = true;

  static final AudioPlayer _reproductor = AudioPlayer();

  static Future<void> _tocar(String archivo) async {
    if (!activado) return;
    try {
      await _reproductor.stop();
      await _reproductor.play(AssetSource('sonidos/$archivo'));
    } catch (_) {
      // Sin sonido: no pasa nada.
    }
  }

  static Future<void> dados() => _tocar('dados.wav');
  static Future<void> colocar() => _tocar('colocar.wav');
  static Future<void> victoria() => _tocar('victoria.wav');
  static Future<void> derrota() => _tocar('derrota.wav');
}

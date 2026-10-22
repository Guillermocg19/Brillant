import 'dart:math';

/// Random para pruebas: devuelve los dados en el orden que le pasas
/// (valores del 1 al 6). Cada tirada consume DOS valores, y si los dados
/// no dan jugada y el juego vuelve a tirar, consume otros dos.
class RandomFijo implements Random {
  final List<int> _dados;
  int _i = 0;

  RandomFijo(this._dados);

  @override
  int nextInt(int max) {
    if (_i >= _dados.length) {
      throw StateError(
        'RandomFijo se quedó sin dados (pediste más de ${_dados.length}). '
        'Recuerda que cada tirada consume 2 y cada re-tirada otros 2.',
      );
    }
    return _dados[_i++] - 1; // JuegoBloc hace nextInt(6) + 1
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
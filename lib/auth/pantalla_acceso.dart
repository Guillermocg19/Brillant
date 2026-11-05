import 'package:flutter/material.dart';
import 'servicio_auth.dart';

final _correoValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Una sola pantalla para entrar y para crear la cuenta (se alterna con un botón).
class PantallaAcceso extends StatefulWidget {
  const PantallaAcceso({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  State<PantallaAcceso> createState() => _PantallaAccesoState();
}

class _PantallaAccesoState extends State<PantallaAcceso> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();

  bool _registro = false; // false = iniciar sesión, true = crear cuenta
  bool _cargando = false;
  bool _ocultar = true;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      if (_registro) {
        await widget.auth.registrar(
          nombre: _nombre.text.trim(),
          correo: _correo.text.trim(),
          contrasena: _contrasena.text,
        );
      } else {
        await widget.auth.iniciarSesion(
          correo: _correo.text.trim(),
          contrasena: _contrasena.text,
        );
      }
      // Al entrar, main.dart cambia solo a la pantalla de inicio.
    } on AuthError catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Brillant',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registro ? 'Crear cuenta' : 'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    if (widget.auth.cuentaBorrada && !_registro)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Tu cuenta se borró correctamente.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          key: const ValueKey('error_acceso'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    if (_registro) ...[
                      TextFormField(
                        key: const ValueKey('campo_nombre'),
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Escribe tu nombre.' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const ValueKey('campo_correo'),
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _correoValido.hasMatch((v ?? '').trim())
                          ? null
                          : 'Escribe un correo válido.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('campo_contrasena'),
                      controller: _contrasena,
                      obscureText: _ocultar,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: _registro ? 'Mínimo 10 caracteres.' : null,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: (v) {
                        final texto = v ?? '';
                        if (texto.isEmpty) return 'Escribe tu contraseña.';
                        if (_registro && texto.length < 10) {
                          return 'Debe tener al menos 10 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (_registro) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('campo_confirmar'),
                        controller: _confirmar,
                        obscureText: _ocultar,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Repite la contraseña',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == _contrasena.text ? null : 'Las contraseñas no coinciden.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        key: const ValueKey('boton_enviar'),
                        onPressed: _cargando ? null : _enviar,
                        child: _cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : Text(_registro ? 'Crear cuenta' : 'Entrar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('boton_alternar'),
                      onPressed: _cargando
                          ? null
                          : () => setState(() {
                                _registro = !_registro;
                                _error = null;
                              }),
                      child: Text(
                        _registro
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Crea una',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'servicio_auth.dart';

/// "Mi cuenta": muestra los datos, permite cerrar sesión y borrar la cuenta.
class PantallaCuenta extends StatelessWidget {
  const PantallaCuenta({super.key, required this.auth});

  final ServicioAuth auth;

  Future<void> _cerrarSesion(BuildContext context) async {
    await auth.cerrarSesion();
    // main.dart ya mostró la pantalla de acceso; se quita esta encima.
    if (context.mounted) Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = auth.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  usuario?.nombre ?? '',
                  key: const ValueKey('cuenta_nombre'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  usuario?.correo ?? '',
                  key: const ValueKey('cuenta_correo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  key: const ValueKey('boton_cerrar_sesion'),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  onPressed: () => _cerrarSesion(context),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const ValueKey('boton_borrar_cuenta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Borrar mi cuenta'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => _DialogoBorrar(auth: auth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Borrar la cuenta es permanente: se pide la contraseña otra vez.
class _DialogoBorrar extends StatefulWidget {
  const _DialogoBorrar({required this.auth});

  final ServicioAuth auth;

  @override
  State<_DialogoBorrar> createState() => _DialogoBorrarState();
}

class _DialogoBorrarState extends State<_DialogoBorrar> {
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _borrar() async {
    if (_contrasena.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await widget.auth.borrarCuenta(_contrasena.text);
      // Cierra este diálogo y "Mi cuenta": main.dart ya mostró la pantalla de acceso.
      if (mounted) Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on AuthError catch (e) {
      if (!mounted) return;
      if (e.estado == 401) {
        // La sesión ya no era válida: se vuelve a la pantalla de acceso.
        Navigator.of(context).popUntil((ruta) => ruta.isFirst);
      } else {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Borrar tu cuenta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Es permanente: se borrarán tu cuenta y tus datos. '
            'Escribe tu contraseña para confirmar.',
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                key: const ValueKey('error_borrar'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextField(
            key: const ValueKey('campo_contrasena_borrar'),
            controller: _contrasena,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            onSubmitted: (_) => _borrar(),
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('boton_cancelar_borrado'),
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('boton_confirmar_borrado'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _cargando ? null : _borrar,
          child: _cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Borrar para siempre'),
        ),
      ],
    );
  }
}
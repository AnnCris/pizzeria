import 'package:flutter/material.dart';
import '../../services/usuario_service.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('👥 Usuarios',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Nuevo usuario',
            onPressed: () => _dialogCrear(context),
          ),
        ],
      ),
      body: StreamBuilder<List<UsuarioDB>>(
        stream: UsuarioService.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }
          if (snap.hasError) {
            return _ErrorCard(mensaje: '${snap.error}');
          }
          final usuarios = snap.data ?? [];
          if (usuarios.isEmpty) {
            return _EmptyState(onCrear: () => _dialogCrear(context));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (_, i) => _UsuarioCard(
              usuario: usuarios[i],
              onEditar: () => _dialogEditar(context, usuarios[i]),
              onEliminar: () => _confirmarEliminar(context, usuarios[i]),
            ),
          );
        },
      ),
    );
  }

  // ── Diálogo crear ────────────────────────────────────────────────────────
  void _dialogCrear(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final emailCtrl  = TextEditingController();
    final passCtrl   = TextEditingController();
    String rol        = 'cajero';
    bool   cargando   = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Text('➕ ', style: TextStyle(fontSize: 20)),
            Text('Nuevo Usuario',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _Campo(ctrl: nombreCtrl, label: 'Nombre completo',
                  icono: Icons.person),
              const SizedBox(height: 12),
              _Campo(ctrl: emailCtrl, label: 'Correo electrónico',
                  icono: Icons.email,
                  tipo: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _Campo(ctrl: passCtrl, label: 'Contraseña (mín. 6 caracteres)',
                  icono: Icons.lock, ocultar: true),
              const SizedBox(height: 16),
              // Selector de rol
              const Align(alignment: Alignment.centerLeft,
                  child: Text('Rol:',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              _SelectorRol(
                rolSeleccionado: rol,
                onCambio: (r) => setS(() => rol = r),
              ),
              // Error
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(
              onPressed: cargando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700]),
              onPressed: cargando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty ||
                          emailCtrl.text.isEmpty ||
                          passCtrl.text.isEmpty) {
                        setS(() => error = 'Completa todos los campos');
                        return;
                      }
                      if (passCtrl.text.length < 6) {
                        setS(() => error =
                            'La contraseña debe tener al menos 6 caracteres');
                        return;
                      }
                      setS(() { cargando = true; error = null; });
                      final err = await UsuarioService.crear(
                        nombreCtrl.text, emailCtrl.text,
                        passCtrl.text, rol,
                      );
                      if (!ctx.mounted) return;
                      if (err != null) {
                        setS(() { cargando = false; error = err; });
                      } else {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Usuario creado correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: cargando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Crear',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Diálogo editar ───────────────────────────────────────────────────────
  void _dialogEditar(BuildContext context, UsuarioDB u) {
    final nombreCtrl = TextEditingController(text: u.nombre);
    String rol    = u.rol;
    bool   activo = u.activo;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Text('✏️ ', style: TextStyle(fontSize: 20)),
            Text('Editar Usuario',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _Campo(ctrl: nombreCtrl, label: 'Nombre completo',
                icono: Icons.person),
            const SizedBox(height: 12),
            // Email — solo lectura
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                Icon(Icons.email, color: Colors.grey[400], size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(u.email,
                    style: TextStyle(color: Colors.grey[600]))),
                const Text('(no editable)',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft,
                child: Text('Rol:',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            _SelectorRol(
              rolSeleccionado: rol,
              onCambio: (r) => setS(() => rol = r),
            ),
            const SizedBox(height: 12),
            // Switch activo
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: const Text('Usuario activo'),
                subtitle: Text(activo ? 'Puede iniciar sesión' : 'Acceso bloqueado'),
                value: activo,
                activeThumbColor: Colors.red[700],
                activeTrackColor: Colors.red[100],
                onChanged: (v) => setS(() => activo = v),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700]),
              onPressed: () async {
                await UsuarioService.actualizar(
                    u.id, nombreCtrl.text, rol, activo);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Usuario actualizado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Guardar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmar eliminar ───────────────────────────────────────────────────
  void _confirmarEliminar(BuildContext context, UsuarioDB u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('🚫 Desactivar usuario'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('¿Desactivar a este usuario?'),
          const SizedBox(height: 8),
          Text(u.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(u.email,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
                '⚠️ El usuario no podrá iniciar sesión.\nPodrás reactivarlo después.',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            onPressed: () async {
              await UsuarioService.eliminar(u.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${u.nombre} desactivado'),
                    backgroundColor: Colors.orange[700],
                  ),
                );
              }
            },
            child: const Text('Desactivar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Card de usuario
// ════════════════════════════════════════════════════════════════════════════

class _UsuarioCard extends StatelessWidget {
  final UsuarioDB usuario;
  final VoidCallback onEditar, onEliminar;
  const _UsuarioCard({required this.usuario,
      required this.onEditar, required this.onEliminar});

  Color get _rolColor {
    switch (usuario.rol) {
      case 'admin':  return Colors.purple[700]!;
      case 'cocina': return Colors.orange[700]!;
      default:       return Colors.blue[700]!;
    }
  }

  String get _rolEmoji {
    switch (usuario.rol) {
      case 'admin':  return '👑';
      case 'cocina': return '👨‍🍳';
      default:       return '💰';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 6)],
          border: usuario.activo
              ? null
              : Border.all(color: Colors.grey.shade300),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: _rolColor.withValues(alpha: 0.15),
            child: Text(_rolEmoji,
                style: const TextStyle(fontSize: 22)),
          ),
          title: Text(usuario.nombre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: usuario.activo ? Colors.black : Colors.grey,
              )),
          subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(usuario.email,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _rolColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(usuario.rol,
                    style: TextStyle(color: _rolColor,
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              if (!usuario.activo) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Inactivo',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ),
              ],
            ]),
          ]),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: onEditar,
            ),
            IconButton(
              icon: Icon(Icons.person_off_outlined,
                  color: usuario.activo ? Colors.red : Colors.grey),
              onPressed: usuario.activo ? onEliminar : null,
            ),
          ]),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets reutilizables
// ════════════════════════════════════════════════════════════════════════════

class _Campo extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final TextInputType tipo;
  final bool ocultar;
  const _Campo({required this.ctrl, required this.label,
      required this.icono, this.tipo = TextInputType.text,
      this.ocultar = false});
  @override
  State<_Campo> createState() => _CampoState();
}

class _CampoState extends State<_Campo> {
  late bool _ocultar;
  @override
  void initState() { super.initState(); _ocultar = widget.ocultar; }

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.ctrl,
        keyboardType: widget.tipo,
        obscureText: _ocultar,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icono),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          suffixIcon: widget.ocultar
              ? IconButton(
                  icon: Icon(_ocultar
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                )
              : null,
        ),
      );
}

class _SelectorRol extends StatelessWidget {
  final String rolSeleccionado;
  final void Function(String) onCambio;
  const _SelectorRol(
      {required this.rolSeleccionado, required this.onCambio});

  static const _roles = [
    {'valor': 'admin',  'emoji': '👑', 'label': 'Admin'},
    {'valor': 'cajero', 'emoji': '💰', 'label': 'Cajero'},
    {'valor': 'cocina', 'emoji': '👨‍🍳', 'label': 'Cocina'},
  ];

  @override
  Widget build(BuildContext context) => Row(
        children: _roles.map((r) {
          final sel = r['valor'] == rolSeleccionado;
          return Expanded(
            child: GestureDetector(
              onTap: () => onCambio(r['valor']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                    vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? Colors.red[700] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel
                          ? Colors.red[700]!
                          : Colors.grey.shade300),
                ),
                child: Column(children: [
                  Text(r['emoji']!,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(r['label']!,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                ]),
              ),
            ),
          );
        }).toList(),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyState({required this.onCrear});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('👥', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text('Sin usuarios registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text('Crear primer usuario',
                style: TextStyle(color: Colors.white)),
            onPressed: onCrear,
          ),
        ]),
      );
}

class _ErrorCard extends StatelessWidget {
  final String mensaje;
  const _ErrorCard({required this.mensaje});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('Error de conexión',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Text(mensaje,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                  'Verifica que Firestore esté configurado y que los índices estén creados.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
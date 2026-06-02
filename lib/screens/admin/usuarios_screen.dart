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
            onPressed: () => _dialogCrear(context),
          ),
        ],
      ),
      body: StreamBuilder<List<UsuarioDB>>(
        stream: UsuarioService.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final usuarios = snap.data ?? [];
          if (usuarios.isEmpty) {
            return const Center(child: Text('Sin usuarios registrados',
                style: TextStyle(color: Colors.grey)));
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

  void _dialogCrear(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final emailCtrl  = TextEditingController();
    final passCtrl   = TextEditingController();
    String rol = 'cajero';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('➕ Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _campo(nombreCtrl, 'Nombre completo', Icons.person),
              const SizedBox(height: 12),
              _campo(emailCtrl, 'Correo electrónico', Icons.email,
                  tipo: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _campo(passCtrl, 'Contraseña', Icons.lock, ocultar: true),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft,
                  child: Text('Rol:', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Row(children: ['admin', 'cajero', 'cocina'].map((r) =>
                GestureDetector(
                  onTap: () => setS(() => rol = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: rol == r ? Colors.red[700] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: rol == r ? Colors.red[700]! : Colors.grey.shade300),
                    ),
                    child: Text(r, style: TextStyle(
                      color: rol == r ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                )).toList(),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () async {
                if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                try {
                  await UsuarioService.crear(
                      nombreCtrl.text.trim(), emailCtrl.text.trim(),
                      passCtrl.text.trim(), rol);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogEditar(BuildContext context, UsuarioDB u) {
    final nombreCtrl = TextEditingController(text: u.nombre);
    String rol    = u.rol;
    bool   activo = u.activo;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('✏️ Editar Usuario'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo(nombreCtrl, 'Nombre completo', Icons.person),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: u.email,
                prefixIcon: const Icon(Icons.email),
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft,
                child: Text('Rol:', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Row(children: ['admin', 'cajero', 'cocina'].map((r) =>
              GestureDetector(
                onTap: () => setS(() => rol = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: rol == r ? Colors.red[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: rol == r ? Colors.red[700]! : Colors.grey.shade300),
                  ),
                  child: Text(r, style: TextStyle(
                    color: rol == r ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.bold, fontSize: 13,
                  )),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Usuario activo'),
              value: activo,
              activeThumbColor: Colors.red[700],
              onChanged: (v) => setS(() => activo = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () async {
                await UsuarioService.actualizar(u.id, nombreCtrl.text.trim(), rol, activo);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, UsuarioDB u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ Desactivar usuario'),
        content: Text('¿Desactivar a ${u.nombre}?\nPodrás reactivarlo después.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              await UsuarioService.eliminar(u.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Desactivar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      {TextInputType tipo = TextInputType.text, bool ocultar = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: tipo,
      obscureText: ocultar,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioDB usuario;
  final VoidCallback onEditar, onEliminar;
  const _UsuarioCard({required this.usuario, required this.onEditar, required this.onEliminar});

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
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      border: usuario.activo ? null : Border.all(color: Colors.grey.shade300),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: _rolColor.withValues(alpha: 0.15),
        child: Text(_rolEmoji, style: const TextStyle(fontSize: 22)),
      ),
      title: Text(usuario.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: usuario.activo ? Colors.black : Colors.grey,
          )),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(usuario.email, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _rolColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(usuario.rol,
                style: TextStyle(color: _rolColor, fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          if (!usuario.activo) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Inactivo',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
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
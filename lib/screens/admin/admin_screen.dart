import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mesa_provider.dart';
import '../../providers/orden_provider.dart';
import 'mesas_screen.dart';
import 'caja_screen.dart';
import 'usuarios_screen.dart';
import 'reportes_screen.dart';
import 'pizzas_admin_screen.dart';
import '../cocina_screen.dart';
import '../menu_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final mesas   = context.watch<MesaProvider>();
    final ordenes = context.watch<OrdenProvider>();
    final pendientes = ordenes.ordenes.where((o) => o.estado == 'pendiente').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: CustomScrollView(slivers: [

        // ── AppBar expandible ──────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 170,
          pinned: true,
          backgroundColor: Colors.red[800],
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF7B1717), Color(0xFFD4521A)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(children: [
                    const Text('🍕', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Text('La Bella Pizzería',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const Text('Panel de Administración',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('Bienvenido, ${auth.nombre ?? ""}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ])),
                    PopupMenuButton<String>(
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text((auth.nombre ?? 'A')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      onSelected: (val) {
                        if (val == 'logout') {
                          auth.logout();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const MenuScreen()));
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(enabled: false,
                            child: Text(auth.nombre ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold))),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'logout',
                            child: Row(children: [
                              Icon(Icons.logout, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Cerrar sesión'),
                            ])),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // ── KPIs ───────────────────────────────────────────────────
              Row(children: [
                _KpiCard(valor: '${mesas.libres}', label: 'Mesas libres',
                    emoji: '🟢', color: const Color(0xFF2E7D32)),
                const SizedBox(width: 10),
                _KpiCard(valor: '${mesas.ocupadas}', label: 'Ocupadas',
                    emoji: '🔴', color: const Color(0xFFC62828)),
                const SizedBox(width: 10),
                _KpiCard(valor: '$pendientes', label: 'Órdenes pend.',
                    emoji: '⏳', color: const Color(0xFFE65100)),
              ]),

              const SizedBox(height: 22),
              const Align(alignment: Alignment.centerLeft,
                child: Text('Módulos del sistema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),

              // ── Grid de módulos ────────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _ModuloCard(
                    emoji: '🍽️', titulo: 'Gestión de Mesas',
                    subtitulo: '${mesas.libres} libres · ${mesas.ocupadas} ocupadas',
                    gradiente: const [Color(0xFF1565C0), Color(0xFF1976D2)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MesasScreen())),
                  ),
                  _ModuloCard(
                    emoji: '🍕', titulo: 'Menú / Pizzas',
                    subtitulo: 'Crear, editar y eliminar',
                    gradiente: const [Color(0xFFB03A2E), Color(0xFFC0392B)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PizzasAdminScreen())),
                  ),
                  _ModuloCard(
                    emoji: '💰', titulo: 'Caja y Cierre',
                    subtitulo: 'Cobros del día',
                    gradiente: const [Color(0xFF00695C), Color(0xFF00897B)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CajaScreen())),
                  ),
                  _ModuloCard(
                    emoji: '📊', titulo: 'Reportes',
                    subtitulo: 'Ventas y estadísticas',
                    gradiente: const [Color(0xFF2E7D32), Color(0xFF388E3C)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ReportesScreen())),
                  ),
                  _ModuloCard(
                    emoji: '👨‍🍳', titulo: 'Cocina',
                    subtitulo: '$pendientes pendientes ahora',
                    gradiente: const [Color(0xFFD84315), Color(0xFFE64A19)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CocinaScreen())),
                  ),
                  _ModuloCard(
                    emoji: '👥', titulo: 'Usuarios',
                    subtitulo: 'Cajeros y cocina',
                    gradiente: const [Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const UsuariosScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String valor, label, emoji;
  final Color color;
  const _KpiCard({required this.valor, required this.label,
      required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(valor, style: TextStyle(color: color, fontSize: 22,
                fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _ModuloCard extends StatelessWidget {
  final String emoji, titulo, subtitulo;
  final List<Color> gradiente;
  final VoidCallback onTap;
  const _ModuloCard({required this.emoji, required this.titulo,
      required this.subtitulo, required this.gradiente, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: gradiente),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: gradiente[0].withValues(alpha: 0.4),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                  const Spacer(),
                  Text(titulo, style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitulo, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );
}
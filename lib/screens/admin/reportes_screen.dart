import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/orden_provider.dart';
import 'package:intl/intl.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordenes  = context.watch<OrdenProvider>().ordenes;
    final hoy      = DateFormat('dd/MM/yyyy').format(DateTime.now());
    double totalDia = ordenes.fold(0, (s, o) => s + o.total);

    final Map<String, int> pizzaConteo = {};
    for (final o in ordenes) {
      for (final item in o.items) {
        pizzaConteo[item.nombre] = (pizzaConteo[item.nombre] ?? 0) + item.cantidad;
      }
    }
    final topPizzas = pizzaConteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Conteo por estado
    final pendientes  = ordenes.where((o) => o.estado == 'pendiente').length;
    final enPrep      = ordenes.where((o) => o.estado == 'en_preparacion').length;
    final listas      = ordenes.where((o) => o.estado == 'lista').length;
    final entregadas  = ordenes.where((o) => o.estado == 'entregada').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('📊 Reportes del Día',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Pizzas'),
            Tab(text: 'Órdenes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Tab 1: Resumen ───────────────────────────────────────
          _TabResumen(
            hoy: hoy,
            totalDia: totalDia,
            ordenes: ordenes,
            pendientes: pendientes,
            enPrep: enPrep,
            listas: listas,
            entregadas: entregadas,
          ),

          // ── Tab 2: Pizzas más vendidas ───────────────────────────
          _TabPizzas(topPizzas: topPizzas),

          // ── Tab 3: Lista de órdenes con opciones CRUD ────────────
          _TabOrdenes(ordenes: ordenes),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tab Resumen
// ════════════════════════════════════════════════════════════════════════════

class _TabResumen extends StatelessWidget {
  final String hoy;
  final double totalDia;
  final List<dynamic> ordenes;
  final int pendientes, enPrep, listas, entregadas;

  const _TabResumen({
    required this.hoy, required this.totalDia, required this.ordenes,
    required this.pendientes, required this.enPrep,
    required this.listas, required this.entregadas,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[800], borderRadius: BorderRadius.circular(20)),
            child: Text('📅 $hoy',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),

        // KPIs principales
        Row(children: [
          _StatCard(valor: 'Bs. ${totalDia.toStringAsFixed(2)}',
              label: 'Total del día', emoji: '💰', color: const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          _StatCard(valor: '${ordenes.length}',
              label: 'Órdenes totales', emoji: '📋', color: const Color(0xFF1565C0)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _StatCard(
              valor: ordenes.isEmpty ? 'Bs. 0'
                  : 'Bs. ${(totalDia / ordenes.length).toStringAsFixed(2)}',
              label: 'Ticket promedio', emoji: '🧾', color: const Color(0xFFE65100)),
          const SizedBox(width: 12),
          _StatCard(valor: '$entregadas',
              label: 'Entregadas', emoji: '✅', color: const Color(0xFF00695C)),
        ]),
        const SizedBox(height: 20),

        // Pipeline de estados
        const Text('🔄 Pipeline de órdenes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Row(children: [
            _PipelineStep(emoji: '⏳', label: 'Pendiente',  count: pendientes, color: Colors.orange),
            _Arrow(),
            _PipelineStep(emoji: '🔥', label: 'Preparando', count: enPrep,    color: Colors.blue),
            _Arrow(),
            _PipelineStep(emoji: '✅', label: 'Lista',       count: listas,    color: Colors.green),
            _Arrow(),
            _PipelineStep(emoji: '🎉', label: 'Entregada',  count: entregadas, color: Colors.teal),
          ]),
        ),

        const SizedBox(height: 20),
        // Ingresos por mesa
        if (ordenes.isNotEmpty) ...[
          const Text('🍽️ Ingresos por mesa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _IngresosPorMesa(ordenes: ordenes),
        ],
      ]),
    );
  }
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey);
}

class _PipelineStep extends StatelessWidget {
  final String emoji, label;
  final int count;
  final Color color;
  const _PipelineStep({required this.emoji, required this.label,
      required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(color: color, fontSize: 20,
              fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      );
}

class _IngresosPorMesa extends StatelessWidget {
  final List<dynamic> ordenes;
  const _IngresosPorMesa({required this.ordenes});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> porMesa = {};
    for (final o in ordenes) {
      porMesa[o.mesa] = (porMesa[o.mesa] ?? 0) + o.total;
    }
    final lista = porMesa.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: lista.map((e) {
          final max = lista.first.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SizedBox(width: 70, child: Text(e.key,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.value / max,
                    backgroundColor: Colors.grey[100],
                    color: Colors.red[700],
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Bs. ${e.value.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tab Pizzas
// ════════════════════════════════════════════════════════════════════════════

class _TabPizzas extends StatelessWidget {
  final List<MapEntry<String, int>> topPizzas;
  const _TabPizzas({required this.topPizzas});

  @override
  Widget build(BuildContext context) {
    if (topPizzas.isEmpty) {
      return const Center(child: Text('Sin datos aún 🍕',
          style: TextStyle(color: Colors.grey, fontSize: 16)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topPizzas.length,
      itemBuilder: (_, i) {
        final item = topPizzas[i];
        final max  = topPizzas.first.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(children: [
            // Posición
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: i == 0 ? Colors.amber[700] : i == 1 ? Colors.grey[400] :
                       i == 2 ? Colors.brown[400] : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(
                i < 3 ? ['🥇','🥈','🥉'][i] : '${i+1}',
                style: TextStyle(
                    fontSize: i < 3 ? 18 : 14,
                    fontWeight: FontWeight.bold,
                    color: i < 3 ? Colors.white : Colors.red[700]),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.value / max,
                  backgroundColor: Colors.grey[100],
                  color: Colors.red[700],
                  minHeight: 6,
                ),
              ),
            ])),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
              child: Text('×${item.value}',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
            ),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tab Órdenes con opciones CRUD
// ════════════════════════════════════════════════════════════════════════════

class _TabOrdenes extends StatelessWidget {
  final List<dynamic> ordenes;
  const _TabOrdenes({required this.ordenes});

  Color _estadoColor(String e) {
    switch (e) {
      case 'pendiente':      return Colors.orange;
      case 'en_preparacion': return Colors.blue;
      case 'lista':          return Colors.green;
      case 'entregada':      return Colors.teal;
      default:               return Colors.grey;
    }
  }

  String _estadoLabel(String e) {
    switch (e) {
      case 'pendiente':      return '⏳ Pendiente';
      case 'en_preparacion': return '🔥 Preparando';
      case 'lista':          return '✅ Lista';
      case 'entregada':      return '🎉 Entregada';
      default:               return e;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ordenes.isEmpty) {
      return const Center(child: Text('Sin órdenes hoy 📋',
          style: TextStyle(color: Colors.grey, fontSize: 16)));
    }

    final provider = context.read<OrdenProvider>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordenes.length,
      itemBuilder: (_, i) {
        final o = ordenes[ordenes.length - 1 - i]; // más recientes primero
        final color = _estadoColor(o.estado);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6)],
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('🍕', style: TextStyle(fontSize: 20)),
            ),
            title: Row(children: [
              Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(_estadoLabel(o.estado),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${o.mesa} · ${DateFormat('HH:mm').format(o.hora)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('${o.items.length} producto(s)',
                  style: const TextStyle(fontSize: 11)),
            ]),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Bs. ${o.total.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  onSelected: (val) {
                    if (val != 'ver') {
                      provider.actualizarEstado(o.id, val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Estado actualizado a: $val'),
                            backgroundColor: Colors.green),
                      );
                    } else {
                      _verDetalle(context, o);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'ver', child: Text('👁️ Ver detalle')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'pendiente',      child: Text('⏳ Pendiente')),
                    const PopupMenuItem(value: 'en_preparacion', child: Text('🔥 En preparación')),
                    const PopupMenuItem(value: 'lista',          child: Text('✅ Lista')),
                    const PopupMenuItem(value: 'entregada',      child: Text('🎉 Entregada')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _verDetalle(BuildContext context, dynamic o) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('📋 Orden #${o.id}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DetalleRow('Mesa', o.mesa),
            _DetalleRow('Hora', DateFormat('dd/MM/yyyy HH:mm').format(o.hora)),
            _DetalleRow('Estado', o.estado),
            const Divider(),
            ...o.items.map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text('${item.nombre} (${item.tamano})')),
                Text('×${item.cantidad}'),
                const SizedBox(width: 8),
                Text('Bs. ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            )),
            const Divider(),
            _DetalleRow('TOTAL', 'Bs. ${o.total.toStringAsFixed(2)}'),
            if (o.notasGenerales.isNotEmpty)
              _DetalleRow('Notas', o.notasGenerales),
          ]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DetalleRow extends StatelessWidget {
  final String label, valor;
  const _DetalleRow(this.label, this.valor);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets reutilizables
// ════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String valor, label, emoji;
  final Color color;
  const _StatCard({required this.valor, required this.label,
      required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(valor, style: TextStyle(color: color, fontSize: 18,
                fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ),
      );
}
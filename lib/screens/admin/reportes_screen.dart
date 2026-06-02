import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/orden_provider.dart';
import 'package:intl/intl.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordenes = context.watch<OrdenProvider>().ordenes;
    final hoy = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Calcular estadísticas
    double totalDia = ordenes.fold(0, (s, o) => s + o.total);
    final Map<String, int> pizzaConteo = {};
    for (final o in ordenes) {
      for (final item in o.items) {
        pizzaConteo[item.nombre] =
            (pizzaConteo[item.nombre] ?? 0) + item.cantidad;
      }
    }
    final topPizzas = pizzaConteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('📊 Reportes del Día',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Fecha
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('📅 $hoy',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),

          // KPIs
          Row(children: [
            _StatCard(valor: 'Bs. ${totalDia.toStringAsFixed(2)}',
                label: 'Total del día', emoji: '💰',
                color: const Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            _StatCard(valor: '${ordenes.length}',
                label: 'Órdenes totales', emoji: '📋',
                color: const Color(0xFF1565C0)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _StatCard(
                valor: ordenes.isEmpty
                    ? 'Bs. 0'
                    : 'Bs. ${(totalDia / ordenes.length).toStringAsFixed(2)}',
                label: 'Ticket promedio', emoji: '🧾',
                color: const Color(0xFFE65100)),
            const SizedBox(width: 12),
            _StatCard(
                valor: '${ordenes.where((o) => o.estado == 'lista').length}',
                label: 'Entregadas', emoji: '✅',
                color: const Color(0xFF00695C)),
          ]),

          const SizedBox(height: 24),

          // Top pizzas
          const Text('🍕 Pizzas más vendidas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (topPizzas.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Sin datos aún', style: TextStyle(color: Colors.grey)),
            ))
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: topPizzas.take(8).toList().asMap().entries.map((e) {
                  final idx  = e.key;
                  final item = e.value;
                  final max  = topPizzas.first.value;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(children: [
                      Row(children: [
                        Text('${idx + 1}.',
                            style: TextStyle(color: Colors.grey[500],
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.key,
                            style: const TextStyle(fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('×${item.value}',
                              style: TextStyle(color: Colors.red[700],
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: item.value / max,
                        backgroundColor: Colors.grey[100],
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      if (idx < topPizzas.take(8).length - 1)
                        Divider(color: Colors.grey.shade100, height: 16),
                    ]),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // Lista de órdenes del día
          const Text('📋 Órdenes del día',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (ordenes.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Sin órdenes hoy', style: TextStyle(color: Colors.grey)),
            ))
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: ordenes.reversed.map((o) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🍕', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('#${o.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${o.mesa} · ${DateFormat('HH:mm').format(o.hora)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ])),
                    Text('Bs. ${o.total.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.red[800],
                            fontWeight: FontWeight.bold)),
                  ]),
                )).toList(),
              ),
            ),
        ]),
      ),
    );
  }
}

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
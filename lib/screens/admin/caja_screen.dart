import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/orden_provider.dart';

class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordenes  = context.watch<OrdenProvider>().ordenes;
    final pendCobro = ordenes.where((o) => o.estado == 'lista').toList();
    final totalDia  = ordenes.fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('💰 Caja',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Total del día
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              const Text('💰 Total recaudado hoy',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Bs. ${totalDia.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36,
                      fontWeight: FontWeight.bold)),
              Text('${ordenes.length} órdenes',
                  style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 20),

          // Órdenes pendientes de cobro
          Row(children: [
            const Text('⏳ Pendientes de cobro',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (pendCobro.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${pendCobro.length}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 10),

          if (pendCobro.isEmpty)
            _EmptyCard(mensaje: 'Sin órdenes pendientes de cobro 🎉')
          else
            ...pendCobro.map((o) => _OrdenCajaCard(
              orden: o,
              onCobrar: () =>
                  context.read<OrdenProvider>().actualizarEstado(o.id, 'entregada'),
            )),

          const SizedBox(height: 20),

          // Cierre del día
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.lock_clock, color: Colors.white),
              label: const Text('Cerrar Caja del Día',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold)),
              onPressed: () => _confirmarCierre(context, totalDia, ordenes.length),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmarCierre(BuildContext context, double total, int cantidad) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🔒 Cierre de Caja'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Resumen del día:'),
          const SizedBox(height: 12),
          _ResumenRow(label: 'Total recaudado',
              valor: 'Bs. ${total.toStringAsFixed(2)}'),
          _ResumenRow(label: 'Órdenes atendidas', valor: '$cantidad'),
          _ResumenRow(label: 'Fecha',
              valor: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
          const SizedBox(height: 12),
          const Text('¿Confirmar cierre del día?',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green[700],
                  content: Text(
                      '✅ Caja cerrada · Bs. ${total.toStringAsFixed(2)} · $cantidad órdenes'),
                ),
              );
            },
            child: const Text('Confirmar cierre',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _OrdenCajaCard extends StatelessWidget {
  final dynamic orden;
  final VoidCallback onCobrar;
  const _OrdenCajaCard({required this.orden, required this.onCobrar});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
          boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.1),
              blurRadius: 6)],
        ),
        child: Row(children: [
          const Text('💰', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('#${orden.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(orden.mesa,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('${orden.items.length} productos',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Bs. ${orden.total.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.green[700], fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onCobrar,
              child: const Text('Cobrar',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ]),
        ]),
      );
}

class _ResumenRow extends StatelessWidget {
  final String label, valor;
  const _ResumenRow({required this.label, required this.valor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );
}

class _EmptyCard extends StatelessWidget {
  final String mensaje;
  const _EmptyCard({required this.mensaje});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(mensaje, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
      );
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/orden_provider.dart';
import '../../models/orden.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});
  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordenes   = context.watch<OrdenProvider>().ordenes;
    final pendCobro = ordenes.where((o) => o.estado == 'lista').toList();
    final cobradas  = ordenes.where((o) => o.estado == 'entregada').toList();
    final totalDia  = ordenes.fold<double>(0, (s, o) => s + o.total);
    final totalCobrado = cobradas.fold<double>(0, (s, o) => s + o.total);
    final totalPendiente = pendCobro.fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('💰 Caja',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Por cobrar (${pendCobro.length})'),
            Tab(text: 'Cobradas (${cobradas.length})'),
          ],
        ),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _TotalChip(label: 'Total día',     valor: totalDia,      color: Colors.blue[700]!),
            const SizedBox(width: 8),
            _TotalChip(label: 'Cobrado',       valor: totalCobrado,  color: Colors.green[700]!),
            const SizedBox(width: 8),
            _TotalChip(label: 'Por cobrar',    valor: totalPendiente, color: Colors.orange[700]!),
          ]),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              pendCobro.isEmpty
                  ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎉', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Sin órdenes pendientes de cobro',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: pendCobro.length,
                      itemBuilder: (_, i) => _OrdenCajaCard(
                        orden: pendCobro[i],
                        onCobrar: () => _confirmarCobro(context, pendCobro[i]),
                        onVerDetalle: () => _verDetalle(context, pendCobro[i]),
                      ),
                    ),

              cobradas.isEmpty
                  ? const Center(child: Text('Sin cobros registrados aún',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: cobradas.length,
                      itemBuilder: (_, i) => _OrdenCobradaCard(
                        orden: cobradas[cobradas.length - 1 - i],
                        onVerDetalle: () => _verDetalle(context, cobradas[cobradas.length - 1 - i]),
                      ),
                    ),
            ],
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.lock_clock, color: Colors.white),
                label: const Text('Cerrar Caja del Día',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                onPressed: () => _confirmarCierre(context, totalDia, ordenes.length),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _confirmarCobro(BuildContext context, Orden orden) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('💰 Confirmar cobro'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Orden #${orden.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(orden.mesa, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('TOTAL A COBRAR',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Bs. ${orden.total.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green[700], fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              context.read<OrdenProvider>().actualizarEstado(orden.firestoreId, 'entregada');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green[700],
                  content: Text('✅ Cobro registrado: Bs. ${orden.total.toStringAsFixed(2)}'),
                ),
              );
            },
            child: const Text('Confirmar cobro', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _verDetalle(BuildContext context, Orden orden) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('📋 Orden #${orden.id}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Row('Mesa', orden.mesa),
            _Row('Hora', DateFormat('HH:mm dd/MM').format(orden.hora)),
            _Row('Estado', orden.estado),
            const Divider(),
            ...orden.items.map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text('${item.nombre} (${item.tamano})',
                    style: const TextStyle(fontSize: 13))),
                Text('×${item.cantidad}  '),
                Text('Bs. ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )),
            const Divider(),
            _Row('TOTAL', 'Bs. ${orden.total.toStringAsFixed(2)}'),
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

  void _confirmarCierre(BuildContext context, double total, int cantidad) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🔒 Cierre de Caja'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Resumen del día:'),
          const SizedBox(height: 12),
          _Row('Total recaudado', 'Bs. ${total.toStringAsFixed(2)}'),
          _Row('Órdenes atendidas', '$cantidad'),
          _Row('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
          const SizedBox(height: 12),
          const Text('¿Confirmar cierre del día?',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green[700],
                  content: Text('✅ Caja cerrada · Bs. ${total.toStringAsFixed(2)} · $cantidad órdenes'),
                ),
              );
            },
            child: const Text('Confirmar cierre', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;
  const _TotalChip({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6)],
          ),
          child: Column(children: [
            Text('Bs. ${valor.toStringAsFixed(0)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _OrdenCajaCard extends StatelessWidget {
  final Orden orden;
  final VoidCallback onCobrar, onVerDetalle;
  const _OrdenCajaCard({required this.orden, required this.onCobrar, required this.onVerDetalle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
          boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.1), blurRadius: 6)],
        ),
        child: Column(children: [
          Row(children: [
            const Text('💰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${orden.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(orden.mesa, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('${orden.items.length} productos',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Bs. ${orden.total.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green[700], fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(DateFormat('HH:mm').format(orden.hora),
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onVerDetalle,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Ver detalle', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCobrar,
                icon: const Icon(Icons.payment, color: Colors.white, size: 16),
                label: const Text('Cobrar', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ]),
      );
}

class _OrdenCobradaCard extends StatelessWidget {
  final Orden orden;
  final VoidCallback onVerDetalle;
  const _OrdenCobradaCard({required this.orden, required this.onVerDetalle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#${orden.id}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${orden.mesa} · ${DateFormat('HH:mm').format(orden.hora)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          Text('Bs. ${orden.total.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
            onPressed: onVerDetalle,
          ),
        ]),
      );
}

class _Row extends StatelessWidget {
  final String l, v;
  const _Row(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(color: Colors.grey)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );
}
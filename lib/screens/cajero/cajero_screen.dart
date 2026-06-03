import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/orden_provider.dart';
import '../../providers/auth_provider.dart';

class CajeroScreen extends StatefulWidget {
  const CajeroScreen({super.key});
  @override
  State<CajeroScreen> createState() => _CajeroScreenState();
}

class _CajeroScreenState extends State<CajeroScreen>
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
    final auth     = context.watch<AuthProvider>();
    final ordenes  = context.watch<OrdenProvider>().ordenes;

    final porCobrar   = ordenes.where((o) => o.estado == 'lista').toList();
    final enCurso     = ordenes.where((o) =>
        o.estado == 'pendiente' || o.estado == 'en_preparacion').toList();
    final cobradas    = ordenes.where((o) => o.estado == 'entregada').toList();
    final totalDia    = ordenes.fold<double>(0, (s, o) => s + o.total);
    final totalCobrado = cobradas.fold<double>(0, (s, o) => s + o.total);
    final totalPend   = porCobrar.fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        // back lleva al menú del cliente
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('💰 Panel de Caja',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 17)),
          Text('Hola, ${auth.nombre ?? ""}',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Por cobrar (${porCobrar.length})'),
            Tab(text: 'Pedidos (${enCurso.length})'),
          ],
        ),
      ),
      body: Column(children: [
        // Resumen de totales
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _TotalChip(label: 'Total día',
                valor: totalDia, color: Colors.blue[700]!),
            const SizedBox(width: 8),
            _TotalChip(label: 'Cobrado',
                valor: totalCobrado, color: Colors.green[700]!),
            const SizedBox(width: 8),
            _TotalChip(label: 'Por cobrar',
                valor: totalPend, color: Colors.orange[700]!),
          ]),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [

              // ── Tab 1: Por cobrar ──────────────────────────────
              porCobrar.isEmpty
                  ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎉', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Sin órdenes pendientes de cobro',
                            style: TextStyle(color: Colors.grey,
                                fontSize: 16)),
                      ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: porCobrar.length,
                      itemBuilder: (_, i) => _OrdenCajaCard(
                        orden: porCobrar[i],
                        onCobrar: () => _confirmarCobro(
                            context, porCobrar[i]),
                        onDetalle: () => _verDetalle(
                            context, porCobrar[i]),
                      ),
                    ),

              // ── Tab 2: Pedidos en curso ────────────────────────
              enCurso.isEmpty
                  ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🍕', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Sin pedidos en curso',
                            style: TextStyle(color: Colors.grey,
                                fontSize: 16)),
                      ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: enCurso.length,
                      itemBuilder: (_, i) => _OrdenEnCursoCard(
                        orden: enCurso[i],
                        onDetalle: () => _verDetalle(
                            context, enCurso[i]),
                      ),
                    ),
            ],
          ),
        ),

        // Botón cierre de caja
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.lock_clock, color: Colors.white),
                label: const Text('Cerrar Caja del Día',
                    style: TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => _confirmarCierre(
                    context, totalDia, ordenes.length),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _confirmarCobro(BuildContext context, dynamic orden) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('💰 Confirmar cobro'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Orden #${orden.id}',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(orden.mesa,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text('TOTAL A COBRAR',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Bs. ${orden.total.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green[700],
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700]),
            onPressed: () {
              // USA firestoreId para actualizar en Firestore
              context.read<OrdenProvider>()
                  .actualizarEstado(orden.firestoreId, 'entregada');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.green[700],
                content: Text(
                    '✅ Cobro registrado: Bs. ${orden.total.toStringAsFixed(2)}'),
              ));
            },
            child: const Text('Confirmar cobro',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _verDetalle(BuildContext context, dynamic orden) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('📋 Orden #${orden.id}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DetalleRow('Mesa', orden.mesa),
            _DetalleRow('Hora',
                DateFormat('HH:mm dd/MM').format(orden.hora)),
            _DetalleRow('Estado', orden.estado),
            const Divider(),
            ...orden.items.map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(
                    '${item.nombre} (${item.tamano})',
                    style: const TextStyle(fontSize: 13))),
                Text('×${item.cantidad}  '),
                Text('Bs. ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )),
            const Divider(),
            _DetalleRow('TOTAL',
                'Bs. ${orden.total.toStringAsFixed(2)}'),
            if (orden.notasGenerales.isNotEmpty)
              _DetalleRow('Notas', orden.notasGenerales),
          ]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarCierre(
      BuildContext context, double total, int cantidad) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('🔒 Cierre de Caja'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Resumen del día:'),
          const SizedBox(height: 12),
          _DetalleRow('Total recaudado',
              'Bs. ${total.toStringAsFixed(2)}'),
          _DetalleRow('Órdenes atendidas', '$cantidad'),
          _DetalleRow('Fecha',
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
          const SizedBox(height: 12),
          const Text('¿Confirmar cierre del día?',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.green[700],
                content: Text(
                    '✅ Caja cerrada · Bs. ${total.toStringAsFixed(2)} · $cantidad órdenes'),
              ));
            },
            child: const Text('Confirmar cierre',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets
// ════════════════════════════════════════════════════════════════════════════

class _TotalChip extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;
  const _TotalChip(
      {required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: color.withValues(alpha: 0.2), blurRadius: 6)],
          ),
          child: Column(children: [
            Text('Bs. ${valor.toStringAsFixed(0)}',
                style: TextStyle(color: color,
                    fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _OrdenCajaCard extends StatelessWidget {
  final dynamic orden;
  final VoidCallback onCobrar, onDetalle;
  const _OrdenCajaCard(
      {required this.orden,
      required this.onCobrar,
      required this.onDetalle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
          boxShadow: [BoxShadow(
              color: Colors.orange.withValues(alpha: 0.1), blurRadius: 6)],
        ),
        child: Column(children: [
          Row(children: [
            const Text('💰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('#${orden.id}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(orden.mesa,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('${orden.items.length} producto(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Bs. ${orden.total.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green[700],
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(DateFormat('HH:mm').format(orden.hora),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: onDetalle,
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Detalle',
                  style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              onPressed: onCobrar,
              icon: const Icon(Icons.payment,
                  color: Colors.white, size: 16),
              label: const Text('Cobrar',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )),
          ]),
        ]),
      );
}

class _OrdenEnCursoCard extends StatelessWidget {
  final dynamic orden;
  final VoidCallback onDetalle;
  const _OrdenEnCursoCard(
      {required this.orden, required this.onDetalle});

  Color get _color => orden.estado == 'pendiente'
      ? Colors.orange : Colors.blue;

  String get _label => orden.estado == 'pendiente'
      ? '⏳ Pendiente' : '🔥 Preparando';

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
              left: BorderSide(color: _color, width: 4)),
          boxShadow: [const BoxShadow(
              color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('#${orden.id}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${orden.mesa} · ${DateFormat('HH:mm').format(orden.hora)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('${orden.items.length} producto(s)',
                style: const TextStyle(fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_label,
                  style: TextStyle(color: _color,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text('Bs. ${orden.total.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.red[800],
                    fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: onDetalle,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero),
              child: const Text('Ver detalle',
                  style: TextStyle(fontSize: 11)),
            ),
          ]),
        ]),
      );
}

class _DetalleRow extends StatelessWidget {
  final String l, v;
  const _DetalleRow(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(l, style: const TextStyle(color: Colors.grey)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );
}
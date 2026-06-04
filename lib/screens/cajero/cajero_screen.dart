import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/orden_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/orden.dart';

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
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final ordProv = context.watch<OrdenProvider>();
    final List<Orden> todas   = ordProv.ordenes;
    final List<Orden> enCurso = todas.where((o) =>
        o.estado == 'pendiente' ||
        o.estado == 'en_preparacion').toList();
    final List<Orden> listas  = todas.where(
        (o) => o.estado == 'lista').toList();
    final List<Orden> cobradas = todas.where(
        (o) => o.estado == 'entregada').toList();

    final totalDia     = todas.fold<double>(0, (s, o) => s + o.total);
    final totalCobrado = cobradas.fold<double>(0, (s, o) => s + o.total);
    final totalPend    = listas.fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('💰 Panel de Caja',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 17)),
          Text('Hola, ${auth.nombre ?? ""}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () { auth.logout(); Navigator.pop(context); },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Listas (${listas.length})'),
            Tab(text: 'En curso (${enCurso.length})'),
            Tab(text: 'Cobradas (${cobradas.length})'),
          ],
        ),
      ),
      body: Column(children: [
        // Resumen de totales
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(children: [
            _TotalChip(label: 'Total día',
                valor: totalDia, color: Colors.blue[700]!),
            const SizedBox(width: 8),
            _TotalChip(label: 'Por cobrar',
                valor: totalPend, color: Colors.orange[700]!),
            const SizedBox(width: 8),
            _TotalChip(label: 'Cobrado',
                valor: totalCobrado, color: Colors.green[700]!),
          ]),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [

              listas.isEmpty
                  ? const _EmptyTab(
                      emoji: '✅',
                      titulo: 'Sin órdenes listas',
                      subtitulo:
                          'Aparecen aquí cuando cocina\nlas marca como listas.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: listas.length,
                      itemBuilder: (_, i) => _OrdenListaCard(
                        orden: listas[i],
                        onCobrar: () => _cobrar(context, listas[i]),
                        onDetalle: () => _verDetalle(context, listas[i]),
                      ),
                    ),
              enCurso.isEmpty
                  ? const _EmptyTab(
                      emoji: '🍕',
                      titulo: 'Sin pedidos en curso',
                      subtitulo: 'Los pedidos activos\naparecerán aquí.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: enCurso.length,
                      itemBuilder: (_, i) => _OrdenEnCursoCard(
                        orden: enCurso[i],
                        onDetalle: () =>
                            _verDetalle(context, enCurso[i]),
                      ),
                    ),

              cobradas.isEmpty
                  ? const _EmptyTab(
                      emoji: '💰',
                      titulo: 'Sin cobros aún',
                      subtitulo: 'Los cobros del día\naparecerán aquí.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: cobradas.length,
                      itemBuilder: (_, i) {
                        final o = cobradas[cobradas.length - 1 - i];
                        return _OrdenCobradaCard(
                          orden: o,
                          onDetalle: () => _verDetalle(context, o),
                        );
                      },
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
                    context, totalCobrado, cobradas.length),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _cobrar(BuildContext context, Orden orden) {
    if (orden.firestoreId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: ID de orden no encontrado. '
              'Recarga la pantalla.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('💰 Confirmar cobro'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (orden.clienteNombre.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(orden.clienteNombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(orden.mesa,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ])),
              ]),
            ),
          const SizedBox(height: 12),
          Text('Orden #${orden.id}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
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
                      fontSize: 20, fontWeight: FontWeight.bold)),
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
            onPressed: () async {
              Navigator.pop(context);
              await context.read<OrdenProvider>()
                  .actualizarEstado(orden.firestoreId, 'entregada');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.green[700],
                  content: Text('✅ Cobrado: '
                      '${orden.clienteNombre.isNotEmpty ? orden.clienteNombre : orden.mesa} '
                      '· Bs. ${orden.total.toStringAsFixed(2)}'),
                ));
              }
            },
            child: const Text('Confirmar cobro',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _verDetalle(BuildContext context, Orden orden) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Text('📋 ', style: TextStyle(fontSize: 20)),
          Expanded(child: Text('Orden #${orden.id}',
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (orden.clienteNombre.isNotEmpty)
              _Row('👤 Cliente', orden.clienteNombre),
            _Row('🍽️ Mesa', orden.mesa),
            _Row('🕐 Hora',
                DateFormat('HH:mm dd/MM').format(orden.hora)),
            _Row('Estado', orden.estado),
            _Row('Firestore ID', orden.firestoreId.isEmpty
                ? '⚠️ VACÍO' : orden.firestoreId.substring(0, 8)),
            const Divider(),
            ...orden.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text(item.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(child: Text('${item.nombre} (${item.tamano})',
                    style: const TextStyle(fontSize: 13))),
                Text('×${item.cantidad}  '),
                Text('Bs. ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )),
            const Divider(),
            _Row('TOTAL', 'Bs. ${orden.total.toStringAsFixed(2)}'),
            if (orden.notasGenerales.isNotEmpty)
              _Row('Notas', orden.notasGenerales),
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
          _Row('Total cobrado', 'Bs. ${total.toStringAsFixed(2)}'),
          _Row('Órdenes cobradas', '$cantidad'),
          _Row('Fecha',
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
                content: Text('✅ Caja cerrada · '
                    'Bs. ${total.toStringAsFixed(2)} · '
                    '$cantidad cobros'),
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

class _TotalChip extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;
  const _TotalChip({required this.label, required this.valor,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 8),
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

class _OrdenListaCard extends StatelessWidget {
  final Orden orden;
  final VoidCallback onCobrar, onDetalle;
  const _OrdenListaCard({required this.orden,
      required this.onCobrar, required this.onDetalle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
          boxShadow: [BoxShadow(
              color: Colors.green.withValues(alpha: 0.1), blurRadius: 6)],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('✅', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                orden.clienteNombre.isNotEmpty
                    ? orden.clienteNombre : '─',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Text('${orden.mesa} · #${orden.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('${orden.items.length} producto(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Bs. ${orden.total.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green[700],
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(DateFormat('HH:mm').format(orden.hora),
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
              icon: const Icon(Icons.payment, color: Colors.white, size: 16),
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
  final Orden orden;
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
          border: Border(left: BorderSide(color: _color, width: 4)),
          boxShadow: [const BoxShadow(
              color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              orden.clienteNombre.isNotEmpty
                  ? orden.clienteNombre : '─',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text('${orden.mesa} · #${orden.id}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            Text('${orden.items.length} producto(s) · '
                '${DateFormat('HH:mm').format(orden.hora)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_label,
                  style: TextStyle(color: _color, fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text('Bs. ${orden.total.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.red[800],
                    fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: onDetalle,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text('Ver detalle',
                  style: TextStyle(fontSize: 11)),
            ),
          ]),
        ]),
      );
}

class _OrdenCobradaCard extends StatelessWidget {
  final Orden orden;
  final VoidCallback onDetalle;
  const _OrdenCobradaCard(
      {required this.orden, required this.onDetalle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Row(children: [
          const Text('💰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              orden.clienteNombre.isNotEmpty
                  ? orden.clienteNombre : '─',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${orden.mesa} · '
                '${DateFormat('HH:mm').format(orden.hora)}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ])),
          Text('Bs. ${orden.total.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.green[700],
                  fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.info_outline,
                size: 18, color: Colors.grey),
            onPressed: onDetalle,
          ),
        ]),
      );
}

class _EmptyTab extends StatelessWidget {
  final String emoji, titulo, subtitulo;
  const _EmptyTab({required this.emoji, required this.titulo,
      required this.subtitulo});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitulo, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
}

class _Row extends StatelessWidget {
  final String l, v;
  const _Row(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(l, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(v, textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
      );
}
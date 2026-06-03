import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/orden.dart';
import '../services/orden_service.dart';

// El cliente ve esta pantalla para seguir su orden en tiempo real.
// Recibe el firestoreId (doc ID real de Firestore) para hacer el stream.
class EstadoPedidoScreen extends StatelessWidget {
  final String firestoreId;
  const EstadoPedidoScreen({super.key, required this.firestoreId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('📍 Estado de tu pedido',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
      // StreamBuilder directo a Firestore — actualización en tiempo real
      body: StreamBuilder<Orden?>(
        stream: OrdenService.streamOrden(firestoreId),
        builder: (context, snap) {
          // Cargando
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }

          // Error de conexión
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Text('⚠️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Error al conectar: ${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
              ]),
            ));
          }

          // Orden no encontrada
          final orden = snap.data;
          if (orden == null) {
            return const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text('🔍', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Orden no encontrada',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Es posible que ya haya sido entregada.',
                    style: TextStyle(color: Colors.grey)),
              ]),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // ── Número de orden ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.red[800]!, Colors.red[600]!]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  const Text('Tu orden',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('# ${orden.id}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(orden.mesa,
                      style: const TextStyle(color: Colors.white70)),
                  Text(DateFormat('HH:mm').format(orden.hora),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Stepper de estado ────────────────────────────────
              _EstadoStepper(estado: orden.estado),
              const SizedBox(height: 28),

              // ── Resumen de items ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [const BoxShadow(
                      color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('🍕 Tu pedido',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...orden.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text('×${item.cantidad}',
                              style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(item.nombre, style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                        Text(item.tamano,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        if (item.notas.isNotEmpty)
                          Text('📝 ${item.notas}',
                              style: TextStyle(
                                  color: Colors.amber[700],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic)),
                      ])),
                      Text(
                          'Bs. ${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold)),
                    ]),
                  )),
                  const Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Bs. ${orden.total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800])),
                  ]),
                ]),
              ),

              // Nota general
              if (orden.notasGenerales.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(children: [
                    const Text('📝 ',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(orden.notasGenerales,
                        style: TextStyle(
                            color: Colors.amber[800]))),
                  ]),
                ),
              ],

              const SizedBox(height: 20),

              // Mensaje según estado
              if (orden.estado == 'lista')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.green.shade300),
                  ),
                  child: const Column(children: [
                    Text('🎉', style: TextStyle(fontSize: 36)),
                    SizedBox(height: 8),
                    Text('¡Tu pizza está lista!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    SizedBox(height: 4),
                    Text('El mesero te la llevará en un momento.',
                        style: TextStyle(color: Colors.grey)),
                  ]),
                ),

              if (orden.estado == 'entregada')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: const Column(children: [
                    Text('😊', style: TextStyle(fontSize: 36)),
                    SizedBox(height: 8),
                    Text('¡Buen provecho!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal)),
                    SizedBox(height: 4),
                    Text('Gracias por visitarnos.',
                        style: TextStyle(color: Colors.grey)),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Stepper visual
// ════════════════════════════════════════════════════════════════════════════

class _EstadoStepper extends StatelessWidget {
  final String estado;
  const _EstadoStepper({required this.estado});

  int get _paso {
    switch (estado) {
      case 'pendiente':      return 0;
      case 'en_preparacion': return 1;
      case 'lista':          return 2;
      case 'entregada':      return 3;
      default:               return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = [
      _PasoData(emoji: '📋', label: 'Recibida',
          sublabel: 'Tu orden llegó a cocina'),
      _PasoData(emoji: '🔥', label: 'Preparando',
          sublabel: 'Estamos haciendo tu pizza'),
      _PasoData(emoji: '✅', label: 'Lista',
          sublabel: 'Lista para entregar'),
      _PasoData(emoji: '🎉', label: '¡Disfruta!',
          sublabel: 'Tu pizza fue entregada'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: pasos.asMap().entries.map((entry) {
          final i          = entry.key;
          final paso       = entry.value;
          final activo     = i == _paso;
          final completado = i < _paso;
          final isLast     = i == pasos.length - 1;

          return Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completado
                        ? Colors.green[600]
                        : activo
                            ? Colors.red[700]
                            : Colors.grey[100],
                    border: Border.all(
                      color: completado
                          ? Colors.green[600]!
                          : activo
                              ? Colors.red[700]!
                              : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: activo
                        ? [BoxShadow(
                            color: Colors.red
                                .withValues(alpha: 0.3),
                            blurRadius: 12)]
                        : [],
                  ),
                  child: Center(
                    child: completado
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 22)
                        : Text(paso.emoji,
                            style: const TextStyle(fontSize: 22)),
                  ),
                ),
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 3, height: 36,
                    decoration: BoxDecoration(
                      color: completado
                          ? Colors.green[400]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ]),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(paso.label,
                        style: TextStyle(
                          fontWeight: activo
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: activo ? 16 : 14,
                          color: completado
                              ? Colors.green[700]
                              : activo
                                  ? Colors.red[800]
                                  : Colors.grey,
                        )),
                    if (activo) ...[
                      const SizedBox(height: 2),
                      Text(paso.sublabel,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12)),
                    ],
                  ]),
                ),
              ),
              if (activo)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _PulseDot(),
                ),
            ]),
          ]);
        }).toList(),
      ),
    );
  }
}

class _PasoData {
  final String emoji, label, sublabel;
  const _PasoData(
      {required this.emoji,
      required this.label,
      required this.sublabel});
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red[700]!.withValues(alpha: _anim.value),
          ),
        ),
      );
}
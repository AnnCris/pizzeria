import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/orden.dart';
import '../services/orden_service.dart';

// Accesible SIN login — el cliente ve su pedido en tiempo real.
// Recibe el firestoreId del documento en Firestore.
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
        // El cliente puede volver al menú con el botón back
      ),
      body: StreamBuilder<Orden?>(
        stream: OrdenService.streamOrden(firestoreId),
        builder: (context, snap) {
          // Cargando
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text('Cargando tu pedido...',
                    style: TextStyle(color: Colors.grey)),
              ],
            ));
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
                const Text('Sin conexión',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700]),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al menú',
                      style: TextStyle(color: Colors.white)),
                ),
              ]),
            ));
          }

          // Orden no encontrada
          final orden = snap.data;
          if (orden == null) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Pedido no encontrado',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Es posible que ya haya sido entregado.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700]),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al menú',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // ── Número de orden ────────────────────────────────
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
              const SizedBox(height: 24),

              // ── Stepper visual ─────────────────────────────────
              _EstadoStepper(estado: orden.estado),
              const SizedBox(height: 24),

              // ── Mensaje especial según estado ──────────────────
              if (orden.estado == 'lista')
                _BannerEstado(
                  emoji: '🎉',
                  titulo: '¡Tu pedido está listo!',
                  subtitulo: 'El mesero te lo llevará en un momento.',
                  color: Colors.green,
                ),
              if (orden.estado == 'entregada')
                _BannerEstado(
                  emoji: '😊',
                  titulo: '¡Buen provecho!',
                  subtitulo: 'Gracias por visitarnos. ¡Vuelve pronto!',
                  color: Colors.teal,
                ),
              if (orden.estado == 'pendiente' ||
                  orden.estado == 'en_preparacion')
                _BannerEstado(
                  emoji: orden.estado == 'pendiente' ? '⏳' : '🔥',
                  titulo: orden.estado == 'pendiente'
                      ? 'Orden recibida'
                      : '¡Cocinando tu pedido!',
                  subtitulo: orden.estado == 'pendiente'
                      ? 'El chef la tomará en breve.'
                      : 'Está siendo preparado con cariño.',
                  color: orden.estado == 'pendiente'
                      ? Colors.orange : Colors.blue,
                ),

              const SizedBox(height: 16),

              // ── Detalle del pedido ─────────────────────────────
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
                  const Text('🛒 Tu pedido',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 12),

                  // Pizzas
                  if (orden.pizzas.isNotEmpty) ...[
                    const _SeccionLabel(label: '🍕 Pizzas'),
                    ...orden.pizzas.map((item) =>
                        _ItemRow(item: item)),
                  ],

                  // Bebidas
                  if (orden.bebidas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const _SeccionLabel(label: '🥤 Bebidas'),
                    ...orden.bebidas.map((item) =>
                        _ItemRow(item: item)),
                  ],

                  const Divider(height: 20),
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                    const Text('Total',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('Bs. ${orden.total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800])),
                  ]),
                ]),
              ),

              // Notas generales
              if (orden.notasGenerales.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.amber.shade300),
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

              const SizedBox(height: 24),

              // ── AVISO DE PAGO ──────────────────────────────────
              // El pago se hace al RECIBIR el pedido, no antes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('¿Cómo pago?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 14)),
                    SizedBox(height: 4),
                    Text(
                      'El pago se realiza en caja al recibir '
                      'tu pedido. Puedes pagar en efectivo '
                      'o con tarjeta.',
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12),
                    ),
                  ])),
                ]),
              ),

              const SizedBox(height: 16),

              // Botón volver al menú
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Volver al menú',
                      style: TextStyle(fontSize: 15)),
                  onPressed: () => Navigator.popUntil(
                      context, (route) => route.isFirst),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets
// ════════════════════════════════════════════════════════════════════════════

class _BannerEstado extends StatelessWidget {
  final String emoji, titulo, subtitulo;
  final Color color;
  const _BannerEstado({required this.emoji, required this.titulo,
      required this.subtitulo, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(titulo, style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitulo,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
        ]),
      );
}

class _SeccionLabel extends StatelessWidget {
  final String label;
  const _SeccionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 13, color: Colors.grey)),
      );
}

class _ItemRow extends StatelessWidget {
  final ItemOrden item;
  const _ItemRow({required this.item});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: item.tipo == 'bebida'
                    ? Colors.teal[50] : Colors.red[50],
                shape: BoxShape.circle),
            child: Center(child: Text('×${item.cantidad}',
                style: TextStyle(
                    color: item.tipo == 'bebida'
                        ? Colors.teal[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 11))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(item.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(item.tamano,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            if (item.notas.isNotEmpty)
              Text('📝 ${item.notas}',
                  style: TextStyle(color: Colors.amber[700],
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
          ])),
          Text('Bs. ${item.subtotal.toStringAsFixed(2)}',
              style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold)),
        ]),
      );
}

// ── Stepper visual ────────────────────────────────────────────────────────

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
      _PasoData('📋', 'Recibida',   'Tu orden llegó a cocina'),
      _PasoData('🔥', 'Preparando', 'Estamos haciendo tu pedido'),
      _PasoData('✅', 'Lista',      'Lista para llevar a tu mesa'),
      _PasoData('🎉', '¡Disfruta!', 'Tu pedido fue entregado'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [const BoxShadow(
            color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(children: pasos.asMap().entries.map((entry) {
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
                      : activo ? Colors.red[700] : Colors.grey[100],
                  border: Border.all(
                    color: completado
                        ? Colors.green[600]!
                        : activo ? Colors.red[700]! : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: activo ? [BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12)] : [],
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
                        ? Colors.green[400] : Colors.grey[200],
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
                  Text(paso.label, style: TextStyle(
                    fontWeight: activo
                        ? FontWeight.bold : FontWeight.w500,
                    fontSize: activo ? 16 : 14,
                    color: completado
                        ? Colors.green[700]
                        : activo ? Colors.red[800] : Colors.grey,
                  )),
                  if (activo) ...[
                    const SizedBox(height: 2),
                    Text(paso.sublabel,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
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
      }).toList()),
    );
  }
}

class _PasoData {
  final String emoji, label, sublabel;
  const _PasoData(this.emoji, this.label, this.sublabel);
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
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red[700]!
                .withValues(alpha: _anim.value),
          ),
        ),
      );
}
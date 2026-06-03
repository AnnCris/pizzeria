import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/orden_provider.dart';
import '../providers/auth_provider.dart';
import '../models/orden.dart';
import 'login_screen.dart';
import 'estado_pedido_screen.dart';

class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});
  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _bannerCtrl;
  late Animation<Offset>   _bannerSlide;
  late Animation<double>   _bannerFade;

  int  _prevPendientes = 0;
  bool _mostrarBanner  = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _bannerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut));
    _bannerFade = CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  void _mostrarNuevaOrden() {
    setState(() => _mostrarBanner = true);
    _bannerCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _bannerCtrl.reverse().then((_) {
        if (mounted) setState(() => _mostrarBanner = false);
      });
    });
  }

  // Actualiza usando firestoreId — CORRECCIÓN PRINCIPAL
  Future<void> _cambiarEstado(Orden orden, String nuevoEstado) async {
    await context.read<OrdenProvider>()
        .actualizarEstado(orden.firestoreId, nuevoEstado);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProvider>();
    final auth     = context.watch<AuthProvider>();

    final pendientes = provider.ordenes
        .where((o) => o.estado == 'pendiente').toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));
    final enPrep = provider.ordenes
        .where((o) => o.estado == 'en_preparacion').toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));
    final listas = provider.ordenes
        .where((o) => o.estado == 'lista').toList()
      ..sort((a, b) => b.hora.compareTo(a.hora));

    final todas = [...pendientes, ...enPrep, ...listas];

    if (pendientes.length > _prevPendientes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _prevPendientes = pendientes.length;
          _mostrarNuevaOrden();
        }
      });
    } else if (pendientes.length < _prevPendientes) {
      _prevPendientes = pendientes.length;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B1A1A), Color(0xFFC0392B),
              Color(0xFFD4521A), Color(0xFFE8820C),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(child: Column(children: [

          // Banner nueva orden
          if (_mostrarBanner)
            SlideTransition(
              position: _bannerSlide,
              child: FadeTransition(
                opacity: _bannerFade,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    boxShadow: [BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.5),
                        blurRadius: 12)],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔔', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text('¡Nueva orden recibida!',
                          style: TextStyle(color: Colors.black87,
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

          // AppBar
          _AppBarCocina(
            auth: auth,
            pendientes: pendientes.length,
            enPrep: enPrep.length,
            listas: listas.length,
            pulseAnim: _pulseAnim,
          ),

          // Lista de órdenes
          Expanded(
            child: todas.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount: todas.length,
                    itemBuilder: (_, i) => _OrdenCard(
                      orden: todas[i],
                      pulseAnim: _pulseAnim,
                      // Pasamos el callback con firestoreId correcto
                      onCambiarEstado: _cambiarEstado,
                    ),
                  ),
          ),
        ])),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// AppBar
// ════════════════════════════════════════════════════════════════════════════

class _AppBarCocina extends StatelessWidget {
  final AuthProvider auth;
  final int pendientes, enPrep, listas;
  final Animation<double> pulseAnim;
  const _AppBarCocina({
    required this.auth,
    required this.pendientes,
    required this.enPrep,
    required this.listas,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        border: Border(bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.15))),
      ),
      child: Column(children: [
        Row(children: [
          // Botón volver al menú
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('👨‍🍳', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Panel de Cocina',
                style: TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Hola, ${auth.nombre ?? ""}',
                style: const TextStyle(color: Colors.white70,
                    fontSize: 12)),
          ])),
          _RelojVivo(),
          const SizedBox(width: 8),
          // Botón cerrar sesión
          GestureDetector(
            onTap: () {
              auth.logout();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.white,
                  size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _ContadorCard(label: 'Pendientes', count: pendientes,
              emoji: '⏳', color: const Color(0xFFFFCC02),
              pulseAnim: pendientes > 0 ? pulseAnim : null),
          const SizedBox(width: 10),
          _ContadorCard(label: 'Preparando', count: enPrep,
              emoji: '🔥', color: const Color(0xFF81D4FA),
              pulseAnim: enPrep > 0 ? pulseAnim : null),
          const SizedBox(width: 10),
          _ContadorCard(label: 'Listas', count: listas,
              emoji: '✅', color: const Color(0xFF69F0AE),
              pulseAnim: null),
        ]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Card de orden — recibe callback para cambiar estado
// ════════════════════════════════════════════════════════════════════════════

class _OrdenCard extends StatelessWidget {
  final Orden orden;
  final Animation<double> pulseAnim;
  final Future<void> Function(Orden orden, String estado) onCambiarEstado;

  const _OrdenCard({
    required this.orden,
    required this.pulseAnim,
    required this.onCambiarEstado,
  });

  Color get _accent {
    switch (orden.estado) {
      case 'pendiente':      return const Color(0xFFFFCC02);
      case 'en_preparacion': return const Color(0xFF4FC3F7);
      case 'lista':          return const Color(0xFF69F0AE);
      default:               return Colors.white38;
    }
  }

  Color get _headerBg {
    switch (orden.estado) {
      case 'pendiente':      return const Color(0xFF3B1500);
      case 'en_preparacion': return const Color(0xFF003060);
      case 'lista':          return const Color(0xFF003820);
      default:               return const Color(0xFF2A1500);
    }
  }

  String get _emoji {
    switch (orden.estado) {
      case 'pendiente':      return '⏳';
      case 'en_preparacion': return '🔥';
      case 'lista':          return '✅';
      default:               return '🍕';
    }
  }

  String get _labelEstado {
    switch (orden.estado) {
      case 'pendiente':      return 'Pendiente';
      case 'en_preparacion': return 'En preparación';
      case 'lista':          return 'Lista ✓';
      default:               return orden.estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutos = DateTime.now().difference(orden.hora).inMinutes;
    final urgente = minutos > 15 && orden.estado != 'lista';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: _accent.withValues(alpha: 0.35),
          blurRadius: 18, offset: const Offset(0, 5),
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          // Cabecera
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _headerBg, _headerBg.withValues(alpha: 0.8)]),
            ),
            child: Row(children: [
              orden.estado == 'pendiente'
                  ? AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (_, child) => Transform.scale(
                          scale: pulseAnim.value, child: child),
                      child: Text(_emoji,
                          style: const TextStyle(fontSize: 28)),
                    )
                  : Text(_emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Text('# ', style: TextStyle(
                      color: Colors.white38, fontSize: 13)),
                  Text(orden.id, style: TextStyle(
                      color: _accent, fontSize: 17,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.table_restaurant,
                      color: Colors.white54, size: 13),
                  const SizedBox(width: 4),
                  Text(orden.mesa, style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 10),
                  const Icon(Icons.schedule,
                      color: Colors.white38, size: 12),
                  const SizedBox(width: 3),
                  Text(DateFormat('HH:mm').format(orden.hora),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.6)),
                  ),
                  child: Text(_labelEstado,
                      style: TextStyle(color: _accent,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgente
                        ? Colors.red.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(urgente
                        ? Icons.warning_amber_rounded
                        : Icons.timer_outlined,
                        size: 11,
                        color: urgente
                            ? Colors.red[300] : Colors.white54),
                    const SizedBox(width: 3),
                    Text('$minutos min',
                        style: TextStyle(
                          color: urgente
                              ? Colors.red[300] : Colors.white54,
                          fontSize: 11,
                          fontWeight: urgente
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                  ]),
                ),
              ]),
            ]),
          ),

          // Items
          Container(
            color: const Color(0xFFFFFBF5),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: orden.items.asMap().entries.map((e) {
                final item   = e.value;
                final isLast = e.key == orden.items.length - 1;
                return Column(children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _accent == const Color(0xFFFFCC02)
                            ? const Color(0xFFFFF8DC)
                            : _accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _accent.withValues(alpha: 0.5)),
                      ),
                      child: Center(child: Text('×${item.cantidad}',
                          style: TextStyle(
                            color: _accent == const Color(0xFFFFCC02)
                                ? const Color(0xFF7A5800)
                                : _accent,
                            fontWeight: FontWeight.bold, fontSize: 12,
                          ))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(item.nombre, style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14, fontWeight: FontWeight.bold)),
                      if (item.notas.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.amber.shade300),
                          ),
                          child: Row(children: [
                            const Text('📝 ',
                                style: TextStyle(fontSize: 11)),
                            Expanded(child: Text(item.notas,
                                style: TextStyle(
                                    color: Colors.amber[800],
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic))),
                          ]),
                        ),
                    ])),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.shade200),
                      ),
                      child: Text(item.tamano,
                          style: TextStyle(color: Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  if (!isLast)
                    Divider(color: Colors.orange.shade100,
                        height: 14, thickness: 1),
                ]);
              }).toList(),
            ),
          ),

          // Nota general
          if (orden.notasGenerales.isNotEmpty)
            Container(
              color: const Color(0xFFFFFBF5),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(children: [
                  const Text('📋 ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text('Nota: ${orden.notasGenerales}',
                      style: TextStyle(color: Colors.amber[800],
                          fontSize: 12,
                          fontStyle: FontStyle.italic))),
                ]),
              ),
            ),

          // Botones de acción
          Container(
            color: const Color(0xFFFFFBF5),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(children: [

              // Botón principal de cambio de estado
              orden.estado == 'lista'
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text('🎉', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('¡Lista! Llevar al cliente',
                            style: TextStyle(color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ]),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orden.estado == 'pendiente'
                            ? const Color(0xFFD84315)
                            : const Color(0xFF1565C0),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        orden.estado == 'pendiente'
                            ? Icons.local_fire_department
                            : Icons.check_circle_outline,
                        color: Colors.white, size: 20,
                      ),
                      label: Text(
                        orden.estado == 'pendiente'
                            ? '🍕  Iniciar preparación'
                            : '✅  Marcar como lista',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      // USA firestoreId a través del callback
                      onPressed: () => onCambiarEstado(
                        orden,
                        orden.estado == 'pendiente'
                            ? 'en_preparacion' : 'lista',
                      ),
                    ),

              const SizedBox(height: 8),

              // Botón ver estado del cliente
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                icon: Icon(Icons.visibility_outlined,
                    color: Colors.orange[700], size: 18),
                label: Text('Ver estado del cliente',
                    style: TextStyle(color: Colors.orange[700],
                        fontWeight: FontWeight.w600, fontSize: 13)),
                // USA firestoreId directamente
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => EstadoPedidoScreen(
                          firestoreId: orden.firestoreId),
                    )),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ════════════════════════════════════════════════════════════════════════════

class _RelojVivo extends StatefulWidget {
  @override
  State<_RelojVivo> createState() => _RelojVivoState();
}

class _RelojVivoState extends State<_RelojVivo> {
  late String _hora;

  @override
  void initState() {
    super.initState();
    _hora = DateFormat('HH:mm').format(DateTime.now());
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() => _hora = DateFormat('HH:mm').format(DateTime.now()));
      return true;
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.access_time, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(_hora, style: const TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
      );
}

class _ContadorCard extends StatelessWidget {
  final String label, emoji;
  final int count;
  final Color color;
  final Animation<double>? pulseAnim;
  const _ContadorCard({required this.label, required this.count,
      required this.emoji, required this.color, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: color.withValues(alpha: count > 0 ? 0.55 : 0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: TextStyle(
              color: count > 0 ? color : Colors.white30,
              fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(
              color: Colors.white60, fontSize: 10)),
        ]),
      ]),
    );

    if (pulseAnim != null && count > 0) {
      card = AnimatedBuilder(
        animation: pulseAnim!,
        builder: (_, child) =>
            Transform.scale(scale: pulseAnim!.value, child: child),
        child: card,
      );
    }
    return Expanded(child: card);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🍕',
                style: TextStyle(fontSize: 64))),
          ),
          const SizedBox(height: 20),
          const Text('¡Todo tranquilo!', style: TextStyle(
              color: Colors.white, fontSize: 24,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                'Las nuevas órdenes aparecerán aquí automáticamente',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center),
          ),
        ]),
      );
}
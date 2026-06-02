import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mesa.dart';
import '../../providers/mesa_provider.dart';

class MesasScreen extends StatefulWidget {
  const MesasScreen({super.key});
  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> {
  @override
  void initState() {
    super.initState();
    // Crea 10 mesas si no existen aún
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesaProvider>().crearMesasIniciales(10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MesaProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        title: const Text('🍽️ Gestión de Mesas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Agregar mesa',
            onPressed: () => _dialogAgregarMesa(context),
          ),
        ],
      ),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(children: [
              // ── Resumen ──────────────────────────────────────────────
              _ResumenBar(
                  libres: provider.libres,
                  ocupadas: provider.ocupadas,
                  cuenta: provider.cuenta),

              // ── Grid de mesas ────────────────────────────────────────
              Expanded(
                child: provider.mesas.isEmpty
                    ? _EmptyMesas(onCrear: () =>
                        provider.crearMesasIniciales(10))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: provider.mesas.length,
                        itemBuilder: (_, i) =>
                            _MesaCard(mesa: provider.mesas[i]),
                      ),
              ),
            ]),
    );
  }

  void _dialogAgregarMesa(BuildContext context) {
    final provider = context.read<MesaProvider>();
    final numCtrl = TextEditingController();
    int capacidad = 4;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('➕ Nueva Mesa'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de mesa',
                prefixIcon: const Icon(Icons.table_restaurant),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Capacidad:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final cap in [2, 4, 6, 8])
                GestureDetector(
                  onTap: () => setS(() => capacidad = cap),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: capacidad == cap ? Colors.red[700] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: capacidad == cap
                              ? Colors.red[700]!
                              : Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text('$cap',
                          style: TextStyle(
                            color: capacidad == cap ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold, fontSize: 16,
                          )),
                    ),
                  ),
                ),
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () {
                if (numCtrl.text.isNotEmpty) {
                  provider.agregarMesa(int.parse(numCtrl.text), capacidad);
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resumen ──────────────────────────────────────────────────────────────────

class _ResumenBar extends StatelessWidget {
  final int libres, ocupadas, cuenta;
  const _ResumenBar(
      {required this.libres, required this.ocupadas, required this.cuenta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(children: [
        _Chip(label: 'Libres', count: libres,
            color: const Color(0xFF2E7D32), emoji: '🟢'),
        _vline(),
        _Chip(label: 'Ocupadas', count: ocupadas,
            color: const Color(0xFFC62828), emoji: '🔴'),
        _vline(),
        _Chip(label: 'Por cobrar', count: cuenta,
            color: const Color(0xFFE65100), emoji: '🟡'),
      ]),
    );
  }

  Widget _vline() => Container(
      width: 1, height: 36, color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _Chip extends StatelessWidget {
  final String label, emoji;
  final int count;
  final Color color;
  const _Chip(
      {required this.label, required this.count,
      required this.color, required this.emoji});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text('$emoji  $count',
              style: TextStyle(color: color, fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      );
}

// ── Card de mesa ─────────────────────────────────────────────────────────────

class _MesaCard extends StatelessWidget {
  final Mesa mesa;
  const _MesaCard({required this.mesa});

  Color get _color {
    switch (mesa.estado) {
      case 'libre':             return const Color(0xFF2E7D32);
      case 'ocupada':           return const Color(0xFFC62828);
      case 'esperando_cuenta':  return const Color(0xFFE65100);
      default:                  return Colors.grey;
    }
  }

  Color get _bgColor {
    switch (mesa.estado) {
      case 'libre':             return const Color(0xFFE8F5E9);
      case 'ocupada':           return const Color(0xFFFFEBEE);
      case 'esperando_cuenta':  return const Color(0xFFFFF3E0);
      default:                  return Colors.grey.shade100;
    }
  }

  String get _emoji {
    switch (mesa.estado) {
      case 'libre':             return '🟢';
      case 'ocupada':           return '🔴';
      case 'esperando_cuenta':  return '💰';
      default:                  return '⚪';
    }
  }

  String get _label {
    switch (mesa.estado) {
      case 'libre':             return 'Libre';
      case 'ocupada':           return 'Ocupada';
      case 'esperando_cuenta':  return 'Por cobrar';
      default:                  return mesa.estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarOpciones(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
                color: _color.withValues(alpha: 0.2),
                blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text('Mesa ${mesa.numero}',
                style: TextStyle(color: _color, fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(_label,
                style: TextStyle(color: _color.withValues(alpha: 0.8),
                    fontSize: 11)),
            if (mesa.clienteNombre.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(mesa.clienteNombre,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.people, size: 12, color: Colors.grey),
              const SizedBox(width: 2),
              Text('${mesa.capacidad} personas',
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ]),
          ],
        ),
      ),
    );
  }

  void _mostrarOpciones(BuildContext context) {
    final provider = context.read<MesaProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OpcionesMesa(mesa: mesa, provider: provider),
    );
  }
}

// ── Opciones de mesa (bottom sheet) ─────────────────────────────────────────

class _OpcionesMesa extends StatefulWidget {
  final Mesa mesa;
  final MesaProvider provider;
  const _OpcionesMesa({required this.mesa, required this.provider});
  @override
  State<_OpcionesMesa> createState() => _OpcionesMesaState();
}

class _OpcionesMesaState extends State<_OpcionesMesa> {
  final _nombreCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nombreCtrl.text = widget.mesa.clienteNombre;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        Text('Mesa ${widget.mesa.numero}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Capacidad: ${widget.mesa.capacidad} personas',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),

        // Campo nombre cliente
        TextField(
          controller: _nombreCtrl,
          decoration: InputDecoration(
            labelText: 'Nombre del cliente (opcional)',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Botones de estado
        Row(children: [
          _BtnEstado(
            label: '🟢 Libre',
            color: const Color(0xFF2E7D32),
            onTap: () {
              widget.provider.liberarMesa(widget.mesa.id);
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 10),
          _BtnEstado(
            label: '🔴 Ocupada',
            color: const Color(0xFFC62828),
            onTap: () {
              widget.provider.actualizarEstado(
                  widget.mesa.id, 'ocupada',
                  clienteNombre: _nombreCtrl.text.trim());
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 10),
          _BtnEstado(
            label: '💰 Por cobrar',
            color: const Color(0xFFE65100),
            onTap: () {
              widget.provider.actualizarEstado(
                  widget.mesa.id, 'esperando_cuenta',
                  clienteNombre: _nombreCtrl.text.trim());
              Navigator.pop(context);
            },
          ),
        ]),

        const SizedBox(height: 12),

        // Eliminar mesa
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Eliminar mesa',
              style: TextStyle(color: Colors.red)),
          onPressed: () {
            widget.provider.eliminarMesa(widget.mesa.id);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _BtnEstado extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BtnEstado(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(color: Colors.white,
                  fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
      );
}

// ── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyMesas extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyMesas({required this.onCrear});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Sin mesas configuradas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Crear 10 mesas',
                style: TextStyle(color: Colors.white)),
            onPressed: onCrear,
          ),
        ]),
      );
}
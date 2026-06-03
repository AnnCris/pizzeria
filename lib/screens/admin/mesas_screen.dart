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
  String _filtro = 'todas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesaProvider>().crearMesasIniciales(10);
    });
  }

  List<Mesa> _filtradas(List<Mesa> mesas) {
    if (_filtro == 'todas') return mesas;
    return mesas.where((m) => m.estado == _filtro).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MesaProvider>();
    final filtradas = _filtradas(provider.mesas);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('🍽️ Gestión de Mesas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Agregar mesa',
            onPressed: () => _dialogMesa(context, null),
          ),
        ],
      ),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(children: [
              _ResumenBar(
                  libres: provider.libres,
                  ocupadas: provider.ocupadas,
                  cuenta: provider.cuenta),
              _FiltroBar(
                filtroActual: _filtro,
                onCambio: (f) => setState(() => _filtro = f),
              ),
              Expanded(
                child: filtradas.isEmpty
                    ? _EmptyMesas(
                        onCrear: () => provider.crearMesasIniciales(10))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: filtradas.length,
                        itemBuilder: (_, i) => _MesaCard(
                          mesa: filtradas[i],
                          onEditar: () => _dialogMesa(context, filtradas[i]),
                        ),
                      ),
              ),
            ]),
    );
  }

  // Dialog único para crear Y editar mesa
  void _dialogMesa(BuildContext context, Mesa? mesaExistente) {
    final provider  = context.read<MesaProvider>();
    final esEdicion = mesaExistente != null;

    final numCtrl      = TextEditingController(
        text: esEdicion ? '${mesaExistente.numero}' : '');
    final etiquetaCtrl = TextEditingController(
        text: esEdicion ? mesaExistente.etiqueta : '');
    int  capacidad = esEdicion ? mesaExistente.capacidad : 4;
    bool esEvento  = esEdicion ? mesaExistente.esEvento  : false;

    // Capacidades normales y de evento
    final capsNormales = [2, 4, 6, 8];
    final capsEvento   = [10, 15, 20, 30, 50];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(esEdicion ? '✏️ Editar Mesa' : '➕ Nueva Mesa',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Número
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
              const SizedBox(height: 12),

              // Etiqueta (nombre descriptivo)
              TextField(
                controller: etiquetaCtrl,
                decoration: InputDecoration(
                  labelText: 'Etiqueta (opcional)',
                  hintText: 'Ej: Terraza, VIP, Salón A...',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle evento
              Container(
                decoration: BoxDecoration(
                  color: esEvento
                      ? Colors.purple[50]
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: esEvento
                          ? Colors.purple.shade200
                          : Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  title: const Text('Mesa de evento',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  subtitle: Text(
                    esEvento
                        ? 'Capacidad ampliada para grupos grandes'
                        : 'Mesa estándar del local',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: esEvento,
                  activeThumbColor: Colors.purple[700],
                  onChanged: (v) => setS(() {
                    esEvento  = v;
                    capacidad = v ? 10 : 4;
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // Capacidad
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Capacidad (personas):',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: (esEvento ? capsEvento : capsNormales)
                    .map((cap) => GestureDetector(
                  onTap: () => setS(() => capacidad = cap),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 52, height: 42,
                    decoration: BoxDecoration(
                      color: capacidad == cap
                          ? (esEvento
                              ? Colors.purple[700]
                              : Colors.red[700])
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: capacidad == cap
                              ? (esEvento
                                  ? Colors.purple[700]!
                                  : Colors.red[700]!)
                              : Colors.grey.shade300),
                    ),
                    child: Center(child: Text('$cap',
                        style: TextStyle(
                          color: capacidad == cap
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ))),
                  ),
                )).toList(),
              ),

              if (esEvento) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline,
                        color: Colors.purple, size: 14),
                    SizedBox(width: 6),
                    Expanded(child: Text(
                        'Las mesas de evento aparecen marcadas con 🎉 y no afectan el conteo normal.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.purple))),
                  ]),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      esEvento ? Colors.purple[700] : Colors.red[700]),
              onPressed: () async {
                if (numCtrl.text.isEmpty) return;
                final num = int.tryParse(numCtrl.text);
                if (num == null) return;

                if (esEdicion) {
                  await provider.editarMesa(
                    mesaExistente.id, num, capacidad,
                    esEvento: esEvento,
                    etiqueta: etiquetaCtrl.text.trim(),
                  );
                } else {
                  await provider.agregarMesa(
                    num, capacidad,
                    esEvento: esEvento,
                    etiqueta: etiquetaCtrl.text.trim(),
                  );
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(esEdicion
                        ? '✅ Mesa actualizada'
                        : '✅ Mesa agregada'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              child: Text(esEdicion ? 'Guardar cambios' : 'Agregar',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets
// ════════════════════════════════════════════════════════════════════════════

class _FiltroBar extends StatelessWidget {
  final String filtroActual;
  final void Function(String) onCambio;
  const _FiltroBar({required this.filtroActual, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {'val': 'todas',            'label': 'Todas',      'emoji': '📋'},
      {'val': 'libre',            'label': 'Libres',     'emoji': '🟢'},
      {'val': 'ocupada',          'label': 'Ocupadas',   'emoji': '🔴'},
      {'val': 'esperando_cuenta', 'label': 'Por cobrar', 'emoji': '💰'},
    ];
    return Container(
      color: Colors.white,
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        children: opciones.map((o) {
          final sel = o['val'] == filtroActual;
          return GestureDetector(
            onTap: () => onCambio(o['val']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? Colors.red[700] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? Colors.red[700]! : Colors.grey.shade300),
              ),
              child: Text('${o['emoji']} ${o['label']}',
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResumenBar extends StatelessWidget {
  final int libres, ocupadas, cuenta;
  const _ResumenBar(
      {required this.libres, required this.ocupadas, required this.cuenta});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(children: [
          _Chip(label: 'Libres',     count: libres,   color: const Color(0xFF2E7D32), emoji: '🟢'),
          _vline(),
          _Chip(label: 'Ocupadas',   count: ocupadas, color: const Color(0xFFC62828), emoji: '🔴'),
          _vline(),
          _Chip(label: 'Por cobrar', count: cuenta,   color: const Color(0xFFE65100), emoji: '🟡'),
        ]),
      );

  Widget _vline() => Container(
      width: 1, height: 36, color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _Chip extends StatelessWidget {
  final String label, emoji;
  final int count;
  final Color color;
  const _Chip({required this.label, required this.count,
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

class _MesaCard extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onEditar;
  const _MesaCard({required this.mesa, required this.onEditar});

  Color get _color {
    switch (mesa.estado) {
      case 'libre':            return const Color(0xFF2E7D32);
      case 'ocupada':          return const Color(0xFFC62828);
      case 'esperando_cuenta': return const Color(0xFFE65100);
      default:                 return Colors.grey;
    }
  }

  Color get _bgColor {
    switch (mesa.estado) {
      case 'libre':            return const Color(0xFFE8F5E9);
      case 'ocupada':          return const Color(0xFFFFEBEE);
      case 'esperando_cuenta': return const Color(0xFFFFF3E0);
      default:                 return Colors.grey.shade100;
    }
  }

  String get _emoji {
    if (mesa.esEvento) return '🎉';
    switch (mesa.estado) {
      case 'libre':            return '🟢';
      case 'ocupada':          return '🔴';
      case 'esperando_cuenta': return '💰';
      default:                 return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MesaProvider>();

    return GestureDetector(
      onTap: () => _mostrarOpciones(context, provider),
      onLongPress: () => _confirmarEliminar(context, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: mesa.esEvento ? Colors.purple[50] : _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: mesa.esEvento
                  ? Colors.purple.withValues(alpha: 0.5)
                  : _color.withValues(alpha: 0.5),
              width: 2),
          boxShadow: [BoxShadow(
              color: (mesa.esEvento ? Colors.purple : _color)
                  .withValues(alpha: 0.2),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Stack(children: [
          // Botón editar (esquina superior derecha)
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onEditar,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_outlined,
                    size: 14,
                    color: mesa.esEvento
                        ? Colors.purple[700]
                        : _color),
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Text(_emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text('Mesa ${mesa.numero}',
                  style: TextStyle(
                      color: mesa.esEvento
                          ? Colors.purple[700]
                          : _color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              if (mesa.etiqueta.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(mesa.etiqueta,
                      style: TextStyle(
                          color: mesa.esEvento
                              ? Colors.purple[500]
                              : _color.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ),
              if (mesa.clienteNombre.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(mesa.clienteNombre,
                      style: const TextStyle(color: Colors.grey, fontSize: 9),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 2),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.people, size: 11, color: Colors.grey),
                const SizedBox(width: 2),
                Text('${mesa.capacidad}p',
                    style: const TextStyle(color: Colors.grey, fontSize: 9)),
              ]),
              if (mesa.esEvento)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('EVENTO',
                      style: TextStyle(color: Colors.purple[700],
                          fontSize: 8, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ]),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, MesaProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🗑️ Eliminar mesa'),
        content: Text('¿Eliminar la Mesa ${mesa.numero}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              await provider.eliminarMesa(mesa.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Mesa ${mesa.numero} eliminada'),
                  backgroundColor: Colors.orange,
                ));
              }
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarOpciones(BuildContext context, MesaProvider provider) {
    final nombreCtrl = TextEditingController(text: mesa.clienteNombre);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Mesa ${mesa.numero}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (mesa.etiqueta.isNotEmpty)
            Text(mesa.etiqueta,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text('${mesa.capacidad} personas${mesa.esEvento ? ' · EVENTO' : ''}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: nombreCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre del cliente (opcional)',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _BtnEstado(label: '🟢 Libre', color: const Color(0xFF2E7D32),
                onTap: () async {
                  await provider.liberarMesa(mesa.id);
                  if (context.mounted) Navigator.pop(context);
                }),
            const SizedBox(width: 8),
            _BtnEstado(label: '🔴 Ocupada', color: const Color(0xFFC62828),
                onTap: () async {
                  await provider.actualizarEstado(mesa.id, 'ocupada',
                      clienteNombre: nombreCtrl.text.trim());
                  if (context.mounted) Navigator.pop(context);
                }),
            const SizedBox(width: 8),
            _BtnEstado(label: '💰 Cobrar', color: const Color(0xFFE65100),
                onTap: () async {
                  await provider.actualizarEstado(
                      mesa.id, 'esperando_cuenta',
                      clienteNombre: nombreCtrl.text.trim());
                  if (context.mounted) Navigator.pop(context);
                }),
          ]),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Eliminar mesa',
                style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await provider.eliminarMesa(mesa.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
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
              style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
      );
}

class _EmptyMesas extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyMesas({required this.onCrear});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Sin mesas en Firestore',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Crear 10 mesas',
                style: TextStyle(color: Colors.white)),
            onPressed: onCrear,
          ),
        ]),
      );
}
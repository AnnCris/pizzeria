import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/pizza_service.dart';

class PizzasAdminScreen extends StatelessWidget {
  const PizzasAdminScreen({super.key});

  static const _categorias = [
    'Clásicas', 'Especiales', 'Vegana', 'Infantil', 'Premium'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('🍕 Gestión de Pizzas',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Nueva pizza',
            onPressed: () => _dialogFormulario(context, null),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
            tooltip: 'Subir pizzas iniciales a Firebase',
            onPressed: () => _subirIniciales(context),
          ),
        ],
      ),
      body: StreamBuilder<List<PizzaDB>>(
        stream: PizzaService.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }
          if (snap.hasError) {
            return _ErrorCard(mensaje: '${snap.error}');
          }
          final pizzas = snap.data ?? [];
          if (pizzas.isEmpty) {
            return _EmptyState(
              onSubir: () => _subirIniciales(context),
              onCrear: () => _dialogFormulario(context, null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pizzas.length,
            itemBuilder: (_, i) => _PizzaAdminCard(
              pizza: pizzas[i],
              onEditar: () => _dialogFormulario(context, pizzas[i]),
              onEliminar: () => _confirmarEliminar(context, pizzas[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _subirIniciales(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(width: 16),
          Text('Subiendo pizzas...'),
        ]),
      ),
    );
    final error = await PizzaService.subirPizzasIniciales();
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '✅ Pizzas subidas a Firebase correctamente'),
      backgroundColor: error != null ? Colors.orange : Colors.green,
    ));
  }

  void _dialogFormulario(BuildContext context, PizzaDB? pizza) {
    final esEdicion  = pizza != null;
    final nombreCtrl = TextEditingController(text: pizza?.nombre ?? '');
    final ingCtrl    = TextEditingController(
        text: pizza?.ingredientes ?? '');
    final precioCtrl = TextEditingController(
        text: pizza?.precioBase.toStringAsFixed(0) ?? '');
    final imgCtrl    = TextEditingController(
        text: pizza?.imageUrl ?? '');
    String categoria  = pizza?.categoria ?? 'Clásicas';
    bool   cargando   = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(esEdicion ? '✏️ Editar Pizza' : '➕ Nueva Pizza',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _Campo(ctrl: nombreCtrl, label: 'Nombre de la pizza',
                  icono: Icons.local_pizza),
              const SizedBox(height: 12),
              TextField(
                controller: ingCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Ingredientes',
                  prefixIcon: const Icon(Icons.list_alt),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              _Campo(ctrl: precioCtrl, label: 'Precio base (Bs.)',
                  icono: Icons.attach_money,
                  tipo: TextInputType.number),
              const SizedBox(height: 12),
              _Campo(ctrl: imgCtrl, label: 'URL de imagen',
                  icono: Icons.image, tipo: TextInputType.url),
              const SizedBox(height: 8),
              // Preview imagen
              StatefulBuilder(
                builder: (_, setSImg) => Column(children: [
                  if (imgCtrl.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imgCtrl.text,
                        height: 80, width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const SizedBox(),
                      ),
                    ),
                  TextButton(
                    onPressed: () => setSImg(() {}),
                    child: const Text('Previsualizar imagen'),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              // Selector categoría
              const Align(alignment: Alignment.centerLeft,
                  child: Text('Categoría:',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: _categorias.map((c) => GestureDetector(
                  onTap: () => setS(() => categoria = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: categoria == c
                          ? Colors.red[700] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: categoria == c
                              ? Colors.red[700]! : Colors.grey.shade300),
                    ),
                    child: Text(c, style: TextStyle(
                      color: categoria == c
                          ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold, fontSize: 12,
                    )),
                  ),
                )).toList(),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error!,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(
              onPressed: cargando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700]),
              onPressed: cargando ? null : () async {
                if (nombreCtrl.text.isEmpty || precioCtrl.text.isEmpty) {
                  setS(() => error = 'Nombre y precio son obligatorios');
                  return;
                }
                setS(() { cargando = true; error = null; });
                final nueva = PizzaDB(
                  id:           pizza?.id ?? '',
                  nombre:       nombreCtrl.text.trim(),
                  ingredientes: ingCtrl.text.trim(),
                  precioBase:   double.tryParse(precioCtrl.text) ?? 0,
                  imageUrl:     imgCtrl.text.trim(),
                  categoria:    categoria,
                );
                final err = esEdicion
                    ? await PizzaService.actualizar(pizza.id, nueva)
                    : await PizzaService.crear(nueva);
                if (!ctx.mounted) return;
                if (err != null) {
                  setS(() { cargando = false; error = err; });
                } else {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(esEdicion
                        ? '✅ Pizza actualizada' : '✅ Pizza creada'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              child: cargando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(esEdicion ? 'Guardar' : 'Crear',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, PizzaDB pizza) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('🗑️ Eliminar pizza'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('¿Eliminar "${pizza.nombre}" del menú?'),
          const SizedBox(height: 8),
          const Text('Esta acción ocultará la pizza del catálogo.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            onPressed: () async {
              await PizzaService.eliminar(pizza.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('🗑️ Pizza eliminada del menú'),
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
}

class _PizzaAdminCard extends StatelessWidget {
  final PizzaDB pizza;
  final VoidCallback onEditar, onEliminar;
  const _PizzaAdminCard({required this.pizza,
      required this.onEditar, required this.onEliminar});

  Color _catColor(String c) {
    switch (c) {
      case 'Clásicas':   return Colors.orange[700]!;
      case 'Especiales': return Colors.red[700]!;
      case 'Vegana':     return Colors.green[700]!;
      case 'Infantil':   return Colors.blue[600]!;
      case 'Premium':    return Colors.purple[700]!;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(children: [
          // Imagen
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14)),
            child: CachedNetworkImage(
              imageUrl: pizza.imageUrl,
              width: 90, height: 90, fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                  width: 90, height: 90, color: Colors.red[50],
                  child: const Center(
                      child: Text('🍕',
                          style: TextStyle(fontSize: 32)))),
              errorWidget: (_, _, _) => Container(
                  width: 90, height: 90, color: Colors.red[50],
                  child: const Center(
                      child: Text('🍕',
                          style: TextStyle(fontSize: 32)))),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(pizza.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(pizza.ingredientes,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _catColor(pizza.categoria)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(pizza.categoria,
                        style: TextStyle(
                            color: _catColor(pizza.categoria),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Text('Bs. ${pizza.precioBase.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ]),
              ]),
            ),
          ),
          // Botones
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: onEditar),
            IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onEliminar),
          ]),
        ]),
      );
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final TextInputType tipo;
  const _Campo({required this.ctrl, required this.label,
      required this.icono, this.tipo = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSubir, onCrear;
  const _EmptyState({required this.onSubir, required this.onCrear});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🍕', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Sin pizzas en Firebase',
              style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Puedes subir las pizzas del menú local\no crear una nueva.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('Subir pizzas iniciales',
                style: TextStyle(color: Colors.white)),
            onPressed: onSubir,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear pizza nueva'),
            onPressed: onCrear,
          ),
        ]),
      );
}

class _ErrorCard extends StatelessWidget {
  final String mensaje;
  const _ErrorCard({required this.mensaje});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('Error de conexión',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Text(mensaje,
                  style: TextStyle(
                      color: Colors.red[700], fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                  'Verifica las reglas de Firestore y que los índices estén creados.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
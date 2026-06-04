import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/bebida_service.dart';

class BebidasAdminScreen extends StatelessWidget {
  const BebidasAdminScreen({super.key});

  static const _categorias = [
    'Gaseosas', 'Jugos', 'Cafés', 'Mates', 'Agua', 'Cervezas'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('🥤 Gestión de Bebidas',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Nueva bebida',
            onPressed: () => _dialogFormulario(context, null),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
            tooltip: 'Subir bebidas iniciales',
            onPressed: () => _subirIniciales(context),
          ),
        ],
      ),
      body: StreamBuilder<List<BebidaDB>>(
        stream: BebidaService.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snap.hasError) {
            return _ErrorCard(mensaje: '${snap.error}');
          }
          final bebidas = snap.data ?? [];
          if (bebidas.isEmpty) {
            return _EmptyState(
              onSubir: () => _subirIniciales(context),
              onCrear: () => _dialogFormulario(context, null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bebidas.length,
            itemBuilder: (_, i) => _BebidaAdminCard(
              bebida: bebidas[i],
              onEditar: () => _dialogFormulario(context, bebidas[i]),
              onEliminar: () => _confirmarEliminar(context, bebidas[i]),
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
          CircularProgressIndicator(color: Colors.teal),
          SizedBox(width: 16),
          Text('Subiendo bebidas...'),
        ]),
      ),
    );
    final error = await BebidaService.subirBebidasIniciales();
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '✅ Bebidas subidas correctamente'),
      backgroundColor: error != null ? Colors.orange : Colors.green,
    ));
  }

  void _dialogFormulario(BuildContext context, BebidaDB? bebida) {
    final esEdicion      = bebida != null;
    final nombreCtrl     = TextEditingController(text: bebida?.nombre ?? '');
    final descCtrl       = TextEditingController(
        text: bebida?.descripcion ?? '');
    final precioCtrl     = TextEditingController(
        text: bebida?.precioBase.toStringAsFixed(0) ?? '');
    final imgCtrl        = TextEditingController(
        text: bebida?.imageUrl ?? '');
    String categoria     = bebida?.categoria ?? 'Gaseosas';
    bool   tieneTamanos  = bebida?.tieneTamanos ?? true;
    bool   cargando      = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(esEdicion ? '✏️ Editar Bebida' : '➕ Nueva Bebida',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Nombre
              _Campo(ctrl: nombreCtrl, label: 'Nombre de la bebida',
                  icono: Icons.local_drink),
              const SizedBox(height: 12),

              // Descripción
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Precio base
              _Campo(ctrl: precioCtrl, label: 'Precio base (Bs.)',
                  icono: Icons.attach_money,
                  tipo: TextInputType.number),
              const SizedBox(height: 12),

              // URL imagen
              _Campo(ctrl: imgCtrl, label: 'URL de imagen',
                  icono: Icons.image_outlined,
                  tipo: TextInputType.url),
              const SizedBox(height: 8),

              // Preview imagen
              StatefulBuilder(
                builder: (_, setSImg) => Column(children: [
                  if (imgCtrl.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imgCtrl.text,
                        height: 70, width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const SizedBox(),
                      ),
                    ),
                  TextButton(
                    onPressed: () => setSImg(() {}),
                    child: const Text('Previsualizar imagen'),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              // Toggle tamaños
              Container(
                decoration: BoxDecoration(
                  color: tieneTamanos ? Colors.teal[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: tieneTamanos
                          ? Colors.teal.shade200
                          : Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  title: const Text('Tiene tamaños',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  subtitle: Text(tieneTamanos
                      ? 'Personal · Mediano · Grande'
                      : 'Precio único'),
                  value: tieneTamanos,
                  activeThumbColor: Colors.teal[700],
                  activeTrackColor: Colors.teal[100],
                  onChanged: (v) => setS(() => tieneTamanos = v),
                ),
              ),
              const SizedBox(height: 12),

              // Categoría
              const Align(alignment: Alignment.centerLeft,
                  child: Text('Categoría:',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categorias.map((c) => GestureDetector(
                  onTap: () => setS(() => categoria = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: categoria == c
                          ? Colors.teal[700] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: categoria == c
                              ? Colors.teal[700]! : Colors.grey.shade300),
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
                  backgroundColor: Colors.teal[700]),
              onPressed: cargando ? null : () async {
                if (nombreCtrl.text.isEmpty || precioCtrl.text.isEmpty) {
                  setS(() => error = 'Nombre y precio son obligatorios');
                  return;
                }
                setS(() { cargando = true; error = null; });
                final nueva = BebidaDB(
                  id:           bebida?.id ?? '',
                  nombre:       nombreCtrl.text.trim(),
                  descripcion:  descCtrl.text.trim(),
                  precioBase:   double.tryParse(precioCtrl.text) ?? 0,
                  imageUrl:     imgCtrl.text.trim(),
                  categoria:    categoria,
                  tieneTamanos: tieneTamanos,
                );
                final err = esEdicion
                    ? await BebidaService.actualizar(bebida.id, nueva)
                    : await BebidaService.crear(nueva);
                if (!ctx.mounted) return;
                if (err != null) {
                  setS(() { cargando = false; error = err; });
                } else {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(esEdicion
                        ? '✅ Bebida actualizada' : '✅ Bebida creada'),
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

  void _confirmarEliminar(BuildContext context, BebidaDB bebida) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('🗑️ Eliminar bebida'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('¿Eliminar "${bebida.nombre}" del menú?'),
          const SizedBox(height: 8),
          const Text('Esta acción ocultará la bebida del catálogo.',
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
              await BebidaService.eliminar(bebida.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                  content: Text('🗑️ Bebida eliminada del menú'),
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

// ════════════════════════════════════════════════════════════════════════════
// Card de bebida
// ════════════════════════════════════════════════════════════════════════════

class _BebidaAdminCard extends StatelessWidget {
  final BebidaDB bebida;
  final VoidCallback onEditar, onEliminar;
  const _BebidaAdminCard(
      {required this.bebida,
      required this.onEditar,
      required this.onEliminar});

  Color _catColor(String c) {
    switch (c) {
      case 'Gaseosas':  return Colors.red[600]!;
      case 'Jugos':     return Colors.orange[700]!;
      case 'Cafés':     return Colors.brown[600]!;
      case 'Mates':     return Colors.green[700]!;
      case 'Agua':      return Colors.blue[600]!;
      case 'Cervezas':  return Colors.amber[700]!;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(children: [
          // Imagen
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14)),
            child: CachedNetworkImage(
              imageUrl: bebida.imageUrl,
              width: 90, height: 90, fit: BoxFit.cover,
              placeholder: (c, u) => Container(
                  width: 90, height: 90, color: Colors.teal[50],
                  child: const Center(
                      child: Text('🥤',
                          style: TextStyle(fontSize: 32)))),
              errorWidget: (c, u, e) => Container(
                  width: 90, height: 90, color: Colors.teal[50],
                  child: const Center(
                      child: Text('🥤',
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
                Row(children: [
                  Expanded(child: Text(bebida.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15))),
                  if (!bebida.tieneTamanos)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Precio único',
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(bebida.descripcion,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _catColor(bebida.categoria)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(bebida.categoria,
                        style: TextStyle(
                            color: _catColor(bebida.categoria),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Text('Bs. ${bebida.precioBase.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: Colors.teal[700],
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

// ════════════════════════════════════════════════════════════════════════════
// Widgets helper
// ════════════════════════════════════════════════════════════════════════════

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
          const Text('🥤', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Sin bebidas en Firebase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Sube el catálogo inicial o crea una bebida.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700]),
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('Subir bebidas iniciales',
                style: TextStyle(color: Colors.white)),
            onPressed: onSubir,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear bebida nueva'),
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
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
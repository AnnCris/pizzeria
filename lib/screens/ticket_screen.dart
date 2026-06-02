import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/orden_provider.dart';
import '../models/orden.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});
  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final _notasCtrl = TextEditingController();

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _imprimirTicket(Orden orden) async {
    final pdf     = pw.Document();
    final formato = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Text('LA BELLA PIZZERIA',
              style: pw.TextStyle(fontSize: 16,
                  fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text('Tel: 591-XXXX-XXXX')),
          pw.Divider(),
          pw.Text('Orden: #${orden.id}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(orden.mesa),
          pw.Text('Fecha: ${formato.format(orden.hora)}'),
          pw.Divider(),
          ...orden.items.map((item) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      child: pw.Text('${item.nombre} (${item.tamano})')),
                  pw.Text('x${item.cantidad}'),
                  pw.Text('Bs.${item.subtotal.toStringAsFixed(2)}'),
                ],
              ),
              if (item.notas.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                  child: pw.Text('  📝 ${item.notas}',
                      style: pw.TextStyle(fontSize: 9,
                          fontStyle: pw.FontStyle.italic)),
                ),
            ],
          )),
          if (orden.notasGenerales.isNotEmpty) ...[
            pw.Divider(),
            pw.Text('Notas: ${orden.notasGenerales}',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
          ],
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                      fontSize: 14)),
              pw.Text('Bs.${orden.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text('¡Gracias por su visita!',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProvider>();
    final ahora    = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('🧾 Tu Pedido',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // ── Encabezado ─────────────────────────────────────
              _Card(child: Column(children: [
                const Text('🍕 La Bella Pizzería',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(ahora),
                    style: const TextStyle(color: Colors.grey)),
                const Divider(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  const Text('Mesa:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(provider.mesa,
                      style: TextStyle(color: Colors.red[700],
                          fontWeight: FontWeight.bold)),
                ]),
              ])),
              const SizedBox(height: 12),

              // ── Items con notas por producto ───────────────────
              _Card(child: Column(children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(flex: 3,
                        child: Text('Producto',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Tam.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
                    Expanded(child: Text('Cant.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
                    Expanded(flex: 2,
                        child: Text('Subtotal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right)),
                  ]),
                ),
                const Divider(height: 1),
                ...provider.carrito.map((item) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(flex: 3,
                            child: Text(item.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                        Expanded(child: Text(item.tamano[0],
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[700],
                                fontWeight: FontWeight.bold))),
                        Expanded(child: Text('×${item.cantidad}',
                            textAlign: TextAlign.center)),
                        Expanded(flex: 2,
                            child: Text(
                                'Bs. ${item.subtotal.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                      ]),
                    ),
                    // Nota por producto
                    GestureDetector(
                      onTap: () => _editarNotaItem(context, item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.notas.isEmpty
                              ? Colors.grey[50]
                              : Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: item.notas.isEmpty
                                  ? Colors.grey.shade200
                                  : Colors.amber.shade300),
                        ),
                        child: Row(children: [
                          Icon(Icons.edit_note,
                              size: 16,
                              color: item.notas.isEmpty
                                  ? Colors.grey
                                  : Colors.amber[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.notas.isEmpty
                                  ? 'Agregar nota (ej: sin cebolla)'
                                  : item.notas,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.notas.isEmpty
                                    ? Colors.grey
                                    : Colors.amber[800],
                                fontStyle: item.notas.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                )),

                // Total
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    const Text('TOTAL',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('Bs. ${provider.totalCarrito.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800])),
                  ]),
                ),
              ])),
              const SizedBox(height: 12),

              // ── Nota general ───────────────────────────────────
              _Card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.note_alt_outlined, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Nota general para la orden',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notasCtrl,
                    maxLines: 2,
                    maxLength: 120,
                    decoration: InputDecoration(
                      hintText: 'Ej: alergia al gluten, todo sin sal...',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.orange.shade400)),
                    ),
                  ),
                ],
              )),
            ]),
          ),
        ),

        // ── Botón confirmar ────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('✅ Confirmar y enviar a cocina',
                  style: TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.bold)),
              // ← FIX: confirmarOrden es async, usamos then()
              onPressed: () async {
                final orden = await provider.confirmarOrden(
                    notasGenerales: _notasCtrl.text.trim());
                if (!context.mounted) return;
                _mostrarConfirmacion(context, orden);
              },
            ),
          ),
        ),
      ]),
    );
  }

  void _editarNotaItem(BuildContext context, ItemOrden item) {
    final ctrl = TextEditingController(text: item.notas);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Text('📝 ', style: TextStyle(fontSize: 22)),
          Expanded(child: Text('Nota para ${item.nombre}',
              style: const TextStyle(fontSize: 16))),
        ]),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 80,
          decoration: InputDecoration(
            hintText: 'Ej: sin cebolla, extra queso...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              item.notas = '';
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Borrar nota',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            onPressed: () {
              item.notas = ctrl.text.trim();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Guardar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacion(BuildContext context, Orden orden) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Text('🎉', style: TextStyle(fontSize: 48)),
          SizedBox(height: 4),
          Text('¡Orden enviada!', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text('# ${orden.id}',
                  style: TextStyle(color: Colors.red[800],
                      fontSize: 18, fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(orden.mesa,
                  style: const TextStyle(color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Bs. ${orden.total.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700])),
          const SizedBox(height: 6),
          const Text('🍕 Tu pizza está siendo preparada',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          if (orden.notasGenerales.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Text('📝 ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(orden.notasGenerales,
                    style: TextStyle(color: Colors.amber[800],
                        fontSize: 12))),
              ]),
            ),
          ],
        ]),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.print_outlined),
            label: const Text('Imprimir'),
            onPressed: () => _imprimirTicket(orden),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.pop(context),
            child: const Text('Listo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
        ),
        child: child,
      );
}
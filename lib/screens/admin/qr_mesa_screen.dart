import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/mesa.dart';
import '../../providers/mesa_provider.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class QrMesasScreen extends StatelessWidget {
  const QrMesasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mesas = context.watch<MesaProvider>().mesas;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('📱 Códigos QR por Mesa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimir todos los QR',
            onPressed: () => _imprimirTodos(context, mesas),
          ),
        ],
      ),
      body: Column(children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'El cliente escanea el QR de su mesa y accede directo al menú con la mesa asignada automáticamente.',
                style: TextStyle(fontSize: 13, color: Colors.blue),
              ),
            ),
          ]),
        ),

        // Contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[700], borderRadius: BorderRadius.circular(12)),
              child: Text('${mesas.length} mesas',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            const Text('Toca una tarjeta para imprimir individualmente',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),

        // Grid de QRs
        Expanded(
          child: mesas.isEmpty
              ? const Center(child: Text('Sin mesas configuradas.\nVe a Gestión de Mesas primero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16)))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: mesas.length,
                  itemBuilder: (_, i) => _QrCard(mesa: mesas[i]),
                ),
        ),
      ]),
    );
  }

  Future<void> _imprimirTodos(BuildContext context, List<Mesa> mesas) async {
    if (mesas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mesas para imprimir')));
      return;
    }

    final pdf = pw.Document();
    // 4 QRs por página
    for (int i = 0; i < mesas.length; i += 4) {
      final grupo = mesas.skip(i).take(4).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(children: [
          pw.Center(
            child: pw.Text('La Bella Pizzería — Códigos QR',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Wrap(
            spacing: 20, runSpacing: 20,
            children: grupo.map((mesa) => pw.Column(children: [
              pw.BarcodeWidget(
                data: 'https://labella.pizzeria/menu?mesa=${mesa.numero}',
                barcode: pw.Barcode.qrCode(),
                width: 120, height: 120,
              ),
              pw.SizedBox(height: 6),
              pw.Text('Mesa ${mesa.numero}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('${mesa.capacidad} personas',
                  style: const pw.TextStyle(fontSize: 10)),
            ])).toList(),
          ),
        ]),
      ));
    }
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}

class _QrCard extends StatelessWidget {
  final Mesa mesa;
  const _QrCard({required this.mesa});

  String get _url => 'https://labella.pizzeria/menu?mesa=${mesa.numero}';

  Color get _estadoColor {
    switch (mesa.estado) {
      case 'libre':            return const Color(0xFF2E7D32);
      case 'ocupada':          return const Color(0xFFC62828);
      case 'esperando_cuenta': return const Color(0xFFE65100);
      default:                 return Colors.grey;
    }
  }

  String get _estadoEmoji {
    switch (mesa.estado) {
      case 'libre':            return '🟢';
      case 'ocupada':          return '🔴';
      case 'esperando_cuenta': return '💰';
      default:                 return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        border: Border.all(color: _estadoColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: QrImageView(
              data: _url,
              version: QrVersions.auto,
              size: 120,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.red[800],
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.red[900],
              ),
            ),
          ),

          // Estado badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _estadoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$_estadoEmoji ${mesa.estado}',
                style: TextStyle(color: _estadoColor, fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 4),
          Text('Mesa ${mesa.numero}',
              style: TextStyle(color: Colors.red[800], fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.people, size: 12, color: Colors.grey),
            const SizedBox(width: 3),
            Text('${mesa.capacidad} personas',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _imprimirUno(context),
            icon: const Icon(Icons.print_outlined, size: 14),
            label: const Text('Imprimir', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _imprimirUno(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (ctx) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('La Bella Pizzería',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Escanea para ver el menú',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 16),
          pw.BarcodeWidget(
            data: _url,
            barcode: pw.Barcode.qrCode(),
            width: 180, height: 180,
          ),
          pw.SizedBox(height: 12),
          pw.Text('Mesa ${mesa.numero}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('Capacidad: ${mesa.capacidad} personas'),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
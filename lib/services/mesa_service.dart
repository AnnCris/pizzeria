import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mesa.dart';

class MesaService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'mesas';

  static Stream<List<Mesa>> stream() =>
      _db.collection(_col).orderBy('numero').snapshots().map(
          (s) => s.docs
              .map((d) => Mesa.fromFirestore(d.data(), d.id))
              .toList());

  static Future<void> crear(int numero, int capacidad,
      {bool esEvento = false, String? etiqueta}) =>
      _db.collection(_col).add({
        'numero':        numero,
        'estado':        'libre',
        'clienteNombre': '',
        'capacidad':     capacidad,
        'ordenId':       null,
        'esEvento':      esEvento,
        'etiqueta':      etiqueta ?? '',
      });

  static Future<void> actualizar(
      String id, Map<String, dynamic> data) =>
      _db.collection(_col).doc(id).update(data);

  static Future<void> eliminar(String id) =>
      _db.collection(_col).doc(id).delete();

  static Future<void> liberarMesa(String id) =>
      _db.collection(_col).doc(id).update({
        'estado':        'libre',
        'clienteNombre': '',
        'ordenId':       null,
      });

  // Marca una mesa como ocupada buscándola por número
  // Útil cuando el provider aún no cargó las mesas
  static Future<void> marcarOcupadaPorNumero(
      int numero, String clienteNombre) async {
    try {
      final snap = await _db
          .collection(_col)
          .where('numero', isEqualTo: numero)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'estado':        'ocupada',
          'clienteNombre': clienteNombre,
        });
      }
    } catch (_) {
      // Si falla, ignorar — no bloquear al cliente
    }
  }

  static Future<void> crearMesasIniciales(int n) async {
    final snap = await _db.collection(_col).limit(1).get();
    if (snap.docs.isNotEmpty) return; // ya existen
    final batch = _db.batch();
    for (int i = 1; i <= n; i++) {
      final ref = _db.collection(_col).doc();
      batch.set(ref, {
        'numero':        i,
        'estado':        'libre',
        'clienteNombre': '',
        'capacidad':     i <= 2 ? 2 : 4,
        'ordenId':       null,
        'esEvento':      false,
        'etiqueta':      '',
      });
    }
    await batch.commit();
  }
}
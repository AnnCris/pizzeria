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

  static Future<void> crear(int numero, int capacidad) =>
      _db.collection(_col).add(
          Mesa(id: '', numero: numero, capacidad: capacidad).toMap());

  static Future<void> actualizar(String id, Map<String, dynamic> data) =>
      _db.collection(_col).doc(id).update(data);

  static Future<void> eliminar(String id) =>
      _db.collection(_col).doc(id).delete();

  static Future<void> liberarMesa(String id) =>
      _db.collection(_col).doc(id).update({
        'estado': 'libre',
        'clienteNombre': '',
        'ordenId': null,
      });

  static Future<void> crearMesasIniciales(int n) async {
    final snap = await _db.collection(_col).limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (int i = 1; i <= n; i++) {
      final ref = _db.collection(_col).doc();
      batch.set(ref,
          Mesa(id: '', numero: i, capacidad: i <= 2 ? 2 : 4).toMap());
    }
    await batch.commit();
  }
}
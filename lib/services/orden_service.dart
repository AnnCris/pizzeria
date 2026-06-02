import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orden.dart';

class OrdenService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ordenes';

  // Escuchar órdenes activas en tiempo real
  static Stream<List<Orden>> streamActivas() =>
      _db.collection(_col)
          .where('estado', whereNotIn: ['entregada'])
          .orderBy('hora', descending: true)
          .snapshots()
          .map((s) => s.docs.map(_fromDoc).toList());

  // Órdenes del día para reportes
  static Stream<List<Orden>> streamHoy() {
    final inicio = DateTime.now();
    final hoyInicio = DateTime(inicio.year, inicio.month, inicio.day);
    return _db.collection(_col)
        .where('hora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(hoyInicio))
        .orderBy('hora', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  static Future<String> crear(Orden orden) async {
    final ref = await _db.collection(_col).add({
      'mesa':            orden.mesa,
      'hora':            Timestamp.fromDate(orden.hora),
      'estado':          orden.estado,
      'notasGenerales':  orden.notasGenerales,
      'total':           orden.total,
      'items': orden.items.map((i) => {
        'pizzaId':  i.pizzaId,
        'nombre':   i.nombre,
        'precio':   i.precio,
        'tamano':   i.tamano,
        'cantidad': i.cantidad,
        'notas':    i.notas,
        'subtotal': i.subtotal,
      }).toList(),
    });
    return ref.id;
  }

  static Future<void> actualizarEstado(String id, String estado) =>
      _db.collection(_col).doc(id).update({'estado': estado});

  static Orden _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final itemsRaw = (d['items'] as List?) ?? [];
    return Orden(
      id:             doc.id,
      mesa:           d['mesa']           ?? '',
      hora:           (d['hora'] as Timestamp).toDate(),
      estado:         d['estado']         ?? 'pendiente',
      notasGenerales: d['notasGenerales'] ?? '',
      items: itemsRaw.map((i) => ItemOrden(
        pizzaId:  i['pizzaId']  ?? '',
        nombre:   i['nombre']   ?? '',
        precio:   (i['precio']  ?? 0).toDouble(),
        tamano:   i['tamano']   ?? '',
        cantidad: i['cantidad'] ?? 1,
        notas:    i['notas']    ?? '',
      )).toList(),
    );
  }
}
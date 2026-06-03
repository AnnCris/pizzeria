import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orden.dart';

class OrdenService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ordenes';

  // Stream en tiempo real — todas las órdenes excepto entregadas
  // IMPORTANTE: este query requiere un índice compuesto en Firestore.
  // Si falla, usa streamTodasActivas() que no requiere índice.
  static Stream<List<Orden>> streamActivas() {
    return _db
        .collection(_col)
        .orderBy('hora', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map(_fromDoc)
            .where((o) => o.estado != 'entregada')
            .toList())
        .handleError((_) => <Orden>[]);
  }

  // Órdenes del día actual para reportes
  static Stream<List<Orden>> streamHoy() {
    final hoy   = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin    = inicio.add(const Duration(days: 1));
    return _db
        .collection(_col)
        .where('hora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('hora', isLessThan: Timestamp.fromDate(fin))
        .orderBy('hora', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList())
        .handleError((_) => <Orden>[]);
  }

  // Stream de UNA orden por firestoreId — para EstadoPedidoScreen
  static Stream<Orden?> streamOrden(String firestoreId) {
    return _db
        .collection(_col)
        .doc(firestoreId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  // Crear orden en Firestore, retorna el firestoreId
  static Future<String> crear(Orden orden) async {
    final ref = await _db.collection(_col).add({
      'id':             orden.id,
      'mesa':           orden.mesa,
      'hora':           Timestamp.fromDate(orden.hora),
      'estado':         orden.estado,
      'notasGenerales': orden.notasGenerales,
      'total':          orden.total,
      'fecha': '${orden.hora.year}-'
          '${orden.hora.month.toString().padLeft(2, '0')}-'
          '${orden.hora.day.toString().padLeft(2, '0')}',
      'items': orden.items
          .map((i) => {
                'pizzaId':  i.pizzaId,
                'nombre':   i.nombre,
                'precio':   i.precio,
                'tamano':   i.tamano,
                'cantidad': i.cantidad,
                'notas':    i.notas,
                'subtotal': i.subtotal,
              })
          .toList(),
    });
    return ref.id; // ← firestoreId real
  }

  // Actualizar estado usando firestoreId
  static Future<void> actualizarEstado(
      String firestoreId, String estado) =>
      _db.collection(_col).doc(firestoreId).update({
        'estado':    estado,
        'updatedAt': Timestamp.now(),
      });

  static Orden _fromDoc(DocumentSnapshot doc) {
    final d        = doc.data() as Map<String, dynamic>;
    final itemsRaw = (d['items'] as List?) ?? [];
    return Orden(
      id:             (d['id'] as String?) ??
                      doc.id.substring(0, 8).toUpperCase(),
      mesa:           (d['mesa']           as String?) ?? '',
      hora:           (d['hora']           as Timestamp).toDate(),
      estado:         (d['estado']         as String?) ?? 'pendiente',
      notasGenerales: (d['notasGenerales'] as String?) ?? '',
      firestoreId:    doc.id,  // ← siempre el ID real de Firestore
      items: itemsRaw.map((i) {
        final m = i as Map<String, dynamic>;
        return ItemOrden(
          pizzaId:  (m['pizzaId']  as String?) ?? '',
          nombre:   (m['nombre']   as String?) ?? '',
          precio:   ((m['precio']  ?? 0) as num).toDouble(),
          tamano:   (m['tamano']   as String?) ?? '',
          cantidad: (m['cantidad'] as int?)    ?? 1,
          notas:    (m['notas']    as String?) ?? '',
        );
      }).toList(),
    );
  }
}
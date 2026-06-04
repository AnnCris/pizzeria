import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orden.dart';

class OrdenService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ordenes';

  static Stream<List<Orden>> streamActivas() {
    return _db
        .collection(_col)
        .orderBy('hora', descending: true)
        .limit(200) 
        .snapshots()
        .map((s) {
          final hoy    = DateTime.now();
          final inicio = DateTime(hoy.year, hoy.month, hoy.day);
          return s.docs
              .map(_fromDoc)
              .where((o) => o.hora.isAfter(inicio))
              .toList();
        });
  }

  static Stream<Orden?> streamOrden(String firestoreId) {
    return _db
        .collection(_col)
        .doc(firestoreId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }


  static Future<String> crear(Orden orden) async {
    final hoy = orden.hora;
    final ref = await _db.collection(_col).add({
      'id':             orden.id,
      'mesa':           orden.mesa,
      'clienteNombre':  orden.clienteNombre,
      'hora':           Timestamp.fromDate(hoy),
      'estado':         orden.estado,
      'notasGenerales': orden.notasGenerales,
      'total':          orden.total,
      'fecha': '${hoy.year}-'
          '${hoy.month.toString().padLeft(2, '0')}-'
          '${hoy.day.toString().padLeft(2, '0')}',
      'items': orden.items.map((i) => {
        'pizzaId':  i.pizzaId,
        'nombre':   i.nombre,
        'precio':   i.precio,
        'tamano':   i.tamano,
        'cantidad': i.cantidad,
        'notas':    i.notas,
        'subtotal': i.subtotal,
        'tipo':     i.tipo,
      }).toList(),
    });
    return ref.id;
  }

  // Actualizar estado usando firestoreId real
  static Future<void> actualizarEstado(
      String firestoreId, String estado) =>
      _db.collection(_col).doc(firestoreId).update({
        'estado':    estado,
        'updatedAt': Timestamp.now(),
      });

  static Orden _fromDoc(DocumentSnapshot doc) {
    final d        = doc.data() as Map<String, dynamic>;
    final itemsRaw = (d['items'] as List?) ?? [];
    
    // Parsear hora de forma segura
    DateTime hora;
    try {
      hora = (d['hora'] as Timestamp).toDate();
    } catch (_) {
      hora = DateTime.now();
    }

    return Orden(
      id:             (d['id']             as String?) ??
                      doc.id.substring(0, 8).toUpperCase(),
      mesa:           (d['mesa']           as String?) ?? '',
      clienteNombre:  (d['clienteNombre']  as String?) ?? '',
      hora:           hora,
      estado:         (d['estado']         as String?) ?? 'pendiente',
      notasGenerales: (d['notasGenerales'] as String?) ?? '',
      firestoreId:    doc.id,
      items: itemsRaw.map((i) {
        final m = i as Map<String, dynamic>;
        return ItemOrden(
          pizzaId:  (m['pizzaId']  as String?) ?? '',
          nombre:   (m['nombre']   as String?) ?? '',
          precio:   ((m['precio']  ?? 0) as num).toDouble(),
          tamano:   (m['tamano']   as String?) ?? '',
          cantidad: (m['cantidad'] as int?)    ?? 1,
          notas:    (m['notas']    as String?) ?? '',
          tipo:     (m['tipo']     as String?) ?? 'pizza',
        );
      }).toList(),
    );
  }
}
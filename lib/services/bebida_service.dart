import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bebida.dart';

class BebidaDB {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioBase;
  final String imageUrl;
  final String categoria;
  final bool tieneTamanos;
  final bool activo;

  BebidaDB({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioBase,
    required this.imageUrl,
    required this.categoria,
    this.tieneTamanos = true,
    this.activo = true,
  });

  factory BebidaDB.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BebidaDB(
      id:           doc.id,
      nombre:       (d['nombre']       as String?) ?? '',
      descripcion:  (d['descripcion']  as String?) ?? '',
      precioBase:   ((d['precioBase']  ?? 0) as num).toDouble(),
      imageUrl:     (d['imageUrl']     as String?) ?? '',
      categoria:    (d['categoria']    as String?) ?? 'Gaseosas',
      tieneTamanos: (d['tieneTamanos'] as bool?)   ?? true,
      activo:       (d['activo']       as bool?)   ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre':       nombre,
    'descripcion':  descripcion,
    'precioBase':   precioBase,
    'imageUrl':     imageUrl,
    'categoria':    categoria,
    'tieneTamanos': tieneTamanos,
    'activo':       activo,
  };

  // Convierte a Bebida para usar en el menú
  Bebida toBebida() => Bebida(
    id:           id,
    nombre:       nombre,
    descripcion:  descripcion,
    precioBase:   precioBase,
    imageUrl:     imageUrl,
    categoria:    categoria,
    tieneTamanos: tieneTamanos,
  );
}

class BebidaService {
  static final _db  = FirebaseFirestore.instance;
  static const _col = 'bebidas';

  // Stream en tiempo real — solo activas
  static Stream<List<BebidaDB>> stream() {
    return _db
        .collection(_col)
        .where('activo', isEqualTo: true)
        .orderBy('categoria')
        .snapshots()
        .map((s) => s.docs.map(BebidaDB.fromFirestore).toList())
        .handleError((_) => <BebidaDB>[]);
  }

  // Crear bebida
  static Future<String?> crear(BebidaDB bebida) async {
    try {
      await _db.collection(_col).add(bebida.toMap());
      return null;
    } catch (e) {
      return _mensajeError(e);
    }
  }

  // Actualizar bebida
  static Future<String?> actualizar(String id, BebidaDB bebida) async {
    try {
      await _db.collection(_col).doc(id).update(bebida.toMap());
      return null;
    } catch (e) {
      return _mensajeError(e);
    }
  }

  // Soft delete
  static Future<String?> eliminar(String id) async {
    try {
      await _db.collection(_col).doc(id).update({'activo': false});
      return null;
    } catch (e) {
      return _mensajeError(e);
    }
  }

  // Subir catálogo inicial
  static Future<String?> subirBebidasIniciales() async {
    try {
      final snap = await _db.collection(_col).limit(1).get();
      if (snap.docs.isNotEmpty) return 'Ya existen bebidas en Firebase';

      final lotes = <List<Bebida>>[];
      for (int i = 0; i < menuBebidas.length; i += 10) {
        lotes.add(menuBebidas.skip(i).take(10).toList());
      }
      for (final lote in lotes) {
        final batch = _db.batch();
        for (final b in lote) {
          final ref = _db.collection(_col).doc();
          batch.set(ref, {
            'nombre':       b.nombre,
            'descripcion':  b.descripcion,
            'precioBase':   b.precioBase,
            'imageUrl':     b.imageUrl,
            'categoria':    b.categoria,
            'tieneTamanos': b.tieneTamanos,
            'activo':       true,
          });
        }
        await batch.commit();
      }
      return null;
    } catch (e) {
      return _mensajeError(e);
    }
  }

  static String _mensajeError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('permission-denied')) {
      return 'Sin permisos. Verifica las reglas de Firestore.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Sin conexión a internet.';
    }
    if (msg.contains('unauthenticated')) {
      return 'Sesión expirada. Vuelve a iniciar sesión.';
    }
    return 'Error: ${e.toString().split(']').last.trim()}';
  }
}
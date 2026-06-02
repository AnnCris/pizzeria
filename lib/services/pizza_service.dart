import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pizza.dart';

class PizzaDB {
  final String id;
  final String nombre;
  final String ingredientes;
  final double precioBase;
  final String imageUrl;
  final String categoria;
  final bool activo;

  PizzaDB({
    required this.id,
    required this.nombre,
    required this.ingredientes,
    required this.precioBase,
    required this.imageUrl,
    required this.categoria,
    this.activo = true,
  });

  factory PizzaDB.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PizzaDB(
      id:           doc.id,
      nombre:       d['nombre']       ?? '',
      ingredientes: d['ingredientes'] ?? '',
      precioBase:   (d['precioBase']  ?? 0).toDouble(),
      imageUrl:     d['imageUrl']     ?? '',
      categoria:    d['categoria']    ?? 'Clásicas',
      activo:       d['activo']       ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre':       nombre,
    'ingredientes': ingredientes,
    'precioBase':   precioBase,
    'imageUrl':     imageUrl,
    'categoria':    categoria,
    'activo':       activo,
  };

  Pizza toPizza() => Pizza(
    id:           id,
    nombre:       nombre,
    ingredientes: ingredientes,
    precioBase:   precioBase,
    imageUrl:     imageUrl,
    categoria:    categoria,
  );
}

class PizzaService {
  static final _db  = FirebaseFirestore.instance;
  static const _col = 'pizzas';

  // ── Stream en tiempo real ─────────────────────────────────────────────
  static Stream<List<PizzaDB>> stream() {
    return _db
        .collection(_col)
        .where('activo', isEqualTo: true)
        .orderBy('categoria')
        .snapshots()
        .map((s) => s.docs.map(PizzaDB.fromFirestore).toList())
        .handleError((e) => <PizzaDB>[]);
  }

  // ── Crear ─────────────────────────────────────────────────────────────
  static Future<String?> crear(PizzaDB pizza) async {
    try {
      await _db.collection(_col).add(pizza.toMap());
      return null;
    } catch (e) {
      return _mensajeError(e);
    }
  }

  // ── Actualizar ────────────────────────────────────────────────────────
  static Future<String?> actualizar(String id, PizzaDB pizza) async {
    try {
      await _db.collection(_col).doc(id).update(pizza.toMap());
      return null;
    } catch (e) {
      return _mensajeError(e);
    }
  }

  // ── Eliminar (soft delete) ────────────────────────────────────────────
  static Future<String?> eliminar(String id) async {
    try {
      await _db.collection(_col).doc(id).update({'activo': false});
      return null;
    } catch (e) {
      return _mensajeError(e);
    }
  }

  // ── Subir pizzas iniciales ────────────────────────────────────────────
  static Future<String?> subirPizzasIniciales() async {
    try {
      final snap = await _db.collection(_col).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return 'Ya existen pizzas en Firebase';
      }
      // Subir en lotes de 10 para evitar límites de Firestore
      final lotes = <List<Pizza>>[];
      for (int i = 0; i < menuPizzas.length; i += 10) {
        lotes.add(menuPizzas.skip(i).take(10).toList());
      }
      for (final lote in lotes) {
        final batch = _db.batch();
        for (final p in lote) {
          final ref = _db.collection(_col).doc();
          batch.set(ref, {
            'nombre':       p.nombre,
            'ingredientes': p.ingredientes,
            'precioBase':   p.precioBase,
            'imageUrl':     p.imageUrl,
            'categoria':    p.categoria,
            'activo':       true,
          });
        }
        await batch.commit();
      }
      return null; // éxito
    } catch (e) {
      return _mensajeError(e);
    }
  }

  // ── Mensaje de error legible ──────────────────────────────────────────
  static String _mensajeError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('permission-denied') || msg.contains('permission denied')) {
      return 'Sin permisos. Verifica las reglas de Firestore.';
    }
    if (msg.contains('not-found') || msg.contains('no document')) {
      return 'Documento no encontrado.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Sin conexión. Verifica tu internet.';
    }
    if (msg.contains('unauthenticated')) {
      return 'Sesión expirada. Vuelve a iniciar sesión.';
    }
    return 'Error: ${e.toString().split(']').last.trim()}';
  }
}
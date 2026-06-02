import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pizza.dart';

// Modelo extendido para Firestore (permite editar)
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

  // Convierte a Pizza local para el menú
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
  static final _db = FirebaseFirestore.instance;
  static const _col = 'pizzas';

  // ── Escuchar en tiempo real ──────────────────────────────────────────────
  static Stream<List<PizzaDB>> stream() =>
      _db.collection(_col)
          .where('activo', isEqualTo: true)
          .orderBy('categoria')
          .snapshots()
          .map((s) => s.docs.map(PizzaDB.fromFirestore).toList());

  // ── Crear ────────────────────────────────────────────────────────────────
  static Future<void> crear(PizzaDB pizza) =>
      _db.collection(_col).add(pizza.toMap());

  // ── Actualizar ───────────────────────────────────────────────────────────
  static Future<void> actualizar(String id, PizzaDB pizza) =>
      _db.collection(_col).doc(id).update(pizza.toMap());

  // ── Eliminar (soft delete) ───────────────────────────────────────────────
  static Future<void> eliminar(String id) =>
      _db.collection(_col).doc(id).update({'activo': false});

  // ── Subir pizzas iniciales si la colección está vacía ───────────────────
  static Future<void> subirPizzasIniciales() async {
    final snap = await _db.collection(_col).limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final p in menuPizzas) {
      final ref = _db.collection(_col).doc();
      batch.set(ref, PizzaDB(
        id: '', nombre: p.nombre, ingredientes: p.ingredientes,
        precioBase: p.precioBase, imageUrl: p.imageUrl,
        categoria: p.categoria,
      ).toMap());
    }
    await batch.commit();
  }
}
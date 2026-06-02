import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsuarioDB {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;

  UsuarioDB({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.activo = true,
  });

  factory UsuarioDB.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UsuarioDB(
      id:     doc.id,
      nombre: d['nombre'] ?? '',
      email:  d['email']  ?? '',
      rol:    d['rol']    ?? 'cajero',
      activo: d['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'email':  email,
    'rol':    rol,
    'activo': activo,
  };
}

class UsuarioService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const _col  = 'usuarios';

  static Stream<List<UsuarioDB>> stream() =>
      _db.collection(_col).snapshots().map(
          (s) => s.docs.map(UsuarioDB.fromFirestore).toList());

  static Future<void> crear(
      String nombre, String email, String password, String rol) async {
    // Crear en Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    // Guardar datos en Firestore
    await _db.collection(_col).doc(cred.user!.uid).set({
      'nombre': nombre,
      'email':  email,
      'rol':    rol,
      'activo': true,
    });
  }

  static Future<void> actualizar(
      String id, String nombre, String rol, bool activo) =>
      _db.collection(_col).doc(id).update({
        'nombre': nombre,
        'rol':    rol,
        'activo': activo,
      });

  static Future<void> eliminar(String id) =>
      _db.collection(_col).doc(id).update({'activo': false});
}
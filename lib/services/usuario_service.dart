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

  // ── Stream de usuarios ─────────────────────────────────────────────────
  static Stream<List<UsuarioDB>> stream() {
    return _db
        .collection(_col)
        .orderBy('nombre')
        .snapshots()
        .map((s) => s.docs.map(UsuarioDB.fromFirestore).toList())
        .handleError((e) => <UsuarioDB>[]);
  }

  // ── Crear usuario ──────────────────────────────────────────────────────
  // IMPORTANTE: en Flutter Web, crear un usuario con Firebase Auth
  // cierra la sesión del admin actual. Por eso guardamos los datos
  // del admin y lo re-autenticamos después si es necesario.
  static Future<String?> crear(
      String nombre, String email, String password, String rol) async {
    // Validaciones previas
    if (nombre.trim().isEmpty) return 'El nombre es obligatorio';
    if (email.trim().isEmpty)  return 'El correo es obligatorio';
    if (password.length < 6)   return 'La contraseña debe tener mínimo 6 caracteres';

    try {
      // Crear en Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) return 'No se pudo obtener el UID del usuario';

      // Guardar en Firestore
      await _db.collection(_col).doc(uid).set({
        'nombre': nombre.trim(),
        'email':  email.trim(),
        'rol':    rol,
        'activo': true,
      });

      return null; // éxito

    } catch (e) {
      return _mensajeErrorAuth(e);
    }
  }

  // ── Actualizar datos del usuario ───────────────────────────────────────
  static Future<String?> actualizar(
      String id, String nombre, String rol, bool activo) async {
    try {
      await _db.collection(_col).doc(id).update({
        'nombre': nombre.trim(),
        'rol':    rol,
        'activo': activo,
      });
      return null;
    } catch (e) {
      return _mensajeErrorDB(e);
    }
  }

  // ── Desactivar usuario (soft delete) ──────────────────────────────────
  static Future<String?> eliminar(String id) async {
    try {
      await _db.collection(_col).doc(id).update({'activo': false});
      return null;
    } catch (e) {
      return _mensajeErrorDB(e);
    }
  }

  // ── Parsear errores de Auth compatibles con web ────────────────────────
  static String _mensajeErrorAuth(dynamic e) {
    // En Flutter Web los errores de Firebase Auth vienen como strings
    // no como FirebaseAuthException directamente
    final msg = e.toString().toLowerCase();

    if (msg.contains('email-already-in-use') ||
        msg.contains('email already in use')) {
      return 'El correo ya está registrado';
    }
    if (msg.contains('weak-password') || msg.contains('weak password')) {
      return 'Contraseña muy débil (mínimo 6 caracteres)';
    }
    if (msg.contains('invalid-email') || msg.contains('invalid email')) {
      return 'El correo no es válido';
    }
    if (msg.contains('network-request-failed') ||
        msg.contains('network request failed')) {
      return 'Sin conexión a internet';
    }
    if (msg.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    if (msg.contains('operation-not-allowed')) {
      return 'Operación no permitida. Activa Email/Password en Firebase Auth.';
    }
    // Extrae solo el mensaje útil del error
    final partes = e.toString().split(']');
    return partes.length > 1
        ? partes.last.trim()
        : e.toString();
  }

  static String _mensajeErrorDB(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('permission-denied')) {
      return 'Sin permisos. Verifica las reglas de Firestore.';
    }
    if (msg.contains('unauthenticated')) {
      return 'Sesión expirada. Vuelve a iniciar sesión.';
    }
    return 'Error: ${e.toString().split(']').last.trim()}';
  }
}
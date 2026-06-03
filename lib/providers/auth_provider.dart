import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  String? _rol;
  String? _nombre;
  String? _uid;
  bool    _cargando = true;

  String? get rol      => _rol;
  String? get nombre   => _nombre;
  String? get uid      => _uid;
  bool get isLoggedIn  => _uid != null;
  bool get cargando    => _cargando;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _uid = user.uid;
        await _cargarDatos(user.uid);
      } else {
        _uid    = null;
        _rol    = null;
        _nombre = null;
      }
      _cargando = false;
      notifyListeners();
    });
  }

  Future<void> _cargarDatos(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        // Lee exactamente el campo 'rol' de Firestore
        final data = doc.data()!;
        _rol    = (data['rol']    as String?) ?? 'cajero';
        _nombre = (data['nombre'] as String?) ??
            FirebaseAuth.instance.currentUser?.email ?? 'Usuario';
      } else {
        // Usuario no tiene documento en Firestore — asumir cajero
        _rol    = 'cajero';
        _nombre = FirebaseAuth.instance.currentUser?.email ?? 'Usuario';
      }
    } catch (e) {
      _rol    = 'cajero';
      _nombre = FirebaseAuth.instance.currentUser?.email ?? 'Usuario';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      // Esperar a que se carguen los datos del rol
      if (cred.user != null) {
        await _cargarDatos(cred.user!.uid);
        _uid = cred.user!.uid;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return _parsearError(e);
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _uid    = null;
    _rol    = null;
    _nombre = null;
    notifyListeners();
  }

  static String _parsearError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user-not-found') || msg.contains('no user')) {
      return 'Usuario no encontrado';
    }
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('invalid credential')) {
      return 'Contraseña incorrecta';
    }
    if (msg.contains('invalid-email')) return 'Correo no válido';
    if (msg.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera.';
    }
    if (msg.contains('network-request-failed')) return 'Sin conexión';
    if (msg.contains('user-disabled')) return 'Cuenta desactivada';
    return 'Error al iniciar sesión';
  }
}
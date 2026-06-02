import 'package:flutter/material.dart';

// Usuarios hardcodeados — cuando Firebase esté listo se reemplaza este archivo
class AuthProvider extends ChangeNotifier {
  String? _rol;
  String? _nombre;

  String? get rol      => _rol;
  String? get nombre   => _nombre;
  bool get isLoggedIn  => _rol != null;
  bool get cargando => false;

  static const _usuarios = {
    'admin@pizzeria.com':  {'pass': 'admin123',  'rol': 'admin',  'nombre': 'Administrador'},
    'cajero@pizzeria.com': {'pass': 'cajero123', 'rol': 'cajero', 'nombre': 'Cajero'},
    'cocina@pizzeria.com': {'pass': 'cocina123', 'rol': 'cocina', 'nombre': 'Cocina'},
  };

  Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400)); // simula red
    final user = _usuarios[email.trim().toLowerCase()];
    if (user == null || user['pass'] != password) {
      return 'Correo o contraseña incorrectos';
    }
    _rol    = user['rol'];
    _nombre = user['nombre'];
    notifyListeners();
    return null;
  }

  void logout() {
    _rol    = null;
    _nombre = null;
    notifyListeners();
  }
}
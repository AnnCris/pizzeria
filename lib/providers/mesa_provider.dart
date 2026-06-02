import 'package:flutter/material.dart';
import '../models/mesa.dart';

class MesaProvider extends ChangeNotifier {
  final List<Mesa> _mesas = [];
  bool _cargando = true;

  List<Mesa> get mesas          => _mesas;
  bool get cargando             => _cargando;
  int get libres                => _mesas.where((m) => m.estado == 'libre').length;
  int get ocupadas              => _mesas.where((m) => m.estado == 'ocupada').length;
  int get cuenta                => _mesas.where((m) => m.estado == 'esperando_cuenta').length;
  int get esperandoCuenta       => cuenta;

  MesaProvider() {
    crearMesasIniciales(10);
  }

  void crearMesasIniciales(int cantidad) {
    if (_mesas.isNotEmpty) return;
    for (int i = 1; i <= cantidad; i++) {
      _mesas.add(Mesa(
        id: 'm$i',
        numero: i,
        capacidad: i <= 2 ? 2 : (i <= 6 ? 4 : 6),
      ));
    }
    _cargando = false;
    notifyListeners();
  }

  void actualizarEstado(String id, String estado,
      {String clienteNombre = '', String? ordenId}) {
    final mesa = _mesas.firstWhere((m) => m.id == id);
    mesa.estado = estado;
    mesa.clienteNombre = clienteNombre;
    notifyListeners();
  }

  void liberarMesa(String id) {
    final mesa = _mesas.firstWhere((m) => m.id == id);
    mesa.estado = 'libre';
    mesa.clienteNombre = '';
    notifyListeners();
  }

  void agregarMesa(int numero, int capacidad) {
    final id = 'm${DateTime.now().millisecondsSinceEpoch}';
    _mesas.add(Mesa(id: id, numero: numero, capacidad: capacidad));
    notifyListeners();
  }

  void eliminarMesa(String id) {
    _mesas.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
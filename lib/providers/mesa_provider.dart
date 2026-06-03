import 'package:flutter/material.dart';
import '../models/mesa.dart';
import '../services/mesa_service.dart';

class MesaProvider extends ChangeNotifier {
  final List<Mesa> _mesas = [];
  bool _cargando = true;

  List<Mesa> get mesas         => _mesas;
  bool       get cargando      => _cargando;
  int        get libres        => _mesas.where((m) => m.estado == 'libre').length;
  int        get ocupadas      => _mesas.where((m) => m.estado == 'ocupada').length;
  int        get cuenta        => _mesas.where((m) => m.estado == 'esperando_cuenta').length;
  int        get esperandoCuenta => cuenta;

  MesaProvider() {
    _escucharFirestore();
  }

  // Escucha en tiempo real desde Firestore
  void _escucharFirestore() {
    MesaService.stream().listen((mesas) {
      _mesas
        ..clear()
        ..addAll(mesas);
      _cargando = false;
      notifyListeners();
    }, onError: (_) {
      _cargando = false;
      notifyListeners();
    });
  }

  // Solo llama si Firestore está vacío
  Future<void> crearMesasIniciales(int cantidad) async {
    await MesaService.crearMesasIniciales(cantidad);
  }

  Future<void> actualizarEstado(String id, String estado,
      {String clienteNombre = '', String? ordenId}) async {
    await MesaService.actualizar(id, {
      'estado': estado,
      'clienteNombre': clienteNombre,
      'ordenId': ordenId,
    });
  }

  Future<void> liberarMesa(String id) async {
    await MesaService.actualizar(id, {
      'estado': 'libre',
      'clienteNombre': '',
      'ordenId': null,
    });
  }

  Future<void> agregarMesa(int numero, int capacidad,
      {bool esEvento = false, String? etiqueta}) async {
    await MesaService.crear(numero, capacidad,
        esEvento: esEvento, etiqueta: etiqueta);
  }

  Future<void> editarMesa(String id, int numero, int capacidad,
      {bool esEvento = false, String? etiqueta}) async {
    await MesaService.actualizar(id, {
      'numero': numero,
      'capacidad': capacidad,
      'esEvento': esEvento,
      'etiqueta': etiqueta ?? '',
    });
  }

  Future<void> eliminarMesa(String id) async {
    await MesaService.eliminar(id);
  }
}
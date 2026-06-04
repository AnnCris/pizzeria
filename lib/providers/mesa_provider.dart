import 'package:flutter/material.dart';
import '../models/mesa.dart';
import '../services/mesa_service.dart';

class MesaProvider extends ChangeNotifier {
  final List<Mesa> _mesas = [];
  bool _cargando = true;

  List<Mesa> get mesas          => _mesas;
  bool       get cargando       => _cargando;
  int        get libres         =>
      _mesas.where((m) => m.estado == 'libre').length;
  int        get ocupadas       =>
      _mesas.where((m) => m.estado == 'ocupada').length;
  int        get cuenta         =>
      _mesas.where((m) => m.estado == 'esperando_cuenta').length;
  int        get esperandoCuenta => cuenta;

  MesaProvider() {
    _escucharFirestore();
  }

  void _escucharFirestore() {
    MesaService.stream().listen((mesas) {
      _mesas
        ..clear()
        ..addAll(mesas);
      _cargando = false;
      notifyListeners();
    }, onError: (e) {
      _cargando = false;
      notifyListeners();
    });
  }

  // Crea 10 mesas iniciales solo si Firestore está vacío
  Future<void> crearMesasIniciales(int cantidad) async {
    await MesaService.crearMesasIniciales(cantidad);
  }

  Future<void> actualizarEstado(String id, String estado,
      {String clienteNombre = '', String? ordenId}) async {
    await MesaService.actualizar(id, {
      'estado':        estado,
      'clienteNombre': clienteNombre,
      'ordenId':       ordenId,
    });
  }

  Future<void> liberarMesa(String id) async {
    await MesaService.actualizar(id, {
      'estado':        'libre',
      'clienteNombre': '',
      'ordenId':       null,
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
      'numero':    numero,
      'capacidad': capacidad,
      'esEvento':  esEvento,
      'etiqueta':  etiqueta ?? '',
    });
  }

  Future<void> eliminarMesa(String id) async {
    await MesaService.eliminar(id);
  }

  // Busca una mesa por número — útil para marcarla ocupada
  // desde menu_screen sin depender de que el provider haya cargado
  Future<void> marcarOcupadaPorNumero(
      int numero, String clienteNombre) async {
    // Primero intentar desde la lista en memoria
    try {
      final mesa = _mesas.firstWhere((m) => m.numero == numero);
      await actualizarEstado(mesa.id, 'ocupada',
          clienteNombre: clienteNombre);
      return;
    } catch (_) {}

    // Si no está en memoria, buscar directamente en Firestore
    await MesaService.marcarOcupadaPorNumero(numero, clienteNombre);
  }
}
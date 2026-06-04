import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pizza.dart';
import '../models/bebida.dart';
import '../models/orden.dart';
import '../services/orden_service.dart';

class OrdenProvider extends ChangeNotifier {
  final List<ItemOrden> _carrito = [];
  final List<Orden>     _ordenes = [];
  final _uuid = const Uuid();
  String _mesa            = '';
  String _clienteNombre   = '';
  String _ultimaOrdenFid  = '';

  String get ultimaOrdenFirestoreId => _ultimaOrdenFid;
  List<ItemOrden> get carrito   => _carrito;
  List<Orden>     get ordenes   => _ordenes;
  String          get mesa      => _mesa;
  String          get clienteNombre => _clienteNombre;
  double get totalCarrito =>
      _carrito.fold(0, (s, i) => s + i.subtotal);


  List<Orden> get ordenesActivas =>
      _ordenes.where((o) => o.estado != 'entregada').toList();

  List<Orden> get ordenesEntregadas =>
      _ordenes.where((o) => o.estado == 'entregada').toList();

  OrdenProvider() {
    _escucharFirestore();
  }

  void _escucharFirestore() {
    OrdenService.streamActivas().listen((lista) {
      _ordenes..clear()..addAll(lista);
      notifyListeners();
    }, onError: (_) => notifyListeners());
  }

  void setMesa(String mesa) {
    _mesa = mesa;
    notifyListeners();
  }

  void setClienteNombre(String nombre) {
    _clienteNombre = nombre;
    notifyListeners();
  }

  void agregarAlCarrito(Pizza pizza, TamanoPizza tamano) {
    final key   = '${pizza.id}_${tamano.nombre}';
    final index = _carrito.indexWhere((i) => i.pizzaId == key);
    if (index >= 0) {
      _carrito[index].cantidad++;
    } else {
      _carrito.add(ItemOrden(
        pizzaId: key,
        nombre:  pizza.nombre,
        precio:  pizza.precioConTamano(tamano),
        tamano:  tamano.nombre,
        tipo:    'pizza',
      ));
    }
    notifyListeners();
  }

  void agregarBebidaAlCarrito(Bebida bebida, TamanoBebida tamano) {
    final key   = 'beb_${bebida.id}_${tamano.nombre}';
    final index = _carrito.indexWhere((i) => i.pizzaId == key);
    if (index >= 0) {
      _carrito[index].cantidad++;
    } else {
      _carrito.add(ItemOrden(
        pizzaId: key,
        nombre:  bebida.nombre,
        precio:  bebida.precioConTamano(tamano),
        tamano:  bebida.tieneTamanos ? tamano.descripcion : 'Único',
        tipo:    'bebida',
      ));
    }
    notifyListeners();
  }

  int cantidadEnCarrito(String pizzaId, String tamano) {
    final key   = '${pizzaId}_$tamano';
    final index = _carrito.indexWhere((i) => i.pizzaId == key);
    return index >= 0 ? _carrito[index].cantidad : 0;
  }

  int cantidadEnCarritoBebida(String key) {
    final index = _carrito.indexWhere((i) => i.pizzaId == key);
    return index >= 0 ? _carrito[index].cantidad : 0;
  }

  void quitarDelCarrito(String pizzaId) {
    final index = _carrito.indexWhere((i) => i.pizzaId == pizzaId);
    if (index >= 0) {
      if (_carrito[index].cantidad > 1) {
        _carrito[index].cantidad--;
      } else {
        _carrito.removeAt(index);
      }
      notifyListeners();
    }
  }

  Future<Orden> confirmarOrden({String notasGenerales = ''}) async {
    final orden = Orden(
      id:             _uuid.v4().substring(0, 8).toUpperCase(),
      mesa:           _mesa,
      clienteNombre:  _clienteNombre,
      hora:           DateTime.now(),
      items:          List.from(_carrito),
      notasGenerales: notasGenerales,
    );
    final fid = await OrdenService.crear(orden);
    final ordenFid = Orden(
      id:             orden.id,
      mesa:           orden.mesa,
      clienteNombre:  orden.clienteNombre,
      hora:           orden.hora,
      items:          orden.items,
      estado:         orden.estado,
      notasGenerales: orden.notasGenerales,
      firestoreId:    fid,
    );
    _ultimaOrdenFid = fid;
    _carrito.clear();
    notifyListeners();
    return ordenFid;
  }

  Future<void> actualizarEstado(
      String firestoreId, String estado) async {
    await OrdenService.actualizarEstado(firestoreId, estado);
  }

  Orden? buscarPorFirestoreId(String fid) {
    try {
      return _ordenes.firstWhere((o) => o.firestoreId == fid);
    } catch (_) {
      return null;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pizza.dart';
import '../models/orden.dart';
import '../services/orden_service.dart';

class OrdenProvider extends ChangeNotifier {
  final List<ItemOrden> _carrito  = [];
  final List<Orden>     _ordenes  = [];
  final _uuid = const Uuid();
  String _mesa = '';

  // firestoreId de la última orden confirmada — para que el cliente
  // pueda navegar a EstadoPedidoScreen sin depender del estado del widget
  String _ultimaOrdenFirestoreId = '';
  String get ultimaOrdenFirestoreId => _ultimaOrdenFirestoreId;

  List<ItemOrden> get carrito    => _carrito;
  List<Orden>     get ordenes    => _ordenes;
  String          get mesa       => _mesa;
  double get totalCarrito =>
      _carrito.fold(0, (s, i) => s + i.subtotal);

  OrdenProvider() {
    _escucharFirestore();
  }

  void _escucharFirestore() {
    OrdenService.streamActivas().listen((lista) {
      _ordenes
        ..clear()
        ..addAll(lista);
      notifyListeners();
    }, onError: (_) {
      notifyListeners();
    });
  }

  void setMesa(String mesa) {
    _mesa = mesa;
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
      ));
    }
    notifyListeners();
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

  /// Guarda la orden en Firestore y retorna la orden con firestoreId correcto
  Future<Orden> confirmarOrden({String notasGenerales = ''}) async {
    final orden = Orden(
      id:             _uuid.v4().substring(0, 8).toUpperCase(),
      mesa:           _mesa,
      hora:           DateTime.now(),
      items:          List.from(_carrito),
      notasGenerales: notasGenerales,
    );

    // Guardar en Firestore y obtener el ID real
    final fid = await OrdenService.crear(orden);

    // Crear nueva instancia con firestoreId correcto
    final ordenConFid = Orden(
      id:             orden.id,
      mesa:           orden.mesa,
      hora:           orden.hora,
      items:          orden.items,
      estado:         orden.estado,
      notasGenerales: orden.notasGenerales,
      firestoreId:    fid,
    );

    _ultimaOrdenFirestoreId = fid;
    _carrito.clear();
    notifyListeners();
    return ordenConFid;
  }

  /// Actualiza estado usando firestoreId (no el ID corto legible)
  Future<void> actualizarEstado(String firestoreId, String estado) async {
    await OrdenService.actualizarEstado(firestoreId, estado);
    // El stream actualiza _ordenes automáticamente
  }

  int cantidadEnCarrito(String pizzaId, String tamano) {
    final key   = '${pizzaId}_$tamano';
    final index = _carrito.indexWhere((i) => i.pizzaId == key);
    return index >= 0 ? _carrito[index].cantidad : 0;
  }

  /// Busca una orden por firestoreId — para la pantalla de estado del cliente
  Orden? buscarPorFirestoreId(String firestoreId) {
    try {
      return _ordenes.firstWhere((o) => o.firestoreId == firestoreId);
    } catch (_) {
      return null;
    }
  }
}
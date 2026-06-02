import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pizza.dart';
import '../models/orden.dart';
import '../services/notification_service.dart';

class OrdenProvider extends ChangeNotifier {
  final List<ItemOrden> _carrito = [];
  final List<Orden>     _ordenes = [];
  final _uuid  = const Uuid();
  final _notif = NotificationService();
  String _mesa = '';

  List<ItemOrden> get carrito  => _carrito;
  List<Orden>     get ordenes  => _ordenes;
  String          get mesa     => _mesa;
  double get totalCarrito      =>
      _carrito.fold(0, (s, i) => s + i.subtotal);

  void setMesa(String mesa) { _mesa = mesa; notifyListeners(); }

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

  Future<Orden> confirmarOrden({String notasGenerales = ''}) async {
    final orden = Orden(
      id:             _uuid.v4().substring(0, 8).toUpperCase(),
      mesa:           _mesa,
      hora:           DateTime.now(),
      items:          List.from(_carrito),
      notasGenerales: notasGenerales,
    );
    _ordenes.add(orden);
    _carrito.clear();
    notifyListeners();

    // ── Disparar notificación de nueva orden ─────────────────────────────
    await _notif.nuevaOrden(
      ordenId:    orden.id,
      mesa:       orden.mesa,
      totalItems: orden.items.fold(0, (s, i) => s + i.cantidad),
    );

    return orden;
  }

  Future<void> actualizarEstado(String ordenId, String estado) async {
    final o = _ordenes.firstWhere((o) => o.id == ordenId);
    o.estado = estado;
    notifyListeners();

    // ── Notificar cuando la orden está lista ─────────────────────────────
    if (estado == 'lista') {
      await _notif.ordenLista(ordenId: ordenId, mesa: o.mesa);
    }
  }

  int cantidadEnCarrito(String pizzaId, String tamano) {
    final key   = '${pizzaId}_$tamano';
    final index = _carrito.indexWhere((i) => i.pizzaId == key);
    return index >= 0 ? _carrito[index].cantidad : 0;
  }
}
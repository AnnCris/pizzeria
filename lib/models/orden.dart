// ACTUALIZACIÓN de lib/models/orden.dart
// Agrega el campo "notas" a ItemOrden

class ItemOrden {
  final String pizzaId;
  final String nombre;
  final double precio;
  final String tamano;
  String notas; // ← NUEVO
  int cantidad;

  ItemOrden({
    required this.pizzaId,
    required this.nombre,
    required this.precio,
    required this.tamano,
    this.notas = '',
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}

class Orden {
  final String id;
  final String mesa;
  final DateTime hora;
  final List<ItemOrden> items;
  String estado;
  String notasGenerales; // ← NUEVO: nota global de la orden

  Orden({
    required this.id,
    required this.mesa,
    required this.hora,
    required this.items,
    this.estado = 'pendiente',
    this.notasGenerales = '',
  });

  double get total => items.fold(0, (s, i) => s + i.subtotal);
}
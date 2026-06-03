class ItemOrden {
  final String pizzaId;
  final String nombre;
  final double precio;
  final String tamano;
  String notas;
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
  final String id;           // ID corto legible: "A3F8C2D1"
  final String firestoreId;  // ID real de Firestore para updates
  final String mesa;
  final DateTime hora;
  final List<ItemOrden> items;
  String estado;
  String notasGenerales;

  Orden({
    required this.id,
    required this.mesa,
    required this.hora,
    required this.items,
    this.estado = 'pendiente',
    this.notasGenerales = '',
    this.firestoreId = '',
  });

  double get total => items.fold(0, (s, i) => s + i.subtotal);
}
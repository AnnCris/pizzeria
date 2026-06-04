class ItemOrden {
  final String pizzaId;
  final String nombre;
  final double precio;
  final String tamano;
  final String tipo; 
  String notas;
  int cantidad;

  ItemOrden({
    required this.pizzaId,
    required this.nombre,
    required this.precio,
    required this.tamano,
    this.tipo     = 'pizza',
    this.notas    = '',
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
  String get emoji    => tipo == 'bebida' ? '🥤' : '🍕';
}

class Orden {
  final String id;            
  final String firestoreId;  
  final String mesa;
  final String clienteNombre; 
  final DateTime hora;
  final List<ItemOrden> items;
  String estado;
  String notasGenerales;

  Orden({
    required this.id,
    required this.mesa,
    required this.hora,
    required this.items,
    this.clienteNombre    = '',
    this.estado           = 'pendiente',
    this.notasGenerales   = '',
    this.firestoreId      = '',
  });

  double get total => items.fold(0, (s, i) => s + i.subtotal);

  List<ItemOrden> get pizzas  =>
      items.where((i) => i.tipo == 'pizza').toList();
  List<ItemOrden> get bebidas =>
      items.where((i) => i.tipo == 'bebida').toList();

  String get etiquetaCliente {
    if (clienteNombre.isNotEmpty) return '$clienteNombre · $mesa';
    return mesa;
  }
}
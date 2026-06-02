class Mesa {
  final String id;
  final int numero;
  String estado; // libre | ocupada | esperando_cuenta
  String clienteNombre;
  int capacidad;
  String? ordenId;

  Mesa({
    required this.id,
    required this.numero,
    this.estado = 'libre',
    this.clienteNombre = '',
    this.capacidad = 4,
    this.ordenId,
  });

  factory Mesa.fromFirestore(Map<String, dynamic> data, String id) => Mesa(
        id: id,
        numero: data['numero'] ?? 0,
        estado: data['estado'] ?? 'libre',
        clienteNombre: data['clienteNombre'] ?? '',
        capacidad: data['capacidad'] ?? 4,
        ordenId: data['ordenId'],
      );

  Map<String, dynamic> toMap() => {
        'numero': numero,
        'estado': estado,
        'clienteNombre': clienteNombre,
        'capacidad': capacidad,
        'ordenId': ordenId,
      };
}
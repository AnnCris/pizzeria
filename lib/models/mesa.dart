class Mesa {
  final String id;
  final int numero;
  String estado; // libre | ocupada | esperando_cuenta
  String clienteNombre;
  int capacidad;
  String? ordenId;
  bool esEvento;      // mesa especial para eventos
  String etiqueta;    // nombre descriptivo ej: "Salón VIP", "Terraza"

  Mesa({
    required this.id,
    required this.numero,
    this.estado = 'libre',
    this.clienteNombre = '',
    this.capacidad = 4,
    this.ordenId,
    this.esEvento = false,
    this.etiqueta = '',
  });

  factory Mesa.fromFirestore(Map<String, dynamic> data, String id) => Mesa(
        id:             id,
        numero:         data['numero']         ?? 0,
        estado:         data['estado']         ?? 'libre',
        clienteNombre:  data['clienteNombre']  ?? '',
        capacidad:      data['capacidad']      ?? 4,
        ordenId:        data['ordenId'],
        esEvento:       data['esEvento']       ?? false,
        etiqueta:       data['etiqueta']       ?? '',
      );

  Map<String, dynamic> toMap() => {
        'numero':        numero,
        'estado':        estado,
        'clienteNombre': clienteNombre,
        'capacidad':     capacidad,
        'ordenId':       ordenId,
        'esEvento':      esEvento,
        'etiqueta':      etiqueta,
      };
}
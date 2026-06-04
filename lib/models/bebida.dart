class TamanoBebida {
  final String nombre;
  final String descripcion;
  final double multiplicador;

  const TamanoBebida({
    required this.nombre,
    required this.descripcion,
    required this.multiplicador,
  });
}

const List<TamanoBebida> tamanosBebida = [
  TamanoBebida(nombre: 'Personal', descripcion: '250 ml',  multiplicador: 0.7),
  TamanoBebida(nombre: 'Mediano',  descripcion: '500 ml',  multiplicador: 1.0),
  TamanoBebida(nombre: 'Grande',   descripcion: '1 litro', multiplicador: 1.5),
];

class Bebida {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioBase;
  final String imageUrl;
  final String categoria;
  final bool tieneTamanos; 

  const Bebida({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioBase,
    required this.imageUrl,
    required this.categoria,
    this.tieneTamanos = true,
  });

  double precioConTamano(TamanoBebida t) =>
      tieneTamanos
          ? (precioBase * t.multiplicador).roundToDouble()
          : precioBase;
}

const List<Bebida> menuBebidas = [
  Bebida(
    id: 'b01', nombre: 'Coca-Cola', categoria: 'Gaseosas',
    descripcion: 'Refresco de cola clásico, bien frío',
    precioBase: 12,
    imageUrl: 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400&q=80',
  ),
  Bebida(
    id: 'b02', nombre: 'Pepsi', categoria: 'Gaseosas',
    descripcion: 'Refresco de cola suave y refrescante',
    precioBase: 12,
    imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&q=80',
  ),
  Bebida(
    id: 'b03', nombre: 'Sprite', categoria: 'Gaseosas',
    descripcion: 'Lima-limón burbujeante y refrescante',
    precioBase: 12,
    imageUrl: 'https://images.unsplash.com/photo-1585951237318-9ea5e175b891?w=400&q=80',
  ),
  Bebida(
    id: 'b04', nombre: 'Fanta Naranja', categoria: 'Gaseosas',
    descripcion: 'Refresco de naranja tropical y burbujeante',
    precioBase: 12,
    imageUrl: 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400&q=80',
  ),
  Bebida(
    id: 'b05', nombre: 'Salvietti', categoria: 'Gaseosas',
    descripcion: 'Gaseosa boliviana sabor a uva, clásica nacional',
    precioBase: 10,
    imageUrl: 'https://images.unsplash.com/photo-1543253687-c931c8e01820?w=400&q=80',
  ),

  Bebida(
    id: 'b06', nombre: 'Jugo de Naranja Natural', categoria: 'Jugos',
    descripcion: 'Exprimido al momento con naranjas frescas bolivianas',
    precioBase: 15,
    imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80',
  ),
  Bebida(
    id: 'b07', nombre: 'Jugo de Maracuyá', categoria: 'Jugos',
    descripcion: 'Maracuyá tropical boliviano con azúcar a gusto',
    precioBase: 15,
    imageUrl: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400&q=80',
  ),
  Bebida(
    id: 'b08', nombre: 'Mocochinchi', categoria: 'Jugos',
    descripcion: 'Bebida boliviana tradicional de durazno deshidratado',
    precioBase: 10,
    imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400&q=80',
  ),
  Bebida(
    id: 'b09', nombre: 'Api Morado', categoria: 'Jugos',
    descripcion: 'Bebida caliente tradicional boliviana de maíz morado con canela',
    precioBase: 10,
    imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&q=80',
  ),

  Bebida(
    id: 'b10', nombre: 'Café Americano', categoria: 'Cafés',
    descripcion: 'Café negro suave, perfecto para acompañar tu pizza',
    precioBase: 12, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&q=80',
  ),
  Bebida(
    id: 'b11', nombre: 'Café con Leche', categoria: 'Cafés',
    descripcion: 'Café espresso con leche caliente espumosa',
    precioBase: 15, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1561882468-9110e03e0f78?w=400&q=80',
  ),
  Bebida(
    id: 'b12', nombre: 'Cappuccino', categoria: 'Cafés',
    descripcion: 'Espresso con leche vaporizada y espuma de leche cremosa',
    precioBase: 18, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&q=80',
  ),

  Bebida(
    id: 'b13', nombre: 'Mate de Coca', categoria: 'Mates',
    descripcion: 'Infusión andina tradicional de hoja de coca, suave y natural',
    precioBase: 8, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80',
  ),
  Bebida(
    id: 'b14', nombre: 'Mate de Manzanilla', categoria: 'Mates',
    descripcion: 'Infusión de manzanilla, relajante y digestiva',
    precioBase: 8, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400&q=80',
  ),
  Bebida(
    id: 'b15', nombre: 'Té Verde', categoria: 'Mates',
    descripcion: 'Té verde antioxidante con rodaja de limón',
    precioBase: 10, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80',
  ),

  Bebida(
    id: 'b16', nombre: 'Agua sin Gas', categoria: 'Agua',
    descripcion: 'Agua mineral pura boliviana',
    precioBase: 8,
    imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400&q=80',
  ),
  Bebida(
    id: 'b17', nombre: 'Agua con Gas', categoria: 'Agua',
    descripcion: 'Agua mineral carbonatada refrescante',
    precioBase: 10,
    imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
  ),

  Bebida(
    id: 'b18', nombre: 'Paceña', categoria: 'Cervezas',
    descripcion: 'Cerveza boliviana clásica, suave y refrescante',
    precioBase: 18, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1608270586620-248524c67de9?w=400&q=80',
  ),
  Bebida(
    id: 'b19', nombre: 'Huari', categoria: 'Cervezas',
    descripcion: 'Cerveza boliviana con cuerpo y sabor intenso',
    precioBase: 18, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400&q=80',
  ),
  Bebida(
    id: 'b20', nombre: 'Sureña', categoria: 'Cervezas',
    descripcion: 'Cerveza rubia ligera, perfecta con pizza',
    precioBase: 15, tieneTamanos: false,
    imageUrl: 'https://images.unsplash.com/photo-1618183479302-1e0aa382c36b?w=400&q=80',
  ),
];
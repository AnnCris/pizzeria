class TamanoPizza {
  final String nombre;
  final String descripcion;
  final double multiplicador;

  const TamanoPizza({
    required this.nombre,
    required this.descripcion,
    required this.multiplicador,
  });
}

const List<TamanoPizza> tamanos = [
  TamanoPizza(nombre: 'Personal', descripcion: '15 cm · 1 porción',   multiplicador: 0.6),
  TamanoPizza(nombre: 'Pequeña',  descripcion: '23 cm · 2 porciones', multiplicador: 0.8),
  TamanoPizza(nombre: 'Mediana',  descripcion: '30 cm · 4 porciones', multiplicador: 1.0),
  TamanoPizza(nombre: 'Grande',   descripcion: '38 cm · 6 porciones', multiplicador: 1.3),
  TamanoPizza(nombre: 'Familiar', descripcion: '45 cm · 8 porciones', multiplicador: 1.6),
];

class Pizza {
  final String id;
  final String nombre;
  final String ingredientes;   // descripción larga para mostrar
  final double precioBase;
  final String imageUrl;
  final String categoria;

  const Pizza({
    required this.id,
    required this.nombre,
    required this.ingredientes,
    required this.precioBase,
    required this.imageUrl,
    required this.categoria,
  });

  double precioConTamano(TamanoPizza t) =>
      (precioBase * t.multiplicador).roundToDouble();
}

const List<Pizza> menuPizzas = [
  // ── Clásicas ─────────────────────────────────────────────────────────────
  Pizza(
    id: 'p01', nombre: 'Margherita', categoria: 'Clásicas',
    ingredientes: 'Salsa de tomate natural, mozzarella fresca, hojas de albahaca y aceite de oliva virgen',
    precioBase: 45,
    imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&q=90',
  ),
  Pizza(
    id: 'p02', nombre: 'Pepperoni', categoria: 'Clásicas',
    ingredientes: 'Salsa de tomate, mozzarella, abundante pepperoni italiano y orégano fresco',
    precioBase: 52,
    imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600&q=90',
  ),
  Pizza(
    id: 'p03', nombre: 'Hawaiana', categoria: 'Clásicas',
    ingredientes: 'Salsa de tomate, mozzarella, jamón ahumado y trozos de piña natural',
    precioBase: 50,
    imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&q=90',
  ),
  Pizza(
    id: 'p04', nombre: 'Napolitana', categoria: 'Clásicas',
    ingredientes: 'Tomate natural, mozzarella, anchoas, aceitunas negras, alcaparras y orégano',
    precioBase: 54,
    imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=90',
  ),
  Pizza(
    id: 'p05', nombre: 'Romana', categoria: 'Clásicas',
    ingredientes: 'Salsa de tomate, mozzarella, salami, cebolla morada y pimiento rojo asado',
    precioBase: 53,
    imageUrl: 'https://images.unsplash.com/photo-1555072956-7758afb20e8f?w=600&q=90',
  ),

  // ── Especiales ────────────────────────────────────────────────────────────
  Pizza(
    id: 'p06', nombre: 'BBQ Pollo', categoria: 'Especiales',
    ingredientes: 'Salsa barbacoa casera, pollo a la parrilla, cebolla caramelizada, mozzarella y cilantro fresco',
    precioBase: 58,
    imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=90',
  ),
  Pizza(
    id: 'p07', nombre: 'Cuatro Quesos', categoria: 'Especiales',
    ingredientes: 'Mozzarella, parmesano, gorgonzola y queso brie sobre base de crema blanca',
    precioBase: 62,
    imageUrl: 'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=600&q=90',
  ),
  Pizza(
    id: 'p08', nombre: 'Diavola', categoria: 'Especiales',
    ingredientes: 'Salsa de tomate picante, salami piccante, jalapeños, aceitunas y mozzarella ahumada',
    precioBase: 57,
    imageUrl: 'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=600&q=90',
  ),
  Pizza(
    id: 'p09', nombre: 'Funghi e Tartufo', categoria: 'Especiales',
    ingredientes: 'Crema de trufa negra, champiñones portobello salteados, rúcula fresca y parmesano laminado',
    precioBase: 65,
    imageUrl: 'https://images.unsplash.com/photo-1506354666786-959d6d497f1a?w=600&q=90',
  ),
  Pizza(
    id: 'p10', nombre: 'Mar y Tierra', categoria: 'Especiales',
    ingredientes: 'Base de ajo y aceite, camarones al ajillo, tocino crujiente, mozzarella y perejil',
    precioBase: 70,
    imageUrl: 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=600&q=90',
  ),
  Pizza(
    id: 'p11', nombre: 'Pollo al Pesto', categoria: 'Especiales',
    ingredientes: 'Pesto de albahaca casero, pollo grillado, tomates cherry, mozzarella y piñones',
    precioBase: 60,
    imageUrl: 'https://images.unsplash.com/photo-1528137871618-79d2761e3fd5?w=600&q=90',
  ),
  Pizza(
    id: 'p12', nombre: 'Tex-Mex', categoria: 'Especiales',
    ingredientes: 'Salsa de tomate picante, carne molida sazonada, maíz, jalapeños, mozzarella y crema agria',
    precioBase: 59,
    imageUrl: 'https://images.unsplash.com/photo-1590947132387-155cc02f3212?w=600&q=90',
  ),
  Pizza(
    id: 'p13', nombre: 'Prosciutto e Rúcula', categoria: 'Especiales',
    ingredientes: 'Base de tomate, mozzarella, prosciutto di Parma, rúcula fresca y virutas de parmesano',
    precioBase: 68,
    imageUrl: 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=600&q=90',
  ),

  // ── Vegana ────────────────────────────────────────────────────────────────
  Pizza(
    id: 'p14', nombre: 'Vegana Mediterránea', categoria: 'Vegana',
    ingredientes: 'Pesto de albahaca, pimiento asado, calabacín, berenjena, tomates cherry y aceitunas kalamata',
    precioBase: 52,
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=90',
  ),
  Pizza(
    id: 'p15', nombre: 'Verde Primavera', categoria: 'Vegana',
    ingredientes: 'Salsa de tomate, espinacas frescas, brócoli, aguacate, cebolla morada y semillas de girasol',
    precioBase: 50,
    imageUrl: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&q=90',
  ),
  Pizza(
    id: 'p16', nombre: 'Hummus y Verduras', categoria: 'Vegana',
    ingredientes: 'Base de hummus casero, tomates cherry, pepino, cebolla morada, menta fresca y limón',
    precioBase: 53,
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=90',
  ),

  // ── Infantil ──────────────────────────────────────────────────────────────
  Pizza(
    id: 'p17', nombre: 'Niños Felices', categoria: 'Infantil',
    ingredientes: 'Salsa de tomate suave, mozzarella extra, pepperoni mini y maíz dulce — ¡sin picante!',
    precioBase: 38,
    imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=90',
  ),
  Pizza(
    id: 'p18', nombre: 'Estrellita', categoria: 'Infantil',
    ingredientes: 'Salsa de tomate, doble mozzarella, jamón dulce y maíz — masa suave y esponjosa',
    precioBase: 36,
    imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&q=90',
  ),

  // ── Premium ───────────────────────────────────────────────────────────────
  Pizza(
    id: 'p19', nombre: 'Trufa Negra Premium', categoria: 'Premium',
    ingredientes: 'Crema de trufa negra, foie gras, champiñones silvestres, mozzarella de búfala y cebollín',
    precioBase: 85,
    imageUrl: 'https://images.unsplash.com/photo-1555072956-7758afb20e8f?w=600&q=90',
  ),
  Pizza(
    id: 'p20', nombre: 'Salmón y Alcaparras', categoria: 'Premium',
    ingredientes: 'Base de crema, salmón ahumado noruego, alcaparras, cebolla morada, eneldo y queso ricotta',
    precioBase: 80,
    imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=90',
  ),
];
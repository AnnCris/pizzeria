import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pizza.dart';
import '../providers/orden_provider.dart';
import '../providers/auth_provider.dart';
import 'ticket_screen.dart';
import 'cocina_screen.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _categoria = 'Todas';
  final _mesaCtrl = TextEditingController();

  final List<String> _categorias = [
    'Todas', 'Clásicas', 'Especiales', 'Vegana', 'Infantil', 'Premium'
  ];

  List<Pizza> get _filtradas => _categoria == 'Todas'
      ? menuPizzas
      : menuPizzas.where((p) => p.categoria == _categoria).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<OrdenProvider>().mesa.isEmpty) _dialMesa();
    });
  }

  void _dialMesa() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('🍕 ', style: TextStyle(fontSize: 24)),
          Text('¿Cuál es tu mesa?', style: TextStyle(fontSize: 18)),
        ]),
        content: TextField(
          controller: _mesaCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.table_restaurant),
            hintText: 'Ej: 3',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_mesaCtrl.text.trim().isNotEmpty) {
                context.read<OrdenProvider>().setMesa('Mesa ${_mesaCtrl.text.trim()}');
                Navigator.pop(context);
              }
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🍕 La Bella Pizzería',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          if (provider.mesa.isNotEmpty)
            Text(provider.mesa,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
        actions: [
          // Carrito
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 26),
              onPressed: provider.carrito.isEmpty
                  ? null
                  : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TicketScreen())),
            ),
            if (provider.carrito.isNotEmpty)
              Positioned(
                right: 6, top: 6,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.yellow[700],
                  child: Text('${provider.carrito.length}',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
          ]),
          // Botón Staff / menú sesión
          if (auth.isLoggedIn)
            PopupMenuButton<String>(
              icon: const Icon(Icons.manage_accounts, color: Colors.white),
              onSelected: (val) {
                if (val == 'cocina') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CocinaScreen()));
                } else if (val == 'cerrar') {
                  auth.logout();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'cocina',
                    child: Row(children: [
                      Icon(Icons.kitchen, color: Colors.red), SizedBox(width: 8),
                      Text('Ver cocina'),
                    ])),
                const PopupMenuItem(value: 'cerrar',
                    child: Row(children: [
                      Icon(Icons.logout, color: Colors.grey), SizedBox(width: 8),
                      Text('Cerrar sesión'),
                    ])),
              ],
            )
          else
            TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                icon: const Icon(Icons.lock_outline, color: Colors.white70, size: 18),
                label: const Text('Personal',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
          const SizedBox(width: 4),
        ],
      ),

      body: Column(children: [
        // ── Banner superior ────────────────────────────────────────────────
        Container(
          color: Colors.red[800],
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: const Row(children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
            SizedBox(width: 6),
            Text('Masa artesanal horneada al leño · Ingredientes frescos cada día',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),

        // ── Filtros de categoría ───────────────────────────────────────────
        Container(
          color: Colors.white,
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: _categorias.map((cat) {
              final sel = cat == _categoria;
              return GestureDetector(
                onTap: () => setState(() => _categoria = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? Colors.red[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? Colors.red[700]! : Colors.grey.shade300),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.grey[700],
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      )),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Grid de pizzas ─────────────────────────────────────────────────
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 320,   // altura FIJA de cada card — cambia este valor si necesitas
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filtradas.length,
            itemBuilder: (_, i) => _PizzaCard(pizza: _filtradas[i]),
          ),
        ),
      ]),

      // ── Barra inferior carrito ─────────────────────────────────────────
      bottomNavigationBar: provider.carrito.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const TicketScreen())),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Ver mi pedido  ·  Bs. ${provider.totalCarrito.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ),
            )
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Card de pizza
// ════════════════════════════════════════════════════════════════════════════

class _PizzaCard extends StatefulWidget {
  final Pizza pizza;
  const _PizzaCard({required this.pizza});
  @override
  State<_PizzaCard> createState() => _PizzaCardState();
}

class _PizzaCardState extends State<_PizzaCard> {
  TamanoPizza _tamano = tamanos[2]; // Mediana por defecto

  String _abrev(String nombre) {
    const map = {
      'Personal': 'Per', 'Pequeña': 'Peq', 'Mediana': 'Med',
      'Grande': 'Gde', 'Familiar': 'Fam',
    };
    return map[nombre] ?? nombre[0];
  }

  Color _categoriaColor(String cat) {
    switch (cat) {
      case 'Clásicas':   return Colors.orange[700]!;
      case 'Especiales': return Colors.red[700]!;
      case 'Vegana':     return Colors.green[700]!;
      case 'Infantil':   return Colors.blue[600]!;
      case 'Premium':    return Colors.purple[700]!;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProvider>();
    final cantidad = provider.cantidadEnCarrito(widget.pizza.id, _tamano.nombre);
    final precio = widget.pizza.precioConTamano(_tamano);

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Imagen completa ──────────────────────────────────────────────
          Stack(children: [
            SizedBox(
              height: 150,          // imagen más alta para que se vea completa
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: widget.pizza.imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (_, _) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: Colors.red[50],
                  child: const Center(child: Text('🍕', style: TextStyle(fontSize: 48))),
                ),
              ),
            ),
            // Badge de categoría
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _categoriaColor(widget.pizza.categoria),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(widget.pizza.categoria,
                    style: const TextStyle(color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),

          // ── Información ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Nombre
                  Text(widget.pizza.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 3),

                  // Ingredientes — 2 líneas completas
                  Text(widget.pizza.ingredientes,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 8),

                  // ── Selector de tamaño ───────────────────────────────────
                  SizedBox(
                    height: 26,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: tamanos.map((t) {
                        final sel = t.nombre == _tamano.nombre;
                        return GestureDetector(
                          onTap: () => setState(() => _tamano = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: sel ? Colors.red[700] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: sel ? Colors.red[700]! : Colors.grey.shade300),
                            ),
                            child: Text(_abrev(t.nombre),
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold,
                                  color: sel ? Colors.white : Colors.grey[700],
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Precio y descripción tamaño en la misma fila
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bs. ${precio.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(_tamano.descripcion,
                          style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                    ],
                  ),

                  const Spacer(),

                  // ── Botón / contador ─────────────────────────────────────
                  cantidad == 0
                      ? SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () =>
                                provider.agregarAlCarrito(widget.pizza, _tamano),
                            child: const Text('Agregar al pedido',
                                style: TextStyle(color: Colors.white, fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        )
                      : Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _Btn(
                                icon: Icons.remove,
                                color: Colors.red[100]!,
                                iconColor: Colors.red[800]!,
                                onTap: () => provider.quitarDelCarrito(
                                    '${widget.pizza.id}_${_tamano.nombre}'),
                              ),
                              Text('$cantidad',
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 16, color: Colors.red[800])),
                              _Btn(
                                icon: Icons.add,
                                color: Colors.red[700]!,
                                iconColor: Colors.white,
                                onTap: () =>
                                    provider.agregarAlCarrito(widget.pizza, _tamano),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color, iconColor;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.color,
      required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      );
}

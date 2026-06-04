import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pizza.dart';
import '../models/bebida.dart';
import '../services/bebida_service.dart';
import '../providers/orden_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mesa_provider.dart';
import 'ticket_screen.dart';
import 'login_screen.dart';
import 'admin/admin_screen.dart';
import 'cocina_screen.dart';
import 'cajero/cajero_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _categoriaPizza  = 'Todas';
  String _categoriaBebida = 'Todas';
  final _mesaCtrl = TextEditingController();

  final List<String> _categoriasPizza = [
    'Todas', 'Clásicas', 'Especiales', 'Vegana', 'Infantil', 'Premium'
  ];
  final List<String> _categoriasBebida = [
    'Todas', 'Gaseosas', 'Jugos', 'Cafés', 'Mates', 'Agua', 'Cervezas'
  ];

  List<Pizza> get _pizzasFiltradas => _categoriaPizza == 'Todas'
      ? menuPizzas
      : menuPizzas
          .where((p) => p.categoria == _categoriaPizza)
          .toList();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<OrdenProvider>().mesa.isEmpty) _dialMesa();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  final _nombreCtrl = TextEditingController();

  void _dialMesa() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('🍕 ', style: TextStyle(fontSize: 24)),
          Expanded(child: Text('Bienvenido',
              style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Ingresa el número de tu mesa y tu nombre'
              ' para que podamos atenderte mejor.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _mesaCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Número de mesa *',
              prefixIcon: const Icon(Icons.table_restaurant),
              hintText: 'Ej: 3',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Tu nombre (opcional)',
              prefixIcon: const Icon(Icons.person_outline),
              hintText: 'Ej: Ana',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final numero = _mesaCtrl.text.trim();
              if (numero.isEmpty) return;
              Navigator.pop(dialogCtx);
              _confirmarMesa(numero, _nombreCtrl.text.trim());
            },
            child: const Text('Confirmar y ver el menú',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarMesa(String numero,
      [String nombre = '']) async {
    final mesaLabel    = 'Mesa $numero';
    final clienteLabel = nombre.isNotEmpty ? nombre : 'Cliente';

    final ordenProv = context.read<OrdenProvider>();
    final mp        = context.read<MesaProvider>();

    ordenProv.setMesa(mesaLabel);
    ordenProv.setClienteNombre(clienteLabel);

    try {
      final numInt = int.parse(numero);
      await mp.marcarOcupadaPorNumero(numInt, clienteLabel);
    } catch (_) {
    }
  }

  Future<void> _irAlLogin() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (!mounted) return;
    final rol = context.read<AuthProvider>().rol;
    if (rol != null) _irAlPanel(context, rol);
  }

  void _irAlPanel(BuildContext ctx, String? rol) {
    final rolActual = context.read<AuthProvider>().rol;
    Widget destino;
    switch (rolActual) {
      case 'admin':
        destino = const AdminScreen();
        break;
      case 'cocina':
        destino = const CocinaScreen();
        break;
      case 'cajero':
        destino = const CajeroScreen();
        break;
      default:
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Rol no reconocido: "$rolActual"'),
          backgroundColor: Colors.red,
        ));
        return;
    }
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => destino));
  }

  String _rolLabel(String? rol) {
    switch (rol) {
      case 'admin':  return '👑 Administrador';
      case 'cocina': return '👨‍🍳 Cocina';
      case 'cajero': return '💰 Cajero';
      default:       return 'Staff';
    }
  }

  IconData _rolIcon(String? rol) {
    switch (rol) {
      case 'admin':  return Icons.admin_panel_settings;
      case 'cocina': return Icons.kitchen;
      case 'cajero': return Icons.point_of_sale;
      default:       return Icons.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProvider>();
    final auth     = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('🍕 La Bella Pizzería',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 18)),
          if (provider.mesa.isNotEmpty)
            Text(provider.mesa,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
        ]),
        actions: [
          // Carrito
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.white, size: 26),
              onPressed: provider.carrito.isEmpty
                  ? null
                  : () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TicketScreen())),
            ),
            if (provider.carrito.isNotEmpty)
              Positioned(
                right: 6, top: 6,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.yellow[700],
                  child: Text('${provider.carrito.length}',
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
              ),
          ]),

          if (!auth.isLoggedIn)
            TextButton.icon(
              onPressed: _irAlLogin,
              icon: const Icon(Icons.lock_outline,
                  color: Colors.white60, size: 16),
              label: const Text('Personal',
                  style: TextStyle(
                      color: Colors.white60, fontSize: 12)),
            )
          else
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (auth.nombre ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(auth.nombre ?? '',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const Icon(Icons.arrow_drop_down,
                      color: Colors.white54, size: 18),
                ]),
              ),
              onSelected: (val) {
                if (val == 'panel') {
                  _irAlPanel(context, auth.rol);
                } else if (val == 'salir') {
                  auth.logout();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(auth.nombre ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(_rolLabel(auth.rol),
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'panel',
                  child: Row(children: [
                    Icon(_rolIcon(auth.rol),
                        color: Colors.red[700], size: 18),
                    const SizedBox(width: 10),
                    const Text('Ir a mi panel'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'salir',
                  child: Row(children: [
                    Icon(Icons.logout, color: Colors.grey, size: 18),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ]),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],

        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.local_pizza, size: 18), text: 'Pizzas'),
            Tab(icon: Icon(Icons.local_drink, size: 18), text: 'Bebidas'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabCtrl,
        children: [
          Column(children: [
            Container(
              color: Colors.red[800],
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: const Row(children: [
                Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Expanded(child: Text(
                    'Masa artesanal horneada al leño · Ingredientes frescos',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11))),
              ]),
            ),
            // Filtros pizza
            _FiltroBar(
              categorias: _categoriasPizza,
              seleccionada: _categoriaPizza,
              color: Colors.red[700]!,
              onCambio: (c) => setState(() => _categoriaPizza = c),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 320,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _pizzasFiltradas.length,
                itemBuilder: (context, i) =>
                    _PizzaCard(pizza: _pizzasFiltradas[i]),
              ),
            ),
          ]),

          Column(children: [
            Container(
              color: Colors.teal[700],
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: const Row(children: [
                Icon(Icons.local_drink, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Expanded(child: Text(
                    'Bebidas frías y calientes · Opciones bolivianas y clásicas',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11))),
              ]),
            ),
            // Filtros bebida
            _FiltroBar(
              categorias: _categoriasBebida,
              seleccionada: _categoriaBebida,
              color: Colors.teal[700]!,
              onCambio: (c) => setState(() => _categoriaBebida = c),
            ),
            // StreamBuilder de bebidas desde Firestore
            Expanded(
              child: StreamBuilder<List<BebidaDB>>(
                stream: BebidaService.stream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(
                        color: Colors.teal));
                  }
                  // Si Firestore falla, usar catálogo local
                  final bebidasDB = snap.data ?? [];
                  final bebidas = bebidasDB.isNotEmpty
                      ? bebidasDB.map((b) => b.toBebida()).toList()
                      : menuBebidas;

                  final filtradas = _categoriaBebida == 'Todas'
                      ? bebidas
                      : bebidas
                          .where((b) => b.categoria == _categoriaBebida)
                          .toList();

                  if (filtradas.isEmpty) {
                    return const Center(child: Text(
                        'Sin bebidas en esta categoría 🥤',
                        style: TextStyle(color: Colors.grey)));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 290,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtradas.length,
                    itemBuilder: (context, i) =>
                        _BebidaCard(bebida: filtradas[i]),
                  );
                },
              ),
            ),
          ]),
        ],
      ),

      // Barra inferior carrito
      bottomNavigationBar: provider.carrito.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TicketScreen())),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Ver mi pedido  ·  Bs. ${provider.totalCarrito.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ),
            )
          : null,
    );
  }
}

class _FiltroBar extends StatelessWidget {
  final List<String> categorias;
  final String seleccionada;
  final Color color;
  final void Function(String) onCambio;
  const _FiltroBar({
    required this.categorias,
    required this.seleccionada,
    required this.color,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          children: categorias.map((cat) {
            final sel = cat == seleccionada;
            return GestureDetector(
              onTap: () => onCambio(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: sel ? color : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? color : Colors.grey.shade300),
                ),
                child: Text(cat,
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.grey[700],
                      fontWeight: sel
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    )),
              ),
            );
          }).toList(),
        ),
      );
}

class _PizzaCard extends StatefulWidget {
  final Pizza pizza;
  const _PizzaCard({required this.pizza});
  @override
  State<_PizzaCard> createState() => _PizzaCardState();
}

class _PizzaCardState extends State<_PizzaCard> {
  TamanoPizza _tamano = tamanos[2];

  String _abrev(String n) => const {
        'Personal': 'Per', 'Pequeña': 'Peq', 'Mediana': 'Med',
        'Grande': 'Gde', 'Familiar': 'Fam',
      }[n] ?? n[0];

  Color _catColor(String cat) {
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
    final cantidad = provider.cantidadEnCarrito(
        widget.pizza.id, _tamano.nombre);
    final precio   = widget.pizza.precioConTamano(_tamano);

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Stack(children: [
          SizedBox(
            height: 150, width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: widget.pizza.imageUrl,
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(
                      color: Colors.red, strokeWidth: 2))),
              errorWidget: (c, u, e) => Container(
                  color: Colors.red[50],
                  child: const Center(child: Text('🍕',
                      style: TextStyle(fontSize: 48)))),
            ),
          ),
          Positioned(top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _catColor(widget.pizza.categoria),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(widget.pizza.categoria,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(widget.pizza.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(widget.pizza.ingredientes,
                  style: TextStyle(fontSize: 10,
                      color: Colors.grey[600], height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: sel ? Colors.red[700] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: sel ? Colors.red[700]!
                                  : Colors.grey.shade300),
                        ),
                        child: Text(_abrev(t.nombre),
                            style: TextStyle(fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white
                                    : Colors.grey[700])),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Text('Bs. ${precio.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.red[800],
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_tamano.descripcion,
                    style: TextStyle(fontSize: 9,
                        color: Colors.grey[500])),
              ]),
              const Spacer(),
              cantidad == 0
                  ? SizedBox(
                      width: double.infinity, height: 34,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => provider.agregarAlCarrito(
                            widget.pizza, _tamano),
                        child: const Text('Agregar al pedido',
                            style: TextStyle(color: Colors.white,
                                fontSize: 12,
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
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                        _Btn(icon: Icons.remove, color: Colors.red[100]!,
                            iconColor: Colors.red[800]!,
                            onTap: () => provider.quitarDelCarrito(
                                '${widget.pizza.id}_${_tamano.nombre}')),
                        Text('$cantidad', style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16,
                            color: Colors.red[800])),
                        _Btn(icon: Icons.add, color: Colors.red[700]!,
                            iconColor: Colors.white,
                            onTap: () => provider.agregarAlCarrito(
                                widget.pizza, _tamano)),
                      ]),
                    ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BebidaCard extends StatefulWidget {
  final Bebida bebida;
  const _BebidaCard({required this.bebida});
  @override
  State<_BebidaCard> createState() => _BebidaCardState();
}

class _BebidaCardState extends State<_BebidaCard> {
  TamanoBebida _tamano = tamanosBebida[1];

  Color _catColor(String cat) {
    switch (cat) {
      case 'Gaseosas':  return Colors.red[600]!;
      case 'Jugos':     return Colors.orange[700]!;
      case 'Cafés':     return Colors.brown[600]!;
      case 'Mates':     return Colors.green[700]!;
      case 'Agua':      return Colors.blue[600]!;
      case 'Cervezas':  return Colors.amber[700]!;
      default:          return Colors.teal[700]!;
    }
  }

  String _abrevTamano(String n) => const {
    'Personal': '250ml',
    'Mediano':  '500ml',
    'Grande':   '1L',
  }[n] ?? n;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenProvider>();
    // Usar mismo provider pero con prefijo 'beb_' para distinguir de pizzas
    final key      = 'beb_${widget.bebida.id}_${_tamano.nombre}';
    final cantidad = provider.cantidadEnCarritoBebida(key);
    final precio   = widget.bebida.precioConTamano(_tamano);

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Stack(children: [
          SizedBox(
            height: 130, width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: widget.bebida.imageUrl,
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(
                  color: Colors.teal[50],
                  child: const Center(child: Text('🥤',
                      style: TextStyle(fontSize: 40)))),
              errorWidget: (c, u, e) => Container(
                  color: Colors.teal[50],
                  child: const Center(child: Text('🥤',
                      style: TextStyle(fontSize: 40)))),
            ),
          ),
          Positioned(top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _catColor(widget.bebida.categoria),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(widget.bebida.categoria,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(widget.bebida.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(widget.bebida.descripcion,
                  style: TextStyle(fontSize: 10,
                      color: Colors.grey[600], height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),

              // Selector tamaño (solo si tieneTamanos)
              if (widget.bebida.tieneTamanos)
                SizedBox(
                  height: 26,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: tamanosBebida.map((t) {
                      final sel = t.nombre == _tamano.nombre;
                      return GestureDetector(
                        onTap: () => setState(() => _tamano = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.teal[700] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: sel ? Colors.teal[700]!
                                    : Colors.grey.shade300),
                          ),
                          child: Text(_abrevTamano(t.nombre),
                              style: TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: sel ? Colors.white
                                      : Colors.grey[700])),
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('Tamaño único',
                        style: TextStyle(fontSize: 10,
                            color: Colors.grey)),
                  ),
                ),

              const SizedBox(height: 4),
              Text('Bs. ${precio.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.teal[700],
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),

              cantidad == 0
                  ? SizedBox(
                      width: double.infinity, height: 34,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => provider
                            .agregarBebidaAlCarrito(
                                widget.bebida, _tamano),
                        child: const Text('Agregar',
                            style: TextStyle(color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  : Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.teal.shade200),
                      ),
                      child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                        _Btn(icon: Icons.remove,
                            color: Colors.teal[100]!,
                            iconColor: Colors.teal[800]!,
                            onTap: () =>
                                provider.quitarDelCarrito(key)),
                        Text('$cantidad', style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16,
                            color: Colors.teal[800])),
                        _Btn(icon: Icons.add,
                            color: Colors.teal[700]!,
                            iconColor: Colors.white,
                            onTap: () => provider
                                .agregarBebidaAlCarrito(
                                    widget.bebida, _tamano)),
                      ]),
                    ),
            ]),
          ),
        ),
      ]),
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
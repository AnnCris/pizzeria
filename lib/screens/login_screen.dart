import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_screen.dart';
import 'cocina_screen.dart';
import 'cajero/cajero_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool   _ocultar  = true;
  bool   _cargando = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }

    setState(() { _cargando = true; _error = null; });

    final error = await context.read<AuthProvider>().login(email, pass);

    if (!mounted) return;

    if (error != null) {
      setState(() { _error = error; _cargando = false; });
      return;
    }

    final rol = context.read<AuthProvider>().rol;
    Widget destino;

    switch (rol) {
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
        destino = const AdminScreen();
    }

    if (!mounted) return;
    Navigator.pop(context);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color(0xFF7B1717), Color(0xFFB03A2E),
              Color(0xFFD4521A), Color(0xFFE8820C),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(children: [

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white70, size: 18),
                      label: const Text('Volver al menú',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: const Center(
                        child: Text('🍕',
                            style: TextStyle(fontSize: 52))),
                  ),
                  const SizedBox(height: 16),
                  const Text('La Bella Pizzería',
                      style: TextStyle(color: Colors.white,
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Acceso para personal',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 13)),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8))],
                    ),
                    child: Column(children: [
                      // Email
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDeco(
                            'Correo electrónico', Icons.email_outlined),
                      ),
                      const SizedBox(height: 14),
                      // Contraseña
                      TextField(
                        controller: _passCtrl,
                        obscureText: _ocultar,
                        onSubmitted: (_) => _login(),
                        decoration: _inputDeco(
                                'Contraseña', Icons.lock_outline)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                                _ocultar
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey),
                            onPressed: () =>
                                setState(() => _ocultar = !_ocultar),
                          ),
                        ),
                      ),
                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.red.shade200),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Botón ingresar
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB03A2E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _cargando ? null : _login,
                          child: _cargando
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Ingresar',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(children: [
                      const Text('👤 Credenciales de prueba',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      _credRow('🔑 Admin',
                          'admin@pizzeria.com', 'admin123'),
                      _credRow('💰 Cajero',
                          'cajero@pizzeria.com', 'cajero123'),
                      _credRow('👨‍🍳 Cocina',
                          'cocina@pizzeria.com', 'cocina123'),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _credRow(String rol, String email, String pass) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(rol, style: const TextStyle(color: Colors.white70,
              fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(email,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const Text('  /  ',
              style: TextStyle(color: Colors.white38)),
          Text(pass,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
      );

  InputDecoration _inputDeco(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFB03A2E))),
      );
}
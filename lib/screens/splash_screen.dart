import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'cocina_screen.dart';
import 'admin/admin_screen.dart';
import 'cajero/cajero_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Mientras Firebase verifica la sesión
    if (auth.cargando) {
      return Scaffold(
        backgroundColor: Colors.red[800],
        body: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🍕', style: TextStyle(fontSize: 72)),
            SizedBox(height: 20),
            Text('La Bella Pizzería',
                style: TextStyle(color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.white),
          ]),
        ),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    switch (auth.rol) {
      case 'admin':
        return const AdminScreen();
      case 'cocina':
        return const CocinaScreen();
      case 'cajero':
        return const CajeroScreen();
      default:
        return const MenuScreen();
    }
  }
}
import 'package:flutter/material.dart';

class NuevaOrdenBanner extends StatefulWidget {
  final bool visible;
  final String mensaje;
  const NuevaOrdenBanner({
    super.key,
    required this.visible,
    this.mensaje = '¡Nueva orden recibida!',
  });

  @override
  State<NuevaOrdenBanner> createState() => _NuevaOrdenBannerState();
}

class _NuevaOrdenBannerState extends State<NuevaOrdenBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    if (widget.visible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(NuevaOrdenBanner old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctrl.forward(from: 0);
      // Ocultar automáticamente después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _ctrl.reverse();
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.yellow[700],
            boxShadow: [
              BoxShadow(color: Colors.yellow.withValues(alpha: 0.5),
                  blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔔', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(widget.mensaje,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
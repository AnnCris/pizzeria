import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin   = FlutterLocalNotificationsPlugin();
  final _player   = AudioPlayer();
  bool  _iniciado = false;

  Future<void> inicializar() async {
    if (_iniciado) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Solicitar permisos en Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _iniciado = true;
  }

  // ── Notificación de nueva orden ──────────────────────────────────────────
  Future<void> nuevaOrden({
    required String ordenId,
    required String mesa,
    required int totalItems,
  }) async {
    await inicializar();

    // Sonido
    await _reproducirSonido();

    // Notificación del sistema
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🍕 ¡Nueva orden!',
      '$mesa · $totalItems producto${totalItems > 1 ? 's' : ''} · #$ordenId',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'nueva_orden',
          'Nuevas Órdenes',
          channelDescription: 'Alertas de nuevas órdenes en cocina',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFC0392B),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Notificación de orden lista para entregar ────────────────────────────
  Future<void> ordenLista({
    required String ordenId,
    required String mesa,
  }) async {
    await inicializar();
    await _reproducirSonido(tipo: 'lista');

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✅ ¡Orden lista!',
      '$mesa · Orden #$ordenId lista para entregar',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'orden_lista',
          'Órdenes Listas',
          channelDescription: 'Alertas cuando una orden está lista',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF2E7D32),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> _reproducirSonido({String tipo = 'nueva'}) async {
    try {
      // Usa un sonido del sistema — no necesita archivo extra
      await _player.play(
        tipo == 'nueva'
            ? AssetSource('sounds/new_order.mp3')
            : AssetSource('sounds/order_ready.mp3'),
      );
    } catch (_) {
      // Si no existe el archivo de sonido, ignora silenciosamente
    }
  }

  void dispose() => _player.dispose();
}
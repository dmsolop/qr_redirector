import 'dart:async';
import 'package:flutter/services.dart';
import 'url_service.dart';
import 'storage_service.dart';

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('qr_redirector/deep_link');
  static StreamSubscription<String>? _linkSubscription;

  static Future<void> initialize() async {
    // Обробка deep links при запуску додатку
    try {
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
    } catch (e) {
      // Помилка отримання початкового deep link
    }

    // Для спрощення не реалізуємо stream - тільки початковий link
  }

  static Future<void> _handleDeepLink(String link) async {
    try {
      // Отримуємо список проєктів
      final projects = await StorageService.getProjects();
      
      // Обробляємо QR код
      final String? finalUrl = await URLService.processQRCode(link, projects);
      
      if (finalUrl != null) {
        await URLService.openUrl(finalUrl);
      }
    } catch (e) {
      // Помилка обробки deep link
    }
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
import 'dart:async';
import 'package:flutter/services.dart';
import 'url_service.dart';
import 'storage_service.dart';
import '../core/errors.dart';

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
      throw DeepLinkError('Не вдалося ініціалізувати deep link сервіс', e.toString());
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
        final success = await URLService.openUrl(finalUrl);
        if (!success) {
          throw DeepLinkError('Не вдалося відкрити URL: $finalUrl');
        }
      } else {
        throw DeepLinkError('Не знайдено відповідний проєкт для QR коду: $link');
      }
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      throw DeepLinkError('Помилка обробки deep link: $link', e.toString());
    }
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
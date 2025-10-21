import 'dart:async';
import 'package:flutter/services.dart';
import 'url_service.dart';
import 'storage_service.dart';
import '../core/errors.dart';

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('qr_redirector/deep_link');
  static StreamSubscription<String>? _linkSubscription;
  static final StreamController<String> _linkController = StreamController<String>.broadcast();

  /// Stream для отримання deep links в реальному часі
  static Stream<String> get linkStream => _linkController.stream;

  static Future<void> initialize() async {
    try {
      // Обробка deep links при запуску додатку
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null) {
        _log('Initial deep link received: $initialLink');
        await _handleDeepLink(initialLink);
      }

      // Налаштовуємо обробку runtime deep links
      _channel.setMethodCallHandler(_handleMethodCall);

      _log('Deep link service initialized successfully');
    } catch (e) {
      _log('Error initializing deep link service: $e');
      throw DeepLinkError('Не вдалося ініціалізувати deep link сервіс', e.toString());
    }
  }

  /// Обробляє виклики методів з нативного коду
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLink':
        final String link = call.arguments as String;
        _log('Runtime deep link received: $link');
        _linkController.add(link);
        await _handleDeepLink(link);
        break;
      default:
        _log('Unknown method call: ${call.method}');
    }
  }

  static Future<void> _handleDeepLink(String link) async {
    try {
      _log('Processing deep link: $link');

      // Отримуємо список проєктів
      final projects = await StorageService.getProjects();
      _log('Loaded ${projects.length} projects');

      // Обробляємо QR код
      final String? finalUrl = await URLService.processQRCode(link, projects);

      if (finalUrl != null) {
        _log('Found matching project, final URL: $finalUrl');
        final success = await URLService.openUrl(finalUrl);
        if (!success) {
          _log('Failed to open URL: $finalUrl');
          throw DeepLinkError('Не вдалося відкрити URL: $finalUrl');
        }
        _log('Successfully opened URL: $finalUrl');
      } else {
        _log('No matching project found for QR code: $link');
        throw DeepLinkError('Не знайдено відповідний проєкт для QR коду: $link');
      }
    } catch (e) {
      _log('Error processing deep link: $e');
      if (e is AppError) {
        rethrow;
      }
      throw DeepLinkError('Помилка обробки deep link: $link', e.toString());
    }
  }

  /// Логування для debugging
  static void _log(String message) {
    // В production можна замінити на proper logging
    // ignore: avoid_print
    print('[DeepLinkService] ${DateTime.now().toIso8601String()} - $message');
  }

  static void dispose() {
    _linkSubscription?.cancel();
    _linkController.close();
    _log('Deep link service disposed');
  }
}

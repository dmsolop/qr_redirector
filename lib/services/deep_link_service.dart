import 'dart:async';
import 'package:flutter/services.dart';
import 'url_service.dart';
import 'storage_service.dart';
import '../core/errors.dart';

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('qr_redirector/deep_link');
  static StreamSubscription<String>? _linkSubscription;
  static final StreamController<String> _linkController = StreamController<String>.broadcast();
  static String? _lastProcessedLink; // Зберігаємо останній оброблений deep link

  /// Stream для отримання deep links в реальному часі
  static Stream<String> get linkStream => _linkController.stream;

  static Future<void> initialize() async {
    try {
      _log('Starting deep link service initialization...');

      // Обробка deep links при запуску додатку
      _log('Calling getInitialLink...');
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      _log('getInitialLink result: $initialLink');

      if (initialLink != null) {
        _log('Initial deep link received: $initialLink');
        await _handleDeepLink(initialLink);
      }

      // Налаштовуємо обробку runtime deep links
      _log('Setting method call handler...');
      _channel.setMethodCallHandler(_handleMethodCall);

      _log('Deep link service initialized successfully');
    } catch (e) {
      _log('Error initializing deep link service: $e');
      _log('Error type: ${e.runtimeType}');
      if (e is PlatformException) {
        _log('PlatformException details: code=${e.code}, message=${e.message}');
      }
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

      // Перевіряємо чи це той самий deep link що вже оброблявся
      if (_lastProcessedLink == link) {
        _log('Skipping duplicate deep link: $link');
        return;
      }

      // Отримуємо список проєктів
      final projects = await StorageService.getProjects();
      _log('Loaded ${projects.length} projects');

      // Логуємо деталі проєктів для debugging
      for (int i = 0; i < projects.length; i++) {
        _log('Project $i: name="${projects[i].name}", regex="${projects[i].regex}", url="${projects[i].urlTemplate}"');
      }

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
        // Зберігаємо оброблений deep link щоб не обробляти його повторно
        _lastProcessedLink = link;
        // Очищаємо deep link в MainActivity щоб не обробляти його повторно
        await _channel.invokeMethod('clearLastProcessedLink');
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

  /// Очищає збережений deep link щоб можна було відсканувати той самий код знову
  static void clearLastProcessedLink() {
    _lastProcessedLink = null;
    _log('Cleared last processed deep link');
  }

  static void dispose() {
    _linkSubscription?.cancel();
    _linkController.close();
    _lastProcessedLink = null; // Скидаємо збережений deep link
    _log('Deep link service disposed');
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'services/deep_link_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/settings_screen.dart';
import 'core/errors.dart';

// Глобальний ключ для навігатора (для показу алєртів з сервісів)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const QRRedirectorApp());
}

class QRRedirectorApp extends StatelessWidget {
  const QRRedirectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Редіректор',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _showSettings = false;
  bool _hasProjects = false;
  StreamSubscription<String>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Спочатку перевіряємо, чи є налаштовані проєкти
    final projects = await StorageService.getProjects();
    final hasProjects = projects.isNotEmpty;

    try {
      // Встановлюємо глобальний ключ навігатора для показу алєртів
      DeepLinkService.setNavigatorKey(navigatorKey);
      await DeepLinkService.initialize();

      // Підписуємося на runtime deep links
      _deepLinkSubscription = DeepLinkService.linkStream.listen(
        (link) {
          // Deep links автоматично обробляються в DeepLinkService
          // ignore: avoid_print
          print('[App] Deep link processed: $link');
        },
        onError: (error) {
          // ignore: avoid_print
          print('[App] Deep link error: $error');
        },
      );

      setState(() {
        _isInitialized = true;
        _hasProjects = hasProjects;
        // Завжди показуємо головний екран з кнопкою "Налаштування"
        _showSettings = false;
      });
    } catch (e) {
      // Логуємо детальну помилку
      // ignore: avoid_print
      print('[App] Initialization error: $e');
      if (e is AppError) {
        // ignore: avoid_print
        print('[App] AppError details: ${e.message}');
      }

      // Показуємо конкретну помилку користувачу
      if (mounted) {
        _showErrorDialog(context, e);
      }
      setState(() {
        _isInitialized = true;
        _hasProjects = hasProjects; // Використовуємо завантажені проєкти
        _showSettings = false;
      });
    }
  }

  Future<void> _openSettings() async {
    // Спочатку завжди запитуємо пароль телефона для верифікації власника
    // ignore: avoid_print
    print('[App] Starting device credentials verification...');

    final deviceVerified = await AuthService.verifyDeviceCredentials();

    // ignore: avoid_print
    print('[App] Device verification result: $deviceVerified');

    if (!deviceVerified) {
      if (mounted) {
        // Показуємо більш детальне повідомлення
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Верифікація не пройшла. Перевірте налаштування біометрії/блокування екрану.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Після успішної верифікації пристрою одразу показуємо налаштування
    if (mounted) {
      setState(() {
        _showSettings = true;
      });
    }
  }

  /// Показує діалог з конкретною помилкою
  void _showErrorDialog(BuildContext context, dynamic error) {
    print('[App] Showing error dialog for: $error');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Проєкт не знайдено'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QR код не відповідає жодному з налаштованих проєктів',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Text(
                'Можливі причини:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text('• Неправильний regex в налаштуваннях проєктів'),
              Text('• QR код не відповідає жодному шаблону'),
              Text('• Відсутні групи захоплення в regex'),
              Text('• Regex знаходить кілька співпадінь'),
              const SizedBox(height: 16),
              Text(
                'Рекомендації для вирішення:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text('• Перевірте правильність regex в налаштуваннях'),
              Text('• Переконайтеся що regex має групи захоплення'),
              Text('• Перевірте що regex дає рівно одне співпадіння'),
              Text('• Зверніться до адміністратора системи'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Зрозуміло'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _openSettings();
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Налаштування'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Ініціалізація...'),
            ],
          ),
        ),
      );
    }

    // Якщо не показуємо налаштування, показуємо головний екран
    if (!_showSettings) {
      // Якщо є проєкти, показуємо покращений стартовий екран
      if (_hasProjects) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),
                  // Головна іконка та заголовок
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 48,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'QR Редіректор',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Система працює у фоні',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Статус проєктів
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Проєкти налаштовані та готові до роботи',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Кнопка налаштувань
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings, size: 20),
                      label: const Text(
                        'Налаштування',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Додаткова інформація
                  Text(
                    'Для доступу до налаштувань потрібна авторизація',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Якщо немає проєктів, показуємо покращений екран налаштувань
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                // Головна іконка та заголовок
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'QR Редіректор',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Налаштуйте перший проєкт',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Інформаційний блок
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Спочатку потрібно налаштувати проєкти для роботи з QR-кодами',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Кнопка налаштувань
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings, size: 20),
                    label: const Text(
                      'Налаштування',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Додаткова інформація
                Text(
                  'Для доступу до налаштувань потрібна авторизація',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Показуємо налаштування
    return SettingsScreen(
      onBack: () async {
        // Перевіряємо, чи є проєкти після повернення з налаштувань
        final projects = await StorageService.getProjects();
        final hasProjects = projects.isNotEmpty;

        setState(() {
          _hasProjects = hasProjects;
          _showSettings = false;
        });
      },
    );
  }
}

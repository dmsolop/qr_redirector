import 'dart:async';
import 'package:flutter/material.dart';
import 'services/deep_link_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/settings_screen.dart';
import 'core/errors.dart';

void main() {
  runApp(const QRRedirectorApp());
}

class QRRedirectorApp extends StatelessWidget {
  const QRRedirectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Редіректор',
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
    try {
      await DeepLinkService.initialize();

      // Перевіряємо, чи є налаштовані проєкти
      final projects = await StorageService.getProjects();
      final hasProjects = projects.isNotEmpty;

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

      // Показуємо помилку користувачу, але все одно запускаємо додаток
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка ініціалізації: ${e is AppError ? e.message : e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isInitialized = true;
        _hasProjects = false;
        // При помилці також показуємо головний екран
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
      // Якщо є проєкти, показуємо мінімальний екран
      if (_hasProjects) {
        return Scaffold(
          backgroundColor: Colors.green.shade50,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 32,
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  'QR Редіректор',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Працює у фоні',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _openSettings,
                  icon: Icon(Icons.settings, size: 16, color: Colors.green.shade700),
                  label: Text(
                    'Налаштування',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Якщо немає проєктів, показуємо повний екран налаштувань
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'QR Редіректор',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Налаштуйте перший проєкт',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Налаштування'),
              ),
            ],
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

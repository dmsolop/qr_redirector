import 'dart:async';
import 'package:flutter/material.dart';
import 'services/deep_link_service.dart';
import 'services/auth_service.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';
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
  StreamSubscription<String>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await DeepLinkService.initialize();

      // Підписуємося на runtime deep links
      _deepLinkSubscription = DeepLinkService.linkStream.listen(
        (link) {
          // Deep links автоматично обробляються в DeepLinkService
          // У background режимі не показуємо UI повідомлення
          // ignore: avoid_print
          print('[App] Deep link processed in background: $link');
        },
        onError: (error) {
          // Логуємо помилки, але не показуємо UI у background режимі
          // ignore: avoid_print
          print('[App] Deep link error: $error');
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
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
      });
    }
  }

  Future<void> _openSettings() async {
    // Перевіряємо, чи налаштована автентифікація
    final authEnabled = await AuthService.isAuthEnabled();
    
    if (authEnabled) {
      // Якщо автентифікація налаштована, показуємо екран автентифікації
      final authenticated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      
      if (authenticated == true) {
        setState(() {
          _showSettings = true;
        });
      }
    } else {
      // Якщо автентифікація не налаштована, показуємо екран налаштування автентифікації
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      
      if (result == true) {
        setState(() {
          _showSettings = true;
        });
      }
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

    // Якщо не показуємо налаштування, показуємо background екран
    if (!_showSettings) {
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
                'Додаток працює у фоні',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
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
      onBack: () {
        setState(() {
          _showSettings = false;
        });
      },
    );
  }
}

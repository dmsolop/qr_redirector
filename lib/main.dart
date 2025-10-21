import 'dart:async';
import 'package:flutter/material.dart';
import 'services/deep_link_service.dart';
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
          // Тут можна додати додаткову логіку, якщо потрібно
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Оброблено deep link: $link'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Помилка обробки deep link: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
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

    return const SettingsScreen();
  }
}

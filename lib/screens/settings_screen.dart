import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../services/ui_mode_service.dart';
import '../services/navigation_observer.dart';
import 'package:flutter/widgets.dart';
import '../services/storage_service.dart';
import 'project_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SettingsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RouteAware {
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    UiModeService.setRouteMode(UiMode.foregroundAuto);
    _loadProjects();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() {
    UiModeService.setRouteMode(UiMode.foregroundAuto);
  }

  @override
  void didPopNext() {
    UiModeService.setRouteMode(UiMode.foregroundAuto);
  }

  @override
  void didPushNext() {
    // Залишаємо true, поки налаштування видимі; якщо зверху інший екран — значення не змінюємо.
  }

  @override
  void didPop() {
    // Route popped; no explicit change needed here.
  }

  Future<void> _loadProjects() async {
    final projects = await StorageService.getProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _navigateToProjects() async {
    // Налаштування проєктів доступні після верифікації пристрою
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectListScreen(
          onProjectsChanged: _loadProjects,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Налаштування проєктів'),
                      subtitle: Text('${_projects.length} проєктів'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _navigateToProjects,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_fill),
                      title: const Text('Перейти у фон'),
                      subtitle: const Text('Сервіс активується, UI згорнеться'),
                      onTap: () async {
                        try {
                          print('[Settings] Starting background mode...');
                          await StorageService.setForegroundServiceEnabled(true);
                          const channel = MethodChannel('qr_redirector/deep_link');
                          await channel.invokeMethod('startForegroundService');
                          print('[Settings] Background service started');
                          await channel.invokeMethod('moveTaskToBack');
                          print('[Settings] App moved to background');
                        } catch (e) {
                          print('[Settings] Failed to start background: $e');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.power_settings_new, color: Colors.red),
                      title: const Text('Повністю закрити застосунок (Android)'),
                      subtitle: const Text('Зупинити фоновий сервіс і завершити роботу'),
                      onTap: () async {
                        try {
                          await StorageService.setForegroundServiceEnabled(false);
                          const channel = MethodChannel('qr_redirector/deep_link');
                          await channel.invokeMethod('exitApp');
                        } catch (e) {
                          print('[Settings] Failed to exit app: $e');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Про додаток'),
                      subtitle: const Text('Версія 1.0.0'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('QR Редіректор'),
                            content: const Text(
                              'Простий додаток для редірекції QR кодів.\n\n'
                              'Скануйте QR коди з схемою reich:// і автоматично '
                              'відкривайте потрібні URL.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

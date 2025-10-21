import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import 'project_list_screen.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const SettingsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await StorageService.getProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _navigateToProjects() async {
    // Налаштування проєктів доступні без додаткової автентифікації
    // (автентифікація вже пройшла при відкритті налаштувань)
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
                      leading: const Icon(Icons.security),
                      title: const Text('Аутентифікація'),
                      subtitle: const Text('Налаштування безпеки'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                        );
                        
                        if (result == true) {
                          // Оновлюємо інформацію про проєкти після зміни налаштувань
                          _loadProjects();
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

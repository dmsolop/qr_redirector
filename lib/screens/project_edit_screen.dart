import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/url_service.dart';
import '../core/errors.dart';
import '../services/ui_mode_service.dart';
import '../services/navigation_observer.dart';
import 'package:flutter/widgets.dart';

class ProjectEditScreen extends StatefulWidget {
  final Project project;

  const ProjectEditScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> with RouteAware {
  late TextEditingController _nameController;
  late TextEditingController _regexController;
  late TextEditingController _urlController;
  late TextEditingController _testController;

  String? _testResult;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    UiModeService.setRouteMode(UiMode.foregroundDisabled);
    _nameController = TextEditingController(text: widget.project.name);
    _regexController = TextEditingController(text: widget.project.regex);
    _urlController = TextEditingController(text: widget.project.urlTemplate);
    _testController = TextEditingController();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _nameController.dispose();
    _regexController.dispose();
    _urlController.dispose();
    _testController.dispose();
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
    UiModeService.setRouteMode(UiMode.foregroundDisabled);
  }

  @override
  void didPopNext() {
    UiModeService.setRouteMode(UiMode.foregroundDisabled);
  }

  @override
  void didPop() {
    // Route popped; returning to previous route's mode
  }

  Future<void> _testProject() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      // Валідуємо regex
      final regexError = URLService.validateRegex(_regexController.text);
      if (regexError != null) {
        throw regexError;
      }

      // Валідуємо URL шаблон
      final urlError = URLService.validateUrlTemplate(_urlController.text);
      if (urlError != null) {
        throw urlError;
      }

      final testProject = Project(
        id: widget.project.id,
        name: _nameController.text,
        regex: _regexController.text,
        urlTemplate: _urlController.text,
      );

      final result = await URLService.testProject(testProject, _testController.text);

      setState(() {
        _testResult = result;
        _isTesting = false;
      });

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regex не співпадає з тестовим значенням')),
        );
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
      });

      String errorMessage = 'Помилка тестування';
      if (e is ValidationError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Помилка тестування: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _saveProject() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву проєкту')),
      );
      return;
    }

    // Валідуємо regex
    final regexError = URLService.validateRegex(_regexController.text);
    if (regexError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(regexError.message)),
      );
      return;
    }

    // Валідуємо URL шаблон
    final urlError = URLService.validateUrlTemplate(_urlController.text);
    if (urlError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(urlError.message)),
      );
      return;
    }

    final updatedProject = Project(
      id: widget.project.id,
      name: _nameController.text,
      regex: _regexController.text,
      urlTemplate: _urlController.text,
    );

    Navigator.pop(context, updatedProject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.project.id == 0 ? 'Новий проєкт' : 'Редагування проєкту'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveProject,
            child: const Text('Зберегти'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Назва проєкту',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _regexController,
              decoration: const InputDecoration(
                labelText: 'Regex',
                hintText: '^reich://1(\\d+)\$',
                border: OutlineInputBorder(),
                helperText: 'Регулярний вираз для визначення проєкту',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL шаблон',
                hintText: 'example.com/project/{key}',
                border: OutlineInputBorder(),
                helperText: 'Використовуйте {key} для підстановки',
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Тестування',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testController,
              decoration: const InputDecoration(
                labelText: 'Deep link для тестування',
                hintText: 'reich://1234',
                border: OutlineInputBorder(),
                helperText: 'Введіть deep link для перевірки regex правила',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTesting ? null : _testProject,
              child: _isTesting
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Тестування...'),
                      ],
                    )
                  : const Text('Тестувати'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Результат:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_testResult!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

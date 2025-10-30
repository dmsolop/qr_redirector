import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import 'project_edit_screen.dart';
import '../services/ui_mode_service.dart';
import '../services/navigation_observer.dart';
import 'package:flutter/widgets.dart';

class ProjectListScreen extends StatefulWidget {
  final VoidCallback onProjectsChanged;

  const ProjectListScreen({
    Key? key,
    required this.onProjectsChanged,
  }) : super(key: key);

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> with RouteAware {
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

  Future<void> _loadProjects() async {
    final projects = await StorageService.getProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _addProject() async {
    final nextId = await StorageService.getNextProjectId();
    final newProject = Project(
      id: nextId,
      name: 'Проєкт $nextId',
      regex: '',
      urlTemplate: '',
    );

    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectEditScreen(project: newProject),
      ),
    );

    if (result != null) {
      await StorageService.addProject(result);
      _loadProjects();
      widget.onProjectsChanged();
    }
  }

  Future<void> _editProject(Project project) async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectEditScreen(project: project),
      ),
    );

    if (result != null) {
      await StorageService.updateProject(result);
      _loadProjects();
      widget.onProjectsChanged();
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити проєкт'),
        content: Text('Ви впевнені, що хочете видалити "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteProject(project.id);
      _loadProjects();
      widget.onProjectsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проєкти'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Немає проєктів',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Натисніть + щоб додати перший проєкт',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(project.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Regex: ${project.regex}'),
                            Text('URL: ${project.urlTemplate}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Редагувати'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Видалити', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editProject(project);
                                break;
                              case 'delete':
                                _deleteProject(project);
                                break;
                            }
                          },
                        ),
                        onTap: () => _editProject(project),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}

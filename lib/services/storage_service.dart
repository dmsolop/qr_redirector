import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../core/errors.dart';

class StorageService {
  static const String _projectsKey = 'projects';
  static const String _nextIdKey = 'next_project_id';
  static const String _fgServiceEnabledKey = 'foreground_service_enabled';

  static Future<List<Project>> getProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getStringList(_projectsKey) ?? [];

      return projectsJson.map((json) => Project.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      throw StorageError('Не вдалося завантажити проєкти', e.toString());
    }
  }

  static Future<void> saveProjects(List<Project> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = projects.map((project) => jsonEncode(project.toJson())).toList();

      await prefs.setStringList(_projectsKey, projectsJson);
      // Дублюємо список проєктів у вигляді одного JSON-рядка для нативного Android сервісу.
      // Ключ буде збережений у SharedPreferences як 'flutter.native_projects_json'.
      // Важливо: для нативного сервісу потрібно правильно екранувати regex
      final nativeProjects = projects.map((p) => {
        'id': p.id,
        'name': p.name,
        'regex': p.regex, // Regex залишається як є для нативного коду
        'urlTemplate': p.urlTemplate,
      }).toList();
      final nativeProjectsJson = jsonEncode(nativeProjects);
      await prefs.setString('native_projects_json', nativeProjectsJson);
    } catch (e) {
      throw StorageError('Не вдалося зберегти проєкти', e.toString());
    }
  }

  static Future<void> addProject(Project project) async {
    try {
      final projects = await getProjects();
      projects.add(project);
      await saveProjects(projects);
    } catch (e) {
      if (e is StorageError) {
        rethrow;
      }
      throw StorageError('Не вдалося додати проєкт', e.toString());
    }
  }

  static Future<void> updateProject(Project project) async {
    try {
      final projects = await getProjects();
      final index = projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        projects[index] = project;
        await saveProjects(projects);
      } else {
        throw StorageError('Проєкт з ID ${project.id} не знайдено');
      }
    } catch (e) {
      if (e is StorageError) {
        rethrow;
      }
      throw StorageError('Не вдалося оновити проєкт', e.toString());
    }
  }

  static Future<void> deleteProject(int projectId) async {
    try {
      final projects = await getProjects();
      final initialLength = projects.length;
      projects.removeWhere((p) => p.id == projectId);

      if (projects.length == initialLength) {
        throw StorageError('Проєкт з ID $projectId не знайдено');
      }

      await saveProjects(projects);
    } catch (e) {
      if (e is StorageError) {
        rethrow;
      }
      throw StorageError('Не вдалося видалити проєкт', e.toString());
    }
  }

  static Future<int> getNextProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }

  static Future<void> resetNextProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nextIdKey);
  }

  static Future<bool> getForegroundServiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fgServiceEnabledKey) ?? false;
  }

  static Future<void> setForegroundServiceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fgServiceEnabledKey, enabled);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class StorageService {
  static const String _projectsKey = 'projects';
  static const String _nextIdKey = 'next_project_id';

  static Future<List<Project>> getProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = prefs.getStringList(_projectsKey) ?? [];
    
    return projectsJson
        .map((json) => Project.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = projects
        .map((project) => jsonEncode(project.toJson()))
        .toList();
    
    await prefs.setStringList(_projectsKey, projectsJson);
  }

  static Future<void> addProject(Project project) async {
    final projects = await getProjects();
    projects.add(project);
    await saveProjects(projects);
  }

  static Future<void> updateProject(Project project) async {
    final projects = await getProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      await saveProjects(projects);
    }
  }

  static Future<void> deleteProject(int projectId) async {
    final projects = await getProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
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
}

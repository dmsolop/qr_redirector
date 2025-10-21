import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';

class URLService {
  static Future<String?> processQRCode(String qrData, List<Project> projects) async {
    // Перебираємо всі проєкти
    for (Project project in projects) {
      try {
        RegExp regex = RegExp(project.regex);
        Match? match = regex.firstMatch(qrData);
        
        if (match != null) {
          // Знайшли відповідний проєкт
          String key = match.group(1)!; // Перша група = ключ
          String finalUrl = project.urlTemplate.replaceAll('{key}', key);
          return finalUrl;
        }
      } catch (e) {
        // Якщо regex некоректний, пропускаємо цей проєкт
        continue;
      }
    }
    
    return null; // Не знайшли відповідний проєкт
  }

  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  static Future<String?> testProject(Project project, String testQrData) async {
    try {
      RegExp regex = RegExp(project.regex);
      Match? match = regex.firstMatch(testQrData);
      
      if (match != null) {
        String key = match.group(1)!;
        return project.urlTemplate.replaceAll('{key}', key);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

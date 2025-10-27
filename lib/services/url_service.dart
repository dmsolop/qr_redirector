import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';
import '../core/errors.dart';
import 'regex_matching_service.dart';

class URLService {
  /// Валідує regex патерн
  static ValidationError? validateRegex(String regex) {
    if (regex.isEmpty) {
      return const ValidationError('Regex не може бути порожнім');
    }

    try {
      RegExp(regex);
      return null; // Regex валідний
    } catch (e) {
      return ValidationError('Неправильний regex патерн', e.toString());
    }
  }

  /// Валідує URL шаблон
  static ValidationError? validateUrlTemplate(String urlTemplate) {
    if (urlTemplate.isEmpty) {
      return const ValidationError('URL шаблон не може бути порожнім');
    }

    if (!urlTemplate.contains('{key}')) {
      return const ValidationError('URL шаблон повинен містити {key}');
    }

    // Перевіряємо, чи можна створити URI з шаблону
    try {
      final testUrl = urlTemplate.replaceAll('{key}', 'test');
      Uri.parse(testUrl);
      return null;
    } catch (e) {
      return ValidationError('Неправильний URL шаблон', e.toString());
    }
  }

  static Future<String?> processQRCode(String qrData, List<Project> projects) async {
    // Використовуємо новий сервіс для пошуку найкращого співпадіння
    final matchResult = RegexMatchingService.findBestMatch(qrData, projects);

    if (matchResult != null) {
      return matchResult.finalUrl;
    }

    return null; // Не знайшли відповідний проєкт
  }

  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      throw UrlError('Не вдалося відкрити URL: $url', e.toString());
    }
  }

  static Future<String?> testProject(Project project, String testQrData) async {
    try {
      // Спочатку валідуємо regex
      final regexError = validateRegex(project.regex);
      if (regexError != null) {
        throw regexError;
      }

      // Валідуємо URL шаблон
      final urlError = validateUrlTemplate(project.urlTemplate);
      if (urlError != null) {
        throw urlError;
      }

      RegExp regex = RegExp(project.regex);
      Match? match = regex.firstMatch(testQrData);

      if (match != null) {
        String key = match.group(match.groupCount)!; // Остання група = ключ
        return project.urlTemplate.replaceAll('{key}', key);
      }
      return null;
    } catch (e) {
      if (e is ValidationError) {
        rethrow;
      }
      throw ValidationError('Помилка тестування проєкту', e.toString());
    }
  }
}

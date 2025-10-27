import 'dart:developer' as developer;
import '../models/project.dart';

/// Результат пошуку найкращого співпадіння
class MatchResult {
  final Project project;
  final String matchedKey;
  final String finalUrl;
  final int matchLength;
  final int groupCount;
  final bool isFullMatch;

  MatchResult({
    required this.project,
    required this.matchedKey,
    required this.finalUrl,
    required this.matchLength,
    required this.groupCount,
    required this.isFullMatch,
  });

  @override
  String toString() {
    return 'MatchResult(project: ${project.name}, key: $matchedKey, url: $finalUrl, length: $matchLength, groups: $groupCount, fullMatch: $isFullMatch)';
  }
}

/// Сервіс для пошуку найкращого співпадіння regex з deeplink
class RegexMatchingService {
  /// Знаходить найкраще співпадіння серед всіх проєктів
  ///
  /// Критерії вибору найкращого співпадіння:
  /// 1. Повне співпадіння (start == 0 && end == input.length)
  /// 2. Більше груп захоплення (groupCount)
  /// 3. Довше співпадіння (matchLength)
  /// 4. Перший в списку проєктів
  static MatchResult? findBestMatch(String deepLink, List<Project> projects) {
    developer.log('[RegexMatching] Пошук найкращого співпадіння для: $deepLink');
    developer.log('[RegexMatching] Кількість проєктів: ${projects.length}');

    final validMatches = <MatchResult>[];

    for (final project in projects) {
      try {
        final regex = RegExp(project.regex);

        // Використовуємо allMatches для перевірки кількості співпадінь
        final allMatches = regex.allMatches(deepLink).toList();

        developer.log('[RegexMatching] Проєкт "${project.name}": regex="${project.regex}", співпадінь=${allMatches.length}');

        // Критерій 1: має бути рівно одне співпадіння
        if (allMatches.length != 1) {
          developer.log('[RegexMatching] Проєкт "${project.name}" пропущено: ${allMatches.length} співпадінь (має бути 1)');
          continue;
        }

        final match = allMatches.first;
        final groups = <String>[];
        for (int i = 0; i <= match.groupCount; i++) {
          groups.add(match.group(i) ?? '');
        }

        // Критерій 2: має бути хоча б одна група захоплення
        if (groups.length < 2) {
          developer.log('[RegexMatching] Проєкт "${project.name}" пропущено: немає груп захоплення');
          continue;
        }

        // Беремо останню групу як ключ (як в поточній логіці)
        final key = groups.last;
        final finalUrl = project.urlTemplate.replaceAll('{key}', key);

        // Визначаємо чи це повне співпадіння
        final isFullMatch = match.start == 0 && match.end == deepLink.length;
        final matchLength = match.end - match.start;
        final groupCount = groups.length - 1; // Виключаємо повне співпадіння

        final matchResult = MatchResult(
          project: project,
          matchedKey: key,
          finalUrl: finalUrl,
          matchLength: matchLength,
          groupCount: groupCount,
          isFullMatch: isFullMatch,
        );

        validMatches.add(matchResult);
        developer.log('[RegexMatching] Проєкт "${project.name}" додано: key="$key", length=$matchLength, groups=$groupCount, fullMatch=$isFullMatch');
      } catch (e) {
        developer.log('[RegexMatching] Помилка regex в проєкті "${project.name}": $e');
        continue;
      }
    }

    if (validMatches.isEmpty) {
      developer.log('[RegexMatching] Не знайдено жодного валідного співпадіння');
      return null;
    }

    // Сортування за критеріями пріоритету:
    // 1. Повне співпадіння (isFullMatch = true)
    // 2. Більше груп захоплення (groupCount)
    // 3. Довше співпадіння (matchLength)
    // 4. Порядок в списку проєктів (перший має пріоритет)
    validMatches.sort((a, b) {
      // Спочатку за повним співпадінням (спадаюче)
      final fullMatchComparison = (b.isFullMatch ? 1 : 0).compareTo(a.isFullMatch ? 1 : 0);
      if (fullMatchComparison != 0) return fullMatchComparison;

      // Потім за кількістю груп (спадаюче)
      final groupComparison = b.groupCount.compareTo(a.groupCount);
      if (groupComparison != 0) return groupComparison;

      // Потім за довжиною співпадіння (спадаюче)
      final lengthComparison = b.matchLength.compareTo(a.matchLength);
      if (lengthComparison != 0) return lengthComparison;

      // Нарешті за порядком в списку (зростаюче)
      return projects.indexOf(a.project).compareTo(projects.indexOf(b.project));
    });

    final bestMatch = validMatches.first;
    developer.log('[RegexMatching] Найкраще співпадіння: ${bestMatch.project.name}');
    developer.log('[RegexMatching] Деталі: key="${bestMatch.matchedKey}", url="${bestMatch.finalUrl}"');

    return bestMatch;
  }

  /// Перевіряє чи regex дає рівно одне співпадіння
  static bool isValidRegex(String regexPattern, String testString) {
    try {
      final regex = RegExp(regexPattern);
      final matches = regex.allMatches(testString).toList();
      return matches.length == 1;
    } catch (e) {
      return false;
    }
  }

  /// Тестує regex на валідність та повертає детальну інформацію
  static Map<String, dynamic> testRegex(String regexPattern, String testString) {
    try {
      final regex = RegExp(regexPattern);
      final matches = regex.allMatches(testString).toList();

      if (matches.isEmpty) {
        return {
          'isValid': false,
          'matchCount': 0,
          'hasGroups': false,
          'groups': [],
          'isFullMatch': false,
          'matchLength': 0,
          'error': null,
        };
      }

      final match = matches.first;
      final groups = <String>[];
      for (int i = 0; i <= match.groupCount; i++) {
        groups.add(match.group(i) ?? '');
      }
      final isFullMatch = match.start == 0 && match.end == testString.length;
      final matchLength = match.end - match.start;

      return {
        'isValid': matches.length == 1 && groups.length >= 2,
        'matchCount': matches.length,
        'hasGroups': groups.length >= 2,
        'groups': groups,
        'isFullMatch': isFullMatch,
        'matchLength': matchLength,
        'error': null,
      };
    } catch (e) {
      return {
        'isValid': false,
        'matchCount': 0,
        'hasGroups': false,
        'groups': [],
        'isFullMatch': false,
        'matchLength': 0,
        'error': e.toString(),
      };
    }
  }
}

/// Тексти для різних типів алєртів в застосунку
class AlertMessages {
  // Невалідний QR код / deeplink
  static const String invalidDeeplinkTitle = 'Невалідний QR код';
  static const String invalidDeeplinkMessage = 'QR код не відповідає жодному налаштованому проєкту.\n\n'
      'Можливі причини:\n'
      '• QR код пошкоджений або неправильно відсканований\n'
      '• Формат QR коду не підтримується\n'
      '• Не налаштовано відповідний проєкт для цього QR коду';
  static const String invalidDeeplinkRecommendations = 'Рекомендації:\n'
      '• Перевірте якість сканування QR коду\n'
      '• Переконайтеся, що QR код містить правильний формат\n'
      '• Налаштуйте новий проєкт для цього типу QR кодів\n'
      '• Зверніться до адміністратора за допомогою';
  static const String invalidDeeplinkButtonOk = 'Зрозуміло';

  // Загальні помилки
  static const String generalErrorTitle = 'Помилка';
  static const String generalErrorButtonOk = 'ОК';

  // Помилки валідації
  static const String validationErrorTitle = 'Помилка валідації';
  static const String validationErrorButtonOk = 'Зрозуміло';

  // Помилки збереження
  static const String storageErrorTitle = 'Помилка збереження';
  static const String storageErrorButtonOk = 'Зрозуміло';

  // Помилки мережі
  static const String networkErrorTitle = 'Помилка мережі';
  static const String networkErrorButtonOk = 'Зрозуміло';
}

/// Базовий клас для всіх помилок в додатку
abstract class AppError {
  final String message;
  final String? details;
  
  const AppError(this.message, [this.details]);
  
  @override
  String toString() => 'AppError: $message${details != null ? ' ($details)' : ''}';
}

/// Помилка валідації даних
class ValidationError extends AppError {
  const ValidationError(String message, [String? details]) : super(message, details);
}

/// Помилка зберігання даних
class StorageError extends AppError {
  const StorageError(String message, [String? details]) : super(message, details);
}

/// Помилка обробки URL
class UrlError extends AppError {
  const UrlError(String message, [String? details]) : super(message, details);
}

/// Помилка аутентифікації
class AuthError extends AppError {
  const AuthError(String message, [String? details]) : super(message, details);
}

/// Помилка обробки deep links
class DeepLinkError extends AppError {
  const DeepLinkError(String message, [String? details]) : super(message, details);
}

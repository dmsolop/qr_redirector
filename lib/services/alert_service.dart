import 'package:flutter/material.dart';
import '../core/alert_messages.dart';

/// Сервіс для показу різних типів алєртів в застосунку
class AlertService {
  /// Показує алєрт про невалідний deeplink
  ///
  /// [context] - контекст для показу алєрту
  /// [onOkPressed] - callback при натисканні кнопки "Зрозуміло"
  static Future<void> showInvalidDeeplinkAlert(
    BuildContext context, {
    VoidCallback? onOkPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: Colors.red.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  AlertMessages.invalidDeeplinkTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AlertMessages.invalidDeeplinkMessage,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    AlertMessages.invalidDeeplinkRecommendations,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOkPressed?.call();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                AlertMessages.invalidDeeplinkButtonOk,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Універсальний метод для показу алєртів про помилки
  ///
  /// [context] - контекст для показу алєрту
  /// [title] - заголовок алєрту
  /// [message] - повідомлення алєрту
  /// [recommendations] - рекомендації (опціонально)
  /// [buttonText] - текст кнопки (за замовчуванням "ОК")
  /// [onPressed] - callback при натисканні кнопки
  /// [icon] - іконка алєрту (опціонально)
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? recommendations,
    String buttonText = AlertMessages.generalErrorButtonOk,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: Colors.red.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
                if (recommendations != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      recommendations,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPressed?.call();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Показує алєрт про помилку валідації
  static Future<void> showValidationErrorAlert(
    BuildContext context, {
    required String message,
    String? recommendations,
    VoidCallback? onPressed,
  }) {
    return showErrorDialog(
      context,
      title: AlertMessages.validationErrorTitle,
      message: message,
      recommendations: recommendations,
      buttonText: AlertMessages.validationErrorButtonOk,
      onPressed: onPressed,
      icon: Icons.warning,
    );
  }

  /// Показує алєрт про помилку збереження
  static Future<void> showStorageErrorAlert(
    BuildContext context, {
    required String message,
    String? recommendations,
    VoidCallback? onPressed,
  }) {
    return showErrorDialog(
      context,
      title: AlertMessages.storageErrorTitle,
      message: message,
      recommendations: recommendations,
      buttonText: AlertMessages.storageErrorButtonOk,
      onPressed: onPressed,
      icon: Icons.storage,
    );
  }

  /// Показує алєрт про помилку мережі
  static Future<void> showNetworkErrorAlert(
    BuildContext context, {
    required String message,
    String? recommendations,
    VoidCallback? onPressed,
  }) {
    return showErrorDialog(
      context,
      title: AlertMessages.networkErrorTitle,
      message: message,
      recommendations: recommendations,
      buttonText: AlertMessages.networkErrorButtonOk,
      onPressed: onPressed,
      icon: Icons.wifi_off,
    );
  }
}

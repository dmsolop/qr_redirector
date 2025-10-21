import 'package:local_auth/local_auth.dart';

class AuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Верифікація основного пароля телефона (при першому запуску)
  static Future<bool> verifyDeviceCredentials() async {
    try {
      // Перевіряємо, чи підтримується автентифікація
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        print('[AuthService] Device does not support authentication');
        return false;
      }

      // Перевіряємо доступність біометрії
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('[AuthService] Can check biometrics: $canCheckBiometrics');

      // Завжди намагаємося використати системну автентифікацію
      // (біометрія або PIN/пароль телефона)
      final result = await _localAuth.authenticate(
        localizedReason: 'Підтвердіть свою особу для налаштування додатку',
        options: const AuthenticationOptions(
          biometricOnly: false, // Дозволяємо і біометрію, і PIN/пароль
          stickyAuth: true,
        ),
      );
      
      print('[AuthService] Authentication result: $result');
      return result;
    } catch (e) {
      // Логуємо помилку для debugging
      print('[AuthService] Device credentials verification failed: $e');
      return false;
    }
  }
}
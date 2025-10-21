import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _authEnabledKey = 'auth_enabled';
  static const String _authTypeKey = 'auth_type';
  static const String _pinKey = 'auth_pin';
  
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authEnabledKey) ?? false;
  }

  static Future<void> setAuthEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authEnabledKey, enabled);
  }

  static Future<String?> getAuthType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTypeKey);
  }

  static Future<void> setAuthType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTypeKey, type);
  }

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> authenticateWithBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Підтвердіть свою особу для доступу до налаштувань',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateWithPin(String enteredPin) async {
    final savedPin = await getPin();
    return savedPin == enteredPin;
  }

  /// Верифікація основного пароля телефона (при першому запуску)
  static Future<bool> verifyDeviceCredentials() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        // Якщо біометрія недоступна, використовуємо PIN
        return await _localAuth.authenticate(
          localizedReason: 'Підтвердіть свою особу для налаштування додатку',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
      }

      // Використовуємо біометрію або PIN
      return await _localAuth.authenticate(
        localizedReason: 'Підтвердіть свою особу для налаштування додатку',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    final authType = await getAuthType();
    
    switch (authType) {
      case 'biometric':
        return await authenticateWithBiometric();
      case 'pin':
        // PIN буде введений через UI
        return false;
      default:
        return false; // Завжди потрібна автентифікація
    }
  }
}

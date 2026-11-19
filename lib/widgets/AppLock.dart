import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fingerprint / Face ID / phone PIN lock when the app opens.
/// The app already stays logged in with the saved token, so biometrics
/// works as an "App Lock" in front of the dashboard.
class AppLock {
  static const _key = 'app_lock_enabled';
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  /// true if the phone has fingerprint / face / PIN set up.
  static Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      print("AppLock isSupported error :: $e");
      return false;
    }
  }

  /// Shows the system prompt. Falls back to the phone PIN / pattern
  /// if the customer has no fingerprint or face set up.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      print("AppLock authenticate error :: $e");
      return false;
    }
  }
}

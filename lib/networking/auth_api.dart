import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Helper for the public (no-token) auth endpoints:
/// forgot password and login with email / mobile OTP.
///
/// Unlike BaseClient.authPost, this returns the server's JSON for every
/// status code (400, 404, 422, 429 ...), so the user sees the real message
/// such as "Invalid OTP" instead of a generic error.
class AuthApi {
  static Future<Map<String, dynamic>?> post(
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      print("URL :: $url");
      print("PAYLOAD :: $payload");
      print("STATUS CODE :: ${res.statusCode}");
      print("RESPONSE :: ${res.body}");

      if (res.body.trim().isEmpty) {
        return {
          'status': false,
          'message': 'Server returned an empty response (${res.statusCode})',
        };
      }

      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'status': false, 'message': 'Unexpected server response'};
    } catch (e) {
      print("AuthApi error :: $e");
      return null;
    }
  }

  /// "1", 1, true, "true", "yes", "on" -> true
  static bool isOn(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'on';
  }

  static bool ok(Map<String, dynamic>? res) =>
      res != null && res['status'] == true;

  /// Best user-facing message: first validation error, then "message".
  static String message(
    Map<String, dynamic>? res, [
    String fallback = "Error! Something went wrong",
  ]) {
    if (res == null) {
      return "Unable to connect. Please check your internet connection.";
    }
    final errors = res['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first != null) return first.toString();
    }
    final msg = res['message'];
    if (msg != null && msg.toString().trim().isNotEmpty) return msg.toString();
    return fallback;
  }

  /// Reads a key from the top level or from "data".
  static dynamic find(Map<String, dynamic>? res, String key) {
    if (res == null) return null;
    if (res[key] != null) return res[key];
    final data = res['data'];
    if (data is Map && data[key] != null) return data[key];
    return null;
  }
}

/// Login screen mode, from the permissions API
/// (GET /permissions -> "login_with_mobile_no_or_email_only").
///
/// /permissions needs a login token, so the value is saved after login and
/// kept through logout. The login screen reads the saved value.
/// First install (never logged in) -> normal password login.
class LoginMode {
  static const permissionKey = 'login_with_mobile_no_or_email_only';
  static const _prefsKey = 'login_mode_otp_only';

  /// Call wherever the permissions API response is received.
  static Future<void> saveFromPermissions(Map permissions) async {
    if (!permissions.containsKey(permissionKey)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, AuthApi.isOn(permissions[permissionKey]));
  }

  static Future<bool> isOtpOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// prefs.clear() for logout, but keeps the login mode.
  static Future<void> clearPrefsKeepLoginMode() async {
    final prefs = await SharedPreferences.getInstance();
    final otpOnly = prefs.getBool(_prefsKey);
    await prefs.clear();
    if (otpOnly != null) await prefs.setBool(_prefsKey, otpOnly);
  }
}

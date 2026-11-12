import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String siteCurrency = "\$";

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    siteCurrency = prefs.getString('site_currency') ?? "\$";
    print('siteCurrency :: $siteCurrency');
  }
}

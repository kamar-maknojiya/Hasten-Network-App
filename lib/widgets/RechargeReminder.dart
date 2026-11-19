import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vision_broadband/widgets/NotificationService.dart';

/// Phone-side recharge reminders (no server work needed):
///   - 3 days before expiry, 10:00 AM
///   - 1 day before expiry, 10:00 AM
///   - at expiry time
/// Re-scheduled only when the expiry date changes (e.g. after a recharge).
class RechargeReminder {
  static const _ids = [9101, 9102, 9103];
  static const _prefsKey = 'recharge_reminder_expiry';
  static bool _tzReady = false;

  static FlutterLocalNotificationsPlugin get _plugin =>
      NotificationService.instance.flutterLocalNotificationsPlugin;

  static Future<void> schedule(DateTime? expiry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = expiry?.toIso8601String() ?? '';
      if (prefs.getString(_prefsKey) == key) return; // already scheduled

      await cancelAll();
      await prefs.setString(_prefsKey, key);
      if (expiry == null) return;

      if (!_tzReady) {
        tzdata.initializeTimeZones();
        _tzReady = true;
      }

      DateTime at10(DateTime d) => DateTime(d.year, d.month, d.day, 10);
      final reminders = <int, Map<String, dynamic>>{
        _ids[0]: {
          "time": at10(expiry.subtract(const Duration(days: 3))),
          "title": "Your plan expires in 3 days",
          "body": "Recharge now to stay connected without interruption.",
        },
        _ids[1]: {
          "time": at10(expiry.subtract(const Duration(days: 1))),
          "title": "Your plan expires tomorrow",
          "body": "Recharge today so your internet keeps running.",
        },
        _ids[2]: {
          "time": expiry,
          "title": "Your plan has expired",
          "body": "Recharge now to get back online.",
        },
      };

      final now = DateTime.now();
      for (final entry in reminders.entries) {
        final when = entry.value["time"] as DateTime;
        if (!when.isAfter(now)) continue; // already passed

        await _plugin.zonedSchedule(
          entry.key,
          entry.value["title"] as String,
          entry.value["body"] as String,
          // exact moment in time; works regardless of the phone's time zone
          tz.TZDateTime.from(when.toUtc(), tz.UTC),
          NotificationDetails(
            android: AndroidNotificationDetails(
              NotificationService.channel.id,
              NotificationService.channel.name,
              channelDescription: NotificationService.channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'recharge',
        );
      }
      print("RechargeReminder scheduled for expiry $expiry");
    } catch (e) {
      print("RechargeReminder error :: $e");
    }
  }

  /// Call on logout so the next user doesn't get the old reminders.
  static Future<void> cancelAll() async {
    try {
      for (final id in _ids) {
        await _plugin.cancel(id);
      }
    } catch (e) {
      print("RechargeReminder cancel error :: $e");
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/screens/dashboard/Home/HomeScreen.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/PaymentSuccessScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/ProfileScreen.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/RechargeScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/StatisticsScreen.dart';
import 'package:vision_broadband/screens/dashboard/Wifi/WifiScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/Network/NetworkAwareWidget.dart';
import 'package:vision_broadband/widgets/Network/NetworkWrapper.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int index = 0;
  DateTime? _lastBackPressTime;
  bool isDark = true;


  Future<bool> hasPermission(int tabIndex) async {
    final prefs = await SharedPreferences.getInstance();

    switch (tabIndex) {
    // Recharge
      case 1:
        return (prefs.getString("recharge_with_online") == "1") ||
            (prefs.getString("recharge_pin") == "1");

    // Statistics
      case 2:
        return (prefs.getString("statistics_general") == "1") ||
            // (prefs.getString("statistics_usage_session") == "1") ||
            // (prefs.getString("statistics_authlog") == "1") ||
            (prefs.getString("bandwidth") == "1");

    // WIFI
      case 3:
        return prefs.getString("acs_device") == "1";

    // Home & profile always allow
      default:
        return true;
    }
  }

  void showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "You don't have permission to access this feature. Please contact your administrator.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(),
      RechargeScreen(),
      StatisticsScreen(isBack: false),
      WifiScreen(isBack: false),
      ProfileScreen(isBack: false),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (index != 0) {
          setState(() {
            index = 0;
          });
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          successToast('Press back again to exit');
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        // body: pages[index],
        body: NetworkWrapper(child: pages[index]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          // onTap: (value) {
          //   setState(() {
          //     index = value;
          //   });
          // },

          onTap: (value) async {
            if (await hasPermission(value)) {
              setState(() {
                index = value;
              });
            } else {
              errToast("You don't have permission to access this feature.");
              // showPermissionDialog();
              // TopAlert.show(context,
              //   message: "You don't have permission to access this feature.",
              //   type: AlertType.error,
              // );
            }
          },

          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          selectedLabelStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.alt_route),
              label: "Recharge",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "Stats",
            ),

            BottomNavigationBarItem(icon: Icon(Icons.wifi), label: "Wifi"),

            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

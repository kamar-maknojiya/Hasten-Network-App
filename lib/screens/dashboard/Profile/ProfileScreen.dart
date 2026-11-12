import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/auth/LoginScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/ServiceHistoryScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/ChangeMacScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/ChangePasswordScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/EditProfileScreen.dart';
import 'package:vision_broadband/screens/dashboard/Invoice/InvoiceScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/LedgerScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/UpcomingRechargeScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/UsageSessionScreen.dart';
import 'package:vision_broadband/screens/dashboard/Wifi/WifiScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/theme/theme_manager.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/CacheHelper.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/ProfileShimmerScreen.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final bool isBack;
  const ProfileScreen({super.key, required this.isBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  Map<String, dynamic> userData = {};
  Map<String, dynamic> packageData = {};
  String contactNo = '';

  final settings = [
    {
      "title": "Edit Profile",
      "icon": Icons.person_outline,
      "color": AppColors.primary,
      "permission": "show_profile",
      "screen": const EditProfileScreen(),
    },
    {
      "title": "Change Password",
      "icon": Icons.lock_outline,
      "color": const Color(0xff4F7BFF),
      "permissions": ["acs_wlan_host", "acs_wan_setting", "acs_wifi_setting"],
      "screen": ChangePasswordScreen(),
    },
    {
      "title": "WiFi Setting",
      "icon": Icons.wifi,
      "color": const Color(0xffC83FFF),
      "permission": "acs_device",
      "screen": WifiScreen(isBack: true),
    },
    {
      "title": "Change MAC Address",
      "icon": Icons.credit_card,
      "color": const Color(0xffF7A84B),
      "permission": "change_mac",
      "screen": ChangeMacScreen(),
    },
    {
      "title": "Invoice",
      "icon": Icons.receipt_long,
      "color": AppColors.primary,
      "permission": "invoice_list",
      "screen": InvoiceScreen(),
    },
    {
      "title": "Ledger",
      "icon": Icons.article_outlined,
      "color": const Color(0xff4F7BFF),
      "permissions": ["ledger_list", "online_transaction"],
      "screen": LedgerScreen(),
    },
    {
      "title": "Upcoming Recharge",
      "icon": Icons.access_time,
      "color": AppColors.primary,
      "permission": "activate_advance_recharge",
      "screen": UpcomingRechargeScreen(),
    },
    {
      "title": "Usage Session",
      "icon": Icons.bar_chart,
      "color": const Color(0xff4F7BFF),
      "permissions": ["statistics_usage_session", "statistics_general"],
      "screen": UsageSessionScreen(),
    },
    {
      "title": "Service History",
      "icon": Icons.history,
      "permission": "service_history_list",
      "color": const Color(0xff4CAF50),
      "screen": ServiceHistoryScreen(isBack: true),
    },
    {
      "title": "Support",
      "icon": Icons.support_agent,
      // "permission": "customer_support_no",
      "color": const Color(0xff3F51B5),
      "bgColor": const Color(0xffE8EAF6),
      "isCall": true,
    },
    {
      "title": "Logout",
      "icon": Icons.logout,
      "color": AppColors.red,
      "isLogout": true,
    },
  ];

  Future<void> makeCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: contactNo);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('Could not launch dialer');
    }
  }

  Map<String, dynamic> permissions = {};

  Future<void> getPermission() async {
    final prefs = await SharedPreferences.getInstance();
    contactNo = prefs.getString('site_mobile_no') ?? '';

    print('contactNo :: $contactNo');

    var response = await BaseClient()
        .get(GET_PERMISSIONS, context)
        .catchError((err) {
      print(err);
      return null;
    });

    if (!mounted) return;

    if (response != null && response['status'] == true) {
      final permission = Map<String, dynamic>.from(response['data']);

      // Save latest permission
      await CacheHelper.save("permission_cache", permission);

      setState(() {
        permissions = permission;
      });
    } else {
      // Load cached permission
      final cache = await CacheHelper.read("permission_cache");

      if (cache != null) {
        setState(() {
          permissions = Map<String, dynamic>.from(cache);
        });

        errToast(response?['message'] ?? "Showing last saved permissions");
      } else {
        errToast(response?['message'] ?? "No permission data available");
      }
    }
  }

  List<Map<String, dynamic>> get visibleSettings {
    return settings
        .where((item) {
          // Multiple permissions
          if (item["isCall"] == true &&
              (contactNo.trim().isEmpty || contactNo == "null")) {
            return false;
          }

          if (item["permissions"] != null) {
            final List permissionsList = item["permissions"] as List;
            return permissionsList.any(
              (key) => permissions[key]?.toString() == "1",
            );
          }
          // Single permission
          if (item["permission"] != null) {
            return permissions[item["permission"]]?.toString() == "1";
          }
          return true;
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    getPermission();
    getProfile();
  }

  String formatDate(String? date) {
    if (date == null ||
        date.trim().isEmpty ||
        date.trim() == "-" ||
        date.toLowerCase() == "null") {
      return "-";
    }

    try {
      DateTime dateTime = DateTime.parse(date);

      return DateFormat("dd MMM yyyy hh:mm a").format(dateTime);
    } catch (_) {
      try {
        final dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date);

        return DateFormat("dd MMM yyyy hh:mm a").format(dateTime);
      } catch (_) {
        return "-";
      }
    }
  }

  void getProfile() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient()
        .get(GET_PROFILE_DETAILS, context)
        .catchError((err) {
          print(err);
          return null;
        });
    if (response != null && response['status'] == true) {
      // await CacheHelper.save("profile_cache", response['data']);
      setState(() {
        userData = response['data'];
        packageData = response['data']['packages'] ?? {};
        isLoading = false;
      });
    } else {
      errToast(response?['message']);
      final cache = await CacheHelper.read("dashboard_cache");
      if (cache != null) {
        setState(() {
          userData = cache;
          packageData = cache['packages'] ?? {};
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white60 : Colors.black54;

    final username = userData['username']?.toString() ?? '';

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: isLoading
            ? const ProfileShimmerScreen()
            : SafeArea(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(height: 10),

                      /// HEADER
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: CustomAppbar(isBack: widget.isBack),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) =>ProfileScreen(isBack: true)));
                              },
                              child: Container(
                                width: 50.w,
                                height: 48.h,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), color: AppColors.primary),
                                child: Center(
                                  child: Text(
                                    username.isEmpty ? 'NA' : username.substring(0, username.length >= 2 ? 2 : username.length).toUpperCase(),
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        username,
                        style: GoogleFonts.poppins(color: text, fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        userData['group']?.toString() ?? '',
                        style: GoogleFonts.poppins(
                          color: subText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: userData['account_status']?.toString() == 'Active'
                              ? AppColors.primary.withOpacity(.15)
                              : AppColors.orange.withOpacity(.15),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // userData['account_status']?.toString() == 'Active'
                            //     ? Icon(
                            //         Icons.check,
                            //         color: AppColors.primary,
                            //         size: 18.r,
                            //       )
                            //     : Icon(
                            //         Icons.check,
                            //         color: AppColors.orange,
                            //         size: 18.r,
                            //       ),
                            // SizedBox(width: 8),
                            Text(
                              userData['account_status']?.toString() ?? '',
                              style: GoogleFonts.poppins(
                                color: userData['account_status']?.toString() == 'Active'
                                    ? AppColors.primary
                                    : AppColors.orange,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      /// ACCOUNT DETAIL CARD
                      Container(
                        padding: EdgeInsets.all(16.r),

                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12)],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Account Detail",
                              style: GoogleFonts.poppins(
                                color: text.withOpacity(0.7),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildRow(
                              "Username",
                              userData['fullname'] ?? '-',
                              text,
                              isPrimary: true,
                            ),
                            divider(text),
                            buildRow(
                              "Package",
                              packageData['package_name'] ?? '-',
                              text,
                            ),
                            divider(text),
                            // buildRow(
                            //   "Status",
                            //   userData['account_status'] ?? '-',
                            //   text,
                            //   isPrimary: true,
                            //   textClr:
                            //       userData['account_status']?.toString() == 'Active'
                            //       ? AppColors.primary
                            //       : AppColors.orange,
                            // ),
                            // divider(text),
                            buildRow(
                              "Account Type",
                              userData['account_type'] ?? '-',
                              text,
                            ),
                            divider(text),
                            buildRow(
                              "Wallet Balance",
                              "${AppConfig.siteCurrency} ${userData['wallet_balance'] ?? '-'}",
                              text,
                            ),
                            divider(text),
                            buildRow("Group", userData['group'] ?? '-', text),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.05),
                                    blurRadius: 12,
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Connection Info",
                              style: GoogleFonts.poppins(
                                color: text.withOpacity(0.7),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildInfoRow(
                              "Expiry Date",
                              formatDate(userData['expiry_date'] ?? '-'),
                              text,
                              isPrimary: true,
                            ),
                            divider(text),
                            buildInfoRow(
                              "Last Recharge",
                              formatDate(userData['last_recharge_date'] ?? '-'),
                              text,
                            ),
                            divider(text),
                            buildInfoRow(
                              "Last Logoff",
                              formatDate(userData['last_logoff'] ?? '-'),
                              text,
                            ),
                            divider(text),
                            buildInfoRow(
                              "Registered",
                              formatDate(userData['registered_on'] ?? '-'),
                              text,
                            ),
                            // ListView.separated(
                            //   shrinkWrap: true,
                            //   physics: const NeverScrollableScrollPhysics(),
                            //   itemCount: connectionInfo.length,
                            //   separatorBuilder: (_, __) => Divider(
                            //     color: isDark ? Colors.white12 : Colors.black12,
                            //   ),
                            //   itemBuilder: (context, index) {
                            //     final item = connectionInfo[index];
                            //     return Padding(
                            //       padding: EdgeInsets.symmetric(vertical: 6.h),
                            //       child: Row(
                            //         children: [
                            //           Expanded(
                            //             child: Text(
                            //               item["title"] as String,
                            //               style: GoogleFonts.poppins(fontSize: 12.sp),
                            //             ),
                            //           ),
                            //           Text(
                            //             item["value"] as String,
                            //             style: GoogleFonts.poppins(
                            //               color: item["highlight"] != null
                            //                   ? AppColors.orange
                            //                   : text,
                            //               fontWeight: FontWeight.bold,
                            //               fontSize: 13.sp,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     );
                            //   },
                            // ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Settings",
                              style: GoogleFonts.poppins(
                                color: text.withOpacity(0.7),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16.sp),

                            /// THEME
                            Row(
                              children: [
                                Container(
                                  width: 45.w,
                                  height: 45.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: const Icon(
                                    Icons.dark_mode,
                                    color: AppColors.orange,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    "Theme",
                                    style: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    themeProvider.toggleTheme(
                                      !themeProvider.isDark,
                                    );
                                  },

                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 60.w,
                                    height: 30.h,
                                    padding: EdgeInsets.all(3.r),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.r),
                                      color: isDark
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      alignment: isDark
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        width: 28.w,
                                        height: 28.h,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isDark
                                              ? Icons.dark_mode
                                              : Icons.light_mode,
                                          size: 16.r,
                                          color: isDark
                                              ? Colors.black
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Switch(
                                //   value: isDark,
                                //   onChanged: (_) {
                                //     onThemeToggle();
                                //   },
                                // ),
                              ],
                            ),
                            Divider(color: text, thickness: 0.1),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visibleSettings.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: text, thickness: 0.1),

                              itemBuilder: (context, index) {
                                final item = visibleSettings[index];

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () async {
                                    print("Tapped ${item["title"]}");
                                    if (item["isLogout"] == true) {
                                      _showLogOutDialog(context, isDark);
                                    } else if (item["isCall"] == true) {
                                      await makeCall();
                                    } else if (item["screen"] != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              item["screen"] as Widget,
                                        ),
                                      );
                                    }
                                  },
                                  leading: Container(
                                    width: 45.w,
                                    height: 45.h,
                                    decoration: BoxDecoration(
                                      color: (item["color"] as Color)
                                          .withOpacity(.15),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(
                                      item["icon"] as IconData,
                                      color: item["color"] as Color,
                                    ),
                                  ),
                                  title: Text(
                                    item["title"] as String,
                                    style: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget buildRow(
    String title,
    String value,
    Color text, {
    Color textClr = AppColors.primary,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: text.withOpacity(0.6),
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: isPrimary ? textClr : text,
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isLogout = false;

  Widget buildInfoRow(
    String title,
    String value,
    Color text, {
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: text.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: isPrimary ? AppColors.orange : text,
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget divider(Color text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Divider(color: text.withOpacity(.20), height: 1),
    );
  }

  void _showLogOutDialog(BuildContext context, bool isDark) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white70 : Colors.black54;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red.withOpacity(.12),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: AppColors.red,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Logout",
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Are you sure you want to logout?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: text.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 45),
                              side: BorderSide(color: Colors.grey.shade500),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              setDialogState(() {
                                isLogout = true;
                              });
                              await Future.delayed(const Duration(seconds: 2));
                              await logout();
                              setDialogState(() {
                                isLogout = false;
                              });
                            },
                            // onPressed: () async {
                            //   final prefs = await SharedPreferences.getInstance();
                            //   await prefs.clear();
                            //   await prefs.remove('token');
                            //
                            //   Navigator.pushAndRemoveUntil(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => const LoginScreen(),
                            //     ),
                            //     (route) => false,
                            //   );
                            // },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              minimumSize: const Size(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLogout
                                ? Center(
                                    child: Lottie.asset(
                                      'assets/animation/loading.json',
                                      height: 45,
                                      repeat: true,
                                      delegates: LottieDelegates(
                                        values: [
                                          ValueDelegate.color(const [
                                            '**',
                                          ], value: Colors.white),
                                        ],
                                      ),
                                    ),
                                  )
                                : Text(
                                    "Logout",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> logout() async {
    setState(() {
      isLogout = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      var payload = {"device_id": deviceId};
      var response = await BaseClient().post(LOGOUT_URL, payload, context);
      setState(() {
        isLogout = false;
      });
      if (response != null && response['status'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        print('TOKEN1 :: $token');
        await prefs.clear();
        await prefs.remove('token');
        print('TOKEN2 :: $token');
        successToast(response['message']);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        errToast(response?['message'] ?? "Something went wrong");
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isLogout = false;
        });
      }
      errToast("Error! Something went wrong");
    }
  }
}

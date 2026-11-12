import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/auth/LoginScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/ServiceHistoryScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/ChangeMacScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/EditProfileScreen.dart';
import 'package:vision_broadband/screens/dashboard/Invoice/InvoiceScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/LedgerScreen.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/RechargeScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/StatisticsScreen.dart';
import 'package:vision_broadband/screens/dashboard/Ticket/SupportTicketScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/UpcomingRechargeScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/UsageSessionScreen.dart';
import 'package:vision_broadband/screens/dashboard/Wifi/WifiScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreSettingsScreen extends StatefulWidget {
  const MoreSettingsScreen({super.key});

  @override
  State<MoreSettingsScreen> createState() => _MoreSettingsScreenState();
}

class _MoreSettingsScreenState extends State<MoreSettingsScreen> {
  bool isLogout = false;
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
      "title": "Recharge",
      "icon": Icons.access_time,
      "permission": "recharge_with_online",
      "color": const Color(0xff26A69A),
      "bgColor": const Color(0xffE0F2F1),
      "screen": RechargeScreen(isBack: true),
    },
    {
      "title": "Upcoming\nRecharge",
      "icon": Icons.inventory_2_outlined,
      "permission": "activate_advance_recharge",
      "color": const Color(0xff26A69A),
      "bgColor": const Color(0xffE0F2F1),
      "screen": UpcomingRechargeScreen(),
    },
    {
      "title": "Usage",
      "icon": Icons.bar_chart,
      "permissions": ["statistics_usage_session", "statistics_general"],
      "color": const Color(0xff5C6BC0),
      "bgColor": const Color(0xffE8EAF6),
      "screen": UsageSessionScreen(),
    },
    {
      "title": "Tickets",
      "icon": Icons.mail_outline,
      "permissions": ["ticket_list", "add_ticket", "update_ticket"],
      "color": const Color(0xffFBC02D),
      "bgColor": const Color(0xffFFF8E1),
      "screen": SupportTicketScreen(),
    },
    {
      "title": "Statistics",
      "icon": Icons.insert_chart_outlined,
      "permissions": ["statistics_general", "bandwidth"],
      "color": const Color(0xff26C6DA),
      "bgColor": const Color(0xffE0F7FA),
      "screen": StatisticsScreen(isBack: true),
    },
    {
      "title": "Service History",
      "icon": Icons.history,
      "permission": "service_history_list",
      "color": const Color(0xff4CAF50),
      "bgColor": const Color(0xffE8F5E9),
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
      "color": const Color(0xffEF5350),
      "bgColor": const Color(0xffFFEBEE),
      "isLogout": true,
    },
  ];

  // List<Map<String, dynamic>> get visibleSettings {
  //   return settings.where((item) {
  //     // Multiple permissions
  //     if (item["permissions"] != null) {
  //       final List permissionsList = item["permissions"] as List;
  //       return permissionsList.any((key) => permissions[key]?.toString() == "1");
  //     }
  //     // Single permission
  //     if (item["permission"] != null) {
  //       return permissions[item["permission"]]?.toString() == "1";
  //     }
  //     return true;
  //   }).cast<Map<String, dynamic>>().toList();
  // }

  List<Map<String, dynamic>> get visibleSettings {
    return settings
        .where((item) {

      // Hide Support if contact number is empty
      if (item["isCall"] == true &&
          (contactNo.trim().isEmpty || contactNo == "null")) {
        return false;
      }

      // Multiple permissions
      if (item["permissions"] != null) {
        final List list = item["permissions"] as List;
        return list.any((key) => permissions[key]?.toString() == "1");
      }

      // Single permission or List permission
      if (item["permission"] != null) {
        final permission = item["permission"];

        if (permission is List) {
          return permission.any(
                (key) => permissions[key]?.toString() == "1",
          );
        }

        return permissions[permission]?.toString() == "1";
      }

      return true;
    })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // List<Map<String, dynamic>> get visibleSettings {
  //   return settings
  //       .where((item) {
  //         // Multiple permissions in "permissions"
  //         if (item["permissions"] != null) {
  //           final List list = item["permissions"] as List;
  //           return list.any((key) => permissions[key]?.toString() == "1");
  //         }
  //
  //         // "permission" can be String or List
  //         if (item["permission"] != null) {
  //           final permission = item["permission"];
  //
  //           if (permission is List) {
  //             return permission.any(
  //               (key) => permissions[key]?.toString() == "1",
  //             );
  //           }
  //
  //           return permissions[permission]?.toString() == "1";
  //         }
  //
  //         return true;
  //       })
  //       .cast<Map<String, dynamic>>()
  //       .toList();
  // }

  Future<void> makeCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: contactNo);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('Could not launch dialer');
    }
  }

  Map<String, String> permissions = {};

  Future<void> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    contactNo = prefs.getString('site_mobile_no') ?? '';
    print('contactNo :: $contactNo');
    permissions = {
      "update_profile": prefs.getString("update_profile") ?? "0",
      "acs_device": prefs.getString("acs_device") ?? "0",
      "acs_wifi_setting": prefs.getString("acs_wifi_setting") ?? "0",
      "change_mac": prefs.getString("change_mac") ?? "0",
      "service_history_list": prefs.getString("service_history_list") ?? "0",
      "invoice_list": prefs.getString("invoice_list") ?? "0",
      "show_profile": prefs.getString("show_profile") ?? "0",
      "ledger_list": prefs.getString("ledger_list") ?? "0",
      "online_transaction": prefs.getString("online_transaction") ?? "0",
      "recharge_with_online": prefs.getString("recharge_with_online") ?? "0",
      "activate_advance_recharge":
          prefs.getString("activate_advance_recharge") ?? "0",
      "statistics_usage_session":
          prefs.getString("statistics_usage_session") ?? "0",
      "ticket_list": prefs.getString("ticket_list") ?? "0",
      "add_ticket": prefs.getString("add_ticket") ?? "0",
      "update_ticket": prefs.getString("update_ticket") ?? "0",
      "customer_support_no": prefs.getString("customer_support_no") ?? "0",
      "statistics_general": prefs.getString("statistics_general") ?? "0",
      "bandwidth": prefs.getString("bandwidth") ?? "0",
    };

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              CustomAppbar(title: 'More Settings'),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: visibleSettings.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 14,
                    childAspectRatio: .96,
                  ),
                  itemBuilder: (context, index) {
                    final item = visibleSettings[index];
                    return GestureDetector(
                      onTap: () async {
                        if (item["isLogout"] == true) {
                          _showLogOutDialog(context, isDark);
                        } else if (item["isCall"] == true) {
                          await makeCall();
                        } else if (item["screen"] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => item["screen"] as Widget,
                            ),
                          );
                        }
                      },


                      child: Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: (item["color"] as Color).withOpacity(.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item["icon"] as IconData,
                                // size: 26,
                                color: item["color"] as Color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                item["title"] as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 12.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Expanded(
              //   child: GridView.builder(
              //
              //     shrinkWrap: true,
              //     physics: const NeverScrollableScrollPhysics(),
              //     itemCount: settings.length,
              //     separatorBuilder: (_, __) =>
              //         Divider(color: isDark ? Colors.white12 : Colors.black12),
              //
              //     itemBuilder: (context, index) {
              //       final item = settings[index];
              //
              //       return ListTile(
              //         contentPadding: EdgeInsets.zero,
              //         onTap: () {
              //           print("Tapped ${item["title"]}");
              //           if (item["isLogout"] == true) {
              //             _showLogOutDialog(context, isDark);
              //           } else if (item["screen"] != null) {
              //             Navigator.push(
              //               context,
              //               MaterialPageRoute(
              //                 builder: (_) => item["screen"] as Widget,
              //               ),
              //             );
              //           }
              //         },
              //         // onTap: () {
              //         //   print("Tapped ${item["title"]}");
              //         //   if (item["screen"] != null) {
              //         //     Navigator.push(
              //         //       context,
              //         //       MaterialPageRoute(
              //         //         builder: (_) => item["screen"] as Widget,
              //         //       ),
              //         //     );
              //         //   }
              //         // },
              //         leading: Container(
              //           width: 52,
              //           height: 52,
              //           decoration: BoxDecoration(
              //             color: (item["color"] as Color).withOpacity(.15),
              //             borderRadius: BorderRadius.circular(16),
              //           ),
              //           child: Icon(
              //             item["icon"] as IconData,
              //             color: item["color"] as Color,
              //           ),
              //         ),
              //         title: Text(
              //           item["title"] as String,
              //           style: TextStyle(
              //             color: text,
              //             fontSize: 16,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //
              //         trailing: const Icon(Icons.chevron_right),
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
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
        successToast(response['message']);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        setState(() {
          isLogout = false;
        });
      } else {
        errToast(response?['message'] ?? "Something went wrong");
        Navigator.pop(context);
        setState(() {
          isLogout = false;
        });
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

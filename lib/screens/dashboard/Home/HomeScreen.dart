import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/Invoice/InvoiceScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/MoreSettingsScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/PayDueAmountScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/ProfileScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/RecentActivityScreen.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/RechargeScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/StatisticsScreen.dart';
import 'package:vision_broadband/screens/dashboard/Ticket/SupportTicketScreen.dart';
import 'package:vision_broadband/screens/dashboard/Profile/UpcomingRechargeScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/CacheHelper.dart';
import 'package:vision_broadband/widgets/Shimmer/HomeShimmerScreen.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? packageData;
  Map<String, dynamic>? nextRechargeData;
  List<dynamic> activities = [];

  @override
  void initState() {
    super.initState();
    loadHome();
  }

  Future<void> loadHome() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      getDashboard(),
      getPermission(),
      loadPermissions(),
      getActivityLogs(),
    ]);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> hasPermission(String permission) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(permission) == "1";
  }

  Future<bool> hasStatisticsPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString("statistics_general") == "1") || (prefs.getString("bandwidth") == "1");
  }

  Future<bool> hasTicketPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString("ticket_list") == "1") || (prefs.getString("add_ticket") == "1") || (prefs.getString("update_ticket") == "1");
  }

  Future<bool> hasRechargePermission() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString("recharge_with_online") == "1") || (prefs.getString("recharge_pin") == "1");
  }

  bool hasRecharge = false;

  Future<void> loadPermissions() async {
    hasRecharge = await hasRechargePermission();
    if (mounted) {
      setState(() {});
    }
  }

  void showPermissionAlert() {
    errToast("You don't have permission to access this feature.");
  }

  // Future<void> getActivityLogs() async {
  //   setState(() {
  //     // isLoading = true;
  //   });
  //   var response = await BaseClient()
  //       .get("$RECENT_ACTIVITY?page=1&per_page=10", context)
  //       .catchError((err) {
  //         print(err);
  //         return null;
  //       });
  //   if (response != null && response['status'] == true) {
  //     setState(() {
  //       activities = response['data']['data'];
  //       // isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       // isLoading = false;
  //     });
  //   }
  // }

  Future<void> getActivityLogs() async {
    var response = await BaseClient()
        .get("$RECENT_ACTIVITY?page=1&per_page=10", context)
        .catchError((err) {
          print(err);
          return null;
        });

    if (response != null && response['status'] == true) {
      activities = response['data']['data'];

      // Save latest activity
      await CacheHelper.save("activity_cache", activities);

      if (!mounted) return;

      setState(() {});
    } else {
      // Load cached activity
      final cache = await CacheHelper.read("activity_cache");

      if (cache != null) {
        activities = List<dynamic>.from(cache);

        errToast(response?['message']);
      }

      if (!mounted) return;

      setState(() {});
    }
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

  String formatUsage(String value) {
    final match = RegExp(r'([\d.]+)\s*(.*)').firstMatch(value);

    if (match == null) return value;

    final number = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2) ?? '';

    return "${number.floor()} $unit";
  }

  IconData getActivityIcon(String message) {
    if (message.toLowerCase().contains('recharge')) {
      return Icons.currency_exchange;
    }

    if (message.toLowerCase().contains('profile')) {
      return Icons.person;
    }

    return Icons.history;
  }

  Future<void> getDashboard() async {
    // setState(() {
    //   isLoading = true;
    // });
    var response = await BaseClient().get(DASHBOARD, context).catchError((err) {
      print(err);
      return null;
    });
    if (response != null && response['status'] == true) {
      // Save latest dashboard
      await CacheHelper.save("dashboard_cache", response['data']);
      if (!mounted) return;
      setState(() {
        dashboardData = response['data'];
        packageData = response['data']['packages'];
        nextRechargeData = response['data']['next_advance_recharge'];
        // isLoading = false;
      });
    } else {
      // Load cached dashboard
      final cache = await CacheHelper.read("dashboard_cache");
      if (cache != null) {
        if (!mounted) return;
        setState(() {
          dashboardData = cache;
          packageData = cache['packages'] ?? {};
          nextRechargeData = cache['next_advance_recharge'];
          // isLoading = false;
        });
        errToast(response?['message']);
      } else {
        if (!mounted) return;
        // setState(() {
        //   isLoading = false;
        // });
        errToast(response?['message']);
      }
    }
  }

  // Future<void> getDashboard() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   var response = await BaseClient().get(DASHBOARD, context).catchError((err) {
  //     errToast("Error! Something went wrong");
  //     return null;
  //   });
  //   if (response != null && response['status'] == true) {
  //     if (!mounted) return;
  //     setState(() {
  //       dashboardData = response['data'];
  //       packageData = response['data']['packages'];
  //       nextRechargeData = response['data']['next_advance_recharge'];
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     errToast("Dashboard error");
  //   }
  // }
  String isAdvance = "0";
  String isDue = "0";
  String isStateGeneral = "0";
  String isBandWidth = "0";

  Future<void> getPermission() async {
    var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
      err,
    ) {
      return null;
    });

    if (!mounted) return;

    if (response != null && response['status'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = response['data'];

      // Save all permissions to SharedPreferences
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value != null) {
          await prefs.setString(key, value.toString());
        }
      }

      // Also store in variables
      setState(() {
        isAdvance = data['activate_advance_recharge'] ?? "0";
        isDue = data['pay_invoice_online'] ?? "0";
        isStateGeneral = data['statistics_general'] ?? "0";
        isBandWidth = data['bandwidth'] ?? "0";
      });

      print("Permissions saved successfully.");
      print("isAdvance :: $isAdvance");
    }
  }
  // Future<void> getPermission() async {
  //   var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
  //     err,
  //   ) {
  //     return null;
  //   });
  //
  //   if (!mounted) return;
  //
  //   if (response != null && response['status'] == true) {
  //     final prefs = await SharedPreferences.getInstance();
  //     final Map<String, dynamic> data = response['data'];
  //
  //     // Save every field in SharedPreferences
  //     for (final entry in data.entries) {
  //       final key = entry.key;
  //       final value = entry.value;
  //
  //       if (value is String) {
  //         await prefs.setString(key, value);
  //       } else if (value is int) {
  //         await prefs.setInt(key, value);
  //       } else if (value is bool) {
  //         await prefs.setBool(key, value);
  //       } else if (value is double) {
  //         await prefs.setDouble(key, value);
  //       } else if (value != null) {
  //         await prefs.setString(key, value.toString());
  //       }
  //     }
  //     print("Permissions saved successfully.");
  //   }
  // }

  // Future<void> getPermission() async {
  //
  //   var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
  //     err,
  //   ) {
  //     return null;
  //   });
  //   if (response != null && response['status'] == true) {
  //     if (!mounted) return;
  //
  //   } else {
  //     if (!mounted) return;
  //
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final Rechargecard = isDark ? AppColors.darkCard : AppColors.lightCard1;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white70 : Colors.black54;
    // bool isOnline = false;
    bool isOnline = dashboardData?['connection_status'] == "Online";
    final username = dashboardData?['username']?.toString() ?? '';

    return Scaffold(
      backgroundColor: bg,
      body: isLoading || dashboardData == null
          ? const HomeShimmerScreen()
          : RefreshIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
              onRefresh: () async {
                await loadHome();
              },
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello,",
                                  style: GoogleFonts.poppins(
                                    color: text,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  dashboardData?['username'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(isBack: true)));
                            },
                            child: Container(
                              width: 45.w,
                              height: 42.h,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), color: AppColors.primary),
                              child: Center(
                                child: Text(
                                  username.isEmpty ? 'NA' : username.substring(0, username.length >= 2 ? 2 : username.length).toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      /// CONNECTION CARD
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(isDark ? .35 : .45)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors:   [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.2),
                              // AppColors.primary.withOpacity(0.3),
                            ],
                          ),
                          // gradient: isDark
                          //     ? AppColors.statusCardGradient
                          //     : const LinearGradient(
                          //         begin: Alignment.topLeft,
                          //         end: Alignment.bottomRight,
                          //         colors: [
                          //           Color(0xFFFFFFFF),
                          //           Color(0xFFF0F8FF),
                          //           Color(0xFFDCEEFF),
                          //         ],
                          //       ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Status
                            Row(
                              children: [
                                CircleAvatar(radius: 5, backgroundColor: isOnline ? AppColors.green : Colors.red),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline ? "Online" : "Offline",
                                  style: GoogleFonts.poppins(
                                    color: isOnline ? AppColors.green : Colors.red,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            /// Plan Name
                            if(packageData != null )       Text(
                              packageData?['package_name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: text,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            /// Expiration
                        if(dashboardData?['expiry_date'] != null)
                          Row(
                              children: [
                                Text(
                                  "Expiration : ",
                                  style: GoogleFonts.poppins(color: subText, fontSize: 13.sp),
                                ),
                                Expanded(
                                  child: Text(
                                    formatDate(dashboardData?['expiry_date'] ?? ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: subText,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if(dashboardData?['expiry_date'] != null)      const SizedBox(height: 6),

                            /// Stats
                            Row(
                              children: [
                                _statBox(
                                  context,
                                  dashboardData?['remaining_data'] ?? '',
                                  "Data Left",
                                  AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                _statBox(
                                  context,
                                  dashboardData?['remaining_uptime'] ?? '',
                                  "Uptime",
                                  AppColors.teal,
                                ),
                                const SizedBox(width: 10),
                                _statBox(
                                  context,
                                  dashboardData?['remaining_expiration'] ?? '',
                                  "Days Left",
                                  AppColors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // const SizedBox(height: 20),
                        if (dashboardData?['due_amount'] != 0 && dashboardData?['due_amount'] != '0.00' && isDue == "1")
                          Container(
                            padding: EdgeInsets.all(10.r),
                            margin: EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: isDark ? AppColors.orange.withOpacity(.35) : AppColors.orange.withOpacity(.20),
                              ),
                              // gradient: isDark
                              //     ? LinearGradient(
                              //         begin: Alignment.centerLeft,
                              //         end: Alignment.centerRight,
                              //         colors: [
                              //           AppColors.orange.withOpacity(.1),
                              //           AppColors.darkCard1,
                              //         ],
                              //       )
                              //     : null,
                              color: AppColors.orange.withOpacity(.1),
                            ),
                            child: Row(
                              children: [
                                /// Icon Box
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.orange.withOpacity(.15) : AppColors.orange.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.payments_outlined,
                                    color: AppColors.orange,
                                    size: 24.sp,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                /// Amount Section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Due Amount",
                                        style: GoogleFonts.poppins(
                                          color: isDark ? Colors.white70 : AppColors.textLight,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "${AppConfig.siteCurrency} ${dashboardData?['due_amount'] ?? '0'}",
                                        style: GoogleFonts.poppins(
                                          color: AppColors.orange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// Pay Button
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => PayDueAmountScreen(dueAmount: dashboardData?['due_amount'] ?? '0')));
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.orange.withOpacity(.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "Pay Now",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                      /// RECHARGE BUTTON
                      if (hasRecharge)
                        Padding(
                          padding: EdgeInsetsGeometry.only(top: 16),
                          child: PrimaryButton(
                            title: "Recharge Now",
                            icon: Icons.alt_route,
                            height: 46,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => RechargeScreen(isBack: true)));
                            },
                          ),
                        ),
                      const SizedBox(height: 16),

                      /// QUICK ACTIONS
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Quick Actions",
                          style: GoogleFonts.poppins(color: text, fontSize: 15.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              // onTap: () {
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (context) => InvoiceScreen(),
                              //     ),
                              //   );
                              // },
                              onTap: () async {
                                if (await hasPermission("invoice_list")) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen()));
                                } else {
                                  showPermissionAlert();
                                }
                              },
                              child: quickActionCard(Icons.receipt_long, "Invoice", AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              // onTap: () {
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (context) =>
                              //           StatisticsScreen(isBack: true),
                              //     ),
                              //   );
                              // },
                              onTap: () async {
                                if (await hasStatisticsPermission()) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => StatisticsScreen(isBack: true)));
                                } else {
                                  showPermissionAlert();
                                }
                              },
                              child: quickActionCard(Icons.bar_chart, "Statistics", AppColors.green),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (await hasTicketPermission()) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => SupportTicketScreen()));
                                } else {
                                  showPermissionAlert();
                                }
                              },
                              child: quickActionCard(Icons.mail_outline, "Tickets", AppColors.orange),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MoreSettingsScreen()));
                              },
                              child: quickActionCard(Icons.grid_view, "More", Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (nextRechargeData != null && nextRechargeData!['package'] != null)
                        _upcomingRechargeCard(),

                      /// USAGE CARD
                      _usageCard(card, text, isDark),
                      const SizedBox(height: 20),

                      /// RECENT ACTIVITY
                      _recentActivity(card, text, isDark),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _statBox(BuildContext context, String title, String subtitle, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(.05) : Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: GoogleFonts.poppins(color: color, fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),

            // const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget quickActionCard(IconData icon, String title, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12.sp)),
        ],
      ),
    );
  }

  double getDataUsagePercent() {
    final totalGb = double.tryParse(packageData?['data_limit']?.toString() ?? '0') ?? 0;
    final usedText = dashboardData?['today_used_data']?.toString() ?? '0 MB';
    final match = RegExp(r'([\d.]+)').firstMatch(usedText);
    final usedMb = match != null ? double.parse(match.group(1)!) : 0;
    final totalMb = totalGb * 1024;
    if (totalMb <= 0) return 0;
    return (usedMb / totalMb).clamp(0.0, 1.0);
  }

  Color getUsageColor(double usedPercent) {
    final remaining = 1 - usedPercent;
    if (remaining > 0.5) {
      return Colors.green;
    } else if (remaining > 0.2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _usageCard(Color card, Color text, bool isDark) {
    final hasDataLimit = packageData?['data_limiter']?.toString() == "1";
    final progress = getDataUsagePercent();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(.05) : Colors.black.withOpacity(.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Usage",
                style: GoogleFonts.poppins(color: text, fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              if (isStateGeneral == '1' || isBandWidth == '1')
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(isBack: true)));
                  },
                  child: Row(
                    children: [
                      Text("Details ", style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 13.sp)),
                      const Icon(Icons.arrow_forward, size: 15, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 85,
                height: 85,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 85, height: 85, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.usageRingGradient)),
                    Container(width: 67, height: 67, decoration: BoxDecoration(shape: BoxShape.circle, color: card)),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (dashboardData?['today_used_data'] ?? '').replaceFirst(' ', '\n'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _usageRow("Download", dashboardData?['today_download_data'] ?? '0 Bytes', text, isDark),
                    _usageRow("Upload", dashboardData?['today_upload_data'] ?? '0 Bytes', text, isDark),
                    _usageRow("Total Used", dashboardData?['today_used_data'] ?? '0 Bytes', AppColors.primary, isDark, isLast: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _usageRow(
    String title,
    String value,
    Color valueColor,
    bool isDark, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12.sp)),
          Text(value, style: GoogleFonts.poppins(color: valueColor, fontSize: 13.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _upcomingRechargeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white70 : Colors.black54;
    final nextPackage = nextRechargeData?['package'];
    final scheduleId = nextRechargeData?['schedule_id'];
    final plans = nextPackage == null
        ? []
        : [
            {
              "name": nextPackage['package_name'] ?? '',
              "expiry": "${nextPackage['expiration_limit'] ?? ''} ${nextPackage['expiration_limit_unit'] ?? ''}",
              "icon": Icons.move_to_inbox_outlined,
            },
          ];

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.secondary.withOpacity(isDark ? .35 : .25)),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
      ),
      child: Column(
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Upcoming Recharge",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: text, fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UpcomingRechargeScreen()));
                },
                child: Row(
                  children: [
                    Text(
                      "See All ",
                      style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const Icon(Icons.arrow_forward, size: 15, color: AppColors.primary, fontWeight: FontWeight.w700),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// Recharge List
          ListView.builder(
            itemCount: plans.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = plans[index];
              return Row(
                children: [
                  /// Icon Box
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.secondary.withOpacity(.12) : AppColors.secondary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(item["icon"] as IconData, color: AppColors.secondary, size: 28.r),
                  ),
                  const SizedBox(width: 14),

                  /// Package Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["name"] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: AppColors.secondary, fontSize: 14.sp, fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: "Expiration : ", style: GoogleFonts.poppins(color: subText, fontSize: 13.sp)),
                              TextSpan(
                                text: item["expiry"] as String,
                                style: GoogleFonts.poppins(color: subText, fontSize: 12.sp, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// Activate Button
                  if (isAdvance == '1')
                    GestureDetector(
                      onTap: () {
                        // print('scheduleId :: $scheduleId');
                        _showActivateDialog(context, scheduleId);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(.25), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          "Activate",
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.sp),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> advanceRecharge(int scheduleId) async {
    setState(() {
      isActive = true;
    });

    try {
      var payload = {"schedule_id": scheduleId.toString()};

      print("payload :: $payload");

      var response = await BaseClient().post(ACTIVE_ADVANCE_RECHARGE, payload, context);
      setState(() {
        isActive = false;
      });
      print("ACTIVE_ADVANCE_RECHARGE :: $ACTIVE_ADVANCE_RECHARGE");
      print("payload :: $payload");
      print("response :: $response");
      if (response != null && response['status'] == true) {
        TopAlert.show(
          context,
          // title: "Success",
          message: response['message'] ?? "Activate advance recharge successfully",
          type: AlertType.success,
        );
        Navigator.pop(context);
        getDashboard();
        getPermission();
        getActivityLogs();
      } else {
        errToast(response?['message'] ?? "Something went wrong");
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isActive = false;
        });
      }
      // errToast("Error! Something went wrong");
    }
  }

  bool isActive = false;

  void _showActivateDialog(BuildContext context, int scheduleId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withOpacity(.12)),
                      child: const Icon(
                        Icons.alt_route,
                        color: AppColors.secondary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Activate",
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Are you sure you want to activate\nadvanced recharge?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600),
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              setDialogState(() {
                                isActive = true;
                              });
                              await Future.delayed(const Duration(seconds: 2));
                              await advanceRecharge(scheduleId);
                              setDialogState(() {
                                isActive = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              minimumSize: const Size(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isActive
                                ? Center(
                                    child: Lottie.asset(
                                      'assets/animation/loading.json',
                                      height: 45,
                                      repeat: true,
                                      delegates: LottieDelegates(
                                        values: [
                                          ValueDelegate.color(const [
                                            '**',
                                          ], value: Colors.black),
                                        ],
                                      ),
                                    ),
                                  )
                                : Text(
                                    "Activate",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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

  Widget _recentActivity(Color card, Color text, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(.05)
              : Colors.black.withOpacity(.05),
        ),
      ),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Activity",
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecentActivityScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "See All ",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          activities.isEmpty
              ? buildEmptyRecentActivity()
              : Column(
                  children: activities.take(3).map(
                        (item) => Column(
                          children: [
                            _activityItem(
                              icon: getActivityIcon(''),
                              iconColor: AppColors.primary,
                              bgColor: AppColors.primary.withOpacity(.12),
                              title: item['message'] ?? '',
                              date: formatDate(item['created_at']),
                              trailing: item['module_type_name'] ?? '',
                              trailingColor: AppColors.primary,
                              isDark: isDark,
                            ),
                            _divider(isDark),
                          ],
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget buildEmptyRecentActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 40, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              "No Recent Activity",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: text, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "You don't have any recent activity yet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: text.withOpacity(0.7),
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String date,
    required String trailing,
    required Color trailingColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45.w,
            height: 45.h,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 28.r),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  date,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          Text(
            trailing,
            style: TextStyle(
              color: trailingColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1);
  }
}

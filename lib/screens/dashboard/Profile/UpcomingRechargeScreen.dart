import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/Shimmer/UpcomingRechargeShimmer.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';
import '../../../theme/app_colors.dart';

class UpcomingRechargeScreen extends StatefulWidget {
  const UpcomingRechargeScreen({super.key});

  @override
  State<UpcomingRechargeScreen> createState() => _UpcomingRechargeScreenState();
}

class _UpcomingRechargeScreenState extends State<UpcomingRechargeScreen> {
  bool isLoading = false;
  bool isActive = false;
  String isAdvance = '0';
  List<dynamic> rechargeList = [];

  @override
  void initState() {
    super.initState();
    getRechargeList();
    getPermission();
  }

  Future<void> getRechargeList() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient()
        .get(GET_ADVANCE_RECHARGE, context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });
    print('GET_ADVANCE_RECHARGE :: $GET_ADVANCE_RECHARGE');
    print('response :: $response');
    if (response == null) {
      errToast("Error! Something went wrong");
    } else {
      if (response['status'] == true) {
        setState(() {
          rechargeList = response['data'] ?? [];
          isLoading = false;
        });
      } else {
        errToast(response['message']);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getPermission() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
      err,
    ) {
      return null;
    });
    if (!mounted) return;
    if (response != null && response['status'] == true) {
      final permission = response['data'];
      setState(() {
        isAdvance = permission['activate_advance_recharge'] ?? "0";
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDataLimit(String? limit, String? unit) {
    if (limit == null || limit.isEmpty || limit == "0.00") {
      return "Unlimited";
    }
    final double value = double.tryParse(limit) ?? 0;
    if (value == value.roundToDouble()) {
      return "${value.toInt()} ${unit ?? ''}";
    }
    return "${value.toStringAsFixed(1)} ${unit ?? ''}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                CustomAppbar(title: 'Upcoming Recharge'),
                const SizedBox(height: 8),
                Expanded(
                  child: isLoading
                      ? const UpcomingRechargeShimmer()
                      : rechargeList.isEmpty
                      ? buildEmptyRecharge()
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: rechargeList.length,
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final recharge = rechargeList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: card,
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.secondary,
                                    width: 3,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [ Text(
                                          recharge["package"]["package_name"],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: text,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),Spacer(), if (isAdvance == '1')
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: GestureDetector(
                                              onTap: () {
                                                _showActivateDialog(
                                                  context,
                                                  recharge["schedule_id"],
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary,
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                ),
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    "Activate",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),],),
                                        // Text(
                                        //   recharge["package"]["package_name"],
                                        //   maxLines: 1,
                                        //   overflow: TextOverflow.ellipsis,
                                        //   style: GoogleFonts.poppins(
                                        //     color: text,
                                        //     fontSize: 15.sp,
                                        //     fontWeight: FontWeight.w600,
                                        //   ),
                                        // ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _infoColumn(
                                                "Activate On",
                                                recharge["schedule_date"],
                                                text,
                                                greyText,
                                              ),
                                            ),
                                            Expanded(
                                              child: _infoColumn(
                                                "Uptime",
                                                recharge["package"]["uptime_limit"] ==
                                                        '0'
                                                    ? 'Unlimited'
                                                    : recharge["package"]["uptime_limit"],
                                                AppColors.primary,
                                                greyText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _infoColumn(
                                                "Data Limit",
                                                formatDataLimit(
                                                  recharge["package"]["data_limit"],
                                                  recharge["package"]['data_limit_unit'],
                                                ),
                                                AppColors.primary,
                                                greyText,
                                              ),
                                            ),
                                            Expanded(
                                              child: _infoColumn(
                                                "Expiration",
                                                '${recharge["package"]["expiration_limit"]} ${recharge["package"]["expiration_limit_unit"]}',
                                                text,
                                                greyText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // if (isAdvance == '1')
                                        //   Align(
                                        //     alignment: Alignment.centerRight,
                                        //     child: GestureDetector(
                                        //       onTap: () {
                                        //         _showActivateDialog(
                                        //           context,
                                        //           recharge["schedule_id"],
                                        //         );
                                        //       },
                                        //       child: Container(
                                        //         decoration: BoxDecoration(
                                        //           color: AppColors.secondary,
                                        //           borderRadius:
                                        //               BorderRadius.circular(10),
                                        //         ),
                                        //         child: Padding(
                                        //           padding:
                                        //               const EdgeInsets.symmetric(
                                        //                 horizontal: 20.0,
                                        //                 vertical: 10,
                                        //               ),
                                        //           child: Text(
                                        //             "Activate",
                                        //             style: GoogleFonts.poppins(
                                        //               color: Colors.white,
                                        //               fontWeight:
                                        //                   FontWeight.w600,
                                        //               fontSize: 12.sp,
                                        //             ),
                                        //           ),
                                        //         ),
                                        //       ),
                                        //     ),
                                        //   ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptyRecharge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              "No Upcoming Recharge",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: text,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You don't have any Upcoming Plan to\nmake Recharge.",
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

  Widget _infoColumn(
    String title,
    String value,
    Color valueColor,
    Color titleColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(color: titleColor, fontSize: 11.sp),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: valueColor,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> advanceRecharge(int scheduleId) async {
    setState(() {
      isActive = true;
    });
    try {
      var payload = {"schedule_id": scheduleId.toString()};
      print("payload :: $payload");
      var response = await BaseClient().post(
        ACTIVE_ADVANCE_RECHARGE,
        payload,
        context,
      );
      setState(() {
        isActive = false;
      });
      print("ACTIVE_ADVANCE_RECHARGE :: $ACTIVE_ADVANCE_RECHARGE");
      print("payload :: $payload");
      print("response :: $response");
      if (response != null && response['status'] == true) {
        TopAlert.show(
          context,
          message:
              response['message'] ?? "Activate advance recharge successfully",
          type: AlertType.success,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BottomNavScreen()),
        );
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
      errToast("Error! Something went wrong");
    }
  }

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withOpacity(.12),
                      ),
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
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
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
}

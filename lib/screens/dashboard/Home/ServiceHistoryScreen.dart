import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Shimmer/ServiceHistoryShimmer.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final bool isBack;
  const ServiceHistoryScreen({super.key, required this.isBack});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  bool isLoading = false;

  List<dynamic> serviceHistory = [];

  @override
  void initState() {
    super.initState();
    getServiceHistory();
  }

  Future<void> getServiceHistory() async {
    setState(() {
      isLoading = true;
    });

    var response = await BaseClient().get(GET_SERVICE_HISTORY, context).catchError((err) {
          errToast("Something went wrong");
          debugPrint(err.toString());
          return null;
        });

    debugPrint("Service History => $response");

    if (!mounted) return;

    if (response != null && response["status"] == true) {
      setState(() {
        serviceHistory = response["data"]["data"] ?? [];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final card2 = isDark ? AppColors.darkCard2 : AppColors.lightCard2;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
          onRefresh: getServiceHistory,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAppbar(title: "Service History", isBack: widget.isBack),
                SizedBox(height: 6.h),
                Expanded(
                  child: isLoading
                      ? const ServiceHistoryShimmer()
                      : serviceHistory.isEmpty
                      ? buildEmpty()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: serviceHistory.length,
                          itemBuilder: (context, index) {
                            return buildHistoryCard(serviceHistory[index]);
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

  Widget buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white70 : Colors.black54;
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2)),]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 50, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              "No Service History",
              style: GoogleFonts.poppins(color: text, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Your recharge history will appear here.",
              style: GoogleFonts.poppins(color: subText, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildHistoryCard(Map item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;

    String package = item["package"]?["package_name"] ?? "-";

    // String applied = item["applied_on"] ?? "-";
    // String schedule = item["scheduled_on"] ?? "-";
    String applied = (item["applied_on"] ?? "-").toString().split(" ").first;
    String schedule = (item["scheduled_on"] ?? "-").toString().split(" ").first;

    String status = '';
    // String status = item["schedule_status"] == "1" ? "Success" : "Pending";

    String type = "";

    switch (item["schedule_status"].toString()) {
      case "0":
        status = "Pending";
        break;
      case "1":
        status = "Success";
        break;

      case "2":
        status = "Cancel";
        break;

      default:
        status = "-";
    }

    switch (item["type"].toString()) {
      case "1":
        type = "Package Change";
        break;
      case "2":
        type = "Recharge";
        break;
      case "3":
        type = "Advance Recharge";
        break;
      default:
        type = "-";
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  package,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: text, fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: text, thickness: 0.1),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: buildInfo("Applied On", applied)),
              const SizedBox(width: 10),
              Expanded(child: buildInfo("Schedule", schedule)),
            ],
          ),const SizedBox(height: 10),
          Row(
            children: [
              buildTypeBadge(type),
              Spacer(),
              buildStatus(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfo(String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: text.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 0),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatus(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case "success":
        bgColor = AppColors.green.withOpacity(0.12);
        textColor = AppColors.green;
        icon = Icons.check_circle;
        break;

      case "failed":
        bgColor = AppColors.red.withOpacity(0.12);
        textColor = AppColors.red;
        icon = Icons.cancel;
        break;

      case "pending":
        bgColor = Colors.orange.withOpacity(0.12);
        textColor = Colors.orange;
        icon = Icons.schedule;
        break;

      default:
        bgColor = Colors.blue.withOpacity(0.12);
        textColor = Colors.blue;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTypeBadge(String type) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case "Recharge":
        bgColor = Colors.blue.withOpacity(0.12);
        textColor = Colors.blue;
        icon = Icons.flash_on;
        break;

      case "Advance Recharge":
        bgColor = Colors.deepPurple.withOpacity(0.12);
        textColor = Colors.deepPurple;
        icon = Icons.update;
        break;

      case "Package":
        bgColor = AppColors.primary.withOpacity(0.12);
        textColor = AppColors.primary;
        icon = Icons.inventory_2_outlined;
        break;

      default:
        bgColor = Colors.grey.withOpacity(0.12);
        textColor = Colors.grey;
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            type,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

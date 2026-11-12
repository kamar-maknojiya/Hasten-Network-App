import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/RecentActivityShimmer.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  List<dynamic> activities = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  final int perPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getActivityLogs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMoreData) {
        getActivityLogs(isLoadMore: true);
      }
    });
  }

  Future<void> getActivityLogs({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        isLoadingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
        currentPage = 1;
        activities.clear();
      });
    }
    var response = await BaseClient()
        .get("$RECENT_ACTIVITY?page=$currentPage&per_page=$perPage", context)
        .catchError((err) {
          print(err);
          return null;
        });
    if (response != null && response['status'] == true) {
      List newData = response['data']['data'] ?? [];
      setState(() {
        activities.addAll(newData);
        hasMoreData = newData.length == perPage;
        if (hasMoreData) {
          currentPage++;
        }
        isLoading = false;
        isLoadingMore = false;
      });
    } else {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                CustomAppbar(title: 'Recent Activity'),
                Expanded(
                  child: isLoading
                      ? const RecentActivityShimmer()
                      : activities.isEmpty ?buildEmptyRecentActivity(): RefreshIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                          onRefresh: getActivityLogs,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            controller: _scrollController,
                            itemCount: activities.length + (isLoadingMore ? 1 : 0),
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              if (index == activities.length) {
                                return Center(
                                  child: Lottie.asset(
                                    'assets/animation/loading.json',
                                    height: 50,
                                    repeat: true,
                                    delegates: LottieDelegates(values: [ValueDelegate.color(const ['**'], value: AppColors.primary)]),
                                  ),
                                );
                              }

                              final item = activities[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                                decoration: BoxDecoration(
                                  color: card,
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
                                    Text(
                                      item["message"] ?? "",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item["action_by"] ?? "",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: text.withOpacity(0.4),
                                      ),
                                    ),

                                    if ((item["particulars"] ?? "")
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkCard2
                                              : AppColors.lightCard2,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          item["particulars"] ?? "",
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: text.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(.15),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Text(
                                            item["module_type_name"] ?? "",
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        // const Spacer(),
                                        Text(
                                          formatDate(item["created_at"] ?? ""),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: text.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              "No Recent Activity",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: text,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
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
}

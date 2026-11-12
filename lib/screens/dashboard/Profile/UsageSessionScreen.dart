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
import 'package:vision_broadband/widgets/toast_massage.dart';

class UsageSessionScreen extends StatefulWidget {
  const UsageSessionScreen({super.key});

  @override
  State<UsageSessionScreen> createState() => _UsageSessionScreenState();
}

class _UsageSessionScreenState extends State<UsageSessionScreen> {
  bool isLoading = false;
  bool isHistory = false;
  bool showFilter = false;
  List<dynamic> onlineSession = [];
  List<dynamic> usageSession = [];
  String isOnlineShow = '0';
  String isHistoryShow = '0';

  final TextEditingController ipController = TextEditingController();
  final TextEditingController macController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      controller.text =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
    }
  }

  @override
  void initState() {
    super.initState();
    // getOnlineSession();
    getPermission();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && currentPage < lastPage) {
          setState(() {
            isLoadingMore = true;
          });

          getUsageSession(page: currentPage + 1);
        }
      }
    });
  }

  Future<void> getOnlineSession() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient()
        .get(GET_ONLINE_SESSIONS, context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });
    print('GET_ONLINE_SESSIONS :: $GET_ONLINE_SESSIONS');
    print('response :: $response');
    if (response != null && response['status'] == true) {
      if (!mounted) return;
      setState(() {
        onlineSession = response['data']['data'] ?? [];
        isLoading = false;
        print('onlineSession :: $onlineSession');
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  int currentPage = 1;
  int lastPage = 1;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  Future<void> getUsageSession({int page = 1}) async {
    if (page == 1) {
      setState(() {
        isLoading = true;
      });
    }

    String url = "$GET_USAGE_SESSIONS?page=$page&per_page=10";

    if (ipController.text.trim().isNotEmpty) {
      url += "&ip_address=${Uri.encodeComponent(ipController.text.trim())}";
    }

    if (macController.text.trim().isNotEmpty) {
      url += "&mac_address=${Uri.encodeComponent(macController.text.trim())}";
    }

    if (startDateController.text.trim().isNotEmpty) {
      url += "&from_date=${startDateController.text.trim()}";
    }

    if (endDateController.text.trim().isNotEmpty) {
      url += "&to_date=${endDateController.text.trim()}";
    }

    var response = await BaseClient().get(url, context);

    if (response != null && response['status'] == true) {
      final sessions = response['data']['sessions'];
      lastPage = sessions['last_page'] ?? 1;
      final List<dynamic> newData = sessions['data'] ?? [];

      setState(() {
        if (page == 1) {
          usageSession = newData;
        } else {
          usageSession.addAll(newData);
        }

        currentPage = page;
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

  // Future<void> getPermission() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
  //     err,
  //   ) {
  //     return null;
  //   });
  //
  //   if (!mounted) return;
  //
  //   if (response != null && response['status'] == true) {
  //     final permission = response['data'];
  //
  //     setState(() async {
  //       isOnlineShow = permission['statistics_general'] ?? "0";
  //       isHistoryShow = permission['statistics_usage_session'] ?? "0";
  //     });
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

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

      isOnlineShow = permission['statistics_general']?.toString() ?? "0";
      isHistoryShow = permission['statistics_usage_session']?.toString() ?? "0";

      // Decide default tab & call only permitted API
      if (isOnlineShow == "1") {
        isHistory = false;
        await getOnlineSession();
      } else if (isHistoryShow == "1") {
        isHistory = true;
        await getUsageSession(page: 1);
      } else {
        isLoading = false;
      }

      if (mounted) {
        setState(() {});
      }
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
    final text = isDark ? Colors.white : Colors.black;
    final text2 = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: AppScaffold(
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  /// APPBAR
                  CustomAppbar(title: 'Usage & Session'),
                  const SizedBox(height: 16),

                  /// TAB BAR
                  Row(
                    children: [
                      if (isOnlineShow == '1')
                        tabButton(
                          title: "Online",
                          selected: !isHistory,
                          onTap: () {
                            if (isOnlineShow != "1") return;

                            setState(() {
                              isHistory = false;
                            });

                            getOnlineSession();
                          },
                          cardColor: card,
                          textColor: text,
                        ),

                      if (isOnlineShow == '1' && isHistoryShow == '1')
                        const SizedBox(width: 15),

                      if (isHistoryShow == '1')
                        tabButton(
                          title: "History",
                          selected: isHistory,
                          onTap: () {
                            if (isHistoryShow != "1") return;

                            setState(() {
                              isHistory = true;
                              currentPage = 1;
                              lastPage = 1;
                              usageSession.clear();
                            });

                            getUsageSession(page: 1);
                          },
                          cardColor: card,
                          textColor: text,
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (isHistory)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(vertical: 0),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    showFilter = !showFilter;
                                  });
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.filter_alt_outlined,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Filter Sessions",
                                        style: GoogleFonts.poppins(
                                          color: text.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      showFilter
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),

                              if (showFilter) ...[
                                const SizedBox(height: 16),

                                buildTextField(
                                  controller: ipController,
                                  hint: "IP Address",
                                  textClr: text,
                                ),

                                const SizedBox(height: 16),

                                buildTextField(
                                  controller: macController,
                                  hint: "MAC Address",
                                  textClr: text,
                                ),

                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: startDateController,
                                  hint: "Start Date",
                                  textClr: text,
                                  readOnly: true,
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                    if (pickedDate != null) {
                                      startDateController.text =
                                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: endDateController,
                                  hint: "End Date",
                                  textClr: text,
                                  readOnly: true,
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                    if (pickedDate != null) {
                                      endDateController.text =
                                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ), // adjust radius here
                                          ),
                                          minimumSize: const Size(0, 40),
                                        ),
                                        onPressed: () {
                                          getUsageSession();
                                        },
                                        child: Text(
                                          "Apply",
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ), // adjust radius here
                                          ),
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          minimumSize: const Size(0, 40),
                                        ),
                                        onPressed: () {
                                          ipController.clear();
                                          macController.clear();
                                          startDateController.clear();
                                          endDateController.clear();
                                          getUsageSession(); // all records reload
                                        },
                                        child: Text(
                                          "Reset",
                                          style: GoogleFonts.poppins(
                                            color: text,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),

                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                      onRefresh: () async {
                        await getOnlineSession();
                        await getUsageSession();
                      },
                      child: isLoading
                          ? Center(
                              child: Lottie.asset(
                                'assets/animation/loading.json',
                                height: 50,
                                repeat: true,
                                delegates: LottieDelegates(
                                  values: [
                                    ValueDelegate.color(const [
                                      '**',
                                    ], value: AppColors.primary),
                                  ],
                                ),
                              ),
                            )
                          : isHistory
                          ? usageSession.isEmpty
                                ? emptyState(text)
                                : historyView(card, text, greyText, isDark)
                          : onlineSession.isEmpty
                          ? onlineEmptyState(text, text)
                          : onlineView(text, text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget emptyState(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time,
                size: 30,
                color: textColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No Session found.",
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "No Session history found.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: textColor.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget sessionCard(Map<String, dynamic> session) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     session['callingstationid'] ?? '-',
  //                     style: const TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     session['framedipaddress'] ?? '-',
  //                     style: const TextStyle(color: Colors.grey, fontSize: 16),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //
  //             Container(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 16,
  //                 vertical: 8,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: Colors.green.withOpacity(0.15),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Text(
  //                 session['status'] ?? '',
  //                 style: const TextStyle(
  //                   color: Colors.green,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //
  //         const SizedBox(height: 20),
  //
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             _infoColumn("Up Time", session['uptime'] ?? '0 m'),
  //             _infoColumn(
  //               "Up/Down Data",
  //               "↓ ${session['download_data'] ?? '0'} / ↑ ${session['upload_data'] ?? '0'}",
  //             ),
  //             _infoColumn("Total Data", session['total_data'] ?? '0'),
  //           ],
  //         ),
  //
  //         const SizedBox(height: 16),
  //
  //         const Divider(),
  //
  //         const SizedBox(height: 12),
  //
  //         Text(
  //           "Created Date : ${session['acctstarttime'] ?? '-'}",
  //           style: const TextStyle(color: Colors.grey, fontSize: 14),
  //         ),
  //
  //         const SizedBox(height: 8),
  //
  //         Text(
  //           "Updated Date : ${session['acctupdatetime'] ?? '-'}",
  //           style: const TextStyle(color: Colors.grey, fontSize: 14),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _infoColumn(String title, String value, Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget onlineView(Color textColor, Color greyText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final text2 = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;
    return ListView.builder(
      itemCount: onlineSession.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final session = onlineSession[index];
        return GestureDetector(
          onTap: () =>
              showOnlineSessionDialog(session, card, textColor, greyText),
          child: Container(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['callingstationid'] ?? '-',
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session['framedipaddress'] ?? '-',
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        session['status'] ?? '',
                        style: GoogleFonts.poppins(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoColumn("Up Time", session['uptime'] ?? '0 m', text),
                    _infoColumn(
                      "Up/Down Data",
                      "↑ ${session['upload_data'] ?? '0'} / ↓ ${session['download_data'] ?? '0'}",
                      text,
                    ),
                    _infoColumn(
                      "Total Data",
                      session['total_data'] ?? '0',
                      text,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                const Divider(),

                const SizedBox(height: 6),

                Text(
                  "Start Time : ${formatDate(session['acctstarttime'] ?? '-')}",
                  style: GoogleFonts.poppins(
                    color: text.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  "Update Time : ${formatDate(session['acctupdatetime'] ?? '-')}",
                  style: GoogleFonts.poppins(
                    color: text.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget onlineEmptyState(Color textColor, Color greyText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time,
                size: 30,
                color: textColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No active sessions",
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "You're currently offline. Connect to see\nactive sessions here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: textColor.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget historyView(
    Color cardColor,
    Color textColor,
    Color greyText,
    bool isDark,
  ) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: usageSession.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == usageSession.length) {
          return Padding(
            padding: EdgeInsets.all(0),
            child: Center(
              child: Lottie.asset(
                'assets/animation/loading.json',
                height: 50,
                repeat: true,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(const ['**'], value: AppColors.primary),
                  ],
                ),
              ),
            ),
          );
        }
        final session = usageSession[index];
        return GestureDetector(
          onTap: () =>
              showSessionDialog(session, cardColor, textColor, greyText),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
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
              children: [
                Row(
                  children: [
                    Text(
                      'session #${index + 1}',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "See Detail",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                buildRow(
                  "Start Time",
                  formatDate(session['start_time'] ?? '-'),
                  textColor,
                  greyText,
                ),
                buildRow(
                  "Up Time",
                  session['session_time'] ?? '',
                  AppColors.primary,
                  greyText,
                ),
                buildRow(
                  "Download",
                  session['download'] ?? '',
                  textColor,
                  greyText,
                ),
                buildRow(
                  "Upload",
                  session['upload'] ?? '',
                  textColor,
                  greyText,
                ),
                buildRow(
                  "Total Data",
                  session['total_usage'] ?? '',
                  Colors.blue,
                  greyText,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color textClr,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: GoogleFonts.poppins(color: textClr, fontSize: 13.sp),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.poppins(color: textClr, fontSize: 13.sp),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.withOpacity(.08),
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(.3)),
        ),
      ),
    );
  }

  // Widget buildTextField(
  //
  //     {
  //   required TextEditingController controller,
  //   required String hint,
  //   required Color textClr,
  // }) {
  //   return TextField(
  //     controller: controller,
  //     style: GoogleFonts.poppins(color: textClr, fontSize: 13.sp),
  //
  //     decoration: InputDecoration(
  //       labelText: hint,
  //       labelStyle: GoogleFonts.poppins(color: textClr, fontSize: 13.sp),
  //       filled: true,
  //       fillColor: Colors.grey.withOpacity(.08),
  //       contentPadding: EdgeInsets.all(10),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide.none,
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: const BorderSide(color: AppColors.primary),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide(color: Colors.grey.withOpacity(.3)),
  //       ),
  //     ),
  //   );
  // }

  Widget buildRow(String title, String value, Color valueColor, Color textClr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: textClr,
                fontSize: 12,
                // fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget buildPopRow(String title, String value) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
  //   final card = isDark ? AppColors.darkCard : AppColors.lightCard;
  //   final text = isDark ? Colors.white : Colors.black;
  //   final text2 = isDark ? Colors.white : Colors.black;
  //   final greyText = isDark ? Colors.white70 : Colors.black54;
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 6),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: GoogleFonts.poppins(
  //               color: text,
  //               fontSize: 12,
  //               // fontWeight: FontWeight.w300,
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value,
  //             style: GoogleFonts.poppins(
  //               color: text,
  //               fontSize: 13,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget buildPopRow(String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(color: text, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: GoogleFonts.poppins(
                color: text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : isDark
              ? AppColors.darkCard2
              : Colors.white,
          borderRadius: BorderRadius.circular(50.r),
          border: isDark
              ? null
              : Border.all(color: Colors.grey.withOpacity(.15)),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: selected
                  ? Colors.white
                  : isDark
                  ? Colors.white70
                  : Colors.grey.shade600,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void showOnlineSessionDialog(
    Map<String, dynamic> session,
    Color cardColor,
    Color textColor,
    Color greyText,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Session Details",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildPopRow(
                      "Subscriber ID :",
                      session['subscriber_id'] ?? '-',
                    ),
                    buildPopRow("Site ID :", session['site_id'] ?? '-'),
                    buildPopRow(
                      "RadAcct ID :",
                      session['radacctid'].toString() ?? '-',
                    ),
                    buildPopRow(
                      "Session ID :",
                      session['acctsessionid'] ?? '-',
                    ),
                    buildPopRow("Username :", session['username'] ?? '-'),
                    buildPopRow("Status :", session['status'] ?? '-'),
                    const Divider(),
                    buildPopRow(
                      "Start Time :",
                      formatDate(session['acctstarttime'] ?? '-'),
                    ),
                    buildPopRow(
                      "Update Time :",
                      formatDate(session['acctupdatetime'] ?? '-'),
                    ),
                    // buildPopRow(
                    //   "Stop Time :",
                    //   session['acctstoptime']?.toString() ?? '-',
                    // ),
                    // buildPopRow(
                    //   "Session Time :",
                    //   session['acctsessiontime'] ?? '-',
                    //   textColor,
                    //   greyText,
                    // ),
                    buildPopRow("Uptime :", session['uptime'] ?? ''),
                    buildPopRow(
                      "Interval :",
                      session['acctinterval'] == null
                          ? '-'
                          : '${session['acctinterval']} S',
                    ),
                    const Divider(),
                    buildPopRow(
                      "Upload Data :",
                      session['upload_data']?.toString() ?? '-',
                    ),
                    buildPopRow(
                      "Download Data :",
                      session['download_data'] ?? '-',
                    ),
                    buildPopRow("Total Data :", session['total_data'] ?? '-'),
                    buildPopRow(
                      "Input Octets :",
                      session['acctinputoctets'] ?? '-',
                    ),
                    buildPopRow(
                      "Output Octets :",
                      session['acctoutputoctets'] ?? '',
                    ),
                    const Divider(),
                    buildPopRow("NAS IP :", session['nasipaddress'] ?? '-'),
                    buildPopRow("NAS Port ID :", session['nasportid'] ?? '-'),
                    buildPopRow(
                      "NAS Port Type :",
                      session['nasporttype'] ?? '-',
                    ),
                    buildPopRow("Realm :", session['realm'] ?? '-'),
                    buildPopRow(
                      "Service Type :",
                      session['servicetype'] ?? '-',
                    ),
                    const Divider(),
                    buildPopRow(
                      "MAC Address :",
                      session['callingstationid'] ?? '-',
                    ),
                    buildPopRow(
                      "Called Station ID :",
                      session['calledstationid'] ?? '-',
                    ),
                    buildPopRow("Protocol :", session['framedprotocol'] ?? '-'),
                    const Divider(),
                    buildPopRow(
                      "IPv4 Address :",
                      session['framedipaddress'] != ''
                          ? session['framedipaddress']
                          : '-',
                    ),
                    buildPopRow(
                      "IPv6 Address :",
                      session['framedipv6address'].toString() != "null"
                          ? session['framedipv6address']
                          : '-',
                    ),
                    buildPopRow(
                      "IPv6 Prefix :",
                      session['framedipv6prefix'] != ''
                          ? session['framedipv6prefix']
                          : '-',
                    ),
                    buildPopRow(
                      "Delegated IPv6Prefix :",
                      session['delegatedipv6prefix'].toString() != "null"
                          ? session['delegatedipv6prefix']
                          : '-',
                    ),
                    buildPopRow(
                      "Interface ID :",
                      session['framedinterfaceid'] != ''
                          ? session['framedinterfaceid']
                          : '-',
                    ),
                    const Divider(),
                    buildPopRow(
                      "Authentication :",
                      session['acctauthentic'] ?? '-',
                    ),
                    buildPopRow(
                      "Connect Start :",
                      session['connectinfo_start'] ?? '-',
                    ),
                    buildPopRow(
                      "Connect Stop :",
                      session['connectinfo_stop'] != ''
                          ? session['connectinfo_stop']
                          : '-',
                    ),
                    buildPopRow(
                      "Terminate Cause :",
                      session['acctterminatecause'] != ''
                          ? session['acctterminatecause']
                          : '-',
                    ),
                    buildPopRow("Custom Mark :", session['custom_mark'] ?? '-'),

                    SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // adjust radius here
                        ),
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Close",
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

  void showSessionDialog(
    Map<String, dynamic> session,
    Color cardColor,
    Color textColor,
    Color greyText,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Session Details",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildPopRow("Username :", session['username'] ?? '-'),
                    buildPopRow(
                      "Start Time :",
                      formatDate(session['start_time'] ?? '-'),
                    ),
                    buildPopRow(
                      "Stop Time :",
                      formatDate(session['stop_time'] ?? '-'),
                    ),
                    buildPopRow(
                      "Updated Time :",
                      formatDate(session['update_time'] ?? '-'),
                    ),
                    buildPopRow("Uptime :", session['session_time'] ?? '-'),
                    buildPopRow("Download :", session['download'] ?? '-'),
                    buildPopRow("Upload :", session['upload'] ?? '-'),
                    buildPopRow("Total Data :", session['total_data'] ?? '-'),
                    buildPopRow(
                      "NAS :",
                      session['nas']['nasname']?.toString() ?? '-',
                    ),
                    buildPopRow("MAC :", session['callingstationid'] ?? '-'),
                    buildPopRow("Protocol :", session['framedprotocol'] ?? '-'),
                    buildPopRow(
                      "Framed IPv4 :",
                      session['framedipaddress'] != ''
                          ? session['framedipaddress']
                          : '-',
                    ),
                    buildPopRow(
                      "Framed IPv6 Prefix :",
                      session['framedipv6prefix'] != ''
                          ? session['framedipv6prefix']
                          : '-',
                    ),
                    buildPopRow(
                      "Delegated IPv6 Prefix :",
                      session['delegatedipv6prefix'] ?? '-',
                    ),
                    buildPopRow(
                      "Framed IPv6 Address :",
                      session['framedipv6address'] ?? '-',
                    ),
                    buildPopRow(
                      "Framed Interface Id :",
                      session['framedinterfaceid'] != ''
                          ? session['framedinterfaceid']
                          : '-',
                    ),
                    buildPopRow("NAS Port ID :", session['nasportid'] ?? '-'),
                    buildPopRow(
                      "NAS Port Type :",
                      session['nasporttype'] ?? '-',
                    ),
                    buildPopRow(
                      "Called Station Id :",
                      session['calledstationid'] ?? '-',
                    ),
                    buildPopRow(
                      "Terminate Cause :",
                      session['acctterminatecause'] ?? '-',
                    ),
                    SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Close",
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildDialogRow(
    String title,
    String value,
    Color textColor,
    Color greyText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text("$title :", style: TextStyle(color: greyText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

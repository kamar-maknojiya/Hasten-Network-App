import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/PaymentSummaryScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/CacheHelper.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/RechargeShimmerScreen.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class RechargeScreen extends StatefulWidget {
  final bool isBack;
  const RechargeScreen({super.key, this.isBack = false});
  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  int rechargeType = 0;
  final TextEditingController pinController = TextEditingController();
  int selectedPlanTab = 0;
  String verifiedPin = '';
  bool showFilter = true;
  int? selectedFilter;
  int? selectedPackageType; // 0 Regular,1 Topup,2 Speed Booster
  int? selectedServiceType; // 1 Internet,2 OTT,3 IPTV,4 OTT+IPTV
  String? selectedBillingCycle; // monthly,quarterly,yearly

  List<dynamic> packages = [];
  // final rechargeTypes = ["Online", "PIN"];
  final planTabs = ["All", "Monthly", "Quarterly", "Half yearly", "Yearly"];
  final filters = ["Regular", "Topup", "Speed Booster"];
  // List<Map> get filteredPackages {
  //   if (selectedPlanTab == 0) {
  //     return packages;
  //   }
  //   if (selectedPlanTab == 1) {
  //     return packages
  //         .where((e) => e["expiry"].toString().contains("Days"))
  //         .toList();
  //   }
  //   if (selectedPlanTab == 2) {
  //     return [];
  //   }
  //   if (selectedPlanTab == 3) {
  //     return [];
  //   }
  //   return [];
  // }
  List<dynamic> get filteredPackages {
    return packages;
  }

  final serviceTypes = [
    "Internet",
    "Internet + OTT",
    "Internet + IPTV",
    "Internet + OTT + IPTV",
  ];

  final ScrollController _scrollController = ScrollController();

  int currentPage = 1;
  bool hasMoreData = true;
  bool isPaginationLoading = false;

  bool isLoading = false;
  bool pinLoading = false;
  bool rechargeLoading = false;
  bool isFilterLoading = false;
  Map<String, dynamic> pinData = {};
  String currentPackage = '';
  String packageDate = '';
  bool canOnlineRecharge = false;
  bool canPinRecharge = false;

  List<String> rechargeTypes = [];
  @override
  void initState() {
    super.initState();
    loadRechargePermission();
    getPackage();
    getRechargePackage();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isPaginationLoading &&
          hasMoreData) {
        loadMoreData();
      }
    });
  }

  Future<void> loadRechargePermission() async {
    final prefs = await SharedPreferences.getInstance();

    canOnlineRecharge = prefs.getString("recharge_with_online") == "1";
    canPinRecharge = prefs.getString("recharge_pin") == "1";

    rechargeTypes.clear();

    if (canOnlineRecharge) {
      rechargeTypes.add("Online");
    }

    if (canPinRecharge) {
      rechargeTypes.add("PIN");
    }

    rechargeType = 0;

    if (mounted) {
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

  // Future<void> getPackage() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   var response = await BaseClient().get(DASHBOARD, context).catchError((err) {
  //     errToast("Error! Something went wrong");
  //     return null;
  //   });
  //
  //   if (response != null && response['status'] == true) {
  //     if (!mounted) return;
  //     setState(() {
  //       packageDate = response['data']['expiry_date'];
  //       currentPackage = response['data']['packages']['package_name'];
  //       isLoading = false;
  //     });
  //     print('currentPackage :: $currentPackage');
  //     print('packageDate :: $packageDate');
  //   } else {
  //     if (!mounted) return;
  //     setState(() {
  //       isLoading = false;
  //     });
  //     errToast("Dashboard error");
  //   }
  // }

  Future<void> getPackage() async {
    final cache = await CacheHelper.read("dashboard_cache");
    if (cache != null) {
      packageDate = cache['expiry_date'];
      currentPackage = cache['packages']['package_name'];
      print('packageDate :: $packageDate');
      print('currentPackage :: $currentPackage');
    }
  }

  // Future<void> getRechargePackage() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   var response = await BaseClient()
  //       .get(GET_RECHARGE_PACKAGE, context)
  //       .catchError((err) {
  //         errToast("Error! Something went wrong");
  //         return null;
  //       });
  //
  //   if (response != null && response['status'] == true) {
  //     setState(() {
  //       packages = response['data']['data'];
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  Future<void> getRechargePackage({
    int page = 1,
    bool isLoadMore = false,
    int? packageType,
    int? serviceType,
    String? billingCycle,
    bool showLoader = false,
  }) async {
    if (isLoadMore) {
      setState(() {
        isPaginationLoading = true;
      });
    } else if (showLoader) {
      setState(() {
        isFilterLoading = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    try {
      Map<String, dynamic> queryParams = {"page": page, "per_page": 5};

      if (packageType != null) {
        queryParams["package_type"] = packageType;
      }
      if (serviceType != null) {
        queryParams["service_type"] = serviceType;
      }
      if (billingCycle != null &&
          billingCycle.isNotEmpty &&
          billingCycle.toLowerCase() != "all") {
        queryParams["billing_cycle"] = billingCycle;
      }
      String url =
          "$GET_RECHARGE_PACKAGE?${Uri(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString()))).query}";

      var response = await BaseClient().get(url, context).catchError((error) {
        errToast("Something went wrong");
        return null;
      });

      if (response != null && response["status"] == true) {
        setState(() {
          final List<dynamic> newData = response["data"]["data"] ?? [];
          if (isLoadMore) {
            packages.addAll(newData);
          } else {
            packages = newData;
          }
          hasMoreData = newData.length == 5;
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isFilterLoading = false;
        isPaginationLoading = false;
      });
    }
  }

  Future<void> loadMoreData() async {
    currentPage++;

    await getRechargePackage(
      page: currentPage,
      isLoadMore: true,
      packageType: selectedPackageType,
      serviceType: selectedServiceType,
      billingCycle: selectedBillingCycle,
    );
  }

  Future<void> applyFilters() async {
    currentPage = 1;
    hasMoreData = true;
    packages.clear();

    await getRechargePackage(
      page: 1,
      packageType: selectedPackageType,
      serviceType: selectedServiceType,
      billingCycle: selectedBillingCycle,
      showLoader: true,
    );
  }

  Future<void> getPinDetails() async {
    if (pinController.text.trim().isEmpty) {
      errToast('Please enter PIN code');
      return;
    }
    setState(() {
      pinLoading = true;
    });

    final PIN = pinController.text.trim();
    var response = await BaseClient()
        .get('$GET_PIN_DETAILS?pin=$PIN', context)
        .catchError((err) {
          // errToast("Error! Something went wrong");
          print(err);
        });
    print('GET_PIN_DETAILS :: $GET_PIN_DETAILS?pin=$PIN');
    print('response :: $response');
    if (response == null) {
      // errToast("Error! Something went wrong");
    } else {
      if (response['status'] == true) {
        setState(() {
          pinData = response['data'] ?? {};
          verifiedPin = pinController.text.trim();
          pinLoading = false;
        });
      } else {
        errToast(response['message']);
        setState(() {
          pinLoading = false;
        });
      }
    }
  }

  Future<void> rechargeByPin() async {
    setState(() {
      rechargeLoading = true;
    });
    final payLoad = {'pin': verifiedPin};
    var response = await BaseClient()
        .post(RECHARGE_BY_PIN, payLoad, context)
        .catchError((err) {
          // errToast("Error! Something went wrong");
          print(err);
        });
    print('payLoad :: $payLoad');
    print('RECHARGE_BY_PIN :: $RECHARGE_BY_PIN');
    print('response :: $response');
    if (response == null) {
      // errToast("Error! Something went wrong");
    } else {
      if (response['status'] == true) {
        successToast(response['message']);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
          (route) => false,
        );
        setState(() {
          rechargeLoading = false;
        });
      } else {
        successToast(response['message']);
        setState(() {
          rechargeLoading = false;
        });
      }
    }
  }

  String formatUptimeLimit(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "Unlimited";
    }

    final text = value.toString().trim();

    if (text.toLowerCase() == "unlimited") {
      return "Unlimited";
    }

    // Extract number from values like "1.00 GB", "1.27GB"
    final match = RegExp(r'([\d.]+)').firstMatch(text);

    if (match != null) {
      final num gb = double.tryParse(match.group(1)!) ?? 0;

      // Remove trailing .0
      if (gb == gb.roundToDouble()) {
        return "${gb.toInt()} GB";
      }

      return "${gb.toStringAsFixed(1)} GB";
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white60 : Colors.black54;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: AppScaffold(
        child: Scaffold(
          backgroundColor: bg,
          body: isLoading
              ? const RechargeShimmerScreen()
              : SafeArea(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                    // onRefresh: getRechargePackage,
                    onRefresh: applyFilters,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomAppbar(
                            title: "Recharge / Topup",
                            isBack: widget.isBack,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _rechargeTypeTabs(),
                                  const SizedBox(height: 16),
                                  if (rechargeType == 0 && currentPackage.isNotEmpty) ...[
                                    _currentPlanCard(card, text, subText),
                                    SizedBox(height: 16.h),
                                  ],

                                  // if (canOnlineRecharge && rechargeType == 0)
                                  //   _currentPlanCard(card, text, subText),
                                  //
                                  // if (canOnlineRecharge && rechargeType == 0)
                                  //   SizedBox(height: 16.h),
                                  _buildRechargeBody(card, text, subText),
                                  // _rechargeTypeTabs(),
                                  // const SizedBox(height: 16),
                                  // if (rechargeType == 0)
                                  //   _currentPlanCard(card, text, subText),
                                  // if (rechargeType == 0) SizedBox(height: 16.h),
                                  // if (rechargeType == 0)
                                  //   _onlineRechargeView(card, text, subText),
                                  // if (rechargeType == 1)
                                  //   _pinRechargeView(card, text, subText),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRechargeBody(Color card, Color text, Color subText) {
    // Only Online permission
    if (canOnlineRecharge && !canPinRecharge) {
      return _onlineRechargeView(card, text, subText);
    }

    // Only PIN permission
    if (!canOnlineRecharge && canPinRecharge) {
      return _pinRechargeView(card, text, subText);
    }

    // Both permissions
    if (canOnlineRecharge && canPinRecharge) {
      return rechargeType == 0
          ? _onlineRechargeView(card, text, subText)
          : _pinRechargeView(card, text, subText);
    }

    // No permission
    return Center(
      child: Text(
        "Recharge is not available.",
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  // Widget _rechargeTypeTabs() {
  //   return SizedBox(
  //     height: 45,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: rechargeTypes.length,
  //       itemBuilder: (context, index) {
  //         bool selected = rechargeType == index;
  //         return GestureDetector(
  //           onTap: () {
  //             setState(() {
  //               rechargeType = index;
  //             });
  //           },
  //           child: Container(
  //             // width: 115,
  //             margin: const EdgeInsets.only(right: 12),
  //             padding: const EdgeInsets.symmetric(horizontal: 25),
  //             decoration: BoxDecoration(
  //               color: selected ? AppColors.primary : const Color(0xff121A35),
  //               borderRadius: BorderRadius.circular(50),
  //             ),
  //             child: Center(
  //               child: Text(
  //                 rechargeTypes[index],
  //                 style: TextStyle(
  //                   color: selected ? Colors.black : Colors.white70,
  //                   fontSize: 17,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _rechargeTypeTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 35.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rechargeTypes.length,
        itemBuilder: (context, index) {
          bool selected = rechargeType == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                rechargeType = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : isDark
                    ? AppColors.darkCard
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(50.r),
                border: isDark ? null : Border.all(color: Colors.grey.withOpacity(.15)),
              ),
              child: Center(
                child: Text(
                  rechargeTypes[index],
                  style: GoogleFonts.poppins(
                    color: selected
                        ? Colors.white
                        : isDark
                        ? Colors.white70
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _currentPlanCard(Color card, Color text, Color subText) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.orange),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(color: AppColors.orange.withOpacity(.20), borderRadius: BorderRadius.circular(10.r)),
            child: const Icon(Icons.access_time, color: AppColors.orange),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: subText, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "Current : ",
                        style: GoogleFonts.poppins(color: text.withOpacity(0.4), fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: currentPackage,
                        style: GoogleFonts.poppins(color: AppColors.orange, fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: subText, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "Expire : ",
                        style: GoogleFonts.poppins(color: text.withOpacity(0.4), fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: formatDate(packageDate),
                        style: GoogleFonts.poppins(color: text, fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 30.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: planTabs.length,
        itemBuilder: (context, index) {
          bool selected = selectedPlanTab == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selectedPlanTab == index) {
                  selectedPlanTab = 0;
                  selectedBillingCycle = null;
                } else {
                  selectedPlanTab = index;

                  switch (index) {
                    case 1:
                      selectedBillingCycle = "monthly";
                      break;
                    case 2:
                      selectedBillingCycle = "quarterly";
                      break;
                    case 3:
                      selectedBillingCycle = "half_yearly";
                      break;
                    case 4:
                      selectedBillingCycle = "yearly";
                      break;
                    default:
                      selectedBillingCycle = null;
                  }
                }

                applyFilters();
                showFilter = true;
                selectedFilter = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              constraints: BoxConstraints(minWidth: 60.w),
              padding: EdgeInsets.symmetric(horizontal: 16.r),

              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : isDark
                    ? AppColors.darkCard
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Center(
                child: Text(
                  planTabs[index],
                  style: GoogleFonts.poppins(
                    color: selected
                        ? Colors.white
                        : isDark
                        ? Colors.white70
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _onlineRechargeView(Color card, Color text, Color subText) {
    return Column(
      children: [
        _planTabs(),
        const SizedBox(height: 10),
        _filterPackageCard(card, text),
        const SizedBox(height: 10),
        isFilterLoading
            ? Lottie.asset(
                'assets/animation/loading.json',
                height: 50,
                repeat: true,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(const ['**'], value: AppColors.primary),
                  ],
                ),
              )
            : filteredPackages.isEmpty
            ? _noPackageWidget(card, text, subText)
            : Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: filteredPackages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _packageCard(filteredPackages[index], card, text, subText),
                      );
                    },
                  ),

                  if (isPaginationLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
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
                    ),
                ],
              ),
      ],
    );
  }

  Widget _filterPackageCard(Color card, Color text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Filter Package",
                  style: GoogleFonts.poppins(color: text.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showFilter = !showFilter;
                  });
                },
                child: Container(
                  width: 30.w,
                  height: 30.h,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.grid_view_outlined, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          if (showFilter)
            Column(
              children: [
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10.w, // Horizontal spacing
                  runSpacing: 10.h, // Vertical spacing
                  children: List.generate(serviceTypes.length, (index) {
                    bool selected = selectedServiceType == (index + 1);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedServiceType == (index + 1)) {
                            selectedServiceType = null;
                          } else {
                            selectedServiceType = index + 1;
                          }
                        });
                        applyFilters();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100.r),
                          color: selected ? AppColors.primary.withOpacity(.1) : Colors.transparent,
                          border: Border.all(color: selected ? AppColors.primary : Colors.grey.withOpacity(.3)),
                        ),
                        child: Text(
                          serviceTypes[index],
                          style: GoogleFonts.poppins(fontSize: 12.sp, color: selected ? AppColors.primary : Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }),
                ),
                // Column(
                //   children: [
                //     SizedBox(
                //       height: 30.h,
                //       child:
                //           ListView.builder(
                //             scrollDirection: Axis.horizontal,
                //             itemCount: serviceTypes.length,
                //             itemBuilder: (context, index) {
                //               bool selected = selectedServiceType == (index + 1);
                //
                //               return GestureDetector(
                //                 onTap: () {
                //                   setState(() {
                //                     if (selectedServiceType == (index + 1)) {
                //                       selectedServiceType = null;
                //                     } else {
                //                       selectedServiceType = index + 1;
                //                     }
                //                   });
                //
                //                   applyFilters();
                //                 },
                //                 child: Container(
                //                   margin: const EdgeInsets.only(right: 10),
                //                   padding: EdgeInsets.symmetric(horizontal: 12.w),
                //                   decoration: BoxDecoration(
                //                     borderRadius: BorderRadius.circular(100.r),
                //                     color: selected
                //                         ? AppColors.primary.withOpacity(.1)
                //                         : Colors.transparent,
                //                     border: Border.all(
                //                       color: selected
                //                           ? AppColors.primary
                //                           : Colors.grey.withOpacity(.3),
                //                     ),
                //                   ),
                //                   child: Center(
                //                     child: Text(
                //                       serviceTypes[index],
                //                       style: GoogleFonts.poppins(
                //                         fontSize: 12,
                //                         color: selected
                //                             ? AppColors.primary
                //                             : Colors.grey,
                //                         fontWeight: FontWeight.w500,
                //                       ),
                //                     ),
                //                   ),
                //                 ),
                //               );
                //             },
                //           ),
                //     ),
                //   ],
                // ),
              ],
            ),
        ],
      ),
    );
  }

  void _showMoreServiceTypes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(serviceTypes.length, (index) {
              bool selected = selectedServiceType == (index + 1);
              return ChoiceChip(
                label: Text(serviceTypes[index]),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    selectedServiceType = selected ? null : (index + 1);
                  });
                  applyFilters();
                  Navigator.pop(context);
                },
              );
            }),
          ),
        );
      },
    );
  }

  void _showOttPopup(List ottPlatforms) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkCard : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * .70,
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(width: 55, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(.35), borderRadius: BorderRadius.circular(20))),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children: [
                      Icon(Icons.live_tv_rounded, color: AppColors.primary, size: 25),
                      const SizedBox(width: 10),
                      Expanded(child: Text("OTT Platforms", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: text))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          "${ottPlatforms.length}",
                          style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: ottPlatforms.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.96,
                        ),
                    itemBuilder: (context, index) {
                      final ott = ottPlatforms[index];
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
                      final card = isDark ? AppColors.darkCard : AppColors.lightCard;
                      final text = isDark ? Colors.white : Colors.black;
                      return GestureDetector(
                        onTap: () async {},
                        child: Container(
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                                  // color: AppColors.primary.withOpacity(.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.network(
                                  ott["icon"] ?? "",
                                  placeholderBuilder: (_) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  ott["name"] ?? "",
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
                PrimaryButton(
                  title: 'Close',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // void _showOttPopup(List ottPlatforms) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         insetPadding: const EdgeInsets.symmetric(horizontal: 40),
  //         titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
  //         contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
  //         actionsPadding: const EdgeInsets.only(bottom: 16),
  //         title: const Text("OTT Platforms"),
  //         content: SizedBox(
  //           width: 300,
  //           child: Wrap(
  //             spacing: 12,
  //             runSpacing: 12,
  //             children: ottPlatforms.map<Widget>((ott) {
  //               return Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   ClipOval(
  //                     child: SvgPicture.network(
  //                       ott['icon'] ?? '',
  //                       width: 40,
  //                       height: 40,
  //                       placeholderBuilder: (_) => const SizedBox(
  //                         width: 40,
  //                         height: 40,
  //                         child: CircularProgressIndicator(strokeWidth: 2),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     ott['name'] ?? '',
  //                     style: const TextStyle(fontSize: 12),
  //                   ),
  //                 ],
  //               );
  //             }).toList(),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Close"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _packageCard(Map package, Color card, Color text, Color subText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List ottPlatforms = package['ott_platforms'] ?? [];
    final isIptv = package['is_iptv'];
    final isOtt = package['is_ott'];
    final isTaxIncluded = package['tax_included'];

    final bool isActive =
        (package["package_name"] ?? "").toString().trim().toLowerCase() ==
        currentPackage.trim().toLowerCase();
    // final List ottPlatforms = [
    //   'assets/Netflix.jpg',
    //   'assets/Hotstar.jpg',
    //   'assets/Zeeee5.jpg',
    // ];
    return Container(

      // margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.primary : Colors.transparent, width: isActive ? 1 : 0),
        boxShadow:isActive
        ? [
        BoxShadow(
          color: AppColors.primary.withOpacity(.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
          ]: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),


      // decoration: BoxDecoration(
      //   color: card,
      //   borderRadius: BorderRadius.circular(12.r),
      //   border: Border.all(
      //     color: isActive ? AppColors.primary : Colors.transparent,
      //     width: isActive ? 1 : 0,
      //   ),
      //   boxShadow: isActive
      //       ? [
      //           BoxShadow(
      //             color: AppColors.primary.withOpacity(.15),
      //             blurRadius: 10,
      //             offset: const Offset(0, 4),
      //           ),
      //         ]
      //       : [],
      // ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isActive)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 3),
                  ],
                ),
              Expanded(
                child: Text(
                  package["package_name"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _badge("Regular", AppColors.primary),
              const SizedBox(width: 8),
              if ((package["total_fup_policies"].toString() != "0"))
                _badge("FUP", AppColors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Expanded(child: _infoBox("Duration", package["duration"])),
              Expanded(
                child: _infoBox(
                  "Data",
                  package["uptime_limit"] != null &&
                          package["uptime_limit"] != "0.00" &&
                          package["uptime_limit_unit"] != null
                      ? "${double.parse(package["uptime_limit"]).toInt()}${package["uptime_limit_unit"]}"
                      : "Unlimited",
                ),
              ),
              const SizedBox(width: 10),
              // Expanded(child: _infoBox("Traffic", "${package["data_limit"]} ${package["data_limit_unit"]}")),
              Expanded(
                child: _infoBox(
                  "Uptime",
                  package["data_limit"] != null &&
                          package["data_limit"] != "0.00" &&
                          package["data_limit_unit"] != null
                      ? "${double.parse(package["data_limit"]).toInt()}${package["data_limit_unit"]}"
                      : "Unlimited",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  "Expiration",
                  "${package["expiration_limit"]} ${package["expiration_limit_unit"]}",
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Divider(color: Colors.grey.withOpacity(.2)),
          SizedBox(height: 5.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${AppConfig.siteCurrency} ${package["price"] ?? "0"}",
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (isTaxIncluded == "1")
                          Text(
                            "Tax Included",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // if (ottPlatforms.isNotEmpty)
                    Row(
                      children: [
                        if (isOtt != 0) _badge("OTT", AppColors.teal),
                        if (isOtt != 0) const SizedBox(width: 5),
                        if (isIptv != 0) _badge("IPTV", AppColors.primary),
                        if (isIptv != 0) const SizedBox(width: 5),
                        if (ottPlatforms.isNotEmpty)
                          ...ottPlatforms.take(2).map<Widget>((ott) {
                            return GestureDetector(
                              onTap: () {
                                _showOttPopup(ottPlatforms);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SvgPicture.network(
                                    ott['icon'] ?? '',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        if (ottPlatforms.length > 2)
                          InkWell(
                            onTap: () {
                              _showOttPopup(ottPlatforms);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                "+${ottPlatforms.length - 2} more",
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  // color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentSummaryScreen(
                        packageId: package["package_id"],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Text(
                    "Select",
                    style: GoogleFonts.poppins(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // OutlinedButton(
              //   onPressed: () {
              //     // _showPackagePopup(package);
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => PaymentSummaryScreen(
              //           packageId: package["package_id"],
              //         ),
              //       ),
              //     );
              //   },
              //   style: OutlinedButton.styleFrom(
              //     side: const BorderSide(color: AppColors.primary, width: 1),
              //     minimumSize: const Size(50, 32),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //   ),
              //   child: Container(
              //     padding: EdgeInsets.symmetric(horizontal: 20,vertical: 5),
              //     decoration: BoxDecoration(
              //       color: card,
              //       borderRadius: BorderRadius.circular(12.r),
              //       border: Border.all(
              //         color: isActive ? AppColors.primary : Colors.transparent,
              //         width: isActive ? 1 : 0,
              //       ),
              //       boxShadow: isActive
              //           ? [
              //         BoxShadow(
              //           color: AppColors.primary.withOpacity(.15),
              //           blurRadius: 10,
              //           offset: const Offset(0, 4),
              //         ),
              //       ]
              //           : [],
              //     ),
              //     child: Text(
              //       "Select",
              //       style: GoogleFonts.poppins(
              //         color: text,
              //         fontSize: 14,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _infoBox(String title, String value) {
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

  Widget _noPackageWidget(Color card, Color text, Color subText) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_sharp,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            "No Recharge Package",
            style: GoogleFonts.poppins(
              color: text,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You don't have any Plan to make Recharge.",
            style: GoogleFonts.poppins(
              color: subText,
              fontSize: 12.sp,
              // fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinRechargeView(Color card, Color text, Color subText) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recharge By PIN",
                style: GoogleFonts.poppins(
                  color: text.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Enter a PIN to recharge your account instantly.",
                style: GoogleFonts.poppins(
                  color: text.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "* PIN Code",
                style: GoogleFonts.poppins(
                  color: text.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: pinController,
                style: GoogleFonts.poppins(color: text, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Enter PIN Code",
                  hintStyle: GoogleFonts.poppins(color: text, fontSize: 12),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(.08),
                  contentPadding: EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(.3)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                title:
                    pinData.isNotEmpty &&
                        verifiedPin == pinController.text.trim()
                    ? "Verified"
                    : "Verify",
                isLoading: pinLoading,
                height: 50,
                btnClr:
                    pinData.isNotEmpty &&
                        verifiedPin == pinController.text.trim()
                    ? AppColors.green
                    : AppColors.primary,
                icon: Icons.verified_outlined,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  final currentPin = pinController.text.trim();
                  if (pinData.isNotEmpty && verifiedPin == currentPin) {
                    return;
                  }
                  getPinDetails();
                },
              ),
              if (pinData.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.only(top: 0),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoCard(
                            title: "PIN Details",
                            package: pinData['package_name'] ?? '',
                            type: pinData['package_type'] ?? '',
                            speed: pinData['speed'] ?? '',
                            // dataLimit: pinData['data_limit'] ?? '',
                            dataLimit: formatUptimeLimit(pinData['data_limit']),
                            updateLimit: formatUptimeLimit(
                              pinData['uptime_limit'],
                            ),
                            expiryDate: pinData['expiration_limit'] ?? '',
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: PrimaryButton(
                              title: "Recharge Now",
                              icon: Icons.alt_route,
                              isLoading: rechargeLoading,
                              height: 50,
                              onTap: () {
                                rechargeByPin();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required String package,
    required String type,
    required String speed,
    required String dataLimit,
    required String updateLimit,
    required String expiryDate,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        _row("Package", package, text),
        divider(text),
        _row("Type", type, AppColors.primary),
        divider(text),
        _row("Speed", speed, AppColors.primary),
        divider(text),
        _row("Data Limit", dataLimit, text),
        divider(text),
        _row("Update Limit", updateLimit, text),
        divider(text),
        _row("Expiry Date", expiryDate, text),
        divider(text),
      ],
    );
  }

  Widget divider(Color text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: text.withOpacity(.20), height: 1),
    );
  }

  Widget _row(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: color.withOpacity(.8),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

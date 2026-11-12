import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CacheHelper.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/StatisticsShimmerScreen.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';
import 'dart:convert';
import 'dart:typed_data';

class StatisticsScreen extends StatefulWidget {
  final bool isBack;
  const StatisticsScreen({super.key, required this.isBack});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool isEnabled = false;
  List<dynamic> onlineSession = [];

  String selectedSession = "Select Session";
  List<String> sessionList = [];
  String selectedGraphType = "Daily";
  final List<String> graphTypes = [
    "Hourly",
    "Daily",
    "Weekly",
    "Monthly",
    "Yearly",
  ];

  String? selectedFramedIp;
  String? selectedNasIp;
  String? selectedProtocol;

  bool isLoading = false;
  bool isLoadings = false;

  List<FlSpot> downloadPoints = [];
  List<FlSpot> uploadPoints = [];

  double xValue = 0;
  StreamSubscription? trafficSubscription;

  List<FlSpot> downloadSpots = [];
  List<FlSpot> uploadSpots = [];

  double graphIndex = 0;

  String currentDownload = "0 Mbps";
  String currentUpload = "0 Mbps";

  double speedToMbps(String speed) {
    speed = speed.trim();
    if (speed.contains('Mbps')) {
      return double.parse(speed.replaceAll('Mbps', '').trim());
    }
    if (speed.contains('Kbps')) {
      return double.parse(speed.replaceAll('Kbps', '').trim()) / 1024;
    }
    return 0;
  }

  double parseSpeed(String speed) {
    speed = speed.trim();
    if (speed.contains("Mbps")) {
      return double.parse(speed.replaceAll("Mbps", "").trim());
    }
    if (speed.contains("Kbps")) {
      return double.parse(speed.replaceAll("Kbps", "").trim()) / 1024;
    }
    return 0;
  }

  double getMaxY() {
    final values = [
      ...downloadPoints.map((e) => e.y),
      ...uploadPoints.map((e) => e.y),
    ];

    if (values.isEmpty) return 100;

    final maxVal = values.reduce(math.max);

    return maxVal + (maxVal * .15);
  }

  void resetGraph() {
    trafficSubscription?.cancel();

    setState(() {
      downloadPoints.clear();
      uploadPoints.clear();

      xValue = 0;
      currentDownload = "0 Mbps";
      currentUpload = "0 Mbps";
    });
  }

  void updateGraph(Map<String, dynamic> data) {
    final rx = double.tryParse(data["rx"].toString()) ?? 0;
    final tx = double.tryParse(data["tx"].toString()) ?? 0;

    if (rx == 0 && tx == 0) {
      return;
    }

    setState(() {
      currentDownload = data["rxf"];
      currentUpload = data["txf"];

      downloadPoints.add(FlSpot(xValue, rx / 1024));
      uploadPoints.add(FlSpot(xValue, tx / 1024));

      xValue++;

      if (downloadPoints.length > 30) {
        downloadPoints.removeAt(0);
        uploadPoints.removeAt(0);
      }
    });
  }

  String formatBytes(num bytes) {
    const units = ['B/s', 'Kb/s', 'Mb/s', 'Gb/s', 'Tb/s', 'Pb/s'];
    double value = bytes.toDouble();
    int unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value < 10 && unitIndex > 0 ? value.toStringAsFixed(1) : value.toStringAsFixed(0)} ${units[unitIndex]}';
  }

  Future<void> getOnlineSession() async {
    setState(() {
      isLoading = true;
    });

    var response = await BaseClient()
        .get(GET_ONLINE_SESSIONS, context)
        .catchError((err) {
          print(err);
          return null;
        });

    print('GET_ONLINE_SESSIONS :: $GET_ONLINE_SESSIONS');
    print('response :: $response');

    if (response != null && response['status'] == true) {
      final sessions = response['data']['data'] ?? [];

      // Save latest session data
      await CacheHelper.save("online_session_cache", sessions);

      if (!mounted) return;

      setState(() {
        onlineSession = sessions;

        sessionList = List.generate(
          sessions.length,
          (index) =>
              "${sessions[index]['framedipaddress']} - Session ${index + 1}",
        );

        if (sessionList.isNotEmpty) {
          selectedSession = sessionList.first;
          selectedFramedIp = sessions.first['framedipaddress'];
          selectedNasIp = sessions.first['nasipaddress'];
          selectedProtocol = sessions.first['framedprotocol'];

          print("NAS IP :: $selectedNasIp");
          print("FRAMED IP :: $selectedFramedIp");
          print("FRAMED PROTOCOL :: $selectedProtocol");

          getLiveTrafficData();
        }

        isLoading = false;
      });

      print('sessionList :: $sessionList');
    } else {
      // Load cached session data
      final cache = await CacheHelper.read("online_session_cache");

      if (cache != null) {
        final sessions = List<dynamic>.from(cache);

        if (!mounted) return;

        setState(() {
          onlineSession = sessions;

          sessionList = List.generate(
            sessions.length,
            (index) =>
                "${sessions[index]['framedipaddress']} - Session ${index + 1}",
          );

          if (sessionList.isNotEmpty) {
            selectedSession = sessionList.first;
            selectedFramedIp = sessions.first['framedipaddress'];
            selectedNasIp = sessions.first['nasipaddress'];

            getLiveTrafficData();
          }

          isLoading = false;
        });

        errToast(response?['message']);
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        errToast(response?['message']);
      }
    }
  }

  Future<void> getLiveTrafficData() async {
    resetGraph();
    if (selectedNasIp == null ||
        selectedFramedIp == null ||
        selectedProtocol == null) {
      print("Session data not available");
      return;
    }
    await trafficSubscription?.cancel();
    try {
      setState(() {
        isLoading = true;
      });
      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');
      final uri = Uri.parse(LIVE_TRAFFIC_DATA).replace(
        queryParameters: {
          "nas_ip_address": selectedNasIp,
          "framed_ip_address": selectedFramedIp,
          "protocol": selectedProtocol,
        },
      );
      final request = http.Request('GET', uri);
      // final request = http.Request('GET', Uri.parse(LIVE_TRAFFIC_DATA));
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });
      final response = await request.send();
      // print('LIVE_TRAFFIC_DATA :: $LIVE_TRAFFIC_DATA');
      print("LIVE_TRAFFIC_DATA => $uri");
      print('response :: $response');
      setState(() {
        isLoading = false;
      });
      if (response.statusCode == 200) {
        trafficSubscription = response.stream.transform(utf8.decoder).listen((
          event,
        ) {
          try {
            print("STREAM EVENT => $event");
            final lines = event.split('\n');
            for (final line in lines) {
              if (line.startsWith('data:')) {
                final jsonString = line.replaceFirst('data:', '').trim();
                if (jsonString.isEmpty) return;
                final data = jsonDecode(jsonString) as Map<String, dynamic>;
                updateGraph(data);
              }
              // if (line.startsWith('data:')) {
              //   final jsonString = line.replaceFirst('data:', '').trim();
              //   final data = jsonDecode(jsonString) as Map<String, dynamic>;
              //   updateGraph(data);
              // }
            }
          } catch (e) {
            // print("JSON Parse Error => $e");
          }
        });
      } else {
        print("Status Code => ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    trafficSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedGraphType = "Daily";
    init();
  }

  String isStatistics = "0";
  String isUsageSession = "0";
  String isBandWidth = "0";

  Future<void> init() async {
    setState(() {
      isLoading = true;
    });
    await getPermission();
    await getOnlineSession();
    await getUsageSessionReport();
    getMRGTGraphData("d");
    setState(() {
      isLoading = false;
    });
  }

  // Future<void> getPermission() async {
  //   var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((err) {
  //     return null;
  //   });
  //   if (!mounted) return;
  //   if (response != null && response['status'] == true) {
  //     final permission = response['data'];
  //     setState(() {
  //       isStatistics = permission['statistics_general'] ?? "0";
  //       isUsageSession = permission['statistics_usage_session'] ?? "0";
  //       isBandWidth = permission['bandwidth'] ?? "0";
  //     });
  //   }
  // }

  Future<void> getPermission() async {
    var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
      err,
    ) {
      print(err);
      return null;
    });

    if (!mounted) return;

    if (response != null && response['status'] == true) {
      final permission = response['data'];

      // Save latest permission
      await CacheHelper.save("statistics_permission_cache", permission);

      setState(() {
        isStatistics = permission['statistics_general'] ?? "0";
        isUsageSession = permission['statistics_usage_session'] ?? "0";
        isBandWidth = permission['bandwidth'] ?? "0";
      });
    } else {
      // Load cached permission
      final cache = await CacheHelper.read("statistics_permission_cache");

      if (cache != null) {
        setState(() {
          isStatistics = cache['statistics_general'] ?? "0";
          isUsageSession = cache['statistics_usage_session'] ?? "0";
          isBandWidth = cache['bandwidth'] ?? "0";
        });

        errToast(response?['message'] ?? "Showing last saved permissions");
      } else {
        errToast(response?['message'] ?? "No permission data available");
      }
    }
  }

  int quarterTurns = 0;

  Map<String, dynamic>? usageInfo;
  Map<String, dynamic>? usageStatistics;
  Uint8List? mrtgGraphImage;

  Future<void> getUsageSessionReport() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient()
        .get(USAGE_SESSIONS_REPORT, context)
        .catchError((err) {
          print(err);
          return null;
        });
    if (response != null && response['status'] == true) {
      // Save latest data
      await CacheHelper.save("usage_session_cache", {
        "info": response['data']['info_till_now'][0],
        "statistics": response['data']['usage_statistics'][0],
      });
      if (!mounted) return;
      setState(() {
        usageInfo = response['data']['info_till_now'][0];
        usageStatistics = response['data']['usage_statistics'][0];
        isLoading = false;
      });

      print("Sessions : ${usageInfo?['sessions']}");
      print("Uptime : ${usageInfo?['uptime']}");
      print("Monthly Total : ${usageStatistics?['monthly_total']}");
    } else {
      final cache = await CacheHelper.read("usage_session_cache");
      if (cache != null) {
        if (!mounted) return;
        setState(() {
          usageInfo = cache['info'];
          usageStatistics = cache['statistics'];
          isLoading = false;
        });
        errToast(response?['message']);
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        errToast(response?['message']);
      }
    }
  }

  String getMRTGUnit(String graphType) {
    switch (graphType) {
      case "Daily":
        return "d";
      case "Hourly":
        return "h";
      case "Weekly":
        return "w";
      case "Monthly":
        return "m";
      case "Yearly":
        return "y";
      default:
        return "d";
    }
  }

  Future<void> getMRGTGraphData(String MRTGUnit) async {
    setState(() {
      isLoadings = true;
    });
    var response = await BaseClient().get(
      "$MRGT_GRAPH_DATA?mrtg_unit=$MRTGUnit",
      context,
    );

    if (response != null && response['status'] == true) {
      String base64String = response['data'];
      base64String = base64String.replaceFirst("data:image/png;base64,", "");
      if (!mounted) return;
      setState(() {
        mrtgGraphImage = base64Decode(base64String);
        isLoadings = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        isLoadings = false;
      });
    }
  }

  Future<void> refreshData() async {
    resetGraph();
    await getOnlineSession(); // Starts a new stream
    await getUsageSessionReport();

    if (isEnabled) {
      await getMRGTGraphData(getMRTGUnit(selectedGraphType));
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

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
            onRefresh: refreshData,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAppbar(title: "Statistics", isBack: widget.isBack),

                  SizedBox(height: 6.h),
                  Expanded(
                    child: isLoading
                        ? const StatisticsShimmerScreen()
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                /// INTERNET USAGE CARD
                                if (isBandWidth == '1')
                                  Container(
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Internet Usage",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14.sp,
                                                  color: text,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  "MRTG",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14.sp,
                                                    color: text,
                                                  ),
                                                ),
                                                SizedBox(width: 5.w),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      isEnabled = !isEnabled;
                                                      if (isEnabled) {
                                                        selectedGraphType =
                                                            "Daily";
                                                      }
                                                    });
                                                    if (isEnabled) {
                                                      getMRGTGraphData("d");
                                                    }
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    width: 55,
                                                    height: 28,
                                                    padding: EdgeInsets.all(
                                                      3.r,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30.r,
                                                          ),
                                                      color: isEnabled
                                                          ? AppColors.primary
                                                          : Colors
                                                                .grey
                                                                .shade400,
                                                    ),
                                                    child: AnimatedAlign(
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      alignment: isEnabled
                                                          ? Alignment
                                                                .centerRight
                                                          : Alignment
                                                                .centerLeft,
                                                      child: Container(
                                                        width: 23.w,
                                                        height: 25.h,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Text(
                                            //   "MRTG",
                                            //   style: GoogleFonts.poppins(
                                            //     fontSize: 14,
                                            //     color: text,
                                            //   ),
                                            // ),
                                            // SizedBox(width: 6),
                                            // SizedBox(
                                            //   height: 10,
                                            //   child: Switch(
                                            //     activeColor: AppColors.primary,
                                            //     value: isEnabled,
                                            //     onChanged: (v) {
                                            //       setState(() {
                                            //         isEnabled = v;
                                            //         if (v) {
                                            //           selectedGraphType = "Daily";
                                            //         }
                                            //       });
                                            //
                                            //       Future.microtask(() {
                                            //         if (v) {
                                            //           getMRGTGraphData("d");
                                            //         }
                                            //       });
                                            //     },
                                            //     // onChanged: (v) {
                                            //     //   setState(() {
                                            //     //     isEnabled = v;
                                            //     //   });
                                            //     //
                                            //     //   if (v) {
                                            //     //     selectedGraphType = "Daily";
                                            //     //     getMRGTGraphData("d");
                                            //     //   }
                                            //     // },
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                        SizedBox(height: 20.h),

                                        // Align(
                                        //   alignment: Alignment.centerRight,
                                        //   child: TextButton(
                                        //     onPressed: showSessionDetail,
                                        //     child: Text(
                                        //       "See Detail",
                                        //       style: GoogleFonts.poppins(
                                        //         color: AppColors.primary,
                                        //
                                        //         fontWeight: FontWeight.w600,
                                        //       ),
                                        //     ),
                                        //   ),
                                        // ),
                                        // const SizedBox(height: 15),
                                        // if (isBandWidth == '0')
                                        SizedBox(
                                          height: 50.h,
                                          child: DropdownButtonFormField<String>(
                                            value: isEnabled
                                                ? selectedGraphType
                                                : (sessionList.isNotEmpty
                                                      ? selectedSession
                                                      : null),

                                            hint: Text(
                                              "Select Session",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.sp,
                                                color: text,
                                              ),
                                            ),

                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey
                                                      .withOpacity(.3),
                                                ),
                                              ),
                                            ),

                                            items:
                                                (isEnabled
                                                        ? graphTypes
                                                        : sessionList)
                                                    .map(
                                                      (
                                                        e,
                                                      ) => DropdownMenuItem<String>(
                                                        value: e,
                                                        child: Text(
                                                          e,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                color: text,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),

                                            // session na ho to dropdown disable
                                            onChanged:
                                                (!isEnabled &&
                                                    sessionList.isEmpty)
                                                ? null
                                                : (value) {
                                                    if (isEnabled) {
                                                      setState(() {
                                                        selectedGraphType =
                                                            value!;
                                                      });
                                                      getMRGTGraphData(
                                                        getMRTGUnit(value!),
                                                      );
                                                    } else {
                                                      setState(() {
                                                        selectedSession =
                                                            value!;
                                                      });
                                                      final index = sessionList
                                                          .indexOf(value!);
                                                      selectedFramedIp =
                                                          onlineSession[index]['framedipaddress'];
                                                      selectedNasIp =
                                                          onlineSession[index]['nasipaddress'];
                                                      selectedProtocol =
                                                          onlineSession[index]['framedprotocol'];
                                                      resetGraph();
                                                      getLiveTrafficData();
                                                      // downloadPoints.clear();
                                                      // uploadPoints.clear();
                                                      // xValue = 0;
                                                      // trafficSubscription?.cancel();
                                                      // getLiveTrafficData();
                                                    }
                                                  },
                                          ),
                                          // child: DropdownButtonFormField<String>(
                                          //   value: isEnabled
                                          //       ? selectedGraphType
                                          //       : selectedSession,
                                          //
                                          //   decoration: InputDecoration(
                                          //     border: OutlineInputBorder(
                                          //       borderRadius:
                                          //           BorderRadius.circular(12),
                                          //       borderSide: BorderSide.none,
                                          //     ),
                                          //
                                          //     focusedBorder: OutlineInputBorder(
                                          //       borderRadius:
                                          //           BorderRadius.circular(12),
                                          //       borderSide: const BorderSide(
                                          //         color: AppColors.primary,
                                          //       ),
                                          //     ),
                                          //
                                          //     enabledBorder: OutlineInputBorder(
                                          //       borderRadius:
                                          //           BorderRadius.circular(12),
                                          //       borderSide: BorderSide(
                                          //         color: Colors.grey.withOpacity(
                                          //           .3,
                                          //         ),
                                          //       ),
                                          //     ),
                                          //   ),
                                          //
                                          //   items:
                                          //       (isEnabled
                                          //               ? graphTypes
                                          //               : sessionList)
                                          //           .map((e) {
                                          //             return DropdownMenuItem(
                                          //               value: e,
                                          //               child: Text(
                                          //                 e,
                                          //                 style:
                                          //                     GoogleFonts.poppins(
                                          //                       fontSize: 12,
                                          //                       color: text,
                                          //                     ),
                                          //               ),
                                          //             );
                                          //           })
                                          //           .toList(),
                                          //   onChanged: (value) {
                                          //     if (isEnabled) {
                                          //       setState(() {
                                          //         selectedGraphType = value!;
                                          //       });
                                          //
                                          //       getMRGTGraphData(
                                          //         getMRTGUnit(value!),
                                          //       );
                                          //     } else {
                                          //       setState(() {
                                          //         selectedSession = value!;
                                          //       });
                                          //     }
                                          //   },
                                          //   // onChanged: (value) {
                                          //   //   setState(() {
                                          //   //     if (isEnabled) {
                                          //   //       selectedGraphType = value!;
                                          //   //     } else {
                                          //   //       selectedSession = value!;
                                          //   //     }
                                          //   //   });
                                          //   // },
                                          // ),
                                        ),
                                        // if (isBandWidth == '0')
                                        SizedBox(height: 20.h),

                                        /// GRAPH SECTION
                                        // if (isBandWidth == '0')
                                        isEnabled
                                            ? GestureDetector(
                                                onTap: () {
                                                  if (mrtgGraphImage != null) {
                                                    showImagePopup(
                                                      context,
                                                      mrtgGraphImage!,
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  height: 130.h,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: isLoadings
                                                      ? Center(
                                                          child: Lottie.asset(
                                                            'assets/animation/loading.json',
                                                            height: 50,
                                                            repeat: true,
                                                            delegates: LottieDelegates(
                                                              values: [
                                                                ValueDelegate.color(
                                                                  const ['**'],
                                                                  value: AppColors
                                                                      .primary,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      : mrtgGraphImage != null
                                                      ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          child: Image.memory(
                                                            mrtgGraphImage!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Lottie.asset(
                                                            'assets/animation/loading.json',
                                                            height: 50,
                                                            repeat: true,
                                                            delegates: LottieDelegates(
                                                              values: [
                                                                ValueDelegate.color(
                                                                  const ['**'],
                                                                  value: AppColors
                                                                      .primary,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  SizedBox(height: 20.h),

                                                  /// LIVE GRAPH AREA
                                                  Container(
                                                    height: 180.h,
                                                    width: double.infinity,

                                                    child: Stack(
                                                      children: [
                                                        /// HORIZONTAL LINES
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,

                                                          children: List.generate(
                                                            6,
                                                            (
                                                              index,
                                                            ) => Container(
                                                              height: 1,
                                                              color: greyText
                                                                  .withOpacity(
                                                                    .15,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),

                                                        /// FAKE LIVE GRAPH
                                                        SizedBox(
                                                          height: 180,

                                                          child:
                                                              downloadPoints
                                                                  .isEmpty
                                                              ? Center(
                                                                  child: Lottie.asset(
                                                                    'assets/animation/loading.json',
                                                                    height: 50,
                                                                    repeat:
                                                                        true,
                                                                    delegates: LottieDelegates(
                                                                      values: [
                                                                        ValueDelegate.color(
                                                                          const [
                                                                            '**',
                                                                          ],
                                                                          value:
                                                                              AppColors.primary,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                )
                                                              : ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                  child: LineChart(
                                                                    LineChartData(
                                                                      minX:
                                                                          downloadPoints
                                                                              .isEmpty
                                                                          ? 0
                                                                          : downloadPoints.first.x,
                                                                      maxX:
                                                                          downloadPoints
                                                                              .isEmpty
                                                                          ? 30
                                                                          : downloadPoints.last.x,
                                                                      minY: 0,
                                                                      maxY:
                                                                          getMaxY(),
                                                                      borderData:
                                                                          FlBorderData(
                                                                            show:
                                                                                false,
                                                                          ),
                                                                      gridData: FlGridData(
                                                                        show:
                                                                            true,
                                                                        drawVerticalLine:
                                                                            true,
                                                                      ),
                                                                      titlesData: FlTitlesData(
                                                                        rightTitles: const AxisTitles(
                                                                          sideTitles: SideTitles(
                                                                            showTitles:
                                                                                false,
                                                                          ),
                                                                        ),
                                                                        leftTitles: AxisTitles(
                                                                          sideTitles: SideTitles(
                                                                            showTitles:
                                                                                true,
                                                                            reservedSize:
                                                                                50,
                                                                            // interval: getMaxY() / 5,
                                                                            interval: math.max(
                                                                              getMaxY() /
                                                                                  5,
                                                                              1,
                                                                            ),
                                                                            getTitlesWidget:
                                                                                (
                                                                                  value,
                                                                                  meta,
                                                                                ) {
                                                                                  return Text(
                                                                                    formatBytes(
                                                                                      value *
                                                                                          1024,
                                                                                    ).replaceAll(
                                                                                      '/s',
                                                                                      '',
                                                                                    ),
                                                                                    style: GoogleFonts.poppins(
                                                                                      fontSize: 10,
                                                                                      color: greyText,
                                                                                    ),
                                                                                  );
                                                                                },
                                                                            // getTitlesWidget:
                                                                            //     (value, meta) {
                                                                            //       return Text(
                                                                            //         "${value.toStringAsFixed(1)} Mb/s",
                                                                            //         style: GoogleFonts.poppins(
                                                                            //           fontSize: 10,
                                                                            //           color: greyText,
                                                                            //         ),
                                                                            //       );
                                                                            //     },
                                                                          ),
                                                                        ),
                                                                        topTitles: const AxisTitles(
                                                                          sideTitles: SideTitles(showTitles: false),
                                                                        ),
                                                                        bottomTitles: const AxisTitles(
                                                                          sideTitles: SideTitles(showTitles: false),
                                                                        ),
                                                                      ),

                                                                      lineBarsData: [
                                                                        LineChartBarData(
                                                                          spots: downloadPoints,
                                                                          isCurved: true,
                                                                          curveSmoothness: 0.35,
                                                                          preventCurveOverShooting: true,
                                                                          color: AppColors.primary,
                                                                          barWidth: 3,
                                                                          isStrokeCapRound: true,
                                                                          dotData: const FlDotData(show: false),
                                                                          belowBarData: BarAreaData(
                                                                            show: true,
                                                                            gradient: LinearGradient(
                                                                              begin: Alignment.topCenter,
                                                                              end: Alignment.bottomCenter,
                                                                              colors: [
                                                                                AppColors.primary.withOpacity(.35),
                                                                                AppColors.primary.withOpacity(.15),
                                                                                AppColors.primary.withOpacity(.08),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),

                                                                        LineChartBarData(
                                                                          spots: uploadPoints,
                                                                          isCurved: true,
                                                                          curveSmoothness: 0.35,
                                                                          preventCurveOverShooting: true,
                                                                          color: AppColors.teal,
                                                                          barWidth: 2,
                                                                          dotData: const FlDotData(show: false),
                                                                          belowBarData: BarAreaData(
                                                                            show: true,
                                                                            gradient: LinearGradient(
                                                                              begin: Alignment.topCenter,
                                                                              end: Alignment.bottomCenter,
                                                                              colors: [
                                                                                AppColors.teal.withOpacity(.35),
                                                                                AppColors.teal.withOpacity(.15),
                                                                                AppColors.teal.withOpacity(.08),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 20.h),

                                                  /// DOWNLOAD / UPLOAD SPEED
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      legendChip(AppColors.primary, "TX"),
                                                      const SizedBox(width: 12),
                                                      legendChip(AppColors.teal, "RX"),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        currentUpload,
                                                        style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12.sp),
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Text(
                                                        '/',
                                                        style: GoogleFonts.poppins(color: text, fontSize: 12.sp),
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Text(
                                                        currentDownload,
                                                        style: GoogleFonts.poppins(color: AppColors.teal, fontSize: 12.sp),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                  ),
                                if (isBandWidth == '1') SizedBox(height: 16.h),

                                /// INFO TILL NOW
                                if (isStatistics == '1')
                                  _infoCard(
                                    title: "Info Till Now",
                                    sessions: usageInfo?['sessions'] ?? '',
                                    uptime: usageInfo?['uptime'] ?? '',
                                    download: usageInfo?['download'] ?? '',
                                    upload: usageInfo?['upload'] ?? '',
                                    total: usageInfo?['total_up_down'] ?? '',
                                  ),
                                if (isStatistics == '1') SizedBox(height: 16.h),
                                if (isStatistics == '1')
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Usage Statistics",
                                          style: GoogleFonts.poppins(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: text,
                                          ),
                                        ),
                                        SizedBox(height: 6.h),
                                        usageStatCard(
                                          title: "Today",
                                          sessions:
                                              usageStatistics?['daily_sessions'] ??
                                              '',
                                          uptime:
                                              usageStatistics?['daily_uptime'] ??
                                              '',
                                          download:
                                              usageStatistics?['daily_down'] ??
                                              '',
                                          upload:
                                              usageStatistics?['daily_up'] ??
                                              '',
                                          total:
                                              usageStatistics?['daily_total'] ??
                                              '',
                                        ),
                                        SizedBox(height: 10.h),
                                        usageStatCard(
                                          title: "This Week",
                                          sessions:
                                              usageStatistics?['weekly_sessions'] ??
                                              '',
                                          uptime:
                                              usageStatistics?['weekly_uptime'] ??
                                              '',
                                          download:
                                              usageStatistics?['weekly_down'] ??
                                              '',
                                          upload:
                                              usageStatistics?['weekly_up'] ??
                                              '',
                                          total:
                                              usageStatistics?['weekly_total'] ??
                                              '',
                                        ),
                                        SizedBox(height: 10.h),
                                        usageStatCard(
                                          title: "This Month",
                                          sessions:
                                              usageStatistics?['monthly_sessions'] ??
                                              '',
                                          uptime:
                                              usageStatistics?['monthly_uptime'] ??
                                              '',
                                          download:
                                              usageStatistics?['monthly_down'] ??
                                              '',
                                          upload:
                                              usageStatistics?['monthly_up'] ??
                                              '',
                                          total:
                                              usageStatistics?['monthly_total'] ??
                                              '',
                                        ),
                                      ],
                                    ),
                                  ),
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
    );
  }

  Widget legendChip(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        // horizontal: 12,
        vertical: 6,
      ),
      // decoration: BoxDecoration(
      //   color: color.withOpacity(.12),
      //   borderRadius: BorderRadius.circular(20),
      //   border: Border.all(color: color.withOpacity(.4)),
      // ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void showImagePopup(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black,
                        child: IconButton(
                          icon: const Icon(
                            Icons.rotate_right,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              quarterTurns = (quarterTurns + 1) % 4;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      CircleAvatar(
                        backgroundColor: Colors.black,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  Expanded(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5,
                      child: RotatedBox(
                        quarterTurns: quarterTurns,
                        child: Image.memory(imageBytes, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // void showImagePopup(BuildContext context, Uint8List imagePath) {
  //   showDialog(
  //     context: context,
  //     barrierColor: Colors.black87,
  //     builder: (context) {
  //       double rotation = 0;
  //
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return Dialog(
  //             backgroundColor: Colors.transparent,
  //             insetPadding: const EdgeInsets.all(16),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 // Top Actions
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.end,
  //                   children: [
  //                     CircleAvatar(
  //                       backgroundColor: Colors.black,
  //                       child: IconButton(
  //                         icon: const Icon(
  //                           Icons.rotate_right,
  //                           color: Colors.white,
  //                         ),
  //                         onPressed: () {
  //                           setState(() {
  //                             quarterTurns = (quarterTurns + 1) % 4;
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     CircleAvatar(
  //                       backgroundColor: Colors.black,
  //                       child: IconButton(
  //                         icon: const Icon(Icons.close, color: Colors.white),
  //                         onPressed: () => Navigator.pop(context),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //
  //                 const SizedBox(height: 10),
  //
  //                 // Image
  //                 Expanded(
  //                   child: InteractiveViewer(
  //                     child: RotatedBox(
  //                       quarterTurns: quarterTurns,
  //                       child: Image.asset(
  //                         imagePath as String,
  //                         fit: BoxFit.contain,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget detailRow(String title, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),

      child: Row(
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.poppins(fontSize: 13.sp)),
          ),

          Text(
            value,

            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String sessions,
    required String uptime,
    required String download,
    required String upload,
    required String total,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
              color: text,
            ),
          ),
          SizedBox(height: 6.sp),
          _row("Sessions", sessions, text),
          divider(greyText),
          _row("Up Time", uptime, text),
          divider(greyText),
          _row("Download", download, text),
          divider(greyText),
          _row("Upload", upload, text),
          divider(greyText),
          _row("Total", total, AppColors.primary),
        ],
      ),
    );
  }

  Widget usageStatCard({
    required String title,
    required String sessions,
    required String uptime,
    required String download,
    required String upload,
    required String total,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    // final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final card = isDark ? AppColors.darkCard2 : AppColors.lightCard2;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              color: text,
            ),
          ),
          const SizedBox(height: 6),
          _row("Sessions", sessions, text),
          divider(greyText),
          _row("Up Time", uptime, text),
          divider(greyText),
          _row("Download", download, text),
          divider(greyText),
          _row("Upload", upload, text),
          divider(greyText),
          _row("Total", total, AppColors.primary),
        ],
      ),
    );
  }

  Widget divider(Color greyText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Divider(color: greyText.withOpacity(.20), height: 1),
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
                fontSize: 12.sp,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

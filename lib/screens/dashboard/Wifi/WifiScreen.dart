import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/Wifi/EditWifiScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CacheHelper.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/WifiShimmerScreen.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class WifiScreen extends StatefulWidget {
  final bool isBack;
  const WifiScreen({super.key, required this.isBack});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  int selectedTab = 0;

  List<Map<String, dynamic>> wifiList = [];
  List<Map<String, dynamic>> wlanList = [];
  bool isLoading = false;
  bool isRefresh = false;
  bool isReboot = false;
  List<String> tabs = [];
  Map<String, dynamic> wanData = {};
  Map<String, dynamic> wifiData = {};
  Map<String, dynamic> wlanData = {};
  Map<String, dynamic> wanDeviceData = {};

  String acsWifiSetting = "0";
  String updateAcsWifiSetting = "0";
  String acsTraceRoute = "0";
  String acsWlanHost = "0";
  String acsWanSetting = "0";
  String rebootDevice = "0";

  @override
  void initState() {
    super.initState();
    // init();
    getPermission();
  }

  Future<void> init() async {
    setState(() {
      isLoading = true;
    });
    await getPermission();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getPermission() async {
    setState(() {
      isLoading = true;
    });

    var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
      err,
    ) {
      print(err);
      return null;
    });

    if (!mounted) return;

    Map<String, dynamic>? permission;

    if (response != null && response['status'] == true) {
      permission = Map<String, dynamic>.from(response['data']);

      // Save latest permissions
      await CacheHelper.save("permission_cache", permission);
    } else {
      // Load cached permissions
      final cache = await CacheHelper.read("permission_cache");

      if (cache != null) {
        permission = Map<String, dynamic>.from(cache);

        errToast(response?['message'] ?? "Showing last saved permissions");
      }
    }

    if (permission == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    acsWifiSetting = permission['acs_wifi_setting'] ?? "0";
    updateAcsWifiSetting = permission['update_acs_wifi_setting'] ?? "0";
    acsTraceRoute = permission['acs_trace_route'] ?? "0";
    acsWlanHost = permission['acs_wlan_host'] ?? "0";
    acsWanSetting = permission['acs_wan_setting'] ?? "0";
    rebootDevice = permission['reboot_device'] ?? "0";

    tabs.clear();

    List<Future> futures = [];

    if (acsWifiSetting == "1") {
      tabs.add("WIFI");
      futures.add(getWIFIData());
    }

    if (acsWanSetting == "1") {
      tabs.add("WAN");
      futures.add(getWANData());
    }

    if (acsWlanHost == "1") {
      tabs.add("WLAN");
      futures.add(getWLANData());
    }

    await Future.wait(futures);

    if (!mounted) return;

    setState(() {
      selectedTab = 0;
      isLoading = false;
    });
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
  //       acsWifiSetting = permission['acs_wifi_setting'] ?? "0";
  //       updateAcsWifiSetting = permission['update_acs_wifi_setting'] ?? "0";
  //       acsTraceRoute = permission['acs_trace_route'] ?? "0";
  //       acsWlanHost = permission['acs_wlan_host'] ?? "0";
  //       acsWanSetting = permission['acs_wan_setting'] ?? "0";
  //       rebootDevice = permission['reboot_device'] ?? "0";
  //
  //       tabs.clear();
  //
  //       List<Future> futures = [];
  //
  //       if (acsWifiSetting == "1") {
  //         tabs.add("WIFI");
  //         futures.add(getWIFIData());
  //       }
  //
  //       if (acsWanSetting == "1") {
  //         tabs.add("WAN");
  //         futures.add(getWANData());
  //       }
  //
  //       if (acsWlanHost == "1") {
  //         tabs.add("WLAN");
  //         futures.add(getWLANData());
  //       }
  //
  //       await Future.wait(futures);
  //       if (mounted) {
  //         setState(() {
  //           selectedTab = 0;
  //           isLoading = false;
  //         });
  //       }
  //     });
  //
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Widget buildEmpty() {
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
            const Icon(Icons.router, size: 40, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              "Device Not Found",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: text,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Your account doesn't have an assigned device. Please contact support for assistance.",
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

  Future<void> getWANData() async {
    // setState(() {
    //   isLoading = true;
    // });

    final prefs = await SharedPreferences.getInstance();

    try {
      var response = await BaseClient()
          .get(WAN_SETTING_URL, context)
          .catchError((err) {
            print(err);
            return null;
          });

      print('WAN_SETTING_URL :: $WAN_SETTING_URL');
      print('response :: $response');

      if (response != null && response['status'] == true) {
        if (response['data'] is List && (response['data'] as List).isEmpty) {
          setState(() {
            wanDeviceData = {};
            wanData = {};
            // isLoading = false;
          });
          return;
        }

        final data = Map<String, dynamic>.from(response['data']);

        // Save cache
        await prefs.setString('wan_cache', jsonEncode(data));

        if (!mounted) return;

        setState(() {
          wanDeviceData = data;
          wanData = data['wan_data'] ?? {};
          // isLoading = false;
        });

        return;
      }

      /// Warning/Error -> Load cache
      final cache = prefs.getString('wan_cache');

      if (cache != null) {
        final data = Map<String, dynamic>.from(jsonDecode(cache));

        if (!mounted) return;

        setState(() {
          wanDeviceData = data;
          wanData = data['wan_data'] ?? {};
          // isLoading = false;
        });

        errToast(response?['message'] ?? "Showing last saved WAN data");
      } else {
        if (!mounted) return;

        setState(() {
          // isLoading = false;
        });

        errToast(response?['message'] ?? "No WAN data available");
      }
    } catch (e) {
      print("getWANData Error :: $e");

      final cache = prefs.getString('wan_cache');

      if (cache != null) {
        final data = Map<String, dynamic>.from(jsonDecode(cache));

        if (!mounted) return;

        setState(() {
          wanDeviceData = data;
          wanData = data['wan_data'] ?? {};
          // isLoading = false;
        });

        // errToast("Showing last saved WAN data");
      } else {
        if (!mounted) return;

        setState(() {
          // isLoading = false;
        });

        // errToast("Error! Something went wrong");
      }
    }
  }

  Future<void> getWIFIData() async {
    // setState(() {
    //   isLoading = true;
    // });

    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await BaseClient().get(WIFI_SETTING_URL, context);

      print('response :: $response');

      if (response != null && response['status'] == true) {
        final data = Map<String, dynamic>.from(response['data']);
        final dynamic wifiDataResponse = data['wifi_data'];

        List<Map<String, dynamic>> tempWifiList = [];

        if (wifiDataResponse is Map) {
          tempWifiList = wifiDataResponse.values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (wifiDataResponse is List) {
          tempWifiList = wifiDataResponse
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        // Save latest data
        await prefs.setString('wifi_cache', jsonEncode(data));

        setState(() {
          wifiData = data;
          wifiList = tempWifiList;
          // isLoading = false;
        });

        return;
      }

      // Warning/Error -> Load cached data
      final cache = prefs.getString('wifi_cache');

      if (cache != null) {
        final data = Map<String, dynamic>.from(jsonDecode(cache));
        final dynamic wifiDataResponse = data['wifi_data'];

        List<Map<String, dynamic>> tempWifiList = [];

        if (wifiDataResponse is Map) {
          tempWifiList = wifiDataResponse.values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (wifiDataResponse is List) {
          tempWifiList = wifiDataResponse
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        setState(() {
          wifiData = data;
          wifiList = tempWifiList;
          // isLoading = false;
        });

        errToast(response?['message'] ?? "Showing last saved WiFi data");
      } else {
        // setState(() {
        //   isLoading = false;
        // });

        errToast(response?['message'] ?? "No WiFi data available");
      }
    } catch (e) {
      print("getWIFIData Error :: $e");

      // Load cache on exception
      final cache = prefs.getString('wifi_cache');

      if (cache != null) {
        final data = Map<String, dynamic>.from(jsonDecode(cache));
        final dynamic wifiDataResponse = data['wifi_data'];

        List<Map<String, dynamic>> tempWifiList = [];

        if (wifiDataResponse is Map) {
          tempWifiList = wifiDataResponse.values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (wifiDataResponse is List) {
          tempWifiList = wifiDataResponse
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        setState(() {
          wifiData = data;
          wifiList = tempWifiList;
          // isLoading = false;
        });

        // errToast("Showing last saved WiFi data");
      } else {
        // setState(() {
        //   isLoading = false;
        // });

        // errToast("Error! Something went wrong");
      }
    }
  }

  Future<void> getWLANData() async {
    // setState(() {
    //   isLoading = true;
    // });
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await BaseClient().get(WLAN_SETTING_URL, context);
      print('response :: $response');
      if (response != null && response['status'] == true) {
        final data = Map<String, dynamic>.from(response['data']);
        final dynamic wlanDataResponse = data['wlan_host_data'];
        List<Map<String, dynamic>> tempWlanList = [];
        if (wlanDataResponse is Map) {
          tempWlanList = wlanDataResponse.values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (wlanDataResponse is List) {
          tempWlanList = wlanDataResponse
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        // Save latest data
        await prefs.setString('wlan_cache', jsonEncode(data));
        setState(() {
          wlanData = data;
          wlanList = tempWlanList;
          // isLoading = false;
        });
        return;
      }
      // Warning/Error -> Load cached data
      final cache = prefs.getString('wlan_cache');
      if (cache != null) {
        final data = Map<String, dynamic>.from(jsonDecode(cache));
        final dynamic wlanDataResponse = data['wlan_host_data'];
        List<Map<String, dynamic>> tempWlanList = [];
        if (wlanDataResponse is Map) {
          tempWlanList = wlanDataResponse.values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (wlanDataResponse is List) {
          tempWlanList = wlanDataResponse
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        setState(() {
          wlanData = data;
          wlanList = tempWlanList;
          // isLoading = false;
        });
        errToast(response?['message'] ?? "Showing last saved WiFi data");
      } else {
        // setState(() {
        //   isLoading = false;
        // });
      }
    } catch (e) {
      print("getWIFIData Error :: $e");

      // Load cache on exception
      final cache = prefs.getString('wlan_cache');

      if (cache != null) {
        final data = Map<String, dynamic>.from(jsonDecode(cache));
        final dynamic wlanDataResponse = data['wlan_host_data'];

        List<Map<String, dynamic>> tempWlanList = [];

        if (wlanDataResponse is Map) {
          tempWlanList = wlanDataResponse.values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (wlanDataResponse is List) {
          tempWlanList = wlanDataResponse
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        setState(() {
          wlanData = data;
          wlanList = tempWlanList;
          // isLoading = false;
        });

        // errToast("Showing last saved WiFi data");
      } else {
        // setState(() {
        //   isLoading = false;
        // });

        // errToast("Error! Something went wrong");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: isLoading
            ? const WifiShimmerScreen()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                    onRefresh: getPermission,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomAppbar(title: "WiFi Settings", isBack: widget.isBack),
                            if (rebootDevice == "1")
                              GestureDetector(
                                onTap: isReboot ? null : rebootData,
                                child: Container(
                                  height: 32.h,
                                  width: 90.h,
                                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8.r)),
                                  child: Center(
                                    child: isReboot
                                        ? Center(
                                            child: Lottie.asset(
                                              'assets/animation/loading.json',
                                              height: 50,
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
                                            "Reboot",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(tabs.length, (index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: _tabButton(
                                          title: tabs[index],
                                          selected: selectedTab == index,
                                        ),
                                      );
                                    }),
                                    Spacer(),
                                    GestureDetector(
                                      onTap: isRefresh
                                          ? null
                                          : () {
                                              if (tabs[selectedTab] == "WIFI") {
                                                refreshWifiData();
                                              } else if (tabs[selectedTab] ==
                                                  "WAN") {
                                                refreshWanData();
                                              } else if (tabs[selectedTab] ==
                                                  "WLAN") {
                                                refreshWlanData();
                                              }
                                            },
                                      child: Container(
                                        height: 32.h,
                                        width: 70.h,
                                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10.r)),
                                        child: Center(
                                          child: isRefresh
                                              ? Center(
                                                  child: Lottie.asset(
                                                    'assets/animation/loading.json',
                                                    height: 50,
                                                    repeat: true,
                                                    delegates: LottieDelegates(
                                                      values: [
                                                        ValueDelegate.color(
                                                          const ['**'],
                                                          value: Colors.white,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : Icon(Icons.refresh_rounded, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                isRefresh || isReboot
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
                                    : Column(
                                        children: [
                                          if (tabs[selectedTab] == "WIFI")
                                            wifiList.isEmpty
                                                ? buildEmpty()
                                                : buildWifiView(),
                                          if (tabs[selectedTab] == "WAN")
                                            wanData.isEmpty
                                                ? buildEmpty()
                                                : buildWanView(),
                                          if (tabs[selectedTab] == "WLAN")
                                            wlanList.isEmpty
                                                ? buildEmpty()
                                                : buildWlanView(),
                                        ],
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

  ListView buildWanView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 45.sp,
                      height: 45.sp,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.language_outlined,
                        size: 30.r,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "WAN Connection",
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            wanData['wan_connection_status'] ?? '-',
                            style: GoogleFonts.poppins(
                              color: AppColors.red,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: wanData['wan_enable'] == true
                            ? AppColors.green.withOpacity(.1)
                            : AppColors.red.withOpacity(.1),
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Text(
                        wanData['wan_enable'] == true ? "Enable" : "Disable",
                        style: GoogleFonts.poppins(
                          color: wanData['wan_enable'] == true
                              ? AppColors.green
                              : AppColors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),
                buildRow('Username', wanData['wan_username']),
                const SizedBox(height: 16),
                buildRow(
                  'DNS Server',
                  wanData['wan_dns_server'].toString().isNotEmpty
                      ? wanData['wan_dns_server']
                      : '-',
                ),
                const SizedBox(height: 16),
                buildRow(
                  'WAN Name',
                  wanData['wan_name'].toString().isNotEmpty
                      ? wanData['wan_name']
                      : '-',
                ),
                const SizedBox(height: 16),
                buildRow('RX Power', wanData['rx_power']),
                const SizedBox(height: 16),
                buildRow('TX Power', wanData['tx_power']),
                if (wanData['wan_mac_address'] != null)
                  const SizedBox(height: 16),
                if (wanData['wan_mac_address'] != null)
                  buildRow('MAC Address', wanData['wan_mac_address']),
                if (wanData['wan_type'] != null) const SizedBox(height: 16),
                if (wanData['wan_type'] != null)
                  buildRow('Type', wanData['wan_type']),
                if (wanData['wan_connection_type'] != null)
                  const SizedBox(height: 16),
                if (wanData['wan_connection_type'] != null)
                  buildRow('Connection Type', wanData['wan_connection_type']),
              ],
            ),
          ),
        );
      },
    );
  }

  ListView buildWifiView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white60 : Colors.black54;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: wifiList.length,
      itemBuilder: (context, index) {
        final wifi = wifiList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12.r),
            border: Border(
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Container(
                          //   width: 42.w,
                          //   height: 42.h,
                          //   decoration: BoxDecoration(color: AppColors.primary.withOpacity(.15), borderRadius: BorderRadius.circular(10.r)),
                          //   child: Icon(Icons.wifi, color: AppColors.primary, size: 28.r),
                          // ),
                          // const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: wifi['enable'] == true
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Text(
                              wifi['enable'] == true ? "Enable" : "Disable",
                              style: GoogleFonts.poppins(
                                color: wifi['enable'] == true ? AppColors.primary : AppColors.red,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (updateAcsWifiSetting == "1")
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: isRefresh
                                    ? null
                                    : () {
                                        print('updateAcsWifiSetting :: $updateAcsWifiSetting');
                                        print('isRefresh :: $isRefresh');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WifiEditScreen(
                                                  device_id: wifiData['device_id'] ?? '',
                                                  device_type: wifiData['device_type'] ?? '',
                                                  ssid_key: wifi['key'] ?? '',
                                                  ssid: wifi['ssid'] ?? '',
                                                  isEnabled: wifi['enable'] ?? '',
                                                ),
                                          ),
                                        );
                                      },
                                child: Icon(Icons.edit, size: 18),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "No",
                                    style: GoogleFonts.poppins(
                                      color: subText,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Text(
                                    wifi["key"]?.toString() ?? "-",
                                    style: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SSID",
                                    style: GoogleFonts.poppins(color: subText, fontSize: 12.sp),
                                  ),
                                  Text(
                                    wifi["ssid"]?.toString() ?? "-",
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 4),
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: Column(
                      //     children: [
                      //       Icon(Icons.edit, size: 20),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ListView buildWlanView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white60 : Colors.black54;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: wlanList.length,
      itemBuilder: (context, index) {
        final wlanHost = wlanList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12.r),
            border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: wlanHost['active'] == true ? AppColors.primary.withOpacity(0.1) : AppColors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Text(
                              wlanHost['active'] == true ? "Active" : "Inactive",
                              style: GoogleFonts.poppins(
                                color: wlanHost['active'] == true ? AppColors.primary : AppColors.red,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12.r)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "No",
                                    style: GoogleFonts.poppins(color: subText, fontSize: 12.sp),
                                  ),
                                  Text(
                                    wlanHost["key"]?.toString() ?? "-",
                                    style: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Host Name",
                                    style: GoogleFonts.poppins(color: subText, fontSize: 12.sp),
                                  ),
                                  SelectableText(
                                    wlanHost["host_name"]?.toString() ?? "-",
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "IP Address",
                                    style: GoogleFonts.poppins(color: subText, fontSize: 12.sp),
                                  ),
                                  SelectableText(
                                    wlanHost["ip_address"]?.toString() ?? "-",
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "MAC Address",
                                    style: GoogleFonts.poppins(color: subText, fontSize: 12.sp),
                                  ),
                                  SelectableText(
                                    wlanHost["Phys_address"]?.toString() ?? "-",
                                    style: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> rebootData() async {
    setState(() {
      isReboot = true;
    });
    try {
      var payload = {"device_id": wifiData['device_id'] ?? ''};
      var response = await BaseClient().post(
        REBOOT_DEVICE_URL,
        payload,
        context,
      );
      setState(() {
        isReboot = false;
      });
      if (response != null && response['status'] == true) {
        successToast(response['message']);
        // await getWIFIData();
      } else {
        errToast(response?['message'] ?? "Something went wrong");
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isReboot = false;
        });
      }
      errToast("Error! Something went wrong");
    }
  }

  Future<void> refreshWifiData() async {
    setState(() {
      isRefresh = true;
    });
    try {
      var payload = {
        "device_id": wifiData['device_id'] ?? '',
        "device_type": wifiData['device_type'] ?? '',
        "vendor": wifiData['vendor'] ?? '',
      };
      var response = await BaseClient().post(
        REFRESH_WIFI_DATA,
        payload,
        context,
      );
      setState(() {
        isRefresh = false;
      });
      if (response != null && response['status'] == true) {
        successToast(response['message']);
        // await getWIFIData();
      } else {
        errToast(response?['message'] ?? "Something went wrong");
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isRefresh = false;
        });
      }
      errToast("Error! Something went wrong");
    }
  }

  Future<void> refreshWanData() async {
    setState(() {
      isRefresh = true;
    });
    try {
      var payload = {
        "device_id": wanDeviceData['device_id'] ?? '',
        "device_type": wanDeviceData['device_type'] ?? '',
        "vendor": wanDeviceData['vendor'] ?? '',
      };
      var response = await BaseClient().post(
        REFRESH_WAN_DATA,
        payload,
        context,
      );
      setState(() {
        isRefresh = false;
      });
      if (response != null && response['status'] == true) {
        successToast(response['message']);
        // getWANData();
      } else {
        errToast(response?['message'] ?? "Something went wrong");
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isRefresh = false;
        });
      }

      errToast("Error! Something went wrong");
    }
  }

  Future<void> refreshWlanData() async {
    setState(() {
      isRefresh = true;
    });
    try {
      var payload = {
        "device_id": wlanData['device_id'] ?? '',
        "device_type": wlanData['device_type'] ?? '',
        "vendor": wlanData['vendor'] ?? '',
      };
      var response = await BaseClient().post(
        REFRESH_WLAN_DATA,
        payload,
        context,
      );
      setState(() {
        isRefresh = false;
      });
      if (response != null && response['status'] == true) {
        successToast(response['message']);
      } else {
        errToast(response?['message'] ?? "Something went wrong");
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isRefresh = false;
        });
      }
      errToast("Error! Something went wrong");
    }
  }

  Widget buildRow(String title, dynamic value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: text.withOpacity(0.6),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value?.toString() ?? '-',
            style: GoogleFonts.poppins(
              color: text.withOpacity(0.8),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton({required String title, required bool selected}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isRefresh
          ? null
          : () {
              setState(() {
                selectedTab = tabs.indexOf(title);
              });
            },
      child: Container(
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : isDark
              ? AppColors.darkCard2
              : Colors.white,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: selected
                  ? Colors.white
                  : isDark
                  ? Colors.white70
                  : Colors.grey,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

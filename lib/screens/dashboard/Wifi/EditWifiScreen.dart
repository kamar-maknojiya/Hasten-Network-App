import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class WifiEditScreen extends StatefulWidget {
  final device_id;
  final ssid_key;
  final device_type;
  final ssid;
  final pass_phrase;
  final isEnabled;
  const WifiEditScreen({
    super.key,
    this.device_id,
    this.ssid_key,
    this.device_type,
    this.ssid,
    this.pass_phrase,
    this.isEnabled,
  });

  @override
  State<WifiEditScreen> createState() => _WifiEditScreenState();
}

class _WifiEditScreenState extends State<WifiEditScreen> {
  bool editSSID = false;
  bool editPassword = false;
  bool isWifiEnabled = false;
  bool isLoading = false;

  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    ssidController.text = widget.ssid?.toString() ?? '';
    passwordController.text = widget.pass_phrase?.toString() ?? '';
    isWifiEnabled = widget.isEnabled ?? false;
    print('ssidController :: ${ssidController.text}');
    print('device_id :: ${widget.device_id}');
    print('ssid :: ${widget.ssid}');
    print('device_type :: ${widget.device_type}');
    print('ssid_key :: ${widget.ssid_key}');
  }

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard2 : AppColors.lightCard2;
    final text = isDark ? Colors.white : Colors.black;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                CustomAppbar(title: 'Edit WiFi'),
                const SizedBox(height: 8),

                /// MAIN CARD
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Edit SSID",
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// SSID
                          Text(
                            "SSID",
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Checkbox(
                                value: editSSID,
                                activeColor: AppColors.primary,
                                onChanged: (v) {
                                  setState(() {
                                    editSSID = v!;
                                  });
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: ssidController,
                                  style: GoogleFonts.poppins(
                                    color: text,
                                    fontSize: 13.sp,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Enter SSID Code",
                                    hintStyle: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 13.sp,
                                    ),
                                    filled: true,
                                    enabled: editSSID,
                                    fillColor: Colors.grey.withOpacity(.08),
                                    contentPadding: EdgeInsets.all(10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          /// PASSWORD
                          Text(
                            "Password",
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Checkbox(
                                value: editPassword,
                                activeColor: AppColors.primary,
                                onChanged: (v) {
                                  setState(() {
                                    editPassword = v!;
                                  });
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: passwordController,
                                  style: GoogleFonts.poppins(
                                    color: text,
                                    fontSize: 13.sp,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Enter Password Code",
                                    hintStyle: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 13.sp,
                                    ),
                                    filled: true,
                                    enabled: editPassword,
                                    fillColor: Colors.grey.withOpacity(.08),
                                    contentPadding: EdgeInsets.all(10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          /// WIFI STATUS
                          Text(
                            "WiFi Status",
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(.08),
                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Enabled",
                                    style: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                Switch(
                                  value: isWifiEnabled,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) {
                                    setState(() {
                                      isWifiEnabled = v;
                                      print('isWifiEnabled :: $isWifiEnabled');
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35),

                          /// SAVE BUTTON
                          PrimaryButton(
                            title: 'Save',
                            icon: Icons.save,
                            isLoading: isLoading,
                            onTap: updateWifiData,
                          ),
                        ],
                      ),
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

  Future<void> updateWifiData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // var payload = {
      //   "device_id": widget.device_id.toString(),
      //   "ssid_key": widget.ssid_key.toString(),
      //   "device_type": widget.device_type.toString(),
      //   "wifi_enabled": isWifiEnabled ? true : false,
      //   "ssid": ssidController.text.trim(),
      //   "pass_phrase": passwordController.text.trim(),
      // };
      Map<String, dynamic> payload = {
        "device_id": widget.device_id,
        "ssid_key": widget.ssid_key,
        "device_type": widget.device_type,
        "wifi_enabled": isWifiEnabled,
      };
      if (editSSID) {
        payload["ssid"] = ssidController.text.trim();
      }
      if (editPassword &&
          passwordController.text.trim().isNotEmpty) {
        payload["pass_phrase"] = passwordController.text.trim();
      }
      print('payload :: $payload');
      var response = await BaseClient().postB(
        UPDATE_WIFI_DATA,
        payload,
        context,
      );
      setState(() {
        isLoading = false;
      });
      if (response != null && response['status'] == true) {
        successToast(response['message']);
        Navigator.pop(context);
      } else {
        errToast(response?['message'] ?? "Something went wrong");
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      errToast("Error! Something went wrong");
    }
  }
}

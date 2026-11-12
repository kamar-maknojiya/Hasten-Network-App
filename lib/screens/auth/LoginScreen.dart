import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;
  String fcmToken = '';
  String deviceId = '';
  String? usernameError;
  String? passwordError;
  Box? box1;

  @override
  void initState() {
    super.initState();
    initDeviceId();
    createBox();
  }

  Future<void> initDeviceId() async {
    deviceId = await getDeviceId();
    if (deviceId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', deviceId);
    }
    print("DEVICE ID :: $deviceId");
  }

  void createBox() async {
    await Hive.initFlutter();
    box1 = await Hive.openBox("login data");
    getData();
  }

  Future<void> getData() async {
    if (box1?.get("userName") != null) {
      usernameController.text = box1?.get("userName");
    }
    if (box1?.get("password") != null) {
      passwordController.text = box1?.get("password");
      rememberMe = true;
    }
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission();

      print("Permission: ${settings.authorizationStatus}");

      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print("APNS Token: $apnsToken");

      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $fcmToken");

      fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      print("fcmToken :: $fcmToken");
    } catch (e) {
      print("FCM token error: $e");
      fcmToken = '';
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  SizedBox(height: 100.h),


                  Center(
                    child: Image.asset(
                      "assets/LogoApp.png",
                      width: 220.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 60.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12.r)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Login Subscriber",
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        /// USERNAME
                        Text(
                          "Username",
                          style: GoogleFonts.poppins(
                            color: text.withOpacity(.75),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: usernameController,
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 13.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter username",
                            filled: true,
                            fillColor: Colors.grey.withOpacity(.08),
                            contentPadding: EdgeInsets.all(10.r),
                            hintStyle: GoogleFonts.poppins(
                              color: text,
                              fontSize: 13.sp,
                            ),
                            errorText: usernameError,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),

                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: AppColors.red),
                            ),

                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: AppColors.red),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                usernameError = null;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16.h),

                        /// PASSWORD
                        Text(
                          "Password",
                          style: GoogleFonts.poppins(
                            color: text.withOpacity(.75),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 13.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter Password",
                            filled: true,
                            fillColor: Colors.grey.withOpacity(.08),
                            contentPadding: EdgeInsets.all(10.r),
                            hintStyle: GoogleFonts.poppins(
                              color: text,
                              fontSize: 13.sp,
                            ),
                            errorText: passwordError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: AppColors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: AppColors.red),
                            ),

                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: text.withOpacity(.65),
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),

                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                passwordError = null;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16.h),

                        /// REMEMBER
                        Row(
                          children: [
                            Checkbox(
                              activeColor: AppColors.primary,
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),
                            Text(
                              "Remember Me",
                              style: GoogleFonts.poppins(
                                color: text,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// LOGIN BUTTON
                        PrimaryButton(
                          title: 'Login',
                          isLoading: isLoading,
                          onTap: () {
                            login();
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  Future<void> login() async {

    // NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    //
    // print("Permission: ${settings.authorizationStatus}");
    //
    // String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    // print("APNS Token: $apnsToken");
    //
    // String? fcmToken = await FirebaseMessaging.instance.getToken();
    // print("FCM Token: $fcmToken");

    setState(() {
      usernameError = null;
      passwordError = null;
    });

    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty && password.isEmpty) {
      setState(() {
        usernameError = "Enter Username";
        passwordError = "Enter Password";
      });
      return;
    }

    if (username.isEmpty) {
      setState(() {
        usernameError = "Enter Username";
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        passwordError = "Enter Password";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    if (usernameController.text != "" && passwordController.text != "") {
      var prefs = await SharedPreferences.getInstance();
      var userName = usernameController.text.trim();
      var password = passwordController.text.trim();

      if (rememberMe) {
        box1?.put("userName", userName);
        box1?.put("password", password);
      } else {
        box1?.delete("userName");
        box1?.delete("password");
      }

      var payload = {
        "username": userName,
        "password": password,
        "subscriber_code": "",
      };
      print('payload :: $payload');
      var response = await BaseClient()
          .authPost(LOGIN_URL, payload, context)
          .catchError((err) {
            errToast("Error! Something went wrong");
            print(err);
          });
      if (!mounted) return;
      if (response == null) {
        errToast("Error! Something went wrong");
        setState(() {
          isLoading = false;
        });
      }
      if (response['status'] == true) {
        await prefs.setString('token', response['token']);
        await prefs.setString('site_currency', response['site_setting']['site_currency'] ?? '\$');
        AppConfig.siteCurrency = response['site_setting']['site_currency'] ?? '\$';
        print('siteCurrency :: ${response['site_setting']['site_currency']}');
        await registerDevice();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavScreen()),
        );
          setState(() {
          isLoading = false;
          });
      } else {
        errToast(response['message'] ?? "Error! Something went wrong");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      errToast("Error! Something went wrong");
      setState(() {
        isLoading = false;
      });
    }
  }
  //
  // Future<String> _getDeviceId() async {
  //   final deviceInfo = DeviceInfoPlugin();
  //
  //   if (Platform.isAndroid) {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     return androidInfo.id;
  //   } else {
  //     IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //     return iosInfo.identifierForVendor ?? "";
  //   }
  // }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? savedId = prefs.getString('device_id');

    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    await prefs.setString('device_id', deviceId);

    return deviceId;
  }

  Future<void> registerDevice() async {
    try {
      if (fcmToken.isEmpty) {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      }

      print("FCM TOKEN :: $fcmToken");
      var payload = {
        "device_type": Platform.isAndroid ? "android" : "ios",
        "device_id": deviceId,
        "fcm_token": fcmToken,
      };

      var response = await BaseClient().post(REGISTER_DEVICE, payload, context);

      print("REGISTER DEVICE PAYLOAD :: $payload");
      print("response :: $response");

      if (response != null && response['status'] == true) {
        // print("Device registered successfully");
      } else {
        // errToast(response?['message'] ?? "Device registration failed");
      }
    } catch (e) {
      // print("registerDevice error => $e");
    }
  }
}

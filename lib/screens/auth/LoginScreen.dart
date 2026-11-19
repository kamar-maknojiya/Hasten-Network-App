import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/networking/auth_api.dart';
import 'package:vision_broadband/screens/auth/ForgotPasswordScreen.dart';
import 'package:vision_broadband/screens/auth/OtpLoginScreen.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AuthWidgets.dart';
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

  /// Login with mobile / email (OTP) on the same page
  bool otpMode = false;
  int otpStep = 0; // 0 = enter mobile/email, 1 = enter OTP
  final emailMobileController = TextEditingController();
  final otpController = TextEditingController();
  final _otpFocus = FocusNode();
  String? emailMobileError;
  String? otpError;
  Timer? _otpTimer;
  int resendIn = 0;

  @override
  void dispose() {
    _otpTimer?.cancel();
    emailMobileController.dispose();
    otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;

  /// Site setting login_with_mobile_no_or_email_only:
  /// Username + password are always shown.
  /// true  -> also show "Login with Mobile / Email" (OTP) below the Login button
  /// false -> no OTP login option
  bool otpOnlyLogin = false;
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
    loadLoginMode();
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
                      isDark ? "assets/LogoApp_dark.png" : "assets/LogoApp.png",
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


                        /// LOGIN TYPE SWITCH - only when login with mobile / email is allowed
                        if (otpOnlyLogin) ...[
                          _loginSwitch(isDark, text),
                          SizedBox(height: 16.h),
                        ],

                        if (!otpMode) ...[
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
                            const Spacer(),
                            GestureDetector(
                              onTap: isLoading ? null : openForgotPassword,
                              child: Text(
                                "Forgot Password?",
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
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
                        ] else
                          _otpForm(text),
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



  /// [ Username | Mobile / Email ] - switches the form on the same page
  Widget _loginSwitch(bool isDark, Color text) {
    Widget item(String label, bool active, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: isLoading ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(vertical: 9.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? (isDark ? AppColors.darkCard : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: active ? (isDark ? AppColors.secondary : AppColors.primary) : text.withOpacity(.55),
                  fontSize: 12.5.sp,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(.07) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          item("Username", !otpMode, () => _setOtpMode(false)),
          const SizedBox(width: 3),
          item("Mobile / Email", otpMode, () => _setOtpMode(true)),
        ],
      ),
    );
  }

  void _setOtpMode(bool on) {
    if (otpMode == on) return;
    FocusScope.of(context).unfocus();
    setState(() {
      otpMode = on;
      usernameError = null;
      passwordError = null;
      emailMobileError = null;
      otpError = null;
    });
  }

  /// Mobile / email -> OTP form (same card)
  Widget _otpForm(Color text) {
    if (otpStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthField(
            label: "Mobile Number / Email",
            hint: "e.g. 9876543210",
            controller: emailMobileController,
            keyboardType: TextInputType.emailAddress,
            errorText: emailMobileError,
            onChanged: (_) {
              if (emailMobileError != null) setState(() => emailMobileError = null);
            },
          ),
          SizedBox(height: 6.h),
          Text(
            "We'll send an OTP to your registered mobile number or email.",
            style: GoogleFonts.poppins(color: text.withOpacity(.55), fontSize: 11.sp),
          ),
          SizedBox(height: 20.h),
          PrimaryButton(title: "Send OTP", isLoading: isLoading, onTap: sendLoginOtp),
        ],
      );
    }
    // ---- step 2: B2 design ----
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? Colors.white.withOpacity(.06) : const Color(0xFFF7F9FB);
    final boxBg = isDark ? Colors.white.withOpacity(.08) : const Color(0xFFF3F5F8);
    final accent = isDark ? AppColors.secondary : AppColors.primary;
    final code = otpController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter the 6-digit OTP",
          style: GoogleFonts.poppins(color: text.withOpacity(.75), fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6.h),

        /// number / email row with edit
        Material(
          color: fieldBg,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: isLoading
                ? null
                : () => setState(() {
                      otpStep = 0;
                      otpError = null;
                      _otpTimer?.cancel();
                      resendIn = 0;
                    }),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: text.withOpacity(.08)),
              ),
              child: Row(
                children: [
                  Icon(
                    emailMobile.contains('@') ? Icons.mail_outline_rounded : Icons.smartphone_rounded,
                    size: 18.r,
                    color: text.withOpacity(.5),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      emailMobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: text, fontSize: 13.sp),
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 18.r, color: accent),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),

        /// 6 OTP boxes over one hidden field (paste + SMS autofill work)
        GestureDetector(
          onTap: () => _otpFocus.requestFocus(),
          child: Stack(
            children: [
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 50.h,
                  child: TextField(
                    controller: otpController,
                    focusNode: _otpFocus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (v) {
                      setState(() => otpError = null);
                      if (v.length == 6 && !isLoading) verifyLoginOtp();
                    },
                  ),
                ),
              ),
              Row(
                children: List.generate(6, (i) {
                  final filled = i < code.length;
                  final current = i == code.length && _otpFocus.hasFocus;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 6.w),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 50.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: current ? (isDark ? AppColors.darkCard : Colors.white) : boxBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: otpError != null
                                ? AppColors.red
                                : current
                                    ? accent
                                    : Colors.transparent,
                            width: current || otpError != null ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          filled ? code[i] : '',
                          style: GoogleFonts.poppins(color: text, fontSize: 18.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        /// error (left) + resend (right)
        Row(
          children: [
            Expanded(
              child: otpError != null
                  ? Text(otpError!, style: GoogleFonts.poppins(color: AppColors.red, fontSize: 11.sp))
                  : const SizedBox(),
            ),
            resendIn > 0
                ? Text(
                    "Resend in ${resendIn}s",
                    style: GoogleFonts.poppins(color: text.withOpacity(.45), fontSize: 11.sp),
                  )
                : GestureDetector(
                    onTap: isLoading ? null : sendLoginOtp,
                    child: Text(
                      "Resend OTP",
                      style: GoogleFonts.poppins(color: accent, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
        SizedBox(height: 14.h),
        PrimaryButton(title: "Verify & Login", isLoading: isLoading, onTap: verifyLoginOtp),
      ],
    );
  }

  String? _validateEmailMobile(String v) {
    if (v.isEmpty) return "Enter email or mobile number";
    if (v.contains('@')) {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
      return ok ? null : "Enter a valid email";
    }
    final digits = v.replaceAll(RegExp(r'[\s-]'), '');
    final ok = RegExp(r'^\+?\d{10,13}$').hasMatch(digits);
    return ok ? null : "Enter a valid mobile number";
  }

  String get emailMobile => emailMobileController.text.trim().replaceAll(RegExp(r'[\s-]'), '');

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() => resendIn = 30);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (resendIn <= 1) {
        t.cancel();
        setState(() => resendIn = 0);
      } else {
        setState(() => resendIn--);
      }
    });
  }

  Future<void> sendLoginOtp() async {
    FocusScope.of(context).unfocus();
    final err = _validateEmailMobile(emailMobileController.text.trim());
    if (err != null) {
      setState(() => emailMobileError = err);
      return;
    }
    setState(() {
      emailMobileError = null;
      isLoading = true;
    });

    final res = await AuthApi.post(LOGIN_OTP_SEND_URL, {"email_mobile": emailMobile});
    if (!mounted) return;
    setState(() => isLoading = false);

    if (AuthApi.ok(res)) {
      successToast(AuthApi.message(res, "OTP sent successfully"));
      otpController.clear();
      setState(() => otpStep = 1);
      _startOtpTimer();
    } else {
      errToast(AuthApi.message(res));
    }
  }

  Future<void> verifyLoginOtp() async {
    FocusScope.of(context).unfocus();
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      setState(() => otpError = "Enter the 6 digit OTP");
      return;
    }
    setState(() {
      otpError = null;
      isLoading = true;
    });

    final res = await AuthApi.post(LOGIN_OTP_VERIFY_URL, {
      "email_mobile": emailMobile,
      "otp": otp,
    });
    if (!mounted) return;

    if (AuthApi.ok(res)) {
      _otpTimer?.cancel();
      await onLoginSuccess(Map<String, dynamic>.from(res as Map));
    } else {
      otpController.clear();
      setState(() {
        isLoading = false;
        otpError = AuthApi.message(res, "Invalid OTP");
      });
      _otpFocus.requestFocus();
    }
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
        return;
      }
      if (response['status'] == true) {
        await onLoginSuccess(Map<String, dynamic>.from(response));
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

  /// login_with_mobile_no_or_email_only from the permissions API
  /// (saved after login, kept through logout).
  Future<void> loadLoginMode() async {
    final otpOnly = await LoginMode.isOtpOnly();
    if (mounted) setState(() => otpOnlyLogin = otpOnly);
  }

  /// Shared by password login and OTP login.
  Future<void> onLoginSuccess(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    final token = AuthApi.find(response, 'token')?.toString() ?? '';
    if (token.isEmpty) {
      errToast(AuthApi.message(response, "Login failed. Please try again."));
      if (mounted) setState(() => isLoading = false);
      return;
    }
    final siteSetting = AuthApi.find(response, 'site_setting');
    final currency =
        (siteSetting is Map ? siteSetting['site_currency'] : null)?.toString() ?? '\$';

    await prefs.setString('token', token);
    await prefs.setString('site_currency', currency);
    AppConfig.siteCurrency = currency;
    print('siteCurrency :: $currency');

    await registerDevice();
    if (!mounted) return;
    setState(() => isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavScreen()),
    );
  }

  Future<void> openForgotPassword() async {
    final username = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialUsername: usernameController.text.trim(),
        ),
      ),
    );
    if (!mounted) return;
    if (username is String && username.isNotEmpty) {
      setState(() {
        usernameController.text = username;
        passwordController.clear();
        usernameError = null;
        passwordError = null;
      });
    }
  }

  Future<void> openOtpLogin() async {
    final response = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OtpLoginScreen()),
    );
    if (!mounted) return;
    if (response is Map<String, dynamic>) {
      setState(() => isLoading = true);
      await onLoginSuccess(response);
    }
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

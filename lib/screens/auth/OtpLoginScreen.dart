import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/networking/auth_api.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AuthWidgets.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

/// Login with registered email or mobile number + OTP.
///
/// On success it pops with the server's login response
/// (Map<String, dynamic>), and LoginScreen finishes the login
/// (save token, register device, open dashboard).
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final emailMobileController = TextEditingController();
  final otpController = TextEditingController();

  int step = 0;
  bool isLoading = false;
  String? emailMobileError;
  String? otpError;

  Timer? _timer;
  int resendIn = 0;

  @override
  void dispose() {
    _timer?.cancel();
    emailMobileController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void startTimer() {
    _timer?.cancel();
    setState(() => resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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

  void goBack() {
    if (step > 0 && !isLoading) {
      setState(() {
        step = 0;
        otpError = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  String? validateEmailMobile(String v) {
    if (v.isEmpty) return "Enter email or mobile number";
    if (v.contains('@')) {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
      return ok ? null : "Enter a valid email";
    }
    final digits = v.replaceAll(RegExp(r'[\s-]'), '');
    final ok = RegExp(r'^\+?\d{10,13}$').hasMatch(digits);
    return ok ? null : "Enter a valid mobile number";
  }

  String get emailMobile =>
      emailMobileController.text.trim().replaceAll(RegExp(r'[\s-]'), '');

  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();
    final err = validateEmailMobile(emailMobileController.text.trim());
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
      setState(() => step = 1);
      startTimer();
    } else {
      errToast(AuthApi.message(res));
    }
  }

  Future<void> verifyOtp() async {
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
    setState(() => isLoading = false);

    if (AuthApi.ok(res)) {
      _timer?.cancel();
      Navigator.pop(context, res);
    } else {
      setState(() => otpError = AuthApi.message(res, "Invalid OTP"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? Colors.white : Colors.black;

    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CustomAppbar(title: "Login with OTP", onTap: goBack),
                ),
                if (step == 0)
                  AuthCard(
                    title: "Login with Mobile / Email",
                    subtitle: "Enter your registered mobile number or email. We'll send you an OTP.",
                    children: [
                      AuthField(
                        label: "Mobile Number / Email",
                        hint: "e.g. 9876543210",
                        controller: emailMobileController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: emailMobileError,
                        onChanged: (_) {
                          if (emailMobileError != null) {
                            setState(() => emailMobileError = null);
                          }
                        },
                      ),
                      SizedBox(height: 24.h),
                      PrimaryButton(title: "Send OTP", isLoading: isLoading, onTap: sendOtp),
                    ],
                  ),
                if (step == 1)
                  AuthCard(
                    title: "Enter OTP",
                    subtitle: "We sent a 6 digit OTP to $emailMobile.",
                    children: [
                      AuthField(
                        label: "OTP",
                        hint: "6 digit OTP",
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        errorText: otpError,
                        onChanged: (_) {
                          if (otpError != null) setState(() => otpError = null);
                        },
                      ),
                      SizedBox(height: 24.h),
                      PrimaryButton(title: "Verify & Login", isLoading: isLoading, onTap: verifyOtp),
                      SizedBox(height: 16.h),
                      ResendOtpLink(
                        secondsLeft: resendIn,
                        disabled: isLoading,
                        onResend: sendOtp,
                      ),
                      SizedBox(height: 8.h),
                      Center(
                        child: GestureDetector(
                          onTap: isLoading ? null : goBack,
                          child: Text(
                            "Change mobile / email",
                            style: GoogleFonts.poppins(
                              color: text.withOpacity(.6),
                              fontSize: 12.sp,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

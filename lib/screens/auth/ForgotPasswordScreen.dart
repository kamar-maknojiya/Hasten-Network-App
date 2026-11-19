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

/// Forgot password in 3 steps:
/// 1. Username -> send OTP
/// 2. OTP (+ optional subscriber code) -> reset_token
/// 3. New password -> reset
///
/// Pops with the username (String) when the password was reset.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialUsername;

  const ForgotPasswordScreen({super.key, this.initialUsername = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final usernameController = TextEditingController();
  final subscriberCodeController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  int step = 0;
  bool isLoading = false;
  bool showSubscriberCode = false;
  bool obscureNew = true;
  bool obscureConfirm = true;
  String resetToken = '';

  String? usernameError;
  String? otpError;
  String? newPasswordError;
  String? confirmPasswordError;

  Timer? _timer;
  int resendIn = 0;

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.initialUsername;
  }

  @override
  void dispose() {
    _timer?.cancel();
    usernameController.dispose();
    subscriberCodeController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
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
        step--;
        otpError = null;
        newPasswordError = null;
        confirmPasswordError = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  /// STEP 1 -> send OTP
  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => usernameError = "Enter Username");
      return;
    }
    setState(() {
      usernameError = null;
      isLoading = true;
    });

    final res = await AuthApi.post(FORGOT_PASSWORD_URL, {"username": username});
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

  /// STEP 2 -> verify OTP, get reset_token
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

    final payload = <String, dynamic>{
      "username": usernameController.text.trim(),
      "otp": otp,
    };
    final code = subscriberCodeController.text.trim();
    if (code.isNotEmpty) payload["subscriber_code"] = code;

    final res = await AuthApi.post(VERIFY_FORGOT_OTP_URL, payload);
    if (!mounted) return;
    setState(() => isLoading = false);

    if (AuthApi.ok(res)) {
      final token = AuthApi.find(res, 'reset_token')?.toString() ?? '';
      if (token.isEmpty) {
        errToast("Could not verify OTP. Please try again.");
        return;
      }
      resetToken = token;
      _timer?.cancel();
      setState(() => step = 2);
    } else {
      final msg = AuthApi.message(res, "Invalid OTP");
      // Same username on more than one account -> ask for subscriber code
      if (msg.toLowerCase().contains("subscriber code") ||
          msg.toLowerCase().contains("subscriber_code")) {
        setState(() => showSubscriberCode = true);
      }
      setState(() => otpError = msg);
    }
  }

  /// STEP 3 -> set new password
  Future<void> resetPassword() async {
    FocusScope.of(context).unfocus();
    final pass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    String? passErr;
    String? confirmErr;
    if (pass.isEmpty) {
      passErr = "Enter new password";
    } else if (RegExp(r'\s').hasMatch(pass)) {
      passErr = "Spaces are not allowed";
    }
    if (confirm.isEmpty) {
      confirmErr = "Confirm your password";
    } else if (confirm != pass) {
      confirmErr = "Passwords do not match";
    }
    setState(() {
      newPasswordError = passErr;
      confirmPasswordError = confirmErr;
    });
    if (passErr != null || confirmErr != null) return;

    setState(() => isLoading = true);
    final res = await AuthApi.post(RESET_PASSWORD_OTP_URL, {
      "reset_token": resetToken,
      "new_password": pass,
      "confirm_password": confirm,
    });
    if (!mounted) return;
    setState(() => isLoading = false);

    if (AuthApi.ok(res)) {
      successToast(
        AuthApi.message(res, "Password changed. Please login with your new password."),
      );
      Navigator.pop(context, usernameController.text.trim());
    } else {
      errToast(AuthApi.message(res));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

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
                  child: CustomAppbar(title: "Forgot Password", onTap: goBack),
                ),
                if (step == 0) _usernameStep(),
                if (step == 1) _otpStep(isDark),
                if (step == 2) _newPasswordStep(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _usernameStep() {
    return AuthCard(
      title: "Reset your password",
      subtitle: "Enter your username. We'll send an OTP to your registered mobile number / email.",
      children: [
        AuthField(
          label: "Username",
          hint: "Enter username",
          controller: usernameController,
          errorText: usernameError,
          onChanged: (_) {
            if (usernameError != null) setState(() => usernameError = null);
          },
        ),
        SizedBox(height: 24.h),
        PrimaryButton(title: "Send OTP", isLoading: isLoading, onTap: sendOtp),
      ],
    );
  }

  Widget _otpStep(bool isDark) {
    final text = isDark ? Colors.white : Colors.black;
    return AuthCard(
      title: "Enter OTP",
      subtitle: "We sent a 6 digit OTP for ${usernameController.text.trim()}.",
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
        SizedBox(height: 12.h),
        if (showSubscriberCode) ...[
          AuthField(
            label: "Subscriber Code",
            hint: "e.g. SUB00123",
            controller: subscriberCodeController,
          ),
          SizedBox(height: 12.h),
        ] else
          GestureDetector(
            onTap: () => setState(() => showSubscriberCode = true),
            child: Text(
              "Have more than one account? Add subscriber code",
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(height: 24.h),
        PrimaryButton(title: "Verify OTP", isLoading: isLoading, onTap: verifyOtp),
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
              "Change username",
              style: GoogleFonts.poppins(
                color: text.withOpacity(.6),
                fontSize: 12.sp,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _newPasswordStep(bool isDark) {
    final text = isDark ? Colors.white : Colors.black;
    return AuthCard(
      title: "Set new password",
      subtitle: "Choose a new password for ${usernameController.text.trim()}. Spaces are not allowed.",
      children: [
        AuthField(
          label: "New Password",
          hint: "Enter new password",
          controller: newPasswordController,
          obscure: obscureNew,
          errorText: newPasswordError,
          suffix: IconButton(
            icon: Icon(
              obscureNew ? Icons.visibility_off : Icons.visibility,
              color: text.withOpacity(.65),
            ),
            onPressed: () => setState(() => obscureNew = !obscureNew),
          ),
          onChanged: (_) {
            if (newPasswordError != null) setState(() => newPasswordError = null);
          },
        ),
        SizedBox(height: 16.h),
        AuthField(
          label: "Confirm Password",
          hint: "Re-enter new password",
          controller: confirmPasswordController,
          obscure: obscureConfirm,
          errorText: confirmPasswordError,
          suffix: IconButton(
            icon: Icon(
              obscureConfirm ? Icons.visibility_off : Icons.visibility,
              color: text.withOpacity(.65),
            ),
            onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
          ),
          onChanged: (_) {
            if (confirmPasswordError != null) {
              setState(() => confirmPasswordError = null);
            }
          },
        ),
        SizedBox(height: 24.h),
        PrimaryButton(
          title: "Change Password",
          isLoading: isLoading,
          onTap: resetPassword,
        ),
      ],
    );
  }
}

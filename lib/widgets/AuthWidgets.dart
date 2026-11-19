import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/theme/app_colors.dart';

/// Text field styled the same as the Login screen.
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.errorText,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: c),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: text.withOpacity(.75),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: GoogleFonts.poppins(color: text, fontSize: 13.sp),
          decoration: InputDecoration(
            hintText: hint,
            counterText: "",
            filled: true,
            fillColor: Colors.grey.withOpacity(.08),
            contentPadding: EdgeInsets.all(10.r),
            hintStyle: GoogleFonts.poppins(
              color: text.withOpacity(.5),
              fontSize: 13.sp,
            ),
            errorText: errorText,
            suffixIcon: suffix,
            enabledBorder: border(Colors.grey.withOpacity(.3)),
            disabledBorder: border(Colors.grey.withOpacity(.2)),
            focusedBorder: border(AppColors.primary),
            errorBorder: border(AppColors.red),
            focusedErrorBorder: border(AppColors.red),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Logo + rounded card used by the auth screens.
class AuthCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const AuthCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        SizedBox(height: 30.h),
        Image.asset(
          isDark ? "assets/LogoApp_dark.png" : "assets/LogoApp.png",
          width: 180.w,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 30.h),
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4.h),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    color: text.withOpacity(.6),
                    fontSize: 12.sp,
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              ...children,
            ],
          ),
        ),
        SizedBox(height: 40.h),
      ],
    );
  }
}

/// "Resend OTP in 25s" / "Resend OTP" link.
class ResendOtpLink extends StatelessWidget {
  final int secondsLeft;
  final bool disabled;
  final VoidCallback onResend;

  const ResendOtpLink({
    super.key,
    required this.secondsLeft,
    required this.onResend,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final waiting = secondsLeft > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't get the OTP? ",
          style: GoogleFonts.poppins(
            color: text.withOpacity(.6),
            fontSize: 12.sp,
          ),
        ),
        GestureDetector(
          onTap: (waiting || disabled) ? null : onResend,
          child: Text(
            waiting ? "Resend in ${secondsLeft}s" : "Resend OTP",
            style: GoogleFonts.poppins(
              color: waiting ? text.withOpacity(.4) : AppColors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Color btnClr;
  final BorderRadius? borderRadius;

  const PrimaryButton({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.height = 55,
    this.borderRadius,
    this.btnClr = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height.h,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          color: btnClr,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.30),
              blurRadius: 20.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: Center(
          child: isLoading
              ? Lottie.asset(
                  'assets/animation/loading.json',
                  repeat: true,
                  delegates: LottieDelegates(values: [ValueDelegate.color(const ['**'], value: Colors.white)]),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 24.r),
                      SizedBox(width: 10.w),
                    ],
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

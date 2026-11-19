import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vision_broadband/theme/app_colors.dart';

/// Parses the dashboard "expiry_date" ("2026-06-17 15:15:00" or ISO).
DateTime? parseExpiryDate(dynamic value) {
  final s = value?.toString().trim() ?? '';
  if (s.isEmpty || s == '-' || s.toLowerCase() == 'null') return null;
  try {
    return DateTime.parse(s);
  } catch (_) {
    try {
      return DateFormat("yyyy-MM-dd HH:mm:ss").parse(s);
    } catch (_) {
      return null;
    }
  }
}

/// Circular countdown to plan expiry, like the data rings in Jio / Airtel.
/// Full ring = 30 or more days left. Colors: green > 7 days,
/// orange 3–7 days, red < 3 days or expired.
class ExpiryRing extends StatelessWidget {
  final DateTime expiry;
  final double size;
  final VoidCallback? onTap;

  const ExpiryRing({
    super.key,
    required this.expiry,
    this.size = 64,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;

    final diff = expiry.difference(DateTime.now());
    final expired = diff.isNegative;
    final hoursLeft = diff.inHours;
    final daysLeft = expired ? 0 : (diff.inMinutes / (60 * 24)).ceil();

    final Color color = expired || daysLeft < 3
        ? AppColors.red
        : daysLeft <= 7
            ? AppColors.orange
            : AppColors.green;
    final double fraction =
        expired ? 1.0 : (daysLeft / 30).clamp(0.04, 1.0).toDouble();

    String big;
    String small;
    if (expired) {
      big = "!";
      small = "Expired";
    } else if (hoursLeft < 24) {
      big = "${math.max(hoursLeft, 1)}";
      small = hoursLeft <= 1 ? "hour" : "hours";
    } else {
      big = "$daysLeft";
      small = daysLeft == 1 ? "day left" : "days left";
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size.r,
        height: size.r,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 5,
                  color: color.withOpacity(.15),
                ),
              ),
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: Colors.transparent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    big,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: (size * .28).sp,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    small,
                    style: GoogleFonts.poppins(
                      color: text.withOpacity(.6),
                      fontSize: (size * .12).sp,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

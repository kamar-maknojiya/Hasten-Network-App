import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/theme/app_colors.dart';

enum AlertType { success, warning, error, info }

class TopAlert {
  static void show(
    BuildContext context, {
    // required String title,
    required String message,
    AlertType type = AlertType.info,
  }) {
    Color bgColor;
    IconData icon;

    switch (type) {
      case AlertType.success:
        bgColor = AppColors.green;
        icon = Icons.check_circle_rounded;
        break;

      case AlertType.warning:
        bgColor = const Color(0xffffc700);
        // bgColor = AppColors.orange;
        icon = Icons.warning_amber_rounded;
        break;

      case AlertType.error:
        bgColor = AppColors.red;
        icon = Icons.error_outline;
        break;

      case AlertType.info:
        bgColor = Colors.blue;
        icon = Icons.info_outline;
        break;
    }

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 15,
        left: 15,
        right: 15,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 25),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   title.toUpperCase(),
                      //   style: GoogleFonts.poppins(
                      //     color: Colors.white,
                      //     fontWeight: FontWeight.w600,
                      //     fontSize: 15,
                      //   ),
                      // ),
                      // const SizedBox(height: 2),
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 3),
                        builder: (context, value, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor: Colors.white.withOpacity(.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    entry.remove();
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

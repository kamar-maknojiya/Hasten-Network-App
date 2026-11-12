import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class CustomAppbar extends StatelessWidget {
  final String title;
  final bool isBack;
  final VoidCallback? onTap;

  const CustomAppbar({
    super.key,
    this.title = "",
    this.isBack = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          if (isBack) ...[
            GestureDetector(
              onTap: onTap ?? () => Navigator.pop(context),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 20, color: text),
              ),
            ),
            const SizedBox(width: 20),
          ],

          Text(
            title,
            style: GoogleFonts.poppins(
              color: text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

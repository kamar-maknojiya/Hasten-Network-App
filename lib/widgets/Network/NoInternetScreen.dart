import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/Network/NetworkService.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final secondaryText = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Column(
          children: [
            /// CENTER CONTENT
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// ICON BOX
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 35,
                          color: isDark ? Colors.white70 : Colors.black38,
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text(
                        "No Internet",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Please Connect to Internet",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 14, color: text),
                      ),
                      const SizedBox(height: 20),

                      /// RETRY BUTTON
                      OutlinedButton(
                        onPressed: () async {
                          await NetworkService().checkConnection();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          "Retry",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAVIGATION
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 2,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color(0xff10D7B1),
      //   unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
      //   backgroundColor: isDark ? const Color(0xff020B24) : Colors.white,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home_outlined),
      //       label: "Home",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.cell_tower),
      //       label: "Recharge",
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
      //     BottomNavigationBarItem(icon: Icon(Icons.wifi), label: "Wifi"),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person_outline),
      //       label: "Profile",
      //     ),
      //   ],
      // ),
    );
  }
}

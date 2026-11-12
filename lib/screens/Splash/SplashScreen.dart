import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/screens/auth/LoginScreen.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/theme/theme_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    checkLogin();
  }

  Future<void> checkLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('TOKEN :: $token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNavScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_controller.value * .05),
                    child: Image.asset(
                      "assets/LogoApp.png",
                      width: 220.w,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
              // SizedBox(height: 20.h),
              // ShaderMask(
              //   shaderCallback: (bounds) {
              //     return const LinearGradient(
              //       colors: [AppColors.primary, AppColors.primary],
              //     ).createShader(bounds);
              //   },
              //   child: Text(
              //     "vision Broadband",
              //     style: GoogleFonts.poppins(
              //       fontSize: 25,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.white,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 6),
              // Text(
              //   "Fast • Secure • Connected",
              //   style: GoogleFonts.poppins(
              //     color: text.withOpacity(.6),
              //     fontSize: 12
              //   ),
              // ),
              const Spacer(),
              SafeArea(
                child: SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      color: AppColors.primary,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Text(
              //   "Powered by Chirag It Solutions",
              //   style: GoogleFonts.poppins(
              //     color: text.withOpacity(.6),
              //     fontSize: 12,
              //   ),
              // ),
              // const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

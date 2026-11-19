import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/auth_api.dart';
import 'package:vision_broadband/screens/auth/LoginScreen.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppLock.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/RechargeReminder.dart';

/// Shown on app start when App Lock is on.
/// Unlock -> dashboard. "Login with password" -> logs out locally.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unlock());
  }

  Future<void> unlock() async {
    if (isAuthenticating) return;
    setState(() => isAuthenticating = true);
    final ok = await AppLock.authenticate("Unlock Hasten Network");
    if (!mounted) return;
    setState(() => isAuthenticating = false);
    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      );
    }
  }

  Future<void> usePassword() async {
    await RechargeReminder.cancelAll();
    await LoginMode.clearPrefsKeepLoginMode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                isDark ? "assets/LogoApp_dark.png" : "assets/LogoApp.png",
                width: 170.w,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              GestureDetector(
                onTap: unlock,
                child: Container(
                  width: 96.r,
                  height: 96.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(.35), width: 2),
                  ),
                  child: Icon(Icons.fingerprint_rounded, size: 54.r, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                "App locked",
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Use your fingerprint, face or phone PIN to continue",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: text.withOpacity(.6),
                  fontSize: 12.5.sp,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                title: "Unlock",
                icon: Icons.lock_open_rounded,
                isLoading: isAuthenticating,
                onTap: unlock,
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: isAuthenticating ? null : usePassword,
                child: Text(
                  "Login with password instead",
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}

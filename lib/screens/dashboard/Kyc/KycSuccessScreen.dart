import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_widgets.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';

/// Celebration screen: shield tick pops in, light confetti falls.
class KycSuccessScreen extends StatefulWidget {
  final String title;
  final String message;
  const KycSuccessScreen({
    super.key,
    this.title = "KYC complete",
    this.message = "Your account is fully verified. Thank you.",
  });

  @override
  State<KycSuccessScreen> createState() => _KycSuccessScreenState();
}

class _KycSuccessScreenState extends State<KycSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();

  static const _colors = [AppColors.secondary, Color(0xFFF5A524), KycColors.green, AppColors.primary];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = KycColors.text(dark);
    final rnd = math.Random(7);
    final pieces = List.generate(22, (i) => [rnd.nextDouble(), rnd.nextDouble() * .4, rnd.nextDouble()]);

    return Scaffold(
      backgroundColor: KycColors.bg(dark),
      body: SafeArea(
        child: Stack(
          children: [
            // confetti
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => LayoutBuilder(
                    builder: (context, box) => Stack(
                      children: [
                        for (int i = 0; i < pieces.length; i++)
                          Builder(builder: (_) {
                            final t = ((_c.value - pieces[i][1]) / .6).clamp(0.0, 1.0);
                            return Positioned(
                              left: pieces[i][0] * box.maxWidth,
                              top: -10 + t * box.maxHeight * .7,
                              child: Opacity(
                                opacity: t == 0 ? 0.0 : (1 - t),
                                child: Transform.rotate(
                                  angle: t * 6 + pieces[i][2] * 3,
                                  child: Container(
                                    width: 7,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: _colors[i % _colors.length],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const KycSuccessTick(size: 96, icon: Icons.verified_user_rounded),
                  SizedBox(height: 22.h),
                  KycAppear(
                    index: 2,
                    child: Text(widget.title,
                        style: GoogleFonts.poppins(color: text, fontSize: 21.sp, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(height: 6.h),
                  KycAppear(
                    index: 3,
                    child: Text(widget.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 13.sp, height: 1.5)),
                  ),
                  const Spacer(flex: 3),
                  KycAppear(
                    index: 4,
                    child: PrimaryButton(title: "Continue", onTap: () => Navigator.pop(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/theme/app_colors.dart';

/// Colors used across the KYC screens (light + dark).
class KycColors {
  static const teal = Color(0xFF0D9488);
  static const amber = Color(0xFFD97706);
  static const amberSoft = Color(0xFFFFF1D6);
  static const amberText = Color(0xFFB45309);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);
  static const greenText = Color(0xFF166534);

  static Color card(bool dark) => dark ? AppColors.darkCard : Colors.white;
  static Color bg(bool dark) => dark ? AppColors.darkBg : AppColors.lightBg;
  static Color text(bool dark) => dark ? Colors.white : const Color(0xFF111827);
  static Color sub(bool dark) => dark ? Colors.white60 : const Color(0xFF6B7280);
  static Color accent(bool dark) => dark ? AppColors.secondary : AppColors.primary;
  static Color iconBg(bool dark) =>
      dark ? AppColors.primary.withOpacity(.25) : const Color(0xFFE3EEF9);
}

/// "Pending" / "Uploaded" / "Verified" pill.
class KycChip extends StatelessWidget {
  final String label;
  final bool done;
  final bool dark;
  const KycChip({super.key, required this.label, required this.done, required this.dark});

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? (dark ? KycColors.green.withOpacity(.2) : KycColors.greenSoft)
        : (dark ? KycColors.amber.withOpacity(.22) : KycColors.amberSoft);
    final fg = done
        ? (dark ? const Color(0xFF4ADE80) : KycColors.greenText)
        : (dark ? const Color(0xFFFBBF24) : KycColors.amberText);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.schedule_rounded, size: 12.r, color: fg),
          SizedBox(width: 4.w),
          Text(label,
              style: GoogleFonts.poppins(color: fg, fontSize: 10.5.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Fade + slide up, delayed by [index] (staggered lists).
class KycAppear extends StatelessWidget {
  final int index;
  final Widget child;
  const KycAppear({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Rings that grow and fade around a center icon.
class KycPulseRings extends StatefulWidget {
  final double size;
  final Color color;
  final IconData icon;
  final Color? coreColor;
  const KycPulseRings({
    super.key,
    required this.size,
    required this.color,
    required this.icon,
    this.coreColor,
  });

  @override
  State<KycPulseRings> createState() => _KycPulseRingsState();
}

class _KycPulseRingsState extends State<KycPulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = widget.size * .46;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 2; i++)
              Builder(builder: (_) {
                final t = (_c.value + i / 2) % 1.0;
                final d = core + (widget.size - core) * t;
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color.withOpacity(.55 * (1 - t)), width: 1.5),
                  ),
                );
              }),
            child!,
          ],
        ),
        child: Container(
          width: core,
          height: core,
          decoration: BoxDecoration(color: widget.coreColor ?? widget.color, shape: BoxShape.circle),
          child: Icon(widget.icon, color: Colors.white, size: core * .52),
        ),
      ),
    );
  }
}

/// Green tick that pops in.
class KycSuccessTick extends StatelessWidget {
  final double size;
  final IconData icon;
  const KycSuccessTick({super.key, this.size = 72, this.icon = Icons.check_rounded});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, v, c) => Transform.scale(scale: v, child: c),
      child: Container(
        width: size.r,
        height: size.r,
        decoration: BoxDecoration(
          color: KycColors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: KycColors.green.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size.r * .55),
      ),
    );
  }
}

/// Small rounded square with an icon (document rows).
class KycIconBox extends StatelessWidget {
  final IconData icon;
  final bool dark;
  final Color? color;
  const KycIconBox({super.key, required this.icon, required this.dark, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        color: color?.withOpacity(dark ? .22 : .12) ?? KycColors.iconBg(dark),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Icon(icon, size: 21.r, color: color ?? KycColors.accent(dark)),
    );
  }
}

IconData kycCategoryIcon(String key) {
  switch (key) {
    case 'idproof':
      return Icons.badge_outlined;
    case 'addressproof':
      return Icons.home_outlined;
    case 'photoproof':
      return Icons.portrait_outlined;
    case 'signatureproof':
      return Icons.draw_outlined;
    default:
      return Icons.description_outlined;
  }
}

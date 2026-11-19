import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/EkycScreen.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/KycSuccessScreen.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/KycUploadSheet.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_service.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_widgets.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';

/// KYC Verification
///  - only e-KYC      -> e-KYC section
///  - only documents  -> documents section
///  - both            -> two equal tabs (e-KYC | Documents); subscriber can do both,
///                       in any order. KYC is complete when both are done.
class KycScreen extends StatefulWidget {
  /// open on this tab when both are on: 0 = e-KYC, 1 = Documents (null = auto)
  final int? initialTab;
  const KycScreen({super.key, this.initialTab});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  KycStatus? status;
  bool loading = true;
  String? error;
  int tab = 0; // 0 e-KYC, 1 Documents
  bool tabPicked = false;

  KycPlan? get plan => status == null ? null : KycPlan.of(status!);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool showLoader = true}) async {
    if (showLoader) setState(() => loading = true);
    try {
      final s = await KycService.fetchStatus();
      if (!mounted) return;
      setState(() {
        status = s;
        loading = false;
        error = null;
        if (!tabPicked) {
          final p = KycPlan.of(s);
          tab = widget.initialTab ?? (p.ekycLeft || p.mismatch || !p.docsLeft ? 0 : 1);
          tabPicked = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> openEkyc() async {
    final docsLeft = plan?.docsLeft ?? false;
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EkycScreen(documentsPending: docsLeft, vendorType: status?.vendorType),
      ),
    );
    if (done == true) await load(showLoader: false);
  }

  Future<void> openUpload(KycDocument d) async {
    final ok = await showKycUploadSheet(
      context,
      d.category,
      presetType: d.canAddMore ? d.documentType : null,
      maxNow: d.canAddMore ? d.remaining : null,
    );
    if (!ok) return;
    final wasDone = plan?.done ?? false;
    await load(showLoader: false);
    if (!mounted || wasDone || !(plan?.done ?? false)) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const KycSuccessScreen()));
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: KycColors.bg(dark),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                const CustomAppbar(title: "KYC Verification"),
                Expanded(
                  child: loading
                      ? Center(child: CircularProgressIndicator(color: KycColors.accent(dark)))
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => load(showLoader: false),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: _body(dark),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(bool dark) {
    if (error != null || status == null) {
      return [
        SizedBox(height: 80.h),
        Icon(Icons.cloud_off_rounded, size: 54.r, color: KycColors.sub(dark)),
        SizedBox(height: 12.h),
        Text(error ?? "Couldn't load KYC details",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 13.sp)),
        SizedBox(height: 18.h),
        PrimaryButton(title: "Try Again", onTap: () => load()),
      ];
    }
    final s = status!;
    final p = plan!;
    if (!p.needsEkyc && !p.needsDocs) {
      return [
        SizedBox(height: 80.h),
        Text("KYC is not required for your account.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 13.sp)),
      ];
    }

    final w = <Widget>[SizedBox(height: 6.h)];
    if (p.done) {
      w.add(KycAppear(index: 0, child: _allDoneCard(dark)));
      w.add(SizedBox(height: 12.h));
    }

    final showEkyc = p.both ? tab == 0 : p.needsEkyc;
    if (p.both) {
      w.add(KycAppear(index: 0, child: _tabs(p, dark)));
      w.add(SizedBox(height: 12.h));
    }

    w.add(AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a),
          child: c,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(showEkyc),
        child: showEkyc ? _ekycSection(s, dark) : _docsSection(s, dark),
      ),
    ));
    w.add(SizedBox(height: 30.h));
    return w;
  }

  // ---------------- tabs ----------------

  Widget _tabs(KycPlan p, bool dark) {
    const amberBg = Color(0x29F5A524);
    final amberFg = dark ? const Color(0xFFFBBF24) : const Color(0xFF8A5A12);
    final greenBg = KycColors.green.withOpacity(.14);
    final blue = KycColors.accent(dark);

    Widget badge(String t, Color fg, Color bg) => Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 1.h),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Text(t, style: GoogleFonts.poppins(color: fg, fontSize: 10.sp, fontWeight: FontWeight.w500)),
        );

    final ekycBadge = p.mismatch
        ? badge("Mismatch", amberFg, amberBg)
        : p.ekycDone
            ? badge("Done", KycColors.green, greenBg)
            : badge("Pending", amberFg, amberBg);
    final docsBadge = p.docsDone
        ? badge("Done", KycColors.green, greenBg)
        : badge("${p.docsUploaded}/${p.docsTotal}", blue, blue.withOpacity(.12));

    Widget item(int i, String label, Widget b) {
      final on = tab == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => tab = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: on ? KycColors.card(dark) : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: on
                  ? [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 6, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                      color: on ? blue : KycColors.sub(dark),
                      fontSize: 13.sp,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                    )),
                SizedBox(width: 6.w),
                b,
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(.07) : const Color(0xFFE3E9F0),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Row(
        children: [
          item(0, "e-KYC", ekycBadge),
          SizedBox(width: 4.w),
          item(1, "Documents", docsBadge),
        ],
      ),
    );
  }

  // ---------------- e-KYC ----------------

  Widget _ekycSection(KycStatus s, bool dark) {
    final text = KycColors.text(dark);
    final p = plan!;
    final Color chipBg;
    final Color chipFg;
    final String chip;
    if (p.mismatch) {
      chip = "Details don't match";
      chipBg = AppColors.red.withOpacity(.12);
      chipFg = AppColors.red;
    } else if (p.ekycDone) {
      chip = "Verified";
      chipBg = KycColors.green.withOpacity(.12);
      chipFg = KycColors.green;
    } else {
      chip = "Pending";
      chipBg = const Color(0xFFF5A524).withOpacity(.16);
      chipFg = const Color(0xFF8A5A12);
    }

    Widget step(int n, String t) => Padding(
          padding: EdgeInsets.symmetric(vertical: 5.h),
          child: Row(
            children: [
              Container(
                width: 22.r,
                height: 22.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: KycColors.teal.withOpacity(.12), shape: BoxShape.circle),
                child: Text("$n",
                    style: GoogleFonts.poppins(color: KycColors.teal, fontSize: 11.sp, fontWeight: FontWeight.w600)),
              ),
              SizedBox(width: 10.w),
              Expanded(child: Text(t, style: GoogleFonts.poppins(color: text, fontSize: 12.5.sp))),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(color: KycColors.card(dark), borderRadius: BorderRadius.circular(18.r)),
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: (p.ekycDone ? KycColors.green : KycColors.teal).withOpacity(.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                color: p.mismatch ? AppColors.red : (p.ekycDone ? KycColors.green : KycColors.teal),
                shape: BoxShape.circle,
              ),
              child: Icon(
                p.ekycDone ? Icons.verified_user_rounded : Icons.fingerprint_rounded,
                color: Colors.white,
                size: 24.r,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text("e-KYC with Aadhaar",
              style: GoogleFonts.poppins(color: text, fontSize: 15.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
            decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20)),
            child: Text(chip, style: GoogleFonts.poppins(color: chipFg, fontSize: 11.sp, fontWeight: FontWeight.w500)),
          ),
          if (p.mismatch) ...[
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(dark ? .15 : .07),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.red.withOpacity(.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 18.r, color: AppColors.red),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      s.mismatchText,
                      style: GoogleFonts.poppins(color: text, fontSize: 12.sp, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (p.ekycDone) ...[
            SizedBox(height: 10.h),
            Text("Your identity is verified with Aadhaar.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.sp)),
          ] else ...[
            SizedBox(height: 12.h),
            if (s.isDigilocker) ...[
              step(1, "Open DigiLocker and sign in"),
              step(2, "Allow access to your Aadhaar"),
              step(3, "Come back here, your e-KYC is verified"),
            ] else ...[
              step(1, "Enter your Aadhaar number"),
              step(2, "Enter the OTP sent to your Aadhaar mobile"),
              step(3, "Your e-KYC is verified"),
            ],
            SizedBox(height: 14.h),
            PrimaryButton(
              title: "Start e-KYC",
              icon: Icons.fingerprint_rounded,
              btnClr: KycColors.teal,
              height: 48,
              onTap: openEkyc,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- documents ----------------

  Widget _docsSection(KycStatus s, bool dark) {
    final p = plan!;
    final left = p.docsTotal - p.docsUploaded;
    final docs = s.documents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.docsDone)
          KycAppear(index: 0, child: _docsDoneCard(dark))
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "$left document${left == 1 ? '' : 's'} left",
                    style: GoogleFonts.poppins(
                      color: KycColors.text(dark),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text("Tap a tile to upload",
                    style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 11.sp)),
              ],
            ),
          ),
        SizedBox(height: 10.h),
        for (int r = 0; r < docs.length; r += 2) ...[
          if (r > 0) SizedBox(height: 10.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: KycAppear(index: 1 + r, child: _docTile(docs[r], dark))),
                SizedBox(width: 10.w),
                Expanded(
                  child: r + 1 < docs.length
                      ? KycAppear(index: 2 + r, child: _docTile(docs[r + 1], dark))
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 14.h),
        Center(
          child: Text(
            "${s.config.typesText} · max ${s.config.maxFileText} · can't be removed later",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 10.5.sp),
          ),
        ),
      ],
    );
  }

  /// Small green strip shown when every document is uploaded
  Widget _docsDoneCard(bool dark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: dark ? KycColors.green.withOpacity(.16) : KycColors.greenSoft,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: KycColors.green.withOpacity(dark ? .35 : .25)),
      ),
      child: Row(
        children: [
          Container(
            width: 22.r,
            height: 22.r,
            decoration: const BoxDecoration(color: KycColors.green, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, color: Colors.white, size: 15.r),
          ),
          SizedBox(width: 10.w),
          Text("All documents uploaded",
              style: GoogleFonts.poppins(
                color: dark ? const Color(0xFF4ADE80) : KycColors.greenText,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  /// One document tile: dashed border = still to upload, ✓ = uploaded
  Widget _docTile(KycDocument d, bool dark) {
    final text = KycColors.text(dark);
    final blue = KycColors.accent(dark);
    final tappable = !d.uploaded || d.canAddMore;

    final Widget status;
    if (!d.uploaded) {
      status = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.upload_rounded, size: 14.r, color: blue),
          SizedBox(width: 3.w),
          Text("Upload", style: GoogleFonts.poppins(color: blue, fontSize: 11.5.sp, fontWeight: FontWeight.w500)),
        ],
      );
    } else if (d.canAddMore) {
      status = Text("+ Add back",
          style: GoogleFonts.poppins(color: blue, fontSize: 11.5.sp, fontWeight: FontWeight.w500));
    } else {
      status = Text("Uploaded",
          style: GoogleFonts.poppins(color: KycColors.green, fontSize: 11.5.sp, fontWeight: FontWeight.w500));
    }

    final tile = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: KycIconBox(
                  icon: kycCategoryIcon(d.category.key),
                  dark: dark,
                  color: d.uploaded ? KycColors.green : null,
                ),
              ),
              SizedBox(height: 8.h),
              Text(d.category.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: text, fontSize: 13.5.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 2.h),
              status,
            ],
          ),
          if (d.uploaded)
            Positioned(
              top: -8.h,
              right: -2.w,
              child: Icon(Icons.check_circle_outline_rounded, color: KycColors.green, size: 20.r),
            ),
        ],
      ),
    );

    return Material(
      color: KycColors.card(dark),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: tappable ? () => openUpload(d) : null,
        child: d.uploaded
            ? tile
            : CustomPaint(
                painter: _DashedBorder(color: AppColors.secondary, radius: 16.r),
                child: tile,
              ),
      ),
    );
  }

  Widget _allDoneCard(bool dark) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: dark ? KycColors.green.withOpacity(.18) : KycColors.greenSoft,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          const KycSuccessTick(size: 38, icon: Icons.verified_user_rounded),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("KYC complete",
                    style: GoogleFonts.poppins(
                        color: dark ? const Color(0xFF4ADE80) : KycColors.greenText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600)),
                Text("Your account is fully verified",
                    style: GoogleFonts.poppins(
                        color: dark ? Colors.white70 : KycColors.greenText, fontSize: 11.5.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded border for tiles that still need an upload.
class _DashedBorder extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorder({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color || old.radius != radius;
}

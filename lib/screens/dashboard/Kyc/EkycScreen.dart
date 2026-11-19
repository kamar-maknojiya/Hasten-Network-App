import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/KycSuccessScreen.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_service.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_widgets.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

/// e-KYC flow
///  vendor_type 1 (OTP)       : intro -> Aadhaar number -> OTP -> result
///  vendor_type 2 (DigiLocker): intro -> open link in browser -> wait -> result
/// Pops with true when e-KYC is verified.
class EkycScreen extends StatefulWidget {
  final bool documentsPending;
  final int? vendorType; // from GET /kyc
  const EkycScreen({super.key, this.documentsPending = false, this.vendorType});

  @override
  State<EkycScreen> createState() => _EkycScreenState();
}

enum _Step { intro, aadhaar, otp, browser, failed }

class _EkycScreenState extends State<EkycScreen> with WidgetsBindingObserver {
  _Step step = _Step.intro;
  bool busy = false;
  String? failText;

  // OTP flow
  final aadhaarCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final otpFocus = FocusNode();
  String? ekycId, requestId;
  int resendIn = 0;
  Timer? timer;

  // DigiLocker flow
  String? link;

  bool get isLinkFlow => widget.vendorType == 2;
  String get aadhaarDigits => aadhaarCtrl.text.replaceAll(' ', '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    aadhaarCtrl.dispose();
    otpCtrl.dispose();
    otpFocus.dispose();
    super.dispose();
  }

  /// Back from the DigiLocker page -> check automatically
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && step == _Step.browser && !busy) {
      checkStatus(silent: true);
    }
  }

  void go(_Step s) => setState(() => step = s);

  // ---------------------------------------------------------------- actions
  Future<void> start() async {
    if (!isLinkFlow) {
      go(_Step.aadhaar);
      return;
    }
    setState(() => busy = true);
    try {
      final r = await KycService.verify();
      if (r.isLink) {
        link = r.link;
        await _openLink();
        if (mounted) setState(() => step = _Step.browser);
      } else if (r.ekycId != null) {
        // server switched to OTP mode
        ekycId = r.ekycId;
        requestId = r.requestId;
        go(_Step.aadhaar);
      }
    } catch (e) {
      errToast(e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _openLink() async {
    if (link == null) return;
    final ok = await launchUrl(Uri.parse(link!), mode: LaunchMode.externalApplication);
    if (!ok) throw KycException("Couldn't open the DigiLocker page");
  }

  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();
    if (aadhaarDigits.length != 12) {
      errToast("Please enter your 12-digit Aadhaar number");
      return;
    }
    setState(() => busy = true);
    try {
      final r = await KycService.verify(aadhaar: aadhaarDigits);
      if (!mounted) return;
      if (r.isLink) {
        link = r.link;
        await _openLink();
        setState(() {
          busy = false;
          step = _Step.browser;
        });
        return;
      }
      ekycId = r.ekycId;
      requestId = r.requestId;
      otpCtrl.clear();
      _startTimer();
      setState(() {
        busy = false;
        step = _Step.otp;
      });
      successToast(r.message.isNotEmpty ? r.message : "OTP sent to your Aadhaar-linked mobile");
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) otpFocus.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      errToast(e.toString());
    }
  }

  void _startTimer() {
    timer?.cancel();
    resendIn = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => resendIn--);
      if (resendIn <= 0) t.cancel();
    });
  }

  Future<void> submitOtp() async {
    if (otpCtrl.text.length != 6) {
      errToast("Please enter the 6-digit OTP");
      return;
    }
    if (ekycId == null || requestId == null) {
      go(_Step.aadhaar);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      await KycService.submitOtp(ekycId: ekycId!, requestId: requestId!, otp: otpCtrl.text);
      if (!mounted) return;
      await checkStatus(afterOtp: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      otpCtrl.clear();
      errToast(e.toString());
    }
  }

  Future<void> checkStatus({bool silent = false, bool afterOtp = false}) async {
    setState(() => busy = true);
    try {
      final s = await KycService.fetchStatus();
      if (!mounted) return;
      setState(() => busy = false);
      if (s.mismatch) {
        // e-KYC is done on the server, but Aadhaar details didn't match the account
        setState(() {
          failText = s.mismatchText;
          step = _Step.failed;
        });
      } else if (s.ekycVerified) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KycSuccessScreen(
              title: widget.documentsPending ? "e-KYC verified" : "KYC complete",
              message: widget.documentsPending
                  ? "One step left: upload your documents."
                  : "Your account is fully verified. Thank you.",
            ),
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else if (afterOtp) {
        successToast("Submitted. Verification is in progress.");
        Navigator.pop(context, true);
      } else if (!silent) {
        errToast("Not verified yet. Please finish the steps on the DigiLocker page.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      if (!silent) errToast(e.toString());
    }
  }

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = KycColors.text(dark);

    Widget body;
    switch (step) {
      case _Step.intro:
        body = _intro(dark, text);
        break;
      case _Step.aadhaar:
        body = _aadhaar(dark, text);
        break;
      case _Step.otp:
        body = _otp(dark, text);
        break;
      case _Step.browser:
        body = _browser(dark, text);
        break;
      case _Step.failed:
        body = _failed(dark, text);
        break;
    }

    return PopScope(
      canPop: step == _Step.intro || step == _Step.failed || step == _Step.browser,
      onPopInvoked: (didPop) {
        if (didPop) return;
        go(step == _Step.otp ? _Step.aadhaar : _Step.intro);
      },
      child: Scaffold(
        backgroundColor: KycColors.bg(dark),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    const CustomAppbar(title: "e-KYC"),
                    if (!isLinkFlow && (step == _Step.aadhaar || step == _Step.otp)) _stepBar(dark),
                  ],
                ),
              ),
              Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(a),
                          child: c,
                        ),
                      ),
                      child: KeyedSubtree(key: ValueKey(step), child: body),
                    ),
                  ),
                ),
              _bottomBar(dark) ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  /// "Step 1 of 2" + 2-part bar
  Widget _stepBar(bool dark) {
    final onOtp = step == _Step.otp;
    Widget seg(bool on) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 4,
            decoration: BoxDecoration(
              color: on ? KycColors.teal : KycColors.sub(dark).withOpacity(.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
    return Padding(
      padding: EdgeInsets.only(top: 2.h, bottom: 6.h),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text("Step ${onOtp ? 2 : 1} of 2",
                style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 11.sp)),
          ),
          SizedBox(height: 6.h),
          Row(children: [seg(true), const SizedBox(width: 4), seg(onOtp)]),
        ],
      ),
    );
  }

  /// Fixed bottom bar with the main button of each step
  Widget? _bottomBar(bool dark) {
    Widget? btn;
    bool note = false;
    switch (step) {
      case _Step.intro:
        btn = PrimaryButton(
          title: "Start e-KYC",
          icon: Icons.fingerprint_rounded,
          btnClr: KycColors.teal,
          height: 48,
          isLoading: busy,
          onTap: busy ? null : start,
        );
        note = true;
        break;
      case _Step.aadhaar:
        btn = PrimaryButton(
          title: "Send OTP",
          btnClr: KycColors.teal,
          height: 48,
          isLoading: busy,
          onTap: busy || aadhaarDigits.length != 12 ? null : sendOtp,
        );
        break;
      case _Step.otp:
        btn = PrimaryButton(
          title: "Verify",
          btnClr: KycColors.teal,
          height: 48,
          isLoading: busy,
          onTap: busy || otpCtrl.text.length != 6 ? null : submitOtp,
        );
        break;
      default:
        return null;
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        border: Border(top: BorderSide(color: (dark ? Colors.white : Colors.black).withOpacity(.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn,
          if (note) ...[SizedBox(height: 8.h), _secureNote(dark)],
        ],
      ),
    );
  }

  Widget _intro(bool dark, Color text) {
    final steps = isLinkFlow
        ? const ["Open DigiLocker and sign in", "Allow access to your Aadhaar", "Come back here, your e-KYC is verified"]
        : const ["Enter your Aadhaar number", "Enter the OTP sent to your Aadhaar mobile", "Your e-KYC is verified"];

    return Column(
      children: [
        SizedBox(height: 12.h),
        KycPulseRings(size: 120.r, color: KycColors.teal, icon: Icons.fingerprint_rounded),
        SizedBox(height: 12.h),
        Text(isLinkFlow ? "Verify with DigiLocker" : "Verify with Aadhaar",
            style: GoogleFonts.poppins(color: text, fontSize: 18.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 2.h),
        Text("Paperless and done in about 2 minutes",
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.5.sp)),
        SizedBox(height: 18.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(color: KycColors.card(dark), borderRadius: BorderRadius.circular(16.r)),
          child: Column(
            children: [
              for (int i = 0; i < steps.length; i++)
                KycAppear(
                  index: i,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Row(
                      children: [
                        Container(
                          width: 26.r,
                          height: 26.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: KycColors.teal.withOpacity(.12), shape: BoxShape.circle),
                          child: Text("${i + 1}",
                              style: GoogleFonts.poppins(
                                  color: KycColors.teal, fontSize: 12.sp, fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(steps[i], style: GoogleFonts.poppins(color: text, fontSize: 13.sp)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        KycAppear(
          index: 3,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A524).withOpacity(dark ? .15 : .12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android_rounded, size: 18.r, color: const Color(0xFFD98A0B)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    isLinkFlow
                        ? "DigiLocker opens in your browser. Come back to the app when it's done."
                        : "Keep the phone linked to your Aadhaar nearby for the OTP.",
                    style: GoogleFonts.poppins(
                        color: dark ? const Color(0xFFFBBF24) : const Color(0xFF7A4A06), fontSize: 11.5.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _secureNote(bool dark) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14.r, color: KycColors.sub(dark)),
          SizedBox(width: 4.w),
          Text("Your details are safe and encrypted",
              style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 11.sp)),
        ],
      );

  Widget _aadhaar(bool dark, Color text) {
    final full = aadhaarDigits.length == 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        KycAppear(
          index: 0,
          child: Text("Your Aadhaar number",
              style: GoogleFonts.poppins(color: text, fontSize: 18.sp, fontWeight: FontWeight.w700)),
        ),
        SizedBox(height: 4.h),
        KycAppear(
          index: 1,
          child: Text("We'll send an OTP to the mobile number linked with your Aadhaar.",
              style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.5.sp, height: 1.5)),
        ),
        SizedBox(height: 22.h),
        KycAppear(
          index: 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: KycColors.card(dark),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: full ? KycColors.green : AppColors.secondary.withOpacity(.5), width: 1.4),
            ),
            child: Row(
              children: [
                Icon(Icons.credit_card_rounded, color: full ? KycColors.green : KycColors.accent(dark), size: 22.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: aadhaarCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, _AadhaarFormatter()],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => sendOtp(),
                    style: GoogleFonts.poppins(
                        color: text, fontSize: 18.sp, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "XXXX XXXX XXXX",
                      hintStyle: GoogleFonts.poppins(
                          color: KycColors.sub(dark).withOpacity(.5), fontSize: 18.sp, letterSpacing: 1.5),
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: full ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Icon(Icons.check_circle_rounded, color: KycColors.green, size: 22.r),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text("${aadhaarDigits.length}/12 digits",
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 11.sp)),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _otp(bool dark, Color text) {
    final d = aadhaarDigits;
    final masked = d.length == 12 ? "XXXX XXXX ${d.substring(8)}" : "";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text("Enter the OTP", style: GoogleFonts.poppins(color: text, fontSize: 18.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 4.h),
        Text.rich(
          TextSpan(
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.5.sp, height: 1.5),
            children: [
              const TextSpan(text: "Sent to the mobile linked with Aadhaar "),
              TextSpan(text: masked, style: TextStyle(color: text, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        _OtpBoxes(
          controller: otpCtrl,
          focus: otpFocus,
          dark: dark,
          onChanged: () => setState(() {}),
          onCompleted: submitOtp,
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Text("Didn't get it? ", style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.sp)),
            resendIn > 0
                ? Text("Resend in ${resendIn}s",
                    style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.sp, fontWeight: FontWeight.w600))
                : GestureDetector(
                    onTap: busy ? null : sendOtp,
                    child: Text("Resend OTP",
                        style: GoogleFonts.poppins(
                            color: KycColors.accent(dark), fontSize: 12.sp, fontWeight: FontWeight.w600)),
                  ),
            const Spacer(),
            GestureDetector(
              onTap: busy ? null : () => go(_Step.aadhaar),
              child: Text("Change Aadhaar",
                  style: GoogleFonts.poppins(color: KycColors.accent(dark), fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _browser(bool dark, Color text) {
    return Column(
      children: [
        SizedBox(height: 30.h),
        KycPulseRings(
            size: 150.r, color: AppColors.secondary, icon: Icons.cloud_done_outlined, coreColor: KycColors.teal),
        SizedBox(height: 18.h),
        Text("Complete e-KYC on DigiLocker",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: text, fontSize: 17.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            "We opened DigiLocker in your browser. Sign in, allow access, then come back here. We'll check automatically.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.5.sp, height: 1.5),
          ),
        ),
        SizedBox(height: 28.h),
        PrimaryButton(
          title: "I've completed it",
          icon: Icons.refresh_rounded,
          isLoading: busy,
          onTap: busy ? null : () => checkStatus(),
        ),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  try {
                    await _openLink();
                  } catch (e) {
                    errToast(e.toString());
                  }
                },
          icon: Icon(Icons.open_in_new_rounded, color: KycColors.accent(dark), size: 18.r),
          label: Text("Open DigiLocker again",
              style: GoogleFonts.poppins(color: KycColors.accent(dark), fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(48.h),
            side: BorderSide(color: KycColors.accent(dark).withOpacity(.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _failed(bool dark, Color text) {
    return Column(
      children: [
        SizedBox(height: 40.h),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 96.r,
            height: 96.r,
            decoration: BoxDecoration(color: AppColors.red.withOpacity(.12), shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded, color: AppColors.red, size: 52.r),
          ),
        ),
        SizedBox(height: 18.h),
        Text("e-KYC done, details don't match",
            style: GoogleFonts.poppins(color: text, fontSize: 18.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            failText ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.5.sp, height: 1.5),
          ),
        ),
        SizedBox(height: 28.h),
        PrimaryButton(title: "Back to KYC", onTap: () => Navigator.pop(context, true)),
        SizedBox(height: 30.h),
      ],
    );
  }
}

/// Formats digits as "1234 5678 9012"
class _AadhaarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(' ', '');
    if (d.length > 12) d = d.substring(0, 12);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

/// 6 animated OTP boxes on top of one hidden TextField (paste + autofill work)
class _OtpBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool dark;
  final VoidCallback onChanged;
  final VoidCallback onCompleted;

  const _OtpBoxes({
    required this.controller,
    required this.focus,
    required this.dark,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    return GestureDetector(
      onTap: () => focus.requestFocus(),
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 56.h,
              child: TextField(
                controller: controller,
                focusNode: focus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  onChanged();
                  if (v.length == 6) onCompleted();
                },
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final filled = i < code.length;
              final current = i == code.length && focus.hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46.w,
                height: 56.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KycColors.card(dark),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: current
                        ? KycColors.teal
                        : filled
                            ? AppColors.secondary.withOpacity(.7)
                            : KycColors.sub(dark).withOpacity(.25),
                    width: current ? 2 : 1.3,
                  ),
                ),
                child: AnimatedScale(
                  scale: filled ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Text(filled ? code[i] : '',
                      style: GoogleFonts.poppins(
                          color: KycColors.text(dark), fontSize: 20.sp, fontWeight: FontWeight.w700)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

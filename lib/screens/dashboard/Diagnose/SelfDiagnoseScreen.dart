import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/RechargeScreen.dart';
import 'package:vision_broadband/screens/dashboard/Ticket/SupportTicketScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

/// "Why is my internet not working?" — same check as the web portal.
/// GET /netzur-ai/diagnose (permission self_diagnose, max 5 checks / 10 min).
///
/// The server returns every result at once; the app reveals the checks
/// one by one (spinner -> result) so the subscriber sees each step.
class SelfDiagnoseScreen extends StatefulWidget {
  /// true when opened from the dashboard "Fix Internet" button.
  final bool autoStart;

  const SelfDiagnoseScreen({super.key, this.autoStart = false});

  @override
  State<SelfDiagnoseScreen> createState() => _SelfDiagnoseScreenState();
}

enum _Phase { idle, checking, done, error }

class _CheckStep {
  String area;
  String state; // waiting | checking | ok | fail | skipped | warn
  String text;
  _CheckStep(this.area, {this.state = 'waiting', this.text = ''});
}

class _ApiResult {
  final Map<String, dynamic>? data;
  final String? error;
  _ApiResult({this.data, this.error});
}

class _SelfDiagnoseScreenState extends State<SelfDiagnoseScreen> {
  static const _orange = Color(0xFFF5A524);
  static const _defaultAreas = ['plan', 'login', 'connection', 'fibre'];

  _Phase phase = _Phase.idle;
  List<_CheckStep> steps = _defaultAreas.map((a) => _CheckStep(a)).toList();
  int activeIndex = -1;
  int revealed = 0;
  Map<String, dynamic>? result;
  String? errorMessage;
  bool isCreatingTicket = false;
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => runDiagnose());
    }
  }

  // ---------------- API ----------------

  Future<_ApiResult> _fetch() async {
    try {
      final response = await BaseClient().get(SELF_DIAGNOSE_URL, context);
      if (response != null && response['status'] == true && response['data'] is Map) {
        return _ApiResult(data: Map<String, dynamic>.from(response['data']));
      }
      final msg = (response is Map && response['message'] != null)
          ? response['message'].toString()
          : "Couldn't run the check. Please try again.";
      return _ApiResult(error: msg);
    } catch (e) {
      print("SelfDiagnose error :: $e");
      return _ApiResult(error: "Couldn't run the check. Please try again.");
    }
  }

  Future<void> runDiagnose() async {
    final runId = ++_runId;
    setState(() {
      phase = _Phase.checking;
      errorMessage = null;
      result = null;
      steps = _defaultAreas.map((a) => _CheckStep(a)).toList();
      activeIndex = 0;
      revealed = 0;
    });

    final api = _fetch(); // runs while the first step animates
    bool replaced = false;
    _ApiResult? res;

    for (int i = 0; i < steps.length; i++) {
      setState(() {
        activeIndex = i;
        steps[i].state = 'checking';
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      res = await api;
      if (!mounted || runId != _runId) return;

      if (res.error != null) {
        setState(() {
          phase = _Phase.error;
          errorMessage = res!.error;
          activeIndex = -1;
        });
        return;
      }

      // First time: switch to the steps the server actually checked
      if (!replaced) {
        replaced = true;
        final serverSteps = res.data!['steps'] is List ? res.data!['steps'] as List : [];
        if (serverSteps.isEmpty) {
          setState(() => steps = []);
          break;
        } else {
          setState(() {
            steps = serverSteps.map((s) {
              final m = s is Map ? s : {};
              return _CheckStep(m['area']?.toString() ?? '');
            }).toList();
            steps[0].state = 'checking';
          });
        }
        if (i >= steps.length) break;
      }


      final serverSteps = res.data!['steps'] is List ? res.data!['steps'] as List : [];
      final m = i < serverSteps.length && serverSteps[i] is Map ? serverSteps[i] as Map : {};
      setState(() {
        steps[i].state = _normState(m['state']?.toString());
        steps[i].text = m['text']?.toString() ?? '';
        revealed = i + 1;
      });
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || runId != _runId) return;
    }

    res ??= await api;
    if (!mounted || runId != _runId) return;
    if (res.error != null) {
      setState(() {
        phase = _Phase.error;
        errorMessage = res!.error;
      });
      return;
    }
    setState(() {
      result = res!.data;
      phase = _Phase.done;
      activeIndex = -1;
      revealed = steps.length;
    });
  }

  Future<void> createTicket(Map ticket) async {
    setState(() => isCreatingTicket = true);
    final payload = <String, dynamic>{
      "subject": ticket['subject']?.toString() ?? "Diagnose",
      "message": ticket['details']?.toString() ?? "",
      "priority": ticket['priority']?.toString() ?? "1",
      "group": ticket['group']?.toString() ?? "0",
      "tag": "",
      "close_otp_ver": "0",
    };
    if (ticket['ticket_template_id'] != null) {
      payload["ticket_template_id"] = ticket['ticket_template_id'].toString();
    }

    dynamic response;
    try {
      response = await BaseClient().multipartRequest(CREATE_TICKET_URL, payload, {}, context);
    } catch (e) {
      print("Diagnose ticket error :: $e");
      response = null;
    }
    if (!mounted) return;
    setState(() => isCreatingTicket = false);

    if (response != null && response['status'] == true) {
      successToast(response['message']?.toString() ?? "Complaint raised");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SupportTicketScreen()),
      );
    } else {
      errToast(response?['message']?.toString() ?? "Failed to raise complaint");
    }
  }

  Future<void> handleFix(Map fix) async {
    final action = fix['action']?.toString() ?? '';
    if (action == 'renew' || action == 'recharge') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RechargeScreen(isBack: true)),
      );
      return;
    }
    final url = fix['url']?.toString() ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      errToast("Couldn't open the link");
    }
  }

  // ---------------- helpers ----------------

  String _normState(String? s) {
    switch (s) {
      case 'ok':
      case 'pass':
        return 'ok';
      case 'fail':
      case 'error':
        return 'fail';
      case 'skipped':
        return 'skipped';
      default:
        return 'warn';
    }
  }

  String areaLabel(String area) {
    switch (area) {
      case 'plan':
        return "Your plan";
      case 'login':
        return "Your login";
      case 'connection':
        return "Your connection";
      case 'fibre':
      case 'fiber':
        return "Your fibre line";
      case 'device':
        return "Your device";
      default:
        return area.isEmpty ? "Check" : "Your ${area.replaceAll('_', ' ')}";
    }
  }

  String checkingText(String area) {
    switch (area) {
      case 'plan':
        return "Checking your plan...";
      case 'login':
        return "Checking router login...";
      case 'connection':
        return "Checking your connection...";
      case 'fibre':
      case 'fiber':
        return "Checking fibre line...";
      default:
        return "Checking...";
    }
  }

  Color stateColor(String state) {
    switch (state) {
      case 'ok':
        return AppColors.green;
      case 'fail':
        return AppColors.red;
      case 'skipped':
        return Colors.grey;
      default:
        return _orange;
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? Colors.white : Colors.black;
    final bar = _bottomBar(isDark);

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CustomAppbar(title: "Internet check"),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.h),

                      /// header while checking, solid status banner when done
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        child: phase == _Phase.done && result != null
                            ? _appear(_foundCard(isDark))
                            : _header(isDark, text),
                      ),
                      SizedBox(height: 14.h),
                      if (phase == _Phase.checking) ...[
                        _progress(),
                        SizedBox(height: 14.h),
                      ],
                      _checklist(isDark, text),
                      if (phase == _Phase.error && errorMessage != null) ...[
                        SizedBox(height: 14.h),
                        _errorBox(errorMessage!),
                      ],
                      if (phase == _Phase.done && result != null) _checkedRow(isDark, text),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              if (bar != null) bar,
            ],
          ),
        ),
      ),
    );
  }

  Widget _appear(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, -10 * (1 - v)), child: c),
      ),
      child: child,
    );
  }

  Widget _header(bool isDark, Color text) {
    String sub;
    switch (phase) {
      case _Phase.idle:
        sub = "Find out in a few seconds";
        break;
      case _Phase.checking:
        sub = "Checking your connection...";
        break;
      case _Phase.done:
        sub = "Checked just now";
        break;
      case _Phase.error:
        sub = "Couldn't finish the check";
        break;
    }
    return Row(
      children: [
        Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? .25 : .10),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.troubleshoot_rounded,
              color: isDark ? AppColors.secondary : AppColors.primary, size: 24.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Why is my internet not working?",
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  sub,
                  key: ValueKey(sub),
                  style: GoogleFonts.poppins(
                    color: text.withOpacity(.55),
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progress() {
    final value = steps.isEmpty
        ? 0.0
        : ((revealed + (activeIndex >= revealed ? .35 : 0)) / steps.length).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 5.h,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(.12),
        ),
      ),
    );
  }

  /// Solid status banner (colour from verdict.state)
  Widget _foundCard(bool isDark) {
    final verdict = result!['verdict'] is Map ? result!['verdict'] as Map : {};
    final state = _normState(verdict['state']?.toString());
    final c = stateColor(state == 'skipped' ? 'warn' : state);
    final icon = state == 'ok'
        ? Icons.check_circle_outline_rounded
        : state == 'fail'
            ? Icons.error_outline_rounded
            : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(18.r)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 26.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What we found",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  verdict['title']?.toString() ?? "Check complete",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if ((verdict['text']?.toString() ?? '').isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    verdict['text'].toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.92),
                      fontSize: 12.sp,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One white card, rows split by thin dividers.
  Widget _checklist(bool isDark, Color text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: text.withOpacity(.07)),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  _stepIcon(steps[i], isDark, text),
                  SizedBox(width: 12.w),
                  Expanded(child: _stepText(steps[i], text)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepIcon(_CheckStep s, bool isDark, Color text) {
    Widget inner;
    switch (s.state) {
      case 'checking':
        inner = SizedBox(
          width: 20.r,
          height: 20.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: isDark ? AppColors.secondary : AppColors.primary,
          ),
        );
        break;
      case 'ok':
        inner = Icon(Icons.check_circle_outline_rounded, color: AppColors.green, size: 26.r);
        break;
      case 'fail':
        inner = Icon(Icons.cancel_outlined, color: AppColors.red, size: 26.r);
        break;
      case 'skipped':
        inner = Icon(Icons.remove_circle_outline_rounded, color: text.withOpacity(.35), size: 26.r);
        break;
      case 'warn':
        inner = Icon(Icons.error_outline_rounded, color: _orange, size: 26.r);
        break;
      default: // waiting
        inner = Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: text.withOpacity(.25), shape: BoxShape.circle),
        );
    }

    return SizedBox(
      width: 28.r,
      height: 28.r,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
            child: child,
          ),
          child: KeyedSubtree(key: ValueKey(s.state), child: inner),
        ),
      ),
    );
  }

  Widget _stepText(_CheckStep s, Color text) {
    final isResult = s.state == 'ok' || s.state == 'fail' || s.state == 'skipped' || s.state == 'warn';
    final nameColor = s.state == 'waiting' ? text.withOpacity(.4) : text;

    String desc;
    Color descColor;
    if (s.state == 'checking') {
      desc = checkingText(s.area);
      descColor = AppColors.secondary;
    } else if (isResult) {
      desc = s.text.isEmpty ? "-" : s.text;
      descColor = text.withOpacity(.6);
    } else {
      desc = "Waiting";
      descColor = text.withOpacity(.35);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: GoogleFonts.poppins(
            color: nameColor,
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w500,
          ),
          child: Text(areaLabel(s.area)),
        ),
        SizedBox(height: 2.h),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            desc,
            key: ValueKey('${s.state}_$desc'),
            style: GoogleFonts.poppins(
              color: descColor,
              fontSize: 12.sp,
              fontStyle: s.state == 'skipped' ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// "Checked 15:53:13"  ...  "Check again"
  Widget _checkedRow(bool isDark, Color text) {
    final raw = result!['checked_at']?.toString() ?? '';
    final time = raw.contains(' ') ? raw.split(' ').last : raw;
    final accent = isDark ? AppColors.secondary : AppColors.primary;
    return _appear(
      Padding(
        padding: EdgeInsets.only(top: 6.h, left: 4.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                time.isNotEmpty ? "Checked $time" : "",
                style: GoogleFonts.poppins(color: text.withOpacity(.45), fontSize: 11.sp),
              ),
            ),
            TextButton.icon(
              onPressed: runDiagnose,
              icon: Icon(Icons.refresh_rounded, color: accent, size: 18.r),
              label: Text(
                "Check again",
                style: GoogleFonts.poppins(color: accent, fontSize: 12.5.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed bottom bar (native style). null = nothing to show.
  Widget? _bottomBar(bool isDark) {
    final buttons = <Widget>[];

    if (phase == _Phase.idle) {
      buttons.add(Expanded(
        child: PrimaryButton(title: "Start Check", icon: Icons.play_arrow_rounded, height: 48, onTap: runDiagnose),
      ));
    } else if (phase == _Phase.error) {
      buttons.add(Expanded(
        child: PrimaryButton(title: "Try Again", icon: Icons.refresh_rounded, height: 48, onTap: runDiagnose),
      ));
    } else if (phase == _Phase.done && result != null) {
      final data = result!;
      final Map fix = data['fix'] is Map ? data['fix'] as Map : {};
      final ticket = data['ticket'] is Map ? data['ticket'] as Map : null;
      final openTicket = data['open_ticket'];
      final hasOpenTicket = openTicket != null && openTicket != false;
      final canTicket = data['can_ticket'] == true && ticket != null;

      if ((fix['label']?.toString() ?? '').isNotEmpty) {
        buttons.add(Expanded(
          child: PrimaryButton(title: fix['label'].toString(), height: 48, onTap: () => handleFix(fix)),
        ));
      }
      if (hasOpenTicket) {
        buttons.add(Expanded(
          child: PrimaryButton(
            title: "View Complaint",
            height: 48,
            btnClr: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportTicketScreen()),
            ),
          ),
        ));
      } else if (canTicket) {
        buttons.add(Expanded(
          child: PrimaryButton(
            title: "Raise a complaint",
            height: 48,
            btnClr: _orange,
            isLoading: isCreatingTicket,
            onTap: isCreatingTicket ? null : () => createTicket(ticket!),
          ),
        ));
      }
    }

    if (buttons.isEmpty) return null;
    return _appear(
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(.08)),
          ),
        ),
        child: Row(
          children: [
            for (int i = 0; i < buttons.length; i++) ...[
              if (i > 0) SizedBox(width: 10.w),
              buttons[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: _orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _orange),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: _orange,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_widgets.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

/// Draw a signature with a finger. Pops with a PNG [File].
class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  bool _saving = false;

  bool get _isEmpty => _strokes.every((s) => s.length < 2);

  Future<void> _save() async {
    if (_isEmpty) {
      errToast("Please sign inside the box");
      return;
    }
    setState(() => _saving = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (e) {
      print("Signature save error :: $e");
      if (mounted) setState(() => _saving = false);
      errToast("Couldn't save the signature. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = KycColors.text(dark);

    return Scaffold(
      backgroundColor: KycColors.bg(dark),
      appBar: AppBar(
        backgroundColor: KycColors.bg(dark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Your signature",
            style: GoogleFonts.poppins(color: text, fontSize: 16.sp, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sign with your finger inside the box",
                  style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.5.sp)),
              SizedBox(height: 12.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // white so the saved image is clear
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.secondary.withOpacity(.5), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.r),
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: GestureDetector(
                        onPanStart: (d) => setState(() => _strokes.add([d.localPosition])),
                        onPanUpdate: (d) => setState(() => _strokes.last.add(d.localPosition)),
                        child: CustomPaint(
                          painter: _SignaturePainter(_strokes),
                          child: Stack(
                            children: [
                              if (_isEmpty)
                                Center(
                                  child: Text("Sign here",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black26, fontSize: 22.sp, fontWeight: FontWeight.w500)),
                                ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 40,
                                child: Container(height: 1, color: Colors.black12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => setState(() => _strokes.clear()),
                      icon: Icon(Icons.refresh_rounded, color: text),
                      label: Text("Clear",
                          style: GoogleFonts.poppins(color: text, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        side: BorderSide(color: text.withOpacity(.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: PrimaryButton(title: "Use signature", isLoading: _saving, onTap: _save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B2E59)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (int i = 1; i < s.length; i++) {
        final p0 = s[i - 1];
        final p1 = s[i];
        path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}

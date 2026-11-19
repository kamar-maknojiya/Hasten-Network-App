import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/SignaturePadScreen.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_service.dart';
import 'package:vision_broadband/screens/dashboard/Kyc/kyc_widgets.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

/// Opens the step-by-step upload sheet for one document.
/// [presetType] / [maxNow]: when adding the 2nd file to a document that already
/// has one (same document type, only the remaining slots).
/// Returns true when the upload finished.
Future<bool> showKycUploadSheet(BuildContext context, KycCategory category,
    {String? presetType, int? maxNow}) async {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: KycColors.card(dark),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
    builder: (_) => _KycUploadSheet(category: category, presetType: presetType, maxNow: maxNow),
  );
  return ok == true;
}

enum _Step { type, source, preview, uploading, done }

class _KycUploadSheet extends StatefulWidget {
  final KycCategory category;
  final String? presetType;
  final int? maxNow;
  const _KycUploadSheet({required this.category, this.presetType, this.maxNow});

  @override
  State<_KycUploadSheet> createState() => _KycUploadSheetState();
}

class _KycUploadSheetState extends State<_KycUploadSheet> {
  int get _maxBytes => KycService.lastConfig?.maxFileBytes ?? 5 * 1024 * 1024;
  String get _maxText => KycService.lastConfig?.maxFileText ?? "5 MB";
  bool get _allowPdf => KycService.lastConfig?.allowsPdf ?? true;
  final _picker = ImagePicker();

  late _Step step =
      widget.category.types.isEmpty || widget.presetType != null ? _Step.source : _Step.type;
  late String? docType = widget.presetType;
  int get _max => widget.maxNow ?? cat.maxFiles;
  final List<File> files = [];

  KycCategory get cat => widget.category;
  bool get isPhoto => cat.isPhoto;
  bool get isSignature => cat.isSignature;

  // ---------- picking ----------

  Future<void> _addFiles(List<File> picked) async {
    final room = _max - files.length;
    final ok = <File>[];
    for (final f in picked.take(room)) {
      if (await f.length() > _maxBytes) {
        errToast("${f.path.split('/').last} is larger than $_maxText");
      } else {
        ok.add(f);
      }
    }
    if (picked.length > room) errToast("You can add up to ${_max} file(s)");
    if (ok.isEmpty) return;
    setState(() {
      files.addAll(ok);
      step = _Step.preview;
    });
  }

  Future<void> _camera() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: isPhoto ? CameraDevice.front : CameraDevice.rear,
      );
      if (x != null) await _addFiles([File(x.path)]);
    } catch (e) {
      errToast("Couldn't open the camera");
    }
  }

  Future<void> _gallery() async {
    try {
      final room = _max - files.length;
      if (room > 1) {
        final xs = await _picker.pickMultiImage(imageQuality: 80, limit: room);
        await _addFiles(xs.map((x) => File(x.path)).toList());
      } else {
        final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (x != null) await _addFiles([File(x.path)]);
      }
    } catch (e) {
      errToast("Couldn't open the gallery");
    }
  }

  Future<void> _pdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: _max - files.length > 1,
    );
    if (res == null) return;
    await _addFiles(res.files.where((f) => f.path != null).map((f) => File(f.path!)).toList());
  }

  Future<void> _draw() async {
    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const SignaturePadScreen()),
    );
    if (file != null) await _addFiles([file]);
  }

  Future<void> _upload() async {
    setState(() => step = _Step.uploading);
    try {
      await KycService.upload(category: cat, documentType: docType, files: files);
      if (!mounted) return;
      setState(() => step = _Step.done);
    } catch (e) {
      if (!mounted) return;
      errToast(e.toString());
      setState(() => step = _Step.preview);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 18.h + MediaQuery.of(context).viewInsets.bottom),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(step),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 14.h),
                      decoration: BoxDecoration(
                        color: KycColors.sub(dark).withOpacity(.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  ..._content(dark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(bool dark) {
    switch (step) {
      case _Step.type:
        return _typeStep(dark);
      case _Step.source:
        return _sourceStep(dark);
      case _Step.preview:
        return _previewStep(dark, uploading: false);
      case _Step.uploading:
        return _previewStep(dark, uploading: true);
      case _Step.done:
        return _doneStep(dark);
    }
  }

  Widget _title(String t, String s, bool dark) => Padding(
        padding: EdgeInsets.only(bottom: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t,
                style: GoogleFonts.poppins(
                    color: KycColors.text(dark), fontSize: 16.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 2.h),
            Text(s, style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.sp)),
          ],
        ),
      );

  List<Widget> _typeStep(bool dark) => [
        _title(cat.title, "Which document will you upload?", dark),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 330.h),
          child: SingleChildScrollView(
            child: Column(
              children: cat.types.map((t) {
                final on = t == docType;
                return GestureDetector(
                  onTap: () => setState(() => docType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: on ? AppColors.primary.withOpacity(dark ? .25 : .08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: on ? KycColors.accent(dark) : KycColors.sub(dark).withOpacity(.3),
                        width: on ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(on ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: on ? KycColors.accent(dark) : KycColors.sub(dark), size: 20.r),
                        SizedBox(width: 10.w),
                        Text(t,
                            style: GoogleFonts.poppins(
                              color: KycColors.text(dark),
                              fontSize: 13.5.sp,
                              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        PrimaryButton(
          title: "Continue",
          onTap: docType == null ? () => errToast("Please select a document type") : () => setState(() => step = _Step.source),
        ),
      ];

  Widget _source(bool dark, IconData icon, String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: KycColors.iconBg(dark),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              children: [
                Icon(icon, color: KycColors.accent(dark), size: 28.r),
                SizedBox(height: 6.h),
                Text(label,
                    style: GoogleFonts.poppins(
                        color: KycColors.text(dark), fontSize: 12.sp, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );

  List<Widget> _sourceStep(bool dark) {
    final sources = <Widget>[];
    if (isSignature) {
      sources.add(_source(dark, Icons.draw_rounded, "Draw", _draw));
      sources.add(SizedBox(width: 10.w));
      sources.add(_source(dark, Icons.photo_library_outlined, "Gallery", _gallery));
    } else if (isPhoto) {
      sources.add(_source(dark, Icons.camera_front_outlined, "Selfie", _camera));
      sources.add(SizedBox(width: 10.w));
      sources.add(_source(dark, Icons.photo_library_outlined, "Gallery", _gallery));
    } else {
      sources.add(_source(dark, Icons.photo_camera_outlined, "Camera", _camera));
      sources.add(SizedBox(width: 10.w));
      sources.add(_source(dark, Icons.photo_library_outlined, "Gallery", _gallery));
      if (_allowPdf) {
        sources.add(SizedBox(width: 10.w));
        sources.add(_source(dark, Icons.picture_as_pdf_outlined, "PDF", _pdf));
      }
    }
    final tip = isSignature
        ? "Sign clearly, the same way as on official documents"
        : isPhoto
            ? "Face the camera in good light, no cap or sunglasses"
            : "Good light, all 4 corners visible, text readable";
    final remaining = _max - files.length;
    return [
      _title(
        "Add ${docType ?? cat.title}",
        widget.presetType != null
            ? "Add the back side of your ${widget.presetType}"
            : _max > 1
                ? "Front and back · up to $remaining more file(s)"
                : "1 file",
        dark,
      ),
      Row(children: sources),
      SizedBox(height: 14.h),
      Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: KycColors.amber, size: 16.r),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(tip, style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 11.5.sp)),
          ),
        ],
      ),
      if (cat.types.isNotEmpty && files.isEmpty && widget.presetType == null) ...[
        SizedBox(height: 8.h),
        Center(
          child: TextButton(
            onPressed: () => setState(() => step = _Step.type),
            child: Text("Change document type",
                style: GoogleFonts.poppins(color: KycColors.accent(dark), fontSize: 12.sp)),
          ),
        ),
      ],
    ];
  }

  List<Widget> _previewStep(bool dark, {required bool uploading}) => [
        _title(uploading ? "Uploading..." : "Check your files", "Make sure the text is clear and readable", dark),
        SizedBox(
          height: 110.h,
          child: Row(
            children: [
              for (int i = 0; i < files.length; i++) ...[
                if (i > 0) SizedBox(width: 10.w),
                Expanded(child: _thumb(files[i], dark, uploading)),
              ],
              if (!uploading && files.length < _max) ...[
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => step = _Step.source),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: KycColors.accent(dark).withOpacity(.5), width: 1.4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: KycColors.accent(dark)),
                          Text(_max > 1 ? "Add back side" : "Add",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: KycColors.accent(dark), fontSize: 11.sp)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 14.h),
        if (uploading)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: .92),
            duration: const Duration(milliseconds: 2200),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6.h,
                color: AppColors.secondary,
                backgroundColor: AppColors.secondary.withOpacity(.15),
              ),
            ),
          )
        else
          PrimaryButton(title: "Upload", icon: Icons.cloud_upload_outlined, onTap: _upload),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            "Uploaded documents can't be removed",
            style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 10.5.sp),
          ),
        ),
      ];

  Widget _thumb(File f, bool dark, bool uploading) {
    final isPdf = f.path.toLowerCase().endsWith('.pdf');
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: isPdf
                ? Container(
                    color: KycColors.iconBg(dark),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, color: AppColors.red, size: 30.r),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Text(f.path.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 9.sp)),
                        ),
                      ],
                    ),
                  )
                : Image.file(f, fit: BoxFit.cover),
          ),
        ),
        if (!uploading)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() {
                files.remove(f);
                if (files.isEmpty) step = _Step.source;
              }),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _doneStep(bool dark) => [
        SizedBox(height: 6.h),
        const Center(child: KycSuccessTick(size: 66)),
        SizedBox(height: 14.h),
        Center(
          child: Text("${cat.title} uploaded",
              style: GoogleFonts.poppins(
                  color: KycColors.text(dark), fontSize: 16.sp, fontWeight: FontWeight.w600)),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Text("We'll verify it shortly",
              style: GoogleFonts.poppins(color: KycColors.sub(dark), fontSize: 12.5.sp)),
        ),
        SizedBox(height: 18.h),
        PrimaryButton(title: "Done", onTap: () => Navigator.pop(context, true)),
      ];
}

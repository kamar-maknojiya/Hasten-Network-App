import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:printing/printing.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class InvoiceViewerScreen extends StatefulWidget {
  final invoiceId;

  const InvoiceViewerScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceViewerScreen> createState() => _InvoiceViewerScreenState();
}

class _InvoiceViewerScreenState extends State<InvoiceViewerScreen> {
  Uint8List? pdfBytes;
  String? savedPath;
  String isPrint = 'o';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPdf();
    getPermission();
  }

  Future<void> getPermission() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
      err,
    ) {
      return null;
    });
    if (!mounted) return;
    if (response != null && response['status'] == true) {
      final permission = response['data'];
      isPrint = permission['invoice_print'] ?? "0";
      isLoading = false;

      print('isPrint :: $isPrint');
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadPdf() async {
    try {
      final bytes = await BaseClient().downloadInvoicePdf(
        "$DOWNLOAD_INVOICES/${widget.invoiceId}",
        context,
      );
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/invoice_${widget.invoiceId}.pdf");
      await file.writeAsBytes(bytes);
      savedPath = file.path;
      if (!mounted) return;
      setState(() {
        pdfBytes = bytes;
        isLoading = false;
      });
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final snackBg = isDark ? AppColors.darkCard : AppColors.lightCard;
      final snackText = isDark ? Colors.white : Colors.black;


      final messenger = ScaffoldMessenger.of(context);

      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          backgroundColor: snackBg,
          behavior: SnackBarBehavior.floating,
          content: Text(
            "PDF downloaded successfully",
            style: GoogleFonts.poppins(color: snackText),
          ),
          action: SnackBarAction(
            label: "Open File",
            textColor: AppColors.primary,
            onPressed: () {
              if (savedPath != null) {
                OpenFile.open(savedPath!);
              }
            },
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          messenger.hideCurrentSnackBar();
        }
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     duration: const Duration(seconds: 5),
      //     backgroundColor: snackBg,
      //     behavior: SnackBarBehavior.floating,
      //     content: Text(
      //       "PDF downloaded successfully",
      //       style: GoogleFonts.poppins(
      //         color: snackText,
      //         fontSize: 12,
      //         fontWeight: FontWeight.w500,
      //       ),
      //     ),
      //     action: SnackBarAction(
      //       label: "Open File",
      //       textColor: AppColors.primary,
      //       onPressed: () {
      //         if (savedPath != null) {
      //           OpenFile.open(savedPath!);
      //         }
      //       },
      //     ),
      //   ),
      // );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(backgroundColor: Colors.black,
      //     content: Text(
      //       "PDF downloaded successfully",
      //       style: GoogleFonts.poppins(
      //         color: Colors.white,
      //         fontSize: 12,
      //         fontWeight: FontWeight.w500,
      //       ),
      //     ),
      //     action: SnackBarAction(
      //       label: "Open File",
      //       textColor: Colors.white,
      //       onPressed: () {
      //         if (savedPath != null) {
      //           OpenFile.open(savedPath!);
      //         }
      //       },
      //     ),
      //   ),
      // );
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          "PDF",
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isPrint == '1')
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () async {
                if (pdfBytes != null) {
                  await Printing.layoutPdf(
                    onLayout: (format) async => pdfBytes!,
                  );
                }
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animation/loading.json',
                height: 50,
                repeat: true,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(const ['**'], value: AppColors.primary),
                  ],
                ),
              ),
            )
          : Container(
              color: Colors.white,
              child: Theme(
                data: ThemeData.light(useMaterial3: false),
                child: Container(
                  color: Colors.white,
                  child: SfPdfViewer.memory(pdfBytes!, pageSpacing: 0),
                ),
              ),
            ),
      // body: isLoading
      //     ? Center(
      //         child: Lottie.asset(
      //           'assets/animation/loading.json',
      //           height: 60,
      //           repeat: true,
      //           delegates: LottieDelegates(
      //             values: [
      //               ValueDelegate.color(const ['**'], value: AppColors.primary),
      //             ],
      //           ),
      //         ),
      //       )
      //     : SfPdfViewer.memory(pdfBytes!),
    );
  }
}

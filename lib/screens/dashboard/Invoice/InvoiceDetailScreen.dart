import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/Invoice/PdfViewerScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/InvoiceDetailShimmer.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool isLoading = false;
  Map<String, dynamic>? invoiceDetails;
  List invoiceInfo = [];
  List taxes = [];

  @override
  void initState() {
    super.initState();
    getInvoicesDetails();
  }

  Future<void> getInvoicesDetails() async {
    setState(() {
      isLoading = true;
    });
    final int invoiceId = widget.invoiceId;
    var response = await BaseClient()
        .get("$GET_INVOICES_DETAILS/$invoiceId", context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });

    print('GET_INVOICES_DETAILS :: $GET_INVOICES_DETAILS/$invoiceId');
    print('response :: $response');

    if (response == null) {
      errToast("Error! Something went wrong");

      setState(() {
        isLoading = false;
      });
      return;
    }

    if (response['status'] == true) {
      setState(() {
        invoiceDetails = response['data'];
        invoiceInfo = response['data']['items'] ?? [];
        taxes = response['data']['taxes'] ?? [];
        isLoading = false;
      });

      print("Invoice No : ${invoiceDetails?['invoice_no']}");
      print("Grand Total : ${invoiceDetails?['grand_total']}");
    } else {
      errToast(response['message']);

      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String date) {
    try {
      return DateFormat('dd MMMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  // Future<void> downloadInvoicePdf() async {
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });
  //
  //     var invoiceId = invoiceDetails?['invoice_id'];
  //     final pdfBytes = await BaseClient().downloadInvoicePdf(
  //       "$DOWNLOAD_INVOICES/$invoiceId",
  //       context,
  //     );
  //
  //     print('DOWNLOAD_INVOICES :: $DOWNLOAD_INVOICES/$invoiceId');
  //
  //     if (pdfBytes == null) {
  //       errToast("Failed to load PDF");
  //       return;
  //     }
  //
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => PdfViewerScreen(
  //           pdfBytes: pdfBytes,
  //           fileName: "invoice_$invoiceId",
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     print(e);
  //     errToast("Something went wrong");
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// APP BAR
                CustomAppbar(title: 'Invoice Detail'),
                const SizedBox(height: 16),

                /// HEADER
                Expanded(
                  child: isLoading
                      ? const InvoiceDetailShimmer()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                          onRefresh: getInvoicesDetails,
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoiceDetails?['invoice_no'] ?? '',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.primary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          "${AppConfig.siteCurrency} ${invoiceDetails?['grand_total'] ?? ''}",
                                          style: GoogleFonts.poppins(
                                            color: text,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: invoiceDetails?['status_label'].toString() == 'Paid'
                                                ? AppColors.green.withOpacity(.15)
                                                : AppColors.red.withOpacity(.15),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            invoiceDetails!['status_label'].toString() ,
                                            style: GoogleFonts.poppins(
                                              color: invoiceDetails?['status_label'].toString() == 'Paid'
                                                  ? AppColors.green
                                                  : AppColors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    GestureDetector(
                                      onTap: () {
                                        var invoiceId = invoiceDetails?['invoice_id'];
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceViewerScreen(invoiceId: invoiceId)));
                                      },
                                      // onTap: () {
                                      //   downloadInvoicePdf();
                                      //   // TopAlert.show(
                                      //   //   context,
                                      //   //   title: "Success",
                                      //   //   message: "Your Invoice Download Successfully.",
                                      //   //   type: AlertType.success,
                                      //   // );
                                      // },
                                      child: Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(.20),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.download_rounded, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                /// DATES ROW
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Invoice Date",
                                              style: GoogleFonts.poppins(
                                                color: text.withOpacity(0.6),
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              formatDate(invoiceDetails?['invoice_date'] ?? ''),
                                              style: GoogleFonts.poppins(
                                                color: AppColors.green,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Due Date",
                                              style: GoogleFonts.poppins(
                                                color: text.withOpacity(0.6),
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              formatDate(
                                                invoiceDetails?['due_date'] ??
                                                    '',
                                              ),
                                              style: GoogleFonts.poppins(
                                                color: AppColors.red,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Last Paid",
                                              style: GoogleFonts.poppins(
                                                color: text.withOpacity(0.6),
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              formatDate(
                                                invoiceDetails?['last_paid_on'] ??
                                                    '',
                                              ),
                                              style: GoogleFonts.poppins(
                                                color: text,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  color: greyText.withOpacity(.25),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 12),

                                /// SUBSCRIBER INFO
                                Text(
                                  "Subscriber Info",
                                  style: GoogleFonts.poppins(
                                    color: text.withOpacity(.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: card,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      subscriptionRow(
                                        "Username",
                                        invoiceDetails?['sub_fullname'] ?? '',
                                        text,
                                        greyText,
                                      ),
                                      _divider(greyText),
                                      subscriptionRow(
                                        "Contact",
                                        invoiceDetails?['sub_contact_no'] !=
                                                null
                                            ? invoiceDetails!['sub_contact_no']
                                                  .toString()
                                            : "-",
                                        text,
                                        greyText,
                                      ),
                                      _divider(greyText),
                                      subscriptionRow(
                                        "Tax No",
                                        invoiceDetails?['sub_tax_no'] != null
                                            ? invoiceDetails!['sub_tax_no']
                                            : "-",
                                        text,
                                        greyText,
                                      ),
                                      _divider(greyText),
                                      subscriptionRow(
                                        "Address",
                                        invoiceDetails?['sub_address'] != null
                                            ? invoiceDetails!['sub_address']
                                            : "-",
                                        text,
                                        greyText,
                                      ),
                                      _divider(greyText),
                                      subscriptionRow(
                                        "Invoice Type",
                                        invoiceDetails?['invoice_type'] != null
                                            ? invoiceDetails!['invoice_type']
                                            : "-",
                                        text,
                                        greyText,
                                      ),
                                      _divider(greyText),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Status",
                                            style: GoogleFonts.poppins(
                                              color: text.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            invoiceDetails?['status_label'] == 'Paid'
                                                ? "Paid"
                                                : "Unpaid",
                                            style: GoogleFonts.poppins(
                                              color:
                                              invoiceDetails?['status_label'].toString() == 'Paid'
                                                  ? AppColors.green
                                                  : AppColors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                /// ITEM INFO
                                Text(
                                  "Item Info",
                                  style: GoogleFonts.poppins(
                                    color: text.withOpacity(.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: invoiceInfo.length,
                                  itemBuilder: (context, index) {
                                    final item = invoiceInfo[index];

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: card,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item['item_type'].toString()}.',
                                            style: GoogleFonts.poppins(
                                              color: text,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          // Container(
                                          //   width: 35,
                                          //   height: 35,
                                          //   decoration: BoxDecoration(
                                          //     color: AppColors.secondary
                                          //         .withOpacity(.15),
                                          //     borderRadius:
                                          //         BorderRadius.circular(10),
                                          //   ),
                                          //   child: Center(
                                          //     child: Text(
                                          //       item['item_type'].toString(),
                                          //       style: GoogleFonts.poppins(
                                          //         color: AppColors.secondary,
                                          //         fontSize: 16,
                                          //         fontWeight: FontWeight.w500,
                                          //       ),
                                          //     ),
                                          //   ),
                                          // ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['item_name'].toString(),
                                                  style: GoogleFonts.poppins(
                                                    color: text.withOpacity(.9),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  item['item_desc'].toString(),
                                                  style: GoogleFonts.poppins(
                                                    color: text.withOpacity(
                                                      0.6,
                                                    ),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withOpacity(.15),
                                                        borderRadius: BorderRadius.circular(100),
                                                      ),
                                                      child: Text(
                                                        "Package",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color: AppColors.primary,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Text(
                                                      "Qty: ${item['item_qty'].toString()}",
                                                      style: GoogleFonts.poppins(color: text.withOpacity(0.6), fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${AppConfig.siteCurrency} ${item['total_price'].toString()}',
                                                style: GoogleFonts.poppins(
                                                  color: text.withOpacity(.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                "Unit ${AppConfig.siteCurrency} ${item['unit_price'].toString()}",
                                                style: GoogleFonts.poppins(
                                                  color: text.withOpacity(0.6),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 30),

                                /// BILLING SUMMARY
                                Text(
                                  "Billing Summary",
                                  style: GoogleFonts.poppins(
                                    color: text.withOpacity(.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),

                                  child: Column(
                                    children: [
                                      billingRow(
                                        "Sub Total",
                                        "${AppConfig.siteCurrency} ${invoiceDetails?['subtotal'] ?? '0'}",
                                        text,
                                        greyText,
                                      ),

                                      _divider(greyText),

                                      billingRow(
                                        "Discount",
                                        "${AppConfig.siteCurrency} ${invoiceDetails?['discount_amount'] ?? '0'}",
                                        text,
                                        greyText,
                                      ),

                                      _divider(greyText),

                                      billingRow(
                                        "Taxable",
                                        "${AppConfig.siteCurrency} ${invoiceDetails?['subtotal'] ?? '0'}",
                                        text,
                                        greyText,
                                      ),

                                      _divider(greyText),

                                      billingRow(
                                        "Tax",
                                        "${AppConfig.siteCurrency} ${invoiceDetails?['total_tax_amount'] ?? '0'}",
                                        text,
                                        greyText,
                                      ),

                                      _divider(greyText),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Paid Amount",
                                            style: GoogleFonts.poppins(color: text.withOpacity(0.6), fontSize: 12),
                                          ),

                                          Text(
                                            "${AppConfig.siteCurrency} ${invoiceDetails?['paid_amount'] ?? '0'}",
                                            style: GoogleFonts.poppins(
                                              color: AppColors.green,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      _divider(greyText),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Receivable",
                                            style: GoogleFonts.poppins(color: text.withOpacity(0.6), fontSize: 12),
                                          ),

                                          Text(
                                            "${AppConfig.siteCurrency} ${invoiceDetails?['status_label'] == 'Overdue' ? invoiceDetails!['grand_total'].toString() : '0.0'}",
                                            style: GoogleFonts.poppins(
                                              color: AppColors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      _divider(greyText),

                                      const SizedBox(height: 0),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Grand Total",
                                            style: GoogleFonts.poppins(
                                              color: text.withOpacity(0.8),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          Text(
                                            "${AppConfig.siteCurrency} ${invoiceDetails?['grand_total'] ?? '0'}",
                                            style: GoogleFonts.poppins(
                                              color: text,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
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

  Widget _divider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),

      child: Divider(color: color.withOpacity(.20), height: 1),
    );
  }

  Widget subscriptionRow(String title, String value, Color text, Color grey) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: GoogleFonts.poppins(color: text.withOpacity(0.6), fontSize: 12),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget billingRow(String title, String value, Color text, Color grey) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: text.withOpacity(0.6),
            fontSize: 12,
          ),
        ),

        Text(
          value,
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

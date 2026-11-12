import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/Invoice/InvoiceDetailScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/InvoiceShimmer.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final TextEditingController searchController = TextEditingController();
  List filteredInvoices = [];
  bool isLoading = true;

  List invoices = [];

  @override
  void initState() {
    super.initState();
    loadAPI();

    searchController.addListener(_filterInvoices);
  }


  Future<void> loadAPI() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
    getUnPaidData(),
    getInvoicesData()
    ]);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  void _filterInvoices() {
    final query = searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredInvoices = List.from(invoices);
      } else {
        filteredInvoices = invoices.where((invoice) {
          return invoice['invoice_no'].toString().toLowerCase().contains(query) ||
              invoice['sub_fullname'].toString().toLowerCase().contains(query) ||
              invoice['invoice_type'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  double totalAmount = 0.0;
  double totalPaidAmount = 0.0;
  double totalUnPaidAmount = 0.0;

  Future<void> getUnPaidData() async {
    setState(() {
      isLoading = true;
    });

    var response = await BaseClient()
        .get(GET_UNPAID_AMOUNT, context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });
    print('GET_UNPAID_AMOUNT :: $GET_UNPAID_AMOUNT');
    print('response :: $response');
    if (response == null) {
      errToast("Error! Something went wrong");
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (response['status'] == true) {
      // totalUnPaidAmount = response['data'];
      totalUnPaidAmount = double.tryParse(response['data'].toString()) ?? 0.0;

      print("Total UnPaid Amount : $totalUnPaidAmount");
      setState(() {
        isLoading = false;
      });
    } else {
      errToast(response['message']);

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getInvoicesData() async {
    setState(() {
      isLoading = true;
    });

    var response = await BaseClient()
        .get(GET_INVOICES_DATA, context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });

    print('GET_INVOICES_DATA :: $GET_INVOICES_DATA');
    print('response :: $response');
    if (response == null) {
      errToast("Error! Something went wrong");
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (response['status'] == true) {
      final List invoicesList = response['data']['data'];

      invoices = invoicesList;
      filteredInvoices = List.from(invoicesList);

      // Reset totals
      totalAmount = 0.0;
      totalPaidAmount = 0.0;

      for (var invoice in invoicesList) {
        totalAmount +=
            double.tryParse(invoice['grand_total'].toString()) ?? 0.0;

        totalPaidAmount +=
            double.tryParse(invoice['paid_amount'].toString()) ?? 0.0;
      }

      print("Total Amount : $totalAmount");
      print("Total Paid Amount : $totalPaidAmount");

      setState(() {
        isLoading = false;
      });
    } else {
      errToast(response['message']);

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
    final greyText = isDark ? Colors.grey : Colors.black54;
    final subText = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: AppScaffold(
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  /// HEADER
                  CustomAppbar(title: 'Invoices'),
                  const SizedBox(height: 4),

                  /// TOTAL AMOUNT CARD
                  Expanded(
                    child: isLoading
                        ? const InvoiceShimmer()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
                            onRefresh: loadAPI,
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: card,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "TOTAL AMOUNT",
                                        style: GoogleFonts.poppins(
                                          color: text.withOpacity(0.6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),

                                      Text(
                                        "${AppConfig.siteCurrency} ${totalAmount.toStringAsFixed(2)}",
                                        style: GoogleFonts.poppins(
                                          color: AppColors.primary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                /// PAID + UNPAID
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "PAID",
                                              style: GoogleFonts.poppins(
                                                color: text.withOpacity(0.6),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              "${AppConfig.siteCurrency} ${totalPaidAmount.toStringAsFixed(2)}",
                                              style: GoogleFonts.poppins(
                                                color: AppColors.primary,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "UNPAID",
                                              style: GoogleFonts.poppins(
                                                color: text.withOpacity(0.6),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              "${AppConfig.siteCurrency} ${totalUnPaidAmount.toStringAsFixed(2)}",
                                              style: GoogleFonts.poppins(
                                                color: AppColors.orange,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                /// SEARCH BOX
                                TextField(
                                  controller: searchController,
                                  style: GoogleFonts.poppins(color: text, fontSize: 13.sp),
                                  decoration: InputDecoration(
                                    hintText: "Search Invoices",
                                    hintStyle: GoogleFonts.poppins(
                                      color: text,
                                      fontSize: 13.sp,
                                    ),
                                    filled: true,
                                    fillColor: card,
                                    contentPadding: EdgeInsets.all(10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.primary),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: text.withOpacity(.65),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                filteredInvoices.isEmpty
                                    ? Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: emptyState(card, text))
                                    : Expanded(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: filteredInvoices.length,
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (context, index) {
                                            final invoice = filteredInvoices[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoiceId: invoice['invoice_id'])));
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: card,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(.05),
                                                      blurRadius: 15,
                                                      offset: const Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  children: [
                                                    /// TOP ROW
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                invoice['invoice_no'].toString(),
                                                                style: GoogleFonts.poppins(
                                                                  color: AppColors.primary,
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                invoice['invoice_date'].toString(),
                                                                style: GoogleFonts.poppins(
                                                                  color: text.withOpacity(0.6),
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w400,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 2),
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(30),
                                                            color:
                                                                invoice['status_label'] == 'Paid'
                                                                ? AppColors.green.withOpacity(.15)
                                                                : invoice['status_label'] == 'Overdue'
                                                                ? AppColors.red.withOpacity(.15)
                                                                : invoice['status_label'] == 'Partial Paid'
                                                                    ? AppColors.secondary.withOpacity(.15)
                                                                    : AppColors.orange.withOpacity(.15),
                                                          ),
                                                          child: Text(
                                                            invoice['status_label'],
                                                            style: GoogleFonts.poppins(
                                                              color: invoice['status_label'] == 'Paid'
                                                                  ? AppColors.green
                                                                  : invoice['status_label'] == 'Overdue'
                                                                  ? AppColors.red
                                                                  : invoice['status_label'] == 'Partial Paid'
                                                                  ? AppColors.secondary
                                                                  : AppColors.orange,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),

                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),

                                                    /// GRAND TOTAL / PAID / TYPE
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                "Grand Total",
                                                                style: GoogleFonts.poppins(
                                                                  color: text.withOpacity(0.6),
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w400,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                invoice['grand_total'].toString(),
                                                                style: GoogleFonts.poppins(
                                                                  color: text,
                                                                  fontSize: 14,
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
                                                                "Paid",
                                                                style: GoogleFonts.poppins(
                                                                  color: text.withOpacity(0.6),
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w400,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                invoice['paid_amount'].toString(),
                                                                style: GoogleFonts.poppins(
                                                                  color: AppColors.green,
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              "Type",
                                                              style: GoogleFonts.poppins(
                                                                color: text.withOpacity(0.6),
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w400,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              "On Recharge",
                                                              style: GoogleFonts.poppins(
                                                                color: text,
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Divider(color: isDark ? Colors.white24 : Colors.black12),
                                                    const SizedBox(height: 6),

                                                    /// BOTTOM ROW
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "Due: ${invoice['due_date'] != null ? invoice['due_date'].toString() : ''}",
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  color: text.withOpacity(0.6),
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {},
                                                          child: Text(
                                                            "See Detail",
                                                            style: GoogleFonts.poppins(
                                                                  color: text.withOpacity(0.9),
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget emptyState(Color card, Color textClr) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_sharp,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              "You don't have any Invoices",
              style: GoogleFonts.poppins(
                color: textClr,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No Invoices Found',
              style: GoogleFonts.poppins(
                color: textClr.withOpacity(0.5),
                fontSize: 12.sp,
                // fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

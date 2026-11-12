import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/PaymentWebViewScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/CacheHelper.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class PaymentSummaryScreen extends StatefulWidget {
  final packageId;
  const PaymentSummaryScreen({super.key, required this.packageId});

  @override
  State<PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen> {
  int quantity = 1;
  bool isLoading = false;
  bool isRecharge = false;
  String isSpeed = "1";
  String isQuantity = "0";
  double price = 100.00;
  double gstPercent = 18;

  String selectedPaymentType = "pg";
  String selectedGateway = '';
  List<dynamic> gateways = [];
  Map<String, dynamic>? paymentSummary;
  List<dynamic> invoiceTaxes = [];

  // double get unitPrice =>
  //     double.tryParse(paymentSummary?['price']?.toString() ?? '0') ?? 0;
  //
  // double get subtotal => unitPrice * quantity;
  //
  // double get taxPercent =>
  //     double.tryParse(
  //       invoiceTaxes.isNotEmpty ? invoiceTaxes[0]['tax_per'].toString() : '0',
  //     ) ??
  //     0;
  //
  // // double get taxAmount => subtotal * taxPercent / 100;
  // double get taxAmount => double.tryParse(
  //   invoiceTaxes.isNotEmpty ? invoiceTaxes[0]['tax_amount'].toString() : '0',
  // ) ??
  //     0;
  //
  // double get grandTotal => subtotal + taxAmount;




  double get unitPrice => (double.tryParse(paymentSummary?['price']?.toString() ?? '0') ?? 0);

  double get subtotal => (paymentSummary?['subtotal'] as num?)?.toDouble() ?? 0;

  double get discountAmount => (paymentSummary?['discount_amount'] as num?)?.toDouble() ?? 0;

  double get subtotalFinal => (paymentSummary?['subtotal_final'] as num?)?.toDouble() ?? 0;

  double get totalTax => (paymentSummary?['total_tax_amount'] as num?)?.toDouble() ?? 0;

  double get grandTotal => (paymentSummary?['grand_total'] as num?)?.toDouble() ?? 0;

  @override
  void initState() {
    super.initState();
    getPaymentSummary();
    getPermission();
    getPaymentGatewayList();
  }

  Future<void> getPermission() async {
    var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((err) {
      print(err);
      return null;
    });

    if (!mounted) return;

    if (response != null && response['status'] == true) {
      final permission = response['data'];

      // Save latest permission
      await CacheHelper.save("summary_cache", permission);

      setState(() {
        isSpeed = permission['hide_package_speed'] ?? "1";
        isQuantity = permission['sub_can_recharge_with_qty'] ?? "0";
        print("isSpeed:-----");
        print(isSpeed);
        print("isQuantity:-----");
        print(isQuantity);
      });
    } else {
      // Load cached permission
      final cache = await CacheHelper.read("summary_cache");

      if (cache != null) {
        setState(() {
          isSpeed = cache['hide_package_speed'] ?? "1";
          isQuantity = cache['sub_can_recharge_with_qty'] ?? "0";
          // isBandWidth = cache['bandwidth'] ?? "0";
        });

        errToast(response?['message'] ?? "Showing last saved permissions");
      } else {
        errToast(response?['message'] ?? "No permission data available");
      }
    }
  }

  void getPaymentSummary() async {
    setState(() {
      isLoading = true;
    });
    int packageId = widget.packageId;
    var response = await BaseClient().get("$GET_PAYMENT_SUMMARY?package_id=$packageId&quantity=$quantity", context).catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });

    print('GET_PAYMENT_SUMMARY :: $GET_PAYMENT_SUMMARY?package_id=$packageId');
    print('response :: $response');

    if (response != null && response['status'] == true) {
      setState(() {
        paymentSummary = response['data'];
        invoiceTaxes = response['data']['invoice_taxes'] ?? [];
        isLoading = false;
      });

      print("Package Name : ${paymentSummary?['package_name']}");
      print("Subtotal : ${paymentSummary?['subtotal']}");
      print("Grand Total : ${paymentSummary?['grand_total']}");
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
  void getRefreshPaymentSummary() async {

    int packageId = widget.packageId;
    var response = await BaseClient().get("$GET_PAYMENT_SUMMARY?package_id=$packageId&quantity=$quantity", context).catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });

    print('GET_PAYMENT_SUMMARY :: $GET_PAYMENT_SUMMARY?package_id=$packageId');
    print('response :: $response');

    if (response != null && response['status'] == true) {
      setState(() {
        paymentSummary = response['data'];
        invoiceTaxes = response['data']['invoice_taxes'] ?? [];
      });

      print("Package Name : ${paymentSummary?['package_name']}");
      print("Subtotal : ${paymentSummary?['subtotal']}");
      print("Grand Total : ${paymentSummary?['grand_total']}");
    } else {
    }
  }

  // void getPaymentGatewayList() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   var response = await BaseClient()
  //       .get(GET_PAYMENT_GATEWAY, context)
  //       .catchError((err) {
  //         errToast("Error! Something went wrong");
  //         print(err);
  //       });
  //
  //   print('GET_PAYMENT_GATEWAY :: $GET_PAYMENT_GATEWAY');
  //   print('response :: $response');
  //
  //   if (response != null && response['status'] == true) {
  //     setState(() {
  //       gateways = response['data'];
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  void getPaymentGatewayList() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient().get(GET_PAYMENT_GATEWAY, context).catchError((err) {
      errToast("Error! Something went wrong");
      print(err);
    });

    print('GET_PAYMENT_GATEWAY :: $GET_PAYMENT_GATEWAY');
    print('response :: $response');

    if (response != null && response['status'] == true) {
      setState(() {
        gateways = response['data'];
        isLoading = false;
        // Auto select first gateway
        if (selectedPaymentType == "pg" && gateways.isNotEmpty) {
          selectedGateway = gateways.first.toString();
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatUptimeLimit(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "Unlimited";
    }
    final text = value.toString().trim();
    if (text.toLowerCase() == "unlimited") {
      return "Unlimited";
    }
    // Extract number from values like "1.00 GB", "1.27GB"
    final match = RegExp(r'([\d.]+)').firstMatch(text);

    if (match != null) {
      final num gb = double.tryParse(match.group(1)!) ?? 0;
      // Remove trailing .0
      if (gb == gb.roundToDouble()) {
        return "${gb.toInt()} GB";
      }
      return "${gb.toStringAsFixed(1)} GB";
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final secondaryText = isDark ? Colors.white60 : Colors.black54;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: PrimaryButton(
              title: 'Pay Now ${AppConfig.siteCurrency} ${grandTotal.toStringAsFixed(2)}',
              icon: Icons.payment,
              isLoading: isRecharge,
              onTap: () {
                makePayment();
                // TopAlert.show(
                //   context,
                //   title: "Success",
                //   message: "Your Payment Successfully receive.",
                //   type: AlertType.success,
                // );
              },
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                /// APPBAR
                CustomAppbar(title: "Payment Summary"),
                const SizedBox(height: 6),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: Lottie.asset(
                            'assets/animation/loading.json',
                            height: 50,
                            repeat: true,
                            delegates: LottieDelegates(
                              values: [
                                ValueDelegate.color(const [
                                  '**',
                                ], value: AppColors.primary),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Package Detail",
                                        style: GoogleFonts.poppins(
                                          color: text.withOpacity(.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    buildRow("Package", paymentSummary?['package_name'] ?? '', text, secondaryText),
                                    _divider(),
                                    buildRow("Type", paymentSummary?['package_type'] == '0' ? "Regular" : '', AppColors.primary, secondaryText),
                                    _divider(),
                                     if(isSpeed == "0") buildRow("Speed", paymentSummary?['speed']?.toString() ?? '', text, secondaryText),
                                    if(isSpeed == "0") _divider(),
                                    buildRow("Data Limit", formatUptimeLimit(paymentSummary?['data_limit']), text, secondaryText),
                                    _divider(),
                                    buildRow("Uptime Limit", formatUptimeLimit(paymentSummary?['uptime_limit']), text, secondaryText),
                                    _divider(),
                                    buildRow("Expiration", paymentSummary?['expiration_limit']?.toString() ?? '', text, secondaryText),
                                    _divider(),
                                    buildRow("Price", "${AppConfig.siteCurrency} ${unitPrice.toStringAsFixed(2)}", text, secondaryText),
                                    _divider(),

                                    /// QUANTITY
                                    Row(
                                      children: [
                                        Expanded(child: Text("Quantity", style: GoogleFonts.poppins(color: text.withOpacity(0.6), fontSize: 12))),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(.15), borderRadius: BorderRadius.circular(6)),
                                          child: isQuantity == "1" ? Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  if (quantity > 1) {
                                                    setState(() {
                                                      quantity--;
                                                      getRefreshPaymentSummary();
                                                    });
                                                  }
                                                },
                                                child: Text("−", style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                quantity.toString(),
                                                style: GoogleFonts.poppins(color: text, fontSize: 13, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(width: 16),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    quantity++;
                                                    getRefreshPaymentSummary();
                                                  });
                                                },

                                                child: Text("+", style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ) : Text("1"),
                                        ),
                                      ],
                                    ),

                                    _divider(),

                                    /// SUBTOTAL
                                    buildRow("Sub Total", "${AppConfig.siteCurrency} ${subtotal.toStringAsFixed(2)}", text, secondaryText),
                                    _divider(),

                                    /// GST
                                    if (invoiceTaxes.isNotEmpty)
                                      ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: invoiceTaxes.length,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return Column(
                                            children: [
                                              buildRow(
                                                "${invoiceTaxes[index]['tax_name']} (${invoiceTaxes[index]['tax_per']}%)",
                                                "+ ${AppConfig.siteCurrency} ${invoiceTaxes[index]['tax_amount'].toStringAsFixed(2)}",
                                                AppColors.orange,
                                                secondaryText,
                                              ),
                                              _divider(),
                                            ],
                                          );
                                        },
                                      ),

                                    // buildRow(
                                    //   "${invoiceTaxes[0]['tax_name']} (${invoiceTaxes[0]['tax_per']}%)",
                                    //   "+ ${AppConfig.siteCurrency} ${taxAmount.toStringAsFixed(2)}",
                                    //   AppColors.orange,
                                    //   secondaryText,
                                    // ),
                                    // const SizedBox(height: 5),

                                    /// GRAND TOTAL
                                    Row(
                                      children: [
                                        Expanded(child: Text("Grand Total", style: GoogleFonts.poppins(color: text.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w600))),
                                        Text(
                                          "${AppConfig.siteCurrency} ${grandTotal.toStringAsFixed(2)}",
                                          style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedPaymentType,
                                    isExpanded: true,
                                    dropdownColor: card,
                                    items: [
                                      DropdownMenuItem(
                                        value: "wallet",
                                        child: Text("Wallet", style: GoogleFonts.poppins(color: text, fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                      DropdownMenuItem(
                                        value: "pg",
                                        child: Text("Payment Gateway", style: GoogleFonts.poppins(color: text, fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                    // onChanged: (value) {
                                    //   setState(() {
                                    //     selectedPaymentType = value!;
                                    //
                                    //     if (selectedPaymentType == "wallet") {
                                    //       selectedGateway = '';
                                    //     }
                                    //   });
                                    // },
                                    onChanged: (value) {
                                      setState(() {
                                        selectedPaymentType = value!;
                                        if (selectedPaymentType == "wallet") {
                                          selectedGateway = '';
                                        } else if (selectedPaymentType == "pg") {
                                          selectedGateway = gateways.isNotEmpty ? gateways.first.toString() : '';
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (selectedPaymentType == "pg")
                                ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: gateways.length,
                                  itemBuilder: (context, index) {
                                    final gateway = gateways[index];
                                    final selected = selectedGateway == gateway;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedGateway = gateway;
                                        });
                                      },

                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: selected ? AppColors.primary.withOpacity(.15) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: selected ? AppColors.primary : isDark ? Colors.white54 : Colors.black26),
                                        ),

                                        child: Row(
                                          children: [
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: selected ? AppColors.primary : isDark ? Colors.white54 : Colors.black38, width: 2),
                                              ),
                                              child: selected
                                                  ? Center(child: Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary))) : null,
                                            ),

                                            const SizedBox(width: 18),
                                            Expanded(
                                              child: Text(gateway, style: GoogleFonts.poppins(color: text, fontSize: 14, fontWeight: FontWeight.w500)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
    );
  }

  Future<void> makePayment() async {
    setState(() {
      isRecharge = true;
    });
    int packageId = widget.packageId;
    try {
      final payload = {
        "package_id": widget.packageId.toString(),
        "payment_method": selectedPaymentType.toString(),
        "quantity": quantity.toString(),
      };

      if (selectedPaymentType == "pg") {
        payload["pg_name"] = selectedGateway.toString();
      }

      print('payload :: $payload');

      var response = await BaseClient().post(
        ADD_RECHARGE_REQUEST,
        payload,
        context,
      );
      print('ADD_RECHARGE_REQUEST :: $ADD_RECHARGE_REQUEST');
      print('response :: $response');
      if (!mounted) return;
      setState(() {
        isRecharge = false;
      });
      if (response == null) {
        errToast("Error! Something went wrong");
        return;
      }
      if (response['status'] == true) {
        if (selectedPaymentType == "pg") {
          String paymentUrl = response['data']['url'].toString();
          String orderId = response['data']['order_id'].toString();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentWebViewScreen(
                paymentUrl: paymentUrl,
                orderId: orderId,
              ),
            ),
          );
        } else {
          TopAlert.show(
            context,
            // title: "",
            message: response['message'] ?? "Recharge successfully",
            type: AlertType.success,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BottomNavScreen()),
          );
        }
      } else {
        TopAlert.show(
          context,
          // title: "",
          message: response['message'] ?? "Error! Something went wrong",
          type: AlertType.warning,
        );
        // errToast(response['message'] ?? "Error! Something went wrong");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isRecharge = false;
      });
      errToast("Error! Something went wrong");
    }
  }

  // Future<void> checkPaymentStatus(String orderId) async {
  //   try {
  //     // showLoader();
  //
  //     final response = await BaseClient().get(
  //       "$GET_PAYMENT_STATUS/$orderId",
  //       context,
  //     );
  //
  //     // hideLoader();
  //
  //     print("PAYMENT STATUS RESPONSE => $response");
  //
  //     if (response == null) {
  //       errToast("Unable to verify payment");
  //       return;
  //     }
  //
  //     if (response['status'] != true) {
  //       errToast(response['message'] ?? "Payment verification failed");
  //       return;
  //     }
  //
  //     String paymentStatus = response['data']['status']
  //         .toString()
  //         .toLowerCase();
  //
  //     if (paymentStatus == "paid") {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
  //       );
  //     } else if (paymentStatus == "processing") {
  //       await Future.delayed(const Duration(seconds: 5));
  //
  //       await checkPaymentStatus(orderId);
  //     } else {
  //       errToast("Payment Failed");
  //     }
  //   } catch (e) {
  //     // hideLoader();
  //
  //     errToast("Error checking payment status");
  //
  //     print(e);
  //   }
  // }

  // Future<void> checkPaymentStatus(String orderId) async {
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });
  //
  //     var prefs = await SharedPreferences.getInstance();
  //     var token = prefs.getString('token');
  //
  //     final response = await http.get(
  //       Uri.parse("$GET_PAYMENT_STATUS/$orderId"),
  //       headers: {
  //         "Accept": "text/event-stream",
  //         "Authorization": "Bearer $token",
  //       },
  //     );
  //
  //     print("STATUS CODE => ${response.statusCode}");
  //     print("BODY => ${response.body}");
  //
  //     setState(() {
  //       isLoading = false;
  //     });
  //
  //     if (response.statusCode != 200) {
  //       errToast("Unable to verify payment");
  //       return;
  //     }
  //
  //     /// SSE Response:
  //     /// event: payment_status
  //     /// data: {"status":true,"status_code":"Paid","message":"Your Payment is paid successfully."}
  //
  //     final dataLine = response.body
  //         .split('\n')
  //         .firstWhere((line) => line.startsWith('data:'), orElse: () => '');
  //
  //     if (dataLine.isEmpty) {
  //       errToast("Invalid payment response");
  //       return;
  //     }
  //
  //     final jsonString = dataLine.replaceFirst('data:', '').trim();
  //
  //     final data = jsonDecode(jsonString);
  //
  //     print("PARSED DATA => $data");
  //
  //     if (data['status'] == true) {
  //       final statusCode = data['status_code'].toString().toLowerCase();
  //
  //       if (statusCode == "paid") {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
  //         );
  //       } else if (statusCode == "processing") {
  //         errToast("Payment is processing");
  //       } else if (statusCode == "failed") {
  //         errToast("Payment Failed");
  //       } else if (statusCode == "cancelled") {
  //         errToast("Payment Cancelled");
  //       } else {
  //         errToast(data['message']);
  //       }
  //     } else {
  //       errToast(data['message']);
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //
  //     print("PAYMENT STATUS ERROR => $e");
  //
  //     errToast("Unable to verify payment");
  //   }
  // }

  Widget buildRow(
      String title,
      String value,
      Color valueColor,
      Color titleColor,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            textAlign: TextAlign.start,
            style: GoogleFonts.poppins(
              color: titleColor.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Widget buildRow(
  //   String title,
  //   String value,
  //   Color valueColor,
  //   Color titleColor,
  // ) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Expanded(
  //         flex: 2,
  //         child: Text(
  //           title,
  //           style: GoogleFonts.poppins(
  //             color: titleColor.withOpacity(0.6),
  //             fontSize: 12,
  //           ),
  //         ),
  //       ),
  //       Expanded(
  //         flex: 3,
  //         child: Text(
  //           value,
  //           style: GoogleFonts.poppins(
  //             color: valueColor,
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _divider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: isDark ? Colors.white12 : Colors.black12),
    );
  }
}

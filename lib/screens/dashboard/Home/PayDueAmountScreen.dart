import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/PaymentWebViewScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class PayDueAmountScreen extends StatefulWidget {
  final dueAmount;
  const PayDueAmountScreen({super.key, required this.dueAmount});

  @override
  State<PayDueAmountScreen> createState() => _PayDueAmountScreenState();
}

class _PayDueAmountScreenState extends State<PayDueAmountScreen> {
  TextEditingController dueAmountController = TextEditingController();
  double payableAmount = 0.0;
  double price = 100.00;
  double gstPercent = 18;
  bool isLoading = false;
  bool isRecharge = false;

  String selectedPaymentType = "pg";
  String selectedGateway = '';
  List<dynamic> gateways = [];

  @override
  void initState() {
    super.initState();
    getPaymentGatewayList();
    dueAmountController.text = widget.dueAmount;
    payableAmount = double.tryParse(widget.dueAmount) ?? 0.0;
    dueAmountController.addListener(() {
      setState(() {
        payableAmount = double.tryParse(dueAmountController.text.trim()) ?? 0.0;
      });
    });
  }

  void getPaymentGatewayList() async {
    setState(() {
      isLoading = true;
    });

    var response = await BaseClient()
        .get(GET_PAYMENT_GATEWAY, context)
        .catchError((err) {
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

  // Future<void> makePayment() async {
  //   setState(() {
  //     isRecharge = true;
  //   });
  //   try {
  //     final payload = {
  //       "payment_method": selectedPaymentType.toString(),
  //       "amount": dueAmountController.text.toString(),
  //     };
  //
  //     if (selectedPaymentType == "pg") {
  //       payload["pg_name"] = selectedGateway.toString();
  //     }
  //
  //     print('payload :: $payload');
  //
  //     var response = await BaseClient().post(ADD_PAYMENT, payload, context);
  //     if (!mounted) return;
  //     setState(() {
  //       isRecharge = false;
  //     });
  //     if (response == null) {
  //       errToast("Error! Something went wrong");
  //       return;
  //     }
  //     if (response['status'] == true) {
  //       String paymentUrl = response['data']['url'].toString();
  //       String orderId = response['data']['order_id'].toString();
  //
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) =>
  //               PaymentWebViewScreen(paymentUrl: paymentUrl, orderId: orderId),
  //         ),
  //       );
  //     } else {
  //       TopAlert.show(
  //         context,
  //         // title: "Failed",
  //         message: response['message'] ?? "Error! Something went wrong",
  //         type: AlertType.error,
  //       );
  //       // errToast(response['message'] ?? "Error! Something went wrong");
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       isRecharge = false;
  //     });
  //     errToast("Error! Something went wrong");
  //   }
  // }

  Future<void> makePayment() async {
    setState(() {
      isRecharge = true;
    });
    try {
      final payload = {
        "payment_method": selectedPaymentType.toString(),
        "amount": dueAmountController.text.toString(),
      };
      if (selectedPaymentType == "pg") {
        payload["pg_name"] = selectedGateway.toString();
      }

      print('payload :: $payload');
      var response = await BaseClient().post(ADD_PAYMENT, payload, context);
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl, orderId: orderId)));
        } else {
          TopAlert.show(
            context,
            message: response['message'] ?? "Recharge successfully",
            type: AlertType.success,
          );
          Navigator.push(context, MaterialPageRoute(builder: (_) => BottomNavScreen()));
        }
      } else {
        TopAlert.show(
          context,
          message: response['message'] ?? "Error! Something went wrong",
          type: AlertType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isRecharge = false;
      });
      errToast("Error! Something went wrong");
    }
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
              title: 'Pay Now ${AppConfig.siteCurrency} ${payableAmount.toStringAsFixed(2)}',
              icon: Icons.payment,
              isLoading: isRecharge,
              onTap: () {
                makePayment();
              },
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                /// APPBAR
                CustomAppbar(title: 'Pay Due Amount'),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Text(
                                "Due Payment",
                                style: GoogleFonts.poppins(color: text, fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "${AppConfig.siteCurrency} ${widget.dueAmount}",
                                style: GoogleFonts.poppins(color: AppColors.orange, fontSize: 25.sp, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "Outstanding balance",
                                style: GoogleFonts.poppins(color: text.withOpacity(0.8), fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "* Amount",
                                style: GoogleFonts.poppins(color: text.withOpacity(.75), fontSize: 12.sp, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: dueAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: 'Enter Amount',
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(.08),
                                    contentPadding: EdgeInsets.all(10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.primary),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.withOpacity(.3)),
                                    ),
                                  ),
                                ),
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
                                  child: Text(
                                    "Wallet",
                                    style: GoogleFonts.poppins(color: text, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "pg",
                                  child: Text(
                                    "Payment Gateway",
                                    style: GoogleFonts.poppins(color: text, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
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
                                          border: Border.all(color: selected ? AppColors.primary : isDark ? Colors.white54 : Colors.black38, width: 2)),
                                        child: selected
                                            ? Center(child: Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)))
                                            : null,
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Text(
                                          gateway,
                                          style: GoogleFonts.poppins(color: text, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
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
}

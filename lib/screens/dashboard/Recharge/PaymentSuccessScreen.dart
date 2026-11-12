import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/screens/dashboard/Home/LedgerScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final orderId;
  const PaymentSuccessScreen({super.key, this.orderId});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white60 : Colors.black54;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              // Success Icon
              Container(
                // margin: const EdgeInsets.all(30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Icon(Icons.done_rounded, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 30),
              Text(
                "Recharge Successfully",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Your payment has been processed successfully.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: text.withOpacity(0.5),
                ),
              ),
              if (widget.orderId.isNotEmpty) const SizedBox(height: 35),

              /// Order ID Card
              if (widget.orderId.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order ID",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: subText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              // 'ORDOPWOM2JJQNE6LZO',
                              widget.orderId ?? "-",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.orderId ?? ""),
                          );
                          successToast('Order ID copied');
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              PrimaryButton(
                title: 'Back to Home',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => BottomNavScreen()),
                  );
                },
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentFailedScreen extends StatefulWidget {
  final String? orderId;

  const PaymentFailedScreen({super.key, this.orderId});

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final subText = text.withOpacity(0.6);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              /// Failed Icon
              Container(
                // margin: const EdgeInsets.all(30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                ),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 30),

              /// Title
              Text(
                "Payment Failed",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              /// Subtitle
              Text(
                "We couldn't process your payment.\nPlease try again.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: text.withOpacity(0.5),
                ),
              ),

              if (widget.orderId!.isNotEmpty) const SizedBox(height: 35),

              /// Order ID Card
              if (widget.orderId!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order ID",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: subText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.orderId ?? "-",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.orderId ?? ""),
                          );
                          successToast('Order ID copied');
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              /// Back Button
              PrimaryButton(
                title: "Back to Home",
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavScreen()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
// class PaymentFailedScreen extends StatefulWidget {
//   final orderId;
//   const PaymentFailedScreen({super.key, this.orderId});
//
//   @override
//   State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
// }
//
// class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
//     final text = isDark ? Colors.white : Colors.black;
//
//     return Scaffold(
//       backgroundColor: bg,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             children: [
//               const Spacer(),
//
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: const BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.red,
//                 ),
//                 child: const Icon(
//                   Icons.error_outline_rounded,
//                   color: Colors.white,
//                   size: 60,
//                 ),
//               ),
//
//               const SizedBox(height: 30),
//
//               Text(
//                 "Payment Failed",
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   color: text,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               Text(
//                 "We couldn't process your payment. Please try again.",
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 15,
//                   color: text.withOpacity(0.5),
//                 ),
//               ),
//
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.withOpacity(0.09),
//                   borderRadius: BorderRadius.circular(12.r),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("SSID", style: GoogleFonts.poppins(color: subText, fontSize: 12.sp)),
//                     Text(Widget.orderId,
//                       style: GoogleFonts.poppins(
//                         color: AppColors.primary,
//                         fontSize: 14.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const Spacer(),
//
//               PrimaryButton(
//                 title: "Back to Home",
//                 onTap: () {
//                   Navigator.of(context).pushAndRemoveUntil(
//                     MaterialPageRoute(builder: (_) => const BottomNavScreen()),
//                     (route) => false,
//                   );
//                 },
//               ),
//
//               const SizedBox(height: 25),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class PaymentCancelledScreen extends StatelessWidget {
  final orderId;
  const PaymentCancelledScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade600,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "Payment Cancelled",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "You cancelled the payment process. No amount has been deducted.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: text.withOpacity(0.5),
                ),
              ),

              const Spacer(),

              PrimaryButton(
                title: "Try Again",
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

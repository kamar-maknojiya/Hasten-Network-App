import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class InvoiceShimmer extends StatelessWidget {
  const InvoiceShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // const SizedBox(height: 10),
            //
            // /// TITLE
            // const Align(
            //   alignment: Alignment.centerLeft,
            //   child: ShimmerBox(width: 120, height: 24),
            // ),
            //
            // const SizedBox(height: 20),

            /// TOTAL AMOUNT CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 90, height: 10),

                  SizedBox(height: 10),

                  ShimmerBox(width: 140, height: 18),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// PAID + UNPAID
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 50, height: 10),

                        SizedBox(height: 10),

                        ShimmerBox(width: 100, height: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 60, height: 10),

                        SizedBox(height: 10),

                        ShimmerBox(width: 100, height: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// SEARCH
            const ShimmerBox(width: double.infinity, height: 52, radius: 12),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: 6,
                padding: EdgeInsets.zero,
                itemBuilder: (_, __) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        /// TOP
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  ShimmerBox(width: 140, height: 16),

                                  SizedBox(height: 8),

                                  ShimmerBox(width: 90, height: 10),
                                ],
                              ),
                            ),

                            const ShimmerBox(width: 70, height: 28, radius: 30),
                          ],
                        ),

                        const SizedBox(height: 18),

                        /// INFO ROW
                        const Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(width: 70, height: 10),

                                  SizedBox(height: 8),

                                  ShimmerBox(width: 80, height: 14),
                                ],
                              ),
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(width: 50, height: 10),

                                  SizedBox(height: 8),

                                  ShimmerBox(width: 80, height: 14),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBox(width: 40, height: 10),

                                SizedBox(height: 8),

                                ShimmerBox(width: 70, height: 14),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Divider(),

                        const SizedBox(height: 12),

                        /// BOTTOM
                        const Row(
                          children: [
                            Expanded(child: ShimmerBox(height: 12)),
                            SizedBox(width: 50),
                            ShimmerBox(width: 80, height: 12),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      period: const Duration(milliseconds: 1400),
      baseColor: isDark ? const Color(0xff2A3550) : const Color(0xffE5E5E5),
      highlightColor: isDark ? const Color(0xff4A5876) : Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

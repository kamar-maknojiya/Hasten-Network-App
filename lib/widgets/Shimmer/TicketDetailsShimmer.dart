import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class TicketDetailsShimmer extends StatelessWidget {
  const TicketDetailsShimmer({super.key});

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
            // /// APPBAR
            // const Align(
            //   alignment: Alignment.centerLeft,
            //   child: ShimmerBox(
            //     width: 150,
            //     height: 24,
            //   ),
            // ),
            //
            // const SizedBox(height: 20),

            /// TOP CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 80, height: 28, radius: 30),

                  const SizedBox(height: 12),

                  const ShimmerBox(width: 220, height: 16),

                  const SizedBox(height: 18),

                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(width: 90, height: 12)),

                      ShimmerBox(width: 50, height: 0),
                      ShimmerBox(width: 100, height: 12),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(width: 90, height: 12)),

                      ShimmerBox(width: 50, height: 0),
                      ShimmerBox(width: 100, height: 12),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const ShimmerBox(
                    width: double.infinity,
                    height: 42,
                    radius: 10,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// COMMENTS CARD
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 100, height: 18),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView(
                        children: [
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                          _rightBubble(isDark),
                          _leftBubble(isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// INPUT
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xff1F2535)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              children: const [
                                SizedBox(width: 15),

                                ShimmerBox(width: 24, height: 24, radius: 12),

                                SizedBox(width: 12),

                                Expanded(
                                  child: ShimmerBox(
                                    width: double.infinity,
                                    height: 12,
                                  ),
                                ),

                                SizedBox(width: 15),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        const ShimmerBox(width: 45, height: 45, radius: 30),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _leftBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        width: 220,
        decoration: BoxDecoration(
          // color: isDark ? const Color(0xff2A3550) : const Color(0xffE5E5E5),
          color: isDark
              ? const Color(0xff1F2535)
              : Colors.grey.shade100,
          // color: const Color(0xff1F2535),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 140, height: 12),

            SizedBox(height: 8),

            ShimmerBox(width: 80, height: 10),
          ],
        ),
      ),
    );
  }

  static Widget _rightBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        width: 220,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xff1F2535)
              : Colors.grey.shade100,
          // color: const Color(0xff0D4B48),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ShimmerBox(width: 140, height: 12),

            SizedBox(height: 8),

            ShimmerBox(width: 80, height: 10),
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

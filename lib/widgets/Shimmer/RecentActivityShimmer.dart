import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class RecentActivityShimmer extends StatelessWidget {
  const RecentActivityShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final card2 = isDark ? AppColors.darkCard2 : AppColors.lightCard2;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // const SizedBox(height: 10),
            //
            // /// APPBAR SHIMMER
            // Row(
            //   children: const [
            //     ShimmerBox(width: 38, height: 38, radius: 10),
            //
            //     SizedBox(width: 16),
            //
            //     ShimmerBox(width: 150, height: 20),
            //   ],
            // ),
            //
            // const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: 10,
                itemBuilder: (_, _) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// MESSAGE
                        const ShimmerBox(width: double.infinity, height: 12),

                        const SizedBox(height: 8),

                        const ShimmerBox(width: 180, height: 10),

                        const SizedBox(height: 10),

                        /// PARTICULARS BOX
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: card2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: double.infinity, height: 12),

                              SizedBox(height: 8),

                              ShimmerBox(width: 220, height: 12),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// CHIP + DATE
                        Row(
                          children: [
                            const ShimmerBox(
                              width: 100,
                              height: 25,
                              radius: 30,
                            ),

                            const Spacer(),

                            const ShimmerBox(width: 120, height: 12),
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

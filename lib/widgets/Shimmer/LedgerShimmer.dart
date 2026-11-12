import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class LedgerShimmer extends StatelessWidget {
  const LedgerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // const SizedBox(height: 15),

          /// APPBAR TITLE
          // const Align(
          //   alignment: Alignment.centerLeft,
          //   child: ShimmerBox(width: 120, height: 24),
          // ),
          //
          // const SizedBox(height: 20),

          /// TABS
          Row(
            children: const [
              ShimmerBox(width: 90, height: 32, radius: 100),

              SizedBox(width: 15),

              ShimmerBox(width: 170, height: 32, radius: 100),
            ],
          ),

          const SizedBox(height: 16),

          /// SEARCH BAR
          const ShimmerBox(width: double.infinity, height: 52, radius: 12),

          const SizedBox(height: 15),

          Expanded(
            child: ListView.builder(
              itemCount: 8,
              padding: EdgeInsets.zero,
              itemBuilder: (_, __) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                ShimmerBox(width: 120, height: 12),

                                SizedBox(height: 10),

                                ShimmerBox(width: 80, height: 10),
                              ],
                            ),
                          ),

                          const ShimmerBox(width: 70, height: 16),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: const [
                          Expanded(
                            child: ShimmerBox(
                              width: double.infinity,
                              height: 12,
                            ),
                          ),

                          SizedBox(width: 10),

                          ShimmerBox(width: 100, height: 26, radius: 50),
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

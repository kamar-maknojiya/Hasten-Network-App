import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class ServiceHistoryShimmer extends StatelessWidget {
  const ServiceHistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: 10,
                  padding: EdgeInsets.zero,
                  itemBuilder: (_, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// HEADER
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    ShimmerBox(width: 180, height: 15),
                                    SizedBox(height: 10),
                                    ShimmerBox(width: 120, height: 12),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const ShimmerBox(width: 100, height: 30, radius: 30,),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.withOpacity(.15)),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Expanded(child: HistoryInfoShimmer()),
                              SizedBox(width: 12),
                              Expanded(child: HistoryInfoShimmer()),
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
      ),
    );
  }
}

class HistoryInfoShimmer extends StatelessWidget {
  const HistoryInfoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard2 : AppColors.lightCard2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          ShimmerBox(width: 70, height: 10),

          SizedBox(height: 8),

          /// VALUE
          ShimmerBox(width: 95, height: 14),
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

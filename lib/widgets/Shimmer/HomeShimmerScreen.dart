import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class HomeShimmerScreen extends StatelessWidget {
  const HomeShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? const Color(0xff1A2438) : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(height: 14),
                        SizedBox(height: 12),
                        ShimmerBox(height: 18),
                      ],
                    ),
                  ),
                  SizedBox(width: 50),

                  Expanded(child: const ShimmerBox(height: 0, radius: 18)),
                  const ShimmerBox(width: 55, height: 55, radius: 12),
                ],
              ),
              const SizedBox(height: 16),

              /// PLAN CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: MediaQuery.of(context).size.width / 3,
                      height: 14,
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: MediaQuery.of(context).size.width / 2,
                      height: 14,
                    ),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: double.infinity, height: 12),
                    const SizedBox(height: 10),

                    Row(
                      children: const [
                        Expanded(child: SmallStatCardShimmer()),
                        SizedBox(width: 10),
                        Expanded(child: SmallStatCardShimmer()),
                        SizedBox(width: 10),
                        Expanded(child: SmallStatCardShimmer()),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// RECHARGE BUTTON
              Container(
                height: 58,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: ShimmerBox(
                    width: MediaQuery.of(context).size.width / 3,
                    height: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ShimmerBox(
                width: MediaQuery.of(context).size.width / 3,
                height: 14,
              ),

              const SizedBox(height: 16),

              /// QUICK ACTIONS
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          ShimmerBox(width: 48, height: 48, radius: 14),

                          SizedBox(height: 10),

                          ShimmerBox(width: 45, height: 10),

                          SizedBox(height: 8),

                          ShimmerBox(width: 60, height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// USAGE CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(
                          width: MediaQuery.of(context).size.width / 3,
                          height: 14,
                        ),

                        ShimmerBox(
                          width: MediaQuery.of(context).size.width / 4,
                          height: 14,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ShimmerBox(width: 90, height: 90, radius: 45),
                        SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            children: [
                              ShimmerBox(width: double.infinity, height: 12),
                              SizedBox(height: 12),
                              ShimmerBox(width: double.infinity, height: 12),
                              SizedBox(height: 12),
                              ShimmerBox(width: double.infinity, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              /// RECENT ACTIVITY
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(
                          width: MediaQuery.of(context).size.width / 3,
                          height: 14,
                        ),
                        ShimmerBox(
                          width: MediaQuery.of(context).size.width / 6,
                          height: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(3, (_) => const ActivityRowShimmer()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmallStatCardShimmer extends StatelessWidget {
  const SmallStatCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      // height: 50,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff2A3550) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(width: 50, height: 14),
          SizedBox(height: 10),
          ShimmerBox(width: 70, height: 10),
        ],
      ),
    );
  }
}

class ActivityRowShimmer extends StatelessWidget {
  const ActivityRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const ShimmerBox(width: 46, height: 46, radius: 12),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: MediaQuery.of(context).size.width / 2.4,
                  height: 12,
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: MediaQuery.of(context).size.width / 3.5,
                  height: 10,
                ),
              ],
            ),
          ),

          const ShimmerBox(width: 60, height: 12),
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

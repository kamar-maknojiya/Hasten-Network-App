import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class RechargeShimmerScreen extends StatelessWidget {
  const RechargeShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg  = isDark ? AppColors.darkBg : AppColors.lightBg;

    final card = isDark ? const Color(0xff18253E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
                ShimmerBox(width: MediaQuery.of(context).size.width / 3, height: 22),
              const SizedBox(height: 16),

              /// ONLINE / PIN
              Row(
                children:   [
                  ShimmerBox(width: MediaQuery.of(context).size.width / 3.5, height: 40, radius: 50),
                  SizedBox(width: 12),
                  ShimmerBox(width: MediaQuery.of(context).size.width / 3.5, height: 40, radius: 50),
                ],
              ),
              const SizedBox(height: 16),
              /// CURRENT PLAN CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const ShimmerBox(width: 50, height: 50, radius: 12),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:   [
                          ShimmerBox(width: MediaQuery.of(context).size.width / 1.8, height: 14),
                          SizedBox(height: 12),
                          ShimmerBox(width: MediaQuery.of(context).size.width / 2.5, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              /// PLAN TABS
              Row(
                children: const [
                  Expanded(child: ShimmerBox(height: 38, radius: 50)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(height: 38, radius: 50)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(height: 38, radius: 50)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(height: 38, radius: 50)),
                ],
              ),
              const SizedBox(height: 16),
              /// FILTER PACKAGE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(child: ShimmerBox(width: double.infinity, height: 14)),
                    const SizedBox(width: 12),
                    const ShimmerBox(width: 34, height: 34, radius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              /// PACKAGE CARD
              ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: PackageCardShimmer(card: card),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PackageCardShimmer extends StatelessWidget {
  final Color card;

  const PackageCardShimmer({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          /// TITLE + BADGES
          Row(
            children: [
              const Expanded(
                child: ShimmerBox(width: double.infinity, height: 18),
              ),
              const SizedBox(width: 10),
              const ShimmerBox(width: 70, height: 28, radius: 30),
              const SizedBox(width: 8),
              const ShimmerBox(width: 50, height: 28, radius: 30),
            ],
          ),
          const SizedBox(height: 16),
          /// INFO BOXES
          Row(
            children: [
              Expanded(child: _infoBox()),
              const SizedBox(width: 10),
              Expanded(child: _infoBox()),
              const SizedBox(width: 10),
              Expanded(child: _infoBox()),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.withOpacity(.15)),
          const SizedBox(height: 10),
          /// PRICE + BUTTON
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:   [
                    ShimmerBox(width: MediaQuery.of(context).size.width / 3.8, height: 18),
                    SizedBox(height: 10),
                    ShimmerBox(width: MediaQuery.of(context).size.width / 3, height: 20, radius: 30),
                  ],
                ),
              ),
              ShimmerBox(width: MediaQuery.of(context).size.width / 3.2, height: 48, radius: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 50, height: 10),
          SizedBox(height: 8),
          ShimmerBox(width: 60, height: 12),
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
      baseColor: isDark ? const Color(0xff2A3550) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xff4A5876) : Colors.grey.shade100,
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

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class WifiShimmerScreen extends StatelessWidget {
  const WifiShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? const Color(0xff1A2438) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// TITLE + REBOOT
              Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: ShimmerBox(height: 30, radius: 16),
                  ),
                  const Expanded(child: ShimmerBox(height: 0)),
                  const Expanded(
                    flex: 2,
                    child: ShimmerBox(height: 45, radius: 10),
                  ),
                  // const ShimmerBox(width: 120, height: 45, radius: 16),
                ],
              ),
              const SizedBox(height: 16),

              /// WIFI WAN + REFRESH
              Row(
                children: [
                  Expanded(child: const ShimmerBox(height: 35, radius: 30)),
                  const SizedBox(width: 15),
                  Expanded(child: const ShimmerBox(height: 35, radius: 30)),
                  const SizedBox(width: 25),
                  Expanded(child: const ShimmerBox(height: 40, radius: 10)),
                ],
              ),
              const SizedBox(height: 16),

              /// CARD 1
              ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: WifiCardShimmer(card: card),
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

class WifiCardShimmer extends StatelessWidget {
  final Color card;
  const WifiCardShimmer({super.key, required this.card});

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
          Row(
            children: [
              const ShimmerBox(width: 55, height: 55, radius: 12),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 16),
                    SizedBox(height: 10),
                    ShimmerBox(width: 100, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const ShimmerBox(width: 80, height: 30, radius: 30),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: ShimmerBox(height: 50, radius: 12)),
              SizedBox(width: 16),
              Expanded(child: ShimmerBox(height: 50, radius: 12)),
            ],
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

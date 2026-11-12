import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class ProfileShimmerScreen extends StatelessWidget {
  const ProfileShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // /// HEADER
              // Row(
              //   children: const [
              //     ShimmerBox(width: 40, height: 40, radius: 10),
              //
              //     Spacer(),
              //
              //     ShimmerBox(width: 50, height: 50, radius: 15),
              //
              //     Spacer(),
              //   ],
              // ),
              ShimmerBox(width: 60, height: 60, radius: 15),
              const SizedBox(height: 10),
              const ShimmerBox(width: 160, height: 18),
              const SizedBox(height: 10),
              const ShimmerBox(width: 110, height: 14),
              const SizedBox(height: 12),
              const ShimmerBox(width: 120, height: 25, radius: 50),
              const SizedBox(height: 18),

              /// ACCOUNT DETAILS
              _detailCard(card, "Account Detail", 5),
              const SizedBox(height: 16),

              /// CONNECTION INFO
              _detailCard(card, "Connection Info", 4),
              const SizedBox(height: 16),

              /// SETTINGS CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: ShimmerBox(width: 90, height: 14),
                    ),
                    const SizedBox(height: 18),

                    /// THEME ROW
                    Row(
                      children: const [
                        ShimmerBox(width: 52, height: 52, radius: 16),
                        SizedBox(width: 15),
                        Expanded(
                          child: ShimmerBox(width: double.infinity, height: 14),
                        ),
                        ShimmerBox(width: 64, height: 32, radius: 50),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(),
                    const SizedBox(height: 6),
                    ...List.generate(9, (index) => const SettingTileShimmer()),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCard(Color card, String title, int rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: ShimmerBox(width: 120, height: 14),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            rows,
            (index) => Column(
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: ShimmerBox(width: double.infinity, height: 12),
                    ),
                    SizedBox(width: 20),
                    ShimmerBox(width: 120, height: 12),
                  ],
                ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingTileShimmer extends StatelessWidget {
  const SettingTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: const [
          ShimmerBox(width: 48, height: 48, radius: 12),
          SizedBox(width: 15),
          Expanded(child: ShimmerBox(width: double.infinity, height: 14)),
          ShimmerBox(width: 20, height: 20, radius: 4),
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

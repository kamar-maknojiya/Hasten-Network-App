import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class InvoiceDetailShimmer extends StatelessWidget {
  const InvoiceDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    final card = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const SizedBox(height: 10),
              //
              // /// APPBAR
              // const ShimmerBox(
              //   width: 150,
              //   height: 24,
              // ),
              //
              // const SizedBox(height: 20),

              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 120, height: 14),

                        SizedBox(height: 12),

                        ShimmerBox(width: 150, height: 22),

                        SizedBox(height: 12),

                        ShimmerBox(width: 90, height: 32, radius: 50),
                      ],
                    ),
                  ),

                  const ShimmerBox(width: 45, height: 45, radius: 12),
                ],
              ),

              const SizedBox(height: 25),

              /// DATES
              Row(
                children: const [
                  Expanded(
                    child: Column(
                      children: [
                        ShimmerBox(width: 70, height: 10),
                        SizedBox(height: 8),
                        ShimmerBox(width: 90, height: 14),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        ShimmerBox(width: 70, height: 10),
                        SizedBox(height: 8),
                        ShimmerBox(width: 90, height: 14),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        ShimmerBox(width: 70, height: 10),
                        SizedBox(height: 8),
                        ShimmerBox(width: 90, height: 14),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Divider(),

              const SizedBox(height: 20),

              /// SUBSCRIBER TITLE
              const ShimmerBox(width: 130, height: 18),

              const SizedBox(height: 12),

              /// SUBSCRIBER CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: List.generate(
                    6,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: const [
                          Expanded(child: ShimmerBox(width: 80, height: 12)),
                          SizedBox(width: 50),
                          ShimmerBox(width: 120, height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// ITEM INFO
              const ShimmerBox(width: 90, height: 18),

              const SizedBox(height: 12),

              /// ITEM CARD 1
              _itemCard(card),

              const SizedBox(height: 12),

              /// ITEM CARD 2
              _itemCard(card),

              const SizedBox(height: 25),

              /// BILLING TITLE
              const ShimmerBox(width: 120, height: 18),

              const SizedBox(height: 12),

              /// BILLING CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: List.generate(
                    7,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: const [
                          Expanded(child: ShimmerBox(width: 80, height: 12)),
                          SizedBox(width: 50),
                          ShimmerBox(width: 120, height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemCard(Color card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 40, height: 40, radius: 10),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 180, height: 14),

                SizedBox(height: 8),

                ShimmerBox(width: double.infinity, height: 12),

                SizedBox(height: 14),

                Row(
                  children: [
                    ShimmerBox(width: 80, height: 28, radius: 50),

                    SizedBox(width: 12),

                    ShimmerBox(width: 50, height: 12),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 10),

          Column(
            children: [
              ShimmerBox(width: 70, height: 14),

              SizedBox(height: 8),

              ShimmerBox(width: 60, height: 12),
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

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class SupportTicketShimmer extends StatelessWidget {
  const SupportTicketShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    final card = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: bg,

      floatingActionButton: const ShimmerBox(width: 56, height: 56, radius: 14),

      body: SafeArea(
        child: Column(
          children: [
            // const SizedBox(height: 10),
            //
            // /// TITLE
            // const Align(
            //   alignment: Alignment.centerLeft,
            //   child: ShimmerBox(width: 160, height: 24),
            // ),
            //
            // const SizedBox(height: 18),

            /// TABS
            SizedBox(
              height: 35,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) {
                  return const ShimmerBox(width: 80, height: 35, radius: 30);
                },
              ),
            ),

            const SizedBox(height: 16),

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
                      // border: const Border(
                      //   left: BorderSide(
                      //     color: AppColors.secondary,
                      //     width: 3,
                      //   ),
                      // ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// SUBJECT
                        const ShimmerBox(width: 220, height: 16),

                        const SizedBox(height: 14),

                        /// STATUS GROUP PRIORITY
                        Row(
                          children: const [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(width: 50, height: 10),

                                  SizedBox(height: 8),

                                  ShimmerBox(width: 70, height: 26, radius: 50),
                                ],
                              ),
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(width: 45, height: 10),

                                  SizedBox(height: 8),

                                  ShimmerBox(width: 80, height: 26, radius: 50),
                                ],
                              ),
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(width: 55, height: 10),

                                  SizedBox(height: 8),

                                  ShimmerBox(width: 75, height: 26, radius: 50),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Divider(),

                        const SizedBox(height: 12),

                        /// DATES + EDIT
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  ShimmerBox(width: 180, height: 12),

                                  SizedBox(height: 10),

                                  ShimmerBox(width: 160, height: 12),
                                ],
                              ),
                            ),

                            const ShimmerBox(width: 20, height: 20, radius: 5),
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

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vision_broadband/theme/app_colors.dart';

class StatisticsShimmerScreen extends StatelessWidget {
  const StatisticsShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? const Color(0xff1A2438) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          // padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ShimmerBox(
              //   width: MediaQuery.of(context).size.width / 3,
              //   height: 24,
              // ),
              // const SizedBox(height: 16),

              /// CARD 1
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ShimmerBox(
                        width: MediaQuery.of(context).size.width / 3,
                        height: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const ShimmerBox(width: 80, height: 80, radius: 50),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: const [
                              ShimmerBox(width: double.infinity, height: 14),
                              SizedBox(height: 16),
                              ShimmerBox(width: double.infinity, height: 14),
                              SizedBox(height: 16),
                              ShimmerBox(width: double.infinity, height: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              /// CARD 2
              Container(
                // height: 150,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 18,
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: ShimmerBox(
                          width: MediaQuery.of(context).size.width / 2.5,
                          height: 18,
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: AlignmentGeometry.bottomEnd,
                        child: ShimmerBox(
                          width: MediaQuery.of(context).size.width / 2.5,
                          height: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TableCard(card: card),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _tableCard(Color card, Context context) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: card,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Column(
  //       children: [
  //           Align(
  //           alignment: Alignment.centerLeft,
  //           child: ShimmerBox(width: MediaQuery.of(context).size.width / 3, height: 18),
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 children: List.generate(
  //                   5,
  //                   (index) => const Padding(
  //                     padding: EdgeInsets.only(bottom: 18),
  //                     child: ShimmerBox(width: 120, height: 14),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //
  //             Expanded(
  //               child: Column(
  //                 children: List.generate(
  //                   5,
  //                   (index) => const Padding(
  //                     padding: EdgeInsets.only(bottom: 18),
  //                     child: Align(
  //                       alignment: Alignment.centerRight,
  //                       child: ShimmerBox(width: 120, height: 14),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class TableCard extends StatelessWidget {
  final Color card;

  const TableCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ShimmerBox(
              width: MediaQuery.of(context).size.width / 3,
              height: 18,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: ShimmerBox(
                        width: MediaQuery.of(context).size.width / 3,
                        height: 16,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ShimmerBox(
                          width: MediaQuery.of(context).size.width / 3,
                          height: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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

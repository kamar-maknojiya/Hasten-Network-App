import 'package:flutter/material.dart';
import 'NetworkService.dart';
import 'NoInternetScreen.dart';

class NetworkWrapper extends StatelessWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NetworkService(),
      builder: (context, _) {
        return Stack(
          children: [
            child,

            if (!NetworkService().isConnected)
              const Positioned.fill(child: NoInternetScreen()),
          ],
        );
      },
    );
  }
}

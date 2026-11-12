import 'package:flutter/material.dart';
import 'package:vision_broadband/widgets/Network/NetworkService.dart';
import 'package:vision_broadband/widgets/Network/NoInternetScreen.dart';

class NetworkAwareWidget extends StatelessWidget {
  final Widget child;

  const NetworkAwareWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NetworkService(),
      builder: (context, _) {
        return NetworkService().isConnected ? child : const NoInternetScreen();
      },
    );
  }
}

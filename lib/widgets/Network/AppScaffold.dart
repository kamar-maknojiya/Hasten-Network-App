import 'package:flutter/material.dart';
import 'package:vision_broadband/widgets/Network/NetworkWrapper.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NetworkWrapper(child: child);
  }
}

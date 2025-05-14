import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class HomeScreenWrapper extends StatelessWidget {
  final Widget child;

  const HomeScreenWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // take to home screen
        context.goNamed('home');
      },
      child: child,
    );
  }
}

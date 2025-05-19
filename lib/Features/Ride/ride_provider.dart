import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/ride_controller.dart';
import 'screens/ride_screen.dart';

class RideProvider extends StatelessWidget {
  const RideProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RideController(),
      child: const RideScreen(),
    );
  }
}

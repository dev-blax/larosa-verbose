import 'package:flutter/material.dart';

class TimeBubble extends StatelessWidget {
  final String duration;
  const TimeBubble({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        duration,
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
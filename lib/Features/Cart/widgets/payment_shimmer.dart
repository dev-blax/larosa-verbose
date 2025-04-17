import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PaymentShimmer extends StatelessWidget {
  const PaymentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
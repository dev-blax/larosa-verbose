import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerOrderCard extends StatefulWidget {
  const ShimmerOrderCard({super.key});

  @override
  State<ShimmerOrderCard> createState() => _ShimmerOrderCardState();
}

class _ShimmerOrderCardState extends State<ShimmerOrderCard> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID Placeholder
            Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 20,
                width: 200,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Total Amount Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 120,
                    color: Colors.white,
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 80,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delivery Amount Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 120,
                    color: Colors.white,
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 80,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Driver Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 100,
                    color: Colors.white,
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 100,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Button Placeholder
            Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

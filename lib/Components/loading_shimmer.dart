import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 10,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: 150,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.favorite_border,
                      color: Colors.grey[300], size: 25),
                  // const SizedBox(width: 10),
                  Icon(Icons.star_border, color: Colors.grey[300], size: 25),
                  // const SizedBox(width: 10),
                  Icon(Icons.chat_bubble_outline,
                      color: Colors.grey[300], size: 25),
                  Icon(Icons.share_outlined, color: Colors.grey[300], size: 25),
                ],
              ),
            ),
          ),
          // const SizedBox(height: 20),
          // Shimmer.fromColors(
          //   baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
          //   highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         Row(
          //           children: [
          //             Container(
          //               height: 15,
          //               width: 80,
          //               color: Colors.grey[300],
          //             ),
          //             const SizedBox(width: 10),
          //             Icon(Icons.star, color: Colors.grey[300], size: 20),
          //           ],
          //         ),
          //         Container(
          //           height: 40,
          //           width: 40,
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color: Colors.grey[300],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: 150,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
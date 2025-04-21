import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CommentsShimmer extends StatelessWidget {
  const CommentsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Image Placeholder
                  Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      height: 200, // Height for the image
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Comment List Placeholder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: List.generate(10, (index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture and Username Shimmer
                            Row(
                              children: [
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 100,
                                    height: 10,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Comment Text Shimmer
                            Shimmer.fromColors(
                              baseColor: isDarkMode
                                  ? Colors.grey[900]!
                                  : Colors.grey[400]!,
                              highlightColor: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: double.infinity,
                                height: 15,
                                margin: const EdgeInsets.only(left: 50),
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Shimmer.fromColors(
                              baseColor: isDarkMode
                                  ? Colors.grey[900]!
                                  : Colors.grey[400]!,
                              highlightColor: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: 10,
                                margin: const EdgeInsets.only(left: 50),
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Date and Reply Shimmer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 80,
                                    height: 10,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 50,
                                    height: 10,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Comment Input Shimmer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
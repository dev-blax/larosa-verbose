import 'package:flutter/material.dart';

Widget buildGradientButton({
  required VoidCallback onTap,
  required String label,
  double verticalPadding = 8.0,
  double horizontalPadding = 16.0,
  double borderRadius = 10.0,
  required Color startColor,
  required Color endColor,
  TextStyle? textStyle,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            startColor,
            endColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: textStyle ??
            const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    ),
  );
}

Widget buildWideGradientButton({
  required VoidCallback onTap,
  required String label,
  double verticalPadding = 12.0,
  double borderRadius = 10.0,
  required Color startColor,
  required Color endColor,
  TextStyle? textStyle, Center? child,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            startColor,
            endColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          label,
          style: textStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ),
    ),
  );
}

// import 'package:flutter/material.dart';

// class WavyBorderPainter extends CustomPainter {
//   final Color borderColor;

//   WavyBorderPainter({required this.borderColor});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = borderColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;

//     final path = Path();

//     const waveHeight = 8.0;
//     const waveWidth = 20.0;

//     // Top border
//     path.moveTo(0, 0);
//     for (double i = 0; i < size.width; i += waveWidth) {
//       path.relativeQuadraticBezierTo(
//         waveWidth / 4,
//         -waveHeight,
//         waveWidth / 2,
//         0,
//       );
//       path.relativeQuadraticBezierTo(
//         waveWidth / 4,
//         waveHeight,
//         waveWidth / 2,
//         0,
//       );
//     }

//     // Right border
//     path.moveTo(size.width, 0);
//     for (double i = 0; i < size.height; i += waveWidth) {
//       path.relativeQuadraticBezierTo(
//         waveHeight,
//         waveWidth / 4,
//         0,
//         waveWidth / 2,
//       );
//       path.relativeQuadraticBezierTo(
//         -waveHeight,
//         waveWidth / 4,
//         0,
//         waveWidth / 2,
//       );
//     }

//     // Bottom border
//     path.moveTo(size.width, size.height);
//     for (double i = size.width; i > 0; i -= waveWidth) {
//       path.relativeQuadraticBezierTo(
//         -waveWidth / 4,
//         waveHeight,
//         -waveWidth / 2,
//         0,
//       );
//       path.relativeQuadraticBezierTo(
//         -waveWidth / 4,
//         -waveHeight,
//         -waveWidth / 2,
//         0,
//       );
//     }

//     // Left border
//     path.moveTo(0, size.height);
//     for (double i = size.height; i > 0; i -= waveWidth) {
//       path.relativeQuadraticBezierTo(
//         -waveHeight,
//         -waveWidth / 4,
//         0,
//         -waveWidth / 2,
//       );
//       path.relativeQuadraticBezierTo(
//         waveHeight,
//         -waveWidth / 4,
//         0,
//         -waveWidth / 2,
//       );
//     }

//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

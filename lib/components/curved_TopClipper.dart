import 'package:flutter/material.dart';

class CurvedTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 60);

    // Reduced curve - control points moved down from 0 to 30
    path.quadraticBezierTo(
      size.width * 0.7, 25, // Changed from 0 to 30
      size.width * 0.5, 25, // Changed from 0 to 30
    );
    path.quadraticBezierTo(
      size.width * 0.25, 25, // Changed from 0 to 30
      0, 60,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

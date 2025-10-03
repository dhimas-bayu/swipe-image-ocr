import 'package:flutter/material.dart';

/// Custom painter for drawing swipe paths.
///
/// This painter draws the path traced by the user's finger during
/// the swiping gesture, providing visual feedback for the selection area.
class SwipePathPainter extends CustomPainter {
  /// List of points that make up the swipe path.
  final List<Offset> path;
  final double strokeWidth;
  final Color? color;

  /// Creates a [SwipePathPainter] with the specified path points.
  ///
  /// Parameters:
  /// - [path]: List of points representing the swipe path
  SwipePathPainter(this.path, {this.strokeWidth = 16.0, this.color});

  /// Paints the swipe path.
  ///
  /// Draws a smooth white line following the points in the path,
  /// providing visual feedback during the swiping gesture.
  @override
  void paint(Canvas canvas, Size size) {
    // Draw swipe path
    if (path.length > 1) {
      final paint = Paint()
        ..color = color ?? Colors.redAccent.withValues(alpha: .3)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke;

      final pathToDraw = Path();
      pathToDraw.moveTo(path.first.dx, path.first.dy);

      for (int i = 1; i < path.length; i++) {
        pathToDraw.lineTo(path[i].dx, path[i].dy);
      }

      canvas.drawPath(pathToDraw, paint);
    }
  }

  /// Determines if the painter should be repainted.
  ///
  /// Always returns true since the path is constantly changing
  /// during the swiping gesture.
  @override
  bool shouldRepaint(SwipePathPainter oldDelegate) => true;
}

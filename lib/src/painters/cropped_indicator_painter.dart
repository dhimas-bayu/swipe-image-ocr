import 'package:flutter/material.dart';

/// Custom painter for drawing cropped area indicators.
///
/// This painter draws a semi-transparent overlay with a clear hole
/// indicating the selected/cropped area. It also draws corner indicators
/// to highlight the selection boundaries.
class CroppedIndicatorPainter extends CustomPainter {
  /// The bounding rectangle of the cropped area.
  ///
  /// If null, no indicator will be drawn.
  final Rect? boundingRect;

  final Color? color;

  /// Creates a [CroppedIndicatorPainter] with the specified bounding rectangle.
  ///
  /// Parameters:
  /// - [boundingRect]: The rectangle defining the cropped area
  CroppedIndicatorPainter(this.boundingRect, {this.color});

  /// Paints the cropped area indicator.
  ///
  /// Draws a semi-transparent overlay with a clear hole for the selected
  /// area and corner indicators to highlight the boundaries.
  @override
  void paint(Canvas canvas, Size size) {
    // Draw bounding rectangle overlay
    if (boundingRect != null) {
      final Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black45;

      final overlayRect = Rect.fromLTWH(0, 0, size.width, size.height);

      final backgroundPath = Path()..addRect(overlayRect);

      const Radius radius = Radius.circular(4.0);
      final hole = RRect.fromRectAndRadius(boundingRect!, radius);
      final holePath = Path()..addRRect(hole);

      final finalPath = Path.combine(
        PathOperation.difference,
        backgroundPath,
        holePath,
      );

      canvas.drawPath(finalPath, paint);

      drawCornerIndicator(canvas);
    }
  }

  /// Draws corner indicators around the selected area.
  ///
  /// Creates rounded corner markers to clearly indicate the boundaries
  /// of the selected/cropped area.
  void drawCornerIndicator(Canvas canvas) {
    double cornerLength = 12.0;
    double strokeWidth = 3.0;

    final paint = Paint()
      ..color = color ?? Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final radius = strokeWidth * 2; // Radius untuk lengkungan corner

    // Top-left corner
    final topLeftPath = Path()
      ..moveTo(boundingRect!.left + cornerLength, boundingRect!.top)
      ..lineTo(boundingRect!.left + radius, boundingRect!.top)
      ..quadraticBezierTo(
        boundingRect!.left,
        boundingRect!.top,
        boundingRect!.left,
        boundingRect!.top + radius,
      )
      ..lineTo(boundingRect!.left, boundingRect!.top + cornerLength);
    canvas.drawPath(topLeftPath, paint);

    // Top-right corner
    final topRightPath = Path()
      ..moveTo(boundingRect!.right - cornerLength, boundingRect!.top)
      ..lineTo(boundingRect!.right - radius, boundingRect!.top)
      ..quadraticBezierTo(
        boundingRect!.right,
        boundingRect!.top,
        boundingRect!.right,
        boundingRect!.top + radius,
      )
      ..lineTo(boundingRect!.right, boundingRect!.top + cornerLength);
    canvas.drawPath(topRightPath, paint);

    // Bottom-left corner
    final bottomLeftPath = Path()
      ..moveTo(boundingRect!.left, boundingRect!.bottom - cornerLength)
      ..lineTo(boundingRect!.left, boundingRect!.bottom - radius)
      ..quadraticBezierTo(
        boundingRect!.left,
        boundingRect!.bottom,
        boundingRect!.left + radius,
        boundingRect!.bottom,
      )
      ..lineTo(boundingRect!.left + cornerLength, boundingRect!.bottom);
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom-right corner
    final bottomRightPath = Path()
      ..moveTo(boundingRect!.right, boundingRect!.bottom - cornerLength)
      ..lineTo(boundingRect!.right, boundingRect!.bottom - radius)
      ..quadraticBezierTo(
        boundingRect!.right,
        boundingRect!.bottom,
        boundingRect!.right - radius,
        boundingRect!.bottom,
      )
      ..lineTo(boundingRect!.right - cornerLength, boundingRect!.bottom);
    canvas.drawPath(bottomRightPath, paint);
    canvas.drawPath(bottomRightPath, paint);
  }

  /// Determines if the painter should be repainted.
  ///
  /// Returns true if the bounding rectangle has changed since the last paint.
  @override
  bool shouldRepaint(CroppedIndicatorPainter oldDelegate) =>
      oldDelegate.boundingRect != boundingRect;
}

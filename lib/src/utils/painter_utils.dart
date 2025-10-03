import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui';

/// Utility class for painter-related calculations.
///
/// This class provides methods for calculating geometric properties
/// from user input, such as bounding rectangles from swipe paths.
class PainterUtils {
  /// Calculates the bounding rectangle from a list of points.
  ///
  /// This method finds the smallest rectangle that encompasses all
  /// the points in the provided list. Useful for determining the
  /// selection area from a swipe gesture.
  ///
  /// Parameters:
  /// - [points]: List of points to calculate the bounding rectangle from
  /// - [useIsolate]: Whether to run the calculation in an isolate (default: true)
  ///
  /// Returns:
  /// - [Future<Rect>]: The bounding rectangle containing all points
  static Future<Rect> calculateBoundingRect(
    List<Offset> points, {
    bool useIsolate = true,
    double strokeWidth = 16.0,
  }) async {
    if (useIsolate) {
      return await Isolate.run(() {
        return _calculateBoundingRect(points, strokeWidth: strokeWidth);
      });
    }
    return await _calculateBoundingRect(points, strokeWidth: strokeWidth);
  }

  /// Private implementation of bounding rectangle calculation.
  ///
  /// Finds the minimum and maximum x and y coordinates from the
  /// provided points and creates a rectangle from them.
  ///
  /// Parameters:
  /// - [points]: List of points to calculate from
  ///
  /// Returns:
  /// - [Future<Rect>]: The bounding rectangle
  static Future<Rect> _calculateBoundingRect(
    List<Offset> points, {
    double strokeWidth = 16.0,
  }) async {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.dx;
    double maxX = points.first.dx + strokeWidth;
    double minY = points.first.dy;
    double maxY = points.first.dy + strokeWidth;

    for (Offset point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

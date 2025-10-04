import '/src/painters/cropped_indicator_painter.dart';
import '/src/painters/swipe_path_painter.dart';
import '/src/utils/image_utils.dart';
import '/src/utils/painter_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// A widget that provides interactive image cropping functionality with swipe gestures.
///
/// This widget displays an image from bytes and allows users to draw a selection area
/// by swiping their finger across the image. When the user completes the gesture,
/// it calculates a bounding rectangle from the swipe path and crops the selected area.
///
/// Features:
/// - Real-time drawing visualization while swiping with customizable stroke
/// - Automatic bounding rectangle calculation from swipe path points
/// - Visual indicators showing the final cropped area
/// - Automatic image cropping when selection is complete
/// - Performance optimized with RepaintBoundary for smooth drawing
/// - Gesture handling with pan start, update, and end events
///
/// Example usage:
/// ```dart
/// ImageSwipperWidget(
///   imageBytes: imageBytes, // Uint8List
///   strokeWidth: 20.0,
///   swipeColor: Colors.blue.withOpacity(0.7),
///   indicatorColor: Colors.red,
///   onSwipeImage: (img.Image? croppedImage) {
///     if (croppedImage != null) {
///       print('Image cropped successfully: ${croppedImage.width}x${croppedImage.height}');
///     }
///   },
/// )
/// ```
class ImageSwipperWidget extends StatefulWidget {
  /// Creates an [ImageSwipperWidget].
  ///
  /// The [imageBytes] parameter is required and specifies the image data to display.
  ///
  /// Optional parameters:
  /// - [strokeWidth]: Width of the swipe stroke for drawing (default: 16.0)
  /// - [swipeColor]: Color of the swipe path during drawing (uses theme if null)
  /// - [indicatorColor]: Color of the selection indicator (uses theme if null)
  /// - [onSwipeImage]: Callback called when image cropping is completed
  const ImageSwipperWidget({
    super.key,
    required this.imageBytes,
    this.strokeWidth = 16.0,
    this.swipeColor,
    this.indicatorColor,
    this.onSwipeImage,
  });

  /// The image data (bytes) that supplies the image to be displayed and cropped.
  final Uint8List imageBytes;

  /// Width of the stroke used for drawing the swipe path.
  ///
  /// Defaults to 16.0 pixels.
  final double strokeWidth;

  /// Color of the swipe path drawn while the user is drawing.
  ///
  /// If null, uses the theme's primary color with opacity.
  final Color? swipeColor;

  /// Color of the selection indicator shown after drawing is complete.
  ///
  /// If null, uses the theme's accent color.
  final Color? indicatorColor;

  /// Callback function called when image cropping is completed.
  ///
  /// The callback receives an [img.Image] object containing the cropped image,
  /// or null if cropping failed or the image is too small (< 32x32 pixels).
  final ValueChanged<img.Image?>? onSwipeImage;

  @override
  State<ImageSwipperWidget> createState() => _ImageSwipperWidgetState();
}

/// Private state class for [ImageSwipperWidget].
///
/// Manages the drawing state, swipe path tracking, bounding rectangle calculation,
/// and image processing. Uses ValueNotifiers for reactive UI updates during
/// the drawing process and processing states.
class _ImageSwipperWidgetState extends State<ImageSwipperWidget> {
  /// Whether the user is currently drawing/swiping on the image.
  final ValueNotifier<bool> _drawingNotifier = ValueNotifier(false);

  /// List of points that make up the current swipe path.
  final ValueNotifier<List<Offset>> _swipePathNotifier = ValueNotifier([]);

  /// The calculated bounding rectangle from the swipe path.
  final ValueNotifier<Rect?> _boundingRectNotifier = ValueNotifier(null);

  /// Cached image bytes for cropping operations.
  late Uint8List _imageBytes;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
  }

  @override
  void didUpdateWidget(covariant ImageSwipperWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _swipePathNotifier.value = List.empty();
      _boundingRectNotifier.value = null;
      _drawingNotifier.value = false;
      _imageBytes = widget.imageBytes;
    }
  }

  @override
  void dispose() {
    _drawingNotifier.dispose();
    _boundingRectNotifier.dispose();
    _swipePathNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            if (!_isProcessing) {
              _drawingNotifier.value = true;
              _swipePathNotifier.value = [details.localPosition];
              _boundingRectNotifier.value = null;
            }
          },
          onPanUpdate: (details) async {
            if (_drawingNotifier.value && !_isProcessing) {
              _swipePathNotifier.value = [
                ..._swipePathNotifier.value,
                details.localPosition,
              ];
            }
          },
          onPanEnd: (details) async {
            _drawingNotifier.value = false;
            if (_swipePathNotifier.value.isNotEmpty && !_isProcessing) {
              _isProcessing = true;
              _boundingRectNotifier.value =
                  await PainterUtils.calculateBoundingRect(
                    _swipePathNotifier.value,
                    strokeWidth: widget.strokeWidth,
                  );

              await _croppingImage(constraints.biggest);
              _isProcessing = false;
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                _imageBytes,
                fit: BoxFit.fill,
              ),
              ValueListenableBuilder(
                valueListenable: _drawingNotifier,
                builder: (context, isDrawing, child) {
                  return RepaintBoundary(
                    child: isDrawing
                        ? ValueListenableBuilder(
                            valueListenable: _swipePathNotifier,
                            builder: (context, swipePath, child) {
                              return CustomPaint(
                                painter: SwipePathPainter(
                                  swipePath,
                                  strokeWidth: widget.strokeWidth,
                                  color: widget.swipeColor,
                                ),
                              );
                            },
                          )
                        : ValueListenableBuilder(
                            valueListenable: _boundingRectNotifier,
                            builder: (context, boundingRect, child) {
                              return CustomPaint(
                                painter: CroppedIndicatorPainter(
                                  boundingRect,
                                  color: widget.indicatorColor,
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Crops the image based on the current bounding rectangle.
  ///
  /// This method is called when the user completes drawing a selection area.
  /// It converts the screen coordinates to image coordinates and performs
  /// the actual image cropping operation using isolate for performance.
  ///
  /// The cropping process:
  /// 1. Validates that a bounding rectangle exists
  /// 2. Ensures image bytes are available
  /// 3. Calls [ImageUtils.cropImageFromScreen] with isolate processing
  /// 4. Calls the [onSwipeImage] callback with the result
  ///
  /// Parameters:
  /// - [displaySize]: The size of the display area where the image is shown
  Future<void> _croppingImage(Size displaySize) async {
    if (_boundingRectNotifier.value != null && _imageBytes.isNotEmpty) {
      final image = await ImageUtils.cropImageFromScreen(
        pictureBytes: _imageBytes,
        screenRect: _boundingRectNotifier.value!,
        displaySize: displaySize,
        fit: BoxFit.fill,
        useIsolate: true,
      );
      widget.onSwipeImage?.call(image);
    }
  }
}

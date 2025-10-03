import 'dart:typed_data';

import '/src/extensions/image_provider_ext.dart';
import '/src/painters/cropped_indicator_painter.dart';
import '/src/painters/swipe_path_painter.dart';
import '/src/utils/image_utils.dart';
import '/src/utils/painter_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// A widget that provides interactive image cropping functionality.
///
/// This widget displays an image and allows users to draw a selection area
/// by swiping their finger across the image. When the user completes the
/// gesture, it calculates a bounding rectangle and crops the selected area.
///
/// Features:
/// - Real-time drawing visualization while swiping
/// - Bounding rectangle calculation from swipe path
/// - Visual indicators for the cropped area
/// - Automatic image cropping when selection is complete
///
/// Example usage:
/// ```dart
/// ImageSwipperWidget(
///   imageProvider: AssetImage('assets/sample.jpg'),
///   onCroppedImage: (img.Image? croppedImage) {
///     if (croppedImage != null) {
///       print('Image cropped successfully');
///     }
///   },
/// )
/// ```
class ImageSwipperWidget extends StatefulWidget {
  /// Creates an [ImageSwipperWidget].
  ///
  /// The [imageProvider] parameter is required and specifies the image to display.
  ///
  /// Optional parameters:
  /// - [onSwipeImage]: Callback called when image cropping is completed
  const ImageSwipperWidget({
    super.key,
    required this.imageBytes,
    this.strokeWidth = 16.0,
    this.swipeColor,
    this.indicatorColor,
    this.onSwipeImage,
  });

  /// The image provider that supplies the image to be displayed and cropped.
  final Uint8List imageBytes;

  final double strokeWidth;

  final Color? swipeColor;

  final Color? indicatorColor;

  /// Callback function called when image cropping is completed.
  ///
  /// The callback receives an [img.Image] object containing the cropped image,
  /// or null if cropping failed.
  final ValueChanged<img.Image?>? onSwipeImage;

  @override
  State<ImageSwipperWidget> createState() => _ImageSwipperWidgetState();
}

/// Private state class for [ImageSwipperWidget].
///
/// Manages the drawing state, swipe path tracking, and image processing.
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
  /// the actual image cropping operation.
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

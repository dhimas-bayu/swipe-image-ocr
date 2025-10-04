import 'dart:io';
import 'dart:typed_data';

import 'src/ui/image_swipper_widget.dart';
import '/src/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// A Flutter widget that provides interactive image cropping and text recognition functionality.
///
/// This widget allows users to draw a selection area on an image by swiping their finger,
/// then automatically crops the selected area and performs text recognition using Google ML Kit.
/// Heavy operations (image encoding to file) are performed on an isolate to keep the UI responsive.
///
/// The widget displays the provided image from bytes and allows users to:
/// - Draw a selection area by swiping across the image with customizable stroke
/// - Automatically crop the selected area based on swipe path
/// - Extract text from the cropped area using OCR with Google ML Kit
/// - Handle errors during text recognition with comprehensive error callbacks
/// - Customize visual appearance with colors and border radius
///
/// Key features:
/// - Interactive swipe-based image selection
/// - Real-time visual feedback during drawing
/// - Automatic bounding rectangle calculation
/// - OCR text recognition with Google ML Kit
/// - Performance optimized with isolate processing
/// - Comprehensive error handling
/// - Customizable UI appearance
///
/// Example usage:
/// ```dart
/// SwipeImageOCR(
///   imageBytes: imageBytes, // Uint8List from File.readAsBytesSync()
///   borderRadius: BorderRadius.circular(12),
///   strokeWidth: 20.0,
///   swipeColor: Colors.blue.withOpacity(0.7),
///   indicatorColor: Colors.red,
///   onSwipeImage: (File? file) {
///     print('Cropped image saved to: ${file?.path}');
///   },
///   onTextRead: (String? text) {
///     print('Recognized text: $text');
///   },
///   onErrorRead: (Object error, StackTrace? stackTrace) {
///     print('Error occurred: $error');
///   },
/// )
/// ```
class SwipeImageOCR extends StatefulWidget {
  /// Creates a [SwipeImageOCR] widget.
  ///
  /// The [imageBytes] parameter is required and specifies the image data to display and crop.
  ///
  /// Optional parameters:
  /// - [borderRadius]: The border radius for the widget container (default: no radius)
  /// - [strokeWidth]: Width of the swipe stroke for drawing (default: 16.0)
  /// - [swipeColor]: Color of the swipe path during drawing (uses theme if null)
  /// - [indicatorColor]: Color of the selection indicator (uses theme if null)
  /// - [onSwipeImage]: Callback called when an image is successfully cropped
  /// - [onTextRead]: Callback called when text is successfully recognized from the cropped image
  /// - [onErrorRead]: Callback called when an error occurs during text recognition
  const SwipeImageOCR({
    super.key,
    required this.imageBytes,
    this.borderRadius,
    this.onSwipeImage,
    this.onTextRead,
    this.onErrorRead,
    this.strokeWidth = 16.0,
    this.swipeColor,
    this.indicatorColor,
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

  /// Optional border radius for the widget container.
  ///
  /// If null, no border radius is applied.
  final BorderRadiusGeometry? borderRadius;

  /// Callback function called when an image is successfully cropped.
  ///
  /// The callback receives a [File] object containing the cropped image,
  /// or null if cropping failed or the image is too small (< 32x32 pixels).
  final Function(File?)? onSwipeImage;

  /// Callback function called when text is successfully recognized from the cropped image.
  ///
  /// The callback receives a [String] containing the recognized text,
  /// or null if text recognition failed or no text was found.
  final Function(String?)? onTextRead;

  /// Callback function called when an error occurs during text recognition.
  ///
  /// The callback receives:
  /// - [Object]: The error that occurred (usually an Exception)
  /// - [StackTrace?]: Optional stack trace for debugging purposes
  final Function(Object, StackTrace)? onErrorRead;

  @override
  State<SwipeImageOCR> createState() => _SwipeImageOCRState();
}

/// Private state class for [SwipeImageOCR].
///
/// Manages the Google ML Kit text recognizer, image bytes caching, and handles
/// image processing callbacks. Also manages widget updates and lifecycle events.
class _SwipeImageOCRState extends State<SwipeImageOCR> {
  /// Google ML Kit text recognizer for OCR functionality.
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Cached image bytes for performance optimization.
  late Uint8List _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
  }

  @override
  void didUpdateWidget(covariant SwipeImageOCR oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _imageBytes = widget.imageBytes;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSwipeImage?.call(null);
        widget.onTextRead?.call(null);
      });
    }
  }

  /// Builds the widget tree for the [SwipeImageOCR].
  ///
  /// Creates a container with optional border radius and border styling,
  /// containing an [ImageSwipperWidget] for interactive image cropping.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: colorScheme.outline,
          ),
        ),
        child: ImageSwipperWidget(
          imageBytes: _imageBytes,
          onSwipeImage: _onReadingImage,
          strokeWidth: widget.strokeWidth,
          swipeColor: widget.swipeColor,
          indicatorColor: widget.indicatorColor,
        ),
      ),
    );
  }

  /// Handles the cropped image processing and text recognition.
  ///
  /// This method is called when the user completes drawing a selection area.
  /// It performs the following steps:
  /// 1. Validates the image size (minimum 32x32 pixels)
  /// 2. Converts the image to a temporary file using [ImageUtils.imageToFile]
  /// 3. Calls the [onSwipeImage] callback with the file
  /// 4. Waits for a brief delay to ensure file is written
  /// 5. Performs text recognition using Google ML Kit TextRecognizer
  /// 6. Calls the [onTextRead] callback with the recognized text
  /// 7. Cleans up the temporary file
  /// 8. Handles any errors by calling [onErrorRead]
  ///
  /// Parameters:
  /// - [image]: The cropped image from the user's selection, or null if cropping failed
  Future<void> _onReadingImage(img.Image? image) async {
    if (image == null) return;

    try {
      if (image.width < 32 && image.height < 32) {
        throw Exception("Circle area to read less than 32 px.");
      }

      final file = await ImageUtils.imageToFile(image);
      widget.onSwipeImage?.call(file);
      await Future.delayed(Durations.long4);
      if (file != null && mounted) {
        final inputImage = InputImage.fromFile(file);
        final recognizedText = await _textRecognizer.processImage(
          inputImage,
        );

        widget.onTextRead?.call(recognizedText.text);
        await file.delete(recursive: true);
      }
    } catch (e, s) {
      widget.onErrorRead?.call(e, s);
    }
  }
}

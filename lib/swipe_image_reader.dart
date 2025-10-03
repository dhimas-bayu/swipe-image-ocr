import 'dart:io';
import 'dart:typed_data';

import 'package:swipe_image_reader/src/extensions/image_provider_ext.dart';

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
/// The widget displays the provided image and allows users to:
/// - Draw a selection area by swiping across the image
/// - Automatically crop the selected area
/// - Extract text from the cropped area using OCR
/// - Handle errors during text recognition
///
/// Example usage:
/// ```dart
/// SwipeImageReader(
///   image: AssetImage('assets/sample_image.jpg'),
///   borderRadius: BorderRadius.circular(12),
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
class SwipeImageReader extends StatefulWidget {
  /// Creates a [SwipeImageReader] widget.
  ///
  /// The [image] parameter is required and specifies the image to display and crop.
  ///
  /// Optional parameters:
  /// - [borderRadius]: The border radius for the widget container
  /// - [onSwipeImage]: Callback called when an image is successfully swipped
  /// - [onTextRead]: Callback called when text is successfully recognized from the cropped image
  /// - [onErrorRead]: Callback called when an error occurs during text recognition
  const SwipeImageReader({
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

  /// The image provider that supplies the image to be displayed and cropped.
  final Uint8List imageBytes;

  final double strokeWidth;

  final Color? swipeColor;

  final Color? indicatorColor;

  /// Optional border radius for the widget container.
  ///
  /// If null, no border radius is applied.
  final BorderRadiusGeometry? borderRadius;

  /// Callback function called when an image is successfully cropped.
  ///
  /// The callback receives a [File] object containing the swipped image,
  /// or null if cropping failed.
  final Function(File?)? onSwipeImage;

  /// Callback function called when text is successfully recognized from the cropped image.
  ///
  /// The callback receives a [String] containing the recognized text,
  /// or null if text recognition failed.
  final Function(String?)? onTextRead;

  /// Callback function called when an error occurs during text recognition.
  ///
  /// The callback receives:
  /// - [Object]: The error that occurred
  /// - [StackTrace?]: Optional stack trace for debugging
  final Function(Object, StackTrace)? onErrorRead;

  @override
  State<SwipeImageReader> createState() => _SwipeImageReaderState();
}

/// Private state class for [SwipeImageReader].
///
/// Manages the text recognizer, image provider, and handles image processing callbacks.
class _SwipeImageReaderState extends State<SwipeImageReader> {
  /// Google ML Kit text recognizer for OCR functionality.
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Cached image provider for performance optimization.
  late Uint8List _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
  }

  @override
  void didUpdateWidget(covariant SwipeImageReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _imageBytes = widget.imageBytes;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSwipeImage?.call(null);
        widget.onTextRead?.call(null);
      });
    }
  }

  /// Builds the widget tree for the [SwipeImageReader].
  ///
  /// Creates a container with optional border radius and border styling,
  /// containing an [ImageCropperWidget] for interactive image cropping.
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
  /// 2. Converts the image to a temporary file
  /// 3. Calls the [onCroppedImage] callback with the file
  /// 4. Performs text recognition using Google ML Kit
  /// 5. Calls the [onTextRead] callback with the recognized text
  /// 6. Cleans up the temporary file
  /// 7. Handles any errors by calling [onErrorRead]
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

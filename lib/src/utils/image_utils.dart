import 'dart:developer' as development;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Utility class for image processing operations.
///
/// This class provides various methods for image manipulation including:
/// - Converting between different image formats
/// - Cropping images based on screen coordinates
/// - Converting images to files
/// - Handling coordinate transformations between screen and image space
///
/// All methods support optional isolate execution for better performance
/// on heavy image processing operations.
class ImageUtils {
  /// Converts raw image bytes to an [img.Image] object.
  ///
  /// This private method decodes the provided [Uint8List] bytes into
  /// an [img.Image] that can be processed by the image package.
  ///
  /// Parameters:
  /// - [pictureBytes]: Raw image data as bytes
  ///
  /// Returns:
  /// - [img.Image?]: The decoded image, or null if decoding failed
  static Future<img.Image?> _convertToImage(Uint8List pictureBytes) async {
    try {
      final image = img.decodeImage(pictureBytes);
      return image;
    } catch (e) {
      development.log('Error converting to image: $e');
      return null;
    }
  }

  /// Converts an image file to an [img.Image] object.
  ///
  /// This method reads an image file from the specified path and converts
  /// it to an [img.Image] object for further processing.
  ///
  /// Parameters:
  /// - [imagePath]: The file path to the image
  ///
  /// Returns:
  /// - [img.Image?]: The decoded image, or null if reading/decoding failed
  static Future<img.Image?> convertFromPath(
    String imagePath, {
    bool useIsolate = false,
  }) async {
    if (useIsolate) {
      return await Isolate.run(() async {
        return await _convertFromPath(imagePath);
      });
    }

    return await _convertFromPath(imagePath);
  }

  /// Crops an image based on screen coordinates.
  ///
  /// This is the main function for cropping images based on a rectangle
  /// drawn on the screen. It handles coordinate transformation from
  /// screen space to image space and performs the actual cropping.
  ///
  /// Parameters:
  /// - [pictureBytes]: Raw image data as bytes
  /// - [screenRect]: The rectangle coordinates in screen space
  /// - [displaySize]: The size of the display area where the image is shown
  /// - [fit]: How the image fits within the display area (default: [BoxFit.contain])
  /// - [useIsolate]: Whether to run the operation in an isolate (default: false)
  ///
  /// Returns:
  /// - [img.Image?]: The cropped image, or null if cropping failed
  static Future<img.Image?> cropImageFromScreen({
    required Uint8List pictureBytes,
    required Rect screenRect,
    required Size displaySize,
    BoxFit fit = BoxFit.contain,
    bool useIsolate = false,
  }) async {
    if (useIsolate) {
      return await Isolate.run(() async {
        return await _cropImageFromScreen(
          pictureBytes: pictureBytes,
          screenRect: screenRect,
          displaySize: displaySize,
          fit: fit,
        );
      });
    }

    return _cropImageFromScreen(
      pictureBytes: pictureBytes,
      screenRect: screenRect,
      displaySize: displaySize,
      fit: fit,
    );
  }

  /// Converts an [img.Image] object to a [File].
  ///
  /// This method encodes the provided image and saves it as a temporary file
  /// in the application's documents directory.
  ///
  /// Parameters:
  /// - [image]: The image object to convert
  /// - [format]: The output format ('jpg', 'jpeg', or 'png') (default: 'jpg')
  /// - [useIsolate]: Whether to run the operation in an isolate (default: false)
  ///
  /// Returns:
  /// - [File?]: The created file, or null if conversion failed
  static Future<File?> imageToFile(
    img.Image image, {
    String format = 'jpg',
    bool useIsolate = false,
  }) async {
    if (useIsolate) {
      return await Isolate.run(() async {
        return await _imageToFile(image, format: format);
      });
    }

    return await _imageToFile(image, format: format);
  }

  /// Converts screen coordinates to image coordinates.
  ///
  /// This private method transforms a rectangle from screen space to
  /// the original image coordinate space, taking into account the
  /// BoxFit transformation applied to display the image.
  ///
  /// Parameters:
  /// - [screenRect]: Rectangle in screen coordinates
  /// - [imageSize]: Original size of the image
  /// - [displaySize]: Size of the display area
  /// - [fit]: BoxFit used to display the image
  ///
  /// Returns:
  /// - [Rect]: Rectangle in image coordinates
  static Rect _convertScreenRectToImageRect({
    required Rect screenRect,
    required Size imageSize,
    required Size displaySize,
    BoxFit fit = BoxFit.contain,
  }) {
    // Hitung transformasi berdasarkan BoxFit menggunakan applyBoxFit
    final FittedSizes sizes = _applyBoxFit(fit, imageSize, displaySize);

    // Hitung offset (posisi gambar dalam container)
    const Alignment alignment = Alignment.center;
    final Offset offset =
        alignment.alongSize(displaySize) -
        alignment.alongSize(sizes.destination);

    // Hitung scale factor
    final double scaleX = imageSize.width / sizes.destination.width;
    final double scaleY = imageSize.height / sizes.destination.height;

    // Adjust koordinat dengan offset
    final double adjustedLeft = screenRect.left - offset.dx;
    final double adjustedTop = screenRect.top - offset.dy;
    final double adjustedRight = screenRect.right - offset.dx;
    final double adjustedBottom = screenRect.bottom - offset.dy;

    // Konversi ke koordinat image original
    final imageRect = Rect.fromLTRB(
      adjustedLeft * scaleX,
      adjustedTop * scaleY,
      adjustedRight * scaleX,
      adjustedBottom * scaleY,
    );

    // Pastikan berada dalam bounds image
    final clampedLeft = imageRect.left.clamp(0.0, imageSize.width);
    final clampedTop = imageRect.top.clamp(0.0, imageSize.height);
    final clampedRight = imageRect.right.clamp(0.0, imageSize.width);
    final clampedBottom = imageRect.bottom.clamp(0.0, imageSize.height);

    return Rect.fromLTRB(clampedLeft, clampedTop, clampedRight, clampedBottom);
  }

  /// Applies BoxFit transformation to calculate fitted sizes.
  ///
  /// This private helper method mimics Flutter's internal BoxFit logic
  /// to calculate how an image should be fitted within a display area.
  ///
  /// Parameters:
  /// - [fit]: The BoxFit mode to apply
  /// - [inputSize]: Original size of the image
  /// - [outputSize]: Target display size
  ///
  /// Returns:
  /// - [FittedSizes]: Object containing source and destination sizes
  static FittedSizes _applyBoxFit(BoxFit fit, Size inputSize, Size outputSize) {
    Size sourceSize, destinationSize;

    switch (fit) {
      case BoxFit.fill:
        sourceSize = inputSize;
        destinationSize = outputSize;
        break;
      case BoxFit.contain:
        sourceSize = inputSize;
        if (outputSize.width / outputSize.height >
            inputSize.width / inputSize.height) {
          destinationSize = Size(
            inputSize.width * outputSize.height / inputSize.height,
            outputSize.height,
          );
        } else {
          destinationSize = Size(
            outputSize.width,
            inputSize.height * outputSize.width / inputSize.width,
          );
        }
        break;
      case BoxFit.cover:
        if (outputSize.width / outputSize.height >
            inputSize.width / inputSize.height) {
          sourceSize = Size(
            inputSize.width,
            inputSize.width * outputSize.height / outputSize.width,
          );
        } else {
          sourceSize = Size(
            inputSize.height * outputSize.width / outputSize.height,
            inputSize.height,
          );
        }
        destinationSize = outputSize;
        break;
      case BoxFit.fitWidth:
        sourceSize = inputSize;
        destinationSize = Size(
          outputSize.width,
          inputSize.height * outputSize.width / inputSize.width,
        );
        break;
      case BoxFit.fitHeight:
        sourceSize = inputSize;
        destinationSize = Size(
          inputSize.width * outputSize.height / inputSize.height,
          outputSize.height,
        );
        break;
      case BoxFit.none:
        sourceSize = inputSize;
        destinationSize = outputSize;
        break;
      case BoxFit.scaleDown:
        sourceSize = inputSize;
        destinationSize = outputSize;
        final double aspectRatio = inputSize.width / inputSize.height;
        if (destinationSize.height * aspectRatio > destinationSize.width) {
          destinationSize = Size(
            destinationSize.width,
            destinationSize.width / aspectRatio,
          );
        } else {
          destinationSize = Size(
            destinationSize.height * aspectRatio,
            destinationSize.height,
          );
        }
        if (sourceSize.width < destinationSize.width) {
          destinationSize = sourceSize;
        }
        break;
    }

    return FittedSizes(sourceSize, destinationSize);
  }

  /// Crops an image based on image coordinates.
  ///
  /// This private method performs the actual image cropping operation
  /// using the provided rectangle in image coordinate space.
  ///
  /// Parameters:
  /// - [originalImage]: The source image to crop
  /// - [cropRect]: Rectangle defining the crop area in image coordinates
  ///
  /// Returns:
  /// - [img.Image?]: The cropped image, or null if cropping failed
  static img.Image? _cropImage(img.Image originalImage, Rect cropRect) {
    try {
      // Validasi parameter crop
      if (cropRect.width <= 0 || cropRect.height <= 0) {
        development.log('Invalid crop rect dimensions');
        return null;
      }

      final left = cropRect.left.clamp(0, originalImage.width).toInt();
      final top = cropRect.top.clamp(0, originalImage.height).toInt();
      final width = cropRect.width.toInt();
      final height = cropRect.height.toInt();

      // Pastikan crop tidak melebihi bounds
      final maxWidth = originalImage.width - left;
      final maxHeight = originalImage.height - top;
      final finalWidth = width.clamp(1, maxWidth);
      final finalHeight = height.clamp(1, maxHeight);

      // Crop image menggunakan copyCrop
      final croppedImage = img.copyCrop(
        originalImage,
        x: left,
        y: top,
        width: finalWidth,
        height: finalHeight,
      );

      return croppedImage;
    } catch (e) {
      development.log('Error cropping image: $e');
      return null;
    }
  }

  /// Private implementation of screen-based image cropping.
  ///
  /// This method performs the complete cropping workflow:
  /// 1. Converts bytes to image
  /// 2. Transforms screen coordinates to image coordinates
  /// 3. Performs the actual cropping
  ///
  /// Parameters:
  /// - [pictureBytes]: Raw image data as bytes
  /// - [screenRect]: Rectangle in screen coordinates
  /// - [displaySize]: Size of the display area
  /// - [fit]: BoxFit used to display the image
  ///
  /// Returns:
  /// - [img.Image?]: The cropped image, or null if cropping failed
  static Future<img.Image?> _cropImageFromScreen({
    required Uint8List pictureBytes,
    required Rect screenRect,
    required Size displaySize,
    BoxFit fit = BoxFit.contain,
  }) async {
    try {
      // 1. Konversi ke image
      final originalImage = await _convertToImage(pictureBytes);
      if (originalImage == null) return null;

      final imageSize = Size(
        originalImage.width.toDouble(),
        originalImage.height.toDouble(),
      );

      // 2. Konversi screen rect ke image rect
      final imageRect = _convertScreenRectToImageRect(
        screenRect: screenRect,
        imageSize: imageSize,
        displaySize: displaySize,
        fit: fit,
      );

      development.log('Screen Rect: $screenRect');
      development.log('Image Rect: $imageRect');
      development.log('Image Size: ${imageSize.width}x${imageSize.height}');

      // 3. Crop image
      final croppedImage = _cropImage(originalImage, imageRect);
      return croppedImage;
    } catch (e) {
      development.log('Error in cropImageFromScreen: $e');
      return null;
    }
  }

  /// Private implementation to read an image file and decode it.
  ///
  /// Parameters:
  /// - [imagePath]: The file path to the image
  ///
  /// Returns:
  /// - [img.Image?]: The decoded image, or null if reading/decoding failed
  static Future<img.Image?> _convertFromPath(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      return image;
    } catch (e) {
      development.log('Error converting from path: $e');
      return null;
    }
  }

  /// Private implementation of image to file conversion.
  ///
  /// This method encodes the image in the specified format and saves
  /// it as a temporary file with a timestamp-based filename.
  ///
  /// Parameters:
  /// - [image]: The image object to convert
  /// - [format]: The output format (jpg, jpeg, or png)
  ///
  /// Returns:
  /// - [File?]: The created file, or null if conversion failed
  static Future<File?> _imageToFile(
    img.Image image, {
    required String format,
  }) async {
    try {
      Uint8List? bytes;

      switch (format.toLowerCase()) {
        case 'png':
          bytes = Uint8List.fromList(img.encodePng(image));
          break;
        case 'jpg':
        case 'jpeg':
          bytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
          break;
        default:
          bytes = Uint8List.fromList(img.encodePng(image));
      }

      final timestamp = DateTime.timestamp().millisecondsSinceEpoch;
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String fileName = 'cropped_image_$timestamp.$format';
      String filePath = '${appDocDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      development.log('Error converting image to bytes: $e');
      return null;
    }
  }
}

/// Helper class for storing the result of BoxFit calculations.
///
/// This class holds both the source size (from the original image)
/// and the destination size (how the image should be displayed)
/// after applying BoxFit transformations.
class FittedSizes {
  /// Creates a [FittedSizes] object with the given source and destination sizes.
  ///
  /// Parameters:
  /// - [source]: The source size (from the original image)
  /// - [destination]: The destination size (how the image should be displayed)
  const FittedSizes(this.source, this.destination);

  /// The source size from the original image.
  final Size source;

  /// The destination size for display after BoxFit transformation.
  final Size destination;
}

import 'dart:async';
import 'dart:developer' as development;
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Extension on [ImageProvider] to add utility methods.
///
/// This extension provides convenient methods for converting
/// [ImageProvider] objects to raw bytes for image processing, including
/// an isolate-backed variant to keep the UI responsive during heavy work.
extension ImageProviderExt on ImageProvider {
  /// Converts the [ImageProvider] to raw bytes.
  ///
  /// This method resolves the image provider and converts the resulting
  /// image to raw bytes in the specified format. Useful for image
  /// processing operations that require raw data.
  ///
  /// Parameters:
  /// - [context]: The build context for resolving the image
  /// - [format]: The byte format for the output (default: [ImageByteFormat.png])
  ///
  /// Returns:
  /// - [Future<Uint8List?>]: The image as raw bytes, or null if conversion failed
  Future<Uint8List?> getBytes(
    BuildContext context, {
    ImageByteFormat format = ImageByteFormat.png,
  }) async {
    try {
      final imageStream = resolve(createLocalImageConfiguration(context));
      final Completer<Uint8List?> completer = Completer<Uint8List?>();
      final ImageStreamListener listener = ImageStreamListener(
        (imageInfo, synchronousCall) async {
          final bytes = await imageInfo.image.toByteData(format: format);
          if (!completer.isCompleted) {
            completer.complete(bytes?.buffer.asUint8List());
          }
        },
      );
      imageStream.addListener(listener);
      final imageBytes = await completer.future;
      imageStream.removeListener(listener);
      return imageBytes;
    } catch (e) {
      development.log("ERROR GET BYTES : $e");
      rethrow;
    }
  }

  /// Converts the [ImageProvider] to raw bytes on an isolate.
  ///
  /// This method mirrors [getBytes] but executes the work on a background
  /// isolate via [Isolate.run] to avoid blocking the main thread. Prefer this
  /// for large images or when calling from performance-sensitive code paths.
  ///
  /// Parameters:
  /// - [context]: The build context for resolving the image
  /// - [format]: The byte format for the output (default: [ImageByteFormat.png])
  ///
  /// Returns:
  /// - [Future<Uint8List?>]: The image as raw bytes, or null if conversion failed
  Future<Uint8List?> computeBytes(
    BuildContext context, {
    ImageByteFormat format = ImageByteFormat.png,
  }) {
    return Isolate.run(() async {
      return await getBytes(context, format: format);
    });
  }
}

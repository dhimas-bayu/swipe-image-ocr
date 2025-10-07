# Swipe Image OCR

A Flutter package that provides interactive image cropping and text recognition functionality using Google ML Kit. Users can draw selection areas on images by swiping their finger, and the package automatically crops the selected area and performs OCR text recognition.

## Features

- 🎯 **Interactive Image Cropping**: Draw selection areas by swiping across images
- 🔍 **OCR Text Recognition**: Automatic text extraction using Google ML Kit
- ⚡ **Performance Optimized**: Heavy operations run on isolates to keep UI responsive
- 🎨 **Customizable UI**: Configurable stroke width, colors, and border radius
- 📱 **Cross Platform**: Supports both Android and iOS
- 🛡️ **Error Handling**: Comprehensive error handling with callbacks



## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  swipe_image_ocr: ^0.0.1+1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart
import 'package:swipe_image_ocr/swipe_image_ocr.dart';
import 'dart:typed_data';

SwipeImageOCR(
  imageBytes: yourImageBytes, // Uint8List
  onSwipeImage: (File? file) {
    print('Cropped image saved to: ${file?.path}');
  },
  onTextRead: (String? text) {
    print('Recognized text: $text');
  },
  onErrorRead: (Object error, StackTrace? stackTrace) {
    print('Error occurred: $error');
  },
)
```

### Advanced Usage with Customization

```dart
SwipeImageOCR(
  imageBytes: imageBytes,
  borderRadius: BorderRadius.circular(12),
  strokeWidth: 20.0,
  swipeColor: Colors.blue.withOpacity(0.7),
  indicatorColor: Colors.red,
  onSwipeImage: (File? file) {
    // Handle cropped image
    if (file != null) {
      // Process the cropped image
      processCroppedImage(file);
    }
  },
  onTextRead: (String? text) {
    // Handle recognized text
    if (text != null && text.isNotEmpty) {
      setState(() {
        recognizedText = text;
      });
    }
  },
  onErrorRead: (Object error, StackTrace? stackTrace) {
    // Handle errors
    showErrorDialog(error.toString());
  },
)
```

## API Reference

### SwipeImageOCR

The main widget that provides the interactive image cropping and OCR functionality.

#### Constructor

```dart
SwipeImageOCR({
  Key? key,
  required Uint8List imageBytes,
  BorderRadiusGeometry? borderRadius,
  Function(File?)? onSwipeImage,
  Function(String?)? onTextRead,
  Function(Object, StackTrace)? onErrorRead,
  double strokeWidth = 16.0,
  Color? swipeColor,
  Color? indicatorColor,
})
```

#### Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `imageBytes` | `Uint8List` | The image data to display and crop | Required |
| `borderRadius` | `BorderRadiusGeometry?` | Border radius for the widget container | `null` |
| `onSwipeImage` | `Function(File?)?` | Callback when image is successfully cropped | `null` |
| `onTextRead` | `Function(String?)?` | Callback when text is successfully recognized | `null` |
| `onErrorRead` | `Function(Object, StackTrace)?` | Callback when an error occurs | `null` |
| `strokeWidth` | `double` | Width of the swipe stroke | `16.0` |
| `swipeColor` | `Color?` | Color of the swipe path | `null` (uses theme) |
| `indicatorColor` | `Color?` | Color of the selection indicator | `null` (uses theme) |

#### Callbacks

- **`onSwipeImage`**: Called when the user completes drawing a selection area and the image is successfully cropped. Receives a `File` object containing the cropped image, or `null` if cropping failed.

- **`onTextRead`**: Called when text recognition is successfully completed. Receives a `String` containing the recognized text, or `null` if text recognition failed.

- **`onErrorRead`**: Called when an error occurs during text recognition. Receives the error object and optional stack trace for debugging.

## Requirements

- Flutter SDK >= 3.3.0
- Dart SDK >= 3.9.0
- Android API level 21+ (Android 5.0)
- iOS 11.0+

## Dependencies

This package uses the following dependencies:

- `google_mlkit_text_recognition`: For OCR text recognition
- `google_mlkit_barcode_scanning`: For barcode scanning capabilities
- `image`: For image processing operations
- `path_provider`: For file system operations

## Example

Check out the [example](example/) directory for a complete implementation example.

To run the example:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please file an issue on the [GitHub repository](https://github.com/dhimas-bayu/swipe-image-reader).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.


import 'dart:io';

import 'package:swipe_image_ocr/swipe_image_ocr.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<File?> _fileNotifier = ValueNotifier(null);
  final ValueNotifier<File?> _croppedNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _croppedNotifier.dispose();
    _fileNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipe Image OCR'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Row(
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () async {
                  final file = await _picker.pickImage(
                    source: ImageSource.camera,
                  );

                  if (file != null) {
                    final imageFile = File(file.path);
                    _fileNotifier.value = imageFile;
                  }
                },
                child: const Text("Load Image"),
              ),
              FilledButton(
                onPressed: () async {
                  _croppedNotifier.value = null;
                  _fileNotifier.value = null;
                  _controller.text = "";
                },
                child: const Text("Clear Image"),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 32.0),
        children: [
          Column(
            spacing: 4.0,
            children: [
              Text(
                "Capture image",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                height: 360.0,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: ValueListenableBuilder(
                  valueListenable: _fileNotifier,
                  builder: (context, image, child) {
                    if (image == null) return const SizedBox();
                    return SwipeImageOCR(
                      imageBytes: image.readAsBytesSync(),
                      borderRadius: BorderRadius.circular(16.0),
                      onSwipeImage: (file) {
                        _croppedNotifier.value = file;
                      },
                      onTextRead: (text) {
                        _controller.text = "$text";
                      },
                      onErrorRead: (e, _) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              action: SnackBarAction(
                                label: "Dismiss",
                                onPressed: () {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                },
                              ),
                            ),
                          );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Column(
            spacing: 4.0,
            children: [
              Text(
                "Cropped image",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                height: 360.0,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: ValueListenableBuilder(
                  valueListenable: _croppedNotifier,
                  builder: (context, file, child) {
                    if (file == null) return const SizedBox();
                    return Image(image: FileImage(file), fit: BoxFit.contain);
                  },
                ),
              ),
            ],
          ),
          Column(
            spacing: 4.0,
            children: [
              Text(
                "Text result",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextField(
                controller: _controller,
                readOnly: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

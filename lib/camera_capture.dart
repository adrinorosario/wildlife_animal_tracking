import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

class CameraCapture extends StatefulWidget {
  const CameraCapture({super.key});

  @override
  State<CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<CameraCapture> {
  File? image; // thios is the image that will be captured from the camera

  final picker = ImagePicker(); // this is the image picker

  // the method that will pick the image of the animal
  Future<void> pickImage(ImageSource source) async {
    //pick the image using the camera
    final pickedImage = await picker.pickImage(source: source);

    // updated the selected image
    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // display the image
        // ? Check whether to use AnimatedSwitcher or AspectRatio
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: image != null
                ? Image.file(image!, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    width: double.infinity,
                    color: Colors.grey,
                    child: const Center(child: Text("No image selected")),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // the camera buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => pickImage(ImageSource.camera),
              child: const Text("Take photo"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

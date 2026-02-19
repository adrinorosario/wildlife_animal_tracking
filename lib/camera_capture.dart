import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Ensure SavannahColors is accessible (either imported or defined here)
class SavannahColors {
  static const Color beigeLight = Color(0xFFF6F1E1);
  static const Color beigeDark = Color(0xFFECE6D4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color greenOlive = Color(0xFF4F5D2F);
  static const Color greenDeep = Color(0xFF3E4A24);
  static const Color textBlack = Color(0xFF1F1F1F);
  static const Color textGrey = Color(0xFF4B4B4B);
}

// class CameraCapture extends StatefulWidget {
//   const CameraCapture({super.key});
class CameraCapture extends StatefulWidget {
  final Function(File)? onImageCaptured;
  const CameraCapture({super.key, this.onImageCaptured});

  @override
  State<CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<CameraCapture> {
  File? image;
  final picker = ImagePicker();

  // Future<void> pickImage(ImageSource source) async {
  //   final pickedImage = await picker.pickImage(source: source);
  //   if (pickedImage != null) {
  //     setState(() {
  //       image = File(pickedImage.path);
  //     });
  //   }
  // }
  Future<void> pickImage(ImageSource source) async {
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
      });

      // ADD THIS LINE to trigger classification
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!(image!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Image Display Area
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: SavannahColors.beigeDark.withOpacity(0.5),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: image != null
                ? Image.file(
                    key: ValueKey(image!.path),
                    image!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_search_rounded,
                        size: 48,
                        color: SavannahColors.greenOlive,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tap to capture animal",
                        style: TextStyle(
                          color: SavannahColors.greenOlive,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Camera Trigger Button (Floating Overlay Style)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => pickImage(ImageSource.camera),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SavannahColors.greenDeep.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: SavannahColors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "TAKE PHOTO",
                      style: TextStyle(
                        color: SavannahColors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

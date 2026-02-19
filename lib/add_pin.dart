import "dart:io";
import "package:flutter/material.dart";
import "package:wildlife_tracker/camera_capture.dart";
import 'package:geolocator/geolocator.dart';
import 'package:wildlife_tracker/theme_colors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PinType {
  injured(color: SavannahColors.orangeCaramel, title: "Injured animal"),
  sighting(color: SavannahColors.greenOlive, title: "Animal sighting"),
  displaced(color: SavannahColors.orangeSand, title: "Displaced animal"),
  lostInUrban(color: Color(0xFF8B7355), title: "Lost in urban area");

  const PinType({required this.color, required this.title});
  final Color color;
  final String title;
}

class AddPin extends StatefulWidget {
  const AddPin({super.key});

  @override
  State<AddPin> createState() => _AddPinState();
}

class _AddPinState extends State<AddPin> {
  bool isSirenActive = false;
  PinType selectedType = PinType.values.first;
  String? identifiedSpecies;
  File? _capturedImage;
  bool _isSubmitting = false;

  static final pinTypeEntries = PinType.values
      .map(
        (pinType) => DropdownMenuEntry<PinType>(
          value: pinType,
          label: pinType.title,
          style: MenuItemButton.styleFrom(
            foregroundColor: SavannahColors.textBlack,
          ),
        ),
      )
      .toList();

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permanently denied");
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Uploads the image to Firebase Cloud Storage and returns the download URL.
  Future<String> _uploadImage(File imageFile) async {
    final fileName = 'sightings/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    final uploadTask = await storageRef.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Saves the sighting record to Firestore.
  Future<void> _saveSightingToFirestore({
    required String imageUrl,
    required String pinType,
    required double latitude,
    required double longitude,
    required bool sirenActive,
    String? species,
  }) async {
    await FirebaseFirestore.instance.collection('animal_sightings').add({
      'imageUrl': imageUrl,
      'pinType': pinType,
      'species': species ?? 'Unknown',
      'latitude': latitude,
      'longitude': longitude,
      'sirenActive': sirenActive,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Handles the full submission: upload image, save to Firestore, and pop.
  Future<void> _submitSighting() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture an image first")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Get current location
      final position = await _getCurrentLocation();

      // 2. Upload image to Cloud Storage
      final imageUrl = await _uploadImage(_capturedImage!);

      // 3. Build the title
      String title = selectedType.title;
      if (identifiedSpecies != null && identifiedSpecies!.isNotEmpty) {
        title += " ($identifiedSpecies)";
      }

      // 4. Save to Firestore
      await _saveSightingToFirestore(
        imageUrl: imageUrl,
        pinType: selectedType.title,
        latitude: position.latitude,
        longitude: position.longitude,
        sirenActive: isSirenActive,
        species: identifiedSpecies,
      );

      debugPrint("Sighting saved to Firestore successfully");

      // 5. Pop with result for map marker
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sighting saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, {
          "pinType": title,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "species": identifiedSpecies,
        });
      }
    } catch (e) {
      debugPrint("Error submitting sighting: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Pin")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Form(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: CameraCapture(
                            onSpeciesIdentified: (species) {
                              setState(() {
                                identifiedSpecies = species;
                              });
                              debugPrint("Species identified: $species");
                            },
                            onImageCaptured: (File file) {
                              setState(() {
                                _capturedImage = file;
                              });
                              debugPrint("Image captured: ${file.path}");
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Status:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return DropdownMenu<PinType>(
                                        width: constraints.maxWidth,
                                        initialSelection: PinType.values.first,
                                        onSelected: (PinType? value) {
                                          if (value != null) {
                                            setState(() {
                                              selectedType = value;
                                            });
                                          }
                                        },
                                        dropdownMenuEntries: pinTypeEntries,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "Siren:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: SegmentedButton<bool>(
                                      style: SegmentedButton.styleFrom(
                                        backgroundColor: Colors.grey[200],
                                        foregroundColor: Colors.black,
                                        selectedBackgroundColor: isSirenActive
                                            ? Colors.green
                                            : Colors.red,
                                        selectedForegroundColor: Colors.white,
                                      ),
                                      segments: const [
                                        ButtonSegment(
                                          value: true,
                                          label: Text("Active"),
                                        ),
                                        ButtonSegment(
                                          value: false,
                                          label: Text("Inactive"),
                                        ),
                                      ],
                                      selected: <bool>{isSirenActive},
                                      onSelectionChanged:
                                          (Set<bool> newSelection) {
                                            setState(() {
                                              isSirenActive =
                                                  newSelection.first;
                                            });
                                          },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSighting,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text("Submit Pin"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Full-screen loading overlay during submission
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Uploading sighting...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

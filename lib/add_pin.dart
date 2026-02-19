// import "package:flutter/material.dart";
// import "package:wildlife_tracker/camera_capture.dart";
// import 'package:collection/collection.dart';
// import 'package:geolocator/geolocator.dart';

// class SavannahColors {
//   static const Color beigeLight = Color(0xFFF6F1E1);
//   static const Color beigeDark = Color(0xFFECE6D4);
//   static const Color white = Color(0xFFFFFFFF);
//   static const Color greenOlive = Color(0xFF4F5D2F);
//   static const Color greenDeep = Color(0xFF3E4A24);
//   static const Color orangeCaramel = Color(0xFFC88A3D);
//   static const Color orangeSand = Color(0xFFE3B071);
//   static const Color textBlack = Color(0xFF1F1F1F);
//   static const Color textGrey = Color(0xFF4B4B4B);
// }

// enum PinType {
//   injured(color: SavannahColors.orangeCaramel, title: "Injured animal"),
//   sighting(color: SavannahColors.greenOlive, title: "Animal sighting"),
//   displaced(color: SavannahColors.orangeSand, title: "Displaced animal"),
//   lostInUrban(color: Color(0xFF8B7355), title: "Lost in urban area");

//   const PinType({required this.color, required this.title});
//   final Color color;
//   final String title;
// }

// class AddPin extends StatefulWidget {
//   const AddPin({super.key});

//   @override
//   State<AddPin> createState() => _AddPinState();
// }

// class _AddPinState extends State<AddPin> {
//   bool isSirenActive = false;
//   // Store the actual enum instead of just the title for easier logic
//   PinType selectedType = PinType.values.first;

//   static final pinTypeEntries = PinType.values.map(
//     (pinType) => DropdownMenuEntry<PinType>(
//       value: pinType,
//       label: pinType.title,
//       style: MenuItemButton.styleFrom(foregroundColor: SavannahColors.textBlack),
//     ),
//   ).toList();

//   Future<Position> _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) throw Exception("Location services disabled");

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     if (permission == LocationPermission.deniedForever) {
//       throw Exception("Location permanently denied");
//     }
//     return await Geolocator.getCurrentPosition();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Logic: Siren is ONLY allowed if the type is 'injured'
//     bool canEnableSiren = selectedType == PinType.injured;

//     return Scaffold(
//       backgroundColor: SavannahColors.beigeLight,
//       appBar: AppBar(
//         backgroundColor: SavannahColors.white.withOpacity(0.8),
//         title: const Text(
//           "NEW REPORT",
//           style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.w900, color: SavannahColors.textBlack, fontSize: 14.0),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: Container(
//                 height: 280,
//                 decoration: BoxDecoration(
//                   color: SavannahColors.beigeDark,
//                   border: Border.all(color: SavannahColors.beigeDark, width: 2),
//                 ),
//                 child: const CameraCapture(),
//               ),
//             ),
//             const SizedBox(height: 32),

//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: SavannahColors.white,
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(color: SavannahColors.beigeDark, width: 1),
//               ),
//               child: Column(
//                 children: [
//                   _buildFormLabel("Incident Type"),
//                   const SizedBox(height: 12),
//                   DropdownMenu<PinType>(
//                     width: MediaQuery.of(context).size.width - 96,
//                     initialSelection: selectedType,
//                     inputDecorationTheme: InputDecorationTheme(
//                       filled: true,
//                       fillColor: SavannahColors.beigeLight.withOpacity(0.5),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: SavannahColors.beigeDark),
//                       ),
//                     ),
//                     onSelected: (PinType? value) {
//                       setState(() {
//                         selectedType = value!;
//                         // Automatically turn off siren if type changes to something else
//                         if (selectedType != PinType.injured) {
//                           isSirenActive = false;
//                         }
//                       });
//                     },
//                     dropdownMenuEntries: pinTypeEntries,
//                   ),

//                   const SizedBox(height: 32),

//                   _buildFormLabel("Siren Status"),
//                   const SizedBox(height: 4),
//                   if (!canEnableSiren)
//                     const Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         "Only available for injured animals",
//                         style: TextStyle(color: SavannahColors.orangeCaramel, fontSize: 10, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   const SizedBox(height: 8),
//                   SizedBox(
//                     width: double.infinity,
//                     child: SegmentedButton<bool>(
//                       // Disable the button if it's not an injured animal
//                       onSelectionChanged: canEnableSiren
//                         ? (Set<bool> newSelection) {
//                             setState(() => isSirenActive = newSelection.first);
//                           }
//                         : null, // Setting this to null disables the interaction
//                       style: SegmentedButton.styleFrom(
//                         backgroundColor: SavannahColors.beigeLight,
//                         // Visual feedback for disabled state
//                         disabledBackgroundColor: SavannahColors.beigeDark.withOpacity(0.5),
//                         selectedBackgroundColor: isSirenActive
//                             ? SavannahColors.orangeCaramel
//                             : SavannahColors.greenOlive,
//                         selectedForegroundColor: Colors.white,
//                         side: const BorderSide(color: SavannahColors.beigeDark),
//                       ),
//                       segments: const [
//                         ButtonSegment(
//                           value: true,
//                           label: Text("Active"),
//                           icon: Icon(Icons.warning_amber_rounded)
//                         ),
//                         ButtonSegment(
//                           value: false,
//                           label: Text("Inactive"),
//                           icon: Icon(Icons.notifications_off_outlined)
//                         ),
//                       ],
//                       selected: <bool>{isSirenActive},
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 40),

//             ElevatedButton(
//               onPressed: () async {
//                 try {
//                   Position position = await _getCurrentLocation();
//                   if (context.mounted) {
//                     Navigator.pop(context, {
//                       "pinType": selectedType.title,
//                       "isSirenActive": isSirenActive,
//                       "latitude": position.latitude,
//                       "longitude": position.longitude,
//                     });
//                   }
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       backgroundColor: SavannahColors.orangeCaramel,
//                       content: Text("Location error: Check permissions"),
//                     ),
//                   );
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//                 backgroundColor: SavannahColors.greenDeep,
//                 foregroundColor: SavannahColors.white,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               ),
//               child: const Text(
//                 "SUBMIT REPORT",
//                 style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFormLabel(String label) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Text(
//         label.toUpperCase(),
//         style: const TextStyle(
//           color: SavannahColors.textGrey,
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1.2,
//         ),
//       ),
//     );
//   }
// }

import "package:flutter/material.dart";
import "package:wildlife_tracker/camera_capture.dart";
import "package:wildlife_tracker/classifier.dart";
import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';

class SavannahColors {
  static const Color beigeLight = Color(0xFFF6F1E1);
  static const Color beigeDark = Color(0xFFECE6D4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color greenOlive = Color(0xFF4F5D2F);
  static const Color greenDeep = Color(0xFF3E4A24);
  static const Color orangeCaramel = Color(0xFFC88A3D);
  static const Color orangeSand = Color(0xFFE3B071);
  static const Color textBlack = Color(0xFF1F1F1F);
  static const Color textGrey = Color(0xFF4B4B4B);
}

enum PinType {
  injured(
    color: Color.fromARGB(255, 230, 14, 14), 
    hue: BitmapDescriptor.hueRed, 
    title: "Injured animal"
  ),
  sighting(
    color: Color.fromARGB(255, 16, 43, 176), 
    hue: BitmapDescriptor.hueBlue, 
    title: "Animal sighting"
  ),
  displaced(
    color: Color.fromARGB(255, 225, 129, 11), 
    hue: BitmapDescriptor.hueOrange, 
    title: "Displaced animal"
  ),
  lostInUrban(
    color: Color.fromARGB(255, 229, 240, 22), 
    hue: BitmapDescriptor.hueYellow, 
    title: "Lost in urban area"
  );

  // THE FIX: Added 'this.hue' to the constructor and defined 'final double hue'
  const PinType({
    required this.color, 
    required this.hue, 
    required this.title
  });

  final Color color;
  final double hue; // This stores the 0.0 - 360.0 value for Google Maps
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

  // NEW: Classifier instance
  final AnimalClassifier _classifier = AnimalClassifier();

  // NEW: Store captured image and predictions
  File? _capturedImage;
  List<Prediction>? _predictions;
  bool _isClassifying = false;

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

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // NEW: Load the classifier model
  Future<void> _loadModel() async {
    await _classifier.loadModel();
  }

  // NEW: Handle image capture and classification
  Future<void> _onImageCaptured(File imageFile) async {
    setState(() {
      _capturedImage = imageFile;
      _isClassifying = true;
      _predictions = null;
    });

    try {
      final predictions = await _classifier.classifyImage(imageFile);
      setState(() {
        _predictions = predictions;
        _isClassifying = false;
      });
    } catch (e) {
      setState(() {
        _isClassifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SavannahColors.orangeCaramel,
            content: Text('Classification error: $e'),
          ),
        );
      }
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services disabled");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permanently denied");
    }
    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canEnableSiren = selectedType == PinType.injured;

    return Scaffold(
      backgroundColor: SavannahColors.beigeLight,
      appBar: AppBar(
        backgroundColor: SavannahColors.white.withOpacity(0.8),
        title: const Text(
          "NEW REPORT",
          style: TextStyle(
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            color: SavannahColors.textBlack,
            fontSize: 14.0,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: SavannahColors.beigeDark,
                  border: Border.all(color: SavannahColors.beigeDark, width: 2),
                ),
                // MODIFIED: Pass callback to CameraCapture
                child: CameraCapture(onImageCaptured: _onImageCaptured),
              ),
            ),
            const SizedBox(height: 16),

            // NEW: Show classification results
            if (_isClassifying)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SavannahColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SavannahColors.greenOlive,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Identifying animal...",
                      style: TextStyle(
                        color: SavannahColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            if (_predictions != null && _predictions!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SavannahColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SavannahColors.greenOlive,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DETECTED SPECIES",
                      style: TextStyle(
                        color: SavannahColors.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._predictions!.take(3).map((prediction) {
                      final parts = prediction.label.split(',');
                      final commonName = parts.length > 1
                          ? parts[1]
                          : prediction.label;
                      final scientificName = parts.length > 2 ? parts[2] : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    commonName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: SavannahColors.textBlack,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (scientificName.isNotEmpty)
                                    Text(
                                      scientificName,
                                      style: const TextStyle(
                                        color: SavannahColors.textGrey,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: SavannahColors.greenOlive.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: SavannahColors.greenDeep,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SavannahColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SavannahColors.beigeDark, width: 1),
              ),
              child: Column(
                children: [
                  _buildFormLabel("Incident Type"),
                  const SizedBox(height: 12),
                  DropdownMenu<PinType>(
                    width: MediaQuery.of(context).size.width - 96,
                    initialSelection: selectedType,
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: SavannahColors.beigeLight.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: SavannahColors.beigeDark,
                        ),
                      ),
                    ),
                    onSelected: (PinType? value) {
                      setState(() {
                        selectedType = value!;
                        if (selectedType != PinType.injured) {
                          isSirenActive = false;
                        }
                      });
                    },
                    dropdownMenuEntries: pinTypeEntries,
                  ),

                  const SizedBox(height: 32),

                  _buildFormLabel("Siren Status"),
                  const SizedBox(height: 4),
                  if (!canEnableSiren)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Only available for injured animals",
                        style: TextStyle(
                          color: SavannahColors.orangeCaramel,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      onSelectionChanged: canEnableSiren
                          ? (Set<bool> newSelection) {
                              setState(
                                () => isSirenActive = newSelection.first,
                              );
                            }
                          : null,
                      style: SegmentedButton.styleFrom(
                        backgroundColor: SavannahColors.beigeLight,
                        disabledBackgroundColor: SavannahColors.beigeDark
                            .withOpacity(0.5),
                        selectedBackgroundColor: isSirenActive
                            ? SavannahColors.orangeCaramel
                            : SavannahColors.greenOlive,
                        selectedForegroundColor: Colors.white,
                        side: const BorderSide(color: SavannahColors.beigeDark),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text("Active"),
                          icon: Icon(Icons.warning_amber_rounded),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text("Inactive"),
                          icon: Icon(Icons.notifications_off_outlined),
                        ),
                      ],
                      selected: <bool>{isSirenActive},
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () async {
                try {
                  Position position = await _getCurrentLocation();
                  if (context.mounted) {
                    Navigator.pop(context, {
                      "pinType": selectedType.title,
                      "isSirenActive": isSirenActive,
                      "latitude": position.latitude,
                      "longitude": position.longitude,
                      // NEW: Include detected species if available
                      "detectedSpecies": _predictions?.isNotEmpty == true
                          ? _predictions!.first.label
                                    .split(',')
                                    .elementAtOrNull(1) ??
                                "Unknown"
                          : null,
                      "confidence": _predictions?.isNotEmpty == true
                          ? _predictions!.first.confidence
                          : null,
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: SavannahColors.orangeCaramel,
                      content: Text("Location error: Check permissions"),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: SavannahColors.greenDeep,
                foregroundColor: SavannahColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "SUBMIT REPORT",
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: SavannahColors.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

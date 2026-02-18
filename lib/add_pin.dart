import "package:flutter/material.dart";
import "package:wildlife_tracker/camera_capture.dart";
import 'package:collection/collection.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

enum PinType {
  injured(color: Colors.red, title: "Injured animal"),
  sighting(color: Colors.blue, title: "Animal sighting"),
  displaced(color: Colors.orange, title: "Displaced animal"),
  lostInUrban(color: Colors.yellow, title: "Lost in urban area");

  const PinType({required this.color, required this.title});

  final Color color;
  final String title;
}

class PinForm {
  const PinForm({
    required this.pinType,
    required this.latitude,
    required this.longitude,
  });

  final PinType pinType;
  final double latitude;
  final double longitude;
}

class AddPin extends StatefulWidget {
  const AddPin({super.key});

  @override
  State<AddPin> createState() => _AddPinState();
}

typedef PinTypeEntry = DropdownMenuEntry<PinType>;

class _AddPinState extends State<AddPin> {
  // String? pinType;
  bool isSirenActive = false;

  static final pinTypeEntries = UnmodifiableListView<PinTypeEntry>(
    PinType.values.map(
      (pinType) => PinTypeEntry(value: pinType, label: pinType.title),
    ),
  );
  String dropDownValue = PinType.values.first.title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Pin")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                child: Column(
                  children: [
                    SizedBox(height: 250, child: CameraCapture()),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  "Status:",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              DropdownMenu<PinType>(
                                initialSelection: PinType.values.first,
                                onSelected: (PinType? value) {
                                  setState(() {
                                    dropDownValue = value!.title;
                                  });
                                },
                                dropdownMenuEntries: pinTypeEntries,
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  "Siren:",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              // ToggleSwitch(
                              //   minWidth: 90.0,
                              //   cornerRadius: 20.0,
                              //   activeBgColors: [
                              //     [Colors.green[800]!],
                              //     [Colors.red[800]!],
                              //   ],
                              //   activeFgColor: Colors.white,
                              //   inactiveBgColor: Colors.grey,
                              //   inactiveFgColor: Colors.white,
                              //   initialLabelIndex: 1,
                              //   totalSwitches: 2,
                              //   labels: ['Active', 'Inactive'],
                              //   radiusStyle: true,
                              //   onToggle: (index) {
                              //     setState(() {
                              //       isSirenActive = !isSirenActive;
                              //     });
                              //   },
                              // ),
                              SegmentedButton<bool>(
                                style: SegmentedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black,
                                  selectedBackgroundColor: isSirenActive
                                      ? Colors.green
                                      : Colors.red,
                                  selectedForegroundColor: Colors.white,
                                ),
                                segments: [
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
                                onSelectionChanged: (Set<bool> newSelection) {
                                  setState(() {
                                    isSirenActive = newSelection.first;
                                  });
                                },
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Pin submitted",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                        width: 300,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.green[500],
                        action: SnackBarAction(
                          label: "Dismiss",
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Submit Pin"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

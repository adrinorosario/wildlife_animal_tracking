import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AnimalClassifier {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> loadModel() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset(
        'assets/animal_classifier.tflite',
      );

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList();

      print('Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<Prediction>> classifyImage(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('Model not loaded');
    }

    // Read and preprocess image
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to 224x224
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // Convert to input tensor format (uint8)
    var input = List.generate(
      224,
      (y) => List.generate(224, (x) {
        final pixel = resizedImage.getPixel(x, y);
        return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
      }),
    );

    // Prepare output buffer
    var output = List.filled(
      1 * _labels!.length,
      0,
    ).reshape([1, _labels!.length]);

    // Run inference
    _interpreter!.run([input], output);

    // Get top 3 predictions
    List<Prediction> predictions = [];
    for (int i = 0; i < _labels!.length; i++) {
      // Convert uint8 output (0-255) to probability (0-1)
      double confidence = output[0][i] / 255.0;
      predictions.add(Prediction(label: _labels![i], confidence: confidence));
    }

    // Sort by confidence and return top 3
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions.take(3).toList();
  }

  void dispose() {
    _interpreter?.close();
  }
}

class Prediction {
  final String label;
  final double confidence;

  Prediction({required this.label, required this.confidence});
}

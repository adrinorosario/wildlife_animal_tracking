import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'dart:convert';
import 'dart:math' as math;

// class CameraCapture extends StatefulWidget {
//   const CameraCapture({super.key});
class CameraCapture extends StatefulWidget {
  final void Function(String)? onSpeciesIdentified;
  final void Function(File)? onImageCaptured;

  const CameraCapture({
    super.key,
    this.onSpeciesIdentified,
    this.onImageCaptured,
  });

  @override
  State<CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<CameraCapture> {
  File? image;
  final picker = ImagePicker();
  OrtSession? _session;
  String? _result;
  List<String>? _labels;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  @override
  void dispose() {
    _session?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _session = await OnnxRuntime().createSessionFromAsset(
        'assets/models/bioclip2_model_int8.onnx',
      );
      debugPrint("Model loaded successfully");
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  List<List<double>>? _speciesEmbeddings;

  Future<void> _loadLabels() async {
    try {
      final labelsJson = await rootBundle.loadString('species_labels.json');
      final labelsList = (json.decode(labelsJson) as List<dynamic>)
          .cast<String>();

      final embeddingsJson = await rootBundle.loadString(
        'assets/models/species_embeddings.json',
      );
      final embeddingsList = (json.decode(embeddingsJson) as List<dynamic>)
          .map((e) => (e as List<dynamic>).cast<double>())
          .toList();

      if (labelsList.length != embeddingsList.length) {
        debugPrint(
          "Warning: Labels count (${labelsList.length}) != Embeddings count (${embeddingsList.length})",
        );
      }

      if (!mounted) return;
      setState(() {
        _labels = labelsList;
        _speciesEmbeddings = embeddingsList;
      });
      debugPrint("Loaded ${_labels?.length} labels and embeddings.");
    } catch (e) {
      debugPrint("Error loading labels/embeddings: $e");
      if (!mounted) return;
      setState(() {
        _labels = [];
        _speciesEmbeddings = [];
      });
    }
  }

  // Future<void> pickImage(ImageSource source) async {
  //   final pickedImage = await picker.pickImage(source: source);
  //   if (pickedImage != null) {
  //     setState(() {
  //       image = File(pickedImage.path);
  //     });
  //   }
  // }
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedImage != null) {
        if (!mounted) return;
        final imageFile = File(pickedImage.path);
        setState(() {
          image = imageFile;
          _result = null;
          _isAnalyzing = true;
        });
        widget.onImageCaptured?.call(imageFile);
        _runInference();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _runInference() async {
    if (image == null) return;
    if (_session == null) {
      debugPrint("Model not loaded");
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _result = "Model not loaded";
      });
      return;
    }

    try {
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // UI update yield
      if (!mounted) return;

      // 1. Preprocess Image
      final imageBytes = await image!.readAsBytes();
      var imageDecoded = img.decodeImage(imageBytes);
      if (imageDecoded == null) {
        if (!mounted) return;
        setState(() {
          _result = 'Failed to decode image';
          _isAnalyzing = false;
        });
        return;
      }

      // Fix orientation (e.g. from camera EXIF)
      imageDecoded = img.bakeOrientation(imageDecoded);

      // CLIP preprocessing: resize shortest side to 224, then center crop
      final int origW = imageDecoded.width;
      final int origH = imageDecoded.height;
      debugPrint("Original image: ${origW}x${origH}");

      img.Image resizedForCrop;
      if (origW < origH) {
        // Width is shorter, resize width to 224
        resizedForCrop = img.copyResize(
          imageDecoded,
          width: 224,
          interpolation: img.Interpolation.cubic,
        );
      } else {
        // Height is shorter, resize height to 224
        resizedForCrop = img.copyResize(
          imageDecoded,
          height: 224,
          interpolation: img.Interpolation.cubic,
        );
      }

      debugPrint(
        "After resize: ${resizedForCrop.width}x${resizedForCrop.height}",
      );

      // Center crop to 224x224
      final int cropX = (resizedForCrop.width - 224) ~/ 2;
      final int cropY = (resizedForCrop.height - 224) ~/ 2;
      final imageResized = img.copyCrop(
        resizedForCrop,
        x: cropX,
        y: cropY,
        width: 224,
        height: 224,
      );

      debugPrint(
        "After center crop: ${imageResized.width}x${imageResized.height}",
      );

      // 2. Prepare Input Tensor
      final inputData = Float32List(1 * 3 * 224 * 224);
      final int imageSize = 224 * 224;
      final mean = [0.48145466, 0.4578275, 0.40821073];
      final std = [0.26862954, 0.26130258, 0.27577711];

      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = imageResized.getPixel(x, y);
          inputData[y * 224 + x] = ((pixel.r / 255.0) - mean[0]) / std[0]; // R
          inputData[imageSize + (y * 224 + x)] =
              ((pixel.g / 255.0) - mean[1]) / std[1]; // G
          inputData[2 * imageSize + (y * 224 + x)] =
              ((pixel.b / 255.0) - mean[2]) / std[2]; // B
        }
      }

      // Debug: verify pixel values and tensor range
      final centerPixel = imageResized.getPixel(112, 112);
      debugPrint(
        "Center pixel RGB: r=${centerPixel.r}, g=${centerPixel.g}, b=${centerPixel.b}",
      );

      // Check tensor statistics
      double tMin = double.infinity, tMax = -double.infinity, tSum = 0;
      for (int i = 0; i < inputData.length; i++) {
        if (inputData[i] < tMin) tMin = inputData[i];
        if (inputData[i] > tMax) tMax = inputData[i];
        tSum += inputData[i];
      }
      debugPrint(
        "Input tensor: min=${tMin.toStringAsFixed(3)}, max=${tMax.toStringAsFixed(3)}, mean=${(tSum / inputData.length).toStringAsFixed(3)}",
      );

      OrtValue? inputOrt;
      OrtRunOptions? runOptions;

      try {
        final startTime = DateTime.now();
        inputOrt = await OrtValue.fromList(inputData, [1, 3, 224, 224]);
        runOptions = OrtRunOptions(logSeverityLevel: 3);

        // 3. Run Inference
        final outputs = await _session!.run({
          _session!.inputNames[0]: inputOrt,
        }, options: runOptions);

        final inferDuration = DateTime.now()
            .difference(startTime)
            .inMilliseconds;
        debugPrint("Inference took: ${inferDuration}ms");

        // 4. Postprocess Output
        if (outputs.isEmpty) {
          if (!mounted) return;
          setState(() {
            _result = 'No output from model';
            _isAnalyzing = false;
          });
          return;
        }

        // Retrieve and copy data, then dispose immediately
        final outputValue = outputs.values.first;
        List<double> rawEmbedding;
        try {
          final rawList = await outputValue.asList();
          rawEmbedding = (rawList[0] as List<dynamic>).cast<double>();
        } finally {
          // Dispose ALL output values
          for (final val in outputs.values) {
            val.dispose();
          }
        }

        debugPrint("Embedding Length: ${rawEmbedding.length}");

        if (_speciesEmbeddings == null || _speciesEmbeddings!.isEmpty) {
          if (!mounted) return;
          setState(() {
            _result = 'No species embeddings loaded';
            _isAnalyzing = false;
          });
          return;
        }

        // Normalize image embedding
        double sumSq = 0.0;
        for (double v in rawEmbedding) sumSq += v * v;
        double magnitude = 0.0;
        if (sumSq > 0) magnitude = math.sqrt(sumSq);

        // Log magnitude to check for "pathetic" zero vectors
        debugPrint("Image embedding magnitude: $magnitude");
        if (magnitude < 0.0001) {
          debugPrint("WARNING: Zero vector returned from model!");
        }

        List<double> imageEmbedding = [];
        if (magnitude > 0) {
          imageEmbedding = rawEmbedding.map((e) => e / magnitude).toList();
        } else {
          imageEmbedding = rawEmbedding;
        }

        var maxScore = -double.infinity;
        var maxIndex = -1;

        // Compute scores for top-k logging
        // Optimization: Use a fixed-size priority queue or just list
        List<MapEntry<int, double>> allScores = [];

        for (var i = 0; i < _speciesEmbeddings!.length; i++) {
          final textEmbedding = _speciesEmbeddings![i];
          double dotProduct = 0.0;
          // Unroll loop slightly or just standard loop
          for (var j = 0; j < imageEmbedding.length; j++) {
            dotProduct += imageEmbedding[j] * textEmbedding[j];
          }
          double score = dotProduct * 100.0;

          if (score > maxScore) {
            maxScore = score;
            maxIndex = i;
          }
          allScores.add(MapEntry(i, score));
        }

        // Sort to find top 5 for debugging
        allScores.sort((a, b) => b.value.compareTo(a.value));
        debugPrint("--- TOP 5 PREDICTIONS ---");
        for (var k = 0; k < 5 && k < allScores.length; k++) {
          final idx = allScores[k].key;
          final name = _labels != null && idx < _labels!.length
              ? _labels![idx]
              : "Index $idx";
          debugPrint("$name: ${allScores[k].value.toStringAsFixed(2)}%");
        }

        if (maxIndex != -1 && _labels != null && maxIndex < _labels!.length) {
          final speciesName = _labels![maxIndex];
          if (!mounted) return;
          setState(() {
            _result = "$speciesName (${maxScore.toStringAsFixed(1)}%)";
            _isAnalyzing = false;
          });
          widget.onSpeciesIdentified?.call(speciesName);
        } else {
          if (!mounted) return;
          setState(() {
            _result = 'Unknown (Max: ${maxScore.toStringAsFixed(1)}%)';
            _isAnalyzing = false;
          });
        }
      } finally {
        inputOrt?.dispose();
        // runOptions?.dispose(); // Check if needed, but safer not to if unsure. OrtRunOptions in flutter_onnxruntime might not have dispose exposed or needed.
      }
    } catch (e) {
      debugPrint("Inference error: $e");
      if (!mounted) return;
      setState(() {
        _result = 'Error analyzing image';
        _isAnalyzing = false;
      });

      // ADD THIS LINE to trigger classification
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!(image!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    Image.file(image!, fit: BoxFit.cover)
                  else
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            "No image selected",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              "Analyzing...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_result != null && !_isAnalyzing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Text(
              'Species: $_result',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing
                ? null
                : () => pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera),
            label: const Text("Take Photo"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

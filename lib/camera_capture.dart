import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'dart:convert';
import 'dart:math' as math;

class CameraCapture extends StatefulWidget {
  final void Function(String)? onSpeciesIdentified;

  const CameraCapture({super.key, this.onSpeciesIdentified});

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

      setState(() {
        _labels = labelsList;
        _speciesEmbeddings = embeddingsList;
      });
      debugPrint("Loaded ${_labels?.length} labels and embeddings.");
    } catch (e) {
      debugPrint("Error loading labels/embeddings: $e");
      setState(() {
        _labels = [];
        _speciesEmbeddings = [];
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedImage = await picker.pickImage(source: source);

      if (pickedImage != null) {
        setState(() {
          image = File(pickedImage.path);
          _result = null;
          _isAnalyzing = true;
        });
        _runInference();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _runInference() async {
    if (image == null) return;
    if (_session == null) {
      debugPrint("Model not loaded");
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

      // 1. Preprocess Image
      final imageBytes = await image!.readAsBytes();
      final imageDecoded = img.decodeImage(imageBytes);
      if (imageDecoded == null) {
        setState(() {
          _result = 'Failed to decode image';
          _isAnalyzing = false;
        });
        return;
      }

      final imageResized = img.copyResize(
        imageDecoded,
        width: 224,
        height: 224,
      );

      // 2. Prepare Input Tensor
      // Flatten image data to Float32List (1 * 3 * 224 * 224) - NCHW format
      // Normalize pixel values (0-1)
      final inputData = Float32List(1 * 3 * 224 * 224);
      final int imageSize = 224 * 224;

      final mean = [0.48145466, 0.4578275, 0.40821073];
      final std = [0.26862954, 0.26130258, 0.27577711];

      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = imageResized.getPixel(x, y);

          // Normalize: (value - mean) / std
          inputData[y * 224 + x] = ((pixel.r / 255.0) - mean[0]) / std[0]; // R
          inputData[imageSize + (y * 224 + x)] =
              ((pixel.g / 255.0) - mean[1]) / std[1]; // G
          inputData[2 * imageSize + (y * 224 + x)] =
              ((pixel.b / 255.0) - mean[2]) / std[2]; // B
        }
      }

      final inputOrt = await OrtValue.fromList(inputData, [1, 3, 224, 224]);
      final runOptions = OrtRunOptions(logSeverityLevel: 3);

      // 3. Run Inference
      final outputs = await _session!.run({
        _session!.inputNames[0]: inputOrt,
      }, options: runOptions);

      // 4. Postprocess Output
      if (outputs.isNotEmpty) {
        final outputValue = outputs.values.first;
        final rawEmbeddingList = await outputValue.asList();
        // Assuming output shape [1, 512] or similar
        final rawEmbedding = (rawEmbeddingList[0] as List<dynamic>)
            .cast<double>();
        debugPrint("Embedding Length: ${rawEmbedding.length}");
        outputValue.dispose();

        if (_speciesEmbeddings == null || _speciesEmbeddings!.isEmpty) {
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

        List<double> imageEmbedding = [];
        if (magnitude > 0) {
          imageEmbedding = rawEmbedding.map((e) => e / magnitude).toList();
        } else {
          imageEmbedding = rawEmbedding;
        }

        // Compute dot product with all species text embeddings
        // Text embeddings are already normalized from Python script
        var maxScore = -double.infinity;
        var maxIndex = -1;

        for (var i = 0; i < _speciesEmbeddings!.length; i++) {
          final textEmbedding = _speciesEmbeddings![i];
          // Size check, but skipping for perf
          double dotProduct = 0.0;
          for (var j = 0; j < imageEmbedding.length; j++) {
            dotProduct += imageEmbedding[j] * textEmbedding[j];
          }

          // Scale by 100 as per user script
          double score = dotProduct * 100.0;

          if (score > maxScore) {
            maxScore = score;
            maxIndex = i;
          }
        }

        if (maxIndex != -1 && _labels != null && maxIndex < _labels!.length) {
          final speciesName = _labels![maxIndex];
          setState(() {
            _result = "$speciesName (${maxScore.toStringAsFixed(1)}%)";
            _isAnalyzing = false;
          });
          widget.onSpeciesIdentified?.call(speciesName);
        } else {
          setState(() {
            _result = 'Unknown (Max: ${maxScore.toStringAsFixed(1)}%)';
            _isAnalyzing = false;
          });
        }
      } else {
        setState(() {
          _result = 'No output from model';
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint("Inference error: $e");
      setState(() {
        _result = 'Error analyzing image';
        _isAnalyzing = false;
      });
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

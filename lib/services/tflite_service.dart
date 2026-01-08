
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      // Load TFLite model
      final options = InterpreterOptions();
      // Add any options if needed, e.g., threads
      // options.threads = 4;
      
      _interpreter = await Interpreter.fromAsset('assets/models/food_model.tflite', options: options);
      
      // Load labels
      final jsonString = await rootBundle.loadString('assets/models/class_indices.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      // The json is like {"Label": index}, we need a list where index maps to Label
      _labels = List<String>.filled(jsonMap.length, '');
      jsonMap.forEach((key, value) {
        if (value is int && value >= 0 && value < _labels.length) {
          _labels[value] = key;
        }
      });

      _isLoaded = true;
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _isLoaded = false;
    }
  }

  Future<String?> predict(String imagePath) async {
    if (!_isLoaded || _interpreter == null) {
      await loadModel();
      if (!_isLoaded) return null;
    }

    try {
      // 1. Read image file
      final imageData = File(imagePath).readAsBytesSync();
      img.Image? image = img.decodeImage(imageData);

      if (image == null) return null;

      // 2. Preprocessing
      // - Bake orientation (EXIF) - decodeImage usually handles this check, but bakeOrientation assures it
      image = img.bakeOrientation(image);

      // - Center crop to 1:1
      final size = image.width < image.height ? image.width : image.height;
      image = img.copyCrop(
        image, 
        x: (image.width - size) ~/ 2, 
        y: (image.height - size) ~/ 2, 
        width: size, 
        height: size
      );

      // - Resize to 224x224 (Bilinear)
      image = img.copyResize(
        image, 
        width: 224, 
        height: 224, 
        interpolation: img.Interpolation.linear
      );

      // - Convert to float32 and normalize [0, 255] -> [0, 1]
      // Tensor shape: [1, 224, 224, 3]
      var input = List.generate(1, (i) => List.generate(224, (j) => List.generate(224, (k) => List.filled(3, 0.0))));

      // While iterating, pixels in 'image' package are usually int (ABGR or ARGB)
      // We need to extract per channel.
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = image.getPixel(x, y);
          input[0][y][x][0] = pixel.r / 255.0; // R
          input[0][y][x][1] = pixel.g / 255.0; // G
          input[0][y][x][2] = pixel.b / 255.0; // B
        }
      }

      // 3. Inference
      // Output shape depends on the model, usually [1, num_classes] (1 x 12 here)
      var output = List<double>.filled(12, 0).reshape([1, 12]);
      
      _interpreter!.run(input, output);

      // 4. Post-processing (Argmax)
      final outputList = output[0] as List<double>;
      int maxIndex = 0;
      double maxScore = outputList[0];
      
      for (int i = 1; i < outputList.length; i++) {
        if (outputList[i] > maxScore) {
          maxScore = outputList[i];
          maxIndex = i;
        }
      }

      if (maxIndex < _labels.length) {
        return _labels[maxIndex];
      }
      
      return null;

    } catch (e) {
      print('Error during prediction: $e');
      return null;
    }
  }

  // Mapping from model label to UI label if strictly needed, 
  // but json keys seem already user friendly enough: "Bakso", "Cimol atau cilok", etc.
  // We will pass the exact string from json.
}

import 'dart:async';

class TFLiteService {
  bool get isLoaded => true;

  Future<void> loadModel() async {
    print('TFLite Web Stub: Model loading simulated (Native TFLite not supported on Web).');
  }

  Future<String?> predict(String imagePath) async {
    print('TFLite Web Stub: Predicting simulated for $imagePath');
    // Simulate network/processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Return a dummy result that exists in our labels to allow UI testing
    return "Cimol atau cilok"; 
  }
}

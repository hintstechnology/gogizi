// Conditionally export the correct implementation
// If dart.library.html is available (Web), use the Web Stub
// Otherwise (Mobile/Desktop), use the Native implementation
export 'tflite_native.dart' if (dart.library.html) 'tflite_web.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import 'hasil_scan_screen.dart';
import '../../models/scan_result.dart';
import '../../services/tflite_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TFLiteService _tfliteService = TFLiteService();
  XFile? _pickedImage;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    // Preload model
    _tfliteService.loadModel();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _isAnalyzing = true;
        });

        // Run prediction
        String? prediction;
        try {
           prediction = await _tfliteService.predict(image.path);
        } catch (e) {
          print("Prediction error: $e");
        }

        setState(() {
          _isAnalyzing = false;
        });

        // Navigate to result screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HasilScanScreen(
                imagePath: image.path, 
                prediction: prediction
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isAnalyzing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Scan Jajanan'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Info card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hasil scan adalah estimasi',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gunakan untuk referensi edukatif. Untuk diagnosis medis, konsultasikan dengan ahli gizi.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Camera placeholder
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.cardGray,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textLight.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/kamera_rb.png',
                        height: 130,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kameranya Ready Nih!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jepret jajanan lu biar ketahuan gizinya!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text('Ambil Foto'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pilih dari Galeri'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Tips
                Card(
                  margin: const EdgeInsets.all(16),
                  color: AppTheme.cardGray,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppTheme.primaryOrange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tips Scan Terbaik',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Pastikan pencahayaan cukup'),
                        _buildTip('Fokuskan pada makanan/minuman'),
                        _buildTip('Hindari gambar blur atau terlalu gelap'),
                        _buildTip('Ambil foto dari berbagai sudut untuk hasil lebih akurat'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
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
                    CircularProgressIndicator(color: AppTheme.primaryOrange),
                    SizedBox(height: 16),
                    Text("Sedang menganalisis...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppTheme.successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}


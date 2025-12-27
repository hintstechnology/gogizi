import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../models/scan_result.dart';
import '../riwayat/riwayat_screen.dart';
import '../rekomendasi/rekomendasi_screen.dart';

class HasilScanScreen extends StatelessWidget {
  final String imagePath;

  const HasilScanScreen({super.key, required this.imagePath});

  // Generate dummy scan result
  ScanResult _generateDummyResult() {
    // Simulate different results based on random or image analysis
    final labels = [
      'Es Teh Manis',
      'Nasi Goreng',
      'Gado-gado',
      'Bakso',
      'Mie Ayam',
    ];
    final label = labels[DateTime.now().millisecond % labels.length];

    final isSweetDrink = label.toLowerCase().contains('teh') ||
        label.toLowerCase().contains('es') ||
        label.toLowerCase().contains('manis');

    NutritionalInfo nutritionalInfo;
    if (isSweetDrink) {
      nutritionalInfo = NutritionalInfo(
        calories: 120,
        protein: 0,
        carbs: 30,
        fat: 0,
        sugar: 28,
        fiber: 0,
        sodium: 10,
      );
    } else if (label.toLowerCase().contains('gado')) {
      nutritionalInfo = NutritionalInfo(
        calories: 280,
        protein: 15,
        carbs: 30,
        fat: 12,
        sugar: 5,
        fiber: 8,
        sodium: 600,
      );
    } else {
      nutritionalInfo = NutritionalInfo(
        calories: 350,
        protein: 12,
        carbs: 45,
        fat: 15,
        sugar: 3,
        fiber: 2,
        sodium: 800,
      );
    }

    final riskAnalysis = ScanResult.analyzeRisks(nutritionalInfo);
    final alternatives = ScanResult.generateAlternatives(
      label,
      isSweetDrink ? FoodCategory.sweetDrink : FoodCategory.food,
    );

    return ScanResult(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      confidence: 0.88,
      category: isSweetDrink ? FoodCategory.sweetDrink : FoodCategory.food,
      nutritionalInfo: nutritionalInfo,
      scannedAt: DateTime.now(),
      imagePath: imagePath,
      isSweetDrink: isSweetDrink,
      riskAnalysis: riskAnalysis,
      healthierAlternatives: alternatives,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _generateDummyResult();
    final riskColor = result.riskAnalysis!.overallRisk == 'Tinggi'
        ? AppTheme.errorRed
        : result.riskAnalysis!.overallRisk == 'Sedang'
            ? Colors.orange
            : AppTheme.successGreen;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Hasil Scan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanned image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagePath),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 16),

            // Label and confidence
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Label',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.label,
                            style: Theme.of(context).textTheme.headlineMedium,
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
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${(result.confidence * 100).toInt()}%',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Confidence',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category badge
            if (result.isSweetDrink)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningRed, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warningRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Minuman Manis Terdeteksi',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.warningRed,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

            // Nutritional info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Gizi',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildNutrientRow(context, 'Kalori', '${result.nutritionalInfo.calories.toInt()} kcal'),
                    _buildNutrientRow(context, 'Protein', '${result.nutritionalInfo.protein.toInt()} g'),
                    _buildNutrientRow(context, 'Karbohidrat', '${result.nutritionalInfo.carbs.toInt()} g'),
                    _buildNutrientRow(context, 'Lemak', '${result.nutritionalInfo.fat.toInt()} g'),
                    _buildNutrientRow(context, 'Gula', '${result.nutritionalInfo.sugar.toInt()} g'),
                    _buildNutrientRow(context, 'Serat', '${result.nutritionalInfo.fiber.toInt()} g'),
                    _buildNutrientRow(context, 'Natrium', '${result.nutritionalInfo.sodium.toInt()} mg'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Risk analysis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: riskColor),
                        const SizedBox(width: 8),
                        Text(
                          'Analisis Risiko',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            result.riskAnalysis!.overallRisk,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (result.riskAnalysis!.risks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...result.riskAnalysis!.risks.map((risk) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: AppTheme.errorRed,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    risk,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.errorRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    if (result.riskAnalysis!.warnings.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...result.riskAnalysis!.warnings.map((warning) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Healthier alternatives
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, color: AppTheme.successGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Alternatif Lebih Sehat',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...result.healthierAlternatives!.map((alt) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppTheme.successGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alt,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Save to history
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hasil scan disimpan ke riwayat'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Simpan ke Riwayat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RekomendasiScreen()),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Lihat Rekomendasi'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hasil ini adalah estimasi untuk tujuan edukatif. Bukan pengganti konsultasi medis.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}


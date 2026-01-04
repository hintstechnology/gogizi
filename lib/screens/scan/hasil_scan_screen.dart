import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../../theme/app_theme.dart';
import '../../models/scan_result.dart';
import '../rekomendasi/rekomendasi_screen.dart';

class HasilScanScreen extends StatefulWidget {
  final String imagePath;

  const HasilScanScreen({super.key, required this.imagePath});

  @override
  State<HasilScanScreen> createState() => _HasilScanScreenState();
}

class _HasilScanScreenState extends State<HasilScanScreen> {
  // Predefined food list
  final List<String> _foodOptions = [
    'Bakso',
    'Cimol',
    'Seblak',
    'Telur Gulung',
    'Tempura',
    'Batagor',
    'Air',
    'Es Teh',
    'Thai Tea',
    'Minuman botol',
  ];

  String? _selectedFood;
  bool _isConfirmed = false;
  ScanResult? _result;

  @override
  void initState() {
    super.initState();
    // Simulate prediction (default to first or random)
    _selectedFood = _foodOptions[3]; // Default to 'Telur Gulung' for now
  }

  // Generate result based on selected food
  void _generateResult() {
    if (_selectedFood == null) return;

    final label = _selectedFood!;
    final isSweetDrink = label.toLowerCase().contains('teh') ||
        (label.toLowerCase().contains('air') && label != 'Air') || // 'Air' is water
        label.toLowerCase().contains('minuman') ||
        label.toLowerCase().contains('thai');

    NutritionalInfo nutritionalInfo;
    
    // Simple mock data mapping
    switch (label) {
      case 'Bakso':
        nutritionalInfo = NutritionalInfo(calories: 320, protein: 18, carbs: 45, fat: 8, sugar: 2, fiber: 2, sodium: 650);
        break;
      case 'Cimol':
        nutritionalInfo = NutritionalInfo(calories: 250, protein: 2, carbs: 55, fat: 12, sugar: 0, fiber: 1, sodium: 300);
        break;
      case 'Seblak':
        nutritionalInfo = NutritionalInfo(calories: 450, protein: 12, carbs: 50, fat: 22, sugar: 4, fiber: 3, sodium: 900);
        break;
      case 'Telur Gulung':
        nutritionalInfo = NutritionalInfo(calories: 150, protein: 6, carbs: 8, fat: 10, sugar: 0, fiber: 0, sodium: 200);
        break;
      case 'Tempura':
         nutritionalInfo = NutritionalInfo(calories: 200, protein: 8, carbs: 25, fat: 8, sugar: 0, fiber: 0, sodium: 400);
         break;
      case 'Batagor':
         nutritionalInfo = NutritionalInfo(calories: 380, protein: 14, carbs: 35, fat: 20, sugar: 5, fiber: 2, sodium: 550);
         break;
      case 'Air':
         nutritionalInfo = NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0, fiber: 0, sodium: 0);
         break;
      case 'Es Teh':
         nutritionalInfo = NutritionalInfo(calories: 90, protein: 0, carbs: 22, fat: 0, sugar: 22, fiber: 0, sodium: 10);
         break;
      case 'Thai Tea':
         nutritionalInfo = NutritionalInfo(calories: 220, protein: 4, carbs: 35, fat: 8, sugar: 30, fiber: 0, sodium: 40);
         break;
      case 'Minuman botol':
         nutritionalInfo = NutritionalInfo(calories: 140, protein: 0, carbs: 35, fat: 0, sugar: 35, fiber: 0, sodium: 20);
         break;
      default:
        nutritionalInfo = NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0, fiber: 0, sodium: 0);
    }

    RiskAnalysis riskAnalysis = ScanResult.analyzeRisks(nutritionalInfo);
    
    // Custom logic for water
    if (label == 'Air') {
        riskAnalysis = RiskAnalysis(
            risks: [],
            warnings: ['Tetap jaga hidrasi tubuh!'],
            overallRisk: 'Aman',
        );
    }

    final alternatives = ScanResult.generateAlternatives(
      label,
      isSweetDrink ? FoodCategory.sweetDrink : FoodCategory.food,
    );

    setState(() {
      _result = ScanResult(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        confidence: 0.95, // High confidence since user confirmed
        category: isSweetDrink ? FoodCategory.sweetDrink : FoodCategory.food,
        nutritionalInfo: nutritionalInfo,
        scannedAt: DateTime.now(),
        imagePath: widget.imagePath,
        isSweetDrink: isSweetDrink && label != 'Air', // Air is drink but not sweet
        riskAnalysis: riskAnalysis,
        healthierAlternatives: alternatives,
      );
      _isConfirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: Text(_isConfirmed ? 'Hasil Analisis' : 'Konfirmasi Scan'),
      ),
      body: _isConfirmed ? _buildAnalysisView() : _buildConfirmationView(),
    );
  }

  Widget _buildConfirmationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Captured Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb
                ? Image.network(
                    widget.imagePath,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(widget.imagePath),
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Apa yang Kamu makan/minum?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kami mendeteksi objek ini, namun kamu bisa mengubahnya jika salah.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFood,
                        isExpanded: true,
                        hint: const Text('Pilih Nama Makanan/Minuman'),
                        items: _foodOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFood = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _selectedFood != null ? _generateResult : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue, // UB Blue
            ),
            child: const Text('Lanjut Analisis Gizi'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView() {
    final result = _result!;
    final riskColor = result.riskAnalysis!.overallRisk == 'Tinggi'
        ? AppTheme.errorRed
        : result.riskAnalysis!.overallRisk == 'Sedang'
            ? Colors.orange
            : result.riskAnalysis!.overallRisk == 'Aman'
              ? AppTheme.primaryBlue
              : AppTheme.successGreen;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Header Result
             Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(widget.imagePath)
                              : FileImage(File(widget.imagePath)) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.label,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ' ${result.isSweetDrink ? "Minuman" : "Makanan"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category badge if warning needed
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
                    _buildNutrientRow('Kalori', '${result.nutritionalInfo.calories.toInt()} kcal'),
                    _buildNutrientRow('Protein', '${result.nutritionalInfo.protein.toInt()} g'),
                    _buildNutrientRow('Karbohidrat', '${result.nutritionalInfo.carbs.toInt()} g'),
                    _buildNutrientRow('Lemak', '${result.nutritionalInfo.fat.toInt()} g'),
                    _buildNutrientRow('Gula', '${result.nutritionalInfo.sugar.toInt()} g'),
                    _buildNutrientRow('Serat', '${result.nutritionalInfo.fiber.toInt()} g'),
                    _buildNutrientRow('Natrium', '${result.nutritionalInfo.sodium.toInt()} mg'),
                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLightOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Angka di atas adalah estimasi dari resep standar. Kandungan asli bisa beda, tergantung "tangan koki"-nya ya (minyak, gula, garam, dsb)! 😉',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                   ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Healthier alternatives
            if (result.healthierAlternatives != null && result.healthierAlternatives!.isNotEmpty)
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
                    label: const Text('Simpan'),
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
                    label: const Text('Rekomendasi'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
             // Re-scan button (Back to confirm)
            TextButton(
              onPressed: () {
                setState(() {
                  _isConfirmed = false;
                });
              }, 
              child: const Text('Scan Ulang / Ubah Data'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      );
  }

  Widget _buildNutrientRow(String label, String value) {
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

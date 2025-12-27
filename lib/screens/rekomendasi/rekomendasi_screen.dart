import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});

  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen> {
  // Master list of recommendations
  final List<MenuRecommendation> _allRecommendations = [
    MenuRecommendation(
      name: 'Nasi Uduk + Ayam Goreng + Sayur',
      calories: 450,
      protein: 25,
      carbs: 50,
      fat: 15,
      reason: 'Seimbang antara karbohidrat, protein, dan serat. Cocok untuk makan siang.',
      price: 'Rp 15.000',
    ),
    MenuRecommendation(
      name: 'Gado-gado',
      calories: 280,
      protein: 15,
      carbs: 30,
      fat: 12,
      reason: 'Tinggi serat, rendah kalori, kaya vitamin dari sayuran segar.',
      price: 'Rp 12.000',
    ),
    MenuRecommendation(
      name: 'Sate Ayam + Lontong',
      calories: 380,
      protein: 28,
      carbs: 35,
      fat: 12,
      reason: 'Tinggi protein, cocok untuk pemulihan otot setelah aktivitas.',
      price: 'Rp 18.000',
    ),
    MenuRecommendation(
      name: 'Salad Buah + Yogurt',
      calories: 200,
      protein: 8,
      carbs: 35,
      fat: 5,
      reason: 'Rendah kalori, tinggi serat, cocok untuk camilan sehat.',
      price: 'Rp 10.000',
    ),
    MenuRecommendation(
      name: 'Bubur Ayam',
      calories: 320,
      protein: 18,
      carbs: 45,
      fat: 8,
      reason: 'Mudah dicerna, cocok untuk sarapan atau makan malam.',
      price: 'Rp 12.000',
    ),
    MenuRecommendation(
      name: 'Soto Ayam + Nasi',
      calories: 400,
      protein: 22,
      carbs: 45,
      fat: 15,
      reason: 'Kuah hangat menyegarkan, sumber protein dan karbohidrat yang baik.',
      price: 'Rp 15.000',
    ),
    MenuRecommendation(
      name: 'Ketoprak',
      calories: 380,
      protein: 12,
      carbs: 45,
      fat: 14,
      reason: 'Alternatif menu berbasis tahu dan bihun dengan bumbu kacang.',
      price: 'Rp 14.000',
    ),
    MenuRecommendation(
      name: 'Mie Ayam + Pangsit',
      calories: 420,
      protein: 18,
      carbs: 55,
      fat: 12,
      reason: 'Menu populer yang mengenyangkan, dengan topping ayam cincang.',
      price: 'Rp 13.000',
    ),
    MenuRecommendation(
      name: 'Capcay Kuah/Goreng',
      calories: 250,
      protein: 10,
      carbs: 15,
      fat: 12,
      reason: 'Penuh dengan aneka sayuran, kaya serat dan vitamin.',
      price: 'Rp 15.000',
    ),
  ];

  List<MenuRecommendation> _currentRecommendations = [];

  @override
  void initState() {
    super.initState();
    _regenerateRecommendations();
  }

  void _regenerateRecommendations() {
    setState(() {
      final shuffled = List<MenuRecommendation>.from(_allRecommendations)..shuffle();
      _currentRecommendations = shuffled.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Rekomendasi Menu'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _regenerateRecommendations,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Regenerate'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentRecommendations.length,
        itemBuilder: (context, index) {
          final menu = _currentRecommendations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMacroChip('Kal', '${menu.calories}'),
                      const SizedBox(width: 8),
                      _buildMacroChip('P', '${menu.protein}g'),
                      const SizedBox(width: 8),
                      _buildMacroChip('K', '${menu.carbs}g'),
                      const SizedBox(width: 8),
                      _buildMacroChip('L', '${menu.fat}g'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    menu.reason,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estimasi: ${menu.price}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class MenuRecommendation {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String reason;
  final String price;

  MenuRecommendation({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.reason,
    required this.price,
  });
}


import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});

  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen> {
  final List<String> _filters = [
    'Murah',
    'Tinggi Protein',
    'Rendah Gula',
    'Rendah Lemak',
    'Cepat Saji Sehat',
  ];
  final Set<String> _selectedFilters = {};

  final List<MenuRecommendation> _recommendations = [
    MenuRecommendation(
      name: 'Nasi Uduk + Ayam Goreng + Sayur',
      calories: 450,
      protein: 25,
      carbs: 50,
      fat: 15,
      reason: 'Seimbang antara karbohidrat, protein, dan serat. Cocok untuk makan siang.',
      price: 'Rp 15.000',
      isLocal: true,
    ),
    MenuRecommendation(
      name: 'Gado-gado',
      calories: 280,
      protein: 15,
      carbs: 30,
      fat: 12,
      reason: 'Tinggi serat, rendah kalori, kaya vitamin dari sayuran segar.',
      price: 'Rp 12.000',
      isLocal: true,
    ),
    MenuRecommendation(
      name: 'Sate Ayam + Lontong',
      calories: 380,
      protein: 28,
      carbs: 35,
      fat: 12,
      reason: 'Tinggi protein, cocok untuk pemulihan otot setelah aktivitas.',
      price: 'Rp 18.000',
      isLocal: true,
    ),
    MenuRecommendation(
      name: 'Salad Buah + Yogurt',
      calories: 200,
      protein: 8,
      carbs: 35,
      fat: 5,
      reason: 'Rendah kalori, tinggi serat, cocok untuk camilan sehat.',
      price: 'Rp 10.000',
      isLocal: false,
    ),
    MenuRecommendation(
      name: 'Bubur Ayam',
      calories: 320,
      protein: 18,
      carbs: 45,
      fat: 8,
      reason: 'Mudah dicerna, cocok untuk sarapan atau makan malam.',
      price: 'Rp 12.000',
      isLocal: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Rekomendasi Menu'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'AI-Optimized',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilters.contains(filter);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected ? Colors.white : const Color(0xFF8B4513), // Coklat saat tidak aktif, putih saat aktif
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFilters.add(filter);
                          } else {
                            _selectedFilters.remove(filter);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryOrange : const Color(0xFF8B4513).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Recommendations list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final menu = _recommendations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                menu.name,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            if (menu.isLocal)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Lokal',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.primaryOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                          ],
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              menu.price,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // Show alternatives
                                _showAlternatives(context, menu);
                              },
                              icon: const Icon(Icons.restaurant_menu, size: 16),
                              label: const Text('Alternatif'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

  void _showAlternatives(BuildContext context, MenuRecommendation menu) {
    final alternatives = [
      '${menu.name} (versi rendah kalori)',
      'Substitusi dengan porsi lebih kecil',
      'Tambahkan sayuran sebagai pendamping',
      'Pilih versi tanpa gula tambahan',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alternatif Jajanan Lokal',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ...alternatives.map((alt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppTheme.successGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(alt)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
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
  final bool isLocal;

  MenuRecommendation({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.reason,
    required this.price,
    this.isLocal = false,
  });
}


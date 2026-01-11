import 'package:flutter/material.dart';
import 'package:go_gizi/models/food_library_item.dart';
import 'package:go_gizi/services/profile_service.dart';
import 'package:go_gizi/services/recommendation_service.dart';

class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});

  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  final ProfileService _profileService = ProfileService();
  
  Map<String, List<FoodLibraryItem>>? _recommendations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    // Fetch cached/stored
    var recs = await _recommendationService.getRecommendations();
    
    try {
      // If no recommendations exist for today, try to generate automatic
      if (recs == null) {
        final profile = await _profileService.getUserProfile();
        if (profile != null) {
          recs = await _recommendationService.generateDailyRecommendations(profile);
        }
      }
      
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Error handling (e.g. timeout or no profile)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _regenerateRecommendations() async {
    setState(() => _isLoading = true);
    final profile = await _profileService.getUserProfile();
    try {
      if (profile != null) {
         final recs = await _recommendationService.generateDailyRecommendations(profile);
         if (mounted) {
           setState(() {
             _recommendations = recs;
             _isLoading = false;
           });
         }
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Checking if empty or null
    final hasData = _recommendations != null && 
        (_recommendations!['breakfast']?.isNotEmpty ?? false);

    if (!hasData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rekomendasi Makanan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Belum ada rekomendasi. Lengkapi profil Anda.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _regenerateRecommendations,
                child: const Text('Buat Rekomendasi'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rekomendasi Makanan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CA771),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menu Harian Sehat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                          const Text(
                            'Disusun pakai AI sesuai spesifikasi kebutuhan gizimu',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Meals
            _buildMealSection(
              title: 'Makan Pagi',
              items: _recommendations!['breakfast'] ?? [],
              time: '07:00 - 09:00',
            ),
            const SizedBox(height: 24),
            _buildMealSection(
              title: 'Makan Siang',
              items: _recommendations!['lunch'] ?? [],
              time: '12:00 - 13:00',
            ),
            const SizedBox(height: 24),
            _buildMealSection(
              title: 'Makan Malam',
              items: _recommendations!['dinner'] ?? [],
              time: '18:00 - 19:00',
            ),

            const SizedBox(height: 30),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _regenerateRecommendations,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Cari Menu Lain'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CA771),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Disclaimer: Rekomendasi di atas diasumsikan untuk individu sehat.',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection({
    required String title,
    required List<FoodLibraryItem> items,
    required String time,
  }) {
    double totalCal = items.fold(0, (sum, i) => sum + i.calories);
    double totalPro = items.fold(0, (sum, i) => sum + i.protein);
    double totalCarb = items.fold(0, (sum, i) => sum + i.carbs);
    double totalFat = items.fold(0, (sum, i) => sum + i.fat);

    IconData mealIcon;
    Color mealColor;
    if (title.contains('Pagi')) {
       mealIcon = Icons.wb_sunny_outlined;
       mealColor = Colors.orange;
    } else if (title.contains('Siang')) {
       mealIcon = Icons.wb_cloudy_outlined;
       mealColor = Colors.blue;
    } else {
       mealIcon = Icons.nights_stay_outlined;
       mealColor = Colors.indigo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: mealColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(mealIcon, color: mealColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                       Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                     ]
                  )
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Belum ada menu, silakan generate ulang.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...items.map((item) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF4CA771), size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item.name} ${item.portionDesc != null ? "(${item.portionDesc})" : ""}',
                            style: const TextStyle(fontSize: 15, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  )),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Nutrient Grid - Corrected Order
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientInfo('Kalori', '${totalCal.round()}', 'kcal', Colors.orange, Icons.local_fire_department),
                    _buildNutrientInfo('Karbo', '${totalCarb.round()}', 'g', Colors.brown, Icons.bakery_dining),
                    _buildNutrientInfo('Protein', '${totalPro.round()}', 'g', Colors.blue, Icons.fitness_center),
                    _buildNutrientInfo('Lemak', '${totalFat.round()}', 'g', Colors.amber[700]!, Icons.opacity),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, String unit, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// Simple ProductCard widget definition to avoid missing file issues
class ProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String image;
  final Color backgroundColor;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.image,
    this.backgroundColor = const Color(0xFFF8F8F8),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Image.network(
                    image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CA771),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

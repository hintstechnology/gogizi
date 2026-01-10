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
                icon: const Icon(Icons.refresh),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                time,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (items.isEmpty)
            const Text('Menu belum tersedia')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        '${item.name} ${item.portionDesc != null ? "(${item.portionDesc})" : ""}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
            
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          // Nutrition Summary Grid
          Row(
            children: [
              _buildNutrientInfo('Kalori', '${totalCal.round()}', 'kcal', Colors.orange),
              _buildNutrientInfo('Protein', '${totalPro.round()}', 'g', Colors.blue),
              _buildNutrientInfo('Karbo', '${totalCarb.round()}', 'g', Colors.brown),
              _buildNutrientInfo('Lemak', '${totalFat.round()}', 'g', Colors.yellow[800]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: color
                )
              ),
              Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
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

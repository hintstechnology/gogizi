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
                          'Disusun dengan Algoritma Genetika 4 Sehat 5 Sempurna',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${totalCal.toStringAsFixed(0)} kkal',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        const SizedBox(height: 12),
        
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Data menu belum lengkap'),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 160,
                    child: ProductCard(
                      title: '${item.name} ${item.portionDesc != null ? "(${item.portionDesc})" : ""}',
                      price: '${item.calories.round()} kkal',
                      image: 'https://placehold.co/150x150/png?text=Menu', 
                      backgroundColor: const Color(0xFFF5F5F5),
                      onTap: () {
                        // Show details
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
  // Helper moved to keep class structure if needed, but here we just replaced the body build.
  // We need to keep the _buildMacroChip method.

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

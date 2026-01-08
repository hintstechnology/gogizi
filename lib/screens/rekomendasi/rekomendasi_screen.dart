import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/recommendation_service.dart';
import '../../services/profile_service.dart';
import '../../models/food_library_item.dart';

class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});

  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen> {
  Map<String, FoodLibraryItem>? _recommendations;
  bool _isLoading = true;
  final RecommendationService _recommendationService = RecommendationService();
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    try {
      var recs = await _recommendationService.getRecommendations();
      
      // If no recommendations exist for today, try to generate automatic
      if (recs == null) {
        final profile = await _profileService.getUserProfile();
        if (profile != null) {
          await _recommendationService.generateDailyRecommendations(profile);
          recs = await _recommendationService.getRecommendations();
        }
      }
      
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _regenerateRecommendations() async {
    setState(() => _isLoading = true);
    final profile = await _profileService.getUserProfile();
    if (profile != null) {
       await _recommendationService.generateDailyRecommendations(profile);
       await _loadRecommendations();
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final recs = _recommendations;
    final meals = recs != null ? ['breakfast', 'lunch', 'dinner'] : [];

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
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Cari Menu Lain'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                       Image.asset(
                        'assets/images/rekom_rb.png',
                        height: 110,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menu Pilihan Buat Lu',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Biar gak bingung mau makan apa hari ini, Bestie!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rekomendasi ini disusun khusus berdasarkan spesifikasi kebutuhan gizimu, Bestie!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (recs == null)
             SliverFillRemaining(
               child: Center(
                 child: Text('Belum ada rekomendasi. Klik tombol di atas!'),
               ),
             )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final key = meals[index];
                  final menu = recs[key]!;
                  final title = key == 'breakfast' ? 'Sarapan' : (key == 'lunch' ? 'Makan Siang' : 'Makan Malam');
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                title, 
                                style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              menu.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            // Description is optional in FoodLibraryItem, use category or generic text
                            Text(
                              'Menu sehat pilihan untukmu.',
                              style: Theme.of(context).textTheme.bodySmall,
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
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: meals.length,
              ),
            ),


          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.textLight, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Disclaimer: Rekomendasi di atas diasumsikan untuk individu sehat tanpa kondisi medis khusus (seperti diabetes, hipertensi, maag, gangguan ginjal, dll). Jika Anda memiliki kondisi medis tertentu, konsultasikan dengan dokter atau ahli gizi.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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


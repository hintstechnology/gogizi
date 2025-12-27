import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../rekomendasi/rekomendasi_screen.dart';

class DetailKebutuhanScreen extends StatelessWidget {
  const DetailKebutuhanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final needs = UserProfile.dummyProfile.nutritionalNeeds!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Detail Kebutuhan Gizi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary card
            Card(
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
                      'Kebutuhan Gizi Harian Anda',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimasi berdasarkan data diri dan aktivitas',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Calories
            _buildNutrientCard(
              context,
              'Kalori',
              '${needs.calories.toInt()}',
              'kcal',
              Icons.local_fire_department,
              'Energi yang dibutuhkan tubuh untuk aktivitas sehari-hari',
              AppTheme.primaryOrange,
            ),

            // Protein
            _buildNutrientCard(
              context,
              'Protein',
              '${needs.protein.toInt()}',
              'gram',
              Icons.egg,
              'Membangun dan memperbaiki jaringan tubuh, penting untuk otot',
              Colors.blue,
            ),

            // Carbs
            _buildNutrientCard(
              context,
              'Karbohidrat',
              '${needs.carbs.toInt()}',
              'gram',
              Icons.breakfast_dining,
              'Sumber energi utama untuk otak dan aktivitas fisik',
              Colors.orange,
            ),

            // Fat
            _buildNutrientCard(
              context,
              'Lemak',
              '${needs.fat.toInt()}',
              'gram',
              Icons.water_drop,
              'Membantu penyerapan vitamin dan sumber energi cadangan',
              Colors.purple,
            ),

            // Fiber
            _buildNutrientCard(
              context,
              'Serat',
              '${needs.fiber.toInt()}',
              'gram',
              Icons.eco,
              'Menjaga kesehatan pencernaan dan membantu kenyang lebih lama',
              Colors.green,
            ),

            const SizedBox(height: 16),

            // Disclaimer
            Card(
              color: AppTheme.cardGray,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.textLight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Catatan: Hasil ini adalah estimasi berdasarkan formula standar. Bukan pengganti konsultasi dengan ahli gizi atau dokter.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CTA to recommendations
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RekomendasiScreen()),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Lihat Rekomendasi Menu'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    String description,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                      children: [
                        TextSpan(text: value),
                        TextSpan(
                          text: ' $unit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textLight,
                                fontWeight: FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
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


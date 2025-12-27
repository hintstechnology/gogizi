import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../models/challenge_status.dart';
import '../detail_kebutuhan/detail_kebutuhan_screen.dart';
import '../scan/scan_screen.dart';
import '../rekomendasi/rekomendasi_screen.dart';
import '../challenge/challenge_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 17) {
      return 'Selamat Siang';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = UserProfile.dummyProfile;
    final challenge = ChallengeStatus.dummy;
    final needs = profile.nutritionalNeeds!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.textLight,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.name ?? 'Pengguna',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),

              // Nutritional needs summary card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kebutuhan Gizi Harian',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DetailKebutuhanScreen(),
                                ),
                              );
                            },
                            child: const Text('Detail'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutrientItem(
                              context,
                              'Kalori',
                              '${needs.calories.toInt()}',
                              'kcal',
                              Icons.local_fire_department,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildNutrientItem(
                              context,
                              'Protein',
                              '${needs.protein.toInt()}',
                              'g',
                              Icons.egg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutrientItem(
                              context,
                              'Karbohidrat',
                              '${needs.carbs.toInt()}',
                              'g',
                              Icons.breakfast_dining,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildNutrientItem(
                              context,
                              'Lemak',
                              '${needs.fat.toInt()}',
                              'g',
                              Icons.water_drop,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // CTA buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ScanScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Jajanan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RekomendasiScreen()),
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Rekomendasi'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Challenge card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChallengeScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: AppTheme.primaryOrange,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tantangan 7 Hari Sehat',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ChallengeScreen()),
                                );
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.primaryOrange,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Progress: ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${challenge.currentStreak}/7',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress dots
                        Row(
                          children: List.generate(7, (index) {
                            final isCompleted = index < challenge.currentStreak;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppTheme.successGreen
                                    : AppTheme.cardGray,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted
                                      ? AppTheme.successGreen
                                      : AppTheme.textLight.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              challenge.todayScanned
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: challenge.todayScanned
                                  ? AppTheme.successGreen
                                  : AppTheme.textLight,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              challenge.todayScanned
                                  ? 'Sudah scan hari ini'
                                  : 'Belum scan hari ini',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientItem(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


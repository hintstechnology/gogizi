import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../models/challenge_status.dart';
import '../detail_kebutuhan/detail_kebutuhan_screen.dart';
import '../scan/scan_screen.dart';
import '../rekomendasi/rekomendasi_screen.dart';
import '../challenge/challenge_screen.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/profile_service.dart';
import '../profil/profil_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<GlobalKey>? extraKeys;
  const HomeScreen({super.key, this.extraKeys});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _greetKey = GlobalKey();
  final GlobalKey _needsKey = GlobalKey();
  final GlobalKey _scanKey = GlobalKey();
  final GlobalKey _challengeKey = GlobalKey();

  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    // Use a unique key for this tutorial version
    final seen = prefs.getBool('tutorial_seen_v1') ?? false;
    
    if (!seen && mounted) {
      // Start showcase
      List<GlobalKey> keys = [_greetKey, _needsKey, _scanKey, _challengeKey];
      if (widget.extraKeys != null) {
        keys.addAll(widget.extraKeys!);
      }
      
      // Start showcase and wait for it to finish (ShowCaseWidget doesn't have direct await, 
      // but we can assume user interacts. 
      // Ideally we use onFinish callback of ShowCaseWidget, but for now let's just trigger it).
      ShowCaseWidget.of(context).startShowCase(keys);
      // Mark as seen
      await prefs.setBool('tutorial_seen_v1', true);
    } else {
      // If tutorial already seen (or skipped), check profile completeness immediately
       _checkProfileCompletion();
    }
  }

  void _checkProfileCompletion() {
    if (_userProfile != null && !_userProfile!.isComplete) {
       // Add small delay to ensure UI built
       Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Yuk isi data dirimu dulu biar bisa dihitung gizinya!')),
             );
             // Navigate to Profile screen (assuming it's index 3 or via push)
             // Since we are in Home (tab 0), and Profile is likely another tab or screen.
             // If we want to force it, we can push the screen.
             // But better: User MainNavigation logic. 
             // For now, let's push ProfileScreen directly on top.
             Navigator.of(context).push(
               MaterialPageRoute(builder: (_) => const ProfilScreen()),
             ).then((_) => _loadProfile()); // Reload after return
          }
       });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning Bestie! ☀️';
    } else if (hour < 17) {
      return 'Siang Bestie! ☀️';
    } else {
      return 'Malem Bestie! 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show skeleton if loading
    if (_isLoading) {
       return const Scaffold(
         body: Center(child: CircularProgressIndicator()),
       );
    }

    final profile = _userProfile; 
    // If profile is null (fetch error), show basic fallback
    final displayName = profile?.name ?? 'Sobat Sehat';
    
    // Use actual needs or null
    final needs = profile != null && profile.nutritionalNeeds != null 
        ? profile.nutritionalNeeds 
        : (profile != null && profile.isComplete ? NutritionalNeeds.calculate(profile) : null);

    // Challenge: Use empty/zero for now if no backend
    final challenge = ChallengeStatus.empty; 

    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              Showcase(
                key: _greetKey,
                title: 'Halo Bestie!',
                description: 'Ini halaman utama kamu, tempat mantau semua progres sehatmu.',
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/menyapa_rb.png',
                        height: 110,
                      ),
                    ],
                  ),
                ),
              ),

              // Nutritional needs summary card
              Showcase(
                key: _needsKey,
                title: 'Info Gizi Harian',
                description: 'Pantau kebutuhan kalori dan nutrisimu di sini. Klik Detail buat lengkapnya!',
                child: Card(
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
                                if (profile != null && profile.isComplete) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const DetailKebutuhanScreen(),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Eits, isi data profil dulu ya bestie!')),
                                  );
                                  Navigator.of(context).push(
                                     MaterialPageRoute(builder: (_) => const ProfilScreen()),
                                  ).then((_) => _loadProfile());
                                }
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
                                needs != null ? '${needs.calories.toInt()}' : '-',
                                'kcal',
                                Icons.local_fire_department,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNutrientItem(
                                context,
                                'Protein',
                                needs != null ? '${needs.protein.toInt()}' : '-',
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
                                needs != null ? '${needs.carbs.toInt()}' : '-',
                                'g',
                                Icons.breakfast_dining,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNutrientItem(
                                context,
                                'Lemak',
                                needs != null ? '${needs.fat.toInt()}' : '-',
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
              ),

              // CTA buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Showcase(
                        key: _scanKey,
                        title: 'Scan Jajanan',
                        description: 'Penasaran sama gizi jajanan lu? Foto aja di sini!',
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ScanScreen()),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                          label: const Text('Scan Jajanan'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
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
              Showcase(
                key: _challengeKey,
                title: 'Tantangan Mingguan',
                description: 'Ikuti tantangan seru buat jaga pola makan sehatmu!',
                child: Card(
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
                                      ? AppTheme.accentGold
                                      : AppTheme.cardGray,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCompleted
                                        ? AppTheme.accentGold
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
                                    ? AppTheme.accentGold
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

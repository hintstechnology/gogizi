import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/challenge_status.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  ChallengeStatus _challenge = ChallengeStatus(
    startDate: DateTime.now(),
    currentStreak: 0,
    dailyStatus: {
      for (int i = 1; i <= 7; i++)
        i: DayStatus(day: i, completed: false, scanned: false, hasSweetDrink: false)
    },
    achievements: [],
    isActive: false,
    autoResetOnSweetDrink: true,
  );
  bool _autoReset = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChallengeData();
  }

  Future<void> _fetchChallengeData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 7 Day Challenge: Last 6 days + Today
    final startOfWindow = today.subtract(const Duration(days: 6));

    try {
      final response = await supabase
          .from('food_logs')
          .select('eaten_at, is_sweet_drink')
          .eq('user_id', user.id)
          .gte('eaten_at', startOfWindow.toIso8601String());
      
      final logs = (response as List).map((e) => {
        'date': DateTime.parse(e['eaten_at']).toLocal(),
        'isSweetDrink': e['is_sweet_drink'] ?? false,
      }).toList();

      Map<int, DayStatus> dailyStatus = {};
      int completedDays = 0;

      for (int i = 0; i < 7; i++) {
        final targetDate = startOfWindow.add(Duration(days: i));
        final dayLogs = logs.where((log) {
          final logDate = log['date'] as DateTime;
          return logDate.year == targetDate.year && 
                 logDate.month == targetDate.month && 
                 logDate.day == targetDate.day;
        }).toList();

        bool scanned = dayLogs.isNotEmpty;
        bool hasSweetDrink = dayLogs.any((l) => l['isSweetDrink'] == true);
        
        // Logic: Complted if scanned. Sweet drink is just a warning unless auto-reset is on?
        // Let's assume completed if scanned.
        bool completed = scanned;

        dailyStatus[i + 1] = DayStatus(
          day: i + 1,
          completed: completed,
          scanned: scanned,
          hasSweetDrink: hasSweetDrink
        );

        if (completed) completedDays++;
      }

      if (mounted) {
        setState(() {
          _challenge = ChallengeStatus(
            startDate: startOfWindow,
            currentStreak: completedDays,
            dailyStatus: dailyStatus,
            achievements: [], // Would need separate table for achievements
            isActive: true,
            autoResetOnSweetDrink: _autoReset,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching challenge data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startChallenge() {
    _fetchChallengeData();
  }

  void _resetChallenge() {
     _fetchChallengeData();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _challenge.currentStreak / 7;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Tantangan 7 Hari Sehat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/piala_rb.png',
                      height: 130,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Challenge Minggu Ini!',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gas selesaikan misinya biar makin GG!',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Progress card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${_challenge.currentStreak}/7',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 24,
                        backgroundColor: AppTheme.cardGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _challenge.isCompleted
                              ? AppTheme.accentGold
                              : AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Daily checklist
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checklist Harian',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(7, (index) {
                      final day = index + 1;
                      final dayStatus = _challenge.dailyStatus[day]!;
                      final isToday = day ==
                          DateTime.now().difference(_challenge.startDate).inDays + 1;
                      final isPast = day <
                          DateTime.now().difference(_challenge.startDate).inDays + 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: dayStatus.completed
                                    ? AppTheme.accentGold
                                    : isPast
                                        ? AppTheme.cardGray
                                        : AppTheme.primaryOrange.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: dayStatus.completed
                                      ? AppTheme.accentGold
                                      : AppTheme.textLight.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: dayStatus.completed
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : Center(
                                      child: Text(
                                        '$day',
                                        style: TextStyle(
                                          color: dayStatus.completed
                                              ? Colors.white
                                              : AppTheme.textLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hari $day',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (isToday)
                                    Text(
                                      'Hari ini',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.primaryOrange,
                                          ),
                                    ),
                                  if (dayStatus.scanned)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: AppTheme.accentGold,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sudah scan',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  if (dayStatus.hasSweetDrink)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          size: 14,
                                          color: AppTheme.warningRed,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Minuman manis terdeteksi',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.warningRed,
                                              ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Reset otomatis jika minuman manis terdeteksi'),
                      subtitle: const Text(
                        'Streak akan direset jika terdeteksi minuman manis',
                      ),
                      value: _autoReset,
                      onChanged: (value) {
                        setState(() {
                          _autoReset = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Achievements
            if (_challenge.achievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ..._challenge.achievements.map((achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: AppTheme.primaryOrange,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        achievement.name,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        achievement.description,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        DateFormat('d MMM yyyy', 'id_ID')
                                            .format(achievement.unlockedAt),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textLight,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            if (!_challenge.isActive || _challenge.currentStreak == 0)
              ElevatedButton.icon(
                onPressed: _startChallenge,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Tantangan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetChallenge,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Ulangi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Pause challenge
                        setState(() {
                          _challenge = ChallengeStatus(
                            startDate: _challenge.startDate,
                            currentStreak: _challenge.currentStreak,
                            dailyStatus: _challenge.dailyStatus,
                            achievements: _challenge.achievements,
                            isActive: false,
                            autoResetOnSweetDrink: _autoReset,
                          );
                        });
                      },
                      icon: const Icon(Icons.pause),
                      label: const Text('Jeda'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


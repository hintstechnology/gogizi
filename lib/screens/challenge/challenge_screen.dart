import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    dailyStatus: {},
    achievements: [],
    isActive: false,
    autoResetOnSweetDrink: true,
  );
  bool _isLoading = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _fetchChallengeData();
  }

  Future<void> _fetchChallengeData() async {
    if (_prefs == null) return;
    
    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1. Get State from Prefs
    String? startDateStr = _prefs!.getString('challenge_start_date');
    final pausedAtStr = _prefs!.getString('challenge_paused_at');
    final now = DateTime.now();

    // Auto-Start Challenge if not active
    if (startDateStr == null) {
       await _prefs!.setString('challenge_start_date', now.toIso8601String());
       startDateStr = now.toIso8601String();
    }

    DateTime startDate = DateTime.parse(startDateStr);
    final bool isPaused = pausedAtStr != null;
    DateTime? pauseDate = isPaused ? DateTime.parse(pausedAtStr) : null;

    // 2. Query Logs for the Challenge Window
    // We only care about logs AFTER or ON startDate (Day 1)
    // Actually, we iterate 7 days.
    
    final response = await supabase
        .from('food_logs')
        .select('eaten_at, food_name')
        .eq('user_id', user.id)
        .gte('eaten_at', startDate.subtract(const Duration(days: 1)).toIso8601String()); // Buffer

    final logs = (response as List).map((e) {
      final label = (e['food_name'] as String? ?? '').toLowerCase();
      
      // Logic based on specific TFLite classes:
      // Classes: 'Air dan sejenisnya', 'Es teh', 'Minuman botol', 'Thai tea', and foods.
      
      final lower = label.toLowerCase();
      
      final isWater = lower.contains('air dan sejenisnya');
      
      final isSweetDrink = lower.contains('es teh') || 
                           lower.contains('minuman botol') || 
                           lower.contains('thai tea');

      return {
        'date': DateTime.parse(e['eaten_at']).toLocal(),
        'isSweetDrink': isSweetDrink,
        'isWater': isWater, 
      };
    }).toList();

    Map<int, DayStatus> dailyStatus = {};
    int currentStreak = 0;
    bool failed = false;
    String failReason = '';

    // Check 7 Days
    for (int i = 0; i < 7; i++) {
      final targetDate = startDate.add(Duration(days: i));
      
      // If targetDate is in future (relative to Now/PauseDate), break or mark pending
      // If paused, time effectively stops at pauseDate. 
      // But actually, 'startDate' in my logic is the FIXED start.
      // If I paused, I should have shifted startDate? 
      // YES. _resumeChallenge handles shifting.
      // So here, we just compare against Now.
      
      // Determine if this day is "Active/Past"
      // Compare Just Dates
      final targetYMD = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final nowYMD = DateTime(now.year, now.month, now.day);
      
      if (targetYMD.isAfter(nowYMD)) {
         // Future day
         dailyStatus[i + 1] = DayStatus(day: i + 1, completed: false, scanned: false, hasSweetDrink: false);
         continue;
      }
      
      // It's Today or Past. Check Logs.
      final dayLogs = logs.where((log) {
        final d = log['date'] as DateTime;
        // Strict check: Log must be AFTER the challenge start time
        // This prevents immediate failure loops from past logs (even from earlier today)
        if (d.isBefore(startDate)) return false; 
        
        return d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day;
      }).toList();

      final hasSweetDrink = dayLogs.any((l) => l['isSweetDrink'] == true);
      final hasWater = dayLogs.any((l) => l['isWater'] == true); // "Scan Air"

      // Fail Condition 1: Sweet Drink
      if (hasSweetDrink) {
        failed = true;
        failReason = 'Minuman manis terdeteksi pada Hari ${i + 1}!';
        // We still populate status to show the red flag
      }
      
      // Fail Condition 2: Missed Water (Only if Day passed)
      if (targetYMD.isBefore(nowYMD) && !hasWater && !isPaused) {
         // If logged but no water? OR no logs at all?
         // "kalau hari itu dia ga scan air otomatis dia gagal"
         // If it's PAUSED, we assume we don't count passage of time?
         // But "paused" usually implies we are not supposedly checking.
         // Wait. If I paused YESTERDAY. Today is +1 day.
         // If I strictly follow: Pause sets 'pausedAt'. Resume shifts start date.
         // So if I am paused, 'startDate' is effectively OLD. 
         // Logic: If _prefs says IS PAUSED, we typically don't fail for missing days AFTER pause.
         // But 'targetDate' is computed from 'startDate'.
         // If paused, we should stop checking days?
         // But I am iterating 1..7 relative to startDate.
         // If paused, any day AFTER pauseDate should be ignored?
         // Actually, if paused, we assumed the user is NOT participating. 
         // So days pass but we don't check.
         // But my resume logic shifts start date. So targetDate will be correct when resumed.
         // What about 'Before Resume'?
         // If I am paused, startDate is "Day 1". 
         // If I pause on Day 1. Resume a week later. Start Date becomes Today.
         // So in this view, while Paused, 'targetDate' is historically fixed?
         // No. If I pause, I expect the UI to Freeze.
         // So if I pause, I should NOT check failure for "Missing Water" on days that "passed" while paused.
         // But days 'before' pause must be valid.
      }
      
      // Refined Logic:
      // A day is "Failed" if:
      // 1. Has Sweet Drink (Always fail, even if paused? Maybe).
      // 2. Is Past AND No Water.
      
      // Handling Pause for "Missed Water": 
      // If isPaused AND targetDate >= pauseDate -> Ignore "Missed Water".
      // (Because we haven't resumed yet).
      
      bool isMissedWater = targetYMD.isBefore(nowYMD) && !hasWater;
      if (isPaused && pauseDate != null) {
         final pauseYMD = DateTime(pauseDate.year, pauseDate.month, pauseDate.day);
         if (targetYMD.isAtSameMomentAs(pauseYMD) || targetYMD.isAfter(pauseYMD)) {
            isMissedWater = false; // Exempt
         }
      }

      if (isMissedWater) {
        failed = true;
        failReason = 'Gagal scan air pada Hari ${i + 1}!';
      }

      bool completed = hasWater && !hasSweetDrink;
      
      dailyStatus[i + 1] = DayStatus(
        day: i + 1,
        completed: completed,
        scanned: dayLogs.isNotEmpty,
        hasSweetDrink: hasSweetDrink,
      );

      if (completed) currentStreak++;
    }

    // Update State
    if (mounted) {
      if (failed) {
         // Show Popup and Reset
         WidgetsBinding.instance.addPostFrameCallback((_) {
             _showFailDialog(failReason);
             _hardResetChallenge();
         });
      }

      if (currentStreak == 7) {
          final victoryKey = 'challenge_victory_shown_${startDate.toIso8601String()}';
          final alreadyShown = _prefs?.getBool(victoryKey) ?? false;
          
          if (!alreadyShown) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 _showSuccessDialog();
                 _prefs?.setBool(victoryKey, true);
             });
          }
      }

      setState(() {
        _challenge = ChallengeStatus(
          startDate: startDate,
          currentStreak: currentStreak,
          dailyStatus: dailyStatus,
          achievements: [],
          isActive: !isPaused, 
          autoResetOnSweetDrink: true, // enforced
        );
        _isLoading = false;
      });
    }
  }

  Map<int, DayStatus> _generateEmptyDays() {
    return {
      for (int i = 1; i <= 7; i++)
        i: DayStatus(day: i, completed: false, scanned: false, hasSweetDrink: false)
    };
  }

  Future<void> _startChallenge() async {
    final now = DateTime.now();
    await _prefs?.setString('challenge_start_date', now.toIso8601String());
    _fetchChallengeData();
  }

  Future<void> _pauseChallenge() async {
    final now = DateTime.now();
    await _prefs?.setString('challenge_paused_at', now.toIso8601String());
    _fetchChallengeData();
  }

  Future<void> _resumeChallenge() async {
    final startStr = _prefs?.getString('challenge_start_date');
    final pauseStr = _prefs?.getString('challenge_paused_at');
    
    if (startStr != null && pauseStr != null) {
      final start = DateTime.parse(startStr);
      final pause = DateTime.parse(pauseStr);
      final now = DateTime.now();
      
      final diff = now.difference(pause); // Duration paused
      final newStart = start.add(diff);   // Shift start forward
      
      await _prefs?.setString('challenge_start_date', newStart.toIso8601String());
      await _prefs?.remove('challenge_paused_at');
    }
    _fetchChallengeData();
  }

  Future<void> _hardResetChallenge() async {
    await _prefs?.remove('challenge_start_date');
    await _prefs?.remove('challenge_paused_at');
    if (mounted) _fetchChallengeData();
  }
  
  void _showFailDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tantangan Gagal 😢'),
        content: Text('$reason\n\nKamu minum minuman manis atau lupa scan air putih. Tantangan direset ke 0 ya. Semangat mulai lagi!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SELAMAT! 🎉'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.emoji_events, color: Colors.orange, size: 80),
             SizedBox(height: 16),
             Text('Kamu berhasil menyelesaikan Tantangan 7 Hari Bebas Gula!', textAlign: TextAlign.center),
             SizedBox(height: 8),
             Text('Kamu keren banget! Pertahankan gaya hidup sehat ini ya.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               // Optional: Auto reset or keep as "Completed" state
               // User might want to see the 7/7 checkboxes.
            },
            child: const Text('Mantap!'),
          )
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Tantangan?'),
        content: const Text('Yakin mau reset manual?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _hardResetChallenge();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  // Update build method actions
  // ...
  
  @override
  Widget build(BuildContext context) {
    final isPaused = _prefs?.getString('challenge_paused_at') != null;
    final progress = _challenge.currentStreak / 7;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(title: const Text('Tantangan 7 Hari Sehat')),
      body: _isLoading 
         ? const Center(child: CircularProgressIndicator())
         : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Image.asset('assets/images/piala_rb.png', height: 130),
                    const SizedBox(height: 16),
                    Text('Tantangan 7 Hari Bebas Gula', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Container( 
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLightOrange.withOpacity(0.5), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3))
                      ),
                      child: Column(
                        children: [
                           const Text('🎯 Cara Menyelesaikan Misi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           const SizedBox(height: 8),
                           const Text('👉 Scan minuman TIDAK MANIS (Air Putih) setiap hari.', textAlign: TextAlign.center),
                           const SizedBox(height: 4),
                           const Text('👉 Lakukan selama 7 hari berturut-turut.', textAlign: TextAlign.center),
                           const SizedBox(height: 8),
                           Text('⚠️ Awas! Jika ketahuan scan minuman manis (Es Teh/Boba/dll) atau lupa scan, progress reset ke 0!', 
                             textAlign: TextAlign.center, 
                             style: TextStyle(color: AppTheme.warningRed, fontWeight: FontWeight.bold, fontSize: 12)
                           ),
                        ],  
                      )
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress
            Card(
               child: Padding(
                 padding: const EdgeInsets.all(20),
                 child: Column(children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       Text('${_challenge.currentStreak}/7', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
                     ]
                   ),
                   const SizedBox(height: 10),
                   ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 16, color: AppTheme.primaryOrange, backgroundColor: AppTheme.cardGray))
                 ]),
               )
            ),
            const SizedBox(height: 16),

            // Checklist
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Checklist Harian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...List.generate(7, (index) {
                      final day = index + 1;
                      final status = _challenge.dailyStatus[day]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                             Icon(
                               status.completed ? Icons.check_circle : (status.hasSweetDrink ? Icons.cancel : Icons.circle_outlined),
                               color: status.completed ? Colors.green : (status.hasSweetDrink ? Colors.red : Colors.grey),
                               size: 32,
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hari $day', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (status.completed) const Text('Berhasil (Air Putih)', style: TextStyle(color: Colors.green, fontSize: 12)),
                                  if (status.hasSweetDrink) const Text('Gagal (Minuman Manis)', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  if (!status.completed && !status.hasSweetDrink) const Text('Belum selesai', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              )
                             )
                          ],
                        ),
                      );
                    })
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            if (!_challenge.isActive && _prefs?.getString('challenge_start_date') == null)
              ElevatedButton.icon(
                onPressed: _startChallenge,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Tantangan'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              )
            else ...[
               Row(
                 children: [
                   Expanded(
                     child: OutlinedButton.icon(
                       onPressed: _confirmReset,
                       icon: const Icon(Icons.restart_alt),
                       label: const Text('Ulangi'),
                     )
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: ElevatedButton.icon(
                       onPressed: isPaused ? _resumeChallenge : _pauseChallenge,
                       icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                       label: Text(isPaused ? 'Lanjut' : 'Jeda'),
                     )
                   )
                 ],
               )
            ]
          ],
        ),
      ),
    );
  }
}


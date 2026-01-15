import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_status.dart';

class ChallengeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ChallengeStatus> getChallengeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return ChallengeStatus.empty;
    }

    // 1. Get State from Prefs
    String? startDateStr = prefs.getString('challenge_start_date');
    final pausedAtStr = prefs.getString('challenge_paused_at');
    final now = DateTime.now();

    // Auto-Start Challenge if not active (Logic consistent with ChallengeScreen)
    if (startDateStr == null) {
       await prefs.setString('challenge_start_date', now.toIso8601String());
       startDateStr = now.toIso8601String();
    }

    DateTime startDate = DateTime.parse(startDateStr);
    final bool isPaused = pausedAtStr != null;
    DateTime? pauseDate = isPaused ? DateTime.parse(pausedAtStr) : null;

    // 2. Query Logs for the Challenge Window
    // We only care about logs AFTER or ON startDate (Day 1)
    // Actually, we iterate 7 days.
    
    final response = await _supabase
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
                           lower.contains('thai tea'); // Removed 'minuman botol' to prevent water bottle false positives

      return {
        'date': DateTime.parse(e['eaten_at']).toLocal(),
        'isSweetDrink': isSweetDrink,
        'isWater': isWater, 
      };
    }).toList();

    Map<int, DayStatus> dailyStatus = {};
    int currentStreak = 0;
    
    // Check 7 Days
    for (int i = 0; i < 7; i++) {
      final targetDate = startDate.add(Duration(days: i));
      
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
      final dayCandidateLogs = logs.where((log) {
        final d = log['date'] as DateTime;
        return d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day;
      }).toList();

      bool hasSweetDrink = false;
      bool hasWater = false;

      for (final log in dayCandidateLogs) {
          final d = log['date'] as DateTime;
          // Strict validity: Log must be AFTER the challenge start time
          final isStrictlyAfterStart = !d.isBefore(startDate);
          
          if (log['isSweetDrink'] == true) {
             // Sweet Drink MUST be strictly after start to count as Failure (prevents loops)
             if (isStrictlyAfterStart) hasSweetDrink = true;
          }
          
          if (log['isWater'] == true) {
             // Water counts even if before start time (as long as it's the same day),
             // so user doesn't lose credit for a scan if app restarts/resets later that day.
             hasWater = true;
          }
      }

      // Logic for DayStatus
      // Fail conditions are implicit in 'hasSweetDrink' (User sees red)
      // or !hasWater if day passed.

      bool completed = hasWater && !hasSweetDrink;
      
      // Check Missed Water logic
      // Fail Condition 2: Missed Water (Only if Day passed)
      // Logic: targetYMD < nowYMD
      
      // Handling Pause for "Missed Water"
      bool isMissedWater = targetYMD.isBefore(nowYMD) && !hasWater;
      if (isPaused && pauseDate != null) {
          final pauseYMD = DateTime(pauseDate.year, pauseDate.month, pauseDate.day);
          if (targetYMD.isAtSameMomentAs(pauseYMD) || targetYMD.isAfter(pauseYMD)) {
             isMissedWater = false; // Exempt from missing check if paused
             // It means day is effectively "frozen" or "skipped"
          }
      }

      // If missed water, completed is false.
      if (isMissedWater) completed = false;

      dailyStatus[i + 1] = DayStatus(
        day: i + 1,
        completed: completed,
        scanned: dayCandidateLogs.isNotEmpty,
        hasSweetDrink: hasSweetDrink,
      );

      if (completed) currentStreak++;
    }

    // Determine Today's Status for specific fields
    final todayStatus = dailyStatus.values.firstWhere(
      (s) => s.day == (now.difference(startDate).inDays + 1).clamp(1, 7),
      orElse: () => DayStatus(day: 1, completed: false, scanned: false, hasSweetDrink: false)
    );

    return ChallengeStatus(
      startDate: startDate,
      currentStreak: currentStreak,
      dailyStatus: dailyStatus,
      achievements: [], // can calculate achievements here
      isActive: true, // Auto-started so technically active unless completed or failed state logic handled elsewhere
      todayScanned: todayStatus.scanned,
      todayHasSweetDrink: todayStatus.hasSweetDrink,
    );
  }

  Future<void> startChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('challenge_start_date', DateTime.now().toIso8601String());
    await prefs.remove('challenge_paused_at');
  }

  Future<void> resetChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('challenge_start_date');
    await prefs.remove('challenge_paused_at');
  }
}

class ChallengeStatus {
  final String? id;
  final DateTime startDate;
  final int currentStreak; // 0-7
  final Map<int, DayStatus> dailyStatus; // day 1-7
  final List<Achievement> achievements;
  final bool isActive;
  final bool autoResetOnSweetDrink;
  final DateTime? lastScanDate;
  final bool todayScanned;
  final bool todayHasSweetDrink;

  ChallengeStatus({
    this.id,
    required this.startDate,
    required this.currentStreak,
    required this.dailyStatus,
    required this.achievements,
    this.isActive = true,
    this.autoResetOnSweetDrink = true,
    this.lastScanDate,
    this.todayScanned = false,
    this.todayHasSweetDrink = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'currentStreak': currentStreak,
      'dailyStatus': dailyStatus.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'isActive': isActive,
      'autoResetOnSweetDrink': autoResetOnSweetDrink,
      'lastScanDate': lastScanDate?.toIso8601String(),
      'todayScanned': todayScanned,
      'todayHasSweetDrink': todayHasSweetDrink,
    };
  }

  factory ChallengeStatus.fromJson(Map<String, dynamic> json) {
    return ChallengeStatus(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      currentStreak: json['currentStreak'] ?? 0,
      dailyStatus: (json['dailyStatus'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              int.parse(key),
              DayStatus.fromJson(value),
            ),
          ) ??
          {},
      achievements: (json['achievements'] as List?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
      autoResetOnSweetDrink: json['autoResetOnSweetDrink'] ?? true,
      lastScanDate: json['lastScanDate'] != null
          ? DateTime.parse(json['lastScanDate'])
          : null,
      todayScanned: json['todayScanned'] ?? false,
      todayHasSweetDrink: json['todayHasSweetDrink'] ?? false,
    );
  }

  // Check if challenge is completed
  bool get isCompleted => currentStreak >= 7;

  // Get progress percentage
  double get progressPercentage => currentStreak / 7;

  // Dummy data
  static ChallengeStatus get dummy {
    final now = DateTime.now();
    return ChallengeStatus(
      id: 'challenge_001',
      startDate: now.subtract(const Duration(days: 2)),
      currentStreak: 2,
      dailyStatus: {
        1: DayStatus(day: 1, completed: true, scanned: true, hasSweetDrink: false),
        2: DayStatus(day: 2, completed: true, scanned: true, hasSweetDrink: false),
        3: DayStatus(day: 3, completed: false, scanned: false, hasSweetDrink: false),
        4: DayStatus(day: 4, completed: false, scanned: false, hasSweetDrink: false),
        5: DayStatus(day: 5, completed: false, scanned: false, hasSweetDrink: false),
        6: DayStatus(day: 6, completed: false, scanned: false, hasSweetDrink: false),
        7: DayStatus(day: 7, completed: false, scanned: false, hasSweetDrink: false),
      },
      achievements: [
        Achievement(
          id: 'ach_001',
          name: 'Hari Pertama',
          description: 'Selesaikan hari pertama tanpa minuman manis',
          unlockedAt: now.subtract(const Duration(days: 2)),
        ),
        Achievement(
          id: 'ach_002',
          name: 'Dua Hari Berturut-turut',
          description: 'Selesaikan 2 hari berturut-turut',
          unlockedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      isActive: true,
      autoResetOnSweetDrink: true,
      lastScanDate: now.subtract(const Duration(days: 1)),
      todayScanned: false,
      todayHasSweetDrink: false,
    );
  }

  static ChallengeStatus get empty {
    return ChallengeStatus(
      startDate: DateTime.now(),
      currentStreak: 0,
      dailyStatus: {
        1: DayStatus(day: 1, completed: false, scanned: false, hasSweetDrink: false),
        2: DayStatus(day: 2, completed: false, scanned: false, hasSweetDrink: false),
        3: DayStatus(day: 3, completed: false, scanned: false, hasSweetDrink: false),
        4: DayStatus(day: 4, completed: false, scanned: false, hasSweetDrink: false),
        5: DayStatus(day: 5, completed: false, scanned: false, hasSweetDrink: false),
        6: DayStatus(day: 6, completed: false, scanned: false, hasSweetDrink: false),
        7: DayStatus(day: 7, completed: false, scanned: false, hasSweetDrink: false),
      },
      achievements: [],
      isActive: false,
    );
  }
}

class DayStatus {
  final int day;
  final bool completed;
  final bool scanned;
  final bool hasSweetDrink;

  DayStatus({
    required this.day,
    required this.completed,
    required this.scanned,
    required this.hasSweetDrink,
  });

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'completed': completed,
      'scanned': scanned,
      'hasSweetDrink': hasSweetDrink,
    };
  }

  factory DayStatus.fromJson(Map<String, dynamic> json) {
    return DayStatus(
      day: json['day'],
      completed: json['completed'] ?? false,
      scanned: json['scanned'] ?? false,
      hasSweetDrink: json['hasSweetDrink'] ?? false,
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final DateTime unlockedAt;
  final String? icon;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockedAt,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unlockedAt': unlockedAt.toIso8601String(),
      'icon': icon,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      unlockedAt: DateTime.parse(json['unlockedAt']),
      icon: json['icon'],
    );
  }
}


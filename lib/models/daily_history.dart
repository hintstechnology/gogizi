import 'scan_result.dart';

class DailyHistory {
  final String? id;
  final DateTime date;
  final List<ScanResult> scanResults;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalSugar;
  final int sweetDrinkCount;

  DailyHistory({
    this.id,
    required this.date,
    required this.scanResults,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalSugar,
    required this.sweetDrinkCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'scanResults': scanResults.map((r) => r.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalSugar': totalSugar,
      'sweetDrinkCount': sweetDrinkCount,
    };
  }

  factory DailyHistory.fromJson(Map<String, dynamic> json) {
    return DailyHistory(
      id: json['id'],
      date: DateTime.parse(json['date']),
      scanResults: (json['scanResults'] as List?)
              ?.map((r) => ScanResult.fromJson(r))
              .toList() ??
          [],
      totalCalories: json['totalCalories']?.toDouble() ?? 0.0,
      totalProtein: json['totalProtein']?.toDouble() ?? 0.0,
      totalCarbs: json['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: json['totalFat']?.toDouble() ?? 0.0,
      totalSugar: json['totalSugar']?.toDouble() ?? 0.0,
      sweetDrinkCount: json['sweetDrinkCount'] ?? 0,
    );
  }

  // Calculate totals from scan results
  static DailyHistory fromScanResults(DateTime date, List<ScanResult> results) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalSugar = 0;
    int sweetDrinkCount = 0;

    for (var result in results) {
      totalCalories += result.nutritionalInfo.calories;
      totalProtein += result.nutritionalInfo.protein;
      totalCarbs += result.nutritionalInfo.carbs;
      totalFat += result.nutritionalInfo.fat;
      totalSugar += result.nutritionalInfo.sugar;
      if (result.isSweetDrink) {
        sweetDrinkCount++;
      }
    }

    return DailyHistory(
      date: date,
      scanResults: results,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalSugar: totalSugar,
      sweetDrinkCount: sweetDrinkCount,
    );
  }

  // Dummy data
  static List<DailyHistory> get dummyHistory {
    final now = DateTime.now();
    return [
      DailyHistory(
        id: 'hist_001',
        date: now.subtract(const Duration(days: 2)),
        scanResults: [
          ScanResult(
            id: 'scan_001',
            label: 'Nasi Goreng',
            confidence: 0.92,
            category: FoodCategory.food,
            nutritionalInfo: NutritionalInfo(
              calories: 350,
              protein: 12,
              carbs: 45,
              fat: 15,
              sugar: 3,
              fiber: 2,
              sodium: 800,
            ),
            scannedAt: now.subtract(const Duration(days: 2, hours: 12)),
            isSweetDrink: false,
          ),
          ScanResult(
            id: 'scan_002',
            label: 'Es Teh Manis',
            confidence: 0.88,
            category: FoodCategory.sweetDrink,
            nutritionalInfo: NutritionalInfo(
              calories: 120,
              protein: 0,
              carbs: 30,
              fat: 0,
              sugar: 28,
              fiber: 0,
              sodium: 10,
            ),
            scannedAt: now.subtract(const Duration(days: 2, hours: 13)),
            isSweetDrink: true,
          ),
        ],
        totalCalories: 470,
        totalProtein: 12,
        totalCarbs: 75,
        totalFat: 15,
        totalSugar: 31,
        sweetDrinkCount: 1,
      ),
      DailyHistory(
        id: 'hist_002',
        date: now.subtract(const Duration(days: 1)),
        scanResults: [
          ScanResult(
            id: 'scan_003',
            label: 'Gado-gado',
            confidence: 0.95,
            category: FoodCategory.food,
            nutritionalInfo: NutritionalInfo(
              calories: 280,
              protein: 15,
              carbs: 30,
              fat: 12,
              sugar: 5,
              fiber: 8,
              sodium: 600,
            ),
            scannedAt: now.subtract(const Duration(days: 1, hours: 12)),
            isSweetDrink: false,
          ),
          ScanResult(
            id: 'scan_004',
            label: 'Air Putih',
            confidence: 0.99,
            category: FoodCategory.drink,
            nutritionalInfo: NutritionalInfo(
              calories: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              sugar: 0,
              fiber: 0,
              sodium: 0,
            ),
            scannedAt: now.subtract(const Duration(days: 1, hours: 13)),
            isSweetDrink: false,
          ),
        ],
        totalCalories: 280,
        totalProtein: 15,
        totalCarbs: 30,
        totalFat: 12,
        totalSugar: 5,
        sweetDrinkCount: 0,
      ),
    ];
  }
}


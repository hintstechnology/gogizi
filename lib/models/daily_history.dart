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
    // Gunakan tanggal tetap untuk demo sesuai permintaan user
    // Asumsi tahun adalah tahun saat ini atau tahun depan jika bulan sudah lewat
    final year = now.year; 
    
    // 25 Desember - Bakso
    final date1 = DateTime(year, 12, 25);
    // 26 Desember - Seblak
    final date2 = DateTime(year, 12, 26);

    return [
      DailyHistory(
        id: 'hist_001',
        date: date1,
        scanResults: [
          ScanResult(
            id: 'scan_001',
            label: 'Bakso',
            confidence: 0.95,
            category: FoodCategory.food,
            nutritionalInfo: NutritionalInfo(
              calories: 320,
              protein: 18,
              carbs: 40,
              fat: 10,
              sugar: 2,
              fiber: 1,
              sodium: 900,
            ),
            scannedAt: DateTime(year, 12, 25, 12, 30),
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
            scannedAt: DateTime(year, 12, 25, 13, 00),
            isSweetDrink: true,
          ),
        ],
        totalCalories: 440,
        totalProtein: 18,
        totalCarbs: 70,
        totalFat: 10,
        totalSugar: 30,
        sweetDrinkCount: 1,
      ),
      DailyHistory(
        id: 'hist_002',
        date: date2,
        scanResults: [
          ScanResult(
            id: 'scan_003',
            label: 'Seblak',
            confidence: 0.90,
            category: FoodCategory.food,
            nutritionalInfo: NutritionalInfo(
              calories: 450,
              protein: 8,
              carbs: 60,
              fat: 20,
              sugar: 4,
              fiber: 2,
              sodium: 1200,
            ),
            scannedAt: DateTime(year, 12, 26, 17, 15),
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
            scannedAt: DateTime(year, 12, 26, 18, 00),
            isSweetDrink: false,
          ),
        ],
        totalCalories: 450,
        totalProtein: 8,
        totalCarbs: 60,
        totalFat: 20,
        totalSugar: 4,
        sweetDrinkCount: 0,
      ),
    ];
  }
}


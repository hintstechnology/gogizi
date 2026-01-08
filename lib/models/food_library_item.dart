class FoodLibraryItem {
  final int id;
  final String name;
  final String? aiClassLabel;
  final String? portionDesc;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodiumMg;
  final double? estimatedPrice;
  final int? healthScore;
  final List<String> warnings;

  FoodLibraryItem({
    required this.id,
    required this.name,
    this.aiClassLabel,
    this.portionDesc,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodiumMg,
    this.estimatedPrice,
    this.healthScore,
    this.warnings = const [],
  });

  // Factory constructor untuk mapping dari JSON (Supabase) ke Dart Object
  factory FoodLibraryItem.fromJson(Map<String, dynamic> json) {
    return FoodLibraryItem(
      id: json['id'],
      name: json['name'],
      aiClassLabel: json['ai_class_label'],
      portionDesc: json['portion_desc'],
      // Menggunakan num.toDouble() agar aman jika data dari DB berupa int atau float
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
      healthScore: json['health_score'],
      // Mapping Array text[] dari Postgres ke List<String> Dart
      warnings: matchesToJsonList(json['warnings']),
    );
  }

  static List<String> matchesToJsonList(dynamic jsonVal) {
    if (jsonVal == null) return [];
    if (jsonVal is List) return jsonVal.map((e) => e.toString()).toList();
    return [];
  }
}

enum FoodCategory { food, drink, sweetDrink }

class ScanResult {
  final String? id;
  final String label;
  final double confidence; // 0.0 - 1.0
  final FoodCategory category;
  final NutritionalInfo nutritionalInfo;
  final DateTime scannedAt;
  final String? imagePath;
  final bool isSweetDrink;
  final RiskAnalysis? riskAnalysis;
  final List<String>? healthierAlternatives;

  ScanResult({
    this.id,
    required this.label,
    required this.confidence,
    required this.category,
    required this.nutritionalInfo,
    required this.scannedAt,
    this.imagePath,
    this.isSweetDrink = false,
    this.riskAnalysis,
    this.healthierAlternatives,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'category': category.toString().split('.').last,
      'nutritionalInfo': nutritionalInfo.toJson(),
      'scannedAt': scannedAt.toIso8601String(),
      'imagePath': imagePath,
      'isSweetDrink': isSweetDrink,
      'riskAnalysis': riskAnalysis?.toJson(),
      'healthierAlternatives': healthierAlternatives,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      label: json['label'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      category: FoodCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => FoodCategory.food,
      ),
      nutritionalInfo: NutritionalInfo.fromJson(json['nutritionalInfo']),
      scannedAt: DateTime.parse(json['scannedAt']),
      imagePath: json['imagePath'],
      isSweetDrink: json['isSweetDrink'] ?? false,
      riskAnalysis: json['riskAnalysis'] != null
          ? RiskAnalysis.fromJson(json['riskAnalysis'])
          : null,
      healthierAlternatives: json['healthierAlternatives'] != null
          ? List<String>.from(json['healthierAlternatives'])
          : null,
    );
  }

  // Analyze risks based on nutritional info
  static RiskAnalysis analyzeRisks(NutritionalInfo info) {
    List<String> risks = [];
    List<String> warnings = [];

    // Sugar analysis
    if (info.sugar > 25) {
      risks.add('Kadar gula tinggi');
      warnings.add('Konsumsi berlebihan dapat meningkatkan risiko diabetes tipe 2');
    } else if (info.sugar > 15) {
      warnings.add('Kandungan gula sedang-tinggi, batasi konsumsi');
    }

    // Fat analysis
    if (info.fat > 20) {
      warnings.add('Kandungan lemak tinggi, perhatikan asupan harian');
    }

    // Calorie analysis
    if (info.calories > 500) {
      warnings.add('Kalori tinggi, pertimbangkan untuk dibagi atau dikurangi');
    }

    // Obesity risk
    if (info.calories > 400 && info.sugar > 20) {
      risks.add('Risiko obesitas');
      warnings.add('Kombinasi kalori dan gula tinggi dapat berkontribusi pada kenaikan berat badan');
    }

    // Diabetes risk
    if (info.sugar > 30) {
      risks.add('Risiko diabetes');
      warnings.add('Kadar gula sangat tinggi, hindari konsumsi rutin');
    }

    // Kidney risk (for high sodium)
    if (info.sodium > 500) {
      risks.add('Risiko gangguan ginjal');
      warnings.add('Kandungan natrium tinggi dapat membebani fungsi ginjal');
    }

    return RiskAnalysis(
      risks: risks,
      warnings: warnings,
      overallRisk: risks.isEmpty ? 'Rendah' : risks.length == 1 ? 'Sedang' : 'Tinggi',
    );
  }

  // Generate healthier alternatives
  static List<String> generateAlternatives(String label, FoodCategory category) {
    if (category == FoodCategory.sweetDrink || category == FoodCategory.drink) {
      return [
        'Air putih',
        'Jus buah tanpa gula',
        'Teh tawar',
        'Infused water',
        'Susu rendah gula',
      ];
    }

    // Food alternatives based on common unhealthy snacks
    if (label.toLowerCase().contains('goreng') ||
        label.toLowerCase().contains('fried')) {
      return [
        'Salad buah',
        'Kacang rebus',
        'Buah segar',
        'Yogurt rendah lemak',
        'Sandwich gandum',
      ];
    }

    return [
      'Buah segar',
      'Kacang-kacangan',
      'Yogurt',
      'Oatmeal',
      'Salad sayur',
    ];
  }
}

class NutritionalInfo {
  final double calories; // kcal
  final double protein; // gram
  final double carbs; // gram
  final double fat; // gram
  final double sugar; // gram
  final double fiber; // gram
  final double sodium; // mg

  NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.sodium,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'sodium': sodium,
    };
  }

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    return NutritionalInfo(
      calories: json['calories']?.toDouble() ?? 0.0,
      protein: json['protein']?.toDouble() ?? 0.0,
      carbs: json['carbs']?.toDouble() ?? 0.0,
      fat: json['fat']?.toDouble() ?? 0.0,
      sugar: json['sugar']?.toDouble() ?? 0.0,
      fiber: json['fiber']?.toDouble() ?? 0.0,
      sodium: json['sodium']?.toDouble() ?? 0.0,
    );
  }
}

class RiskAnalysis {
  final List<String> risks;
  final List<String> warnings;
  final String overallRisk; // Rendah, Sedang, Tinggi

  RiskAnalysis({
    required this.risks,
    required this.warnings,
    required this.overallRisk,
  });

  Map<String, dynamic> toJson() {
    return {
      'risks': risks,
      'warnings': warnings,
      'overallRisk': overallRisk,
    };
  }

  factory RiskAnalysis.fromJson(Map<String, dynamic> json) {
    return RiskAnalysis(
      risks: List<String>.from(json['risks'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      overallRisk: json['overallRisk'] ?? 'Rendah',
    );
  }
}


enum Gender { male, female }
enum ActivityLevel { low, medium, high }

class UserProfile {
  final String? id;
  final String? email;
  final String? phoneNumber;
  final String? name;
  final DateTime? birthDate; // Replaces age
  final Gender? gender;
  final double? height; // cm
  final double? weight; // kg

  // Helper getter for Age
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
  final int? stressLevel; // 1-5
  final ActivityLevel? activityLevel;
  final NutritionalNeeds? nutritionalNeeds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    this.email,
    this.phoneNumber,
    this.name,
    this.birthDate,
    this.gender,
    this.height,
    this.weight,
    this.stressLevel,
    this.activityLevel,
    this.nutritionalNeeds,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'full_name': name,
      'birth_date': birthDate?.toIso8601String().split('T')[0], // Save as YYYY-MM-DD
      'gender': gender?.toString().split('.').last,
      'height_cm': height,
      'weight_kg': weight,
      'stressLevel': stressLevel,
      'activity_level': activityLevel?.toString().split('.').last,
      'nutritionalNeeds': nutritionalNeeds?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      // Parse birth_date preferably, or fallback to age approximation if needed (handled in service now)
      birthDate: json['birthDate'] != null ? 
        (json['birthDate'] is DateTime ? json['birthDate'] : DateTime.tryParse(json['birthDate'].toString())) 
        : null,
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.toString().split('.').last == json['gender'],
              orElse: () => Gender.male,
            )
          : null,
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      stressLevel: json['stressLevel'],
      activityLevel: json['activityLevel'] != null
          ? ActivityLevel.values.firstWhere(
              (e) => e.toString().split('.').last == json['activityLevel'],
              orElse: () => ActivityLevel.medium,
            )
          : null,
      nutritionalNeeds: json['nutritionalNeeds'] != null
          ? NutritionalNeeds.fromJson(json['nutritionalNeeds'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Check if profile has all necessary data for standard usage
  bool get isComplete {
    return age != null &&
           height != null &&
           weight != null &&
           activityLevel != null &&
           gender != null;
  }

  // Dummy data
  static UserProfile get dummyProfile {
    return UserProfile(
      id: 'user_001',
      email: 'anakmuda@example.com',
      phoneNumber: '081234567890',
      name: 'Anak Muda Sehat',
      birthDate: DateTime(2000, 1, 1),
      gender: Gender.male,
      height: 170.0,
      weight: 65.0,
      stressLevel: 3,
      activityLevel: ActivityLevel.medium,
      nutritionalNeeds: NutritionalNeeds.dummy,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }
}

class NutritionalNeeds {
  final double calories; // kcal
  final double protein; // gram
  final double carbs; // gram
  final double fat; // gram
  final double fiber; // gram

  NutritionalNeeds({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  factory NutritionalNeeds.fromJson(Map<String, dynamic> json) {
    return NutritionalNeeds(
      calories: json['calories']?.toDouble() ?? 0.0,
      protein: json['protein']?.toDouble() ?? 0.0,
      carbs: json['carbs']?.toDouble() ?? 0.0,
      fat: json['fat']?.toDouble() ?? 0.0,
      fiber: json['fiber']?.toDouble() ?? 0.0,
    );
  }

  // Calculate nutritional needs based on user profile
  static NutritionalNeeds calculate(UserProfile profile) {
    if (profile.age == null ||
        profile.gender == null ||
        profile.height == null ||
        profile.weight == null ||
        profile.activityLevel == null) {
      return dummy;
    }

    // BMR calculation using Mifflin-St Jeor Equation
    double bmr;
    if (profile.gender == Gender.male) {
      bmr = 10 * profile.weight! + 6.25 * profile.height! - 5 * profile.age! + 5;
    } else {
      bmr = 10 * profile.weight! + 6.25 * profile.height! - 5 * profile.age! - 161;
    }

    // Activity multiplier
    double activityMultiplier;
    switch (profile.activityLevel!) {
      case ActivityLevel.low:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.medium:
        activityMultiplier = 1.55;
        break;
      case ActivityLevel.high:
        activityMultiplier = 1.725;
        break;
    }

    // Stress adjustment (add 5-10% for stress)
    double stressMultiplier = 1.0 + (profile.stressLevel ?? 3) * 0.02;

    double calories = bmr * activityMultiplier * stressMultiplier;

    // Macronutrient distribution (for students: 30% protein, 45% carbs, 25% fat)
    double protein = (calories * 0.30) / 4; // 4 kcal per gram
    double carbs = (calories * 0.45) / 4; // 4 kcal per gram
    double fat = (calories * 0.25) / 9; // 9 kcal per gram
    double fiber = calories / 100; // Rough estimate: 1g per 100 kcal

    return NutritionalNeeds(
      calories: calories.roundToDouble(),
      protein: protein.roundToDouble(),
      carbs: carbs.roundToDouble(),
      fat: fat.roundToDouble(),
      fiber: fiber.roundToDouble(),
    );
  }

  static NutritionalNeeds get dummy {
    return NutritionalNeeds(
      calories: 2200.0,
      protein: 165.0,
      carbs: 247.5,
      fat: 61.0,
      fiber: 22.0,
    );
  }
}


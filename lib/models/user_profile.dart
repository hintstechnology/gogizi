enum Gender { male, female }
enum ActivityLevel { low, medium, high }

class UserProfile {
  final String? id;
  final String? email;
  final String? phoneNumber;
  final String? name;
  final int? age;
  final Gender? gender;
  final double? height; // cm
  final double? weight; // kg
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
    this.age,
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
    // Convert age to birth_date (approximate if user only inputs age)
    // Better: Controller should manage birthDate, but if we only have age int:
    // We can't accurately save birth_date from age.
    // Ideally UI inputs birthDate.
    // If UI inputs Age, we save it where?
    // If DB REQUIRES birth_date, we need to ask User for Birth Date OR estimte it.
    // Let's assume we save to compatible fields if possible.
    
    // Note: Saving profile usually updates specific fields. 
    // We return a map, but the Service dictates what gets sent to Supabase.
    
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'full_name': name, // DB: full_name
      // 'birth_date': ... hard to reverse age without full date
      'gender': gender?.toString().split('.').last,
      'height_cm': height, // DB: height_cm
      'weight_kg': weight, // DB: weight_kg
      'stressLevel': stressLevel,
      'activity_level': activityLevel?.toString().split('.').last, // DB: activity_level
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
      age: json['age'],
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
      age: 20,
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


import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // If profile doesn't exist, return a basic profile from auth metadata
        return UserProfile(
          id: user.id,
          email: user.email,
          name: user.userMetadata?['full_name'] ?? 'Pengguna Baru',
          phoneNumber: user.userMetadata?['phone_number'],
          // Default values for new users
          age: 20,
          gender: Gender.male,
          activityLevel: ActivityLevel.medium,
          stressLevel: 3,
        );
      }

      // Merge auth data and map fields
      final data = Map<String, dynamic>.from(response);
      data['email'] = user.email;
      data['name'] = data['full_name']; // Map full_name column to name field
      // Map other potential discrepancies if schema differs

      
      return UserProfile.fromJson(data);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Helper to map activity (App Enum -> DB String)
    String mapActivity(ActivityLevel? level) {
      switch (level) {
        case ActivityLevel.low: return 'sedentary';
        case ActivityLevel.medium: return 'moderate';
        case ActivityLevel.high: return 'active'; // 'active' or 'very_active' depending on schema check
        default: return 'sedentary';
      }
    }

    // Helper to estimate birth_date from age
    String estimateBirthDate(int? age) {
      if (age == null) return '2000-01-01';
      final year = DateTime.now().year - age;
      return '$year-01-01';
    }

    final updates = {
      'full_name': profile.name,
      'phone_number': profile.phoneNumber,
      'birth_date': estimateBirthDate(profile.age), // DB uses birth_date
      'gender': profile.gender?.toString().split('.').last, // 'male', 'female' matches DB
      'height_cm': profile.height, // DB uses height_cm
      'weight_kg': profile.weight, // DB uses weight_kg
      'activity_level': mapActivity(profile.activityLevel),
      // 'updated_at': DateTime.now().toIso8601String(), // Trigger usually handles this, or manual is fine
    };

    // Remove nulls if partially updating (though here we likely update all form fields)
    // updates.removeWhere((key, value) => value == null);

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        ...updates,
      });
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}

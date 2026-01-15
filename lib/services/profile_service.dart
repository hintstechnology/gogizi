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
          birthDate: DateTime(2000, 1, 1),
          gender: Gender.male,
          activityLevel: ActivityLevel.medium,
          stressLevel: 3,
        );
      }

      // Merge auth data and map fields
      final data = Map<String, dynamic>.from(response);
      data['email'] = user.email;
      data['name'] = data['full_name'];
      data['phoneNumber'] = data['phone_number'];
      data['height'] = data['height_cm'];
      data['weight'] = data['weight_kg'];

      // Map birth_date to birthDate
      if (data['birth_date'] != null) {
         data['birthDate'] = data['birth_date']; // String is fine, fromJson parses it
      }

      // Map Activity Level (DB: sedentary/moderate/active -> App: low/medium/high)
      if (data['activity_level'] != null) {
        String dbLevel = data['activity_level'].toString().toLowerCase();
        if (dbLevel == 'sedentary') data['activityLevel'] = 'low';
        else if (dbLevel == 'moderate') data['activityLevel'] = 'medium';
        else if (dbLevel == 'active') data['activityLevel'] = 'high';
        else data['activityLevel'] = 'medium'; 
      }
      
      final profile = UserProfile.fromJson(data);
      
      // Calculate nutritional needs only if profile is complete
      final needs = profile.isComplete ? NutritionalNeeds.calculate(profile) : null;
      
      return UserProfile(
        id: profile.id,
        email: profile.email,
        phoneNumber: profile.phoneNumber,
        name: profile.name,
        birthDate: profile.birthDate,
        gender: profile.gender,
        height: profile.height,
        weight: profile.weight,
        stressLevel: profile.stressLevel,
        activityLevel: profile.activityLevel,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
        nutritionalNeeds: needs,
      );
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
        case ActivityLevel.high: return 'active';
        default: return 'sedentary';
      }
    }

    final updates = {
      'full_name': profile.name,
      'phone_number': profile.phoneNumber,
      'birth_date': profile.birthDate?.toIso8601String(), // Send exact date
      'gender': profile.gender?.toString().split('.').last,
      'height_cm': profile.height,
      'weight_kg': profile.weight,
      'activity_level': mapActivity(profile.activityLevel),
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

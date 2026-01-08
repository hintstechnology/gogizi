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

    final updates = {
      'full_name': profile.name,
      'phone_number': profile.phoneNumber,
      'age': profile.age,
      'gender': profile.gender?.toString().split('.').last,
      'height': profile.height,
      'weight': profile.weight,
      'activity_level': profile.activityLevel?.toString().split('.').last,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').upsert({
      'id': user.id,
      ...updates,
    });
  }
}

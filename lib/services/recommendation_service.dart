import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/food_library_item.dart';

class RecommendationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate recommendations for the day
  Future<void> generateDailyRecommendations(UserProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || profile.nutritionalNeeds == null) return;

      // 1. Fetch available food library
      // In a real app with limited RAM, we might fetch only a subset or use server-side function/edge function.
      // For now, assuming library < 1000 items, fetching all is okay.
      final response = await _supabase.select('food_library'); // Fetch all columns
      final List<FoodLibraryItem> foodLibrary = (response as List)
          .map((item) => FoodLibraryItem.fromJson(item))
          .toList();

      if (foodLibrary.isEmpty) return;

      // 2. Algorithm: "Smart Random Selection" targeting calorie needs
      // Target: +- 10% of daily calories
      final targetCalories = profile.nutritionalNeeds!.calories;
      final mealSplit = {
        'Breakfast': 0.30, // 30%
        'Lunch': 0.40,     // 40%
        'Dinner': 0.30     // 30%
      };

      Map<String, FoodLibraryItem> selectedMenu = {};

      // Helper to find food close to target
      FoodLibraryItem findFoodFor(double targetCal) {
        // Filter candidates within reasonable range (e.g. 0.5x to 1.5x of sub-target)
        // If strict range yields no results, fallback to random.
        var candidates = foodLibrary.where((f) => 
            f.calories >= targetCal * 0.5 && f.calories <= targetCal * 1.5
        ).toList();

        if (candidates.isEmpty) candidates = foodLibrary;
        
        // Pick random
        return candidates[Random().nextInt(candidates.length)];
      }

      selectedMenu['breakfast'] = findFoodFor(targetCalories * mealSplit['Breakfast']!);
      selectedMenu['lunch'] = findFoodFor(targetCalories * mealSplit['Lunch']!);
      selectedMenu['dinner'] = findFoodFor(targetCalories * mealSplit['Dinner']!);

      // 3. Save to Database (Replace existing for this user)
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      final recommendationData = {
        'user_id': user.id,
        'date': today,
        'breakfast_id': selectedMenu['breakfast']!.id,
        'lunch_id': selectedMenu['lunch']!.id,
        'dinner_id': selectedMenu['dinner']!.id,
        'total_calories': selectedMenu.values.fold(0.0, (sum, item) => sum + item.calories),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Upsert: user_id + date Constraint typically handles 'one per day'
      // If user wants to REPLACE simply regardless of history, we might delete first?
      // Or if table has Unique(user_id) constraint for 'current' recommendation.
      // Let's assume unique constraint on (user_id, date) or just (user_id) if we only keep 1 ever.
      // Given request: "replace aja recommendation yang lama", we upsert.
      
      // We need to know the constraint name if we use onConflict, 
      // but standard upsert works if Primary Key matches.
      // If table structure handles history (user_id, date PK), upsert works for today.
      // If we want to replace YESTERDAY's data with TODAY's, we just insert today's.
      // Let's try upserting based on user_id if that's the intention, OR just insert new date.
      
      // Strategy: Check if entry exists for today
      final existing = await _supabase.from('daily_recommendations')
          .select()
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (existing != null) {
        // Update
        await _supabase.from('daily_recommendations').update(recommendationData).eq('id', existing['id']);
      } else {
        // Insert
        await _supabase.from('daily_recommendations').insert(recommendationData);
      }
      
    } catch (e) {
      print('Error generating recommendations: $e');
      rethrow; 
    }
  }

  // Get current recommendations
  Future<Map<String, FoodLibraryItem>?> getRecommendations() async {
     try {
       final user = _supabase.auth.currentUser;
       if (user == null) return null;
       
       final today = DateTime.now().toIso8601String().split('T')[0];

       // 1. Get IDs
       final response = await _supabase.from('daily_recommendations')
           .select()
           .eq('user_id', user.id)
           .eq('date', today)
           .maybeSingle();

       if (response == null) return null;

       // 2. Fetch Food Items manually to be safe against missing FK relations
       final foodIds = [
         response['breakfast_id'],
         response['lunch_id'],
         response['dinner_id']
       ];

       final foodsResponse = await _supabase.from('food_library')
           .select()
           .inFilter('id', foodIds);
           
       final List<FoodLibraryItem> foods = (foodsResponse as List)
           .map((item) => FoodLibraryItem.fromJson(item))
           .toList();

       // Map back to meals (careful if duplicate IDs selected, need to match by ID)
       FoodLibraryItem? findById(dynamic id) => 
           foods.firstWhere((f) => f.id == id, orElse: () => foods.first);

       return {
         'breakfast': findById(response['breakfast_id'])!,
         'lunch': findById(response['lunch_id'])!,
         'dinner': findById(response['dinner_id'])!,
       };
     } catch (e) {
       print('Error fetching recommendations: $e');
       return null;
     }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_library_item.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- FOOD LIBRARY ---

  /// Mengambil data makanan berdasarkan label prediksi AI (e.g. 'Bakso', 'Cimol atau cilok')
  Future<FoodLibraryItem?> getFoodByAiLabel(String label) async {
    try {
      final response = await _client
          .from('food_library')
          .select()
          .eq('ai_class_label', label)
          .maybeSingle(); // Mengambil 1 baris, return null jika tidak ada

      if (response == null) return null;
      return FoodLibraryItem.fromJson(response);
    } catch (e) {
      print('Supabase Error (getFoodByAiLabel): $e');
      return null;
    }
  }

  /// Mengambil semua library makanan (misal untuk fitur search manual)
  Future<List<FoodLibraryItem>> searchFood(String query) async {
    try {
      final response = await _client
          .from('food_library')
          .select()
          .ilike('name', '%$query%') // Case-insensitive search
          .limit(20);

      final List<dynamic> data = response;
      return data.map((json) => FoodLibraryItem.fromJson(json)).toList();
    } catch (e) {
      print('Supabase Error (searchFood): $e');
      return [];
    }
  }
}

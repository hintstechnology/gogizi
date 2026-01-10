import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/food_library_item.dart';

class RecommendationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Genetic Algorithm Parameters
  static const int POPULATION_SIZE = 20;
  static const int GENERATIONS = 30; // Reduced for performance
  static const double MUTATION_RATE = 0.1;

  // Generate recommendations using Genetic Algorithm
  Future<Map<String, List<FoodLibraryItem>>?> generateDailyRecommendations(UserProfile profile) async {
    final user = _supabase.auth.currentUser;
    if (user == null || profile.nutritionalNeeds == null) return null;

    try {
      // 1. Fetch data from all 5 categories from EXISTING tables
      // Mapping: staple->mp, animal->sh, plant->sn, vegetable->sy, side->plk
      final tables = {
        'mp': 'rec_source_staple',
        'sn': 'rec_source_plant', 
        'sh': 'rec_source_animal',
        'sy': 'rec_source_vegetable',
        'plk': 'rec_source_side'
      };
      
      final Map<String, List<FoodLibraryItem>> library = {};

      for (var key in tables.keys) {
        try {
          final res = await _supabase.from(tables[key]!).select();
          library[key] = (res as List).map((e) {
            // Mapping DB column 'price' to model 'estimated_price' if needed
            // But FoodLibraryItem might expect 'estimated_price'. 
            // If DB has 'price', let's manually map it or let generic handle it.
            // Creating a map copy to ensure correct key for model if needed.
            final map = Map<String, dynamic>.from(e);
            if (!map.containsKey('estimated_price') && map.containsKey('price')) {
              map['estimated_price'] = map['price'];
            }
            if (!map.containsKey('portion_desc') && map.containsKey('unit')) {
              map['portion_desc'] = map['unit'];
            }
            return FoodLibraryItem.fromJson(map);
          }).toList();
        } catch (e) {
          print('Error fetching ${tables[key]}: $e');
          library[key] = [];
        }
      }

      // Check if we have enough data (at least 1 item per category)
      if (library.values.any((list) => list.isEmpty)) {
        print('Not enough data in source tables for GA');
        return null;
      }

      // 2. Run Genetic Algorithm
      // Gene: [idx_mp, idx_sn, idx_sh, idx_sy, idx_plk] * 3 meals = 15 integers
      
      List<List<int>> population = [];
      
      // Initialize Population
      for (int i = 0; i < POPULATION_SIZE; i++) {
        population.add(_createRandomIndividual(library));
      }

      // Evolution Loop
      for (int g = 0; g < GENERATIONS; g++) {
        // Calculate Fitness for all
        List<Map<String, dynamic>> scoredPop = [];
        for (var ind in population) {
          double score = _calculateFitness(ind, library, profile.nutritionalNeeds!);
          scoredPop.add({'individual': ind, 'fitness': score});
        }

        // Sort by fitness (descending, higher is better)
        scoredPop.sort((a, b) => (b['fitness'] as double).compareTo(a['fitness']));

        // Selection & Reproduction
        List<List<int>> newPop = [];
        
        // Elitism: Keep best 2
        newPop.add(scoredPop[0]['individual']);
        newPop.add(scoredPop[1]['individual']);

        // Crossover & Mutation for the rest
        while (newPop.length < POPULATION_SIZE) {
          // Tournamen Selection
          var p1 = _tournamentSelection(scoredPop);
          var p2 = _tournamentSelection(scoredPop);
          
          // Crossover
          var child = _crossover(p1, p2);
          
          // Mutation
          _mutate(child, library);
          
          newPop.add(child);
        }
        population = newPop;
      }

      // Best Solution
      var bestInd = population[0];
      // Recalculate sort to be safe
      population.sort((a, b) => 
        _calculateFitness(b, library, profile.nutritionalNeeds!)
        .compareTo(_calculateFitness(a, library, profile.nutritionalNeeds!))
      );
      bestInd = population.first;

      // 3. Decode Best Individual to Meals
      Map<String, List<FoodLibraryItem>> recommendedMenu = _decodeIndividual(bestInd, library);
      NutritionalNeeds totalNutrients = _calculateTotalNutrients(bestInd, library);

      // Calculate Total Price
      double totalPrice = 0;
      for (var meal in recommendedMenu.values) {
        for (var item in meal) {
          totalPrice += item.estimatedPrice ?? 0;
        }
      }

      // 4. Save to DB (JSONB format in 'composition')
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      try {
        final composition = {
          'breakfast': recommendedMenu['breakfast']!.map((e) => e.toJson()).toList(),
          'lunch': recommendedMenu['lunch']!.map((e) => e.toJson()).toList(),
          'dinner': recommendedMenu['dinner']!.map((e) => e.toJson()).toList(),
        };

        // Note: constraint might be different or implicit. 
        // Attempting update logic manually if upsert fails on constraint name detection.
        // Assuming unique index on (user_id, valid_date) exists or we handle duplication logic logic.
        
        final existing = await _supabase.from('daily_recommendations')
            .select('id')
            .eq('user_id', user.id)
            .eq('valid_date', today)
            .maybeSingle();

        final data = {
          'user_id': user.id,
          'valid_date': today,
          'composition': composition,
          'total_calories': totalNutrients.calories,
          'total_protein': totalNutrients.protein,
          'total_carbs': totalNutrients.carbs,
          'total_fat': totalNutrients.fat,
          'total_price': totalPrice,
          'package_name': 'Paket Sehat',
          'rank_order': 1,
          'created_at': DateTime.now().toIso8601String(),
        };

        if (existing != null) {
          await _supabase.from('daily_recommendations').update(data).eq('id', existing['id']);
        } else {
          await _supabase.from('daily_recommendations').insert(data);
        }

      } catch (e) {
        print('Failed to save to DB, returning memory result: $e');
      }

      return recommendedMenu;

    } catch (e) {
      print('GA Critical Failure: $e');
      return null;
    }
  }

  // --- GA Helpers ---

  List<int> _createRandomIndividual(Map<String, List<FoodLibraryItem>> lib) {
    // 3 meals * 5 components. Structure:
    // 0-4: Breakfast [mp, sn, sh, sy, plk]
    // 5-9: Lunch ...
    // ...
    List<int> genes = [];
    final types = ['mp', 'sn', 'sh', 'sy', 'plk'];
    
    for (int meal = 0; meal < 3; meal++) {
      for (var type in types) {
        int max = lib[type]!.length;
        if (max == 0) {
           genes.add(0); // Should not happen if check passed
        } else {
           genes.add(Random().nextInt(max));
        }
      }
    }
    return genes;
  }

  double _calculateFitness(List<int> genes, Map<String, List<FoodLibraryItem>> lib, NutritionalNeeds target) {
    var total = _calculateTotalNutrients(genes, lib);
    
    double diffCal = (total.calories - target.calories).abs();
    double diffPro = (total.protein - target.protein).abs();
    double diffCarb = (total.carbs - target.carbs).abs();
    double diffFat = (total.fat - target.fat).abs();

    double penalty = diffCal + (diffPro * 4) + (diffCarb * 4) + (diffFat * 9); 
    
    if (penalty == 0) return 10000;
    return 10000 / penalty; 
  }

  NutritionalNeeds _calculateTotalNutrients(List<int> genes, Map<String, List<FoodLibraryItem>> lib) {
    double cal = 0, pro = 0, carb = 0, fat = 0;
    final types = ['mp', 'sn', 'sh', 'sy', 'plk'];
    
    int geneIdx = 0;
    for (int meal = 0; meal < 3; meal++) {
      for (var type in types) {
        int itemIdx = genes[geneIdx];
        if (lib[type]!.isNotEmpty && itemIdx < lib[type]!.length) {
          var item = lib[type]![itemIdx];
          cal += item.calories;
          pro += item.protein;
          carb += item.carbs;
          fat += item.fat;
        }
        geneIdx++;
      }
    }
    return NutritionalNeeds(calories: cal, protein: pro, carbs: carb, fat: fat, fiber: 0);
  }

  List<int> _tournamentSelection(List<Map<String, dynamic>> pop) {
    int bestIdx = Random().nextInt(pop.length);
    for (int i=0; i<2; i++) {
      int idx = Random().nextInt(pop.length);
      if ((pop[idx]['fitness'] as double) > (pop[bestIdx]['fitness'] as double)) {
        bestIdx = idx;
      }
    }
    return List<int>.from(pop[bestIdx]['individual'] as List<int>);
  }

  List<int> _crossover(List<int> p1, List<int> p2) {
    if (Random().nextDouble() > 0.7) return List.from(p1);
    
    int point = Random().nextInt(p1.length);
    List<int> child = [];
    child.addAll(p1.sublist(0, point));
    child.addAll(p2.sublist(point));
    return child;
  }

  void _mutate(List<int> ind, Map<String, List<FoodLibraryItem>> lib) {
    if (Random().nextDouble() < MUTATION_RATE) {
      final types = ['mp', 'sn', 'sh', 'sy', 'plk'];
      int pos = Random().nextInt(ind.length);
      int typeIdx = pos % 5;
      String type = types[typeIdx];
      
      if (lib[type]!.isNotEmpty) {
        ind[pos] = Random().nextInt(lib[type]!.length);
      }
    }
  }

  Map<String, List<FoodLibraryItem>> _decodeIndividual(List<int> genes, Map<String, List<FoodLibraryItem>> lib) {
    final types = ['mp', 'sn', 'sh', 'sy', 'plk'];
    Map<String, List<FoodLibraryItem>> meals = {
      'breakfast': [],
      'lunch': [],
      'dinner': []
    };
    
    int idx = 0;
    void add(String time) {
      for (var type in types) {
        int itemIdx = genes[idx++];
        if (lib[type]!.isNotEmpty && itemIdx < lib[type]!.length) {
          meals[time]!.add(lib[type]![itemIdx]);
        }
      }
    }
    
    add('breakfast');
    add('lunch');
    add('dinner');
    
    return meals;
  }

  // Get current recommendations
  Future<Map<String, List<FoodLibraryItem>>?> getRecommendations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase.from('daily_recommendations')
          .select()
          .eq('user_id', user.id)
          .eq('valid_date', today) // Updated column name
          .maybeSingle();

      if (response == null || response['composition'] == null) return null;

      final composition = response['composition'] as Map<String, dynamic>;

      // Helper to parse JSONB list
      List<FoodLibraryItem> parseList(dynamic jsonList) {
        if (jsonList == null || jsonList is! List) return [];
        return (jsonList as List).map((e) => FoodLibraryItem.fromJson(e)).toList();
      }

      return {
        'breakfast': parseList(composition['breakfast']),
        'lunch': parseList(composition['lunch']),
        'dinner': parseList(composition['dinner']),
      };
    } catch (e) {
      print('Error fetching recommendations: $e');
      return null;
    }
  }
}

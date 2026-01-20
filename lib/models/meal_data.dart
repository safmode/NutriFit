// lib/models/meal_data.dart
import 'package:flutter/foundation.dart';

@immutable
class MealData {
  /// Stable identifier so you can schedule/save favorites without relying on name.
  final String id;

  final String name;
  final String difficulty; // Easy/Medium/Hard etc.
  final int timeMinutes; // 30 (mins)
  final int caloriesKcal; // 180 (kCal)
  final String category;

  final String description;
  final List<String> nutritionFacts;
  final List<Map<String, String>> ingredients; // [{'name':..., 'amount':...}]
  final List<String> steps;

  /// Optional: for UI images later. Can be asset path or network url.
  final String? image;

  const MealData({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.timeMinutes,
    required this.caloriesKcal,
    required this.category,
    required this.description,
    required this.nutritionFacts,
    required this.ingredients,
    required this.steps,
    this.image,
  });

  /// Backward-friendly text helpers for your UI
  String get timeLabel => '${timeMinutes}mins';
  String get caloriesLabel => '${caloriesKcal}kCal';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'difficulty': difficulty,
      'timeMinutes': timeMinutes,
      'caloriesKcal': caloriesKcal,
      'category': category,
      'description': description,
      'nutritionFacts': nutritionFacts,
      'ingredients': ingredients,
      'steps': steps,
      if (image != null) 'image': image,
    };
  }

  factory MealData.fromMap(Map<String, dynamic> map) {
    return MealData(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      difficulty: (map['difficulty'] ?? 'Easy').toString(),
      timeMinutes: _toInt(map['timeMinutes'], fallback: 0),
      caloriesKcal: _toInt(map['caloriesKcal'], fallback: 0),
      category: (map['category'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      nutritionFacts: (map['nutritionFacts'] is List)
          ? List<String>.from(map['nutritionFacts'])
          : const [],
      ingredients: (map['ingredients'] is List)
          ? List<Map<String, String>>.from(
              (map['ingredients'] as List).map((e) {
                final m = (e is Map) ? e : <String, dynamic>{};
                return {
                  'name': (m['name'] ?? '').toString(),
                  'amount': (m['amount'] ?? '').toString(),
                };
              }),
            )
          : const [],
      steps: (map['steps'] is List) ? List<String>.from(map['steps']) : const [],
      image: map['image']?.toString(),
    );
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return fallback;
      return int.tryParse(digits) ?? fallback;
    }
    return fallback;
  }
}

/// =========================================================
/// Meal Catalog (Static library / local database)
/// =========================================================
class MealCatalog {
  static const List<MealData> breakfast = breakfastMeals;
  static const List<MealData> lunch = lunchMeals;
  static const List<MealData> snacks = snackMeals;
  static const List<MealData> dinner = dinnerMeals;

  static List<MealData> all() => <MealData>[
        ...breakfastMeals,
        ...lunchMeals,
        ...snackMeals,
        ...dinnerMeals,
      ];

  /// type: Breakfast / Lunch / Snacks / Dinner
  static List<MealData> byType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'breakfast':
        return breakfastMeals;
      case 'lunch':
        return lunchMeals;
      case 'snacks':
      case 'snack':
        return snackMeals;
      case 'dinner':
        return dinnerMeals;
      default:
        return all();
    }
  }

  static MealData? findById(String id) {
    for (final m in all()) {
      if (m.id == id) return m;
    }
    return null;
  }

  static MealData? findByName(String name) {
    final key = name.trim().toLowerCase();
    for (final m in all()) {
      if (m.name.trim().toLowerCase() == key) return m;
    }
    return null;
  }

  static List<MealData> search(
    String query, {
    String? type,
    int limit = 50,
  }) {
    final q = query.trim().toLowerCase();
    final list = (type == null) ? all() : byType(type);
    if (q.isEmpty) return list.take(limit).toList();

    final result = list.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q) ||
          m.difficulty.toLowerCase().contains(q);
    }).take(limit).toList();

    return result;
  }
}

/// =========================================================
/// YOUR MEAL DATABASE (same content, but structured safer)
/// =========================================================

// Breakfast Meals
const List<MealData> breakfastMeals = [
  MealData(
    id: 'breakfast_honey_pancake',
    name: 'Honey Pancake',
    difficulty: 'Easy',
    timeMinutes: 30,
    caloriesKcal: 180,
    category: 'Cake',
    description:
        'Fluffy pancakes drizzled with golden honey, a perfect sweet breakfast treat that energizes your morning.',
    nutritionFacts: ['180kCal', '30g fats', '20g proteins'],
    ingredients: [
      {'name': 'Wheat Flour', 'amount': '100g'},
      {'name': 'Sugar', 'amount': '1 tsp'},
      {'name': 'Baking Soda', 'amount': '2 tsp'},
      {'name': 'Eggs', 'amount': '2 items'},
      {'name': 'Honey', 'amount': '2 tbsp'},
      {'name': 'Milk', 'amount': '1 cup'},
    ],
    steps: [
      'Mix flour, sugar, salt, and baking powder in a bowl',
      'In separate bowl, whisk eggs and milk until blended',
      'Pour wet mixture into dry ingredients and stir gently',
      'Heat pan on medium and pour batter to form circles',
      'Cook until bubbles form, then flip and cook other side',
      'Serve warm with honey drizzled on top',
    ],
  ),
  MealData(
    id: 'breakfast_blueberry_pancake',
    name: 'Blueberry Pancake',
    difficulty: 'Medium',
    timeMinutes: 30,
    caloriesKcal: 230,
    category: 'Cake',
    description:
        'Delicious pancakes loaded with fresh blueberries, providing antioxidants and a burst of fruity flavor.',
    nutritionFacts: ['230kCal', '25g fats', '22g proteins'],
    ingredients: [
      {'name': 'Wheat Flour', 'amount': '100g'},
      {'name': 'Sugar', 'amount': '1 tsp'},
      {'name': 'Baking Soda', 'amount': '2 tsp'},
      {'name': 'Eggs', 'amount': '2 items'},
      {'name': 'Blueberries', 'amount': '1 cup'},
      {'name': 'Milk', 'amount': '1 cup'},
    ],
    steps: [
      'Prepare pancake batter following standard recipe',
      'Gently fold in fresh blueberries',
      'Cook on medium heat until golden brown',
      'Flip carefully to avoid breaking blueberries',
      'Serve with maple syrup or yogurt',
    ],
  ),
  MealData(
    id: 'breakfast_canai_bread',
    name: 'Canai Bread',
    difficulty: 'Easy',
    timeMinutes: 20,
    caloriesKcal: 230,
    category: 'Pie',
    description:
        'Traditional flatbread with crispy layers, perfect for dipping in curry or enjoying with condensed milk.',
    nutritionFacts: ['230kCal', '15g fats', '18g proteins'],
    ingredients: [
      {'name': 'All Purpose Flour', 'amount': '200g'},
      {'name': 'Ghee', 'amount': '3 tbsp'},
      {'name': 'Salt', 'amount': '1 tsp'},
      {'name': 'Water', 'amount': '1 cup'},
      {'name': 'Sugar', 'amount': '1 tsp'},
    ],
    steps: [
      'Mix flour and salt in a bowl',
      'Add water gradually and knead into smooth dough',
      'Rest dough for 30 minutes covered',
      'Divide into balls and flatten with ghee',
      'Cook on hot griddle until golden and crispy',
    ],
  ),
  MealData(
    id: 'breakfast_salmon_nigiri',
    name: 'Salmon Nigiri',
    difficulty: 'Medium',
    timeMinutes: 20,
    caloriesKcal: 120,
    category: 'Salad',
    description:
        'Fresh salmon over seasoned rice, a protein-rich Japanese delicacy perfect for a healthy breakfast.',
    nutritionFacts: ['120kCal', '8g fats', '25g proteins'],
    ingredients: [
      {'name': 'Fresh Salmon', 'amount': '100g'},
      {'name': 'Sushi Rice', 'amount': '150g'},
      {'name': 'Rice Vinegar', 'amount': '2 tbsp'},
      {'name': 'Nori', 'amount': '1 sheet'},
      {'name': 'Wasabi', 'amount': '1 tsp'},
    ],
    steps: [
      'Cook sushi rice and season with vinegar',
      'Slice salmon thinly against the grain',
      'Form rice into small oval shapes',
      'Place salmon slice over rice',
      'Serve with soy sauce and wasabi',
    ],
  ),
  MealData(
    id: 'breakfast_avocado_toast',
    name: 'Avocado Toast',
    difficulty: 'Easy',
    timeMinutes: 10,
    caloriesKcal: 250,
    category: 'Salad',
    description:
        'Creamy avocado on toasted bread, a trendy and nutritious breakfast option packed with healthy fats.',
    nutritionFacts: ['250kCal', '18g fats', '12g proteins'],
    ingredients: [
      {'name': 'Whole Grain Bread', 'amount': '2 slices'},
      {'name': 'Avocado', 'amount': '1 item'},
      {'name': 'Lemon Juice', 'amount': '1 tbsp'},
      {'name': 'Salt & Pepper', 'amount': 'to taste'},
      {'name': 'Cherry Tomatoes', 'amount': '4 items'},
    ],
    steps: [
      'Toast bread until golden brown',
      'Mash avocado with lemon juice and seasoning',
      'Spread avocado mixture on toast',
      'Top with sliced tomatoes',
      'Garnish with herbs if desired',
    ],
  ),
  MealData(
    id: 'breakfast_berry_smoothie_bowl',
    name: 'Berry Smoothie Bowl',
    difficulty: 'Easy',
    timeMinutes: 15,
    caloriesKcal: 280,
    category: 'Smoothie',
    description:
        'Thick and creamy smoothie bowl topped with fresh berries, granola, and seeds for a refreshing start.',
    nutritionFacts: ['280kCal', '12g fats', '15g proteins'],
    ingredients: [
      {'name': 'Mixed Berries', 'amount': '200g'},
      {'name': 'Banana', 'amount': '1 item'},
      {'name': 'Greek Yogurt', 'amount': '1 cup'},
      {'name': 'Granola', 'amount': '50g'},
      {'name': 'Chia Seeds', 'amount': '1 tbsp'},
    ],
    steps: [
      'Blend berries, banana, and yogurt until smooth',
      'Pour into a bowl',
      'Top with granola, fresh berries, and chia seeds',
      'Drizzle with honey if desired',
      'Serve immediately',
    ],
  ),
  MealData(
    id: 'breakfast_greek_yogurt_parfait',
    name: 'Greek Yogurt Parfait',
    difficulty: 'Easy',
    timeMinutes: 10,
    caloriesKcal: 200,
    category: 'Smoothie',
    description:
        'Layered yogurt with granola and fresh fruits, providing probiotics and sustained energy.',
    nutritionFacts: ['200kCal', '8g fats', '20g proteins'],
    ingredients: [
      {'name': 'Greek Yogurt', 'amount': '200g'},
      {'name': 'Granola', 'amount': '50g'},
      {'name': 'Fresh Berries', 'amount': '100g'},
      {'name': 'Honey', 'amount': '1 tbsp'},
      {'name': 'Almonds', 'amount': '10 pieces'},
    ],
    steps: [
      'Layer yogurt in a glass or bowl',
      'Add layer of granola',
      'Top with fresh berries',
      'Drizzle honey over top',
      'Garnish with sliced almonds',
    ],
  ),
  MealData(
    id: 'breakfast_oatmeal_with_fruits',
    name: 'Oatmeal with Fruits',
    difficulty: 'Easy',
    timeMinutes: 15,
    caloriesKcal: 220,
    category: 'Cake',
    description:
        'Warm and comforting oatmeal topped with seasonal fruits and nuts, rich in fiber and nutrients.',
    nutritionFacts: ['220kCal', '6g fats', '12g proteins'],
    ingredients: [
      {'name': 'Rolled Oats', 'amount': '1 cup'},
      {'name': 'Milk', 'amount': '2 cups'},
      {'name': 'Banana', 'amount': '1 item'},
      {'name': 'Berries', 'amount': '50g'},
      {'name': 'Cinnamon', 'amount': '1 tsp'},
    ],
    steps: [
      'Bring milk to boil in a pot',
      'Add oats and reduce heat',
      'Simmer for 10 minutes stirring occasionally',
      'Top with sliced fruits and cinnamon',
      'Serve hot with honey if desired',
    ],
  ),
];

// Lunch Meals
const List<MealData> lunchMeals = [
  MealData(
    id: 'lunch_chicken_steak',
    name: 'Chicken Steak',
    difficulty: 'Medium',
    timeMinutes: 45,
    caloriesKcal: 450,
    category: 'Main Course',
    description:
        'Juicy grilled chicken breast with herbs and spices, served with vegetables for a protein-packed lunch.',
    nutritionFacts: ['450kCal', '20g fats', '45g proteins'],
    ingredients: [
      {'name': 'Chicken Breast', 'amount': '200g'},
      {'name': 'Olive Oil', 'amount': '2 tbsp'},
      {'name': 'Garlic', 'amount': '3 cloves'},
      {'name': 'Mixed Herbs', 'amount': '1 tsp'},
      {'name': 'Salt & Pepper', 'amount': 'to taste'},
    ],
    steps: [
      'Season chicken with herbs, salt, and pepper',
      'Heat olive oil in pan over medium-high heat',
      'Cook chicken for 6-7 minutes per side',
      'Let rest for 5 minutes before serving',
      'Serve with steamed vegetables',
    ],
  ),
  MealData(
    id: 'lunch_caesar_salad',
    name: 'Caesar Salad',
    difficulty: 'Easy',
    timeMinutes: 20,
    caloriesKcal: 320,
    category: 'Salad',
    description:
        'Classic Caesar salad with crispy romaine lettuce, parmesan cheese, and creamy dressing.',
    nutritionFacts: ['320kCal', '25g fats', '15g proteins'],
    ingredients: [
      {'name': 'Romaine Lettuce', 'amount': '200g'},
      {'name': 'Parmesan Cheese', 'amount': '50g'},
      {'name': 'Croutons', 'amount': '30g'},
      {'name': 'Caesar Dressing', 'amount': '50ml'},
      {'name': 'Lemon', 'amount': '1 item'},
    ],
    steps: [
      'Wash and chop romaine lettuce',
      'Add croutons and shaved parmesan',
      'Drizzle with Caesar dressing',
      'Squeeze fresh lemon juice',
      'Toss well and serve immediately',
    ],
  ),
  MealData(
    id: 'lunch_pasta_carbonara',
    name: 'Pasta Carbonara',
    difficulty: 'Medium',
    timeMinutes: 30,
    caloriesKcal: 520,
    category: 'Main Course',
    description:
        'Creamy Italian pasta with bacon, eggs, and parmesan cheese - a comfort food classic.',
    nutritionFacts: ['520kCal', '28g fats', '22g proteins'],
    ingredients: [
      {'name': 'Spaghetti', 'amount': '200g'},
      {'name': 'Bacon', 'amount': '100g'},
      {'name': 'Eggs', 'amount': '2 items'},
      {'name': 'Parmesan', 'amount': '50g'},
      {'name': 'Black Pepper', 'amount': '1 tsp'},
    ],
    steps: [
      'Cook spaghetti according to package directions',
      'Fry bacon until crispy',
      'Mix eggs and parmesan in a bowl',
      'Toss hot pasta with egg mixture',
      'Add bacon and pepper, serve hot',
    ],
  ),
  MealData(
    id: 'lunch_grilled_salmon',
    name: 'Grilled Salmon',
    difficulty: 'Medium',
    timeMinutes: 35,
    caloriesKcal: 380,
    category: 'Main Course',
    description: 'Omega-3 rich salmon fillet grilled to perfection with lemon and dill.',
    nutritionFacts: ['380kCal', '22g fats', '40g proteins'],
    ingredients: [
      {'name': 'Salmon Fillet', 'amount': '200g'},
      {'name': 'Lemon', 'amount': '1 item'},
      {'name': 'Fresh Dill', 'amount': '10g'},
      {'name': 'Olive Oil', 'amount': '1 tbsp'},
      {'name': 'Garlic', 'amount': '2 cloves'},
    ],
    steps: [
      'Season salmon with salt and pepper',
      'Brush with olive oil and minced garlic',
      'Grill for 4-5 minutes per side',
      'Squeeze fresh lemon over fish',
      'Garnish with dill and serve',
    ],
  ),
  MealData(
    id: 'lunch_vegetable_stir_fry',
    name: 'Vegetable Stir Fry',
    difficulty: 'Easy',
    timeMinutes: 25,
    caloriesKcal: 280,
    category: 'Vegetarian',
    description: 'Colorful mixed vegetables stir-fried with aromatic Asian seasonings.',
    nutritionFacts: ['280kCal', '12g fats', '10g proteins'],
    ingredients: [
      {'name': 'Mixed Vegetables', 'amount': '300g'},
      {'name': 'Soy Sauce', 'amount': '2 tbsp'},
      {'name': 'Sesame Oil', 'amount': '1 tbsp'},
      {'name': 'Ginger', 'amount': '1 inch'},
      {'name': 'Garlic', 'amount': '3 cloves'},
    ],
    steps: [
      'Heat oil in wok over high heat',
      'Add garlic and ginger, stir briefly',
      'Add vegetables and stir fry',
      'Add soy sauce and toss well',
      'Serve hot over rice',
    ],
  ),
  MealData(
    id: 'lunch_chicken_wrap',
    name: 'Chicken Wrap',
    difficulty: 'Easy',
    timeMinutes: 15,
    caloriesKcal: 340,
    category: 'Quick Meal',
    description: 'Grilled chicken wrapped in tortilla with fresh vegetables and sauce.',
    nutritionFacts: ['340kCal', '15g fats', '28g proteins'],
    ingredients: [
      {'name': 'Tortilla Wrap', 'amount': '1 large'},
      {'name': 'Grilled Chicken', 'amount': '100g'},
      {'name': 'Lettuce', 'amount': '50g'},
      {'name': 'Tomato', 'amount': '1 item'},
      {'name': 'Ranch Dressing', 'amount': '2 tbsp'},
    ],
    steps: [
      'Warm tortilla in microwave',
      'Layer lettuce and sliced tomatoes',
      'Add grilled chicken strips',
      'Drizzle with ranch dressing',
      'Roll tightly and cut in half',
    ],
  ),
];

// Snacks
const List<MealData> snackMeals = [
  MealData(
    id: 'snack_apple_peanut_butter',
    name: 'Apple Slices with Peanut Butter',
    difficulty: 'Easy',
    timeMinutes: 5,
    caloriesKcal: 180,
    category: 'Healthy Snack',
    description:
        'Crisp apple slices paired with creamy peanut butter for a perfect energy boost.',
    nutritionFacts: ['180kCal', '10g fats', '6g proteins'],
    ingredients: [
      {'name': 'Apple', 'amount': '1 large'},
      {'name': 'Peanut Butter', 'amount': '2 tbsp'},
    ],
    steps: [
      'Wash and core the apple',
      'Slice apple into wedges',
      'Serve with peanut butter for dipping',
    ],
  ),
  MealData(
    id: 'snack_trail_mix',
    name: 'Trail Mix',
    difficulty: 'Easy',
    timeMinutes: 5,
    caloriesKcal: 220,
    category: 'Healthy Snack',
    description:
        'Nutritious mix of nuts, dried fruits, and seeds for on-the-go energy.',
    nutritionFacts: ['220kCal', '14g fats', '8g proteins'],
    ingredients: [
      {'name': 'Almonds', 'amount': '30g'},
      {'name': 'Cashews', 'amount': '30g'},
      {'name': 'Dried Cranberries', 'amount': '20g'},
      {'name': 'Dark Chocolate Chips', 'amount': '10g'},
    ],
    steps: [
      'Mix all ingredients in a bowl',
      'Portion into small containers',
      'Store in airtight container',
    ],
  ),
  MealData(
    id: 'snack_hummus_veggies',
    name: 'Hummus with Veggies',
    difficulty: 'Easy',
    timeMinutes: 10,
    caloriesKcal: 150,
    category: 'Healthy Snack',
    description: 'Creamy chickpea hummus served with fresh crunchy vegetables.',
    nutritionFacts: ['150kCal', '8g fats', '6g proteins'],
    ingredients: [
      {'name': 'Hummus', 'amount': '100g'},
      {'name': 'Carrot Sticks', 'amount': '50g'},
      {'name': 'Cucumber', 'amount': '50g'},
      {'name': 'Bell Pepper', 'amount': '50g'},
    ],
    steps: [
      'Cut vegetables into sticks',
      'Arrange on a plate',
      'Serve with hummus for dipping',
    ],
  ),
  MealData(
    id: 'snack_protein_bar',
    name: 'Protein Bar',
    difficulty: 'Easy',
    timeMinutes: 2,
    caloriesKcal: 200,
    category: 'Quick Snack',
    description:
        'Convenient protein-packed bar for post-workout or mid-day energy.',
    nutritionFacts: ['200kCal', '7g fats', '15g proteins'],
    ingredients: [
      {'name': 'Protein Bar', 'amount': '1 bar'},
    ],
    steps: ['Unwrap and enjoy'],
  ),
  MealData(
    id: 'snack_cheese_crackers',
    name: 'Cheese and Crackers',
    difficulty: 'Easy',
    timeMinutes: 5,
    caloriesKcal: 190,
    category: 'Quick Snack',
    description: 'Classic combination of cheese with whole grain crackers.',
    nutritionFacts: ['190kCal', '12g fats', '8g proteins'],
    ingredients: [
      {'name': 'Cheddar Cheese', 'amount': '40g'},
      {'name': 'Whole Grain Crackers', 'amount': '10 pieces'},
    ],
    steps: [
      'Slice cheese into squares',
      'Arrange with crackers on plate',
      'Enjoy together',
    ],
  ),
  MealData(
    id: 'snack_fruit_salad',
    name: 'Fruit Salad',
    difficulty: 'Easy',
    timeMinutes: 10,
    caloriesKcal: 120,
    category: 'Healthy Snack',
    description: 'Refreshing mix of seasonal fruits for a vitamin-rich snack.',
    nutritionFacts: ['120kCal', '1g fats', '2g proteins'],
    ingredients: [
      {'name': 'Mixed Fruits', 'amount': '200g'},
      {'name': 'Honey', 'amount': '1 tsp'},
      {'name': 'Mint Leaves', 'amount': '5 leaves'},
    ],
    steps: [
      'Wash and chop fruits into bite-size pieces',
      'Mix in a bowl',
      'Drizzle with honey',
      'Garnish with mint leaves',
    ],
  ),
];

// Dinner Meals
const List<MealData> dinnerMeals = [
  MealData(
    id: 'dinner_grilled_chicken_salad',
    name: 'Grilled Chicken Salad',
    difficulty: 'Easy',
    timeMinutes: 25,
    caloriesKcal: 350,
    category: 'Light Dinner',
    description: 'Healthy grilled chicken over mixed greens with light vinaigrette.',
    nutritionFacts: ['350kCal', '15g fats', '35g proteins'],
    ingredients: [
      {'name': 'Chicken Breast', 'amount': '150g'},
      {'name': 'Mixed Greens', 'amount': '100g'},
      {'name': 'Cherry Tomatoes', 'amount': '50g'},
      {'name': 'Cucumber', 'amount': '50g'},
      {'name': 'Balsamic Dressing', 'amount': '2 tbsp'},
    ],
    steps: [
      'Grill seasoned chicken breast',
      'Chop vegetables',
      'Toss greens with vegetables',
      'Slice chicken and place on top',
      'Drizzle with dressing',
    ],
  ),
  MealData(
    id: 'dinner_beef_stir_fry',
    name: 'Beef Stir Fry',
    difficulty: 'Medium',
    timeMinutes: 30,
    caloriesKcal: 420,
    category: 'Main Course',
    description: 'Tender beef strips with colorful vegetables in savory sauce.',
    nutritionFacts: ['420kCal', '22g fats', '38g proteins'],
    ingredients: [
      {'name': 'Beef Sirloin', 'amount': '200g'},
      {'name': 'Broccoli', 'amount': '100g'},
      {'name': 'Bell Peppers', 'amount': '100g'},
      {'name': 'Soy Sauce', 'amount': '3 tbsp'},
      {'name': 'Ginger', 'amount': '1 inch'},
    ],
    steps: [
      'Slice beef into thin strips',
      'Stir fry beef until browned',
      'Add vegetables and cook',
      'Add soy sauce and ginger',
      'Serve over rice or noodles',
    ],
  ),
  MealData(
    id: 'dinner_baked_salmon_asparagus',
    name: 'Baked Salmon with Asparagus',
    difficulty: 'Medium',
    timeMinutes: 40,
    caloriesKcal: 400,
    category: 'Light Dinner',
    description: 'Oven-baked salmon fillet with roasted asparagus spears.',
    nutritionFacts: ['400kCal', '24g fats', '42g proteins'],
    ingredients: [
      {'name': 'Salmon Fillet', 'amount': '200g'},
      {'name': 'Asparagus', 'amount': '150g'},
      {'name': 'Olive Oil', 'amount': '2 tbsp'},
      {'name': 'Lemon', 'amount': '1 item'},
      {'name': 'Garlic', 'amount': '2 cloves'},
    ],
    steps: [
      'Preheat oven to 400°F (200°C)',
      'Season salmon and asparagus',
      'Drizzle with olive oil',
      'Bake for 15-20 minutes',
      'Serve with lemon wedges',
    ],
  ),
  MealData(
    id: 'dinner_vegetable_soup',
    name: 'Vegetable Soup',
    difficulty: 'Easy',
    timeMinutes: 35,
    caloriesKcal: 180,
    category: 'Light Dinner',
    description: 'Warm and comforting vegetable soup packed with nutrients.',
    nutritionFacts: ['180kCal', '5g fats', '8g proteins'],
    ingredients: [
      {'name': 'Mixed Vegetables', 'amount': '300g'},
      {'name': 'Vegetable Broth', 'amount': '500ml'},
      {'name': 'Tomatoes', 'amount': '2 items'},
      {'name': 'Onion', 'amount': '1 item'},
      {'name': 'Herbs', 'amount': '1 tsp'},
    ],
    steps: [
      'Sauté onions in pot',
      'Add chopped vegetables',
      'Pour in broth and bring to boil',
      'Simmer for 20 minutes',
      'Season and serve hot',
    ],
  ),
  MealData(
    id: 'dinner_turkey_meatballs',
    name: 'Turkey Meatballs',
    difficulty: 'Medium',
    timeMinutes: 45,
    caloriesKcal: 380,
    category: 'Main Course',
    description: 'Lean turkey meatballs in marinara sauce, a healthy protein option.',
    nutritionFacts: ['380kCal', '18g fats', '42g proteins'],
    ingredients: [
      {'name': 'Ground Turkey', 'amount': '250g'},
      {'name': 'Breadcrumbs', 'amount': '50g'},
      {'name': 'Egg', 'amount': '1 item'},
      {'name': 'Marinara Sauce', 'amount': '200ml'},
      {'name': 'Parmesan', 'amount': '30g'},
    ],
    steps: [
      'Mix turkey, breadcrumbs, and egg',
      'Form into meatballs',
      'Bake at 375°F for 25 minutes',
      'Heat marinara sauce',
      'Combine and serve with pasta',
    ],
  ),
  MealData(
    id: 'dinner_quinoa_bowl',
    name: 'Quinoa Bowl',
    difficulty: 'Easy',
    timeMinutes: 30,
    caloriesKcal: 360,
    category: 'Vegetarian',
    description: 'Nutritious quinoa bowl with roasted vegetables and tahini dressing.',
    nutritionFacts: ['360kCal', '16g fats', '14g proteins'],
    ingredients: [
      {'name': 'Quinoa', 'amount': '100g'},
      {'name': 'Chickpeas', 'amount': '100g'},
      {'name': 'Sweet Potato', 'amount': '100g'},
      {'name': 'Spinach', 'amount': '50g'},
      {'name': 'Tahini Dressing', 'amount': '2 tbsp'},
    ],
    steps: [
      'Cook quinoa according to package',
      'Roast chickpeas and sweet potato',
      'Arrange in bowl with spinach',
      'Top with roasted items',
      'Drizzle with tahini dressing',
    ],
  ),
];

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../models/meal_data.dart';
import '../../widgets/press_scale.dart';

class MealCategoryScreen extends StatefulWidget {
  /// You can pass mealType either via constructor OR route arguments.
  /// ✅ Supported route argument formats:
  /// 1) String: Navigator.pushNamed(context, '/meal-category', arguments: 'Breakfast')
  /// 2) Map:    Navigator.pushNamed(context, '/meal-category', arguments: {'type': 'Breakfast'})
  final String? mealType;

  const MealCategoryScreen({super.key, this.mealType});

  @override
  State<MealCategoryScreen> createState() => _MealCategoryScreenState();
}

class _MealCategoryScreenState extends State<MealCategoryScreen> {
  String _selectedCategory = 'All';
  String _query = '';

  String get _mealTypeFromRoute {
    final arg = ModalRoute.of(context)?.settings.arguments;

    if (arg is String && arg.trim().isNotEmpty) return arg.trim();

    if (arg is Map) {
      final t = arg['type'];
      if (t is String && t.trim().isNotEmpty) return t.trim();
    }

    return widget.mealType ?? 'Breakfast';
  }

  List<MealData> get _allMeals {
    switch (_mealTypeFromRoute) {
      case 'Breakfast':
        return breakfastMeals;
      case 'Lunch':
        return lunchMeals;
      case 'Snacks':
        return snackMeals;
      case 'Dinner':
        return dinnerMeals;
      default:
        return breakfastMeals;
    }
  }

  List<String> get _categories {
    final set = _allMeals.map((m) => m.category).toSet();

    // keep mockup-style categories if available
    final wanted = <String>['Salad', 'Cake', 'Pie', 'Smoothie'];
    final filtered = wanted.where((c) => set.contains(c)).toList();
    if (filtered.isNotEmpty) return ['All', ...filtered];

    final fallback = set.toList()..sort();
    return ['All', ...fallback];
  }

  List<MealData> get _filteredMeals {
    Iterable<MealData> list = _allMeals;

    if (_selectedCategory != 'All') {
      list = list.where((m) => m.category == _selectedCategory);
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) {
        return m.name.toLowerCase().contains(q) ||
            m.category.toLowerCase().contains(q) ||
            m.difficulty.toLowerCase().contains(q);
      });
    }

    return list.toList();
  }

  List<MealData> get _recommendations {
    final list = _filteredMeals;
    if (list.length <= 2) return list;
    return list.take(6).toList();
  }

  List<MealData> get _popular {
    final list = _filteredMeals;
    if (list.length <= 2) return list;
    return list.skip(2).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final type = _mealTypeFromRoute;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: AppRadii.r24),
                ),
                builder: (_) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Filters & sorting (coming soon)'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: type == 'Breakfast' ? 'Search Pancake' : 'Search meals',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  suffixIcon: Icon(Icons.tune, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),

            // Category tiles
            if (_categories.length > 1) ...[
              const Text(
                'Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),

              SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length - 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final category = _categories[i + 1];
                    final selected = _selectedCategory == category;

                    return _CategoryTile(
                      title: category,
                      icon: _iconForCategory(category),
                      bg: _bgForCategory(category),
                      selected: selected,
                      onTap: () => setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),

              const SizedBox(height: 26),
            ],

            // Recommendations
            const Text(
              'Recommendation\nfor Diet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 14),

            if (_recommendations.isEmpty)
              const _EmptyBox(text: 'No meals found. Try another keyword/category.')
            else
              SizedBox(
                height: 310,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendations.length.clamp(0, 10),
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final meal = _recommendations[index];
                    return _RecommendationCard(
                      meal: meal,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/meal-detail',
                        arguments: meal,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 26),

            // Popular list
            const Text(
              'Popular',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            if (_popular.isEmpty)
              const _EmptyBox(text: 'No popular meals yet.')
            else
              Column(
                children: _popular.map((meal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PopularRow(
                      meal: meal,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/meal-detail',
                        arguments: meal,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'Salad':
        return Icons.set_meal;
      case 'Cake':
        return Icons.cake;
      case 'Pie':
        return Icons.pie_chart;
      case 'Smoothie':
        return Icons.local_drink;
      default:
        return Icons.category;
    }
  }

  Color _bgForCategory(String c) {
    switch (c) {
      case 'Salad':
        return const Color(0xFFEAF2FF);
      case 'Cake':
        return const Color(0xFFF8E9FF);
      case 'Pie':
        return const Color(0xFFEAF2FF);
      case 'Smoothie':
        return const Color(0xFFF8E9FF);
      default:
        return AppColors.card;
    }
  }
}

// ======================
// Widgets
// ======================

class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bg;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.bg,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 125,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 1.4,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final MealData meal;
  final VoidCallback onTap;

  const _RecommendationCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = (meal.category == 'Cake' || meal.category == 'Smoothie')
        ? const Color(0xFFF8E9FF)
        : const Color(0xFFEAF2FF);

    return PressScale(
      onTap: onTap,
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 200,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.fastfood,
                    size: 62,
                    color: Color(0xFFFF9A62),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              meal.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // ✅ FIX: use timeLabel + caloriesLabel (new MealData)
            Text(
              '${meal.difficulty} | ${meal.timeLabel} | ${meal.caloriesLabel}',
              style: const TextStyle(fontSize: 13, color: AppColors.subText),
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  final MealData meal;
  final VoidCallback onTap;

  const _PopularRow({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow(opacity: 0.06),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.restaurant,
                  color: Color(0xFFFF9A62), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ✅ FIX: use timeLabel + caloriesLabel
                  Text(
                    '${meal.difficulty} | ${meal.timeLabel} | ${meal.caloriesLabel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.subText),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.br16,
      ),
      child: Text(text, style: const TextStyle(color: AppColors.subText)),
    );
  }
}

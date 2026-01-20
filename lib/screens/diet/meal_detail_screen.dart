import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants.dart';
import '../../models/meal_data.dart';
import '../../services/firestore_service.dart';
import '../../widgets/press_scale.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({super.key});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool isFav = false;

  // Get current date in Malaysia timezone (UTC+8)
  DateTime get _todayInMalaysia {
    final utcNow = DateTime.now().toUtc();
    final malaysiaTime = utcNow.add(const Duration(hours: 8));
    return DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;

    // ✅ Support BOTH:
    // 1) arguments: meal (MealData)
    // 2) arguments: {'meal': meal, 'type': 'Breakfast'}
    MealData? meal;
    String? defaultType;

    if (arg is MealData) {
      meal = arg;
    } else if (arg is Map) {
      final m = arg['meal'];
      if (m is MealData) meal = m;

      final t = arg['type'];
      if (t is String && t.trim().isNotEmpty) defaultType = t.trim();
    }

    if (meal == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text(
            'Meal Detail',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Meal data not found. Please open from Meal Category.'),
        ),
      );
    }

    // ✅ make non-null for the rest of build (fixes nullable ingredients/steps error)
    final MealData mealData = meal;

    final timeLabel = _mealTimeLabel(mealData);
    final caloriesLabel = _mealCaloriesLabel(mealData);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Stack(
              children: [
                Container(
                  height: 350,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Colors.white60,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fastfood,
                        size: 100,
                        color: Color(0xFFFF9A62),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 10,
                  child: _HeroIconButton(
                    icon: Icons.arrow_back_ios,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 48,
                  right: 58,
                  child: _HeroIconButton(
                    icon: Icons.more_horiz,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: AppRadii.r24),
                        ),
                        builder: (_) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                ListTile(
                                  leading: Icon(Icons.info_outline),
                                  title: Text('More actions (coming soon)'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 48,
                  right: 10,
                  child: _FavButton(
                    isFav: isFav,
                    onToggle: () => setState(() => isFav = !isFav),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    mealData.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${mealData.difficulty} | $timeLabel | $caloriesLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.subText,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Nutrition
                  const Text(
                    'Nutrition',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mealData.nutritionFacts.map((fact) {
                      final f = fact.toLowerCase();
                      Color color = const Color(0xFFFFE5E5);
                      if (f.contains('fat')) color = const Color(0xFFFFF4E6);
                      if (f.contains('protein')) color = const Color(0xFFE3F2FD);
                      if (f.contains('carb')) color = const Color(0xFFE8F5E9);
                      if (f.contains('kcal')) color = const Color(0xFFFFECF5);
                      return _NutritionBadge(text: fact, color: color);
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Description
                  const Text(
                    'Descriptions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mealData.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5E5E5E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Ingredients
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ingredients That You\nWill Need',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      Text(
                        '${mealData.ingredients.length} items',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.subText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mealData.ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = mealData.ingredients[index];
                        return _IngredientCard(
                          name: (ingredient['name'] ?? '').toString(),
                          amount: (ingredient['amount'] ?? '').toString(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Steps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Step by Step',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${mealData.steps.length} Steps',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.subText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...mealData.steps.asMap().entries.map(
                        (e) => _StepItem(
                          number: e.key + 1,
                          description: e.value,
                        ),
                      ),
                  const SizedBox(height: 22),

                  // Add to schedule
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _openAddToSchedule(mealData, defaultType),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add to Meal Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Works with BOTH old and new MealData
  String _mealTimeLabel(MealData meal) {
    // New model may have timeLabel
    try {
      final dynamic d = meal;
      final v = d.timeLabel;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}

    // Old model: "30mins"
    try {
      final dynamic d = meal;
      final v = d.time;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}

    // New model fallback: minutes
    try {
      final dynamic d = meal;
      final v = d.timeMinutes;
      if (v is int) return '${v}mins';
    } catch (_) {}

    return '—';
  }

  String _mealCaloriesLabel(MealData meal) {
    // New model may have caloriesLabel
    try {
      final dynamic d = meal;
      final v = d.caloriesLabel;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}

    // Old model: "180kCal"
    try {
      final dynamic d = meal;
      final v = d.calories;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}

    // New model: caloriesKcal int
    try {
      final dynamic d = meal;
      final v = d.caloriesKcal;
      if (v is int) return '${v}kCal';
    } catch (_) {}

    return '—';
  }

  // ✅ Extract calories reliably (new model first)
  int _extractCalories(MealData meal) {
    // New model: caloriesKcal
    try {
      final dynamic d = meal;
      final v = d.caloriesKcal;
      if (v is int) return v;
    } catch (_) {}

    // Try nutritionFacts
    for (final fact in meal.nutritionFacts) {
      final lower = fact.toLowerCase();
      if (lower.contains('kcal')) {
        final digits = fact.replaceAll(RegExp(r'[^0-9]'), '');
        final value = int.tryParse(digits);
        if (value != null) return value;
      }
    }

    // Old model: meal.calories string
    try {
      final dynamic d = meal;
      final s = d.calories;
      if (s is String) {
        final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(digits) ?? 0;
      }
    } catch (_) {}

    return 0;
  }

  Future<void> _openAddToSchedule(MealData meal, String? defaultType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    final result = await showModalBottomSheet<_AddToScheduleResult?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.r24),
      ),
      builder: (_) =>
          _AddToScheduleSheet(defaultType: defaultType ?? 'Breakfast'),
    );

    if (result == null) return;
    if (!mounted) return;

    // Use Malaysia timezone for scheduling
    final today = _todayInMalaysia;
    final scheduledAt = DateTime(
      today.year,
      today.month,
      today.day,
      result.time.hour,
      result.time.minute,
    );

    final calories = _extractCalories(meal);

    await _firestore.addMealSchedule(
      uid: uid,
      mealName: meal.name,
      mealType: result.type,
      scheduledAt: scheduledAt,
      calories: calories == 0 ? null : calories,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added "${meal.name}" (${calories == 0 ? '—' : '${calories}kCal'}) to ${result.type} at ${result.time.format(context)}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!mounted) return;
    Navigator.pushNamed(context, '/meal-schedule');
  }
}

// ------------------ UI pieces ------------------

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  final bool isFav;
  final VoidCallback onToggle;

  const _FavButton({required this.isFav, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(isFav),
            color: isFav ? const Color(0xFFFF5C8A) : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _NutritionBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _NutritionBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final String name;
  final String amount;

  const _IngredientCard({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {},
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.ac_unit,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(fontSize: 9, color: AppColors.subText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int number;
  final String description;

  const _StepItem({required this.number, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: PressScale(
        onTap: () {},
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step $number',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ Add to schedule sheet ------------------

class _AddToScheduleResult {
  final String type;
  final TimeOfDay time;

  const _AddToScheduleResult({required this.type, required this.time});
}

class _AddToScheduleSheet extends StatefulWidget {
  final String defaultType;
  const _AddToScheduleSheet({required this.defaultType});

  @override
  State<_AddToScheduleSheet> createState() => _AddToScheduleSheetState();
}

class _AddToScheduleSheetState extends State<_AddToScheduleSheet> {
  late String _type;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding:
          EdgeInsets.only(left: 18, right: 18, top: 18, bottom: bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Add to Schedule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Meal type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
              DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
              DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
              DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'Breakfast'),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked == null) return;
                setState(() => _time = picked);
              },
              child: Text('Time: ${_time.format(context)}'),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                    context, _AddToScheduleResult(type: _type, time: _time));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
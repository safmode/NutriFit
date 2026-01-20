import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../models/meal_data.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/press_scale.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final FirestoreService firestore = FirestoreService();

  String _mealType = 'Breakfast'; // default
  String _period = 'Weekly'; // UI only for now

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Get current date in Malaysia timezone (UTC+8)
  DateTime get _todayInMalaysia {
    final utcNow = DateTime.now().toUtc();
    final malaysiaTime = utcNow.add(const Duration(hours: 8));
    return DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Session expired. Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Meal Planner',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        automaticallyImplyLeading: false,
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
                          title: Text('More actions (coming soon)'),
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
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MealNutritionsCard(
              uid: uid,
              periodLabel: _period,
              onTapPeriod: () async {
                final picked = await _pickSimple(
                  context,
                  title: 'Period',
                  options: const ['Weekly', 'Monthly'],
                  current: _period,
                );
                if (picked != null && mounted) {
                  setState(() => _period = picked);
                }
              },
            ),
            const SizedBox(height: 22),

            _DailyScheduleCard(
              onCheck: () => Navigator.pushNamed(context, '/meal-schedule'),
            ),
            const SizedBox(height: 22),

            // =========================
            // Today Meals (Firestore)
            // =========================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today Meals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                _PillDropdown(
                  label: _mealType,
                  onTap: () async {
                    final picked = await _pickSimple(
                      context,
                      title: 'Meal Type',
                      options: const ['Breakfast', 'Lunch', 'Snacks', 'Dinner'],
                      current: _mealType,
                    );
                    if (picked != null && mounted) {
                      setState(() => _mealType = picked);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore.streamMealsForDay(uid, day: _todayInMalaysia),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Error: ${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                // Filter locally by mealType
                final allDocs = snap.data?.docs ?? [];
                final docs = allDocs.where((d) {
                  final data = d.data();
                  final type = data['mealType'] as String? ?? 'Breakfast';
                  return type == _mealType;
                }).toList();

                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 60,
                          color: AppColors.subText,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No meals scheduled',
                          style: TextStyle(color: AppColors.subText),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: docs.map((d) {
                    final data = d.data();

                    final ts = data['scheduledAt'];
                    final scheduledAt = (ts is Timestamp)
                        ? ts.toDate()
                        : DateTime.now();

                    final mealName = (data['mealName'] ?? 'Meal').toString();
                    final notificationEnabled =
                        (data['notificationEnabled'] ?? true) as bool;

                    return _MealCard(
                      name: mealName,
                      time: _formatMealTime(scheduledAt),
                      alert: notificationEnabled,
                      onToggle: (val) {
                        firestore.updateMealSchedule(uid, d.id, {
                          'notificationEnabled': val,
                        });
                      },
                      onTap: () => _openMealDetailFromSchedule(
                        mealName: mealName,
                        type: _mealType,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 22),

            // =========================
            // Find Something to Eat
            // =========================
            _FindFoodSection(
              onSelect: (type) {
                Navigator.pushNamed(context, '/meal-category', arguments: type);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Convert scheduled mealName -> MealData, then open detail screen correctly.
  void _openMealDetailFromSchedule({
    required String mealName,
    required String type,
  }) {
    final meal = _findMealByName(mealName);

    if (meal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meal "$mealName" not found in local database. Please open from category list.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/meal-detail',
      arguments: {'meal': meal, 'type': type},
    );
  }

  MealData? _findMealByName(String name) {
    final all = <MealData>[
      ...breakfastMeals,
      ...lunchMeals,
      ...snackMeals,
      ...dinnerMeals,
    ];

    final key = name.trim().toLowerCase();
    for (final m in all) {
      if (m.name.trim().toLowerCase() == key) return m;
    }

    // fallback contains match (helps if name has extra spaces)
    for (final m in all) {
      if (m.name.trim().toLowerCase().contains(key) ||
          key.contains(m.name.trim().toLowerCase())) {
        return m;
      }
    }
    return null;
  }

  static String _formatMealTime(DateTime date) {
    // Get today in Malaysia timezone
    final utcNow = DateTime.now().toUtc();
    final malaysiaTime = utcNow.add(const Duration(hours: 8));
    final today = DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
    
    final d = DateTime(date.year, date.month, date.day);

    final time = DateFormat('h a').format(date).toLowerCase();
    if (d == today) return 'Today | $time';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow | $time';
    return '${DateFormat('MMM dd').format(date)} | $time';
  }

  Future<String?> _pickSimple(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.r24),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...options.map((v) {
                final selected = v == current;
                return ListTile(
                  title: Text(v),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, v),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------
// Meal Nutritions Card (functional graph based on calories)
// -------------------------
class _MealNutritionsCard extends StatefulWidget {
  final String periodLabel;
  final VoidCallback onTapPeriod;
  final String uid;

  const _MealNutritionsCard({
    required this.periodLabel,
    required this.onTapPeriod,
    required this.uid,
  });

  @override
  State<_MealNutritionsCard> createState() => _MealNutritionsCardState();
}

class _MealNutritionsCardState extends State<_MealNutritionsCard> {
  final FirestoreService _firestore = FirestoreService();
  List<int> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  // Get current date in Malaysia timezone (UTC+8)
  DateTime get _todayInMalaysia {
    final utcNow = DateTime.now().toUtc();
    final malaysiaTime = utcNow.add(const Duration(hours: 8));
    return DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
  }

  Future<void> _loadWeeklyData() async {
    setState(() => _isLoading = true);

    final today = _todayInMalaysia;
    final sunday = today.subtract(Duration(days: today.weekday % 7));

    final List<int> calories = [];

    for (int i = 0; i < 7; i++) {
      final day = sunday.add(Duration(days: i));
      final snapshot = await _firestore.streamMealsForDay(widget.uid, day: day).first;
      
      int dayCalories = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        dayCalories += (data['calories'] ?? 0) as int;
      }
      calories.add(dayCalories);
    }

    if (mounted) {
      setState(() {
        _weeklyCalories = calories;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Meal Nutritions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            _PillDropdown(label: widget.periodLabel, onTap: widget.onTapPeriod),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.br20,
            boxShadow: AppColors.softShadow(opacity: 0.06),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomPaint(
                  painter: _NutritionGraphPainter(caloriesData: _weeklyCalories),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 12),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _DayLabel('Sun'),
                          _DayLabel('Mon'),
                          _DayLabel('Tue'),
                          _DayLabel('Wed'),
                          _DayLabel('Thu'),
                          _DayLabel('Fri'),
                          _DayLabel('Sat'),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;
  const _DayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, color: AppColors.subText),
    );
  }
}

class _PillDropdown extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillDropdown({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyScheduleCard extends StatelessWidget {
  final VoidCallback onCheck;
  const _DailyScheduleCard({required this.onCheck});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadii.br20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Daily Meal Schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          ElevatedButton(
            onPressed: onCheck,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Check', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// -------------------------
// Meal Card (with bell toggle)
// -------------------------
class _MealCard extends StatelessWidget {
  final String name;
  final String time;
  final bool alert;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _MealCard({
    required this.name,
    required this.time,
    required this.alert,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.br16,
            boxShadow: AppColors.softShadow(opacity: 0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFFFF9A62)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  alert
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  color: alert ? AppColors.accent : Colors.grey.shade400,
                ),
                onPressed: () => onToggle(!alert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------
// Find Something to Eat
// -------------------------
class _FindFoodSection extends StatelessWidget {
  final void Function(String mealType) onSelect;
  const _FindFoodSection({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Healthy Food Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                title: 'Breakfast',
                icon: Icons.bakery_dining,
                count: '${breakfastMeals.length}+ Foods',
                bgColor: const Color(0xFFEAF1FF),
                btnText: 'Select',
                onTap: () => onSelect('Breakfast'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _CategoryCard(
                title: 'Lunch',
                icon: Icons.lunch_dining,
                count: '${lunchMeals.length}+ Foods',
                bgColor: const Color(0xFFFFECF5),
                btnText: 'Select',
                onTap: () => onSelect('Lunch'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                title: 'Snacks',
                icon: Icons.fastfood,
                count: '${snackMeals.length}+ Foods',
                bgColor: const Color(0xFFEAF1FF),
                btnText: 'Select',
                onTap: () => onSelect('Snacks'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _CategoryCard(
                title: 'Dinner',
                icon: Icons.dinner_dining,
                count: '${dinnerMeals.length}+ Foods',
                bgColor: const Color(0xFFFFECF5),
                btnText: 'Select',
                onTap: () => onSelect('Dinner'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String count;
  final Color bgColor;
  final String btnText;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.bgColor,
    required this.btnText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: bgColor, borderRadius: AppRadii.br20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(color: AppColors.subText)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(onPressed: onTap, child: Text(btnText)),
          ),
        ],
      ),
    );
  }
}

// -------------------------
// Painter (functional wave chart based on real data)
// -------------------------
class _NutritionGraphPainter extends CustomPainter {
  final List<int> caloriesData;

  _NutritionGraphPainter({required this.caloriesData});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Calculate normalized values (0.0 to 1.0)
    final maxCalories = caloriesData.isEmpty 
        ? 2500 
        : caloriesData.reduce((a, b) => a > b ? a : b).clamp(100, 3500);
    
    final values = caloriesData.map((cal) {
      if (maxCalories == 0) return 0.0;
      return (cal / maxCalories).clamp(0.0, 1.0);
    }).toList();

    // If all values are 0, show a flat line at the bottom
    if (values.every((v) => v == 0.0)) {
      final p = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final y = size.height * 0.85 + 18;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        p,
      );
      return;
    }

    // Draw the curve
    final p = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pts = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height * (1 - values[i]) * 0.85 + 18;
      pts.add(Offset(x, y));
    }

    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final cx = (prev.dx + cur.dx) / 2;
      path.cubicTo(cx, prev.dy, cx, cur.dy, cur.dx, cur.dy);
    }

    canvas.drawPath(path, p);

    // Draw dots
    final dot = Paint()..color = Colors.white;
    final border = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final o in pts) {
      canvas.drawCircle(o, 5, dot);
      canvas.drawCircle(o, 5, border);
    }
  }

  @override
  bool shouldRepaint(covariant _NutritionGraphPainter oldDelegate) {
    return oldDelegate.caloriesData != caloriesData;
  }
}
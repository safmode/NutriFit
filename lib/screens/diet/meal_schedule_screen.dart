import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../models/meal_data.dart';
import '../../services/firestore_service.dart';
import '../../widgets/press_scale.dart';

class MealScheduleScreen extends StatefulWidget {
  const MealScheduleScreen({super.key});

  @override
  State<MealScheduleScreen> createState() => _MealScheduleScreenState();
}

class _MealScheduleScreenState extends State<MealScheduleScreen> {
  final _firestore = FirestoreService();
  late final String _uid;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _uid = u?.uid ?? '';
    
    // Initialize selected date to today in Malaysia timezone
    _selectedDate = _todayInMalaysia;
  }

  // Get current date in Malaysia timezone (UTC+8)
  DateTime get _todayInMalaysia {
    final utcNow = DateTime.now().toUtc();
    final malaysiaTime = utcNow.add(const Duration(hours: 8));
    return DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
  }

  DateTime get _monthStart => DateTime(_selectedDate.year, _selectedDate.month, 1);

  void _prevMonth() => setState(() => _selectedDate =
      DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day));

  void _nextMonth() => setState(() => _selectedDate =
      DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day));

  List<DateTime> get _weekDays {
    final d = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final sunday = d.subtract(Duration(days: d.weekday % 7));
    return List.generate(7, (i) => sunday.add(Duration(days: i)));
  }

  String _monthLabel(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamMeals() {
    return _firestore.streamMealsForDay(_uid, day: _selectedDate);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final isPm = h >= 12;
    final hh = ((h + 11) % 12) + 1;
    return '$hh:$m${isPm ? 'pm' : 'am'}';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Breakfast':
        return Icons.breakfast_dining;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Snacks':
        return Icons.fastfood;
      case 'Dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  MealData? _findMealByName(String name) {
    final all = <MealData>[
      ...breakfastMeals,
      ...lunchMeals,
      ...snackMeals,
      ...dinnerMeals,
    ];
    final n = name.trim().toLowerCase();
    for (final m in all) {
      if (m.name.trim().toLowerCase() == n) return m;
    }
    return null;
  }

  Future<void> _openAddMealSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddMealSheet(),
    );

    if (result == null) return;
    if (!mounted) return;

    final minutes = result['time24'] as int;
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      minutes ~/ 60,
      minutes % 60,
    );

    await _firestore.addMealSchedule(
      uid: _uid,
      mealName: result['name'] as String,
      mealType: result['type'] as String,
      scheduledAt: scheduledAt,
      calories: (result['calories'] as int?) ?? 0,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added: ${result['name']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMealSection(
    String title,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final totalCals = docs.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['calories'] ?? 0) as int),
    );

    final info = docs.isEmpty
        ? 'No meals'
        : '${docs.length} meals | $totalCals calories';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(info,
                style: const TextStyle(fontSize: 12, color: AppColors.subText)),
          ],
        ),
        const SizedBox(height: 12),
        if (docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Tap + to add',
                style: TextStyle(color: AppColors.subText)),
          )
        else
          ...docs.map((d) {
            final data = d.data();
            final name = (data['mealName'] ?? 'Meal').toString();
            final when = (data['scheduledAt'] as Timestamp).toDate();
            final timeLabel = _formatTime(when);

            return _MealRow(
              name: name,
              time: timeLabel,
              icon: _iconForType(title),
              onTap: () {
                final found = _findMealByName(name);
                if (found != null) {
                  Navigator.pushNamed(context, '/meal-detail', arguments: found);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recipe not found for "$name" (not in meal_data.dart)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              onDelete: () => _firestore.deleteMealSchedule(_uid, d.id),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _weekDays;
    final today = _todayInMalaysia;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Meal Schedule',
            style: TextStyle(fontWeight: FontWeight.w800)),
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

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMealSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: _uid.isEmpty
          ? const Center(child: Text('Please login again.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month nav
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: _prevMonth,
                      ),
                      Text(
                        _monthLabel(_monthStart),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Week strip
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final day = weekDays[index];
                        final isSelected = day.year == _selectedDate.year &&
                            day.month == _selectedDate.month &&
                            day.day == _selectedDate.day;
                        
                        // Check if this day is today (Malaysia time)
                        final isToday = day.year == today.year &&
                            day.month == today.month &&
                            day.day == today.day;

                        const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

                        return PressScale(
                          onTap: () => setState(() => _selectedDate = day),
                          child: Container(
                            width: 52,
                            decoration: BoxDecoration(
                              color: isToday 
                                  ? const Color(0xFF92A3FD) 
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: (isSelected && !isToday)
                                  ? Border.all(color: AppColors.primary, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  labels[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isToday 
                                        ? Colors.white 
                                        : AppColors.subText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isToday 
                                        ? Colors.white 
                                        : AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _streamMeals(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(child: Text('No data'));
                      }

                      final docs = snap.data!.docs;

                      List<QueryDocumentSnapshot<Map<String, dynamic>>> byType(String type) {
                        final list = docs.where((d) => (d.data()['mealType'] ?? '') == type).toList();
                        list.sort((a, b) {
                          final ta = (a.data()['scheduledAt'] as Timestamp).toDate();
                          final tb = (b.data()['scheduledAt'] as Timestamp).toDate();
                          return ta.compareTo(tb);
                        });
                        return list;
                      }

                      final caloriesToday = docs.fold<int>(
                        0,
                        (sum, d) => sum + ((d.data()['calories'] ?? 0) as int),
                      );

                      const caloriesGoal = 2000;

                      return Column(
                        children: [
                          _buildMealSection('Breakfast', byType('Breakfast')),
                          const SizedBox(height: 18),
                          _buildMealSection('Lunch', byType('Lunch')),
                          const SizedBox(height: 18),
                          _buildMealSection('Snacks', byType('Snacks')),
                          const SizedBox(height: 18),
                          _buildMealSection('Dinner', byType('Dinner')),
                          const SizedBox(height: 22),

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Today Meal Nutritions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _NutritionProgress(
                            label: 'Calories',
                            value: caloriesToday,
                            unit: ' kCal',
                            max: caloriesGoal,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

// -------------------- Meal row --------------------
class _MealRow extends StatelessWidget {
  final String name;
  final String time;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MealRow({
    required this.name,
    required this.time,
    required this.icon,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFFF9A62), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(time,
                      style: const TextStyle(fontSize: 11, color: AppColors.subText)),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Calories progress --------------------
class _NutritionProgress extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String unit;
  final Color color;

  const _NutritionProgress({
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final v = (value / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Icon(Icons.local_fire_department, size: 18, color: color),
              ],
            ),
            Text('$value$unit',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: v),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, _) {
              return LinearProgressIndicator(
                value: animValue,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 12,
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text('Goal: $max kCal', style: const TextStyle(fontSize: 12, color: AppColors.subText)),
      ],
    );
  }
}

// -------------------- Add meal sheet --------------------
class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet();

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _name = TextEditingController();
  final _calories = TextEditingController();

  String _type = 'Breakfast';
  int _time24 = 7 * 60;

  String get _timeLabel {
    final h = _time24 ~/ 60;
    final m = _time24 % 60;
    final isPm = h >= 12;
    final hh = ((h + 11) % 12) + 1;
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm${isPm ? 'pm' : 'am'}';
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: bottom + 18),
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
          const Text('Add Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),

          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Meal name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calories (kCal)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
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
                final initial = TimeOfDay(hour: _time24 ~/ 60, minute: _time24 % 60);
                final picked = await showTimePicker(context: context, initialTime: initial);
                if (picked == null) return;
                setState(() => _time24 = picked.hour * 60 + picked.minute);
              },
              child: Text('Time: $_timeLabel'),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _name.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter meal name')),
                  );
                  return;
                }

                final cal = int.tryParse(_calories.text.trim()) ?? 0;

                Navigator.pop(context, {
                  'name': name,
                  'type': _type,
                  'time24': _time24,
                  'calories': cal,
                });
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
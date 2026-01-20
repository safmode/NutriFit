import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  State<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();

  double _waterTargetL = 8.0;
  int _stepsTarget = 2400;
  String _period = 'Weekly'; // Daily, Weekly, Monthly

  bool _savingTargets = false;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snap = await _db.getDailyTargets(user.uid);
      final data = snap.data();
      if (data == null) return;

      if (!mounted) return;
      setState(() {
        _waterTargetL = (data['waterLitersTarget'] is num)
            ? (data['waterLitersTarget'] as num).toDouble()
            : _waterTargetL;

        _stepsTarget = (data['stepsTarget'] is num)
            ? (data['stepsTarget'] as num).toInt()
            : _stepsTarget;
      });
    } catch (_) {
      // keep defaults
    }
  }

  Future<void> _openTargetSheet() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.r24),
      ),
      builder: (_) => _TargetSheet(
        waterTargetL: _waterTargetL,
        stepsTarget: _stepsTarget,
      ),
    );

    if (result == null) return;

    if (!mounted) return;
    setState(() => _savingTargets = true);

    try {
      await _db.setDailyTargets(
        uid: user.uid,
        waterLitersTarget: (result['water'] as num).toDouble(),
        stepsTarget: (result['steps'] as num).toInt(),
      );

      if (!mounted) return;
      setState(() {
        _waterTargetL = (result['water'] as num).toDouble();
        _stepsTarget = (result['steps'] as num).toInt();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Targets updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingTargets = false);
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet(
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
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Edit Today Target'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openTargetSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _loadTargets();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker() {
    final options = ['Daily', 'Weekly', 'Monthly'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                  'Select Period',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ...options.map((v) {
                  final isSelected = v == _period;
                  return ListTile(
                    title: Text(v),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _period = v);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ FIXED: Calculate bars based on selected period
  List<_BarPoint> _calculateBars({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
    required DateTime now,
  }) {
    if (_period == 'Daily') {
      return _calculateDailyBars(activities, now);
    } else if (_period == 'Weekly') {
      return _calculateWeeklyBars(activities, now);
    } else {
      return _calculateMonthlyBars(activities, now);
    }
  }

  // Daily: Last 7 days
  List<_BarPoint> _calculateDailyBars(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
    DateTime now,
  ) {
    final counts = List<int>.filled(7, 0);
    final startDate = _startOfDay(now.subtract(const Duration(days: 6)));

    for (final doc in activities) {
      final data = doc.data();
      final ts = _safeTs(data['timestamp']);
      if (ts == null) continue;

      final activityDate = ts.toDate();

      // Check which of the last 7 days this activity belongs to
      for (int i = 0; i < 7; i++) {
        final day = startDate.add(Duration(days: i));
        final dayStart = _startOfDay(day);
        final dayEnd = _endOfDay(day);

        if ((activityDate.isAfter(dayStart) ||
                activityDate.isAtSameMomentAs(dayStart)) &&
            activityDate.isBefore(dayEnd)) {
          counts[i]++;
          break;
        }
      }
    }

    final maxCount = counts.fold<int>(1, (prev, count) => count > prev ? count : prev);

    // Generate labels with day numbers
    final labels = List.generate(7, (i) {
      final day = startDate.add(Duration(days: i));
      return '${day.day}';
    });

    return List.generate(7, (i) {
      final normalizedValue =
          counts[i] > 0 ? (counts[i] / maxCount).clamp(0.0, 1.0) : 0.0;

      final isToday = i == 6; // Last bar is today

      return _BarPoint(
        labels[i],
        normalizedValue,
        isToday ? AppColors.accent : AppColors.primary,
      );
    });
  }

  // Weekly: Current week (Sun-Sat) with activities on correct days
  List<_BarPoint> _calculateWeeklyBars(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
    DateTime now,
  ) {
    final counts = List<int>.filled(7, 0);

    // Get current week start (Sunday)
    final currentWeekStart = _startOfWeek(now);

    for (final doc in activities) {
      final data = doc.data();
      final ts = _safeTs(data['timestamp']);
      if (ts == null) continue;

      final activityDate = ts.toDate();

      // Check which day of current week this activity belongs to
      for (int i = 0; i < 7; i++) {
        final day = currentWeekStart.add(Duration(days: i));
        final dayStart = _startOfDay(day);
        final dayEnd = _endOfDay(day);

        if ((activityDate.isAfter(dayStart) ||
                activityDate.isAtSameMomentAs(dayStart)) &&
            activityDate.isBefore(dayEnd)) {
          counts[i]++;
          break;
        }
      }
    }

    final maxCount = counts.fold<int>(1, (prev, count) => count > prev ? count : prev);

    // Day names: Sun, Mon, Tue, Wed, Thu, Fri, Sat
    final labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    // Get which day of the week today is (0=Sun, 1=Mon, ..., 6=Sat)
    final todayDayOfWeek = now.weekday % 7; // Sun=0, Mon=1, Tue=2, etc.

    return List.generate(7, (i) {
      final normalizedValue =
          counts[i] > 0 ? (counts[i] / maxCount).clamp(0.0, 1.0) : 0.0;

      final isToday = i == todayDayOfWeek; // Highlight today

      return _BarPoint(
        labels[i],
        normalizedValue,
        isToday ? AppColors.accent : AppColors.primary,
      );
    });
  }

  // Monthly: Last 7 months
  List<_BarPoint> _calculateMonthlyBars(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
    DateTime now,
  ) {
    final counts = List<int>.filled(7, 0);

    for (final doc in activities) {
      final data = doc.data();
      final ts = _safeTs(data['timestamp']);
      if (ts == null) continue;

      final activityDate = ts.toDate();

      // Check which of the last 7 months this activity belongs to
      for (int i = 0; i < 7; i++) {
        // Month starts from 6 months ago
        final monthDate = DateTime(now.year, now.month - (6 - i), 1);
        final monthStart = DateTime(monthDate.year, monthDate.month, 1);
        final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 1);

        if ((activityDate.isAfter(monthStart) ||
                activityDate.isAtSameMomentAs(monthStart)) &&
            activityDate.isBefore(monthEnd)) {
          counts[i]++;
          break;
        }
      }
    }

    final maxCount = counts.fold<int>(1, (prev, count) => count > prev ? count : prev);

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Generate month labels
    final labels = List.generate(7, (i) {
      final monthDate = DateTime(now.year, now.month - (6 - i), 1);
      return monthNames[monthDate.month - 1];
    });

    return List.generate(7, (i) {
      final normalizedValue =
          counts[i] > 0 ? (counts[i] / maxCount).clamp(0.0, 1.0) : 0.0;

      final isCurrentMonth = i == 6; // Last bar is current month

      return _BarPoint(
        labels[i],
        normalizedValue,
        isCurrentMonth ? AppColors.accent : AppColors.primary,
      );
    });
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  DateTime _startOfWeek(DateTime d) {
    // weekday: Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6, Sunday=7
    // To get Sunday as start of week:
    // Sunday (7) -> 0 days back
    // Monday (1) -> 1 day back
    // Tuesday (2) -> 2 days back
    // etc.
    final daysFromSunday = d.weekday % 7; // Sunday becomes 0, Mon=1, Tue=2, etc.
    return _startOfDay(d.subtract(Duration(days: daysFromSunday)));
  }

  Timestamp? _safeTs(dynamic v) {
    if (v is Timestamp) return v;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Activity Tracker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: _openMoreMenu,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================
            // Today Target Card
            // =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today Target',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      _PressScale(
                        onTap: _savingTargets ? () {} : _openTargetSheet,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _savingTargets
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _TargetCard(
                          icon: Icons.water_drop_outlined,
                          value:
                              '${_waterTargetL.toStringAsFixed(_waterTargetL % 1 == 0 ? 0 : 1)}L',
                          label: 'Water Intake',
                          color: AppColors.primary,
                          onTap: _openTargetSheet,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _TargetCard(
                          icon: Icons.directions_walk,
                          value: '$_stepsTarget',
                          label: 'Foot Steps',
                          color: const Color(0xFFFF9A62),
                          onTap: _openTargetSheet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // =================
            // Activity Progress
            // =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                _PressScale(
                  onTap: _showPeriodPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _period,
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
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==========
            // Bar Chart (FIXED)
            // ==========
            if (user != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.streamLatestActivities(user.uid, limit: 100),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 250,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final activities = snapshot.data?.docs ?? [];
                  final bars = _calculateBars(
                    activities: activities,
                    now: DateTime.now(),
                  );

                  // Show message if no activities
                  if (activities.isEmpty) {
                    return Container(
                      height: 250,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No activities yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start tracking your activities to see progress',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    height: 250,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activities.length} activities this period',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: bars
                                .map(
                                  (b) => Expanded(
                                    child: _Bar(
                                      day: b.day,
                                      value: b.value,
                                      color: b.color,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                height: 250,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('Please login to view activity progress'),
                ),
              ),

            const SizedBox(height: 25),

            // ==============
            // Latest Activity
            // ==============
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('See more (demo)')),
                    );
                  },
                  child: const Text('See more'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _LatestActivityList(auth: _auth, db: _db),
          ],
        ),
      ),
    );
  }
}

// --------------------
// Target card (press anim)
// --------------------
class _TargetCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TargetCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.subText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------
// Bar with animation
// --------------------
class _Bar extends StatelessWidget {
  final String day;
  final double value;
  final Color color;

  const _Bar({required this.day, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final h = (value.clamp(0.0, 1.0)) * 150.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: h),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (_, height, __) {
            return Container(
              width: double.infinity,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: const TextStyle(fontSize: 11, color: AppColors.subText),
        ),
      ],
    );
  }
}

class _BarPoint {
  final String day;
  final double value;
  final Color color;
  const _BarPoint(this.day, this.value, this.color);
}

// --------------------
// Latest activity list (Firestore)
// --------------------
class _LatestActivityList extends StatelessWidget {
  final AuthService auth;
  final FirestoreService db;

  const _LatestActivityList({required this.auth, required this.db});

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const Column(
        children: [
          _ActivityItem(
            title: 'Drinking 300ml Water',
            time: 'About 3 minutes ago',
            icon: Icons.water_drop,
            iconBg: Color(0xFFFFECF5),
            iconColor: AppColors.accent,
          ),
          SizedBox(height: 12),
          _ActivityItem(
            title: 'Eat Snack (Fitbar)',
            time: 'About 10 minutes ago',
            icon: Icons.restaurant,
            iconBg: Color(0xFFFFF4E6),
            iconColor: Color(0xFFFF9A62),
          ),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.streamLatestActivities(user.uid, limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 44, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'No activity yet',
                    style: TextStyle(color: AppColors.subText),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.take(5).map((d) {
            final data = d.data();
            final title = (data['title'] ?? 'Activity').toString();
            final type = (data['type'] ?? '').toString();
            final timeText = _friendlyTime(data['timestamp']);
            final iconPack = _iconForType(type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PressScale(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(title)),
                  );
                },
                child: _ActivityItem(
                  title: title,
                  time: timeText,
                  icon: iconPack.icon,
                  iconBg: iconPack.bg,
                  iconColor: iconPack.color,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static String _friendlyTime(dynamic ts) {
    try {
      final DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is DateTime) {
        dt = ts;
      } else {
        dt = DateTime.now();
      }

      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Recently';
    }
  }

  static _TypeIcon _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('water')) {
      return const _TypeIcon(
        icon: Icons.water_drop,
        bg: Color(0xFFFFECF5),
        color: AppColors.accent,
      );
    }
    if (t.contains('workout') || t.contains('schedule')) {
      return const _TypeIcon(
        icon: Icons.fitness_center,
        bg: Color(0xFFE8EEFF),
        color: AppColors.primary,
      );
    }
    if (t.contains('snack') || t.contains('meal') || t.contains('food')) {
      return const _TypeIcon(
        icon: Icons.restaurant,
        bg: Color(0xFFFFF4E6),
        color: Color(0xFFFF9A62),
      );
    }
    if (t.contains('progress_photo') || t.contains('photo')) {
      return const _TypeIcon(
        icon: Icons.camera_alt,
        bg: Color(0xFFE8F5E9),
        color: Color(0xFF4CAF50),
      );
    }
    return const _TypeIcon(
      icon: Icons.check_circle_outline,
      bg: Color(0xFFF3F4F6),
      color: AppColors.subText,
    );
  }
}

class _TypeIcon {
  final IconData icon;
  final Color bg;
  final Color color;
  const _TypeIcon({required this.icon, required this.bg, required this.color});
}

// --------------------
// Activity row UI
// --------------------
class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
          Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}

// --------------------
// Target edit bottom sheet
// --------------------
class _TargetSheet extends StatefulWidget {
  final double waterTargetL;
  final int stepsTarget;

  const _TargetSheet({
    required this.waterTargetL,
    required this.stepsTarget,
  });

  @override
  State<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends State<_TargetSheet> {
  late final TextEditingController _water;
  late final TextEditingController _steps;

  @override
  void initState() {
    super.initState();
    _water = TextEditingController(text: widget.waterTargetL.toString());
    _steps = TextEditingController(text: widget.stepsTarget.toString());
  }

  @override
  void dispose() {
    _water.dispose();
    _steps.dispose();
    super.dispose();
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
            'Edit Today Target',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _water,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Water target (liters)',
              prefixIcon: Icon(Icons.water_drop_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _steps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Steps target',
              prefixIcon: Icon(Icons.directions_walk),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final w =
                    double.tryParse(_water.text.trim()) ?? widget.waterTargetL;
                final s = int.tryParse(_steps.text.trim()) ?? widget.stepsTarget;

                Navigator.pop(context, {
                  'water': math.max(0.0, w),
                  'steps': math.max(0, s),
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

// --------------------
// Reusable press animation
// --------------------
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _down ? 0.97 : 1.0,
        child: widget.child,
      ),
    );
  }
}
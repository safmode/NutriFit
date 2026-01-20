import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav.dart';

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({super.key});

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen> {
  final _firestore = FirestoreService();

  Future<void> _refresh() async {
    // Trigger rebuild so StreamBuilders re-evaluate.
    if (!mounted) return;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Session expired. Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Workout Tracker',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklyProgressGraph(uid: uid, firestore: _firestore),

              // Daily schedule shortcut
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Workout Schedule',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/workout-schedule'),
                      child: const Text('Check'),
                    ),
                  ],
                ),
              ),

              // Upcoming
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/workout-schedule'),
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore.getUpcomingSchedules(uid, DateTime.now()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final workouts =
                      docs
                          .map((d) {
                            final data = d.data();
                            final ts = data['scheduledAt'];
                            final scheduledAt = (ts is Timestamp)
                                ? ts.toDate()
                                : null;

                            return {
                              'id': d.id,
                              'title': (data['workoutTitle'] ?? 'Workout')
                                  .toString(),
                              'scheduledAt': scheduledAt,
                              'notificationEnabled':
                                  (data['notificationEnabled'] ?? true) as bool,
                              'isDone': (data['isDone'] ?? false) as bool,
                            };
                          })
                          .where((w) {
                            final dt = w['scheduledAt'] as DateTime?;
                            if (dt == null) return false;
                            return dt.isAfter(DateTime.now()) &&
                                !(w['isDone'] as bool);
                          })
                          .toList()
                        ..sort(
                          (a, b) => (a['scheduledAt'] as DateTime).compareTo(
                            b['scheduledAt'] as DateTime,
                          ),
                        );

                  if (workouts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 60,
                            color: AppColors.subText,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No upcoming workouts',
                            style: TextStyle(color: AppColors.subText),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: workouts.take(3).toList().asMap().entries.map((
                      e,
                    ) {
                      final index = e.key;
                      final workout = e.value;

                      return _PressScale(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/workout-detail',
                          arguments: {'workoutName': workout['title']},
                        ),
                        child: _UpcomingWorkoutCard(
                          title: workout['title'] as String,
                          time: _formatTime(workout['scheduledAt'] as DateTime),
                          color: _cycleColor(index),
                          enabled: workout['notificationEnabled'] as bool,
                          onToggle: (val) {
                            _firestore.updateSchedule(
                              uid,
                              workout['id'] as String,
                              {'notificationEnabled': val},
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 25),

              // What do you want to train
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'What Do You Want to Train',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 15),

              const _WorkoutCategoryCard(
                title: 'Fullbody Workout',
                subtitle: '11 Exercises | 32mins',
                icon: Icons.accessibility_new,
                bg: AppColors.softBlue,
              ),
              const SizedBox(height: 15),
              const _WorkoutCategoryCard(
                title: 'Lowerbody Workout',
                subtitle: '12 Exercises | 40mins',
                icon: Icons.directions_run,
                bg: Color(0xFFFFE8F5),
              ),
              const SizedBox(height: 15),
              const _WorkoutCategoryCard(
                title: 'AB Workout',
                subtitle: '14 Exercises | 20mins',
                icon: Icons.fitness_center,
                bg: AppColors.softBlue,
              ),
              const SizedBox(height: 15),
              const _WorkoutCategoryCard(
                title: 'Upperbody Workout',
                subtitle: '10 Exercises | 28mins',
                icon: Icons.accessibility,
                bg: Color(0xFFFFE8F5),
              ),
              const SizedBox(height: 15),
              const _WorkoutCategoryCard(
                title: 'Cardio Workout',
                subtitle: '8 Exercises | 25mins',
                icon: Icons.directions_run_outlined,
                bg: AppColors.softBlue,
              ),
              const SizedBox(height: 15),
              const _WorkoutCategoryCard(
                title: 'HIIT Workout',
                subtitle: '12 Exercises | 18mins',
                icon: Icons.local_fire_department,
                bg: Color(0xFFFFE8F5),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
    );
  }

  static String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) return 'Today, ${DateFormat('hh:mm a').format(date)}';
    if (day == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${DateFormat('hh:mm a').format(date)}';
    }
    return DateFormat('MMM dd, hh:mm a').format(date);
  }

  static Color _cycleColor(int i) {
    const colors = [AppColors.primary, AppColors.accent, Color(0xFFEEA4CE)];
    return colors[i % colors.length];
  }
}

class _WeeklyProgressGraph extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;
  const _WeeklyProgressGraph({required this.uid, required this.firestore});

  @override
  State<_WeeklyProgressGraph> createState() => _WeeklyProgressGraphState();
}

class _WeeklyProgressGraphState extends State<_WeeklyProgressGraph> {
  int _selectedIndex = 5;

  DateTime get _today => DateTime.now();

  List<DateTime> _last7Days() {
    final t = DateTime(_today.year, _today.month, _today.day);
    return List.generate(7, (i) => t.subtract(Duration(days: 6 - i)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _last7Days();
    final start = days.first;
    final end = days.last.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.firestore.streamSchedulesInRange(
        widget.uid,
        start: start,
        end: end,
      ),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        // group by day
        final Map<String, List<Map<String, dynamic>>> byKey = {};
        for (final d in docs) {
          final data = d.data();
          final ts = data['scheduledAt'];
          if (ts is! Timestamp) continue;
          final dt = ts.toDate();
          final key = DateFormat('yyyyMMdd').format(dt);
          (byKey[key] ??= []).add({
            'title': (data['workoutTitle'] ?? 'Workout').toString(),
            'isDone': (data['isDone'] ?? false) as bool,
          });
        }

        final percents = <double>[];
        final tooltipTitle = <String>[];

        for (final day in days) {
          final key = DateFormat('yyyyMMdd').format(day);
          final list = byKey[key] ?? const [];
          final total = list.length;
          final done = list.where((x) => x['isDone'] == true).length;
          percents.add(total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0));
          tooltipTitle.add(
            total == 0 ? 'No workout' : (list.first['title'] as String),
          );
        }

        final idx = _selectedIndex.clamp(0, 6);
        final selectedDay = days[idx];
        final selectedPercent = (percents[idx] * 100).round();
        final selectedTitle = tooltipTitle[idx];

        return Container(
          height: 270,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: LayoutBuilder(
                builder: (context, c) {
                  final fullW = c.maxWidth;

                  // Graph padding (must match painter area)
                  const leftPad = 16.0;
                  const rightPad = 46.0;
                  const topPad = 36.0;
                  const bottomPad = 28.0;

                  final usableW = (fullW - leftPad - rightPad).clamp(
                    1.0,
                    99999.0,
                  );
                  final dx = usableW / 6; // 7 points -> 6 gaps

                  // Tooltip width & clamped left
                  const tipW = 180.0;
                  final desiredLeft = leftPad + (dx * idx) - (tipW / 2);
                  final tipLeft = desiredLeft.clamp(12.0, fullW - tipW - 12.0);

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            leftPad,
                            topPad,
                            rightPad,
                            bottomPad,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (d) {
                              final localX = (d.localPosition.dx).clamp(
                                0.0,
                                usableW,
                              );
                              final t = (localX / usableW).clamp(0.0, 1.0);
                              final newIndex = (t * 6).round().clamp(0, 6);
                              setState(() => _selectedIndex = newIndex);
                            },
                            child: CustomPaint(
                              painter: _WeeklyGraphPainter(
                                percents: percents,
                                selectedIndex: idx,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Tooltip card
                      Positioned(
                        top: 48,
                        left: tipLeft,
                        child: Container(
                          width: tipW,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEE, dd MMM',
                                    ).format(selectedDay),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.subText,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$selectedPercent%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF39D98A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: percents[idx].clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF0F0F0),
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom weekday labels
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (i) {
                              final d = days[i];
                              final label = DateFormat('EEE').format(d);
                              final isSel = i == idx;
                              return Text(
                                label,
                                style: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.75),
                                  fontWeight: isSel
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // Right % labels
                      Positioned(
                        right: 10,
                        top: 70,
                        bottom: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              '100%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '80%',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '60%',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '40%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '20%',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '0%',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeeklyGraphPainter extends CustomPainter {
  final List<double> percents;
  final int selectedIndex;

  _WeeklyGraphPainter({required this.percents, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final n = percents.isEmpty ? 1 : percents.length;
    final dx = n <= 1 ? 0.0 : size.width / (n - 1);

    Offset point(int i) {
      final x = dx * i;
      final p = (i >= 0 && i < percents.length)
          ? percents[i].clamp(0.0, 1.0)
          : 0.0;
      final y = size.height * (1 - p);
      return Offset(x, y);
    }

    // highlight vertical bar
    if (n > 1) {
      final sel = selectedIndex.clamp(0, n - 1);
      final selX = dx * sel;
      final barPaint = Paint()..color = Colors.white.withValues(alpha: 0.20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(selX - 8, 0, 16, size.height),
          const Radius.circular(10),
        ),
        barPaint,
      );
    }

    // line path
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    if (percents.isNotEmpty) {
      final path = Path()..moveTo(point(0).dx, point(0).dy);
      for (int i = 1; i < percents.length; i++) {
        final p = point(i);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);

      // dots
      final dotPaint = Paint()..color = Colors.white;
      for (int i = 0; i < percents.length; i++) {
        final p = point(i);
        final isSel = i == selectedIndex;
        canvas.drawCircle(p, isSel ? 5 : 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyGraphPainter oldDelegate) {
    return oldDelegate.percents != percents ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _UpcomingWorkoutCard extends StatelessWidget {
  final String title;
  final String time;
  final Color color;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _UpcomingWorkoutCard({
    required this.title,
    required this.time,
    required this.color,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: color),
          ),
          const SizedBox(width: 14),
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
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: color, // ✅ replaced activeColor
          ),
        ],
      ),
    );
  }
}

class _WorkoutCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;

  const _WorkoutCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: () => Navigator.pushNamed(
        context,
        '/workout-detail',
        arguments: {'workoutName': title},
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'View more',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

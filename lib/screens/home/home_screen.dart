// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/bottom_nav.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String _workoutPeriod = "Weekly"; // Daily | Weekly | Monthly

  // ✅ stable jitter (avoid flicker every rebuild)
  int _stableRandomJitterForMinute(DateTime now, {required String uid}) {
    final seed =
        now.year * 100000000 +
        now.month * 1000000 +
        now.day * 10000 +
        now.hour * 100 +
        now.minute +
        uid.hashCode;
    final r = math.Random(seed);
    return r.nextInt(6) - 3; // -3..+2
  }

  // ------------------------------------------------------------------
  // ✅ Month schedules stream (range query)
  // ------------------------------------------------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> _streamSchedulesForMonth(
    String uid,
    DateTime month,
  ) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _firestoreService.streamSchedulesInRange(
      uid,
      start: start,
      end: end,
    );
  }

  // ------------------------------------------------------------------
  // ✅ Workout period picker
  // ------------------------------------------------------------------
  void _showWorkoutPeriodPicker() {
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
                  final isSelected = v == _workoutPeriod;
                  return ListTile(
                    title: Text(v),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF92A3FD),
                          )
                        : null,
                    onTap: () {
                      setState(() => _workoutPeriod = v);
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

  // ------------------------------------------------------------------
  // ✅ Heart rate logic:
  // - normal resting around 75-82
  // - higher for 90 minutes after completing a workout (schedule done OR activity workout)
  // ------------------------------------------------------------------
  int computeHeartRate({
    required String uid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> activityDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> scheduleDocs,
  }) {
    final now = DateTime.now();

    bool recentlyWorkedOut = false;

    // 1) If any schedule completed within last 90 mins
    for (final d in scheduleDocs) {
      final data = d.data();
      final isDone = (data['isDone'] as bool?) ?? false;
      if (!isDone) continue;

      final ts = safeTs(data['scheduledAt']);
      if (ts == null) continue;

      final t = ts.toDate();
      if (now.difference(t).inMinutes <= 90) {
        recentlyWorkedOut = true;
        break;
      }
    }

    // 2) Or activity type workout within last 90 mins (optional backup)
    if (!recentlyWorkedOut) {
      for (final d in activityDocs) {
        final data = d.data();
        final type = (data['type'] as String?) ?? '';
        if (type != 'workout') continue;

        final ts = safeTs(data['timestamp']);
        if (ts == null) continue;

        final t = ts.toDate();
        if (now.difference(t).inMinutes <= 90) {
          recentlyWorkedOut = true;
          break;
        }
      }
    }

    final base = recentlyWorkedOut ? 104 : 79;
    final jitter = _stableRandomJitterForMinute(now, uid: uid);
    return base + jitter;
  }

  // ------------------------------------------------------------------
  // ✅ Water timeline from activities type="water"
  // meta: { "ml": 250 }
  // ------------------------------------------------------------------
  List<Map<String, dynamic>> waterTimelineFromActivities(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final todayStart = startOfDay(DateTime.now());
    final todayEnd = endOfDay(DateTime.now());

    final items = <Map<String, dynamic>>[];

    for (final d in docs) {
      final data = d.data();
      if ((data['type'] as String?) != 'water') continue;

      final ts = safeTs(data['timestamp']);
      if (ts == null) continue;

      final t = ts.toDate();
      if (t.isBefore(todayStart) || !t.isBefore(todayEnd)) continue;

      final meta = (data['meta'] as Map?) ?? {};
      final ml = safeInt(meta['ml'], fallback: 0);

      items.add({'time': t, 'ml': ml});
    }

    items.sort(
      (a, b) => (a['time'] as DateTime).compareTo((b['time'] as DateTime)),
    );
    return items;
  }

  int sumWaterMlToday(List<Map<String, dynamic>> items) {
    int sum = 0;
    for (final i in items) {
      sum += (i['ml'] as int);
    }
    return sum;
  }

  // ------------------------------------------------------------------
  // ✅ Calories sum from meals today (field: calories)
  // ------------------------------------------------------------------
  int sumCaloriesToday(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    int sum = 0;

    for (final d in docs) {
      final data = d.data();

      // try multiple possible keys
      final raw = data['calories'] ?? data['kcal'] ?? data['energy'];

      // use safeNum so "250", "250 kcal", 250 all work
      final c = safeNum(raw, fallback: 0).round();
      sum += c;
    }

    return sum;
  }

  // ------------------------------------------------------------------
  // ✅ Workout progress from schedules (field: isDone)
  // ------------------------------------------------------------------
  double computeWorkoutProgress({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required int targetSessions,
  }) {
    if (targetSessions <= 0) return 0;
    int done = 0;
    for (final d in docs) {
      final isDone = (d.data()['isDone'] as bool?) ?? false;
      if (isDone) done++;
    }
    return (done / targetSessions).clamp(0.0, 1.0);
  }

  // ------------------------------------------------------------------
  // ✅ Pick water amount (ml)
  // ------------------------------------------------------------------
  Future<int?> _pickWaterMl() async {
    final options = <int>[150, 200, 250, 300, 500, 750, 1000];
    return showModalBottomSheet<int>(
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
                const SizedBox(height: 12),
                const Text(
                  'Add Water',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...options.map((ml) {
                  return ListTile(
                    leading: const Icon(Icons.water_drop_outlined),
                    title: Text('$ml ml'),
                    onTap: () => Navigator.pop(ctx, ml),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: SafeArea(
        child: user == null
            ? _signedOutView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Header is LIVE from user doc
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.streamUserData(user.uid),
                      builder: (context, snap) {
                        final data = snap.data?.data() ?? {};
                        final firstName =
                            (data['firstName'] as String?)?.trim() ?? '';
                        final lastName =
                            (data['lastName'] as String?)?.trim() ?? '';
                        final email = (data['email'] as String?)?.trim();

                        String displayName = '$firstName $lastName'.trim();
                        if (displayName.isEmpty) {
                          displayName = (email != null && email.contains('@'))
                              ? email.split('@')[0]
                              : 'User';
                        }

                        return _header(displayName);
                      },
                    ),

                    const SizedBox(height: 25),

                    // ✅ BMI from user profile (LIVE) — FIXED (reads ProfileSetup keys + string clean)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.streamUserData(user.uid),
                      builder: (context, userSnap) {
                        final data = userSnap.data?.data() ?? {};

                        // ✅ ProfileSetupScreen saves: height, weight, heightUnit, weightUnit
                        // ✅ fallback for old keys (if any)
                        final heightVal = safeNum(
                          data['height'],
                          fallback: safeNum(data['heightCm'], fallback: 0),
                        );
                        final weightVal = safeNum(
                          data['weight'],
                          fallback: safeNum(data['weightKg'], fallback: 0),
                        );

                        final rawHeightUnit = (data['heightUnit'] as String?)
                            ?.trim()
                            .toUpperCase();
                        final rawWeightUnit = (data['weightUnit'] as String?)
                            ?.trim()
                            .toUpperCase();

                        // if using new fields height/weight -> units matter
                        final usingNewHeight = data.containsKey('height');
                        final usingNewWeight = data.containsKey('weight');

                        final heightUnit =
                            (usingNewHeight ? rawHeightUnit : 'CM') ?? 'CM';
                        final weightUnit =
                            (usingNewWeight ? rawWeightUnit : 'KG') ?? 'KG';

                        // ✅ convert to CM & KG for BMI formula
                        final heightCm = heightUnit == 'FT'
                            ? (heightVal * 30.48)
                            : heightVal;
                        final weightKg = weightUnit == 'LB'
                            ? (weightVal / 2.2046226218)
                            : weightVal;

                        final bmiRes = computeBMI(
                          heightCm: heightCm <= 0 ? null : heightCm,
                          weightKg: weightKg <= 0 ? null : weightKg,
                        );

                        final bmiText = bmiRes == null
                            ? '--'
                            : bmiRes.bmi.toStringAsFixed(1);
                        final message = bmiRes == null
                            ? 'Add height & weight in your profile'
                            : bmiRes.message;

                        final progress = bmiRes == null
                            ? 0.0
                            : bmiToProgress(bmiRes.bmi);

                        return _bmiCard(
                          bmiText: bmiText,
                          message: message,
                          progress: progress,

                          // ✅ disable until you add /bmi-details route
                          onViewMore: null,
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ✅ Today Target (LIVE)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.streamDailyTargets(user.uid),
                      builder: (context, tSnap) {
                        final t = tSnap.data?.data() ?? {};

                        final waterTargetL = safeNum(
                          t['waterLitersTarget'],
                          fallback: 3.7,
                        );
                        final caloriesTarget = safeInt(
                          t['caloriesTarget'],
                          fallback: 2500,
                        );
                        final sleepTargetMin = safeInt(
                          t['sleepMinutesTarget'],
                          fallback: 8 * 60,
                        );

                        return _todayTargetCard(
                          subtitle:
                              'Water ${waterTargetL.toStringAsFixed(1)}L • Sleep ${formatMinutesToHM(sleepTargetMin)} • Calories $caloriesTarget',
                          onCheck: () =>
                              Navigator.pushNamed(context, '/activity-tracker'),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Activity Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ✅ We need BOTH: activities + targets + schedules for heart/water/calories
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.streamLatestActivities(
                        user.uid,
                        limit: 80,
                      ),
                      builder: (context, actSnap) {
                        final activityDocs = actSnap.data?.docs ?? const [];

                        // last update label
                        String lastUpdate = '—';
                        if (activityDocs.isNotEmpty) {
                          final ts = safeTs(
                            activityDocs.first.data()['timestamp'],
                          );
                          if (ts != null) {
                            final mins = DateTime.now()
                                .difference(ts.toDate())
                                .inMinutes;
                            lastUpdate = mins <= 1
                                ? 'just now'
                                : '${mins}mins ago';
                          }
                        }

                        final waterItems = waterTimelineFromActivities(
                          activityDocs,
                        );
                        final waterMlToday = sumWaterMlToday(waterItems);

                        return StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>
                        >(
                          stream: _firestoreService.streamDailyTargets(
                            user.uid,
                          ),
                          builder: (context, targetSnap) {
                            final t = targetSnap.data?.data() ?? {};
                            final waterTargetL = safeNum(
                              t['waterLitersTarget'],
                              fallback: 3.7,
                            );
                            final caloriesTarget = safeInt(
                              t['caloriesTarget'],
                              fallback: 2500,
                            );
                            final sleepTargetMin = safeInt(
                              t['sleepMinutesTarget'],
                              fallback: 8 * 60,
                            );

                            return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>
                            >(
                              stream: _streamSchedulesForMonth(
                                user.uid,
                                DateTime.now(),
                              ),
                              builder: (context, schedSnap) {
                                final scheduleDocs =
                                    schedSnap.data?.docs ?? const [];

                                final bpm = computeHeartRate(
                                  uid: user.uid,
                                  activityDocs: activityDocs,
                                  scheduleDocs: scheduleDocs,
                                );

                                return Column(
                                  children: [
                                    _heartRateCard(
                                      bpm: bpm,
                                      tag: bpm >= 100 ? 'High' : 'In Range',
                                      lastUpdateLabel: lastUpdate,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/activity-tracker',
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _waterCard(
                                            waterTargetL: waterTargetL,
                                            waterMlToday: waterMlToday,
                                            timeline: waterItems,
                                            onAdd: () async {
                                              final picked =
                                                  await _pickWaterMl();
                                              if (picked == null) return;

                                              await _firestoreService.addWater(
                                                uid: user.uid,
                                                ml: picked,
                                                when: DateTime.now(),
                                              );
                                            },
                                            onTap: () => Navigator.pushNamed(
                                              context,
                                              '/activity-tracker',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _sleepCard(
                                                sleepMinutes: sleepTargetMin,
                                                onTap: () =>
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/sleep-tracker',
                                                    ),
                                              ),
                                              const SizedBox(height: 15),
                                              StreamBuilder<
                                                QuerySnapshot<
                                                  Map<String, dynamic>
                                                >
                                              >(
                                                stream: _firestoreService
                                                    .streamMealsForDay(
                                                      user.uid,
                                                      day: DateTime.now(),
                                                    ),
                                                builder: (context, mealsSnap) {
                                                  final mealDocs =
                                                      mealsSnap.data?.docs ??
                                                      const [];
                                                  final consumed =
                                                      sumCaloriesToday(
                                                        mealDocs,
                                                      );

                                                  final target = caloriesTarget;
                                                  final left =
                                                      (target - consumed).clamp(
                                                        0,
                                                        target,
                                                      );

                                                  final p = target == 0
                                                      ? 0.0
                                                      : (consumed / target)
                                                            .clamp(0.0, 1.0);

                                                  return _caloriesCard(
                                                    consumed: consumed,
                                                    target: target,
                                                    left: left,
                                                    progress: p,
                                                    onTap: () =>
                                                        Navigator.pushNamed(
                                                          context,
                                                          '/meal-planner',
                                                        ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    _mealPlannerCard(
                      onView: () =>
                          Navigator.pushNamed(context, '/meal-planner'),
                    ),

                    const SizedBox(height: 25),

                    // ✅ Workout Progress header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Workout Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showWorkoutPeriodPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF92A3FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _workoutPeriod,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
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
                    const SizedBox(height: 15),

                    _workoutProgressSection(user.uid),

                    const SizedBox(height: 25),

                    // ✅ Latest Workout (3 types)
                    _latestWorkoutSection(user.uid),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // -------------------------
  // UI widgets
  // -------------------------

  Widget _signedOutView() {
    return const Center(child: Text('Please login to view your dashboard.'));
  }

  Widget _header(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            Text(
              userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notification'),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _bmiCard({
    required String bmiText,
    required String message,
    required double progress,
    required VoidCallback? onViewMore,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BMI (Body Mass Index)',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: onViewMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC58BF2),
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.25,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View More',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(90, 90),
                  painter: BMIPieChartPainter(progress: progress),
                ),
                Center(
                  child: Text(
                    bmiText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayTargetCard({
    required String subtitle,
    required VoidCallback onCheck,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today Target',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onCheck,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF92A3FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              elevation: 0,
            ),
            child: const Text(
              'Check',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heartRateCard({
    required int bpm,
    required String tag,
    required String lastUpdateLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF92A3FD).withValues(alpha: 0.2),
              const Color(0xFF9DCEFF).withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heart Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$bpm BPM',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF69B4),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC58BF2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastUpdateLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 60,
              child: CustomPaint(
                painter: HeartRateGraphPainter(),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waterCard({
    required double waterTargetL,
    required int waterMlToday,
    required List<Map<String, dynamic>> timeline,
    required VoidCallback onAdd,
    required VoidCallback onTap,
  }) {
    final targetMl = (waterTargetL * 1000).round();

    // ✅ raw ratio (can be > 1 if user drinks more than target)
    final rawRatio = targetMl <= 0 ? 0.0 : (waterMlToday / targetMl);

    // ✅ bar fill is capped 0..1 so it never “overfills”
    final fill = rawRatio.clamp(0.0, 1.0);

    // ✅ label percent (choose one)
    // A) cap at 100%:
    final percentLabel = '${(fill * 100).round()}%';

    // If you prefer showing OVER target like 173% uncomment this and replace percentLabel above:
    // final percentLabel = '${(rawRatio * 100).round()}%';

    final slotLabels = <String>[
      '6am - 8am',
      '9am - 11am',
      '11am - 2pm',
      '2pm - 5pm',
      '5pm - now',
    ];
    final slotTotals = List<int>.filled(5, 0);

    for (final w in timeline) {
      final t = w['time'] as DateTime;
      final ml = w['ml'] as int;
      final h = t.hour;

      int slot = 4;
      if (h >= 6 && h < 8) {
        slot = 0;
      } else if (h >= 9 && h < 11) {
        slot = 1;
      } else if (h >= 11 && h < 14) {
        slot = 2;
      } else if (h >= 14 && h < 17) {
        slot = 3;
      } else {
        slot = 4;
      }
      slotTotals[slot] += ml;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 270,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Water Intake',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${(waterMlToday / 1000).toStringAsFixed(1)} L',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92A3FD),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Today: $waterMlToday ml / $targetMl ml',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),

            // timeline list (no left bar)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(5, (i) {
                  return _timeLabel(slotLabels[i], '${slotTotals[i]}ml');
                }),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ progress bar + add button on the same row
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(
                        value: fill,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFC58BF2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onAdd,
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFFC58BF2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ✅ percent + target label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  percentLabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  '${waterTargetL.toStringAsFixed(1)}L target',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sleepCard({required int sleepMinutes, required VoidCallback onTap}) {
    final label = sleepMinutes < 420
        ? 'Not enough'
        : (sleepMinutes > 600 ? 'Too much' : 'Good');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sleep',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              formatMinutesToHM(sleepMinutes),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92A3FD),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                painter: SleepWavePainter(),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caloriesCard({
    required int consumed,
    required int target,
    required int left,
    required double progress,
    required VoidCallback onTap,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // ✅ remove risky tight height, give a bit more space
        height: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calories',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '$consumed KCal',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92A3FD),
              ),
            ),
            Text(
              'Target $target',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 8),

            // ✅ This prevents overflow: circle always fits in remaining space
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: safeProgress,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF92A3FD),
                        ),
                      ),
                      Text(
                        '$left\nleft',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealPlannerCard({required VoidCallback onView}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC58BF2), Color(0xFFEEA4CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meal Nutrition Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get started with tracking your meals',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Color(0xFFC58BF2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          const Icon(Icons.restaurant, color: Colors.white, size: 60),
        ],
      ),
    );
  }

  Widget _timeLabel(String time, String amount) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFC58BF2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$time - $amount',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // -------------------------
  // ✅ Workout progress section
  // -------------------------
  Widget _workoutProgressSection(String uid) {
    final now = DateTime.now();

    if (_workoutPeriod == 'Daily') {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.streamSchedulesForDay(uid, day: now),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? const [];
          final progress = computeWorkoutProgress(
            docs: docs,
            targetSessions: 1,
          );

          return _workoutProgressCard(
            title: 'My Daily Target',
            percentLabel: '${(progress * 100).round()}%',
            bars: _weekBarsFromDoneDocs(docs, now),
            onTap: () => Navigator.pushNamed(context, '/workout-tracker'),
          );
        },
      );
    }

    if (_workoutPeriod == 'Weekly') {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamSchedulesForMonth(uid, now),
        builder: (context, snap) {
          final all = snap.data?.docs ?? const [];
          final wStart = startOfWeek(now);
          final wEnd = endOfWeek(now);

          final weekDocs = all.where((d) {
            final ts = safeTs(d.data()['scheduledAt']);
            if (ts == null) return false;
            final t = ts.toDate();
            return (t.isAfter(wStart) || t.isAtSameMomentAs(wStart)) &&
                t.isBefore(wEnd);
          }).toList();

          final progress = computeWorkoutProgress(
            docs: weekDocs,
            targetSessions: 3,
          );

          return _workoutProgressCard(
            title: 'My Weekly Target',
            percentLabel: '${(progress * 100).round()}%',
            bars: _weekBarsFromDoneDocs(weekDocs, now),
            onTap: () => Navigator.pushNamed(context, '/workout-tracker'),
          );
        },
      );
    }

    // Monthly
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _streamSchedulesForMonth(uid, now),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final progress = computeWorkoutProgress(docs: docs, targetSessions: 12);

        return _workoutProgressCard(
          title: 'My Monthly Target',
          percentLabel: '${(progress * 100).round()}%',
          bars: _weekBarsFromDoneDocs(docs, now),
          onTap: () => Navigator.pushNamed(context, '/workout-tracker'),
        );
      },
    );
  }

  List<_BarPoint> _weekBarsFromDoneDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime now,
  ) {
    // Use Sunday as first bar
    final sunday = startOfWeek(now).subtract(const Duration(days: 1));
    final counts = List<int>.filled(7, 0);

    for (final d in docs) {
      final data = d.data();
      final isDone = (data['isDone'] as bool?) ?? false;
      if (!isDone) continue;

      final ts = safeTs(data['scheduledAt']);
      if (ts == null) continue;

      final t = ts.toDate();

      for (int i = 0; i < 7; i++) {
        final day = sunday.add(Duration(days: i));
        final s = startOfDay(day);
        final e = endOfDay(day);

        if ((t.isAfter(s) || t.isAtSameMomentAs(s)) && t.isBefore(e)) {
          counts[i] += 1;
          break;
        }
      }
    }

    final maxC = counts.fold<int>(1, (p, c) => c > p ? c : p);
    final labels = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return List.generate(7, (i) {
      return _BarPoint(
        label: labels[i],
        value: (counts[i] / maxC).clamp(0.0, 1.0),
        isToday: labels[i] == _dayLabel(now.weekday),
      );
    });
  }

  String _dayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return 'Sun';
    }
  }

  Widget _workoutProgressCard({
    required String title,
    required String percentLabel,
    required List<_BarPoint> bars,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240, // ✅ Increased from 200 to 240
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF92A3FD).withValues(alpha: 0.15),
              const Color(0xFF9DCEFF).withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      percentLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92A3FD),
                      ),
                    ),
                  ],
                ),
                Text(
                  '100%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 15), // ✅ Reduced from 20 to 15
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars
                    .map((b) => _bar(b.label, b.value, isToday: b.isToday))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Also update the _bar method to use a smaller max height:

  Widget _bar(String day, double value, {bool isToday = false}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            height: 80 * value, // ✅ Reduced from 90 to 80
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      colors: [Color(0xFFC58BF2), Color(0xFF92A3FD)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : LinearGradient(
                      colors: [
                        const Color(0xFF92A3FD).withValues(alpha: 0.30),
                        const Color(0xFF92A3FD).withValues(alpha: 0.30),
                      ],
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6), // ✅ Reduced from 8 to 6
          Text(
            day,
            style: TextStyle(
              fontSize: 11,
              color: isToday ? const Color(0xFF92A3FD) : Colors.grey.shade600,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // ✅ Latest workout section (3 fixed workout types)
  // -------------------------
  Widget _latestWorkoutSection(String uid) {
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _streamSchedulesForMonth(uid, now),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? const []).toList();

        // latest first
        docs.sort((a, b) {
          final ta =
              safeTs(a.data()['scheduledAt'])?.toDate() ?? DateTime(1970);
          final tb =
              safeTs(b.data()['scheduledAt'])?.toDate() ?? DateTime(1970);
          return tb.compareTo(ta);
        });

        final doneDocs = docs
            .where((d) => (d.data()['isDone'] as bool?) ?? false)
            .toList();

        QueryDocumentSnapshot<Map<String, dynamic>>? latestOf(String title) {
          for (final d in doneDocs) {
            final t = ((d.data()['workoutTitle'] as String?) ?? '').trim();
            if (t.toLowerCase() == title.toLowerCase()) return d;
          }
          return null;
        }

        final types = const [
          'Fullbody Workout',
          'Lowerbody Workout',
          'AB Workout',
        ];

        final cards = types.map((t) => latestOf(t)).toList();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Workout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/workout-tracker'),
                  child: Text(
                    'See more',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...List.generate(types.length, (i) {
              final typeTitle = types[i];
              final d = cards[i];

              if (d == null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _workoutItem(
                    title: typeTitle,
                    subtitle: 'Not completed yet',
                    progress: 0.0,
                    color: _colorForWorkout(typeTitle),
                    icon: _iconForWorkout(typeTitle),
                    onTap: () =>
                        Navigator.pushNamed(context, '/workout-tracker'),
                  ),
                );
              }

              final data = d.data();
              final mins = safeInt(data['durationMinutes'], fallback: 20);
              final burn = mins * 8;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _workoutItem(
                  title: typeTitle,
                  subtitle: '$burn Calories Burn | $mins minutes',
                  progress: 1.0,
                  color: _colorForWorkout(typeTitle),
                  icon: _iconForWorkout(typeTitle),
                  onTap: () => _openWorkoutDetail(typeTitle),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // -------------------------
  // ✅ Workout item card
  // -------------------------
  Widget _workoutItem({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
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
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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

  IconData _iconForWorkout(String title) {
    final t = title.toLowerCase();
    if (t.contains('cardio') || t.contains('run')) {
      return Icons.directions_run;
    }
    if (t.contains('leg') || t.contains('lower')) {
      return Icons.airline_seat_legroom_extra;
    }
    if (t.contains('arm') || t.contains('upper')) {
      return Icons.fitness_center;
    }
    if (t.contains('abs') || t.contains('ab') || t.contains('core')) {
      return Icons.self_improvement;
    }
    if (t.contains('full')) {
      return Icons.sports_gymnastics;
    }
    return Icons.sports_gymnastics;
  }

  Color _colorForWorkout(String title) {
    final t = title.toLowerCase();
    if (t.contains('cardio') || t.contains('run')) {
      return const Color(0xFFC58BF2);
    }
    if (t.contains('leg') || t.contains('lower')) {
      return const Color(0xFF92A3FD);
    }
    if (t.contains('abs') || t.contains('ab') || t.contains('core')) {
      return const Color(0xFFEEA4CE);
    }
    if (t.contains('full')) {
      return const Color(0xFF9DCEFF);
    }
    return const Color(0xFF9DCEFF);
  }

  void _openWorkoutDetail(String workoutName) {
    Navigator.pushNamed(
      context,
      '/workout-detail',
      arguments: {'workoutName': workoutName},
    );
  }
} // ✅ End of _HomeScreenState class
// ===================================================================
// ✅ HELPERS (TOP-LEVEL)
// ===================================================================

Timestamp? safeTs(dynamic v) {
  if (v is Timestamp) return v;
  return null;
}

double safeNum(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();

  if (v is String) {
    final cleaned = v
        .trim()
        .replaceAll(',', '.') // 60,5 -> 60.5
        .replaceAll(RegExp(r'[^0-9.\-]'), ''); // remove CM, KG, spaces etc.
    return double.tryParse(cleaned) ?? fallback;
  }

  return fallback;
}

int safeInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

DateTime startOfWeek(DateTime d) {
  // Monday start
  final diff = d.weekday - DateTime.monday;
  return startOfDay(d.subtract(Duration(days: diff)));
}

DateTime endOfWeek(DateTime d) => startOfWeek(d).add(const Duration(days: 7));

String formatMinutesToHM(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

// ===================================================================
// ✅ BMI computation (TOP-LEVEL)
// ===================================================================

class BMIResult {
  final double bmi;
  final String category;
  final String message;

  const BMIResult({
    required this.bmi,
    required this.category,
    required this.message,
  });
}

BMIResult? computeBMI({required double? weightKg, required double? heightCm}) {
  if (weightKg == null || heightCm == null) return null;
  if (weightKg <= 0 || heightCm <= 0) return null;

  final h = heightCm / 100.0;
  final bmi = weightKg / (h * h);

  if (bmi < 18.5) {
    return BMIResult(
      bmi: bmi,
      category: 'Underweight',
      message: 'You are below the healthy range.',
    );
  } else if (bmi < 25) {
    return BMIResult(
      bmi: bmi,
      category: 'Normal',
      message: 'You are in a healthy range.',
    );
  } else if (bmi < 30) {
    return BMIResult(
      bmi: bmi,
      category: 'Overweight',
      message: 'You are above the healthy range.',
    );
  } else {
    return BMIResult(
      bmi: bmi,
      category: 'Obese',
      message: 'You are significantly above the healthy range.',
    );
  }
}

double bmiToProgress(double bmi) {
  // Map 10..40 → 0..1
  final p = (bmi - 10) / 30.0;
  return p.clamp(0.0, 1.0);
}

// ===================================================================
// ✅ MODELS (TOP-LEVEL)
// ===================================================================

class _BarPoint {
  final String label;
  final double value;
  final bool isToday;

  const _BarPoint({
    required this.label,
    required this.value,
    required this.isToday,
  });
}

// ===================================================================
// ✅ PAINTERS (TOP-LEVEL)
// ===================================================================

class BMIPieChartPainter extends CustomPainter {
  final double progress; // 0..1

  BMIPieChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintBg = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final paintFg = Paint()
      ..color = const Color(0xFFFF69B4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paintBg);

    final sweep = (math.pi * 2) * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      true,
      paintFg,
    );
  }

  @override
  bool shouldRepaint(covariant BMIPieChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class HeartRateGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF92A3FD).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 2) {
      final p = x / size.width;
      final y = size.height / 2 + math.sin(p * math.pi * 6) * 20;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SleepWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF92A3FD).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int lineNum = 0; lineNum < 3; lineNum++) {
      final path = Path();
      final yOffset = lineNum * 3.0;

      path.moveTo(0, size.height / 2 + yOffset);

      for (double x = 0; x <= size.width; x += 2) {
        final p = x / size.width;
        final y = size.height / 2 + math.sin(p * math.pi * 4) * 5 + yOffset;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

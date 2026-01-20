import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with SingleTickerProviderStateMixin {
  // NutriFit palette
  static const Color kPrimary = Color(0xFF92A3FD);
  static const Color kSecondary = Color(0xFF9DCEFF);
  static const Color kAccent = Color(0xFFC58BF2);

  final AuthService _authService = AuthService();
  late final AnimationController _controller;

  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = _authService.currentUser?.uid;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();

    // Optional demo seed (comment out if you don’t want)
    if (_uid != null) {
      _seedSleepDataIfEmpty(_uid!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- FIRESTORE PATHS ----------------

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleepSettings')
        .doc('main');
  }

  CollectionReference<Map<String, dynamic>> _logsCol(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleepLogs');
  }

  // ---------------- DEFAULTS ----------------

  _SleepSettings _defaults() {
    return _SleepSettings(
      bedtimeEnabled: true,
      alarmEnabled: true,
      bedtime: const TimeOfDay(hour: 21, minute: 0),
      sleepDuration: const Duration(hours: 8, minutes: 30),
      repeat: const [true, true, true, true, true, false, false], // Mon..Sun
      vibrate: true,
    );
  }

  // ---------------- DEMO SEED (OPTIONAL) ----------------

  Future<void> _seedSleepDataIfEmpty(String uid) async {
    try {
      // Ensure settings exist
      final s = await _settingsDoc(uid).get();
      if (!s.exists) {
        await _settingsDoc(uid).set(_defaults().toMap());
      }

      // Ensure logs exist
      final logs = await _logsCol(uid).limit(1).get();
      if (logs.docs.isNotEmpty) return;

      final now = DateTime.now();
      final rand = math.Random(7);

      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < 7; i++) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
        // Random ~ 6h30m to 9h
        final minutes = 390 + rand.nextInt(160); // 390..549
        final ref = _logsCol(uid).doc();
        batch.set(ref, {
          'date': Timestamp.fromDate(day),
          'sleepMinutes': minutes,
        });
      }
      await batch.commit();
    } catch (_) {
      // ignore demo seed errors
    }
  }

  // ---------------- HELPERS ----------------

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'am' : 'pm';
    return '$hour:$mm$suffix';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (m == 0) return '${h}hours';
    return '${h}hours ${m}minutes';
  }

  String _formatRepeatShort(List<bool> repeat) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selected = <String>[];
    for (var i = 0; i < 7; i++) {
      if (repeat[i]) selected.add(names[i]);
    }
    if (selected.isEmpty) return 'Once';
    if (selected.length == 7) return 'Everyday';

    final weekdays = repeat.sublist(0, 5).every((v) => v) && !repeat[5] && !repeat[6];
    if (weekdays) return 'Mon to Fri';

    final weekend = !repeat.sublist(0, 5).any((v) => v) && repeat[5] && repeat[6];
    if (weekend) return 'Sat & Sun';

    return selected.join(', ');
  }

  TimeOfDay _alarmTime(TimeOfDay bedtime, Duration sleepDuration) {
    final totalMinutes = bedtime.hour * 60 + bedtime.minute + sleepDuration.inMinutes;
    final m = totalMinutes % (24 * 60);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  int _weekdayIndexMon0(DateTime date) {
    // Dart weekday: Mon=1..Sun=7
    return (date.weekday - 1) % 7;
  }

  String _dayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[_weekdayIndexMon0(date)];
  }

  // ---------------- SAVE/UPDATE ----------------

  Future<void> _updateSettings(String uid, Map<String, dynamic> patch) async {
    await _settingsDoc(uid).set(patch, SetOptions(merge: true));
  }

  Future<void> _openSchedule(_SleepSettings settings) async {
    final result = await Navigator.pushNamed(
      context,
      '/sleep-schedule',
      arguments: {
        'bedtime': settings.bedtime,
        'sleepDuration': settings.sleepDuration,
        'repeat': settings.repeat,
        'vibrate': settings.vibrate,
        'bedtimeEnabled': settings.bedtimeEnabled,
        'alarmEnabled': settings.alarmEnabled,
      },
    );

    final uid = _uid;
    if (!mounted || uid == null) return;

    if (result is Map) {
      final next = settings.copyWithFromResult(result);
      await _updateSettings(uid, next.toMap());
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Sleep Tracker',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Please login first.')),
      );
    }

    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _settingsDoc(uid).snapshots(),
      builder: (context, settingsSnap) {
        final settings = settingsSnap.hasData && settingsSnap.data!.exists
            ? _SleepSettings.fromMap(settingsSnap.data!.data()!)
            : _defaults();

        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);
        final weekStart = todayMidnight.subtract(const Duration(days: 6));

        final logsQuery = _logsCol(uid)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .orderBy('date', descending: false);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: logsQuery.snapshots(),
          builder: (context, logsSnap) {
            // Build week data Mon..Sun-like for last 7 days (actual date order)
            final weekDates = List.generate(7, (i) => weekStart.add(Duration(days: i)));
            final minutesByDay = <String, int>{}; // key: yyyy-mm-dd

            if (logsSnap.hasData) {
              for (final d in logsSnap.data!.docs) {
                final data = d.data();
                final ts = data['date'];
                final min = data['sleepMinutes'];
                if (ts is Timestamp && min is int) {
                  final dt = ts.toDate();
                  final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                  minutesByDay[key] = min;
                }
              }
            }

            final weekMinutes = weekDates.map((dt) {
              final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              return minutesByDay[key] ?? 0;
            }).toList();

            // Sleep quality % based on ideal 8h30m
            final idealMin = const Duration(hours: 8, minutes: 30).inMinutes;
            final curMin = settings.sleepDuration.inMinutes;
            final percent = (curMin / idealMin).clamp(0.0, 1.0);
            final percentLabel = '${(percent * 100).round()}%';

            final alarm = _alarmTime(settings.bedtime, settings.sleepDuration);

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: const Text(
                  'Sleep Tracker',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                centerTitle: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
              body: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weekly Graph
                        Container(
                          height: 220,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: const Size(double.infinity, 180),
                                painter: WeeklySleepGraphPainter(
                                  minutes: weekMinutes,
                                  labels: weekDates.map(_dayLabel).toList(),
                                  highlightIndex: 6, // last day = today in this range
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _IncreaseChip(
                                    percentText: _calcIncreaseChipText(weekMinutes),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Last Night Sleep Card -> open schedule
                        _PressScale(
                          onTap: () => _openSchedule(settings),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPrimary, kSecondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last Night Sleep',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDuration(settings.sleepDuration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CustomPaint(
                                  size: const Size(double.infinity, 40),
                                  painter: SleepWavePatternPainter(),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Quality $percentLabel • ${_formatRepeatShort(settings.repeat)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Daily Sleep Schedule
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daily Sleep Schedule',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              ElevatedButton(
                                onPressed: () => _openSchedule(settings),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Check',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Today Schedule',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        _buildScheduleItem(
                          icon: Icons.bed_outlined,
                          iconColor: kPrimary,
                          title: 'Bedtime',
                          time: _formatTime(settings.bedtime),
                          subtitle: 'Repeat: ${_formatRepeatShort(settings.repeat)}',
                          isEnabled: settings.bedtimeEnabled,
                          onToggle: (v) async {
                            await _updateSettings(uid, {'bedtimeEnabled': v});
                          },
                          onTap: () => _openSchedule(settings),
                        ),
                        const SizedBox(height: 14),
                        _buildScheduleItem(
                          icon: Icons.alarm,
                          iconColor: Colors.red,
                          title: 'Alarm',
                          time: _formatTime(alarm),
                          subtitle: 'Vibrate: ${settings.vibrate ? "On" : "Off"}',
                          isEnabled: settings.alarmEnabled,
                          onToggle: (v) async {
                            await _updateSettings(uid, {'alarmEnabled': v});
                          },
                          onTap: () => _openSchedule(settings),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _calcIncreaseChipText(List<int> weekMinutes) {
    // Compare last 2 days average vs first 2 days average for a simple “increase”
    if (weekMinutes.length < 4) return '0% increase';
    final firstAvg = (weekMinutes[0] + weekMinutes[1]) / 2.0;
    final lastAvg = (weekMinutes[5] + weekMinutes[6]) / 2.0;
    if (firstAvg <= 0) return '0% increase';

    final pct = (((lastAvg - firstAvg) / firstAvg) * 100).round();
    if (pct <= 0) return '${pct.abs()}% decrease';
    return '$pct% increase';
  }

  Widget _buildScheduleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTap,
  }) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$title, ',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: onToggle,
              activeThumbColor: kAccent,
            ),
            const SizedBox(width: 6),
            Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

/* ------------------ SETTINGS MODEL ------------------ */

class _SleepSettings {
  final bool bedtimeEnabled;
  final bool alarmEnabled;
  final TimeOfDay bedtime;
  final Duration sleepDuration;
  final List<bool> repeat; // Mon..Sun
  final bool vibrate;

  const _SleepSettings({
    required this.bedtimeEnabled,
    required this.alarmEnabled,
    required this.bedtime,
    required this.sleepDuration,
    required this.repeat,
    required this.vibrate,
  });

  Map<String, dynamic> toMap() {
    return {
      'bedtimeEnabled': bedtimeEnabled,
      'alarmEnabled': alarmEnabled,
      'bedtimeMinutes': bedtime.hour * 60 + bedtime.minute,
      'sleepMinutes': sleepDuration.inMinutes,
      'repeat': repeat,
      'vibrate': vibrate,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static _SleepSettings fromMap(Map<String, dynamic> data) {
    final bedtimeMin = (data['bedtimeMinutes'] is int) ? data['bedtimeMinutes'] as int : 21 * 60;
    final sleepMin = (data['sleepMinutes'] is int) ? data['sleepMinutes'] as int : (8 * 60 + 30);

    final repeatRaw = data['repeat'];
    final repeat = (repeatRaw is List && repeatRaw.length == 7)
        ? repeatRaw.map((e) => e == true).toList()
        : <bool>[true, true, true, true, true, false, false];

    return _SleepSettings(
      bedtimeEnabled: data['bedtimeEnabled'] == true,
      alarmEnabled: data['alarmEnabled'] != false,
      bedtime: TimeOfDay(hour: bedtimeMin ~/ 60, minute: bedtimeMin % 60),
      sleepDuration: Duration(minutes: sleepMin),
      repeat: repeat,
      vibrate: data['vibrate'] != false,
    );
  }

  _SleepSettings copyWithFromResult(Map result) {
    TimeOfDay bedtime = this.bedtime;
    Duration sleepDuration = this.sleepDuration;
    List<bool> repeat = this.repeat;
    bool vibrate = this.vibrate;
    bool bedtimeEnabled = this.bedtimeEnabled;
    bool alarmEnabled = this.alarmEnabled;

    final bt = result['bedtime'];
    final sd = result['sleepDuration'];
    final rp = result['repeat'];
    final vb = result['vibrate'];
    final be = result['bedtimeEnabled'];
    final ae = result['alarmEnabled'];

    if (bt is TimeOfDay) bedtime = bt;
    if (sd is Duration) sleepDuration = sd;
    if (rp is List<bool> && rp.length == 7) repeat = List<bool>.from(rp);
    if (vb is bool) vibrate = vb;
    if (be is bool) bedtimeEnabled = be;
    if (ae is bool) alarmEnabled = ae;

    return _SleepSettings(
      bedtimeEnabled: bedtimeEnabled,
      alarmEnabled: alarmEnabled,
      bedtime: bedtime,
      sleepDuration: sleepDuration,
      repeat: repeat,
      vibrate: vibrate,
    );
  }
}

/* ------------------ GRAPH UI ------------------ */

class WeeklySleepGraphPainter extends CustomPainter {
  final List<int> minutes; // 7 values
  final List<String> labels; // 7 labels
  final int highlightIndex;

  WeeklySleepGraphPainter({
    required this.minutes,
    required this.labels,
    required this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - 30; // keep right padding for y labels
    final chartH = size.height;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Grid + hour labels (0h..10h)
    const maxHours = 10;
    for (var i = 0; i <= 5; i++) {
      final y = chartH - (chartH * i / 5);

      canvas.drawLine(
        Offset(0, y),
        Offset(chartW, y),
        Paint()
          ..color = Colors.grey.shade200
          ..strokeWidth = 1,
      );

      final hour = (maxHours * i / 5).round();
      textPainter.text = TextSpan(
        text: '${hour}h',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(chartW + 4, y - 9));
    }

    // Day labels
    for (var i = 0; i < labels.length; i++) {
      final x = chartW * i / (labels.length - 1);
      final isHi = i == highlightIndex;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isHi ? const Color(0xFF92A3FD) : Colors.grey.shade500,
          fontSize: 12,
          fontWeight: isHi ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 10, chartH + 5));
    }

    // Convert minutes -> normalized Y (0..maxHours)
    double yForMinutes(int min) {
      final h = (min / 60.0).clamp(0.0, maxHours.toDouble());
      final t = h / maxHours;
      return chartH - (t * chartH);
    }

    // Area fill
    final areaPath = Path()..moveTo(0, chartH);
    for (var i = 0; i < minutes.length; i++) {
      final x = chartW * i / (minutes.length - 1);
      final y = yForMinutes(minutes[i]);
      areaPath.lineTo(x, y);
    }
    areaPath.lineTo(chartW, chartH);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF92A3FD).withValues(alpha: 0.30),
          const Color(0xFF9DCEFF).withValues(alpha: 0.10),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, chartW, chartH));

    canvas.drawPath(areaPath, areaPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = const Color(0xFF92A3FD)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    for (var i = 0; i < minutes.length; i++) {
      final x = chartW * i / (minutes.length - 1);
      final y = yForMinutes(minutes[i]);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Highlight vertical line
    final hiX = chartW * highlightIndex / (minutes.length - 1);
    canvas.drawLine(
      Offset(hiX, 0),
      Offset(hiX, chartH),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant WeeklySleepGraphPainter oldDelegate) {
    return oldDelegate.minutes != minutes ||
        oldDelegate.labels != labels ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}

class SleepWavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var lineNum = 0; lineNum < 3; lineNum++) {
      final path = Path();
      final yOffset = lineNum * 5.0;

      path.moveTo(0, size.height / 2 + yOffset);
      for (var i = 0.0; i <= size.width; i += 2) {
        final progress = i / size.width;
        final y =
            size.height / 2 + math.sin(progress * math.pi * 4) * 8 + yOffset;
        path.lineTo(i, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ------------------ SMALL UI WIDGETS ------------------ */

class _IncreaseChip extends StatelessWidget {
  final String percentText;
  const _IncreaseChip({required this.percentText});

  @override
  Widget build(BuildContext context) {
    final isIncrease = percentText.contains('increase');
    final c = isIncrease ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.shade100, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            percentText,
            style: TextStyle(
              color: c.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: c.shade700,
          ),
        ],
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

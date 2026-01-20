import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../services/firestore_service.dart';

class WorkoutScheduleScreen extends StatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();

  late final String _uid;

  DateTime _selectedDate = DateTime.now();

  String? _selectedScheduleId;
  Map<String, dynamic>? _selectedSchedule;

  // Details popup animation
  late final AnimationController _detailsCtrl;
  late final Animation<double> _detailsFade;
  late final Animation<double> _detailsScale;

  // Predefined workout types
  final List<Map<String, String>> workoutTypes = const [
    {'name': 'Fullbody Workout', 'duration': '32'},
    {'name': 'Lowerbody Workout', 'duration': '40'},
    {'name': 'AB Workout', 'duration': '20'},
    {'name': 'Upper Body Workout', 'duration': '35'},
    {'name': 'Cardio Workout', 'duration': '30'},
    {'name': 'HIIT Workout', 'duration': '25'},
  ];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    _detailsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _detailsFade = CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOut);
    _detailsScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _safeDayInMonth(DateTime monthBase, int day) {
    final lastDay = DateTime(monthBase.year, monthBase.month + 1, 0).day;
    final safeDay = day.clamp(1, lastDay);
    return DateTime(monthBase.year, monthBase.month, safeDay);
  }

  void _changeMonth(int delta) {
    setState(() {
      final currentDay = _selectedDate.day;
      final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
      _selectedDate = _safeDayInMonth(nextMonth, currentDay);
    });
    _closeDetails();
  }

  List<DateTime> _weekAroundSelected() {
    final base = _startOfDay(_selectedDate);
    // shift so selected date is the middle
    return List.generate(7, (i) => base.add(Duration(days: i - 3)));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamSchedules() {
    return _firestore.streamSchedulesForDay(_uid, day: _selectedDate);
  }

  void _openDetails(Map<String, dynamic> schedule) {
    setState(() {
      _selectedScheduleId = schedule['id'] as String?;
      _selectedSchedule = schedule;
    });
    _detailsCtrl.forward(from: 0);
  }

  void _closeDetails() async {
    if (_selectedScheduleId == null) return;
    await _detailsCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _selectedScheduleId = null;
      _selectedSchedule = null;
    });
  }

  Future<void> _markAsDone(String scheduleId, bool isDone) async {
    if (_uid.isEmpty) return;
    await _firestore.markScheduleDone(
      uid: _uid,
      scheduleId: scheduleId,
      isDone: isDone,
    );
    _closeDetails();
  }

  Future<void> _toggleNotification(String scheduleId, bool enabled) async {
    if (_uid.isEmpty) return;
    await _firestore.updateSchedule(_uid, scheduleId, {
      'notificationEnabled': enabled,
    });
    if (!mounted) return;
    setState(() {
      if (_selectedSchedule != null) {
        _selectedSchedule = {
          ..._selectedSchedule!,
          'notificationEnabled': enabled,
        };
      }
    });
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || _uid.isEmpty) return;

    await _firestore.deleteWorkoutSchedule(_uid, scheduleId);
    _closeDetails();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _getHour(DateTime dt) => dt.hour;

  List<Map<String, dynamic>> _getSchedulesForHour(
    List<Map<String, dynamic>> list,
    int hour,
  ) {
    return list.where((w) {
      final dt = w['scheduledAt'];
      return dt is DateTime && _getHour(dt) == hour;
    }).toList();
  }

  void _showAddWorkoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: _AddWorkoutSheet(
          workoutTypes: workoutTypes,
          onSave: (data) async {
            if (_uid.isEmpty) return;

            final scheduledAt = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              data.time.hour,
              data.time.minute,
            );

            await _firestore.addWorkoutSchedule(
              uid: _uid,
              workoutTitle: data.workoutTitle,
              scheduledAt: scheduledAt,
              difficulty: data.difficulty,
              durationMinutes: data.durationMinutes,
              notificationEnabled: data.notificationEnabled,
            );

            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workout added!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  DateTime? _parseScheduledAt(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _weekAroundSelected();

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        title: const Text(
          'Workout Schedule',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
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
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWorkoutSheet,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _uid.isEmpty
          ? const Center(child: Text('Please login again.'))
          : Stack(
              children: [
                Column(
                  children: [
                    // Month selector
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left,
                                color: Colors.grey.shade400),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right,
                                color: Colors.grey.shade400),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ),

                    // Week days
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: weekDays.map((date) {
                          final isSelected =
                              _startOfDay(date) == _startOfDay(_selectedDate);

                          return _PressScale(
                            onTap: () => setState(() {
                              _selectedDate = date;
                              _closeDetails();
                            }),
                            child: _DayCard(
                              day: DateFormat('E').format(date),
                              date: date.day,
                              isSelected: isSelected,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Timeline (Stream)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _streamSchedules(),
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snap.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Error: ${snap.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }

                          final docs = snap.data?.docs ?? [];

                          final schedules = <Map<String, dynamic>>[];

                          for (final doc in docs) {
                            final data = doc.data();

                            final dt = _parseScheduledAt(data['scheduledAt']);
                            if (dt == null) continue;

                            schedules.add({
                              'id': doc.id,
                              'workoutTitle':
                                  (data['workoutTitle'] ?? '').toString(),
                              'scheduledAt': dt,
                              'difficulty':
                                  (data['difficulty'] ?? 'Beginner').toString(),
                              'durationMinutes': (data['durationMinutes'] is int)
                                  ? data['durationMinutes'] as int
                                  : int.tryParse(
                                          (data['durationMinutes'] ?? '30')
                                              .toString()) ??
                                      30,
                              'isDone': (data['isDone'] ?? false) as bool,
                              'notificationEnabled':
                                  (data['notificationEnabled'] ?? true) as bool,
                            });
                          }

                          schedules.sort((a, b) =>
                              (a['scheduledAt'] as DateTime)
                                  .compareTo(b['scheduledAt'] as DateTime));

                          if (schedules.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fitness_center,
                                      size: 80,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No workouts scheduled',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.subText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Tap + to add a workout',
                                    style: TextStyle(
                                        fontSize: 13, color: AppColors.subText),
                                  ),
                                ],
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: List.generate(24, (hour) {
                                final items =
                                    _getSchedulesForHour(schedules, hour);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TimeSlot(
                                        time:
                                            '${hour.toString().padLeft(2, '0')}:00'),
                                    ...items.map((schedule) {
                                      final done = schedule['isDone'] as bool;
                                      final dt =
                                          schedule['scheduledAt'] as DateTime;

                                      return _PressScale(
                                        onTap: () => _openDetails(schedule),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color: done
                                                ? AppColors.success
                                                    .withValues(alpha: 0.18)
                                                : AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      schedule['workoutTitle'],
                                                      style: TextStyle(
                                                        color: done
                                                            ? const Color(
                                                                0xFF116B2B)
                                                            : Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${DateFormat('hh:mm a').format(dt)} • ${schedule['durationMinutes']}min • ${schedule['difficulty']}',
                                                      style: TextStyle(
                                                        color: done
                                                            ? const Color(
                                                                0xFF1B7C36)
                                                            : Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.85),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (done)
                                                const Icon(Icons.check_circle,
                                                    color: AppColors.success,
                                                    size: 24),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Details Popup (animated)
                if (_selectedScheduleId != null && _selectedSchedule != null)
                  FadeTransition(
                    opacity: _detailsFade,
                    child: GestureDetector(
                      onTap: _closeDetails,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.30),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {},
                            child: ScaleTransition(
                              scale: _detailsScale,
                              child: _WorkoutDetailsCard(
                                schedule: _selectedSchedule!,
                                onClose: _closeDetails,
                                onDelete: () => _deleteSchedule(_selectedScheduleId!),
                                onDone: () => _markAsDone(_selectedScheduleId!, true),
                                onToggleNotification: (v) =>
                                    _toggleNotification(_selectedScheduleId!, v),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// --------------------
// UI widgets
// --------------------
class _DayCard extends StatelessWidget {
  final String day;
  final int date;
  final bool isSelected;

  const _DayCard({
    required this.day,
    required this.date,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.primaryGradient : null,
        color: isSelected ? null : AppColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white : AppColors.subText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  final String time;
  const _TimeSlot({required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(time,
                style: const TextStyle(fontSize: 13, color: AppColors.subText)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
        ],
      ),
    );
  }
}

class _WorkoutDetailsCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onDone;
  final ValueChanged<bool> onToggleNotification;

  const _WorkoutDetailsCard({
    required this.schedule,
    required this.onClose,
    required this.onDelete,
    required this.onDone,
    required this.onToggleNotification,
  });

  @override
  Widget build(BuildContext context) {
    final done = (schedule['isDone'] ?? false) as bool;
    final dt = schedule['scheduledAt'] as DateTime;
    final notif = (schedule['notificationEnabled'] ?? true) as bool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              const Expanded(
                child: Text(
                  'Workout Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              (schedule['workoutTitle'] ?? '').toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.access_time,
            text: DateFormat('MMM dd, hh:mm a').format(dt),
          ),
          _InfoRow(
            icon: Icons.timer,
            text: '${schedule['durationMinutes']} minutes',
          ),
          _InfoRow(
            icon: Icons.fitness_center,
            text: (schedule['difficulty'] ?? '').toString(),
          ),

          const SizedBox(height: 8),

          // Real toggle (writes to Firestore)
          SwitchListTile(
            value: notif,
            onChanged: onToggleNotification,
            title: const Text('Notification'),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 10),

          if (!done)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onDone,
                child: const Text('Mark as Done'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 10),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.subText),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------
// Add workout sheet
// --------------------
class _AddWorkoutSheetData {
  final String workoutTitle;
  final TimeOfDay time;
  final int durationMinutes;
  final String difficulty;
  final bool notificationEnabled;

  const _AddWorkoutSheetData({
    required this.workoutTitle,
    required this.time,
    required this.durationMinutes,
    required this.difficulty,
    required this.notificationEnabled,
  });
}

class _AddWorkoutSheet extends StatefulWidget {
  final List<Map<String, String>> workoutTypes;
  final Future<void> Function(_AddWorkoutSheetData data) onSave;

  const _AddWorkoutSheet({
    required this.workoutTypes,
    required this.onSave,
  });

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  late String workoutTitle;
  late int durationMinutes;

  TimeOfDay time = TimeOfDay.now();
  String difficulty = 'Beginner';
  bool notificationEnabled = true;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    workoutTitle = widget.workoutTypes.first['name']!;
    durationMinutes = int.parse(widget.workoutTypes.first['duration']!);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await widget.onSave(
        _AddWorkoutSheetData(
          workoutTitle: workoutTitle,
          time: time,
          durationMinutes: durationMinutes,
          difficulty: difficulty,
          notificationEnabled: notificationEnabled,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: bottom + 18,
      ),
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
          const Text('Add Workout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            initialValue: workoutTitle,
            decoration: const InputDecoration(
              labelText: 'Workout Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fitness_center),
            ),
            items: widget.workoutTypes
                .map((w) => DropdownMenuItem(
                      value: w['name'],
                      child: Text(w['name']!),
                    ))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              final selected =
                  widget.workoutTypes.firstWhere((w) => w['name'] == val);
              setState(() {
                workoutTitle = val;
                durationMinutes = int.parse(selected['duration']!);
              });
            },
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final picked =
                    await showTimePicker(context: context, initialTime: time);
                if (picked == null) return;
                setState(() => time = picked);
              },
              child: Text('Time: ${time.format(context)}'),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            initialValue: durationMinutes,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              border: OutlineInputBorder(),
            ),
            items: const [15, 20, 25, 30, 32, 35, 40, 45, 60, 90]
                .map((m) => DropdownMenuItem(value: m, child: Text('$m minutes')))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => durationMinutes = val);
            },
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: difficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(),
            ),
            items: const ['Beginner', 'Intermediate', 'Advanced']
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => difficulty = val);
            },
          ),
          const SizedBox(height: 10),

          SwitchListTile(
            value: notificationEnabled,
            onChanged: (v) => setState(() => notificationEnabled = v),
            title: const Text('Enable Notification'),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------
// Press animation
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
        scale: _down ? 0.97 : 1.0,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

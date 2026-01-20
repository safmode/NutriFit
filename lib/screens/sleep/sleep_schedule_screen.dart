import 'package:flutter/material.dart';

class SleepScheduleScreen extends StatefulWidget {
  const SleepScheduleScreen({super.key});

  @override
  State<SleepScheduleScreen> createState() => _SleepScheduleScreenState();
}

class _SleepScheduleScreenState extends State<SleepScheduleScreen>
    with SingleTickerProviderStateMixin {
  // NutriFit palette
  static const Color kPrimary = Color(0xFF92A3FD);
  static const Color kSecondary = Color(0xFF9DCEFF);
  static const Color kAccent = Color(0xFFC58BF2);
  static const Color kCard = Color(0xFFF7F8F8);

  // For day cards (purely visual)
  int selectedDayIndex = 2; // 0..4 (Wed..Sun)

  bool _bedtimeEnabled = true;
  bool _alarmEnabled = true;

  TimeOfDay _bedtime = const TimeOfDay(hour: 21, minute: 0);
  Duration _sleepDuration = const Duration(hours: 8, minutes: 30);
  List<bool> _repeat = [true, true, true, true, true, false, false]; // Mon..Sun
  bool _vibrate = true;

  late final AnimationController _controller;
  bool _didInitArgs = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map) {
      final bedtime = arg['bedtime'];
      final sleepDuration = arg['sleepDuration'];
      final repeat = arg['repeat'];
      final vibrate = arg['vibrate'];
      final be = arg['bedtimeEnabled'];
      final ae = arg['alarmEnabled'];

      if (bedtime is TimeOfDay) _bedtime = bedtime;
      if (sleepDuration is Duration) _sleepDuration = sleepDuration;
      if (repeat is List && repeat.length == 7) {
        _repeat = List<bool>.from(repeat.map((e) => e == true));
      }
      if (vibrate is bool) _vibrate = vibrate;
      if (be is bool) _bedtimeEnabled = be;
      if (ae is bool) _alarmEnabled = ae;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _currentPayload() => {
        'bedtime': _bedtime,
        'sleepDuration': _sleepDuration,
        'repeat': _repeat,
        'vibrate': _vibrate,
        'bedtimeEnabled': _bedtimeEnabled,
        'alarmEnabled': _alarmEnabled,
      };

  void _popWithPayload() {
    if (!mounted) return;
    Navigator.pop(context, _currentPayload());
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'am' : 'pm';
    return '$hour:$mm$suffix';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _formatRepeatShort() {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selected = <String>[];
    for (var i = 0; i < 7; i++) {
      if (_repeat[i]) selected.add(names[i]);
    }
    if (selected.isEmpty) return 'Once';
    if (selected.length == 7) return 'Everyday';

    final weekdays = _repeat.sublist(0, 5).every((v) => v) && !_repeat[5] && !_repeat[6];
    if (weekdays) return 'Mon to Fri';

    final weekend = !_repeat.sublist(0, 5).any((v) => v) && _repeat[5] && _repeat[6];
    if (weekend) return 'Sat & Sun';

    return selected.join(', ');
  }

  TimeOfDay get _alarmTime {
    final totalMinutes = _bedtime.hour * 60 + _bedtime.minute + _sleepDuration.inMinutes;
    final m = totalMinutes % (24 * 60);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      helpText: 'Select bedtime',
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _bedtime = picked);
    }
  }

  Future<void> _pickSleepDuration() async {
    // simple duration picker dialog: hours/minutes
    int h = _sleepDuration.inHours;
    int m = _sleepDuration.inMinutes.remainder(60);

    final res = await showDialog<Duration>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Sleep Duration'),
          content: Row(
            children: [
              Expanded(
                child: _NumberWheel(
                  label: 'Hours',
                  min: 0,
                  max: 15,
                  initial: h,
                  onChanged: (v) => h = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberWheel(
                  label: 'Minutes',
                  min: 0,
                  max: 55,
                  step: 5,
                  initial: (m ~/ 5),
                  display: (i) => (i * 5).toString().padLeft(2, '0'),
                  onChanged: (i) => m = i * 5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, Duration(hours: h, minutes: m)),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (res != null) setState(() => _sleepDuration = res);
  }

  Future<void> _editRepeatAndVibrate() async {
    final localRepeat = List<bool>.from(_repeat);
    bool localVibrate = _vibrate;

    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Repeat & Vibrate',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(7, (i) {
                        final on = localRepeat[i];
                        return InkWell(
                          onTap: () => setSheet(() => localRepeat[i] = !localRepeat[i]),
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: on ? const Color(0xFFE8EEFF) : const Color(0xFFF7F8F8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: on ? kPrimary : Colors.transparent,
                                width: 1.4,
                              ),
                            ),
                            child: Text(
                              names[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: on ? kPrimary : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Icon(Icons.vibration, color: kAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Vibrate',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Switch(
                          value: localVibrate,
                          onChanged: (v) => setSheet(() => localVibrate = v),
                          activeThumbColor: kAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx, {'repeat': localRepeat, 'vibrate': localVibrate});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (res != null) {
      final r = res['repeat'];
      final v = res['vibrate'];
      setState(() {
        if (r is List<bool> && r.length == 7) _repeat = List<bool>.from(r);
        if (v is bool) _vibrate = v;
      });
    }
  }

  Future<void> _openAddAlarm() async {
    // Keep your original route if you have it; fallback to our inline pickers
    final hasRoute = ModalRoute.of(context) != null; // always true, but keep safe

    if (hasRoute) {
      final result = await Navigator.pushNamed(context, '/add-alarm');
      if (!mounted) return;
      if (result is Map) {
        final bedtime = result['bedtime'];
        final sleepDuration = result['sleepDuration'];
        final repeat = result['repeat'];
        final vibrate = result['vibrate'];

        setState(() {
          if (bedtime is TimeOfDay) _bedtime = bedtime;
          if (sleepDuration is Duration) _sleepDuration = sleepDuration;
          if (repeat is List && repeat.length == 7) {
            _repeat = List<bool>.from(repeat.map((e) => e == true));
          }
          if (vibrate is bool) _vibrate = vibrate;

          _bedtimeEnabled = true;
          _alarmEnabled = true;
        });
        return;
      }
    }

    // If route returns nothing / not implemented: open inline editors
    await _pickBedtime();
    await _pickSleepDuration();
    await _editRepeatAndVibrate();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final idealMin = const Duration(hours: 8, minutes: 30).inMinutes;
    final percent = (_sleepDuration.inMinutes / idealMin).clamp(0.0, 1.0);
    final percentLabel = '${(percent * 100).round()}%';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _popWithPayload();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Sleep Schedule',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: _popWithPayload,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onPressed: _editRepeatAndVibrate,
            ),
          ],
        ),
        floatingActionButton: _FabScale(
          onTap: _openAddAlarm,
          child: FloatingActionButton(
            onPressed: _openAddAlarm,
            backgroundColor: kAccent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
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
                  // Ideal Hours card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ideal Hours for Sleep',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(const Duration(hours: 8, minutes: 30)),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const _UnderlineLink(text: 'Learn More'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.bedtime, size: 56, color: kAccent),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Text(
                    'Your Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 86,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildDayCard('Wed', 12, 0),
                        _buildDayCard('Thu', 13, 1),
                        _buildDayCard('Fri', 14, 2),
                        _buildDayCard('Sat', 15, 3),
                        _buildDayCard('Sun', 16, 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildScheduleItem(
                    icon: Icons.bed_outlined,
                    iconColor: kPrimary,
                    title: 'Bedtime',
                    time: _formatTime(_bedtime),
                    subtitle: 'Repeat: ${_formatRepeatShort()}',
                    isEnabled: _bedtimeEnabled,
                    onToggle: (v) => setState(() => _bedtimeEnabled = v),
                    onTap: () async {
                      await _pickBedtime();
                      if (!mounted) return;
                      setState(() {
                        _bedtimeEnabled = true;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  _buildScheduleItem(
                    icon: Icons.alarm,
                    iconColor: Colors.red,
                    title: 'Alarm',
                    time: _formatTime(_alarmTime),
                    subtitle: 'Vibrate: ${_vibrate ? "On" : "Off"} • Sleep: ${_formatDuration(_sleepDuration)}',
                    isEnabled: _alarmEnabled,
                    onToggle: (v) => setState(() => _alarmEnabled = v),
                    onTap: () async {
                      await _pickSleepDuration();
                      if (!mounted) return;
                      setState(() {
                        _alarmEnabled = true;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // Repeat & Vibrate
                  _PressScale(
                    onTap: _editRepeatAndVibrate,
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
                              color: kAccent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.repeat, color: kAccent, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Repeat & Vibrate',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatRepeatShort()} • Vibrate: ${_vibrate ? "On" : "Off"}',
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
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Tonight progress
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E8FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You will get ${_formatDuration(_sleepDuration)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'for tonight',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 26,
                                backgroundColor: const Color(0xFFE8D4FF),
                                valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
                              ),
                            ),
                            Text(
                              percentLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(String day, int date, int index) {
    final isSelected = selectedDayIndex == index;

    return GestureDetector(
      onTap: () => setState(() => selectedDayIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 68,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [kPrimary, kSecondary]) : null,
          color: isSelected ? null : kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? kPrimary : Colors.grey)
                  .withValues(alpha: isSelected ? 0.22 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$date',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
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

/* ---------------- SMALL UI ---------------- */

class _UnderlineLink extends StatelessWidget {
  final String text;
  const _UnderlineLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: _SleepScheduleScreenState.kPrimary,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FabScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _FabScale({required this.child, required this.onTap});

  @override
  State<_FabScale> createState() => _FabScaleState();
}

class _FabScaleState extends State<_FabScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
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

/* ---------------- SIMPLE WHEEL ---------------- */

class _NumberWheel extends StatelessWidget {
  final String label;
  final int min;
  final int max;
  final int step;
  final int initial;
  final String Function(int index)? display;
  final void Function(int value) onChanged;

  const _NumberWheel({
    required this.label,
    required this.min,
    required this.max,
    this.step = 1,
    required this.initial,
    this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = ((max - min) ~/ step) + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 36,
            diameterRatio: 1.4,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: initial),
            onSelectedItemChanged: (index) {
              final val = min + index * step;
              onChanged(val);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (context, index) {
                final val = min + index * step;
                final text = display != null ? display!(index) : val.toString();
                return Center(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

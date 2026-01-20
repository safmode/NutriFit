import 'package:flutter/material.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen>
    with SingleTickerProviderStateMixin {
  // NutriFit palette
  static const Color kPrimary = Color(0xFF92A3FD);
  static const Color kSecondary = Color(0xFF9DCEFF);
  static const Color kAccent = Color(0xFFC58BF2);
  static const Color kCard = Color(0xFFF7F8F8);

  bool _didInitArgs = false;

  bool vibrateEnabled = true;

  TimeOfDay _bedtime = const TimeOfDay(hour: 21, minute: 0);
  Duration _sleepDuration = const Duration(hours: 8, minutes: 30);

  // Repeat days (Mon..Sun)
  List<bool> _repeat = [true, true, true, true, true, false, false];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    // ✅ Support optional incoming args from SleepScheduleScreen
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map) {
      final bedtime = arg['bedtime'];
      final sleepDuration = arg['sleepDuration'];
      final repeat = arg['repeat'];
      final vibrate = arg['vibrate'];

      if (bedtime is TimeOfDay) _bedtime = bedtime;
      if (sleepDuration is Duration) _sleepDuration = sleepDuration;
      if (repeat is List && repeat.length == 7) {
        _repeat = List<bool>.from(repeat.map((e) => e == true));
      }
      if (vibrate is bool) vibrateEnabled = vibrate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() => {
        'bedtime': _bedtime,
        'sleepDuration': _sleepDuration,
        'repeat': List<bool>.from(_repeat),
        'vibrate': vibrateEnabled,
      };

  void _popWithPayload() {
    if (!mounted) return;
    Navigator.pop(context, _payload());
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

  String _formatRepeat() {
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

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      helpText: 'Select bedtime',
    );
    if (!mounted) return;
    if (picked != null) setState(() => _bedtime = picked);
  }

  Future<void> _pickSleepDuration() async {
    int hours = _sleepDuration.inHours.clamp(1, 16);
    int minutes = _sleepDuration.inMinutes.remainder(60);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
                      'Hours of sleep',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _numberPickerCard(
                            title: 'Hours',
                            valueText: '$hours',
                            onMinus: () => setSheet(() => hours = (hours - 1).clamp(1, 16)),
                            onPlus: () => setSheet(() => hours = (hours + 1).clamp(1, 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _numberPickerCard(
                            title: 'Minutes',
                            valueText: minutes.toString().padLeft(2, '0'),
                            onMinus: () => setSheet(() {
                              minutes -= 5;
                              if (minutes < 0) minutes = 55;
                            }),
                            onPlus: () => setSheet(() {
                              minutes += 5;
                              if (minutes > 55) minutes = 0;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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
    if (ok == true) {
      setState(() => _sleepDuration = Duration(hours: hours, minutes: minutes));
    }
  }

  Future<void> _pickRepeat() async {
    final temp = List<bool>.from(_repeat);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
                      'Repeat',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _chipButton(
                            label: 'Weekdays',
                            onTap: () => setSheet(() {
                              for (var i = 0; i < 5; i++) {
                                temp[i] = true;
                              }
                              temp[5] = false;
                              temp[6] = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _chipButton(
                            label: 'Everyday',
                            onTap: () => setSheet(() {
                              for (var i = 0; i < 7; i++) {
                                temp[i] = true;
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: List.generate(7, (i) {
                          return SwitchListTile(
                            value: temp[i],
                            onChanged: (v) => setSheet(() => temp[i] = v),
                            title: Text(
                              names[i],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            activeThumbColor: kAccent,
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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
    if (ok == true) {
      setState(() => _repeat = List<bool>.from(temp));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
            'Add Alarm',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: _PressScale(
            onTap: _popWithPayload,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            ),
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: Icons.bed_outlined,
                          title: 'Bedtime',
                          value: _formatTime(_bedtime),
                          onTap: _pickBedtime,
                        ),
                        const SizedBox(height: 15),
                        _buildSettingItem(
                          icon: Icons.access_time,
                          title: 'Hours of sleep',
                          value: _formatDuration(_sleepDuration),
                          onTap: _pickSleepDuration,
                        ),
                        const SizedBox(height: 15),
                        _buildSettingItem(
                          icon: Icons.repeat,
                          title: 'Repeat',
                          value: _formatRepeat(),
                          onTap: _pickRepeat,
                        ),
                        const SizedBox(height: 15),
                        _buildToggleItem(
                          icon: Icons.vibration,
                          title: 'Vibrate when alarm sounds',
                          value: vibrateEnabled,
                          onChanged: (value) => setState(() => vibrateEnabled = value),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: _PressScale(
                      onTap: _popWithPayload,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [kPrimary, kSecondary]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.grey.shade700, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: kAccent,
          ),
        ],
      ),
    );
  }

  Widget _chipButton({required String label, required VoidCallback onTap}) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _numberPickerCard({
    required String title,
    required String valueText,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            valueText,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)),
              IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline)),
            ],
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
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

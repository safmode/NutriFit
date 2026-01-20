import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isFav = true;
  String _difficulty = 'Beginner';

  // Demo schedule time (you can replace from Firestore later)
  final DateTime _scheduledAt = DateTime.now().add(
    const Duration(days: 1, hours: 2),
  );

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Schedule workout'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/workout-schedule');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report sent (demo)')),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickDifficulty() {
    final options = ['Beginner', 'Intermediate', 'Advanced'];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                const Text(
                  'Select Difficulty',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...options.map((v) {
                  final isSelected = v == _difficulty;
                  return ListTile(
                    title: Text(v),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () {
                      setState(() => _difficulty = v);
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  String _scheduleLabel(DateTime t) {
    // Mockup style: 5/27, 09:00 AM
    return DateFormat('M/d, hh:mm a').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final workoutName = (args is Map && args['workoutName'] is String)
        ? args['workoutName'] as String
        : 'Fullbody Workout';

    // Mockup numbers
    const subtitle = '11 Exercises | 32mins | 320 Calories Burn';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // =========================
          // Hero (top)
          // =========================
          Container(
            height: 360,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 6,
                    child: _PressScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 6,
                    child: _PressScale(
                      onTap: _openMoreMenu,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 56),
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.accessibility_new,
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =========================
          // White sheet content
          // =========================
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(34),
                  topRight: Radius.circular(34),
                ),
              ),
              transform: Matrix4.translationValues(0, -70, 0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workoutName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _PressScale(
                          onTap: () => setState(() => _isFav = !_isFav),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: AppColors.subText),
                    ),
                    const SizedBox(height: 18),

                    _PressScale(
                      onTap: () =>
                          Navigator.pushNamed(context, '/workout-schedule'),
                      child: _InfoRow(
                        icon: Icons.calendar_month,
                        label: 'Schedule Workout',
                        trailingText: _scheduleLabel(_scheduledAt),
                        bg: const Color(0xFFEFF4FF),
                        iconBg: Colors.white.withValues(alpha: 0.7),
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _PressScale(
                      onTap: _pickDifficulty,
                      child: _InfoRow(
                        icon: Icons.swap_vert_rounded,
                        label: 'Difficulty',
                        trailingText: _difficulty,
                        bg: const Color(0xFFFFECF5),
                        iconBg: Colors.white.withValues(alpha: 0.65),
                        iconColor: AppColors.accent,
                        trailingColor: AppColors.subText,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // You'll Need
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "You'll Need",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '5 Items',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _EquipmentTile(
                            name: 'Barbell',
                            icon: Icons.fitness_center,
                          ),
                          _EquipmentTile(
                            name: 'Skipping Rope',
                            icon: Icons.extension,
                          ),
                          _EquipmentTile(
                            name: 'Bottle 1 Ltr',
                            icon: Icons.local_drink,
                          ),
                          _EquipmentTile(name: 'Mat', icon: Icons.crop_16_9),
                          _EquipmentTile(name: 'Timer', icon: Icons.timer),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================
                    // Exercises
                    // =========================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Exercises',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '3 Sets',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // -------- Set 1
                    Text(
                      'Set 1',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _ExerciseTile(
                      name: 'Warm Up',
                      value: '05:00',
                      icon: Icons.self_improvement,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'warm_up.mp4',
                          'name': 'Warm Up',
                          'subtitle': 'Easy | 120 Calories Burn',
                          'description':
                              'A light warm up prepares your muscles and joints for exercise, increases heart rate gradually, and reduces injury risk.',
                          'steps': const [
                            {
                              'title': 'Start Slow',
                              'desc':
                                  'Begin with light movement to raise your heart rate gently.',
                            },
                            {
                              'title': 'Mobilize Joints',
                              'desc':
                                  'Rotate shoulders, hips, and ankles for better flexibility.',
                            },
                            {
                              'title': 'Increase Range',
                              'desc':
                                  'Slowly increase range of motion and pace.',
                            },
                            {
                              'title': 'Breathe',
                              'desc':
                                  'Maintain steady breathing and good posture.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Duration', 'value': '05:00'},
                            {'title': 'Calories Burn', 'value': '120'},
                            {'title': 'Intensity', 'value': 'Easy'},
                          ],
                        },
                      ),
                    ),

                    _ExerciseTile(
                      name: 'Jumping Jack',
                      value: '12x',
                      icon: Icons.accessibility_new,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'jumping_jack.mp4',
                          'name': 'Jumping Jack',
                          'subtitle': 'Easy | 390 Calories Burn',
                          'description':
                              'A jumping jack (star jump) is a full-body cardio move. Jump with legs apart while raising arms overhead, then return to start.',
                          'steps': const [
                            {
                              'title': 'Spread Your Arms',
                              'desc':
                                  'Stretch your arms overhead. Keep shoulders relaxed.',
                            },
                            {
                              'title': 'Land Softly',
                              'desc':
                                  'Land softly using the balls of your feet to reduce impact.',
                            },
                            {
                              'title': 'Control Movement',
                              'desc':
                                  'Keep your core engaged and control the pace.',
                            },
                            {
                              'title': 'Rhythm',
                              'desc': 'Stay consistent with smooth breathing.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Reps', 'value': '12x'},
                            {'title': 'Calories Burn', 'value': '390'},
                            {'title': 'Intensity', 'value': 'Easy'},
                          ],
                        },
                      ),
                    ),

                    _ExerciseTile(
                      name: 'Skipping',
                      value: '15x',
                      icon: Icons.sports,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'skipping.mp4',
                          'name': 'Skipping',
                          'subtitle': 'Medium | 260 Calories Burn',
                          'description':
                              'Skipping improves coordination and cardio endurance. Keep jumps low and wrists rotating the rope.',
                          'steps': const [
                            {
                              'title': 'Light Jumps',
                              'desc': 'Jump just enough to clear the rope.',
                            },
                            {
                              'title': 'Use Wrists',
                              'desc': 'Rotate rope with wrists, not arms.',
                            },
                            {
                              'title': 'Stay Tall',
                              'desc': 'Keep chest up and core tight.',
                            },
                            {
                              'title': 'Soft Landing',
                              'desc': 'Land quietly to protect joints.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Reps', 'value': '15x'},
                            {'title': 'Calories Burn', 'value': '260'},
                            {'title': 'Intensity', 'value': 'Medium'},
                          ],
                        },
                      ),
                    ),

                    _ExerciseTile(
                      name: 'Squats',
                      value: '20x',
                      icon: Icons.accessibility,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'squats.mp4',
                          'name': 'Squats',
                          'subtitle': 'Medium | 210 Calories Burn',
                          'description':
                              'Squats strengthen legs and glutes. Keep knees tracking over toes and back neutral.',
                          'steps': const [
                            {
                              'title': 'Feet Position',
                              'desc': 'Feet shoulder-width apart.',
                            },
                            {
                              'title': 'Sit Back',
                              'desc': 'Push hips back like sitting on a chair.',
                            },
                            {
                              'title': 'Knees Out',
                              'desc': 'Keep knees aligned with toes.',
                            },
                            {
                              'title': 'Drive Up',
                              'desc': 'Press through heels to stand.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Reps', 'value': '20x'},
                            {'title': 'Calories Burn', 'value': '210'},
                            {'title': 'Intensity', 'value': 'Medium'},
                          ],
                        },
                      ),
                    ),

                    _ExerciseTile(
                      name: 'Arm Raises',
                      value: '00:53',
                      icon: Icons.fitness_center,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'arm_raises.mp4',
                          'name': 'Arm Raises',
                          'subtitle': 'Easy | 120 Calories Burn',
                          'description':
                              'Arm raises strengthen shoulders. Keep shoulders down and avoid swinging.',
                          'steps': const [
                            {
                              'title': 'Neutral Spine',
                              'desc': 'Stand tall and brace your core.',
                            },
                            {
                              'title': 'Lift Controlled',
                              'desc': 'Raise arms slowly to shoulder level.',
                            },
                            {
                              'title': 'No Swing',
                              'desc': 'Avoid momentum; keep elbows soft.',
                            },
                            {
                              'title': 'Lower Slow',
                              'desc': 'Lower with control for best results.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Duration', 'value': '00:53'},
                            {'title': 'Calories Burn', 'value': '120'},
                            {'title': 'Intensity', 'value': 'Easy'},
                          ],
                        },
                      ),
                    ),

                    _ExerciseTile(
                      name: 'Rest and Drink',
                      value: '02:00',
                      icon: Icons.local_drink,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': '', // No video for rest
                          'name': 'Rest and Drink',
                          'subtitle': 'Recovery | Hydrate',
                          'description':
                              'Rest allows heart rate to stabilize and helps recovery. Sip water and breathe deeply.',
                          'steps': const [
                            {
                              'title': 'Slow Breathing',
                              'desc': 'Inhale 3 sec, exhale 3 sec.',
                            },
                            {
                              'title': 'Sip Water',
                              'desc': 'Small sips to rehydrate comfortably.',
                            },
                            {
                              'title': 'Shake Limbs',
                              'desc': 'Relax shoulders and legs gently.',
                            },
                            {
                              'title': 'Prepare',
                              'desc': 'Reset posture before next set.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Duration', 'value': '02:00'},
                            {'title': 'Hydration', 'value': '250ml'},
                            {'title': 'Recovery', 'value': 'Good'},
                          ],
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // -------- Set 2
                    Text(
                      'Set 2',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _ExerciseTile(
                      name: 'Incline Push-Ups',
                      value: '12x',
                      icon: Icons.fitness_center,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'incline_pushups.mp4',
                          'name': 'Incline Push-Ups',
                          'subtitle': 'Medium | 180 Calories Burn',
                          'description':
                              'Incline push-ups target chest and triceps with less load than floor push-ups.',
                          'steps': const [
                            {
                              'title': 'Hands on Bench',
                              'desc':
                                  'Hands shoulder-width on elevated surface.',
                            },
                            {
                              'title': 'Body Straight',
                              'desc': 'Keep head-to-heel straight line.',
                            },
                            {
                              'title': 'Lower Controlled',
                              'desc': 'Elbows ~45° from body.',
                            },
                            {
                              'title': 'Press Up',
                              'desc':
                                  'Push back to start without locking elbows.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Reps', 'value': '12x'},
                            {'title': 'Calories Burn', 'value': '180'},
                            {'title': 'Intensity', 'value': 'Medium'},
                          ],
                        },
                      ),
                    ),

                    _ExerciseTile(
                      name: 'Push-Ups',
                      value: '15x',
                      icon: Icons.fitness_center,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'pushups.mp4',
                          'name': 'Push-Ups',
                          'subtitle': 'Hard | 220 Calories Burn',
                          'description':
                              'Push-ups strengthen chest, shoulders and triceps. Keep core tight and avoid sagging hips.',
                          'steps': const [
                            {
                              'title': 'Plank Setup',
                              'desc': 'Hands under shoulders, core braced.',
                            },
                            {
                              'title': 'Lower',
                              'desc': 'Lower chest toward floor with control.',
                            },
                            {
                              'title': 'Elbows 45°',
                              'desc': 'Avoid flaring elbows straight out.',
                            },
                            {
                              'title': 'Press',
                              'desc': 'Push up and keep body aligned.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Reps', 'value': '15x'},
                            {'title': 'Calories Burn', 'value': '220'},
                            {'title': 'Intensity', 'value': 'Hard'},
                          ],
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // -------- Set 3 (added so 3 Sets is real)
                    Text(
                      'Set 3',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _ExerciseTile(
                      name: 'Plank',
                      value: '01:00',
                      icon: Icons.horizontal_rule,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'videoUrl': 'plank.mp4',
                          'name': 'Plank',
                          'subtitle': 'Medium | 140 Calories Burn',
                          'description':
                              'Plank strengthens core, shoulders and stability. Keep hips level and spine neutral.',
                          'steps': const [
                            {
                              'title': 'Elbows Under Shoulders',
                              'desc': 'Keep forearms flat and elbows aligned.',
                            },
                            {
                              'title': 'Core Tight',
                              'desc': 'Brace your core to avoid sagging.',
                            },
                            {
                              'title': 'Neutral Neck',
                              'desc': 'Look down slightly, keep neck relaxed.',
                            },
                            {
                              'title': 'Breathe',
                              'desc': 'Breathe steadily throughout.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Duration', 'value': '01:00'},
                            {'title': 'Calories Burn', 'value': '140'},
                            {'title': 'Intensity', 'value': 'Medium'},
                          ],
                        },
                      ),
                    ),

                    _ExerciseTile(
                      name: 'Cooldown Stretch',
                      value: '03:00',
                      icon: Icons.self_improvement,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/exercise-detail',
                        arguments: {
                          'name': 'Cooldown Stretch',
                          'subtitle': 'Easy | Recovery',
                          'description':
                              'Cooldown helps relax muscles and reduce soreness. Focus on slow breathing and gentle stretches.',
                          'steps': const [
                            {
                              'title': 'Slow Breathing',
                              'desc': 'Inhale 4 sec, exhale 4 sec.',
                            },
                            {
                              'title': 'Stretch Legs',
                              'desc':
                                  'Hold hamstring and quad stretches gently.',
                            },
                            {
                              'title': 'Stretch Upper Body',
                              'desc': 'Open chest and shoulders slowly.',
                            },
                            {
                              'title': 'Hydrate',
                              'desc': 'Drink water after finishing.',
                            },
                          ],
                          'reps': const [
                            {'title': 'Duration', 'value': '03:00'},
                            {'title': 'Recovery', 'value': 'Good'},
                            {'title': 'Intensity', 'value': 'Easy'},
                          ],
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // =========================
      // Bottom CTA
      // =========================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting: $workoutName')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Workout',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// UI components
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailingText;
  final Color bg;
  final Color iconBg;
  final Color iconColor;
  final Color? trailingColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.trailingText,
    required this.bg,
    required this.iconBg,
    required this.iconColor,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            trailingText,
            style: TextStyle(
              fontSize: 12,
              color: trailingColor ?? Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  final String name;
  final IconData icon;

  const _EquipmentTile({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Icon(
                icon,
                size: 44,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String name;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.name,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.grey.shade500,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable press animation
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

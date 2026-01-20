import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _expanded = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_videoPlayerController == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final url = args['videoUrl'];
        if (url is String && url.isNotEmpty) {
          _initializePlayer(url);
        }
      }
    }
  }

  Future<void> _initializePlayer(String fileName) async {
    try {
      // Assuming files are in assets/video/
      _videoPlayerController = VideoPlayerController.asset(
        'assets/video/$fileName',
      );
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Video not found: assets/video/$fileName\nPlease add this file.',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading video: $e");
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Save as favorite (demo)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Saved (demo)')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share (demo)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report (demo)'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    final name = (args is Map && args['name'] is String)
        ? args['name'] as String
        : 'Jumping Jack';

    final subtitle = (args is Map && args['subtitle'] is String)
        ? args['subtitle'] as String
        : 'Easy | 390 Calories Burn';

    final description = (args is Map && args['description'] is String)
        ? args['description'] as String
        : 'A jumping jack is a full-body exercise performed by jumping to a position with legs spread wide and hands overhead, then returning to start.';

    final stepsRaw = (args is Map && args['steps'] is List)
        ? (args['steps'] as List)
        : const [];
    final repsRaw = (args is Map && args['reps'] is List)
        ? (args['reps'] as List)
        : const [];

    final shortDesc = description.length > 150
        ? '${description.substring(0, 150)}...'
        : description;

    final steps = stepsRaw.whereType<Map>().toList();
    final reps = repsRaw.whereType<Map>().toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // =========================
          // Top actions
          // =========================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 54, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PressScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.close),
                  ),
                ),
                _PressScale(
                  onTap: _openMoreMenu,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.more_horiz),
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // Video placeholder
          // =========================
          // =========================
          // Video Player
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child:
                  _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                  ? SizedBox(
                      height: 190,
                      child: Chewie(controller: _chewieController!),
                    )
                  : Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 74,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
            ),
          ),

          // =========================
          // Content
          // =========================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.subText,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Descriptions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _expanded ? description : shortDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.subText,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 6),

                  _PressScale(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? 'Read Less' : 'Read More..',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =========================
                  // Steps
                  // =========================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'How To Do It',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${steps.isEmpty ? 4 : steps.length} Steps',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _StepTimeline(
                    steps: steps.isEmpty
                        ? const [
                            {
                              'title': 'Spread Your Arms',
                              'desc':
                                  'Stretch your arms as you start this movement.',
                            },
                            {
                              'title': 'Rest at The Toe',
                              'desc':
                                  'Land softly using the tips of your feet.',
                            },
                            {
                              'title': 'Adjust Foot Movement',
                              'desc':
                                  'Pay attention to leg movement and balance.',
                            },
                            {
                              'title': 'Clapping Both Hands',
                              'desc': 'Keep rhythm and maintain good posture.',
                            },
                          ]
                        : steps,
                  ),

                  const SizedBox(height: 22),

                  // =========================
                  // Repetitions
                  // =========================
                  const Text(
                    'Custom Repetitions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),

                  ...(reps.isEmpty
                      ? [
                          const _RepetitionRow(
                            title: 'Duration',
                            value: '00:30',
                            icon: Icons.fitness_center,
                            bgColor: Color(0xFFFFECF5),
                            iconColor: AppColors.accent,
                          ),
                          const SizedBox(height: 10),
                          const _RepetitionRow(
                            title: 'Calories Burn',
                            value: '390',
                            icon: Icons.local_fire_department,
                            bgColor: Color(0xFFFFF4E6),
                            iconColor: Color(0xFFFF9A62),
                          ),
                        ]
                      : reps.map((r) {
                          final title = (r['title'] is String)
                              ? r['title'] as String
                              : 'Item';
                          final value = (r['value'] is String)
                              ? r['value'] as String
                              : '-';

                          final isFire = title.toLowerCase().contains(
                            'calories',
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RepetitionRow(
                              title: title,
                              value: value,
                              icon: isFire
                                  ? Icons.local_fire_department
                                  : Icons.fitness_center,
                              bgColor: isFire
                                  ? const Color(0xFFFFF4E6)
                                  : const Color(0xFFFFECF5),
                              iconColor: isFire
                                  ? const Color(0xFFFF9A62)
                                  : AppColors.accent,
                            ),
                          );
                        }).toList()),
                ],
              ),
            ),
          ),
        ],
      ),

      // =========================
      // Bottom button
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
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save',
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
// Timeline widget
// ============================================================

class _StepTimeline extends StatelessWidget {
  final List<Map> steps;
  const _StepTimeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];

        final title = (s['title'] is String) ? s['title'] as String : 'Step';
        final desc = (s['desc'] is String) ? s['desc'] as String : '';

        final number = (i + 1).toString().padLeft(2, '0');
        final isLast = i == steps.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 62,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.subText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ============================================================
// Repetition row
// ============================================================

class _RepetitionRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _RepetitionRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.subText),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Press animation
// ============================================================

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

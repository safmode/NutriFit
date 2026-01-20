import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Set<String> selectedGoals = {
    'Lose Weight',
    'Reduce Stress',
    'Improve Health',
  };

  bool _isLoading = false;
  late final AnimationController _controller;

  final List<_GoalItem> _goals = const [
    _GoalItem('Lose Weight', Icons.speed),
    _GoalItem('Build Strength', Icons.fitness_center),
    _GoalItem('Gain Weight', Icons.assessment),
    _GoalItem('Reduce Stress', Icons.self_improvement),
    _GoalItem('Improve Health', Icons.favorite),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleGoal(String title) {
    if (_isLoading) return;
    setState(() {
      if (selectedGoals.contains(title)) {
        selectedGoals.remove(title);
      } else {
        selectedGoals.add(title);
      }
    });
  }

  Future<void> _saveGoalsAndComplete() async {
    if (selectedGoals.isEmpty) {
      _showSnack('Please select at least one goal', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _showSnack('No user logged in.', isError: true);
        return;
      }

      await _firestoreService.updateUserProfile(user.uid, {
        'goals': selectedGoals.toList(),
        'onboardingComplete': true, // ✅ final flag
        'completedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSnack('Setup complete! Welcome to NutriFit!');
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      // ✅ go to '/' so main.dart decides to show Home
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      if (mounted) _showSnack('Error saving goals: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skip() async {
    // If you allow skipping, you MUST still mark onboardingComplete,
    // otherwise main.dart will keep sending user back here.
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _showSnack('No user logged in.', isError: true);
        return;
      }
      await _firestoreService.updateUserProfile(user.uid, {
        'onboardingComplete': true,
      });

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      _showSnack('Skip failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTap(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: 0.66,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: _isLoading ? Colors.grey.shade400 : AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'What is your fitness goal?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Knowing your goals help us tailor\nyour experience',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.3),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final g = _goals[index];
                    final isSelected = selectedGoals.contains(g.title);

                    final start = (index * 0.08).clamp(0.0, 0.6);
                    final anim = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
                    );

                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(anim),
                        child: _TapScale(
                          enabled: !_isLoading,
                          onTap: () => _toggleGoal(g.title),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.softBlue : AppColors.card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 1.6,
                              ),
                              boxShadow: AppColors.softShadow(opacity: 0.06),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    g.icon,
                                    size: 26,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    g.title,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, a) =>
                                      ScaleTransition(scale: a, child: child),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          key: ValueKey('on'),
                                          color: AppColors.accent,
                                          size: 28,
                                        )
                                      : Icon(
                                          Icons.circle_outlined,
                                          key: const ValueKey('off'),
                                          color: Colors.grey.shade400,
                                          size: 28,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoalsAndComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalItem {
  final String title;
  final IconData icon;
  const _GoalItem(this.title, this.icon);
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  const _TapScale({
    required this.child,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _down = false);
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _IconTap({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      ),
    );
  }
}

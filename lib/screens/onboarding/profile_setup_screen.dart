import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String selectedGender = '';
  String weightUnit = 'KG';
  String heightUnit = 'CM';
  String _userName = 'User';
  bool _isLoading = false;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
          ..forward();
    _loadUserName();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final userSnap = await _firestoreService.getUserData(user.uid);
      if (!userSnap.exists) return;

      final data = userSnap.data();
      final first = data?['firstName'];

      if (!mounted) return;
      setState(() {
        _userName =
            (first is String && first.trim().isNotEmpty) ? first.trim() : 'User';
      });
    } catch (_) {}
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int? _parseIntSafe(String v) => int.tryParse(v.trim());

  double? _parseDoubleSafe(String v) {
    final t = v.trim().replaceAll(',', '.');
    return double.tryParse(t);
  }

  Future<void> _saveProfileData() async {
    if (selectedGender.isEmpty) {
      _snack('Please select your gender', isError: true);
      return;
    }

    final age = _parseIntSafe(_ageController.text);
    if (age == null || age <= 0 || age > 120) {
      _snack('Please enter a valid age', isError: true);
      return;
    }

    final weight = _parseDoubleSafe(_weightController.text);
    if (weight == null || weight <= 0) {
      _snack('Please enter a valid weight', isError: true);
      return;
    }

    final height = _parseDoubleSafe(_heightController.text);
    if (height == null || height <= 0) {
      _snack('Please enter a valid height', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _snack('No user logged in.', isError: true);
        return;
      }

      await _firestoreService.updateUserProfile(user.uid, {
        'gender': selectedGender,
        'age': age,
        'weight': weight,
        'weightUnit': weightUnit,
        'height': height,
        'heightUnit': heightUnit,
        'profileSetupComplete': true,
      });

      if (!mounted) return;
      _snack('Profile saved successfully!');
      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;
      Navigator.pushNamed(context, '/goal-selection');
    } catch (e) {
      _snack('Error saving profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickUnit({
    required String title,
    required List<String> options,
    required String current,
    required void Function(String) onSelected,
  }) async {
    if (_isLoading) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.r24),
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
                Text(title,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...options.map((opt) {
                  final isSel = opt == current;
                  return ListTile(
                    title: Text(opt),
                    trailing:
                        isSel ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelected(opt);
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

  void _convertWeightUnit(String toUnit) {
    final w = _parseDoubleSafe(_weightController.text);
    if (w == null) return;

    double newValue = w;
    if (weightUnit == 'KG' && toUnit == 'LB') {
      newValue = w * 2.2046226218;
    } else if (weightUnit == 'LB' && toUnit == 'KG') {
      newValue = w / 2.2046226218;
    } else {
      return;
    }
    _weightController.text = newValue.toStringAsFixed(1);
  }

  void _convertHeightUnit(String toUnit) {
    final h = _parseDoubleSafe(_heightController.text);
    if (h == null) return;

    double newValue = h;
    if (heightUnit == 'CM' && toUnit == 'FT') {
      newValue = h / 30.48;
    } else if (heightUnit == 'FT' && toUnit == 'CM') {
      newValue = h * 30.48;
    } else {
      return;
    }
    _heightController.text = newValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: fade,
                child: Row(
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
                          value: 0.33,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/goal-selection'),
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
              ),

              const SizedBox(height: 22),

              FadeTransition(
                opacity: fade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello $_userName!',
                        style:
                            const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'Tell us more about you...',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Select your gender'),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _GenderCard(
                              title: 'Male',
                              icon: Icons.person,
                              selected: selectedGender == 'Male',
                              enabled: !_isLoading,
                              onTap: () => setState(() => selectedGender = 'Male'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _GenderCard(
                              title: 'Female',
                              icon: Icons.person_outline,
                              selected: selectedGender == 'Female',
                              enabled: !_isLoading,
                              onTap: () => setState(() => selectedGender = 'Female'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      _sectionTitle('Age'),
                      const SizedBox(height: 10),
                      _InputRow(
                        enabled: !_isLoading,
                        controller: _ageController,
                        hint: 'Enter age',
                        keyboardType: TextInputType.number,
                        unitText: 'years',
                        onUnitTap: null,
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle('Weight'),
                      const SizedBox(height: 10),
                      _InputRow(
                        enabled: !_isLoading,
                        controller: _weightController,
                        hint: weightUnit == 'KG' ? 'e.g. 60' : 'e.g. 132',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        unitText: weightUnit,
                        onUnitTap: () async {
                          await _pickUnit(
                            title: 'Weight unit',
                            options: const ['KG', 'LB'],
                            current: weightUnit,
                            onSelected: (u) {
                              setState(() {
                                _convertWeightUnit(u);
                                weightUnit = u;
                              });
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle('Height'),
                      const SizedBox(height: 10),
                      _InputRow(
                        enabled: !_isLoading,
                        controller: _heightController,
                        hint: heightUnit == 'CM' ? 'e.g. 165' : 'e.g. 5.4',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        unitText: heightUnit,
                        onUnitTap: () async {
                          await _pickUnit(
                            title: 'Height unit',
                            options: const ['CM', 'FT'],
                            current: heightUnit,
                            onSelected: (u) {
                              setState(() {
                                _convertHeightUnit(u);
                                heightUnit = u;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfileData,
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

  Widget _sectionTitle(String t) =>
      Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
}

class _InputRow extends StatelessWidget {
  final bool enabled;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String unitText;
  final VoidCallback? onUnitTap;

  const _InputRow({
    required this.enabled,
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.unitText,
    required this.onUnitTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: enabled ? onUnitTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Text(
                    unitText,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onUnitTap != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.primary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _GenderCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      enabled: enabled,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.softBlue : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: AppColors.softShadow(opacity: 0.06),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 56,
                color: selected ? Colors.black87 : Colors.black54),
            const SizedBox(height: 10),
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: selected
                  ? const Icon(Icons.check_circle,
                      key: ValueKey('on'), color: AppColors.accent)
                  : Icon(Icons.circle_outlined,
                      key: const ValueKey('off'),
                      color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
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

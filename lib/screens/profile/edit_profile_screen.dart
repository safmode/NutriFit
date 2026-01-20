// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  // Goals/Program
  Set<String> _selectedGoals = {};
  final List<Map<String, dynamic>> _goalOptions = [
    {'title': 'Lose Weight', 'icon': Icons.speed},
    {'title': 'Build Strength', 'icon': Icons.fitness_center},
    {'title': 'Gain Weight', 'icon': Icons.assessment},
    {'title': 'Reduce Stress', 'icon': Icons.self_improvement},
    {'title': 'Improve Health', 'icon': Icons.favorite},
  ];

  String _heightUnit = 'CM';
  String _weightUnit = 'KG';
  bool _loading = false;
  bool _dataLoaded = false;

  // Store the original heightCm and weightKg from database
  double? _storedHeightCm;
  double? _storedWeightKg;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _loadUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestoreService.getUserData(user.uid);
      final data = snapshot.data() ?? {};

      if (!mounted) return;

      setState(() {
        _firstNameController.text = (data['firstName'] as String?) ?? '';
        _lastNameController.text = (data['lastName'] as String?) ?? '';

        // Load height - ALWAYS store as CM in database
        final heightCm = data['heightCm'] as num?;
        _heightUnit = (data['heightUnit'] as String?) ?? 'CM';

        if (heightCm != null) {
          _storedHeightCm = heightCm.toDouble();
          // Convert from CM to selected unit for display
          final displayHeight = _heightUnit == 'FT' 
              ? heightCm / 30.48 
              : heightCm;
          _heightController.text = displayHeight.toStringAsFixed(1);
        }

        // Load weight - ALWAYS store as KG in database
        final weightKg = data['weightKg'] as num?;
        _weightUnit = (data['weightUnit'] as String?) ?? 'KG';

        if (weightKg != null) {
          _storedWeightKg = weightKg.toDouble();
          // Convert from KG to selected unit for display
          final displayWeight = _weightUnit == 'LBS' 
              ? weightKg / 0.453592 
              : weightKg;
          _weightController.text = displayWeight.toStringAsFixed(1);
        }

        _ageController.text = (data['age']?.toString()) ?? '';

        // Load goals
        final goals = data['goals'];
        if (goals is List) {
          _selectedGoals = Set<String>.from(goals.map((e) => e.toString()));
        }

        _dataLoaded = true;
      });

      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error loading profile: $e', isError: true);
      setState(() => _dataLoaded = true);
      _animController.forward();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  String? _validateNumber(
    String? value,
    String fieldName, {
    double? min,
    double? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    return null;
  }

  // Handle unit changes - convert the displayed value
  void _onHeightUnitChanged(String newUnit) {
    if (_heightController.text.trim().isEmpty) {
      setState(() => _heightUnit = newUnit);
      return;
    }

    final currentValue = double.tryParse(_heightController.text.trim());
    if (currentValue == null) {
      setState(() => _heightUnit = newUnit);
      return;
    }

    double newValue;
    if (_heightUnit == 'CM' && newUnit == 'FT') {
      // Converting CM to FT
      newValue = currentValue / 30.48;
    } else if (_heightUnit == 'FT' && newUnit == 'CM') {
      // Converting FT to CM
      newValue = currentValue * 30.48;
    } else {
      newValue = currentValue;
    }

    setState(() {
      _heightUnit = newUnit;
      _heightController.text = newValue.toStringAsFixed(1);
    });
  }

  void _onWeightUnitChanged(String newUnit) {
    if (_weightController.text.trim().isEmpty) {
      setState(() => _weightUnit = newUnit);
      return;
    }

    final currentValue = double.tryParse(_weightController.text.trim());
    if (currentValue == null) {
      setState(() => _weightUnit = newUnit);
      return;
    }

    double newValue;
    if (_weightUnit == 'KG' && newUnit == 'LBS') {
      // Converting KG to LBS
      newValue = currentValue / 0.453592;
    } else if (_weightUnit == 'LBS' && newUnit == 'KG') {
      // Converting LBS to KG
      newValue = currentValue * 0.453592;
    } else {
      newValue = currentValue;
    }

    setState(() {
      _weightUnit = newUnit;
      _weightController.text = newValue.toStringAsFixed(1);
    });
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _showSnackBar('User not logged in', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final updates = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'heightUnit': _heightUnit,
        'weightUnit': _weightUnit,
      };

      // Add optional numeric fields
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());
      final age = int.tryParse(_ageController.text.trim());

      // ALWAYS store height in CM (for consistency in BMI calculations)
      if (height != null) {
        final heightCm = _heightUnit == 'FT' ? height * 30.48 : height;
        updates['heightCm'] = heightCm;
        // Also store the display value and unit for reference
        updates['height'] = height;
      }

      // ALWAYS store weight in KG (for consistency in BMI calculations)
      if (weight != null) {
        final weightKg = _weightUnit == 'LBS' ? weight * 0.453592 : weight;
        updates['weightKg'] = weightKg;
        // Also store the display value and unit for reference
        updates['weight'] = weight;
      }

      if (age != null) updates['age'] = age;

      // Add goals
      updates['goals'] = _selectedGoals.toList();

      // Add timestamp
      updates['profileSetupComplete'] = true;

      // Debug: Print what we're saving
      print('💾 Saving profile updates: $updates');

      await _firestoreService.updateUserProfile(user.uid, updates);

      // Verify the save by reading back
      final verifySnapshot = await _firestoreService.getUserData(user.uid);
      final verifyData = verifySnapshot.data();
      print('✅ Verified saved data: $verifyData');

      if (!mounted) return;
      _showSnackBar('Profile updated successfully!');

      // Wait a bit for snackbar to show, then go back
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      print('❌ Error saving profile: $e');
      _showSnackBar('Failed to update profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
      ),
      body: !_dataLoaded
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline,
                            validator: (v) => _validateName(v, 'First name'),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline,
                            validator: (v) => _validateName(v, 'Last name'),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Body Measurements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildNumberFieldWithUnit(
                            controller: _heightController,
                            label: 'Height',
                            icon: Icons.height,
                            unit: _heightUnit,
                            units: ['CM', 'FT'],
                            onUnitChanged: _onHeightUnitChanged,
                            validator: (v) =>
                                _validateNumber(v, 'Height', min: 1, max: 300),
                          ),
                          const SizedBox(height: 12),
                          _buildNumberFieldWithUnit(
                            controller: _weightController,
                            label: 'Weight',
                            icon: Icons.monitor_weight_outlined,
                            unit: _weightUnit,
                            units: ['KG', 'LBS'],
                            onUnitChanged: _onWeightUnitChanged,
                            validator: (v) =>
                                _validateNumber(v, 'Weight', min: 1, max: 500),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _ageController,
                            label: 'Age',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                _validateNumber(v, 'Age', min: 1, max: 150),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Goals / Program',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._goalOptions.map((goal) {
                            final title = goal['title'] as String;
                            final icon = goal['icon'] as IconData;
                            final isSelected = _selectedGoals.contains(title);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedGoals.remove(title);
                                  } else {
                                    _selectedGoals.add(title);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.softBlue
                                      : AppColors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 20,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isSelected
                                              ? AppColors.text
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 32),
                          _buildSaveButton(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: TextInputAction.next,
        enabled: !_loading,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.subText),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildNumberFieldWithUnit({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String unit,
    required List<String> units,
    required ValueChanged<String> onUnitChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_loading,
              validator: validator,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.subText),
                prefixIcon: Icon(icon, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: unit,
              underline: const SizedBox(),
              items: units
                  .map(
                    (u) => DropdownMenuItem(
                      value: u,
                      child: Text(
                        u,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : (v) => onUnitChanged(v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
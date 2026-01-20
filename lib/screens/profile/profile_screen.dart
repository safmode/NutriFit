// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/press_scale.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Local palette (safe to use everywhere in this file)
  static const Color kPrimary = Color(0xFF92A3FD);
  static const Color kAccent = Color(0xFFC58BF2);

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late final AnimationController _controller;

  bool _notificationEnabled = true;
  bool _savingNotif = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setNotificationEnabled(bool value) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // optimistic update
    setState(() {
      _notificationEnabled = value;
      _savingNotif = true;
    });

    try {
      await _firestoreService.updateUserProfile(user.uid, {
        'notificationEnabled': value,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationEnabled = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update notification: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // ✅ no return inside finally
      if (mounted) {
        setState(() => _savingNotif = false);
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              ListTile(
                leading: const Icon(Icons.share, color: kPrimary),
                title: const Text('Share Profile'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _safeMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    final fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Session expired. Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SquareIconButton(
              icon: Icons.more_horiz,
              onTap: _showMoreOptions,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.streamUserData(user.uid),
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          final hasError = snap.hasError;

          final data = _safeMap(snap.data?.data());

          // Build values safely
          final first = (data['firstName'] is String)
              ? (data['firstName'] as String).trim()
              : '';
          final last = (data['lastName'] is String)
              ? (data['lastName'] as String).trim()
              : '';
          final fullFromParts = ('$first $last').trim();

          final fullName =
              (data['fullName'] is String &&
                  (data['fullName'] as String).trim().isNotEmpty)
              ? (data['fullName'] as String).trim()
              : fullFromParts;

          final goalsRaw = data['goals'];
          final goals = (goalsRaw is List)
              ? goalsRaw
                    .map((e) => e.toString())
                    .where((s) => s.trim().isNotEmpty)
                    .toList()
              : <String>[];

          final heightVal = data['height'];
          final weightVal = data['weight'];
          final ageVal = data['age'];

          final heightUnit = (data['heightUnit'] is String)
              ? (data['heightUnit'] as String)
              : 'CM';
          final weightUnit = (data['weightUnit'] is String)
              ? (data['weightUnit'] as String)
              : 'KG';

          final notif = data['notificationEnabled'];
          final notifEnabled = (notif is bool) ? notif : true;

          // sync switch state from Firestore only when not saving locally
          if (!_savingNotif && _notificationEnabled != notifEnabled) {
            _notificationEnabled = notifEnabled;
          }

          final userName = fullName.isNotEmpty ? fullName : 'User';
          final userProgram = goals.isNotEmpty
              ? goals.join(', ')
              : 'No program assigned';

          final height = (heightVal != null)
              ? '${heightVal.toString()} ${heightUnit.toUpperCase()}'
              : '--';
          final weight = (weightVal != null)
              ? '${weightVal.toString()} ${weightUnit.toUpperCase()}'
              : '--';
          final age = (ageVal != null) ? '${ageVal.toString()} yo' : '--';

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Error loading profile: ${snap.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0FF),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: kPrimary,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userProgram,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _GradientButton(
                                text: "Edit",
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/edit-profile',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  value: height,
                                  label: "Height",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  value: weight,
                                  label: "Weight",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(value: age, label: "Age"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SectionCard(
                            title: "Account",
                            children: [
                              _MenuTile(
                                icon: Icons.person_outline,
                                title: "Personal Data",
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/personal-data',
                                ),
                              ),
                              _MenuTile(
                                icon: Icons.assignment_outlined,
                                title: "Achievement",
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Achievements coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _MenuTile(
                                icon: Icons.history,
                                title: "Activity History",
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/activity-tracker',
                                ),
                              ),
                              _MenuTile(
                                icon: Icons.bar_chart,
                                title: "Workout Progress",
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/progress-photo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: "Notification",
                            children: [
                              Row(
                                children: [
                                  const _IconBox(
                                    icon: Icons.notifications_none,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Pop-up Notification",
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _notificationEnabled,
                                    onChanged: _setNotificationEnabled,
                                    activeThumbColor: kAccent,
                                  ),
                                ],
                              ),
                              if (_savingNotif)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: const [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Saving...',
                                        style: TextStyle(
                                          color: AppColors.subText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: PressScale(
                              onTap: _logout,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Logout",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

/* ---------------- UI PIECES ---------------- */

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  static const Color kPrimary = Color(0xFF92A3FD);
  static const Color kSecondary = Color(0xFF9DCEFF);

  final String text;
  final VoidCallback onTap;

  const _GradientButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: 110,
      child: PressScale(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kPrimary, kSecondary]),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  static const Color kPrimary = Color(0xFF92A3FD);

  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  static const Color kPrimary = Color(0xFF92A3FD);

  final IconData icon;
  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: kPrimary, size: 20),
    );
  }
}

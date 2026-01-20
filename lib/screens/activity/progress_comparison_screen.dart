import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ProgressComparisonScreen extends StatefulWidget {
  const ProgressComparisonScreen({super.key});

  @override
  State<ProgressComparisonScreen> createState() =>
      _ProgressComparisonScreenState();
}

class _ProgressComparisonScreenState extends State<ProgressComparisonScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  late final AnimationController _pageCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  List<String> _availableMonths = [];
  Map<String, List<Map<String, dynamic>>> _photosByMonth = {};
  String? selectedMonth1;
  String? selectedMonth2;
  bool _isLoading = true;

  bool get _canCompare => selectedMonth1 != null && selectedMonth2 != null;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));

    _pageCtrl.forward();
    _loadPhotos();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestoreService.getProgressPhotos(user.uid);

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp'];
        final DateTime date = (ts is Timestamp) ? ts.toDate() : DateTime.now();
        
        // Group by month-year (e.g., "January 2024")
        final monthKey = DateFormat('MMMM yyyy').format(date);
        
        // ✅ FIX: Include the 'view' field from Firestore!
        final photo = {
          'id': doc.id,
          'base64': (data['photoBase64'] ?? '').toString(),
          'date': date,
          'displayDate': DateFormat('MMM dd, yyyy').format(date),
          'view': (data['view'] ?? 'unknown').toString(), // ✅✅✅ CRITICAL FIX!
        };

        // Debug logging
        debugPrint('📸 Loading photo for comparison:');
        debugPrint('   ID: ${doc.id}');
        debugPrint('   View: ${photo['view']}');
        debugPrint('   Date: $date');
        debugPrint('   Month: $monthKey');

        if (grouped.containsKey(monthKey)) {
          grouped[monthKey]!.add(photo);
        } else {
          grouped[monthKey] = [photo];
        }
      }

      // Sort photos within each month by date
      grouped.forEach((key, photos) {
        photos.sort((a, b) =>
            (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      });

      // Sort months chronologically (most recent first)
      final sortedMonths = grouped.keys.toList()
        ..sort((a, b) {
          final dateA = DateFormat('MMMM yyyy').parse(a);
          final dateB = DateFormat('MMMM yyyy').parse(b);
          return dateB.compareTo(dateA);
        });

      if (mounted) {
        setState(() {
          _photosByMonth = grouped;
          _availableMonths = sortedMonths;
          
          // Auto-select two most recent months if available
          if (_availableMonths.isNotEmpty) {
            selectedMonth1 = _availableMonths.first;
          }
          if (_availableMonths.length > 1) {
            selectedMonth2 = _availableMonths[1];
          }
        });
      }

      // Debug: Print what we loaded
      debugPrint('✅ Loaded photos grouped by month:');
      grouped.forEach((month, photos) {
        debugPrint('  $month: ${photos.length} photos');
        for (var photo in photos) {
          debugPrint('    - ${photo['id']}: view=${photo['view']}');
        }
      });
    } catch (e) {
      debugPrint('Error loading photos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openMoreSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.r24),
      ),
      builder: (ctx) {
        return SafeArea(
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
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Take New Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/progress-photo');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: AppColors.accent),
                  title: const Text('Swap Months'),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (selectedMonth1 != null && selectedMonth2 != null) {
                      setState(() {
                        final temp = selectedMonth1;
                        selectedMonth1 = selectedMonth2;
                        selectedMonth2 = temp;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker({required bool isMonth1}) {
    if (_availableMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos available. Take some photos first!')),
      );
      return;
    }

    final currentSelection = isMonth1 ? selectedMonth1 : selectedMonth2;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.r24),
      ),
      builder: (ctx) {
        return SafeArea(
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
                const SizedBox(height: 12),
                Text(
                  isMonth1 ? 'Select Month 1' : 'Select Month 2',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _availableMonths.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final month = _availableMonths[i];
                      final photoCount = _photosByMonth[month]?.length ?? 0;
                      final selected = month == currentSelection;

                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.softBlue,
                          ),
                          child: const Icon(Icons.calendar_month, color: AppColors.primary),
                        ),
                        title: Text(
                          month,
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            if (isMonth1) {
                              selectedMonth1 = month;
                            } else {
                              selectedMonth2 = month;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _appbarIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Comparison',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: _appbarIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
        ),
        actions: [
          _appbarIconButton(icon: Icons.more_horiz, onTap: _openMoreSheet),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableMonths.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No Photos Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take progress photos to compare months',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/progress-photo'),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _MonthSelectorCard(
                            label: 'Select Month 1',
                            month: selectedMonth1,
                            photoCount: _photosByMonth[selectedMonth1]?.length ?? 0,
                            onTap: () => _showMonthPicker(isMonth1: true),
                          ),
                          const SizedBox(height: 18),
                          _MonthSelectorCard(
                            label: 'Select Month 2',
                            month: selectedMonth2,
                            photoCount: _photosByMonth[selectedMonth2]?.length ?? 0,
                            onTap: () => _showMonthPicker(isMonth1: false),
                          ),
                          const Spacer(),
                          _PressScale(
                            enabled: _canCompare,
                            onTap: () {
                              if (!_canCompare) return;
                              
                              // Debug: Print what we're passing
                              debugPrint('🚀 Navigating to comparison with:');
                              debugPrint('  Month 1: $selectedMonth1');
                              debugPrint('  Month 2: $selectedMonth2');
                              final m1Photos = _photosByMonth[selectedMonth1] ?? [];
                              final m2Photos = _photosByMonth[selectedMonth2] ?? [];
                              debugPrint('  Month 1 photos: ${m1Photos.length}');
                              for (var p in m1Photos) {
                                debugPrint('    - ${p['id']}: view=${p['view']}');
                              }
                              debugPrint('  Month 2 photos: ${m2Photos.length}');
                              for (var p in m2Photos) {
                                debugPrint('    - ${p['id']}: view=${p['view']}');
                              }
                              
                              Navigator.pushNamed(
                                context,
                                '/progress-result',
                                arguments: {
                                  'month1': selectedMonth1,
                                  'month2': selectedMonth2,
                                  'photosMonth1': m1Photos,
                                  'photosMonth2': m2Photos,
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                gradient:
                                    _canCompare ? AppColors.primaryGradient : null,
                                color: _canCompare ? null : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: _canCompare
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.28),
                                          blurRadius: 16,
                                          offset: const Offset(0, 10),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Compare',
                                style: TextStyle(
                                  color: _canCompare
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 38),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _MonthSelectorCard extends StatelessWidget {
  final String label;
  final String? month;
  final int photoCount;
  final VoidCallback onTap;

  const _MonthSelectorCard({
    required this.label,
    required this.month,
    required this.photoCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMonth = month != null;
    final displayText = hasMonth ? month! : 'Select Month';

    return _PressScale(
      enabled: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasMonth && photoCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: hasMonth ? Colors.grey.shade700 : Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  const _PressScale({
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _down ? 0.97 : 1.0,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
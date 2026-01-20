// ================================
// progress_result_screen.dart
// ================================
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;

class ProgressResultScreen extends StatefulWidget {
  const ProgressResultScreen({super.key});

  @override
  State<ProgressResultScreen> createState() => _ProgressResultScreenState();
}

class _ProgressResultScreenState extends State<ProgressResultScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _pageCtrl;
  late final Animation<double> _fade;

  String? month1;
  String? month2;
  Map<String, List<Map<String, dynamic>>> photosMonth1ByView = {};
  Map<String, List<Map<String, dynamic>>> photosMonth2ByView = {};

  final List<String> _viewKeys = ['front', 'right', 'back', 'left'];
  final List<String> _viewLabels = ['Front Facing', 'Right Facing', 'Back Facing', 'Left Facing'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _pageCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      month1 = args['month1'] as String?;
      month2 = args['month2'] as String?;
      
      final photosM1 = (args['photosMonth1'] as List<Map<String, dynamic>>?) ?? [];
      final photosM2 = (args['photosMonth2'] as List<Map<String, dynamic>>?) ?? [];

      // Group photos by view
      photosMonth1ByView = _groupPhotosByView(photosM1);
      photosMonth2ByView = _groupPhotosByView(photosM2);

      // Debug: Print what we received
      debugPrint('📸 Month 1 photos by view:');
      photosMonth1ByView.forEach((view, photos) {
        debugPrint('  $view: ${photos.length} photos');
      });
      debugPrint('📸 Month 2 photos by view:');
      photosMonth2ByView.forEach((view, photos) {
        debugPrint('  $view: ${photos.length} photos');
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupPhotosByView(
    List<Map<String, dynamic>> photos,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'front': [],
      'right': [],
      'back': [],
      'left': [],
    };

    for (final photo in photos) {
      // Get the view field from Firestore
      final String? detectedView = photo['view'] as String?;
      
      debugPrint('Photo view: $detectedView');

      if (detectedView != null && grouped.containsKey(detectedView)) {
        // Use the ML-detected pose
        grouped[detectedView]!.add(photo);
      } else {
        // If no valid view, skip this photo
        debugPrint('⚠️ Photo has no valid view field: ${photo['id']}');
      }
    }

    // Sort newest first within each view
    grouped.forEach((_, list) {
      list.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
    });

    return grouped;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  int _calculateDaysDifference() {
    final allPhotos1 = photosMonth1ByView.values.expand((x) => x).toList();
    final allPhotos2 = photosMonth2ByView.values.expand((x) => x).toList();
    
    if (allPhotos1.isEmpty || allPhotos2.isEmpty) return 0;
    
    final date1 = allPhotos1.first['date'] as DateTime;
    final date2 = allPhotos2.first['date'] as DateTime;
    
    return date1.difference(date2).inDays.abs();
  }

  String _getProgressStatus() {
    final days = _calculateDaysDifference();
    if (days < 30) return 'Early Progress';
    if (days < 60) return 'Good';
    if (days < 90) return 'Great';
    return 'Excellent';
  }

  double _calculateProgressPercentage() {
    final days = _calculateDaysDifference();
    return (days / 90).clamp(0.0, 1.0) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Result',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Photo'),
                  Tab(text: 'Statistic'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPhotoTab(context),
                  _buildStatisticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // PHOTO TAB
  // --------------------------------------------------
  Widget _buildPhotoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Average Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              _StatusChip(label: _getProgressStatus()),
            ],
          ),
          const SizedBox(height: 15),

          // Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.62,
                        minHeight: 30,
                        backgroundColor: const Color(0xFFE8EEFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF92A3FD),
                        ),
                      ),
                    ),
                    const Text(
                      '62%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const SizedBox(height: 25),

          // Month labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month1 ?? 'Month 1',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                month2 ?? 'Month 2',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // View comparisons - Show ALL views with clear instructions
          for (int i = 0; i < _viewKeys.length; i++) ...[
            _buildViewSection(
              viewKey: _viewKeys[i],
              viewLabel: _viewLabels[i],
              month1Photos: photosMonth1ByView[_viewKeys[i]] ?? [],
              month2Photos: photosMonth2ByView[_viewKeys[i]] ?? [],
            ),
          ],

          // Overall status message
          _buildStatusMessage(),

          const SizedBox(height: 10),
          _backHomeButton(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildViewSection({
    required String viewKey,
    required String viewLabel,
    required List<Map<String, dynamic>> month1Photos,
    required List<Map<String, dynamic>> month2Photos,
  }) {
    final hasMonth1 = month1Photos.isNotEmpty;
    final hasMonth2 = month2Photos.isNotEmpty;
    final isComplete = hasMonth1 && hasMonth2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForView(viewKey),
                  size: 20,
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                Text(
                  viewLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Status badge
            if (isComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Need ${!hasMonth1 ? "Month 1" : "Month 2"}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Photo comparison row
        Row(
          children: [
            Expanded(
              child: _buildPhotoCard(
                photo: month1Photos.firstOrNull,
                fallbackColor: const Color(0xFFE8EEFF),
                expectedView: viewKey,
                monthLabel: month1 ?? 'Month 1',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPhotoCard(
                photo: month2Photos.firstOrNull,
                fallbackColor: const Color(0xFFF0F0F0),
                expectedView: viewKey,
                monthLabel: month2 ?? 'Month 2',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPhotoCard({
    required Map<String, dynamic>? photo,
    required Color fallbackColor,
    required String expectedView,
    required String monthLabel,
  }) {
    final hasPhoto = photo != null && photo['base64'] != null;
    final String? detectedView = photo?['view'] as String?;
    final bool viewMatches = detectedView == expectedView;
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: fallbackColor,
        borderRadius: BorderRadius.circular(18),
        border: hasPhoto && viewMatches
            ? Border.all(color: Colors.grey.shade300, width: 1)
            : Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto && viewMatches)
              Image.memory(
                base64Decode(photo!['base64'] as String),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon(
                  fallbackColor,
                  expectedView,
                  monthLabel,
                ),
              )
            else if (hasPhoto && !viewMatches)
              // Show warning for mismatched photos
              _wrongPoseWarning(fallbackColor, detectedView, expectedView)
            else
              _placeholderIcon(fallbackColor, expectedView, monthLabel),

            // Verified badge for correct photos
            if (hasPhoto && viewMatches)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _getShortViewLabel(expectedView),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Date badge
            if (hasPhoto && viewMatches && photo!['date'] != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDate(photo['date'] as DateTime),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wrongPoseWarning(Color bgColor, String? detectedView, String expectedView) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade100, Colors.red.shade50],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(
                'Wrong Pose',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expected: ${_getShortViewLabel(expectedView)}',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              if (detectedView != null)
                Text(
                  'Got: ${_getShortViewLabel(detectedView)}',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(Color bgColor, String viewType, String monthLabel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, bgColor.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForView(viewType),
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Take ${_getShortViewLabel(viewType)} Photo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'for $monthLabel',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    final allMonth1Empty = photosMonth1ByView.values.every((list) => list.isEmpty);
    final allMonth2Empty = photosMonth2ByView.values.every((list) => list.isEmpty);
    
    if (allMonth1Empty && allMonth2Empty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_camera_outlined, size: 48, color: Colors.blue.shade700),
            const SizedBox(height: 12),
            Text(
              'Start Your Progress Journey!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take photos from 4 angles:\n• Front (facing camera)\n• Right side\n• Back (facing away)\n• Left side',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  IconData _getIconForView(String view) {
    switch (view) {
      case 'front':
        return Icons.person;
      case 'right':
        return Icons.turn_right;
      case 'left':
        return Icons.turn_left;
      case 'back':
        return Icons.person_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getShortViewLabel(String view) {
    switch (view) {
      case 'front':
        return 'Front';
      case 'right':
        return 'Right';
      case 'left':
        return 'Left';
      case 'back':
        return 'Back';
      default:
        return view;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    }
    final months = (difference / 30).floor();
    return '$months ${months == 1 ? "month" : "months"} ago';
  }

  // --------------------------------------------------
  // STATISTIC TAB
  // --------------------------------------------------
  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Line Graph
          Container(
            height: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Green increase label
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '82% increase',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_upward,
                          color: Colors.green.shade600,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: ProgressGraphPainter(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // May and June Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'May',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                'June',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Progress Bars with Before/After comparisons
          _comparisonBar('Lose Weight', 0.33, 0.67),
          const SizedBox(height: 18),
          _comparisonBar('Height Increase', 0.88, 0.12),
          const SizedBox(height: 18),
          _comparisonBar('Muscle Mass Increase', 0.57, 0.43),
          const SizedBox(height: 18),
          _comparisonBar('Abs', 0.89, 0.11),

          const SizedBox(height: 35),

          // Back to Home Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF92A3FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _comparisonBar(String label, double left, double right) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '${(left * 100).toInt()}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: left,
                      child: Container(
                        height: 12,
                        color: Colors.pink.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(right * 100).toInt()}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _backHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF92A3FD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Back to Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// SMALL WIDGETS
// --------------------------------------------------
class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --------------------------------------------------
// GRAPH PAINTER
// --------------------------------------------------
class ProgressGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final percentPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw percentage lines
    for (var i = 0; i <= 5; i++) {
      final y = size.height - (size.height * i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width - 30, y), percentPaint);

      final percentage = i * 20;
      textPainter.text = TextSpan(
        text: '$percentage%',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 28, y - 7));
    }

    // Draw month labels
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    for (var i = 0; i < months.length; i++) {
      final x = (size.width - 30) * i / (months.length - 1);
      textPainter.text = TextSpan(
        text: months[i],
        style: TextStyle(
          color: months[i] == 'May'
              ? const Color(0xFFFF69B4)
              : Colors.grey.shade500,
          fontSize: 11,
          fontWeight: months[i] == 'May' ? FontWeight.w700 : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 10, size.height + 8));
    }

    // Draw blue wave
    final bluePath = Path();
    final bluePaint = Paint()
      ..color = const Color(0xFF92A3FD)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    bluePath.moveTo(0, size.height * 0.6);
    for (var i = 0.0; i <= size.width - 30; i++) {
      final progress = i / (size.width - 30);
      final y = size.height * 0.6 +
          math.sin((progress) * math.pi * 2.5) * size.height * 0.3;
      bluePath.lineTo(i, y);
    }
    canvas.drawPath(bluePath, bluePaint);

    // Draw pink wave
    final pinkPath = Path();
    final pinkPaint = Paint()
      ..color = Colors.pink.shade200
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    pinkPath.moveTo(0, size.height * 0.8);
    for (var i = 0.0; i <= size.width - 30; i++) {
      final progress = i / (size.width - 30);
      final y = size.height * 0.8 +
          math.sin((progress + 0.5) * math.pi * 2) * size.height * 0.15;
      pinkPath.lineTo(i, y);
    }
    canvas.drawPath(pinkPath, pinkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// ================================
// body_visualization_screen.dart
// ================================
import 'package:flutter/material.dart';

class BodyVisualizationScreen extends StatefulWidget {
  const BodyVisualizationScreen({super.key});

  @override
  State<BodyVisualizationScreen> createState() =>
      _BodyVisualizationScreenState();
}

class _BodyVisualizationScreenState extends State<BodyVisualizationScreen> {
  int _selectedIndex = 0;

  void _openCameraFlow() {
    Navigator.pushNamed(context, '/progress-photo');
  }

  void _openGalleryFlow() {
    Navigator.pushNamed(context, '/progress-comparison');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        size: 280,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'View ${_selectedIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Floating Action Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _roundIcon(
                              Icons.close,
                              () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 30),

                            // Camera
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC58BF2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _openCameraFlow,
                              ),
                            ),

                            const SizedBox(width: 30),

                            // Gallery
                            _roundIcon(
                              Icons.photo_library_outlined,
                              _openGalleryFlow,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Thumbnails
          Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final isSelected = index == _selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: _thumbnail(isSelected),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.grey.shade700),
        onPressed: onTap,
      ),
    );
  }

  Widget _thumbnail(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8EEFF) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF92A3FD) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 50,
          color: selected ? const Color(0xFF92A3FD) : Colors.grey.shade400,
        ),
      ),
    );
  }
}
